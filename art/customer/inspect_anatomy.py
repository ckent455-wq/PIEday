from pathlib import Path
import bpy
bpy.ops.wm.open_mainfile(filepath=str(Path(__file__).resolve().parent/'source'/'Humanoid.blend'))
o=bpy.data.objects['HumanoidBase_NotOverlapping']
for lo,hi in [(0,.12),(.12,.20),(.20,.28),(.28,.38),(.38,.52),(.52,.68),(.68,.85)]:
    vv=[v.co for v in o.data.vertices if lo<=abs(v.co.x)<hi and v.co.z>1.0]
    print('BAND',lo,hi, 'count',len(vv),'minmax',[(min(v[k] for v in vv),max(v[k] for v in vv)) for k in range(3)] if vv else '')
