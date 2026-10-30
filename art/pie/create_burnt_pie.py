"""Bake a separate charred pie variant; keep original and toasted assets intact."""
from pathlib import Path
import bpy

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / 'art/pie'
ASSETS = ROOT / 'assets/pies'
bpy.ops.wm.open_mainfile(filepath=str(ART / 'golden_pie_ps2.blend'))
pie = bpy.data.objects['PS2_Golden_Domed_Pie']
bpy.ops.object.select_all(action='DESELECT')
pie.select_set(True)
bpy.context.view_layer.objects.active = pie
mat = pie.data.materials[0].copy()
mat.name = 'Burnt pie | uneven charcoal crust'
pie.data.materials.clear()
pie.data.materials.append(mat)
tree = mat.node_tree
bsdf = tree.nodes.get('Principled BSDF')
original = bsdf.inputs['Base Color'].links[0].from_socket
noise = tree.nodes.new('ShaderNodeTexNoise')
noise.inputs['Scale'].default_value = 7.5
noise.inputs['Detail'].default_value = 3
noise.inputs['Roughness'].default_value = .8
ramp = tree.nodes.new('ShaderNodeValToRGB')
ramp.color_ramp.elements[0].position = .30
ramp.color_ramp.elements[0].color = (.012,.010,.008,1)
ramp.color_ramp.elements[1].position = .72
ramp.color_ramp.elements[1].color = (.24,.105,.035,1)
middle = ramp.color_ramp.elements.new(.53)
middle.color = (.055,.035,.022,1)
tree.links.new(noise.outputs['Fac'],ramp.inputs[0])
mix = tree.nodes.new('ShaderNodeMixRGB')
mix.blend_type = 'MULTIPLY'
mix.inputs[0].default_value = 1
tree.links.new(original,mix.inputs[1])
tree.links.new(ramp.outputs['Color'],mix.inputs[2])
tree.links.new(mix.outputs[0],bsdf.inputs['Base Color'])
image = bpy.data.images.new('Burnt_Pie_256_Atlas',width=256,height=256,alpha=False)
target = tree.nodes.new('ShaderNodeTexImage')
target.image = image
tree.nodes.active = target
scene = bpy.context.scene
scene.render.engine = 'CYCLES'
scene.cycles.samples = 8
scene.render.bake.use_pass_direct = False
scene.render.bake.use_pass_indirect = False
scene.render.bake.use_pass_color = True
scene.render.bake.margin = 3
bpy.ops.object.bake(type='DIFFUSE')
image.filepath_raw = str(ASSETS / 'pie_ps2_burnt_albedo.png')
image.file_format = 'PNG'
image.save()
image.pack()
tree.links.new(target.outputs['Color'],bsdf.inputs['Base Color'])
target.interpolation = 'Closest'
bsdf.inputs['Roughness'].default_value = .97
pie.name = 'PS2_Burnt_Domed_Pie'
bpy.ops.wm.save_as_mainfile(filepath=str(ART / 'burnt_pie_ps2.blend'))
bpy.ops.export_scene.gltf(filepath=str(ASSETS / 'pie_ps2_burnt.glb'),use_selection=True,export_format='GLB')
scene.render.resolution_x = 900
scene.render.resolution_y = 750
scene.cycles.samples = 16
scene.render.filepath = str(ROOT.parent / 'outputs/burnt_pie_preview.png')
bpy.ops.render.render(write_still=True)
print('BURNT_PIE_COMPLETE')
