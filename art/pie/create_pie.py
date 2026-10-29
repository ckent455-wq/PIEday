import bpy
import math
import random
from mathutils import Vector
from pathlib import Path

OUT = Path(__file__).resolve().parent
random.seed(12)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
for collection in list(bpy.data.collections):
    if collection.name != 'Collection':
        bpy.data.collections.remove(collection)
model = bpy.data.collections.new('PIE | actual 3D geometry')
bpy.context.scene.collection.children.link(model)
studio = bpy.data.collections.new('STUDIO | preview only')
bpy.context.scene.collection.children.link(studio)

def move(obj, collection):
    for c in list(obj.users_collection):
        c.objects.unlink(obj)
    collection.objects.link(obj)
    return obj

def material(name, color, roughness=.5, metallic=0, baked=False):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    bsdf = nodes.get('Principled BSDF')
    bsdf.inputs['Base Color'].default_value = (*color, 1)
    bsdf.inputs['Roughness'].default_value = roughness
    bsdf.inputs['Metallic'].default_value = metallic
    if baked:
        noise = nodes.new('ShaderNodeTexNoise')
        noise.inputs['Scale'].default_value = 38
        noise.inputs['Detail'].default_value = 2
        ramp = nodes.new('ShaderNodeValToRGB')
        ramp.color_ramp.elements[0].position = .2
        ramp.color_ramp.elements[0].color = (*[v*.48 for v in color], 1)
        ramp.color_ramp.elements[1].position = .78
        ramp.color_ramp.elements[1].color = (*[min(v*1.3,1) for v in color], 1)
        mat.node_tree.links.new(noise.outputs['Fac'], ramp.inputs[0])
        mat.node_tree.links.new(ramp.outputs[0], bsdf.inputs['Base Color'])
        bump = nodes.new('ShaderNodeBump')
        bump.inputs['Strength'].default_value = .14
        bump.inputs['Distance'].default_value = .0005
        mat.node_tree.links.new(noise.outputs['Fac'], bump.inputs['Height'])
        mat.node_tree.links.new(bump.outputs['Normal'], bsdf.inputs['Normal'])
    return mat

gold = material('Pastry | golden egg wash', (.64,.255,.045), .36, baked=True)
edge = material('Crimp | toasted golden crust', (.48,.145,.022), .47, baked=True)
side = material('Shell | baked pastry', (.46,.19,.055), .58, baked=True)
filling = material('Filling | dark savory gravy', (.075,.022,.007), .48)
foil = material('Tin | brushed aluminum', (.52,.55,.59), .32, .86)

def mesh_object(name, verts, faces, mat):
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    model.objects.link(obj)
    obj.data.materials.append(mat)
    for p in mesh.polygons:
        p.use_smooth = True
    return obj

def lathe(name, profile, mat, count=96, flutes=0):
    verts = []
    for radius, z in profile:
        for j in range(count):
            a = j*math.tau/count
            r = radius + flutes*math.cos(24*a)
            verts.append((r*math.cos(a),r*math.sin(a),z))
    faces=[]
    for i in range(len(profile)-1):
        for j in range(count):
            k=i*count+j
            n=i*count+(j+1)%count
            faces.append((k,n,n+count,k+count))
    faces += [tuple(reversed(range(count))),tuple((len(profile)-1)*count+j for j in range(count))]
    return mesh_object(name,verts,faces,mat)

# A shallow, tapered foil tin, a fluted pastry shell, and a closed domed lid.
lathe('Pie tin',[(.001,.007),(.118,.007),(.123,.011),(.145,.052),(.148,.054),(.145,.057),(.141,.053),(.121,.013),(.001,.013)],foil,96,.0007)
lathe('Fluted pastry sides',[(.001,.014),(.121,.014),(.131,.032),(.143,.056),(.142,.066),(.001,.066)],side,144,.0015)
def dome_height(r):
    radius = .142
    rise = .072
    sphere_radius = (radius*radius + rise*rise) / (2*rise)
    return .073 + math.sqrt(max(0, sphere_radius*sphere_radius-r*r)) - (sphere_radius-rise)

lid_profile=[(.001,.069),(.137,.069),(.142,.073)]
for i in range(31,-1,-1):
    r=.142*i/32
    lid_profile.append((max(r,.0001),dome_height(r)))
lid=lathe('Domed pastry lid with real cut vents',lid_profile,gold,96)

