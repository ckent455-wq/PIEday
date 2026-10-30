"""Convert downloaded PSX rigs to six regular customers and one refusal encounter.
Run with Blender --factory-startup -b --python art/customer_psx/build_customers.py.
Control rigs stay in source; exported meshes retain the original deform weights.
"""
import bpy, sys
from pathlib import Path
from mathutils import Vector

HERE = Path(__file__).resolve().parent
SOURCE = HERE / 'source'
OUT = HERE.parents[1] / 'assets' / 'customers'
OUT.mkdir(parents=True, exist_ok=True)
RENAME = {'DEF-upper_arm.L':'Arm_L', 'DEF-upper_arm.R':'Arm_R',
          'DEF-thigh.L':'Leg_L', 'DEF-thigh.R':'Leg_R'}
VARIANTS = [
 ('adult_unclothed','male_nude','m',1,'male_body_cauc_D.png'),
 ('male_1','male_pants', 'm',1,'M_NPC_pants1.png'),
 ('male_2','male_pants', 'm',2,'M_NPC_pants2.png'),
 ('male_3','male_pants', 'm',3,'M_NPC_pants3.png'),
 ('female_1','female_pants','f',1,'scrubs_F_D.png'),
 ('female_2','female_skirt','f',2,'F_NPC_skirt1.png'),
 ('female_3','female_skirt','f',3,'F_NPC_skirt3.png'),
]

def texture_material(name, path):
 mat=bpy.data.materials.new(name)
 mat.use_nodes=True
 bsdf=mat.node_tree.nodes.get('Principled BSDF')
 bsdf.inputs['Roughness'].default_value=0.95
 image=bpy.data.images.load(str(path), check_existing=False)
 image.scale(256,256)
 image.pack()
 tex=mat.node_tree.nodes.new('ShaderNodeTexImage')
 tex.image=image
 tex.interpolation='Closest'
 mat.node_tree.links.new(tex.outputs['Color'],bsdf.inputs['Base Color'])
 return mat

def bounds(obj):
 points=[obj.matrix_world @ Vector(p) for p in obj.bound_box]
 return Vector(tuple(min(p[i] for p in points) for i in range(3))), Vector(tuple(max(p[i] for p in points) for i in range(3)))

for variant,base,gender,index,clothes in VARIANTS:
 if '--' in sys.argv and variant not in sys.argv[sys.argv.index('--')+1:]:
  continue
 bpy.ops.wm.open_mainfile(filepath=str(SOURCE/(base+'_rigged.blend')))
 original=bpy.data.objects['rig']
 original.data.pose_position='REST'
 body=next(o for o in bpy.data.objects if o.type=='MESH' and '_body_' in o.name)
 old_head=next(o for o in bpy.data.objects if o.type=='MESH' and '_head_' in o.name)
 head_lo,head_hi=bounds(old_head)
 # Build a clean deform-only armature from the rig's rest matrices.
 deform=[b for b in original.data.bones if b.use_deform and b.name.startswith('DEF-')]
 data=bpy.data.armatures.new('CustomerSkeleton')
 rig=bpy.data.objects.new('CustomerRig',data)
 bpy.context.collection.objects.link(rig)
 bpy.context.view_layer.objects.active=rig
 rig.select_set(True)
 bpy.ops.object.mode_set(mode='EDIT')
 for bone in deform:
  new=data.edit_bones.new(RENAME.get(bone.name,bone.name))
  new.head=original.matrix_world @ bone.head_local
  new.tail=original.matrix_world @ bone.tail_local
  new.align_roll((original.matrix_world @ bone.matrix_local).to_3x3().col[2])
 for bone in deform:
  parent=bone.parent
  while parent and parent not in deform: parent=parent.parent
  if parent: data.edit_bones[RENAME.get(bone.name,bone.name)].parent=data.edit_bones[RENAME.get(parent.name,parent.name)]
 bpy.ops.object.mode_set(mode='OBJECT')
 world=body.matrix_world.copy()
 body.parent=None
 body.matrix_world=world
 body.modifiers.clear()
 for group in body.vertex_groups:
  group.name=RENAME.get(group.name,group.name)
 body.parent=rig
 mod=body.modifiers.new('Skin','ARMATURE')
 mod.object=rig
 body.data.materials.clear()
 body.data.materials.append(texture_material('Clothes',SOURCE/clothes))
 # The new head meshes share the pack's UV layout. Align the neck/head volume
 # to the original head, then bind it to the existing head bone.
 # The bob-cut female head has a clean neck seam with both clothing bases.
 geometry_index = 2 if gender == 'f' else index
 bpy.ops.import_scene.fbx(filepath=str(SOURCE/f'{gender}_head{geometry_index}.fbx'))
 head=next(o for o in bpy.context.selected_objects if o.type=='MESH')
 lo,hi=bounds(head)
 ratio=(head_hi.z-head_lo.z)/(hi.z-lo.z)
 center=(lo+hi)*0.5
 target=(head_lo+head_hi)*0.5
 world=head.matrix_world.copy()
 for vertex in head.data.vertices:
  vertex.co=(world @ vertex.co-center)*ratio+target
 head.matrix_world.identity()
 head.modifiers.clear()
 head.vertex_groups.clear()
 group=head.vertex_groups.new(name='DEF-spine.006')
 group.add(list(range(len(head.data.vertices))),1.0,'REPLACE')
 head.parent=rig
 mod=head.modifiers.new('Skin','ARMATURE')
 mod.object=rig
 head.data.materials.clear()
 face_index = 9 if variant == 'female_3' else index
 head.data.materials.append(texture_material('Face',SOURCE/f'head_{gender.upper()}_D{face_index}.png'))
 head.data.validate()
 head.data.update()
 keep={body,head,rig}
 for obj in list(bpy.data.objects):
  if obj not in keep: bpy.data.objects.remove(obj,do_unlink=True)
 bpy.ops.object.select_all(action='SELECT')
 bpy.context.view_layer.objects.active=rig
 bpy.ops.export_scene.gltf(filepath=str(OUT/(variant+'.glb')),export_format='GLB',
  use_selection=True,export_animations=False,export_def_bones=True,
  export_yup=True,export_image_format='AUTO')
 print('EXPORTED',variant, 'BONES',len(data.bones),flush=True)
