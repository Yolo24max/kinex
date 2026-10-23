# Extracted historical tool call; depends on prior observations and device state.
import numpy as np
from scipy.spatial.transform import Rotation as R
from kinex import call
p1=call('relative_pose',child={'frame':'camera'},parent={'frame':'world'})['pose'];p2=call('relative_pose',child={'frame':'camera_wrist'},parent={'frame':'world'})['pose']
def tri(uv1,uv2):
 d1=R.from_quat(p1[3:]).apply([(uv1[0]-127.5)/309.0193,(uv1[1]-127.5)/309.0193,1]); d2=R.from_quat(p2[3:]).apply([(uv2[0]-127.5)/166.81285,(uv2[1]-127.5)/166.81285,1]); a=np.array(p1[:3]);b=np.array(p2[:3]); ts=np.linalg.lstsq(np.column_stack([d1,-d2]),b-a,rcond=None)[0]; print((a+ts[0]*d1+b+ts[1]*d2)/2,'ray error',np.linalg.norm(a+ts[0]*d1-b-ts[1]*d2))
tri((132,146),(114,79));tri((198,189),(27,10));tri((180,126),(32,141))
