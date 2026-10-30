"""Rebuild the user's clipboard reference as geometry; export for Godot."""
from pathlib import Path
from math import sin, cos, pi
import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
bpy.ops.wm.read_factory_settings(use_empty=True)
model = bpy.data.collections.new('Clipboard model')
bpy.context.scene.collection.children.link(model)

def mat(name, color, metal=0, rough=.7):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    m.diffuse_color = (*color, 1)
    p = m.node_tree.nodes.get('Principled BSDF')
    p.inputs['Base Color'].default_value = (*color, 1)
    p.inputs['Metallic'].default_value = metal
    p.inputs['Roughness'].default_value = rough
    return m

wood = mat('Brown fiberboard', (.34,.17,.075), rough=.9)
paper = mat('Warm white paper', (.88,.86,.79), rough=.92)
blue = mat('Faint blue ruled lines', (.34,.53,.64))
red = mat('Red margin line', (.63,.26,.23))
chrome = mat('Brushed silver clip', (.76,.78,.80), .35, .30)
dark = mat('Clip recess', (.13,.14,.14), .5, .4)
ink = mat('Printed heading', (.13,.17,.19))

def finish(obj, name, material):
    obj.name = name
    for c in list(obj.users_collection): c.objects.unlink(obj)
    model.objects.link(obj)
    obj.data.materials.append(material)
    return obj

def cube(name, at, size, material, bevel=0):
    bpy.ops.mesh.primitive_cube_add(size=1, location=at)
    obj = bpy.context.object
    obj.dimensions = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    finish(obj,name,material)
    if bevel:
        mod = obj.modifiers.new('Soft edges','BEVEL')
        mod.width = bevel
        mod.segments = 3
        obj.modifiers.new('Weighted normals','WEIGHTED_NORMAL')
    return obj

def outline(name, points, y, thickness, material):
    n=len(points)
    verts=[(x,y+dy,z) for dy in [-thickness/2,thickness/2] for x,z in points]
    faces=[tuple(range(n-1,-1,-1)), tuple(range(n,n*2))]
    faces += [(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    data=bpy.data.meshes.new(name)
    data.from_pydata(verts,[],faces)
    data.update()
    obj=bpy.data.objects.new(name,data)
    model.objects.link(obj)
    data.materials.append(material)
    return obj

def rounded(name,width,height,radius,y,thickness,material):
    points=[]
    for x,z,start in [(width/2-radius,height/2-radius,0),(-width/2+radius,height/2-radius,90),(-width/2+radius,-height/2+radius,180),(width/2-radius,-height/2+radius,270)]:
        for i in range(7):
            angle=(start+i*15)*pi/180
            points.append((x+radius*cos(angle), z+radius*sin(angle)))
    return outline(name,points,y,thickness,material)

rounded('Rounded brown backing',.46,.68,.027,0,.016,wood)
for i in range(3):
    sheet=rounded('Paper sheet %d'%i,.417,.612,.008,-.010-i*.0012,.001,paper)
    sheet.location.z=-.012+i*.003
    sheet.rotation_euler.y=0 if i==2 else (i-0.5)*.008

# Fine geometric lines stay crisp and portable without a billboard image.
for i in range(29):
    cube('Blue ruled line %02d'%i,(.001,-.017,.227-i*.018),(.408,.0003,.0018),blue)
cube('Red left margin',(-.149,-.0173,-.028),(.002,.0003,.562),red)

outline('Spring clip arched plate',[(-.15,.282),(-.151,.309),(-.101,.326),(-.054,.348),(-.028,.387),(.028,.387),(.054,.348),(.101,.326),(.151,.309),(.15,.282)],-.028,.009,chrome)
cube('Rolled clamping lip',(0,-.041,.284),(.306,.025,.018),chrome,.008)
cube('Clip shadow',(0,-.018,.277),(.275,.006,.004),dark)
bpy.ops.mesh.primitive_torus_add(major_radius=.022,minor_radius=.005,major_segments=32,minor_segments=8,location=(0,-.035,.383),rotation=(pi/2,0,0))
finish(bpy.context.object,'Hanging ring',chrome)
for x in [-.118,.118]:
    cube('Folded mounting tab',(x,-.025,.320),(.044,.015,.038),chrome,.004)
    bpy.ops.mesh.primitive_uv_sphere_add(segments=12,ring_count=6,radius=.005,location=(x,-.036,.322))
    rivet=finish(bpy.context.object,'Round silver rivet',chrome)
    rivet.scale.y=.4

bpy.ops.object.text_add(location=(-.110,-.018,.241),rotation=(pi/2,0,0))
text=bpy.context.object
text.data.body='SHIFT BOARD'
text.data.size=.028
text.data.extrude=0
finish(text,'Printed shift heading',ink)
bpy.ops.object.convert(target='MESH')

# Fix polygon winding on the extruded board/paper outlines.
for obj in model.objects:
    bpy.context.view_layer.objects.active=obj
    obj.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.mesh.normals_make_consistent(inside=False)
    bpy.ops.object.mode_set(mode='OBJECT')
    obj.select_set(False)
for obj in model.objects: obj.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/clipboard/shift_clipboard.glb'),use_selection=True,export_format='GLB')
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/clipboard/shift_clipboard.blend'))
print('CLIPBOARD_COMPLETE',len(model.objects),'objects')
