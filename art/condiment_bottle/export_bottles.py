import bpy, math
from mathutils import Vector
from pathlib import Path
root=Path.cwd()
source=next(o for o in bpy.context.scene.objects if o.type=='MESH')
bpy.context.view_layer.objects.active=source
source.select_set(True)
# Bake the current modeled shape and normalize to a 28 cm tabletop bottle.
deps=bpy.context.evaluated_depsgraph_get()
mesh=bpy.data.meshes.new_from_object(source.evaluated_get(deps),depsgraph=deps)
points=[source.matrix_world@v.co for v in mesh.vertices]
lo=Vector(tuple(min(p[i] for p in points) for i in range(3)))
hi=Vector(tuple(max(p[i] for p in points) for i in range(3)))
center=(lo+hi)*.5
scale=.28/(hi.z-lo.z)
for v,p in zip(mesh.vertices,points): v.co=Vector(((p.x-center.x)*scale,(p.y-center.y)*scale,(p.z-lo.z)*scale))
for o in list(bpy.data.objects): bpy.data.objects.remove(o,do_unlink=True)
for name,color,x in [('ketchup',(0.65,.025,.015,1),-.09),('mustard',(.95,.62,.012,1),.09)]:
 obj=bpy.data.objects.new(name,mesh.copy());bpy.context.collection.objects.link(obj)
 obj.data.materials.clear()
 mat=bpy.data.materials.new(name+' plastic');mat.diffuse_color=color;mat.use_nodes=True
 bs=mat.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=color;bs.inputs['Roughness'].default_value=.37
 obj.data.materials.append(mat)
 bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);bpy.context.view_layer.objects.active=obj
 bpy.ops.export_scene.gltf(filepath=str(root/'assets/condiments'/f'{name}_bottle.glb'),export_format='GLB',use_selection=True)
 obj.location.x=x
scene=bpy.context.scene
scene.render.engine='CYCLES';scene.cycles.samples=24
scene.render.resolution_x=800;scene.render.resolution_y=650;scene.render.resolution_percentage=100
scene.world.color=(.22,.22,.22)
bpy.ops.object.camera_add(location=(.6,-1,.5));camera=bpy.context.object;camera.rotation_euler=(Vector((0,0,.14))-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.type='ORTHO';camera.data.ortho_scale=.48;scene.camera=camera
bpy.ops.object.light_add(type='AREA',location=(.1,-.4,.9));bpy.context.object.data.energy=70;bpy.context.object.data.shape='DISK';bpy.context.object.data.size=.8
scene.render.filepath=str(root/'builds/condiment-bottles.png');bpy.ops.render.render(write_still=True)
