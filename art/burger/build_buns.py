import bpy,math,random,os
import numpy as np
from mathutils import Vector
base=os.getcwd();out=os.path.join(base,'assets','burger');random.seed(111)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
n=256;rng=np.random.default_rng(111);y,x=np.mgrid[:n,:n];noise=rng.random((n,n));smooth=np.sin(x*.17)*np.sin(y*.13)*.02
pixels=np.ones((n,n,4),np.float32);pixels[:,:,:3]=np.clip(np.array([.64,.30,.075])+((noise-.5)*.12+smooth)[...,None],0,1)
img=bpy.data.images.new('GoldenBunCrust256',width=n,height=n);img.pixels.foreach_set(pixels.ravel());img.filepath_raw=os.path.join(out,'bun_crust_albedo.png');img.file_format='PNG';img.save();img.pack()
crust=bpy.data.materials.new('Golden baked crust');crust.use_nodes=True;bs=crust.node_tree.nodes.get('Principled BSDF');bs.inputs['Roughness'].default_value=.65;tex=crust.node_tree.nodes.new('ShaderNodeTexImage');tex.image=img;tex.interpolation='Closest';crust.node_tree.links.new(tex.outputs['Color'],bs.inputs['Base Color'])
crumb=bpy.data.materials.new('Soft cut bread');crumb.diffuse_color=(.78,.61,.36,1)
edge=bpy.data.materials.new('Toasted rim');edge.diffuse_color=(.38,.16,.035,1)
seedmat=bpy.data.materials.new('Sesame');seedmat.diffuse_color=(.87,.76,.49,1)
for material in [crumb,edge,seedmat]:
 material.use_nodes=True;node=material.node_tree.nodes.get('Principled BSDF');node.inputs['Base Color'].default_value=material.diffuse_color;node.inputs['Roughness'].default_value=.8
def bun(name,profile):
 verts=[];faces=[];segments=48
 for r,z in profile:
  for i in range(segments):
   a=math.tau*i/segments;w=1+.009*math.sin(a*5)+.004*math.sin(a*11);verts.append((r*math.cos(a)*w,r*math.sin(a)*w,z))
 for j in range(len(profile)-1):
  for i in range(segments):
   a=j*segments+i;b=j*segments+(i+1)%segments;c=(j+1)*segments+(i+1)%segments;d=(j+1)*segments+i;faces.extend([(a,b,c),(a,c,d)])
 mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);mesh.update();obj=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(obj)
 for mat in [crust,crumb,edge]:mesh.materials.append(mat)
 uv=mesh.uv_layers.new(name='BunUV')
 for p in mesh.polygons:
  j=p.index//(segments*2);p.material_index=1 if j<2 or (name=="BurgerBun_Bottom" and j>=6) else 2 if j==2 else 0;p.use_smooth=j>=2
  for li in p.loop_indices:
   co=mesh.vertices[mesh.loops[li].vertex_index].co;uv.data[li].uv=(co.x/.16+.5,co.y/.16+.5)
 return obj
bottom=bun('BurgerBun_Bottom',[(0,.001),(.045,.001),(.066,.001),(.071,.004),(.073,.009),(.073,.014),(.070,.018),(.035,.018),(0,.018)])
# Flat cut underside, softly domed crown and a thin browned heel.
top=bun('BurgerBun_Top',[(0,0),(.04,0),(.066,0),(.071,.002),(.074,.006),(.075,.012),(.070,.022),(.057,.031),(.037,.036),(.018,.038),(0,.0385)])
seeds=[]
for i in range(38):
 a=random.random()*math.tau;r=math.sqrt(random.random())*.064;z=float(np.interp(r,[0,.018,.037,.057,.070,.075],[.0385,.038,.036,.031,.022,.012]))+.001
 bpy.ops.mesh.primitive_uv_sphere_add(segments=8,ring_count=4,location=(math.cos(a)*r,math.sin(a)*r,z));seed=bpy.context.object;seed.name='Sesame';seed.scale=(.0032,.00125,.0009);seed.rotation_euler=(0,0,random.random()*math.tau);seed.data.materials.append(seedmat);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);seeds.append(seed)
bpy.ops.object.select_all(action='DESELECT');top.select_set(True)
for s in seeds:s.select_set(True)
bpy.context.view_layer.objects.active=top;bpy.ops.object.join()
for obj,filename in [(top,'burger_bun_top.glb'),(bottom,'burger_bun_bottom.glb')]:
 bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);bpy.context.view_layer.objects.active=obj;bpy.ops.export_scene.gltf(filepath=os.path.join(out,filename),export_format='GLB',use_selection=True,export_yup=True)
# Left: complete burger. Right: bun halves opened to show the cut faces.
bottom.location.x=-.09;top.location=(-.09,0,.0405)
bpy.ops.import_scene.gltf(filepath=os.path.join(out,'burger_patty_cooked.glb'))
for obj in list(bpy.context.selected_objects):
 if obj.parent is None:obj.location=(-.09,0,.018)
for original,pos in [(bottom,(.09,0,0)),(top,(.09,.075,0))]:
 copy=original.copy();copy.data=original.data.copy();bpy.context.collection.objects.link(copy);copy.location=pos
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.001));mat=bpy.data.materials.new('PreviewBackdrop');mat.diffuse_color=(.045,.05,.06,1);bpy.context.object.data.materials.append(mat)
for at,power in [((-.12,-.2,.4),4),((.2,.12,.3),2)]:
 bpy.ops.object.light_add(type='AREA',location=at);o=bpy.context.object;o.data.energy=power;o.data.size=.3;o.rotation_euler=(Vector((0,0,.02))-o.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add(location=(.15,-.35,.30));cam=bpy.context.object;cam.rotation_euler=(Vector((0,.01,.025))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=.40
scene=bpy.context.scene;scene.camera=cam;scene.render.engine='CYCLES';scene.cycles.samples=24;scene.world.color=(.2,.2,.2);scene.render.resolution_x=1100;scene.render.resolution_y=700;scene.render.resolution_percentage=100;scene.render.filepath=os.path.join(base,'..','outputs','PIEday-burger-buns.png')
for area in bpy.context.screen.areas:
 if area.type=='VIEW_3D':area.spaces.active.region_3d.view_distance=.45;area.spaces.active.shading.type='MATERIAL'
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(base,'art','burger','burger_buns.blend'));bpy.ops.render.render(write_still=True)

