# Extracted historical tool call; depends on prior observations and device state.
from kinex import call
p1=call('relative_pose',child={'frame':'camera'},parent={'frame':'world'})['pose'];p2=call('relative_pose',child={'frame':'camera_wrist'},parent={'frame':'world'})['pose']
def dot(a,b): return sum(x*y for x,y in zip(a,b))
def rot(q,v):
 x,y,z,w=q;u=[x,y,z];c=[y*v[2]-z*v[1],z*v[0]-x*v[2],x*v[1]-y*v[0]]
 return [2*dot(u,v)*u[i]+(w*w-dot(u,u))*v[i]+2*w*c[i] for i in range(3)]
def tri(uv1,uv2):
 d=rot(p1[3:],[(uv1[0]-127.5)/309.0193,(uv1[1]-127.5)/309.0193,1]);e=rot(p2[3:],[(uv2[0]-127.5)/166.81285,(uv2[1]-127.5)/166.81285,1]);v=[p2[i]-p1[i] for i in range(3)];aa=dot(d,d);bb=dot(d,e);cc=dot(e,e);dd=dot(d,v);ee=dot(e,v); t=(dd*cc-bb*ee)/(aa*cc-bb*bb);s=(bb*dd-aa*ee)/(aa*cc-bb*bb);a=[p1[i]+t*d[i] for i in range(3)];b=[p2[i]+s*e[i] for i in range(3)];print('xyz',[(a[i]+b[i])/2 for i in range(3)],'error',sum((a[i]-b[i])**2 for i in range(3))**0.5)
tri((132,146),(114,79));tri((198,189),(27,10));tri((180,126),(32,141))
