"""Build the additional portrait customer without changing existing customers.
Blender --factory-startup -b --python art/customer_portrait/build_customer.py
"""
from pathlib import Path
import bpy
import bmesh
import math
import argparse
import sys

SCRIPT = Path(__file__).resolve().parent
ROOT = SCRIPT.parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--variant', default='male_photo')
parser.add_argument('--source', default=str(SCRIPT))
args = parser.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
HERE = Path(args.source).resolve()
VARIANT = args.variant
HEAD_LIFT = .0225 if VARIANT == 'male_glasses' else 0.0
OUT = ROOT / 'assets' / 'customers'
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=str(OUT / 'male_1.glb'))
rig = next(o for o in bpy.data.objects if o.type == 'ARMATURE')
for obj in list(bpy.data.objects):
    if obj.type == 'MESH' and obj.hide_render:
        bpy.data.objects.remove(obj, do_unlink=True)

def material(name, filename):
    image = bpy.data.images.load(str(HERE / filename), check_existing=False)
    image.scale(256, 256)
    image.filepath_raw = str(OUT / (VARIANT + '_' + filename))
    image.file_format = 'PNG'
    image.save()
    image.pack()
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get('Principled BSDF')
    bsdf.inputs['Roughness'].default_value = .95
    texture = mat.node_tree.nodes.new('ShaderNodeTexImage')
    texture.image = image
    texture.interpolation = 'Closest'
    mat.node_tree.links.new(texture.outputs['Color'], bsdf.inputs['Base Color'])
    return mat

face = material('Face', 'face_atlas.png')
clothes = material('Clothes', 'shirt_atlas.png')
for obj in list(bpy.data.objects):
    if obj.type != 'MESH':
        continue
    is_head = any(slot.material and slot.material.name.startswith('Face') for slot in obj.material_slots)
    obj.data.materials.clear()
    obj.data.materials.append(face if is_head else clothes)
    if is_head:
        # A fuller jaw/cheek silhouette suits the portrait while keeping the
        # original neck seam, head bone, and animation-compatible rig.
        zs = [v.co.z for v in obj.data.vertices]
        lo, hi = min(zs), max(zs)
        for vertex in obj.data.vertices:
            height = (vertex.co.z-lo)/(hi-lo)
            vertex.co.x *= (1.10 if .2 < height < .75 else 1.04) if VARIANT == 'male_photo' else 1.02
            if VARIANT == 'male_glasses' and vertex.co.z > 1.73:
                vertex.co.z = 1.73+(vertex.co.z-1.73)*.7
        # The donor head was offset left and forward relative to this body's
        # neck. Center the actual mesh over the spine, not just its head bone.
        xs = [v.co.x for v in obj.data.vertices]
        ys = [v.co.y for v in obj.data.vertices]
        center_x = (min(xs)+max(xs))*.5
        center_y = (min(ys)+max(ys))*.5
        for vertex in obj.data.vertices:
            vertex.co.x -= center_x
            vertex.co.y += .055-center_y
            # Taper the lower rear head into the neck rather than leaving a
            # flat skin shelf sticking out beneath the hair.
            if vertex.co.z < 1.61 and vertex.co.y > .10:
                rear = .105 + max(0,vertex.co.z-1.53)*.5
                vertex.co.y = min(vertex.co.y,rear)
            vertex.co.z += HEAD_LIFT
        # Fit the generated portrait atlas's feature heights to the original
        # head UVs. This edits mesh UV coordinates, not the reference photo.
        stops = [(0,0),(.44,.42),(.62,.56),(.75,.67),(.98,.965),(1,1)]
        for loop in obj.data.uv_layers.active.data:
            y = 1-loop.uv.y
            for (a,b),(c,d) in zip(stops,stops[1:]):
                if a <= y <= c:
                    loop.uv.y = 1-(b+(d-b)*(y-a)/(c-a))
                    break
    else:
        if obj.name.startswith('male_body'):
            # A regular-fit male torso: flatten the donor's pronounced pecs
            # and fill out the pinched waist under the shirt.
            for vertex in obj.data.vertices:
                co = vertex.co
                if abs(co.x) < .30 and 1.08 < co.z < 1.46:
                    height_weight = min(1.0,(co.z-1.08)/.12,(1.46-co.z)/.08)
                    side_weight = min(1.0,(.30-abs(co.x))/.07)
                    weight = max(0,height_weight*side_weight)
                    if co.y < -.025:
                        co.y += (-.025-co.y)*weight
                if abs(co.x) < .27 and .96 < co.z < 1.24:
                    waist_weight = max(0,1-abs(co.z-1.08)/.16)
                    co.x *= 1+.13*waist_weight
            if VARIANT == 'male_glasses':
                # Give the polo a broad, rounded abdomen instead of the
                # donor's athletic waist. Blend into the hips and chest so
                # the hem and side seams remain continuous when he walks.
                for vertex in obj.data.vertices:
                    co = vertex.co
                    if abs(co.x) < .32 and .87 < co.z < 1.43:
                        belly = max(0.0, 1.0-((co.z-1.115)/.255)**2)
                        side = max(0.0, min(1.0, (.32-abs(co.x))/.08))
                        co.x *= 1.0+.38*belly*side
                        front = max(0.0, min(1.0, (.07-co.y)/.10))
                        co.y -= .105*belly*front*side
                # Smooth the fabric across the low-poly chest and shoulders.
                for polygon in obj.data.polygons:
                    if all(obj.data.vertices[i].co.z > .97 for i in polygon.vertices):
                        polygon.use_smooth = True
                obj.data.update()
        if VARIANT == 'male_glasses':
            # The generated collar opening crosses the donor shoulder UVs.
            # Project the shoulder caps onto a continuous gray fabric swatch,
            # preserving the center collar and the short sleeve/skin boundary.
            uv = obj.data.uv_layers.active
            for polygon in obj.data.polygons:
                center = polygon.center
                if center.z > 1.38 and abs(center.x) > .07:
                    for index in polygon.loop_indices:
                        co = obj.data.vertices[obj.data.loops[index].vertex_index].co
                        uv.data[index].uv = (.43+co.x*.12,.65+(co.z-1.38)*.25)
        # Remove the original body's long rear neck stub. It protruded behind
        # the separate portrait head when the locomotion pose straightened it.
        mesh = bmesh.new()
        mesh.from_mesh(obj.data)
        remove = [f for f in mesh.faces if f.calc_center_median().z > 1.50
                  and abs(f.calc_center_median().x) < .09]
        bmesh.ops.delete(mesh, geom=remove, context='FACES')
        mesh.to_mesh(obj.data)
        mesh.free()

