import bpy, math, random, os
import numpy as np
from mathutils import Vector
random.seed(41);rng=np.random.default_rng(41)
base=os.getcwd();assets=os.path.join(base,'assets','burger')
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
n=256;y,x=np.mgrid[:n,:n]
def noise(size):
 a=rng.random((size,size));xx=x/n*size;yy=y/n*size;ix=xx.astype(int);iy=yy.astype(int);fx=xx-ix;fy=yy-iy
 return a[iy%size,ix%size]*(1-fx)*(1-fy)+a[iy%size,(ix+1)%size]*fx*(1-fy)+a[(iy+1)%size,ix%size]*(1-fx)*fy+a[(iy+1)%size,(ix+1)%size]*fx*fy
v=noise(16)*.4+noise(60)*.4+rng.random((n,n))*.2
fat=np.zeros((n,n))
for i in range(750):
 cx,cy=rng.uniform(0,n,2);rx,ry=rng.uniform(.6,2.1,2);fat=np.maximum(fat,np.clip((1-((x-cx)/rx)**2-((y-cy)/ry)**2)*2,0,1))
segments=48;verts=[];faces=[]
profile=[(0,.001),(.4,.001),(.8,.001),(.96,.003),(1,.007),(1,.014),(.95,.019),(.8,.021),(.6,.022),(.4,.0225),(.2,.022),(0,.022)]
for j,(r,z) in enumerate(profile):
 for i in range(segments):
  a=math.tau*i/segments;rad=.062*r*(1+.018*math.sin(i*.91)+.014*math.sin(i*2.7));verts.append((rad*math.cos(a),rad*math.sin(a),max(0,z+(random.random()-.5)*.0012*r)))
for j in range(len(profile)-1):
 for i in range(segments):
  a=j*segments+i;b=j*segments+(i+1)%segments;c=(j+1)*segments+(i+1)%segments;d=(j+1)*segments+i;faces.extend([(a,b,c),(a,c,d)])
mesh=bpy.data.meshes.new('HandPressedPatty');mesh.from_pydata(verts,[],faces);mesh.update();uv=mesh.uv_layers.new(name='PattyUV')
for p in mesh.polygons:
 for li in p.loop_indices:
  co=mesh.vertices[mesh.loops[li].vertex_index].co;uv.data[li].uv=(co.x/.132+.5,co.y/.132+.5)
objects=[]
for kind in ['raw','cooked']:
 dark=np.array([.29,.055,.065]) if kind=='raw' else np.array([.095,.035,.017]);light=np.array([.74,.25,.28]) if kind=='raw' else np.array([.43,.22,.105]);fatcolor=np.array([.91,.70,.63]) if kind=='raw' else np.array([.62,.40,.21])
 rgb=dark+(light-dark)*np.clip(v*1.35-.14,0,1)[...,None];rgb=rgb*(1-fat[...,None]*.65)+fatcolor*fat[...,None]*.65
 if kind=='cooked':rgb*=1-np.clip((.20-np.abs(np.sin((x*.79+y*.61)/12)))*7,0,.8)[...,None]*.7
 pixels=np.ones((n,n,4),np.float32);pixels[:,:,:3]=rgb
 image=bpy.data.images.new('Patty_'+kind+'_256',width=n,height=n);image.pixels.foreach_set(pixels.ravel());image.filepath_raw=os.path.join(assets,'patty_'+kind+'_albedo.png');image.file_format='PNG';image.save();image.pack()
 obj=bpy.data.objects.new('BurgerPatty_'+kind,mesh.copy());bpy.context.collection.objects.link(obj)
 mat=bpy.data.materials.new('Beef_'+kind);mat.use_nodes=True;bs=mat.node_tree.nodes.get('Principled BSDF');bs.inputs['Roughness'].default_value=.70
 tex=mat.node_tree.nodes.new('ShaderNodeTexImage');tex.image=image;tex.interpolation='Closest';mat.node_tree.links.new(tex.outputs['Color'],bs.inputs['Base Color']);obj.data.materials.append(mat)
 for p in obj.data.polygons:p.use_smooth=True
 obj['state']=kind;obj['origin']='bottom center';objects.append(obj)
 bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);bpy.context.view_layer.objects.active=obj
 bpy.ops.export_scene.gltf(filepath=os.path.join(assets,'burger_patty_'+kind+'.glb'),export_format='GLB',use_selection=True,export_yup=True)
objects[0].location.x=-.079;objects[1].location.x=.079
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.001));floor=bpy.context.object;floor.name='PreviewBackdrop';mat=bpy.data.materials.new('Backdrop');mat.diffuse_color=(.055,.068,.075,1);floor.data.materials.append(mat)
for at,energy,size in [((-.15,-.15,.35),3,.25),((.2,.1,.25),2,.2)]:
 bpy.ops.object.light_add(type='AREA',location=at);light=bpy.context.object;light.data.energy=energy;light.data.shape='DISK';light.data.size=size;light.rotation_euler=(Vector((0,0,0))-light.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add(location=(.14,-.30,.30));cam=bpy.context.object;cam.rotation_euler=(Vector((0,0,.01))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=.37
scene=bpy.context.scene;scene.camera=cam;scene.render.engine='CYCLES';scene.cycles.samples=24;scene.world.color=(.3,.3,.3);scene.render.resolution_x=1100;scene.render.resolution_y=700;scene.render.resolution_percentage=100;scene.view_settings.view_transform='AgX';scene.render.filepath=os.path.join(base,'..','outputs','PIEday-burger-patties.png')
for area in bpy.context.screen.areas:
 if area.type=='VIEW_3D':area.spaces.active.region_3d.view_distance=.42;area.spaces.active.region_3d.view_location=Vector((0,0,.01));area.spaces.active.shading.type='MATERIAL'
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(base,'art','burger','burger_patties.blend'));bpy.ops.render.render(write_still=True);print('PATTIES_DONE',len(faces),'triangles each')

