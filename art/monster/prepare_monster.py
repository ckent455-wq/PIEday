from pathlib import Path
import bpy
root=Path(__file__).resolve().parents[2]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(root/'art/monster/source.glb'))
# Remove the source game's non-character helper mesh, retaining the rig,
# textured body parts, and original animation clips.
for obj in list(bpy.context.scene.objects):
    if obj.type=='MESH' and obj.name.startswith('Icosphere'):
        bpy.data.objects.remove(obj,do_unlink=True)
for image in bpy.data.images:
    if image.source=='FILE': image.pack()
material=bpy.data.materials.new('Yard stalker textured skin and clothing')
material.use_nodes=True
bsdf=material.node_tree.nodes.get('Principled BSDF')
bsdf.inputs['Roughness'].default_value=.95
bsdf.inputs['Metallic'].default_value=0
texture=material.node_tree.nodes.new('ShaderNodeTexImage')
texture.image=bpy.data.images.load(str(root/'art/monster/zombie_color.png'))
texture.image.pack()
texture.interpolation='Closest'
material.node_tree.links.new(texture.outputs['Color'],bsdf.inputs['Base Color'])
for obj in bpy.context.scene.objects:
    if obj.type=='MESH':
        obj.data.materials.clear()
        obj.data.materials.append(material)
        for face in obj.data.polygons: face.material_index=0
bpy.ops.object.select_all(action='SELECT')
bpy.ops.wm.save_as_mainfile(filepath=str(root/'art/monster/yard_stalker.blend'))
bpy.ops.export_scene.gltf(filepath=str(root/'assets/monster/yard_stalker.glb'),export_format='GLB',use_selection=True,export_animations=True)
print('PREPARED_ANIMATED_YARD_MONSTER')
