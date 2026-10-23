# Extracted historical tool call; depends on prior observations and device state.
from kinex import device, call, finish
print(call('servo',device='arm',pose=[-0.073,-0.030,1.044,1,0,0,0],frame='world',speedFraction=0.2))
print(device('world','wait',{'duration_s':0.25}))
a=device('arm');print(a);print(device('arm','fk',{'joints':a['positions']}))
r=device('camera_wrist','read',{'output':'file'});finish({},file=r['file'])
