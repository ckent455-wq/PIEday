import bpy
import math
from mathutils import Vector
from pathlib import Path

root = Path.cwd()
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)

# Broad, asymmetric leaf with a pinched stem and curled, scalloped edges.
segments = 48
rings = 7
vertices = [(0, 0, 0)]
colors = [(0.25, 0.53, 0.07, 1)]
for ring in range(1, rings + 1):
    r = ring / rings
    for i in range(segments):
        a = math.tau * i / segments
        fringe = 1 + r**4 * (0.105*math.sin(11*a) + 0.062*math.sin(17*a+0.8) + 0.07*math.sin(5*a))
        x = 0.073*r*math.cos(a)*fringe*(0.85+0.15*math.sin(a))
        y = 0.076*r*math.sin(a)*fringe
        z = 0.004*r*r + 0.007*r**4*math.sin(9*a+0.6) + 0.003*r*math.sin(16*x/0.073+5*y/0.076)
        vertices.append((x,y,z))
        pale = math.exp(-abs(x)/0.017) * (0.7-0.3*math.sin(a))
        mottling = 0.035*math.sin(23*a+5*r)*r
        colors.append((0.065+0.36*pale+mottling, 0.30+0.29*pale+0.12*r+mottling, 0.022+0.085*pale,1))
faces = [(0,1+i,1+(i+1)%segments) for i in range(segments)]
for ring in range(rings-1):
    for i in range(segments):
        a = 1+ring*segments+i
        b = 1+ring*segments+(i+1)%segments
        faces.append((a,a+segments,b+segments,b))
mesh = bpy.data.meshes.new('Ruffled leaf')
mesh.from_pydata(vertices,[],faces)
mesh.update()
leaf = bpy.data.objects.new('Crisp lettuce leaf',mesh)
bpy.context.collection.objects.link(leaf)
palette = [(0.055,0.22,0.015),(0.085,0.34,0.025),(0.13,0.44,0.037),(0.21,0.51,0.06),(0.33,0.58,0.095)]
for i, shade in enumerate(palette):
    mat = bpy.data.materials.new('Leaf green %d' % i)
    mat.use_nodes = True
    shader = mat.node_tree.nodes.get('Principled BSDF')
    shader.inputs['Base Color'].default_value = (*shade,1)
    shader.inputs['Roughness'].default_value = 0.58
    mesh.materials.append(mat)
for face in mesh.polygons:
    greenness = sum(colors[i][1] for i in face.vertices)/len(face.vertices)
    face.material_index = min(4,max(0,round((greenness-0.30)*13)))
    face.use_smooth = True

rib_material = bpy.data.materials.new('Pale lettuce veins')
rib_material.use_nodes = True
rib_material.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value = (0.36,0.55,0.14,1)
def vein(points, radius):
    curve = bpy.data.curves.new('Leaf vein','CURVE')
    curve.dimensions = '3D'
    curve.bevel_depth = radius
    curve.bevel_resolution = 0
    spline = curve.splines.new('POLY')
    spline.points.add(len(points)-1)
    for i,(point, xyz) in enumerate(zip(spline.points,points)):
        point.co = (*xyz,1)
        point.radius = 1.0-0.8*i/(len(points)-1)
    obj = bpy.data.objects.new('Leaf vein',curve)
    bpy.context.collection.objects.link(obj)
    obj.parent = leaf
    curve.materials.append(rib_material)
vein([(0,-0.073,0.004),(0,-0.046,0.004),(0,0,0.002),(0.001,0.035,0.004),(0.003,0.063,0.004)],0.0016)
for side in [-1,1]:
    for y in [-0.041,-0.021,0,0.019,0.035]:
        vein([(0,y,0.003),(side*0.016,y+0.009,0.003),(side*0.035,y+0.017,0.004),(side*0.049,y+0.022,0.004)],0.00065)

bpy.ops.object.select_all(action='SELECT')
bpy.context.view_layer.objects.active = leaf
bpy.ops.wm.save_as_mainfile(filepath=str(root/'art/burger/lettuce_leaf.blend'))
bpy.ops.export_scene.gltf(filepath=str(root/'assets/burger/lettuce_leaf.glb'),export_format='GLB',use_selection=True,export_yup=True)
