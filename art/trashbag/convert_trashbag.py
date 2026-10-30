"""Convert the user-provided FBX bags to portable Godot GLBs using Blender."""
from pathlib import Path
import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'art' / 'trashbag' / 'source'
for variant in ['A', 'B']:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=str(SOURCE / ('Retro PSX Trash bag ' + variant + '.fbx')))
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == 'MESH']
    points = [obj.matrix_world @ Vector(corner) for obj in meshes for corner in obj.bound_box]
    low = Vector(tuple(min(p[i] for p in points) for i in range(3)))
    high = Vector(tuple(max(p[i] for p in points) for i in range(3)))
    origin = Vector(((low.x + high.x) / 2, (low.y + high.y) / 2, low.z))
    scale = 0.55 / (high.z - low.z)
    material = bpy.data.materials.new('PSX black trash bag')
    material.use_nodes = True
    bsdf = material.node_tree.nodes.get('Principled BSDF')
    bsdf.inputs['Roughness'].default_value = 0.72
    texture = material.node_tree.nodes.new('ShaderNodeTexImage')
    texture.image = bpy.data.images.load(str(SOURCE / 'Trash Bag Black Texture.png'))
    texture.image.pack()
    texture.interpolation = 'Closest'
    material.node_tree.links.new(texture.outputs['Color'], bsdf.inputs['Base Color'])
    bpy.ops.object.select_all(action='DESELECT')
    for obj in meshes:
        world = obj.matrix_world.copy()
        for vertex in obj.data.vertices:
            vertex.co = (world @ vertex.co - origin) * scale
        obj.parent = None
        obj.matrix_world.identity()
        obj.data.materials.clear()
        obj.data.materials.append(material)
        for polygon in obj.data.polygons: polygon.material_index = 0
        obj.select_set(True)
    bpy.ops.export_scene.gltf(filepath=str(ROOT / 'assets' / 'trashbag' / ('trashbag_' + variant.lower() + '.glb')), use_selection=True, export_format='GLB')
    print('TRASHBAG_EXPORTED', variant, 'height 0.55m')
