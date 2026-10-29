import bpy, math
from mathutils import Vector
from pathlib import Path

OUT=Path(__file__).resolve().parent
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
model=bpy.data.collections.new('TRAY | export geometry')
bpy.context.scene.collection.children.link(model)
studio=bpy.data.collections.new('STUDIO | preview only')
bpy.context.scene.collection.children.link(studio)

def move(obj,collection):
    for c in list(obj.users_collection): c.objects.unlink(obj)
    collection.objects.link(obj)
    return obj

def material(name,color,roughness):
    mat=bpy.data.materials.new(name)
    mat.diffuse_color=(*color,1)
    mat.use_nodes=True
    shader=mat.node_tree.nodes.get('Principled BSDF')
    shader.inputs['Base Color'].default_value=(*color,1)
    shader.inputs['Roughness'].default_value=roughness
    return mat

rim=material('Black molded plastic | satin rim',(.015,.017,.019),.28)
rim.node_tree.nodes['Principled BSDF'].inputs['Coat Weight'].default_value=.18
floor=material('Black nonslip woven base',(.019,.021,.023),.68)

# A seamless small woven tile: restrained relief, not a painted checkerboard.
N=256
heights=[]
for y in range(N):
    for x in range(N):
        u=x/N*8; v=y/N*8
        ix,iy=int(u),int(v)
        fu,fv=u%1,v%1
        if (ix+iy)%2==0:
            h=(math.sin(math.pi*fv)**6)*(.65+.35*math.sin(math.pi*fu))
        else:
            h=(math.sin(math.pi*fu)**6)*(.65+.35*math.sin(math.pi*fv))
        heights.append(h)
image=bpy.data.images.new('Tray woven grip | 256px',width=N,height=N)
pixels=[]
for h in heights:
    value=.04+h*.012
    pixels.extend((value,value*1.015,value*1.025,1))
image.pixels[:]=pixels
image.filepath_raw=str(OUT/'tray_grip_albedo.png')
image.file_format='PNG'
image.save(); image.pack()
normal=bpy.data.images.new('Tray woven grip | tangent normal',width=N,height=N,is_data=True)
pixels=[]
for y in range(N):
    for x in range(N):
        dx=(heights[y*N+(x+1)%N]-heights[y*N+(x-1)%N])*.6
        dy=(heights[((y+1)%N)*N+x]-heights[((y-1)%N)*N+x])*.6
        v=Vector((-dx,-dy,1)).normalized()
        pixels.extend((v.x*.5+.5,v.y*.5+.5,v.z*.5+.5,1))
normal.pixels[:]=pixels
normal.filepath_raw=str(OUT/'tray_grip_normal.png')
normal.file_format='PNG'
normal.save(); normal.pack()
nodes=floor.node_tree.nodes; links=floor.node_tree.links
texture=nodes.new('ShaderNodeTexImage'); texture.image=image
links.new(texture.outputs['Color'],nodes.get('Principled BSDF').inputs['Base Color'])
texture_normal=nodes.new('ShaderNodeTexImage'); texture_normal.image=normal
normal_map=nodes.new('ShaderNodeNormalMap')
normal_map.inputs['Strength'].default_value=.3
links.new(texture_normal.outputs['Color'],normal_map.inputs['Color'])
links.new(normal_map.outputs['Normal'],nodes.get('Principled BSDF').inputs['Normal'])

def rounded_ring(w,d,r,z,segments=12):
    ring=[]
    for cx,cy,start in [(w-r,d-r,0),(-w+r,d-r,90),(-w+r,-d+r,180),(w-r,-d+r,270)]:
        for j in range(segments+1):
            a=math.radians(start+j*90/segments)
            ring.append((cx+r*math.cos(a),cy+r*math.sin(a),z))
    return ring

# Closed solid cross-section: underside, tapered outer wall, rolled lip,
# tapered inner wall, and recessed flat serving surface. Dimensions in meters.
profiles=[
(.224,.154,.027,.000),
(.228,.158,.030,.002),
(.249,.179,.044,.021),
(.252,.182,.047,.024),
(.252,.182,.047,.026),
(.250,.180,.045,.028),
(.247,.177,.043,.0285),
(.244,.174,.041,.026),
(.242,.172,.040,.0225),
(.224,.154,.027,.0065),
(.220,.150,.024,.0055),
]
verts=[]
for profile in profiles: verts.extend(rounded_ring(*profile))
count=len(rounded_ring(*profiles[0]))
faces=[]
for i in range(len(profiles)-1):
    for j in range(count):
        k=(j+1)%count
        faces.append((i*count+j,i*count+k,(i+1)*count+k,(i+1)*count+j))
