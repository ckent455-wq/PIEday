import bpy
import math
from pathlib import Path

root = Path.cwd()
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
mat = bpy.data.materials.new('Golden American cheese')
mat.use_nodes = True
shader = mat.node_tree.nodes.get('Principled BSDF')
shader.inputs['Base Color'].default_value = (0.89, 0.39, 0.038, 1)
shader.inputs['Roughness'].default_value = 0.42

edge = bpy.data.materials.new('Cheese slice edge')
edge.use_nodes = True
edge_shader = edge.node_tree.nodes.get('Principled BSDF')
edge_shader.inputs['Base Color'].default_value = (0.49, 0.17, 0.018, 1)
edge_shader.inputs['Roughness'].default_value = 0.48

for name, draped in [('cheese_slice', False), ('cheese_draped', True)]:
    grid = 13
    vertices = []
    for row in range(grid):
        for column in range(grid):
            x = (column/(grid-1)*2-1)*0.054
            y = (row/(grid-1)*2-1)*0.054
            cx = math.copysign(min(abs(x),0.049),x)
            cy = math.copysign(min(abs(y),0.049),y)
            dx, dy = x-cx,y-cy
            length = math.hypot(dx,dy)
            if length > 0.005:
                x = cx+dx*0.005/length
                y = cy+dy*0.005/length
            z = 0.002 + 0.0018*(x/0.054)**2*math.sin(23*y+0.4)
            if draped:
                z -= min(0.011,max(0,math.hypot(x,y)-0.057)*0.65)
            vertices.append((x,y,z))
    faces = []
    for row in range(grid-1):
        for column in range(grid-1):
            i = row*grid+column
            faces.append((i,i+1,i+grid+1,i+grid))
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(vertices,[],faces)
    mesh.update()
    obj = bpy.data.objects.new(name,mesh)
    bpy.context.collection.objects.link(obj)
    mesh.materials.append(mat)
    if not draped:
        mesh.materials.append(edge)
    for face in mesh.polygons:
        face.use_smooth = True
    thickness = obj.modifiers.new('Thin cheese edge','SOLIDIFY')
    thickness.thickness = 0.0023
    thickness.offset = -1
    if not draped:
        thickness.material_offset_rim = 1
    bevel = obj.modifiers.new('Soft cut edges','BEVEL')
    bevel.width = 0.00055
    bevel.segments = 2
    bevel.limit_method = 'ANGLE'
    if not draped:
        bevel.material = 1
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.export_scene.gltf(filepath=str(root/'assets/burger'/f'{name}.glb'),export_format='GLB',use_selection=True,export_yup=True,export_apply=True)
    obj.location.x = 0.145 if draped else 0

bpy.ops.wm.save_as_mainfile(filepath=str(root/'art/burger/cheese_slices.blend'))
