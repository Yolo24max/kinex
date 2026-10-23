# Extracted historical tool call; depends on prior observations and device state.
from kinex import call, device
print(call('relative_pose',child={'frame':'camera'},parent={'frame':'world'}))
print(call('relative_pose',child={'frame':'camera_wrist'},parent={'frame':'world'}))
a=device('arm'); print(device('arm','fk',{'joints':a['positions']}))
