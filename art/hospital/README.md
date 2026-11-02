# Hospital kit

User-provided `Hospital_assets.zip`, downloaded November 2, 2026.
Extract into `source/` so `source/Hospital_assets/hospital.blend` exists.
Run Blender with `--factory-startup -b --python art/hospital/export_assets.py`
from the project directory to rebuild the portable models in `assets/hospital/`.

The original 564 MB pack stays local and is ignored by Git. Exported GLBs contain
the geometry and embedded 256 px base-color textures needed to run the scene
on another PC. No original archive or Blender installation is needed to play.
