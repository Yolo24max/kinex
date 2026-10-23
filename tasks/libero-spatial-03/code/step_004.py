# Extracted historical tool call; depends on prior observations and device state.
from kinex import profile
for name in ['world','arm','gripper','camera','camera_wrist']:
 print(name, profile(name))
