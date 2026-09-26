extends Node3D
# Small reusable mesh bundles: no imported model or per-frame allocations.
func build(world,kind:String):
 rotation=Vector3(-.12,-.35,0)
 if kind=="wood":
  for i in range(3):
   var pos=Vector3((i%2-.5)*.65,.3+int(i/2)*.55,0)
   var log=CylinderMesh.new();log.top_radius=.32;log.bottom_radius=.32;log.height=1.6;log.radial_segments=10
   var n=world.mesh_node(log,pos,world.material(Color("965526"),.75),self);n.rotation.x=PI/2
   for side in [-1,1]:
    var end=CylinderMesh.new();end.top_radius=.26;end.bottom_radius=.26;end.height=.02;end.radial_segments=10
    var cap=world.mesh_node(end,pos+Vector3(0,0,side*.81),world.material(Color("edc58c")),self);cap.rotation.x=PI/2
 elif kind=="stone":
  for i in range(3):
   var rock=SphereMesh.new();rock.radius=.53;rock.height=.88;rock.radial_segments=5;rock.rings=2
   var n=world.mesh_node(rock,Vector3((i%2-.5)*.65,int(i/2)*.55,0),world.material(Color("acbfd1"),.6),self);n.rotation=Vector3(i*.7,i*.8,.2)
 else:
  for i in range(7):
   var coin=CylinderMesh.new();coin.top_radius=.42;coin.bottom_radius=.42;coin.height=.16;coin.radial_segments=16
   var m=world.material(Color("ffc23c"),.28);m.metallic=.55
   world.mesh_node(coin,Vector3((i%2-.5)*.64,int(i/2)*.19,0),m,self)
