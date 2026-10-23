"""Task transport recovery: persistent ranges, retry/backoff, official pin checks."""
import errno
import fcntl
import hashlib
from http.client import HTTPException
import json
import os
from pathlib import Path
import sys
import threading
import time
from urllib.error import HTTPError, URLError
from urllib.parse import quote
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT / "RoboEnv/src"))
from roboenv.provisioning import robodojo_assets as official

SOURCES = ["https://huggingface.co", "https://hf-mirror.com"]
CHUNK = 8 * 1024**2
OUTPUT_LOCK = threading.Lock()


class RangeRejected(Exception):
    pass


def fetch_range(url, pending, offset, total, pacer):
    end = min(total - 1, offset + CHUNK - 1)
    request = Request(url, headers={
        "Range": f"bytes={offset}-{end}", "Accept-Encoding": "identity",
        "User-Agent": "KinEx-authorized-asset-recovery/1",
    })
    pacer.wait()
    with urlopen(request, timeout=90) as response:
        expected = end - offset + 1
        ranged = response.status == 206 and response.headers.get("Content-Range") == f"bytes {offset}-{end}/{total}"
        whole_small = response.status == 200 and offset == 0 and expected == total
        if not (ranged or whole_small):
            raise RangeRejected("Unexpected range response; no data appended")
        if response.headers.get("Content-Length") not in (None, str(expected)):
            raise RangeRejected("Unexpected range size; no data appended")
        if (pending.stat().st_size if pending.exists() else 0) != offset:
            raise ValueError("Partial changed outside the single task downloader")
        remaining = expected
        with pending.open("ab") as output:
            while remaining:
                block = response.read(min(1024**2, remaining))
                if not block:
                    raise ConnectionError("Incomplete range; received bytes retained")
                output.write(block)
                output.flush()
                remaining -= len(block)
            os.fsync(output.fileno())


def download_file(root, entry, pacer=None):
    root = Path(root).resolve()
    relative = official.safe_relative(entry["rfilename"]).relative_to("Assets")
    path = root / relative
    if not path.parent.resolve().is_relative_to(root):
        raise ValueError("Asset destination leaves the selected task depot")
    if path.exists() or path.is_symlink():
        if not official.verified(path, entry):
            raise ValueError("Existing final asset differs from the official pin; preserved")
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    pending = path.with_name(path.name + ".kinex.partial")
    if pending.is_symlink():
        raise ValueError("Partial must not be a symlink")
    pacer = pacer or official.ResolverPacer()
    failures = index = 0
    rejected_sources = set()
    total = entry["size"]
    if total == 0:
        pending.touch(exist_ok=True)
    while True:
        offset = pending.stat().st_size if pending.exists() else 0
        if offset > total:
            raise ValueError("Partial exceeds official size; preserved")
        if offset == total:
            break
        source = SOURCES[index % len(SOURCES)]
        if source in rejected_sources:
            index += 1
            continue
        url = f"{source}/datasets/{official.REPOSITORY}/resolve/{official.REVISION}/{quote(entry['rfilename'])}?download=true&kinex_range={offset}&nonce={time.time_ns()}"
        try:
            fetch_range(url, pending, offset, total, pacer)
            failures = 0
            continue
        except HTTPError as error:
            if error.code == 429:
                pacer.limited(error.headers)
                continue
            if error.code in {401, 403, 404}:
                rejected_sources.add(source)
                if len(rejected_sources) == len(SOURCES):
                    raise RuntimeError("All pinned asset sources require access/source review") from None
            kind = f"HTTP{error.code}"
        except OSError as error:
            if error.errno in {errno.ENOSPC, errno.EDQUOT, errno.EACCES, errno.EPERM, errno.EROFS}:
                raise
            kind = type(error).__name__
        except (URLError, HTTPException, RangeRejected) as error:
            kind = type(error).__name__
        failures += 1
        index += 1
        delay = min(60, 2 ** min(failures, 6))
        if failures <= 3 or failures % 5 == 0:
            with OUTPUT_LOCK:
                print(json.dumps({"event": "resumable_network_retry", "file": entry["rfilename"], "bytes": pending.stat().st_size if pending.exists() else 0, "error_type": kind, "retry_seconds": delay}), flush=True)
        if pacer.cancelled.wait(delay):
            raise ConnectionError("Asset acquisition cancelled; partial retained")
    if not official.verified(pending, entry):
        raise ValueError("Completed partial differs from official checksum; preserved")
    try:
        os.link(pending, path)
    except FileExistsError:
        if not official.verified(path, entry):
            raise ValueError("Concurrent final asset differs from official pin; preserved")
    pending.unlink()  # Verified final hard link retains the complete downloaded bytes.


def self_test():
    from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
    import tempfile
    payload = bytes(range(256)) * 4096
    observed = []
    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            header = self.headers.get("Range")
            observed.append(header)
            start, end = map(int, header.removeprefix("bytes=").split("-"))
            self.send_response(206)
            self.send_header("Content-Range", f"bytes {start}-{end}/{len(payload)}")
            self.send_header("Content-Length", str(end-start+1))
            self.end_headers()
            data = payload[start:end+1]
            self.wfile.write(data[:65536] if len(observed) == 1 else data)
            self.wfile.flush()
            self.close_connection = True
        def log_message(self, *args):
            pass
    server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    test_parent = ROOT / "tmp"
    test_parent.mkdir(exist_ok=True)
    try:
        with tempfile.TemporaryDirectory(prefix="range-recovery-test-", dir=test_parent) as temporary:
            pending = Path(temporary) / "probe.partial"
            for _ in range(3):
                offset = pending.stat().st_size if pending.exists() else 0
                try:
                    fetch_range(f"http://127.0.0.1:{server.server_port}/probe", pending, offset, len(payload), official.ResolverPacer())
                except (ConnectionError, HTTPException):
                    continue
                if pending.stat().st_size == len(payload):
                    break
            assert observed[:2] == [f"bytes=0-{len(payload)-1}", f"bytes=65536-{len(payload)-1}"], observed
            assert hashlib.sha256(pending.read_bytes()).digest() == hashlib.sha256(payload).digest()
            print(json.dumps({"interrupted_transfer_resumed": True, "resume_offset": 65536, "final_sha256_verified": True}), flush=True)
    finally:
        server.shutdown()


def main():
    if "--self-test" in sys.argv:
        self_test()
        return
    lock_path = ROOT / "logs/robodojo-download-recovery7.lock"
    lock_path.parent.mkdir(exist_ok=True)
    with lock_path.open("a+") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        identity = {"pid": os.getpid(), "boot_id": Path("/proc/sys/kernel/random/boot_id").read_text().strip(), "start_ticks": Path("/proc/self/stat").read_text().split()[21], "script_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest()}
        lock.seek(0)
        lock.truncate()
        lock.write(json.dumps(identity))
        lock.flush()
        def progress(message):
            with OUTPUT_LOCK:
                state = {**identity, "updated_at": time.time(), "message": message}
                target = ROOT / "logs/robodojo-download-recovery7-state.json"
                pending = target.with_suffix(".tmp")
                pending.write_text(json.dumps(state) + "\n")
                pending.replace(target)
                print(message, flush=True)
        official.download_file = download_file
        report = official.prepare_assets(ROOT / "RoboEnv", cache=ROOT / "assets/robodojo", progress=progress)
        print(json.dumps(report, indent=2), flush=True)


if __name__ == "__main__":
    main()
