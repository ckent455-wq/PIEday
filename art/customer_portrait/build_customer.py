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
HOODIE = VARIANT in ['male_blue_hoodie', 'male_gray_hoodie']
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
            if HOODIE and vertex.co.z > 1.71:
                # The references have a fringe and a buzzcut, not a tall quiff.
                vertex.co.z = 1.71+(vertex.co.z-1.71)*(.8 if VARIANT == 'male_blue_hoodie' else .48)
            if VARIANT == 'male_blue_hoodie':
                vertex.co.x *= 1.10
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
            if HOODIE:
                for vertex in obj.data.vertices:
                    co = vertex.co
                    if abs(co.x) < .30 and .95 < co.z < 1.43:
                        fullness = max(0.0, 1.0-((co.z-1.16)/.25)**2)
                        co.x *= 1.0+.19*fullness
                        if co.y < .04: co.y -= .035*fullness
                for polygon in obj.data.polygons:
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
        if HOODIE:
            uv = obj.data.uv_layers.active
            for polygon in obj.data.polygons:
                center = polygon.center
                for index in polygon.loop_indices:
                    co = obj.data.vertices[obj.data.loops[index].vertex_index].co
                    if .10 < center.z < .99 and abs(center.x) < .30:
                        # Both legs sample the denim island, never the newly
                        # generated sleeve that occupies the old front-leg UV.
                        t = max(0,min(1,(.99-co.z)/.89))
                        uv.data[index].uv = (.66+.25*t+(abs(co.x)-.12)*.12,.69+.22*t)
                    elif .28 < abs(center.x) < .59 and center.z > 1.0:
                        # Extend fabric down both forearms, stopping at hands.
                        uv.data[index].uv = (.16+abs(co.x)*.08,.81+(co.z-1.0)*.12)
                    elif center.z > 1.38 and abs(center.x) > .07:
                        uv.data[index].uv = (.17+co.x*.03,.83+(co.z-1.38)*.08)
                    elif VARIANT == 'male_blue_hoodie' and 1.0 < center.z < 1.42 and center.y < .025 and abs(center.x) < .27:
                        # The blue wordmark was painted upright in its atlas;
                        # project it upright across the chest, not a shoulder.
                        uv.data[index].uv = (.455+(co.x+.24)/.48*.24,.19+(co.z-1.0)/.46*.22)
        # Remove the original body's long rear neck stub. It protruded behind
        # the separate portrait head when the locomotion pose straightened it.
        mesh = bmesh.new()
        mesh.from_mesh(obj.data)
        remove = [f for f in mesh.faces if f.calc_center_median().z > 1.50
                  and abs(f.calc_center_median().x) < .09]
        bmesh.ops.delete(mesh, geom=remove, context='FACES')
        mesh.to_mesh(obj.data)
        mesh.free()
        if HOODIE and obj.name.startswith('male_body'):
            # A clean waist seam and simple cloth materials avoid stretching
            # the generated atlas across unrelated trouser/sleeve islands.
            mesh = bmesh.new()
            mesh.from_mesh(obj.data)
            bmesh.ops.bisect_plane(mesh,geom=list(mesh.verts)+list(mesh.edges)+list(mesh.faces),dist=.0001,plane_co=(0,0,1.02),plane_no=(0,0,1),clear_inner=False,clear_outer=False)
            mesh.to_mesh(obj.data)
            mesh.free()
            fabric = bpy.data.materials.new('SweatshirtFabric')
            fabric.diffuse_color = (.006,.065,.25,1) if VARIANT == 'male_blue_hoodie' else (.23,.25,.27,1)
            denim = bpy.data.materials.new('Denim')
            denim.diffuse_color = (.018,.028,.055,1) if VARIANT == 'male_blue_hoodie' else (.035,.065,.11,1)
            for mat in [fabric,denim]:
                mat.use_nodes = True
                shader = mat.node_tree.nodes.get('Principled BSDF')
                shader.inputs['Base Color'].default_value = mat.diffuse_color
                shader.inputs['Roughness'].default_value = .96
            obj.data.materials.append(fabric)
            obj.data.materials.append(denim)
            hand_groups = {g.index for g in obj.vertex_groups if 'hand' in g.name.lower() or 'finger' in g.name.lower() or 'thumb' in g.name.lower() or 'palm' in g.name.lower() or 'f_' in g.name.lower()}
            for polygon in obj.data.polygons:
                center = sum((obj.data.vertices[i].co for i in polygon.vertices), __import__('mathutils').Vector())/len(polygon.vertices)
                hand_weight = sum(sum(g.weight for g in obj.data.vertices[i].groups if g.group in hand_groups) for i in polygon.vertices)/len(polygon.vertices)
                if center.z > 1.02 and hand_weight < .5:
                    polygon.material_index = 1
                elif .105 < center.z <= 1.02 and abs(center.x) < .32:
                    polygon.material_index = 2
            obj.data.update()

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

