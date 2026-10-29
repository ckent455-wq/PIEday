import bpy
from pathlib import Path
out=Path(__file__).resolve().parent
bpy.ops.wm.open_mainfile(filepath=str(out/'golden_pie_ps2.blend'))
pie=bpy.data.objects['PS2_Golden_Domed_Pie']
print('MESH_REPAIRED',pie.data.validate(clean_customdata=False))
pie.data.update()
bpy.ops.object.select_all(action='DESELECT')
pie.select_set(True)
bpy.context.view_layer.objects.active=pie
bpy.ops.wm.save_as_mainfile(filepath=str(out/'golden_pie_ps2.blend'))
bpy.ops.export_scene.gltf(filepath=str(out.parents[1]/'assets'/'pies'/'pie_ps2.glb'),use_selection=True,export_format='GLB',export_yup=True)
print('PS2_FINAL',sum(len(p.vertices)-2 for p in pie.data.polygons),'triangles')
