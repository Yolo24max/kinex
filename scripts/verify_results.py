"""Offline archive check; no GPU, model, network, or environment installation."""
import ast,hashlib,json,pathlib,sys
ROOT=pathlib.Path(__file__).resolve().parents[1]
errors=[];checked=0
manifest=ROOT/'provenance/published-files.json'
for r in json.loads(manifest.read_text(encoding='utf-8'))['files']:
 p=ROOT/r['path']
 if not p.is_file():errors.append('Missing: '+r['path']);continue
 b=p.read_bytes();checked+=1
 if len(b)!=r['bytes'] or hashlib.sha256(b).hexdigest()!=r['sha256']:errors.append('Hash/size mismatch: '+r['path'])
results=json.loads((ROOT/'results/completed.json').read_text(encoding='utf-8'))
assert results['functional_successes']==3 and results['strict_official_benchmark_completed'] is False
for task in results['tasks']:
 folder=ROOT/'tasks'/task['key'];terminal=folder/'evidence/terminal.json'
 d=json.loads(terminal.read_text(encoding='utf-8'));calls=json.loads((folder/'code/tool-calls.json').read_text(encoding='utf-8'))['calls']
 if hashlib.sha256(terminal.read_bytes()).hexdigest()!=task['terminal_sha256']:errors.append(task['key']+': terminal identity changed')
 if d['status']['success'] is not True or d['verdict']['raw_score']!=task['raw_score']:errors.append(task['key']+': native result mismatch')
 if d['status']['budget']['max'] is not None:errors.append(task['key']+': historical budget disclosure mismatch')
 if len(calls)!=task['tool_calls']:errors.append(task['key']+': incomplete tool calls')
 steps=list((folder/'code').glob('step_*.py'))
 if len(steps)!=task['python_steps']:errors.append(task['key']+': incomplete Python code extraction')
 for call in calls:
  code=call['arguments'].get('python')
  if isinstance(code,str):
   p=folder/'code'/f'step_{call["sequence"]:03d}.py'
   if p.read_text(encoding='utf-8')!='# Extracted historical tool call; depends on prior observations and device state.\n'+code+'\n':errors.append(str(p)+': extracted arguments differ')
for p in (ROOT/'scripts').glob('*.py'):
 try:ast.parse(p.read_text(encoding='utf-8'))
 except SyntaxError as e:errors.append(str(e))
print(json.dumps({'checked_published_files':checked,'functional_successes':len(results['tasks']),'tool_calls':sum(t['tool_calls'] for t in results['tasks']),'python_steps':sum(t['python_steps'] for t in results['tasks']),'errors':errors},ensure_ascii=False,indent=2))
raise SystemExit(bool(errors))
