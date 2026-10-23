# Extracted historical tool call; depends on prior observations and device state.
from kinex import device, call
print(device('gripper','write',{'actions':[-1.0],'duration_s':0.5}))
print(call('servo',device='arm',pose=[-0.073,-0.030,1.145,1,0,0,0],frame='world',speedFraction=0.35))
a=device('arm');print(a);print(device('arm','fk',{'joints':a['positions']}));print(device('gripper'))
r=device('camera_wrist','read',{'output':'file'});finish(file=r['file'])
