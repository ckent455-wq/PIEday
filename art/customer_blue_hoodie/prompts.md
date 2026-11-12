# Hoodie customer

User-provided reference photo, generated diffuse atlases, and editable rigged Blender model. Rebuild using art/customer_portrait/build_customer.py with the matching --variant and --source options. Existing customer animations are reused.

## boy_face

Create a square PS2 game head UV diffuse texture. Image 1 is the EXACT UV LAYOUT TEMPLATE, image 2 is the identity reference of the boy. Replace the adult face and hair in image1 with the boy's recognizable youthful face, brown fringe/bowl haircut, hazel eyes, freckles, gentle closed-mouth smile, no facial hair. Preserve template feature coordinates and flattened wrap layout precisely: eyes 44% down, nose60%, mouth76%, chin97%, ears at sides53%, centerx50%. Hair fills upper edge and corners. Just face/hair/ears, no neck or clothing. Flat even light, painted photographic game texture, no shine, no baked strong shadows. Black unused bottom corners. No labels, UV lines, borders or head render. Square atlas.

## boy_shirt

Image1 is EDIT TARGET an exact flattened clothing UV atlas. Image2 is clothing reference. Keep EVERY UV island silhouette, placement, scale, orientation and black padding EXACTLY as image1. Replace gray polo pieces with royal blue hoodie fabric matching boy reference, with white NIKE wordmark on front chest ONLY, hood collar instead of polo collar, kangaroo pocket, plain blue back and full length blue sleeves covering existing forearm skin to wrists. Preserve hands skin, replace khaki trousers with dark navy casual pants, replace teal shoes with dark gray sneakers. Do not add new islands or render clothes. Shirt front island is bottom center, rotated with neck at right, hem at left: align wordmark accordingly. Back island middle center rotated opposite. Single square diffuse game atlas, soft fabric folds, no background scene, labels or UV lines. Precise atlas preservation.
