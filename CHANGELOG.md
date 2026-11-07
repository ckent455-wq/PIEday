# Changelog

## 0.9.1

- Added a main menu with separate Solo Campaign and Online Co-op buttons. The co-op lobby is available before campaign saves load.

## 0.9.0

- Two-player online co-op service shifts with separate hands and shared customers, equipment, tray, and earnings.
- Full campaign orders draw from the existing menu at random without consecutive recipe repeats during a shift.
- Correct orders earn a $145 service reward. Completing closing duties after a correct order earns $275. The treatment goal stays at $15,000.

## 0.8.0

- Editable kitchen pistol centered on the right-hand table, with firing sound and muzzle flash. Only available during clothing-required encounters.
- Shot customers become jointed ragdolls that collide with the diner and remain for closing cleanup.
- Pick up bodies with E, carry them to the outdoor dumpster, and press E to dispose; Q sets them down. Bodies hold a fixed pose while carried and resume physics when set down.
- Body disposal is required before completing closing duties. Manual saves preserve body poses and the carried body; older saves remain supported.
- Ragdolls ignore character contact and use constrained joints to prevent contact instability.

## 0.7.0

- Compact diner HUD with treatment savings and the shift clock. Grandpa's condition appears at the clipboard and bedside.
- Coffee requires an empty cup before brewing. Pies are ready at five seconds and burn at ten, with a countdown after the ding.
- Correctly served customers have a 75% dine-in chance when a clean booth is available. Customers follow the aisles to and from all six booths.
- The separate demo preset includes practice orders for coffee, donuts, fountain soda and baking.

- Separate playable demo: intro, one shift, guaranteed doorway encounter during closing, hospital conversation, earnings ending and replay. Temporary progress stays separate from campaign saves.
- Bathroom and kitchen doors stay closed until player interaction.
- Customers open the front door only while passing through, wait for its swing, and close it behind the last person. Front-door state is preserved in manual saves.

## 0.6.0

- Strawberry icing, chocolate icing and plain glazed donuts, with labeled case sections and flavor-specific orders.
- Cola, Lemon Fizz and Dr. Paw Paw fountain drinks, three flush-mounted labeled buttons and three aligned nozzles; matching colored cups and orders.
- Pies become perfectly baked after five seconds, with a one-time oven-ready bell. They burn at thirteen seconds.
- Selected Freesound recordings for coffee/soda pouring, cooler opening and floor scrubbing. Pouring follows fill progress; scrub audio stops on release, look-away or completion.
- Original BeepBox music: Counter Service for daytime, Last Customer for closing, and Still Here for hospital visits. Music continues through dialogue and pauses with Esc.
- Restored animated monster waits in the back doorway after trash disposal. It starts dissipating immediately on sight, with soft textures, drifting shadow wisps and spatial audio.
- Haunted cooler doors open while watched; normal cooler openings share the selected sound.
- Save-free scare adjustment mode exposes all six encounters, direct selection, replay and next controls.
- Camera-relative diner movement fixes the test camera/control mismatch. Expanded gameplay, audio, music, save and encounter checks.

## 0.4.0

- Six textured, rigged customer appearances with new heads, varied clothing,
  relaxed arms and walking. Includes editable source assets and conversion script.
- Rare unclothed adult customer encounter: refuse service with E. Refusal has
  no earnings or streak penalty and preserves prepared food.
- Six random closing encounters: unattended bell, flickering lights, a fleeting
  yard figure, bathroom knocks, a cooler opening, and moving footsteps.
  At most one encounter per closing, with a 30% chance of a quiet night.
- The shift ends immediately at zero. All remaining customers walk out while
  closing chores begin; unfinished orders cause no earnings or streak penalty.
- Reliable physical E input checked alongside player movement.
- Smooth dumpster collision, filled fence gaps, and taller player-only yard
  boundaries prevent getting stuck after jumping onto the dumpster.
- Regression checks cover the new customers, refusal, closing encounters,
  input, immediate closing and dumpster movement.

## 0.3.0

- Up to three customers form a visible line. The next person steps up while
  the previous customer exits independently.
- New arrivals stop at closing; serve everyone already in line before cleanup.
- Waiting customers show subtle impatience after 45 seconds. Queue waits have
  a 60-second grace period before affecting tips; nobody abandons the line.
- Separate baked burnt-pie model, material atlas, editable Blender source, and
  generation script. The burnt appearance persists in the oven, hand, and tray.
- Queue lifecycle, payment, closing, and reset coverage in gameplay checks.

## 0.2.0

- Segmented typewriter intro with the downloaded font and keypress sound,
  E/Space controls, and a fade into the diner.
- $15,000 treatment goal, saved cash, tips, service and streak rewards,
  and a closing bonus. Earnings are tuned toward roughly 26-33 days at
  6-8 correct orders per shift, with no hard deadline.
- Five-minute service shifts, faster customer arrivals and exits,
  balanced pie orders, and randomized shirt colors.
- Closing chores after service, nighttime lighting, a visible carried trash
  bag, and an opening back door to a dressed service yard with the dumpster.
- Linked oven doors and pie baking: ready at seven seconds, burnt at thirteen.
  Toasted pies retain their appearance when carried and served.
- Easier one-click coffee preparation, corrected soda filling position,
  and a clear-glass donut display with direct pickup prompts.
- Blender clipboard replaces the shift board. Repeated interaction cannot
  accidentally reset an active shift.
- Downloaded desk-bell sound, reduced HUD clutter, cash/clock display,
  editable source assets, and expanded gameplay verification scripts.

## 0.1.1

- Portable Windows prototype and development setup documentation.
