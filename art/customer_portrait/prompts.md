# Portrait customer assets

Created with the built-in imagegen tool using the user-provided portrait in `reference.jpg` and the existing male_1 UV textures as layout references. Existing characters were preserved.

Generated masters: `art/customer_portrait/face_atlas.png` and `art/customer_portrait/shirt_atlas.png`.
Runtime 256px textures: `assets/customers/male_photo_face_atlas.png` and `assets/customers/male_photo_shirt_atlas.png`.
Rigged model: `assets/customers/male_photo.glb`. Editable Blender source: `art/customer_portrait/portrait_customer.blend`.
Rebuild: Blender background mode with `--python art/customer_portrait/build_customer.py`.

The portrait head mesh is centered laterally over the spine and moved back to the body's neck center. Its lower rear edge tapers into a short replacement neck, removing the original body's protruding neck stub. The replacement neck samples skin from the face atlas and uses the existing rig.

The male torso's pectoral bulge is flattened and its pinched waist filled out for a straighter shirt fit. The shared builder also supports the male_glasses variant through command-line arguments.

## Face prompt

Use case: identity-preserve. Asset: a square flattened head UV texture atlas for a PS2 low polygon game character. Image 1 is the EDIT TARGET / exact UV layout template; Image 2 is the FACE IDENTITY reference. Change the face in Image 1 to the man in Image 2, preserving his recognizable broad face, blue-grey eyes, warm skin, brown side-swept short hair and full short brown beard/moustache and friendly small toothy smile. Match Image 1's exact flattened layout, framing and feature coordinates: eyes at 44% down, nose at 60%, mouth at 76%, chin at 97%, ears at left/right around 53%; face centered x50%. Hair fills top corners and top edge. Preserve the template's ear positions, facial outline and chin position. No shoulders, clothing, neck below chin, background scene, labels, UV lines, or borders. Neutral even diffuse lighting without specular highlights, painted phototexture suitable for downsampling to 256x256, realistic likeness with low-resolution PS2 texture detail. Black unused bottom corners. Entire output is just the seamless square texture atlas, not a render of a head.

## Shirt prompt

Use case: precise-object-edit. Asset: square diffuse clothing UV texture atlas for an existing low-poly PS2 character. First image is EDIT TARGET with an exact UV island layout, second image is shirt fabric reference. Keep every UV island's silhouette, location, size, seams, orientation, black padding and ALL existing skin/hands, pants and shoes unchanged. Change ONLY the pink/coral shirt UV islands into the reference man's dark burgundy/red-and-black small checked flannel shirt fabric. Remove the turquoise necktie completely, replacing it with checked shirt fabric and a narrow open black undershirt at the collar. Preserve shading folds buttons collar/cuffs from the existing shirt. The reference shirt has a dark red base with closely spaced black/navy gingham grid. Paint that recognizable pattern across all shirt/sleeve pieces at a consistent scale. Do not put the reference photo itself onto the atlas. Do not add faces, heads, labels, rendered clothing, new UV pieces, borders or a different layout. Flat game texture atlas output only, same square framing, suitable for 256x256 runtime texture. Precise preservation of all non-shirt pixels and island bounds.