faces.append(tuple(reversed(range(count))))
faces.append(tuple((len(profiles)-1)*count+j for j in range(count)))
mesh=bpy.data.meshes.new('Rounded molded tray shell')
mesh.from_pydata(verts,[],faces)
mesh.update()
tray=bpy.data.objects.new('Black cafeteria serving tray',mesh)
model.objects.link(tray)
mesh.materials.append(rim)
mesh.materials.append(floor)
uv=mesh.uv_layers.new(name='Grip UV')
for polygon in mesh.polygons:
    polygon.use_smooth=len(polygon.vertices)==4
    polygon.material_index=1 if polygon.index==len(mesh.polygons)-1 else 0
    for loop_index in polygon.loop_indices:
        co=mesh.vertices[mesh.loops[loop_index].vertex_index].co
        # Repeat the weave at a believable fine scale; glTF exports this UV.
        uv.data[loop_index].uv=(co.x/.10,co.y/.10)
tray['reference']='Screenshot 2026-10-29 152731.png'
tray['dimensions']='50.4 x 36.4 x 2.85 cm'

# Four low molded feet keep the underside believable and the tray off the table.
for x in [-.185,.185]:
    for y in [-.115,.115]:
        bpy.ops.mesh.primitive_cube_add(size=1,location=(x,y,-.001))
        foot=move(bpy.context.object,model)
        foot.name='Molded underside support'
        foot.dimensions=(.035,.012,.003)
        bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
        bevel=foot.modifiers.new('Soft molding','BEVEL'); bevel.width=.002; bevel.segments=2
        bpy.context.view_layer.objects.active=foot
        bpy.ops.object.modifier_apply(modifier=bevel.name)
        foot.data.materials.append(rim)

groundmat=material('Preview warm white',(.7,.72,.74),.84)
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.003))
plane=move(bpy.context.object,studio)
plane.data.materials.append(groundmat)

def aim(obj,point): obj.rotation_euler=(Vector(point)-obj.location).to_track_quat('-Z','Y').to_euler()
def area(name,position,energy,size):
    data=bpy.data.lights.new(name,'AREA'); data.energy=energy*.18; data.shape='DISK'; data.size=size
    obj=bpy.data.objects.new(name,data); studio.objects.link(obj); obj.location=position; aim(obj,(0,0,0))
area('Large side softbox',(-.45,-.35,.85),22,.65)
area('Rim highlight',(.15,.5,.6),28,.55)
area('Gentle front fill',(.5,-.3,.4),8,.5)
data=bpy.data.cameras.new('Tray presentation camera')
camera=bpy.data.objects.new('Tray presentation camera',data)
studio.objects.link(camera)
camera.location=(.23,-.75,.62)
aim(camera,(0,0,.012))
camera.data.type='ORTHO'; camera.data.ortho_scale=.72
scene=bpy.context.scene
scene.camera=camera
scene.render.engine='CYCLES'
scene.cycles.samples=24
scene.cycles.use_denoising=True
scene.render.resolution_x=1200; scene.render.resolution_y=900
scene.render.resolution_percentage=100
scene.world.color=(.2,.2,.2)
scene.view_settings.view_transform='AgX'
scene.unit_settings.system='METRIC'
bpy.ops.object.select_all(action='DESELECT')
for obj in model.objects: obj.select_set(True)
bpy.context.view_layer.objects.active=tray
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'black_cafeteria_tray.blend'))
bpy.ops.export_scene.gltf(filepath=str(OUT/'black_cafeteria_tray.glb'),use_selection=True,export_format='GLB')
scene.render.filepath=str(OUT/'black_cafeteria_tray_preview.png')
bpy.ops.render.render(write_still=True)
print('TRAY_COMPLETE',sum(len(o.data.polygons) for o in model.objects),'polygons')
