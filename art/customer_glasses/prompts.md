# Glasses customer

Photo supplied by the user; texture atlases generated with the built-in imagegen tool. Gray short-sleeved polo and khaki pants were explicitly requested. The corrected centered head and short neck are shared with the first portrait build pipeline. Existing customers are retained.

Generated masters: `art/customer_glasses/face_atlas.png`, `art/customer_glasses/shirt_atlas.png`.
Runtime: `assets/customers/male_glasses.glb`, `assets/customers/male_glasses_face_atlas.png`, `assets/customers/male_glasses_shirt_atlas.png`.
Editable model: `art/customer_glasses/portrait_customer.blend`.
Rebuild: Blender background mode with `--python art/customer_portrait/build_customer.py -- --variant male_glasses --source art/customer_glasses`.

The shoulder UVs are projected onto a continuous shirt fabric area, keeping the atlas's collar/skin opening from stretching across the left shoulder. The center collar, forearm skin and khaki trouser mapping remain intact.

This character uses the male_1/male_body_pants rig and mesh. The head is raised 2.25 cm with a matching neck extension, halfway between the original short neck and the longer revision; the forward/sideways alignment correction is retained. Both portrait variants use a flatter chest and straighter shirt waist for a regular male fit.

## Face prompt

Use case: identity-preserve. Make a square flattened head UV texture for a PS2 low-poly game NPC. Image 1 is the exact UV LAYOUT edit target, image 2 is the identity reference. Replace the man in the atlas with the man from image 2, retaining his recognizable facial likeness: pale warm skin, high receding hairline with mostly bald forehead/top, short fine grey-brown hair at the sides, thin dark rectangular metal glasses with clear lenses so eyes remain visible, broad nose, clean-shaven jaw, slightly open friendly mouth. Preserve the template's exact UV framing and positions: centered front face, ears at both edges, eyes centered at y44%, nose tip at y62%, mouth at y75%, chin at y97%. Keep face symmetry and upright head, no tilt. Hair only at sides and rear; scalp skin on crown and high forehead, no thick full head of hair. Even diffuse lighting, no forehead glare or dramatic shadows. A game-ready diffuse texture atlas, not a rendered head or portrait photograph: no neck below chin, clothes, background, text, UV lines, shadows outside face or borders. Fill full square following template, black unused bottom corners. Maintain modest PS2 phototexture style suited to runtime downsampling to256px.

## Final clothing prompt

Use case: precise-object-edit. Square clothing diffuse UV texture atlas for a PS2 low-poly game character. Image 1 is exact UV layout edit target; image 2 is polo-shirt reference. Replace pink shirt regions with the reference man's plain slate/charcoal blue-grey polo shirt, small open collar, short button placket with two small light buttons, NO necktie, no logos, no red checks. Change ALL brown/purple trouser islands to light tan/beige KHAKI PANTS with the same pocket seams and folds, visibly khaki not brown/purple. Retain every UV island silhouette position edge and black padding, and keep shoes unchanged. The source atlas sleeves are long: make sleeve pieces show grey polo fabric from shoulder to just above elbow, then natural pale warm skin for exposed forearms down to hands, so they read as short sleeves on the existing model. Match both sleeve pieces with identical cuff height. Preserve hands and subtle cloth folds/collar outlines. Remove the turquoise necktie completely, paint polo fabric in its place and a narrow open neckline at collar. Match photograph's shirt color and plain knit texture. No face, portrait, rendered clothing, text, new islands, framing change or backdrop. Entire output must be a flat square UV atlas matching original, suitable for 256px game texture.
