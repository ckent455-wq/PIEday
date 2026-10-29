import bpy, math
from mathutils import Vector
from pathlib import Path
out=Path(__file__).resolve().parent
bpy.ops.wm.open_mainfile(filepath=str(Path(__file__).resolve().parent/'source'/'Humanoid.blend'))
source=bpy.data.objects['HumanoidBase_NotOverlapping']
for obj in list(bpy.data.objects):
    if obj != source:
        bpy.data.objects.remove(obj,do_unlink=True)
palette=[('Skin',(.48,.28,.17)),('Shirt',(.10,.28,.32)),('Denim',(.055,.08,.13)),('Shoes',(.035,.025,.02)),('Hair',(.055,.027,.012))]
mats=[]
for name,color in palette:
    mat=bpy.data.materials.new(name)
    mat.diffuse_color=(*color,1)
    mat.use_nodes=True
    mat.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=(*color,1)
    mat.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value=.9
    mats.append(mat)
# Deform the existing A-pose once, per vertex, keeping every shoulder connected.
original = [v.co.copy() for v in source.data.vertices]
def arm_weight(v):
    if v.z < 1.0: return 0.0
    t=max(0.0,min(1.0,(abs(v.x)-.17)/.10))
    return t*t*(3-2*t)
for vertex, old in zip(source.data.vertices, original):
    w=arm_weight(old)
    if w:
        side=1 if old.x>0 else -1
        pivot=Vector((side*.18,0,1.45))
        theta=math.radians(38*side*w)
        dx,dz=old.x-pivot.x,old.z-pivot.z
        vertex.co.x=pivot.x+math.cos(theta)*dx+math.sin(theta)*dz
        vertex.co.z=pivot.z-math.sin(theta)*dx+math.cos(theta)*dz
source.data.update()
source.name='Customer_Continuous_Body'
source.location=Vector((0,0,0))
source.data.materials.clear()
for mat in mats: source.data.materials.append(mat)
for face in source.data.polygons:
    old=sum((original[i] for i in face.vertices),Vector())/len(face.vertices)
    material=0
    if old.z<.11: material=3
    elif old.z<.94: material=2
    elif old.z<1.5 and (abs(old.x)<.37): material=1
    elif old.z>1.715: material=4
    face.material_index=material
    face.use_smooth=False
# A true skin rig replaces the disconnected rigid arm pieces.
rig_data=bpy.data.armatures.new('CustomerSkeleton')
rig=bpy.data.objects.new('CustomerRig',rig_data)
bpy.context.scene.collection.objects.link(rig)
bpy.context.view_layer.objects.active=rig
rig.select_set(True)
bpy.ops.object.mode_set(mode='EDIT')
body=rig_data.edit_bones.new('Body')
body.head=(0,0,0)
body.tail=(0,0,1)
for name,head,tail in [
 ('Arm_L',(-.18,0,1.45),(-.40,0,.75)),
 ('Arm_R',(.18,0,1.45),(.40,0,.75)),
 ('Leg_L',(-.10,0,.88),(-.10,0,.12)),
 ('Leg_R',(.10,0,.88),(.10,0,.12))]:
    bone=rig_data.edit_bones.new(name)
    bone.head=head; bone.tail=tail; bone.parent=body
bpy.ops.object.mode_set(mode='OBJECT')
for name in ['Body','Arm_L','Arm_R','Leg_L','Leg_R']: source.vertex_groups.new(name=name)
for index, old in enumerate(original):
    weights={}
    w=arm_weight(old)
    if w>0:
        weights['Arm_R' if old.x>0 else 'Arm_L']=w
        weights['Body']=1-w
    elif old.z<.94:
        w=max(0,min(1,(.94-old.z)/.15))
        weights['Leg_R' if old.x>0 else 'Leg_L']=w
        weights['Body']=1-w
    else: weights['Body']=1
    for name,weight in weights.items():
        if weight>0: source.vertex_groups[name].add([index],weight,'REPLACE')
modifier=source.modifiers.new('Connected skeletal deformation','ARMATURE')
modifier.object=rig
source.parent=rig
# Small eyes make the customer's facing direction readable at the counter.
for x in [-.043,.043]:
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=.012,location=(x,-.149,1.655))
    bpy.context.object.name='Eye'
    bpy.context.object.data.materials.append(mats[3])
bpy.ops.object.select_all(action='SELECT')
bpy.ops.wm.save_as_mainfile(filepath=str(out/'customer.blend'))
bpy.ops.export_scene.gltf(filepath=str(out.parents[1]/'assets'/'customer'/'customer.glb'),use_selection=True,export_format='GLB')
print('CUSTOMER_EXPORTED_FROM_USER_HUMANOID')
