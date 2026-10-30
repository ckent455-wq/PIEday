# Changelog

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
