import bpy, json
bpy.ops.wm.open_mainfile(filepath=r'C:\Users\jkern\Documents\ChatGPT\PIEday\art\hospital\source\Hospital_assets\hospital.blend')
for o in bpy.data.objects:
    if o.type == 'MESH':
        print('ASSET', o.name, 'LOCATION', list(o.location), 'SIZE', list(o.dimensions), 'MATERIALS', [m.name for m in o.data.materials if m])
print('IMAGES', [(i.name,i.filepath) for i in bpy.data.images])