# Three narrow capsule-shaped cutters create genuine holes, not painted slits.
for x in [-.042,0,.042]:
    bpy.ops.mesh.primitive_cube_add(size=1, location=(x,0,.125))
    cutter=bpy.context.object
    cutter.name='Temporary vent cutter'
    cutter.dimensions=(.005,.042,.17)
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    bevel=cutter.modifiers.new('Rounded slit ends','BEVEL')
    bevel.width=.0023
    bevel.segments=3
    bpy.context.view_layer.objects.active=cutter
    bpy.ops.object.modifier_apply(modifier=bevel.name)
    bpy.context.view_layer.objects.active=lid
    mod=lid.modifiers.new('Cut steam vent','BOOLEAN')
    mod.operation='DIFFERENCE'
    mod.solver='EXACT'
    mod.object=cutter
    bpy.ops.object.modifier_apply(modifier=mod.name)
    bpy.data.objects.remove(cutter,do_unlink=True)
lathe('Savory filling visible through vents',[(.001,.073),(.10,.073),(.10,.078),(.001,.078)],filling,64)

# Continuous scalloped rim with pinched ridges, matching the sprite silhouette.
verts=[]
faces=[]
N=192
M=12
for j in range(N):
    a=math.tau*j/N
    scallop=math.cos(24*a)
    radius=.142+.0035*scallop
    for k in range(M):
        b=math.tau*k/M
        r=radius+.009*math.cos(b)
        z=.069+(.0058+.0012*scallop)*math.sin(b)+.001*scallop
        verts.append((r*math.cos(a),r*math.sin(a),z))
for j in range(N):
    for k in range(M):
        faces.append((j*M+k,((j+1)%N)*M+k,((j+1)%N)*M+(k+1)%M,j*M+(k+1)%M))
mesh_object('Hand crimped scalloped crust rim',verts,faces,edge)

# Fine pastry flecks remain actual geometry rather than a billboard texture.
for i in range(26):
    a=random.uniform(0,math.tau)
    r=math.sqrt(random.random())*.122
    x,y=r*math.cos(a),r*math.sin(a)
    if abs(y)<.028 and min(abs(x-q) for q in [-.042,0,.042])<.008:
        continue
    z=dome_height(r)
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=random.uniform(.0009,.0018),location=(x,y,z+.0004))
    obj=move(bpy.context.object,model)
    obj.name='Baked pastry fleck'
    obj.scale.z=.25
    obj.data.materials.append(edge)

# Neutral studio is a separate collection and is excluded from the GLB export.
backdrop=material('Studio | slate blue',(.032,.047,.063),.82)
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,.005))
plane=move(bpy.context.object,studio)
plane.name='Studio ground'
plane.data.materials.append(backdrop)

def aim(obj,point):
    obj.rotation_euler=(Vector(point)-obj.location).to_track_quat('-Z','Y').to_euler()

def area(name,location,power,size,color):
    data=bpy.data.lights.new(name,'AREA')
    data.energy=power * .18
    data.shape='DISK'
    data.size=size
    data.color=color
    obj=bpy.data.objects.new(name,data)
    studio.objects.link(obj)
    obj.location=location
    aim(obj,(0,0,.04))

area('Large softbox',(-.35,-.38,.65),28,.48,(1,.84,.65))
area('Cool fill',(.4,-.1,.3),12,.4,(.7,.82,1))
area('Warm rim',(.1,.4,.5),24,.33,(1,.7,.4))
camera_data=bpy.data.cameras.new('Pie presentation camera')
camera=bpy.data.objects.new('Pie presentation camera',camera_data)
studio.objects.link(camera)
camera.location=(.36,-.48,.36)
aim(camera,(0,0,.065))
camera.data.type='ORTHO'
camera.data.ortho_scale=.43
scene=bpy.context.scene
scene.camera=camera
scene.render.engine='CYCLES'
scene.cycles.samples=24
scene.cycles.use_denoising=True
scene.render.resolution_x=1080
scene.render.resolution_y=900
scene.render.resolution_percentage=100
scene.world.color=(.18,.18,.18)
scene.view_settings.view_transform='AgX'
scene.unit_settings.system='METRIC'

# Select only the pie for a game-ready interchange file, without adding it to Godot.
bpy.ops.object.select_all(action='DESELECT')
for obj in model.objects:
    obj.select_set(True)
bpy.context.view_layer.objects.active=lid
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'golden_pie.blend'))
bpy.ops.export_scene.gltf(filepath=str(OUT/'golden_pie.glb'),use_selection=True,export_format='GLB',export_yup=True)
scene.render.filepath=str(OUT/'golden_pie_preview.png')
bpy.ops.render.render(write_still=True)
camera.location=(.17,-.23,.62)
aim(camera,(0,0,.045))
scene.render.filepath=str(OUT/'golden_pie_top.png')
bpy.ops.render.render(write_still=True)
print('PIE_COMPLETE',len(model.objects),'mesh objects',sum(len(o.data.polygons) for o in model.objects if o.type=='MESH'),'polygons')
