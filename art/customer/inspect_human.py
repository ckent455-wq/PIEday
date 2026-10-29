from pathlib import Path
import bpy
from mathutils import Vector
bpy.ops.wm.open_mainfile(filepath=str(Path(__file__).resolve().parent/'source'/'Humanoid.blend'))
for o in bpy.context.scene.objects:
    print('HUMAN_OBJECT',o.name,o.type,tuple(o.dimensions),tuple(o.location))
    if o.type=='ARMATURE':
        print('BONES',[b.name for b in o.data.bones])
    if o.type=='MESH':
        print('BOUNDS', min((o.matrix_world@Vector(v)).z for v in o.bound_box), max((o.matrix_world@Vector(v)).z for v in o.bound_box), 'POLYS',len(o.data.polygons))
