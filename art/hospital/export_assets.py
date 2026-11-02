"""Export the downloaded hospital kit with portable, low resolution materials."""
import bpy, math
from pathlib import Path
from mathutils import Vector, Matrix
ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'art/hospital/source/Hospital_assets'
OUT = ROOT / 'assets/hospital'
OUT.mkdir(parents=True, exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(SOURCE / 'hospital.blend'))
maps = {
 'Bed':'bed', 'Chairs_tables_1':'Chairs_table_1', 'Ceiling_light':'Ceiling_light',
 'Ceiling_1':'ceiling_1', 'Door_mat':'Door_1', 'Exit_sign':'exit_sign',
 'Floors_1':'Floors_1', 'IV_bag':'Iv_bag', 'IV_Pole':'Iv_pole',
 'Magazine':'Magazine', 'Walls_1':'Walls_1', 'Doorway_1':'Doorway_1',
 'Wheel_chair':'wheel_chair', 'Phone_ExitSign':'exit_sign',
}
for mat in bpy.data.materials:
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    nodes.clear()
    output = nodes.new('ShaderNodeOutputMaterial')
    shader = nodes.new('ShaderNodeBsdfPrincipled')
    shader.inputs['Roughness'].default_value = .9
    mat.node_tree.links.new(shader.outputs['BSDF'], output.inputs['Surface'])
    folder = SOURCE / 'textures' / maps.get(mat.name, '__none__')
    files = list(folder.glob('*Base*')) if folder.exists() else []
    if files:
        image = bpy.data.images.load(str(files[0]), check_existing=True)
        image.scale(256,256)
        image.pack()
        tex = nodes.new('ShaderNodeTexImage')
        tex.image = image
        tex.interpolation = 'Closest'
        mat.node_tree.links.new(tex.outputs['Color'], shader.inputs['Base Color'])
    else:
        shader.inputs['Base Color'].default_value = (.17,.24,.25,1) if mat.name == 'Window' else (.5,.55,.5,1)
names = ['Bed','Cabinet_1','Cabinet_2','Cabinet_3','Ceiling_Light','Ceiling_Tile',
 'Chair','Door_1','Exit_sign','Floor_tile_1','IV_bag','Iv_bag_holder',
 'Landline_phone','Magazine','Tile_Wall','Tile_Wall_Window','Wheel_chair']
for name in names:
    original = bpy.data.objects[name]
    obj = original.copy()
    obj.data = original.data.copy()
    obj.parent = None
    bpy.context.collection.objects.link(obj)
    world = original.matrix_world.copy()
    # Bake the source world transform; the kit contains unapplied rotations.
    upright = Matrix.Identity(4)
    coords = [upright @ (world @ v.co) for v in obj.data.vertices]
    low = Vector(tuple(min(v[i] for v in coords) for i in range(3)))
    high = Vector(tuple(max(v[i] for v in coords) for i in range(3)))
    offset = Vector(((low.x+high.x)/2, (low.y+high.y)/2, low.z))
    for v, co in zip(obj.data.vertices, coords): v.co = co - offset
    obj.matrix_world = Matrix.Identity(4)
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.export_scene.gltf(filepath=str(OUT / (name+'.glb')), export_format='GLB', use_selection=True, export_animations=False)
    bpy.data.objects.remove(obj, do_unlink=True)
    print('EXPORTED',name, list(high-low))
