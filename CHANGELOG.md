# Changelog

## 0.15.2

- The glasses-wearing regular visits to complain about the food and suggest smoked sausage. The shared dialogue works in solo and co-op.

## 0.15.1

- Add blue and gray hoodie customers based on the provided portraits, bringing the normal customer rotation to ten appearances.
- Include editable Blender sources, generated face/clothing atlases, and shared animation support.
- Match the younger customer with smaller proportions, interaction collider, and seated height.
- Correct hoodie sleeve, chest graphic, and trouser mapping; expand animation preview controls to 1�9 and 0.


## 0.15.0

- Appliances can break with a bang, smoke, and an out-of-order sign. Pay for repairs to restore their menu items.
- Eight customer appearances now include two photo-based customers, with gray polo/khaki and checked-shirt outfits, improved proportions, and corrected head placement.
- Customers use retargeted idle, walk, and jog animations.
- Robberies wait for an accepted order and staff at the front counter. Robbers take only unspent current-shift takings; previous days remain safe.
- Equipment state and robbery accounting persist in saves and co-op.


## 0.14.1

- The robber rushes past the queue while customers at the counter, in line, and at the booths flee through the front door.
- Shooting the robber pauses arrivals and the shift clock. Service resumes after the body is taken to the outdoor dumpster. Body disposal has been removed from the closing checklist.
- Grandpa's homecoming plays the original BeepBox track Grandpa's Home. After his last line, the screen fades to black and the credits begin on the next downbeat.
- The credits recognize ckent455-wq for writing and original food models, credit ckent455-wq and BeepBox for original music, and list third-party assets separately.

## 0.14.0

- Finish closing with $15,000 saved to win the campaign. The closing bonus counts toward the goal.
- Grandpa returns after successful surgery, walks through the front door, performs a celebratory jig, and thanks the player in typewriter dialogue.
- Clear center-aisle camera framing, synchronized door timing, and hidden collision helper geometry for the cutscene.
- Victory persists across reloads. Ending controls offer replay, a new campaign, main menu, and quit; manual save slots remain intact.
- Co-op supports victory travel and requires matching updated builds.

## 0.12.1

- Soda empty-cup pickup covers the full front holder with more vertical tolerance; rays from multiple approach angles are verified without intercepting flavor buttons or filled-cup rays.

- Donut pickups remove the exact case item, stop when a flavor sells out, and preserve depleted slots in saves/co-op. Returning held or tray donuts restores stock; fryer batches refill the case during service.

- The entire donut case can be filled to eight per flavor (24 total). Partial refills keep the unused portion of a six-donut batch for other shelves, including across saves and co-op.

- Service shifts last five minutes, with untimed opening prep and closing chores.
- Correct-order service reward is $80 and the closing bonus is $300. Menu prices, tips and streak bonuses remain; simulations with 9–16 correct orders per shift reach $15,000 in about 8–12 shifts. Existing savings are unchanged.

## 0.12.0

- Opening prep uses the existing fryer baskets: fry six donuts, lift between five and ten seconds, then ice and stock strawberry, chocolate and glazed batches. Oil ripples, bubbles and positional sizzling accompany frying.
- Switch the classic red-and-blue neon OPEN sign on after prep to begin service. It switches off at closing.
- Burgers join random customer orders. Cook raw patties on the flat top for three seconds per side, flip with E, then assemble on the separate bun tray. Patties burn at twelve seconds; correct burgers sell for $8.
- Original Blender raw/cooked patties and sesame buns replace placeholder food. Raw meat and buns use separate trays.
- The saved diner layout contains the kitchen, cooler and yard changes visible in the editor. Burger equipment follows the edited stove and prep counter.
- The nurse mistreatment event includes a non-graphic witnessed cutscene, louder slap, Grandpa grunt, recoil, brief blackout and bedside dialogue. It removes twenty health points in addition to daily decline, once per incident.
- Nurse setbacks have double selection weight; the twelve-percent overall setback roll, six-day spacing and no consecutive repeats remain.
- New equipment state and the witnessed-incident flag are saved and replicated in co-op. Both players must use v0.12.0.

## 0.11.0

- Main-menu updater checks GitHub, verifies and installs the Windows release, and opens the updated game. Future launches redirect to the newest installed version.

- Co-op player bodies and carried items face the same direction as their player cameras.

## 0.10.0

- Co-op follows the story, service shift, closing chores, scares, hospital visits and subsequent days.
- Customer conversations use the solo dialogue presentation and pause both players. Hospital choices and dialogue are shared.
- Dine-in meals, table litter, held items, ragdolls and scare effects are replicated.
- The host manages persistent co-op progress and manual saves in separate co-op files.
- Both co-op characters wear diner uniforms and aprons.

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
