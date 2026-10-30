from pathlib import Path
import bpy
from mathutils import Vector, Matrix
root = Path(__file__).resolve().parents[2]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(root / 'art/dumpster/source.glb'))
meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
points = [o.matrix_world @ Vector(c) for o in meshes for c in o.bound_box]
low = Vector(tuple(min(p[i] for p in points) for i in range(3)))
high = Vector(tuple(max(p[i] for p in points) for i in range(3)))
print('DUMPSTER_SOURCE_BOUNDS', low[:], high[:])
origin = Vector(((low.x + high.x) / 2, (low.y + high.y) / 2, low.z))
scale = min(2.3 / max(high.x-low.x, high.y-low.y), 1.65 / (high.z-low.z))
transforms = {o: o.matrix_world.copy() for o in meshes}
bpy.ops.object.select_all(action='DESELECT')
for obj in meshes:
    obj.data = obj.data.copy()
    for vertex in obj.data.vertices:
        vertex.co = (transforms[obj] @ vertex.co - origin) * scale
    obj.parent = None
    obj.matrix_world = Matrix.Identity(4)
    obj.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(root / 'assets/dumpster/dumpster.glb'), use_selection=True, export_format='GLB')
