"""Run with Blender --background --python art/pie/create_toasted_pie.py."""
import json
import struct
from pathlib import Path
import bpy

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / 'art' / 'pie'
ASSETS = ROOT / 'assets' / 'pies'
TINT = (0.52, 0.32, 0.18, 1.0)

# Give the variant its own material while preserving the original geometry,
# UVs, embedded atlas, and all other binary data exactly.
source = (ASSETS / 'pie_ps2.glb').read_bytes()
json_size, json_type = struct.unpack_from('<II', source, 12)
document = json.loads(source[20:20 + json_size])
for material in document['materials']:
    material['name'] = 'Toasted pie crust'
    pbr = material.setdefault('pbrMetallicRoughness', {})
    original = pbr.get('baseColorFactor', [1, 1, 1, 1])
    pbr['baseColorFactor'] = [a * b for a, b in zip(original, TINT)]
encoded = json.dumps(document, separators=(',', ':')).encode()
encoded += b' ' * (-len(encoded) % 4)
tail = source[20 + json_size:]
result = struct.pack('<III', 0x46546C67, 2, 20 + len(encoded) + len(tail))
result += struct.pack('<II', len(encoded), json_type) + encoded + tail
(ASSETS / 'pie_ps2_toasted.glb').write_bytes(result)

# Preserve an editable source with the same material tint and studio lighting.
bpy.ops.wm.open_mainfile(filepath=str(ART / 'golden_pie_ps2.blend'))
for material in list(bpy.data.materials):
    if not material.use_nodes:
        continue
    bsdf = material.node_tree.nodes.get('Principled BSDF')
    if not bsdf or not bsdf.inputs['Base Color'].is_linked:
        continue
    material.name = 'Toasted pie | dark golden brown crust'
    tree = material.node_tree
    source_socket = bsdf.inputs['Base Color'].links[0].from_socket
    tint = tree.nodes.new('ShaderNodeMixRGB')
    tint.blend_type = 'MULTIPLY'
    tint.inputs[0].default_value = 1
    tint.inputs[2].default_value = TINT
    tree.links.new(source_socket, tint.inputs[1])
    tree.links.new(tint.outputs[0], bsdf.inputs['Base Color'])
bpy.ops.wm.save_as_mainfile(filepath=str(ART / 'toasted_pie_ps2.blend'))
scene = bpy.context.scene
scene.render.resolution_x = 900
scene.render.resolution_y = 750
scene.cycles.samples = 16
scene.render.filepath = str(ROOT.parent / 'outputs' / 'toasted_pie_preview.png')
bpy.ops.render.render(write_still=True)
print('TOASTED_PIE_COMPLETE')
