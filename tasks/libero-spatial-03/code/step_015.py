# Extracted historical tool call; depends on prior observations and device state.
from kinex import call, device, finish
print(call('servo',device='arm',pose=[0.077,0.157,1.070,1,0,0,0],frame='world',speedFraction=0.18));device('world','wait',{'duration_s':0.3});a=device('arm');print(a);print(device('arm','fk',{'joints':a['positions']}));print(device('gripper'))
r=device('camera','read',{'output':'file'});s=device('camera_wrist','read',{'output':'file'});finish({},file=[r['file'],s['file']])