# Short, centered neck bridges the collar and head without a rear shelf.
vertices = []
faces = []
for z, radius in [(1.465,.059),(1.575+HEAD_LIFT,.047)]:
    for i in range(12):
        angle = i*math.tau/12
        vertices.append((math.cos(angle)*radius,.055+math.sin(angle)*radius,z))
for i in range(12):
    j = (i+1)%12
    faces.append((i,j,j+12,i+12))
neck_mesh = bpy.data.meshes.new('PortraitNeck')
neck_mesh.from_pydata(vertices,[],faces)
neck_mesh.update()
neck = bpy.data.objects.new('PortraitNeck',neck_mesh)
bpy.context.collection.objects.link(neck)
neck.parent = rig
skin = face.copy()
skin.name = 'NeckSkin'
neck_mesh.materials.append(skin)
uv = neck_mesh.uv_layers.new(name='UVMap')
for loop in uv.data:
    loop.uv = (.5,.7)
lower = neck.vertex_groups.new(name='DEF-spine.004')
upper = neck.vertex_groups.new(name='DEF-spine.006')
lower.add(list(range(12)),1,'REPLACE')
upper.add(list(range(12,24)),1,'REPLACE')
modifier = neck.modifiers.new('Skin','ARMATURE')
modifier.object = rig

bpy.ops.wm.save_as_mainfile(filepath=str(HERE / 'portrait_customer.blend'))
bpy.ops.export_scene.gltf(filepath=str(OUT / (VARIANT+'.glb')), export_format='GLB',
    export_animations=False, export_def_bones=True, export_yup=True)
print('EXPORTED portrait customer', flush=True)
