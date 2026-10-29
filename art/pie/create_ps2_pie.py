import bpy
import math
from pathlib import Path

OUT=Path(__file__).resolve().parent
ASSETS=OUT.parents[1]/'assets'/'pies'
bpy.ops.wm.open_mainfile(filepath=str(OUT/'golden_pie.blend'))
collection=bpy.data.collections['PIE | actual 3D geometry']
bpy.ops.object.select_all(action='DESELECT')
for obj in collection.objects:
    obj.select_set(True)
bpy.context.view_layer.objects.active=next(o for o in collection.objects if 'Domed' in o.name)
bpy.ops.object.join()
pie=bpy.context.object
pie.name='PS2_Golden_Domed_Pie'
bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
triangles=sum(len(p.vertices)-2 for p in pie.data.polygons)
decimate=pie.modifiers.new('PS2 polygon budget','DECIMATE')
decimate.ratio=min(1.0,1800/triangles)
decimate.use_collapse_triangulate=True
bpy.ops.object.modifier_apply(modifier=decimate.name)
pie.data.validate(clean_customdata=False)
pie.data.update()
for polygon in pie.data.polygons:
    polygon.use_smooth=True
bpy.ops.object.mode_set(mode='EDIT')
bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.uv.smart_project(angle_limit=math.radians(66),island_margin=.015)
bpy.ops.object.mode_set(mode='OBJECT')

# Bake the approved pastry materials into one small, portable texture atlas.
image=bpy.data.images.new('Pie_PS2_256_Atlas',width=256,height=256,alpha=False)
for mat in pie.data.materials:
    nodes=mat.node_tree.nodes
    target=nodes.new('ShaderNodeTexImage')
    target.image=image
    nodes.active=target
scene=bpy.context.scene
scene.render.engine='CYCLES'
scene.cycles.samples=8
scene.render.bake.use_pass_direct=False
scene.render.bake.use_pass_indirect=False
scene.render.bake.use_pass_color=True
scene.render.bake.margin=3
bpy.ops.object.bake(type='DIFFUSE')
pixels=list(image.pixels[:])
for i in range(0,len(pixels),4):
    for channel in range(3):
        pixels[i+channel]=round(pixels[i+channel]*31)/31
image.pixels[:]=pixels
image.filepath_raw=str(ASSETS/'pie_ps2_albedo.png')
image.file_format='PNG'
image.save()
image.pack()

mat=bpy.data.materials.new('PS2 Pie | 256px baked color')
mat.use_nodes=True
mat.diffuse_color=(.64,.255,.045,1)
bsdf=mat.node_tree.nodes.get('Principled BSDF')
bsdf.inputs['Roughness'].default_value=.8
texture=mat.node_tree.nodes.new('ShaderNodeTexImage')
texture.image=image
texture.interpolation='Closest'
mat.node_tree.links.new(texture.outputs['Color'],bsdf.inputs['Base Color'])
pie.data.materials.clear()
pie.data.materials.append(mat)
for polygon in pie.data.polygons:
    polygon.material_index=0
pie['style']='PS2 inspired: low polygon geometry, 256px 5-bit color atlas, nearest filtering'
pie['triangle_count']=sum(len(p.vertices)-2 for p in pie.data.polygons)
scene.cycles.samples=16
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'golden_pie_ps2.blend'))
bpy.ops.export_scene.gltf(filepath=str(ASSETS/'pie_ps2.glb'),use_selection=True,export_format='GLB',export_yup=True)
scene.render.filepath=str(OUT/'golden_pie_ps2_preview.png')
bpy.ops.render.render(write_still=True)
print('PS2_PIE_COMPLETE',pie['triangle_count'],'triangles, 256x256 baked atlas')