if HOODIE:
    # The chest graphic is a small skinned fabric panel with explicit UVs,
    # keeping its orientation independent of the donor's rotated UV islands.
    graphic = bpy.data.meshes.new('ChestGraphic')
    w, bottom, top = (.245,1.23,1.365) if VARIANT == 'male_blue_hoodie' else (.25,1.205,1.395)
    graphic.from_pydata([(-w/2,-.073,bottom),(w/2,-.073,bottom),(w/2,-.064,top),(-w/2,-.064,top)],[],[(0,1,2,3)])
    graphic.materials.append(clothes)
    layer = graphic.uv_layers.new()
    coords = [(.55,.30),(.685,.30),(.685,.38),(.55,.38)] if VARIANT == 'male_blue_hoodie' else [(.53,.255),(.53,.42),(.62,.42),(.62,.255)]
    for loop in graphic.loops: layer.data[loop.index].uv = coords[loop.vertex_index]
    panel = bpy.data.objects.new('ChestGraphic',graphic)
    bpy.context.collection.objects.link(panel)
    panel.parent = rig
    panel.vertex_groups.new(name='DEF-spine.003').add([0,1,2,3],1,'REPLACE')
    panel.modifiers.new('Skin','ARMATURE').object = rig
    # A lowered hood gives the sweatshirt an actual 3D silhouette around the
    # back of the neck. It follows the upper spine, leaving the face clear.
    hood_mat = bpy.data.materials.new('HoodFabric')
    hood_mat.diffuse_color = (.018,.16,.36,1) if VARIANT == 'male_blue_hoodie' else (.27,.29,.31,1)
    hood_mat.use_nodes = True
    hood_mat.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value = (.006,.065,.25,1) if VARIANT == 'male_blue_hoodie' else (.23,.25,.27,1)
    hood_mat.node_tree.nodes.get('Principled BSDF').inputs['Roughness'].default_value = .96
    hood_vertices, hood_faces = [], []
    for i in range(17):
        angle = math.pi*i/16
        for j in range(6):
            cross = math.tau*j/6
            radius = .105+.027*math.cos(cross)
            hood_vertices.append((math.cos(angle)*radius,.04+math.sin(angle)*radius,1.475+.032*math.sin(cross)-.035*math.sin(angle)))
    for i in range(16):
        for j in range(6):
            hood_faces.append((i*6+j,i*6+(j+1)%6,(i+1)*6+(j+1)%6,(i+1)*6+j))
    mesh = bpy.data.meshes.new('LoweredHood')
    mesh.from_pydata(hood_vertices,[],hood_faces)
    mesh.materials.append(hood_mat)
    hood = bpy.data.objects.new('LoweredHood',mesh)
    bpy.context.collection.objects.link(hood)
    hood.parent = rig
    hood.vertex_groups.new(name='DEF-spine.003').add(list(range(len(hood_vertices))),1,'REPLACE')
    hood.modifiers.new('Skin','ARMATURE').object = rig
    for polygon in mesh.polygons: polygon.use_smooth = True

bpy.ops.wm.save_as_mainfile(filepath=str(HERE / 'portrait_customer.blend'))
bpy.ops.export_scene.gltf(filepath=str(OUT / (VARIANT+'.glb')), export_format='GLB',
    export_animations=False, export_def_bones=True, export_yup=True)
print('EXPORTED portrait customer', flush=True)
