import bpy
import math
from pathlib import Path
import numpy as np

root = Path.cwd()
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
size = 256
y, x = np.mgrid[-1:1:complex(size), -1:1:complex(size)]
r = np.hypot(x, y)
a = np.arctan2(y, x)
rng = np.random.default_rng(52)
grain = rng.random((size, size)) * 0.035
chambers = (r > 0.24 + 0.08*np.cos(5*a)) & (r < 0.76 + 0.07*np.cos(5*a)) & (np.cos(5*a) > -0.76)
color = np.zeros((size, size, 4), np.float32)
color[:, :, :3] = np.array([0.66,0.09,0.045]) + grain[...,None]
color[chambers,:3] = np.array([0.37,0.052,0.025]) + grain[chambers,None]*2
color[r > .86,:3] = np.array([0.57,0.022,0.014]) + grain[r > .86,None]
core = r < .21 + .08*np.cos(5*a)
color[core,:3] = np.array([0.82,0.24,0.13]) + grain[core,None]
for pocket in range(5):
    for seed in range(7):
        angle = pocket*math.tau/5 + rng.uniform(-.29,.29)
        radius = rng.uniform(.37,.68)
        dx=x-math.cos(angle)*radius
        dy=y-math.sin(angle)*radius
        u=dx*math.cos(angle)+dy*math.sin(angle)
        v=-dx*math.sin(angle)+dy*math.cos(angle)
        kernel=(u/.052)**2+(v/.025)**2 < 1
        color[kernel & chambers,:3] = (.86,.58,.24)
color[:,:,3]=1
image=bpy.data.images.new('Tomato cut surface',width=size,height=size)
image.pixels.foreach_set(color.ravel())
image.filepath_raw=str(root/'assets/burger/tomato_slice_albedo.png')
image.file_format='PNG'
image.save()
image.pack()

segments=40
vertices=[]
for radius,z in [(0.052,0),(0.056,0.002),(0.056,0.008),(0.052,0.010)]:
    for i in range(segments):
        angle=math.tau*i/segments
        outline=1+.026*math.cos(5*angle)+.015*math.sin(3*angle)
        vertices.append((math.cos(angle)*radius*outline,math.sin(angle)*radius*outline,z))
faces=[tuple(reversed(range(segments)))]
for ring in range(3):
    for i in range(segments):
        a=ring*segments+i
        b=ring*segments+(i+1)%segments
        faces.append((a,b,b+segments,a+segments))
faces.append(tuple(range(3*segments,4*segments)))
mesh=bpy.data.meshes.new('Sliced tomato mesh')
mesh.from_pydata(vertices,[],faces)
mesh.update()
obj=bpy.data.objects.new('Fresh tomato slice',mesh)
bpy.context.collection.objects.link(obj)
for name,shade,roughness in [('Cut tomato flesh',(1,1,1,1),.32),('Red tomato skin',(.45,.018,.009,1),.42)]:
    mat=bpy.data.materials.new(name)
    mat.use_nodes=True
    shader=mat.node_tree.nodes.get('Principled BSDF')
    shader.inputs['Base Color'].default_value=shade
    shader.inputs['Roughness'].default_value=roughness
    if name=='Cut tomato flesh':
        tex=mat.node_tree.nodes.new('ShaderNodeTexImage')
        tex.image=image
        mat.node_tree.links.new(tex.outputs['Color'],shader.inputs['Base Color'])
    mesh.materials.append(mat)
uv=mesh.uv_layers.new(name='Tomato UV')
for face in mesh.polygons:
    face.material_index=0 if face.index in (0,len(mesh.polygons)-1) else 1
    for loop in face.loop_indices:
        point=mesh.vertices[mesh.loops[loop].vertex_index].co
        uv.data[loop].uv=(point.x/.108+.5,point.y/.108+.5)
obj.select_set(True)
bpy.context.view_layer.objects.active=obj
bpy.ops.wm.save_as_mainfile(filepath=str(root/'art/burger/tomato_slice.blend'))
bpy.ops.export_scene.gltf(filepath=str(root/'assets/burger/tomato_slice.glb'),export_format='GLB',use_selection=True,export_yup=True)
