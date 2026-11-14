"""Pose WRAD ARMS with its authored IK rig and bake viewmodel meshes."""
from pathlib import Path
import bpy, math
from mathutils import Matrix, Vector
ROOT=Path(__file__).resolve().parents[2]
HERE=ROOT/'art/player_arms'
OUT=ROOT/'assets/player_arms'
OUT.mkdir(parents=True,exist_ok=True)
for mode in ['support','single','grip']:
 bpy.ops.wm.open_mainfile(filepath=str(HERE/'arms.blend'))
 rig=next(o for o in bpy.data.objects if o.type=='ARMATURE')
 body=next(o for o in bpy.data.objects if o.type=='MESH')
 for side,sign in [('r',1),('l',-1)]:
  target=rig.pose.bones['wrist_ik.'+side]
  rotation=Matrix.Rotation(-math.pi/2,4,'Y') if mode=='grip' and side=='r' else Matrix.Identity(4)
  rotation.translation=Vector((sign*1.40,3.55,-1.20))
  if mode=='grip' and side=='r': rotation.translation=Vector((2.6,3.65,-.62))
  if mode!='support' and side=='l': rotation.translation=Vector((-4,0,-5))
  target.matrix=rotation
  pole=rig.pose.bones.get('arm_target.'+side)
  if pole:
   m=pole.matrix.copy();m.translation=Vector((sign*6,0,-3));pole.matrix=m
  for bone in rig.pose.bones:
   if bone.name.startswith('finger_') and bone.name.endswith('.'+side):
    bone.rotation_mode='XYZ'
    bone.rotation_euler.x += (.68 if mode=='grip' and side=='r' and 'thumb' not in bone.name else .12)
 bpy.context.view_layer.update()
 deps=bpy.context.evaluated_depsgraph_get()
 mesh=bpy.data.meshes.new_from_object(body.evaluated_get(deps),depsgraph=deps)
 baked=bpy.data.objects.new('PlayerArms_'+mode,mesh)
 bpy.context.collection.objects.link(baked)
 for vertex in mesh.vertices:
  vertex.co*=.12
  vertex.co.z-=.18
 mat=bpy.data.materials.new('ArmSkin')
 mat.use_nodes=True
 shader=mat.node_tree.nodes.get('Principled BSDF')
 shader.inputs['Roughness'].default_value=.95
 tex=mat.node_tree.nodes.new('ShaderNodeTexImage')
 tex.image=bpy.data.images.load(str(HERE/'arm_albedo_pale.png'))
 tex.interpolation='Closest'
 tex.image.pack()
 mat.node_tree.links.new(tex.outputs['Color'],shader.inputs['Base Color'])
 mesh.materials.clear();mesh.materials.append(mat)
 for obj in list(bpy.data.objects):
  if obj!=baked: bpy.data.objects.remove(obj,do_unlink=True)
 bpy.ops.wm.save_as_mainfile(filepath=str(HERE/(mode+'.blend')))
 bpy.ops.export_scene.gltf(filepath=str(OUT/(mode+'.glb')),export_format='GLB',export_animations=False,export_yup=True)
 print('BAKED',mode,flush=True)
