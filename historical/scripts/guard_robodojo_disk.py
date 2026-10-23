"""Pause only the pinned asset downloader before the task disk reserve is lost."""
import fcntl
import json
import os
from pathlib import Path
import shutil
import signal
import time

ROOT = Path(__file__).resolve().parent
STATE = ROOT / "logs/robodojo-disk-guard.json"
BOOT = Path("/proc/sys/kernel/random/boot_id").read_text().strip()


def main():
    with (ROOT / "logs/robodojo-disk-guard.lock").open("a+") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        owner = json.loads((ROOT / "logs/robodojo-download-recovery7-state.json").read_text())
        source = json.loads((ROOT / "assets/robodojo/source.json").read_text())
        depot = ROOT / "assets/robodojo" / source["sha"] / "Assets"
        entries = [row for row in source["siblings"] if row["rfilename"].startswith("Assets/")]
        previous = json.loads(STATE.read_text()) if STATE.exists() else {}
        paused = bool(previous.get("paused_by_guard") and previous.get("download_pid") == owner["pid"] and previous.get("download_start_ticks") == owner["start_ticks"])
        while True:
            process = Path("/proc") / str(owner["pid"])
            if owner["boot_id"] != BOOT or not process.exists():
                return
            if process.joinpath("stat").read_text().split()[21] != owner["start_ticks"]:
                return
            if b"resilient_robodojo_assets.py" not in process.joinpath("cmdline").read_bytes():
                return
            missing = 0
            for row in entries:
                target = depot / Path(row["rfilename"]).relative_to("Assets")
                if target.exists():
                    continue
                partial = target.with_name(target.name + ".kinex.partial")
                try:
                    have = partial.stat().st_size
                except FileNotFoundError:
                    have = row["size"] if target.exists() else 0
                missing += max(0, row["size"] - have)
            free = shutil.disk_usage(ROOT).free
            headroom = free - missing
            action = "watching"
            if headroom < 2 * 1024**3 and not paused:
                os.kill(owner["pid"], signal.SIGSTOP)
                paused = True
                action = "paused_for_disk_reserve"
            elif paused and headroom >= 3 * 1024**3:
                os.kill(owner["pid"], signal.SIGCONT)
                paused = False
                action = "resumed_after_capacity_recovery"
            record = {"pid": os.getpid(), "boot_id": BOOT, "start_ticks": Path("/proc/self/stat").read_text().split()[21], "updated_at": time.time(), "download_pid": owner["pid"], "download_start_ticks": owner["start_ticks"], "free_bytes": free, "remaining_asset_bytes": missing, "final_headroom_bytes": headroom, "paused_by_guard": paused, "action": action}
            pending = STATE.with_suffix(".tmp")
            pending.write_text(json.dumps(record, indent=2) + "\n")
            pending.replace(STATE)
            if action != "watching":
                with (ROOT / "logs/robodojo-disk-guard-events.jsonl").open("a") as log:
                    log.write(json.dumps(record) + "\n")
            time.sleep(45)


if __name__ == "__main__":
    main()
