"""Preview a new run by default. --execute opts into simulator and model calls."""
import argparse,datetime,json,os,pathlib,shutil,subprocess,sys,time
ROOT=pathlib.Path(__file__).resolve().parents[1]
def plan(args):
 data=json.loads((ROOT/'results/completed.json').read_text(encoding='utf-8'))
 task=next(t for t in data['tasks'] if t['key']==args.task)
 envroot=pathlib.Path(args.roboenv_root).expanduser().resolve()
 workspace=ROOT/'.runs/workspaces'/task['key']
 robot='libero/libero-panda-tabletop' if task['key']=='libero-spatial-03' else task['robot']
 cli=envroot/'.venv/bin/roboenv'
 prompt='Operate the running simulator through KinEx device tools only. '+task['prompt']+' Inspect camera observations and robot state, load/ping devices, and verify the outcome honestly. Do not call the RoboEnv driver directly.'
 return task,workspace,{
  'task':task['native_id'],'mode':'new functional run; not strict benchmark replay',
  'roboenv_root':str(envroot),'workspace':str(workspace),'port':args.port or task['port'],
  'setup':[str(cli),'setup',robot],
  'launch':[str(cli),'launch',task['native_id'],'--port',str(args.port or task['port']),'--record','<NEW_RUN>/recordings','--stop-on-success','--detach','--json'],
  'agent':['kinex','--auto','--provider','openai-codex','--model',args.model,'--thinking','high','--mode','json','-p',prompt],
  'executes':args.execute,'historical_budget_max':None,
 }
def run(args):
 task,workspace,p=plan(args)
 if not args.execute:
  print(json.dumps(p,ensure_ascii=False,indent=2));return 0
 if os.name!='posix':raise SystemExit('Execute on the prepared Linux simulator host; preview works on any OS.')
 cli=pathlib.Path(p['setup'][0])
 if not cli.is_file():raise SystemExit('Missing RoboEnv CLI: prepare the pinned checkout and environment first.')
 if shutil.which('kinex') is None:raise SystemExit('KinEx must be installed and logged in before executing.')
 # Fail before creating a simulator if another task already owns this port.
 import socket
 with socket.socket() as s:
  if s.connect_ex(('127.0.0.1',p['port']))==0:raise SystemExit('Port already in use; choose another --port. Existing services were left alone.')
 stamp=datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%SZ')
 output=ROOT/'.runs'/task['key']/stamp;output.mkdir(parents=True,exist_ok=False)
 workspace.mkdir(parents=True,exist_ok=True)
 env=os.environ.copy();env['ROBOENV_ENDPOINT']='http://127.0.0.1:'+str(p['port'])
 p['launch'][p['launch'].index('<NEW_RUN>/recordings')]=str(output/'recordings')
 (output/'plan.json').write_text(json.dumps(p,indent=2),encoding='utf-8')
 if not (workspace/'.kinex').exists():subprocess.run(p['setup'],cwd=workspace,env=env,check=True)
 launch=subprocess.run(p['launch'],cwd=p['roboenv_root'],env=env,check=True,capture_output=True,text=True)
 (output/'launch.json').write_text(launch.stdout,encoding='utf-8')
 record=json.loads(launch.stdout)
 run_id=next((record[k] for k in ['id','run','session'] if record.get(k)),None)
 if not isinstance(run_id,str):raise SystemExit('Launch returned no owned run ID. Inspect launch.json; no unrelated process was stopped.')
 agent_exit=None;status=None
 try:
  for _ in range(90):
   check=subprocess.run([str(cli),'status','--port',str(p['port']),'--json'],env=env,capture_output=True,text=True)
   if check.returncode==0:break
   time.sleep(2)
  else:raise RuntimeError('Simulator did not become ready; model was not called.')
  with (output/'agent.jsonl').open('w',encoding='utf-8') as f:
   try:agent_exit=subprocess.run(p['agent'],cwd=workspace,env=env,stdout=f,stderr=subprocess.STDOUT,timeout=args.timeout).returncode
   except subprocess.TimeoutExpired:agent_exit=124
  final=subprocess.run([str(cli),'status','--port',str(p['port']),'--json'],env=env,capture_output=True,text=True)
  (output/'status.json').write_text(final.stdout,encoding='utf-8')
  if final.returncode==0:
   try:status=json.loads(final.stdout)
   except ValueError:pass
 finally:
  stopped=subprocess.run([str(cli),'stop',run_id,'--json'],env=env,capture_output=True,text=True)
  (output/'stopped.json').write_text(stopped.stdout,encoding='utf-8')
 summary={'agent_process_exit':agent_exit,'status':status,'note':'Process exit is not task success. Inspect native status/verdict and recordings.'}
 (output/'outcome.json').write_text(json.dumps(summary,indent=2),encoding='utf-8')
 print('New run saved:',output)
 # Require the captured native status, independently of CLI process success.
 state=status.get('status',status) if isinstance(status,dict) else {}
 return 0 if agent_exit==0 and state.get('success') is True else 1
if __name__=='__main__':
 parser=argparse.ArgumentParser(description=__doc__)
 parser.add_argument('task',choices=['libero-spatial-03','robotwin-handover-block','robodojo-stack-bowls'])
 parser.add_argument('--roboenv-root',required=True)
 parser.add_argument('--model',default='gpt-6.1-sol')
 parser.add_argument('--port',type=int)
 parser.add_argument('--timeout',type=int,default=3000)
 parser.add_argument('--execute',action='store_true',help='Actually start a new simulator and call the model.')
 raise SystemExit(run(parser.parse_args()))
