# Extracted historical tool call; depends on prior observations and device state.
from kinex import device, finish
print(device('gripper','write',{'actions':[1.0],'duration_s':0.7}));print(device('world','wait',{'duration_s':0.8}));print(device('gripper')); print(device('arm'))
r=device('camera','read',{'output':'file'});finish({},file=r['file'])
