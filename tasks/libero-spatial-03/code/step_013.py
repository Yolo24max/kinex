# Extracted historical tool call; depends on prior observations and device state.
from kinex import device, call, finish
print(call('servo',device='arm',pose=[-0.073,-0.030,1.125,1,0,0,0],frame='world',speedFraction=0.2));device('world','wait',{'duration_s':0.3});print(device('arm')); print(device('gripper'))
r=device('camera','read',{'output':'file'});s=device('camera_wrist','read',{'output':'file'});finish({},file=[r['file'],s['file']])
