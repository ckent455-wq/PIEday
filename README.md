# PIEday

Current version: **0.8.0**. Adds a kitchen pistol for clothing-required encounters,
jointed customer ragdolls, and a closing chore to pick up bodies and carry them
to the dumpster. Includes the full campaign, hospital visits, save/load, donut
and soda varieties, music, and closing scares.

The game opens with a typewriter-style story on a black screen. Press E or
Space to reveal each passage and advance, then choose Open the Diner. Earn $15,000 toward Grandpa's
treatment; the upper-left cash display tracks the goal. Existing cash is retained.

A first-person diner prototype built with **Godot 4.7.2**. Prepare customer orders
with meat, apple, or cherry pies, donuts, coffee, and fountain soda. Assemble the
order on the counter tray and **ring the service bell to serve it**. Wrong orders
make customers angry; correct orders make them leave happy.

Up to three customers line up. The next customer steps forward while the
previous one leaves. At closing, queued customers walk out. You can finish an
already accepted order before nighttime cleanup; customers whose orders were not
taken leave without a penalty.

## Play the Windows release

Download the Windows ZIP from this repository's **Releases** page and extract
the entire folder. Keep `PIEday.exe` and `PIEday.pck` together. Run `PIEday.exe`
for the full day flow, or press **F6 in the game** to jump into customer service.
The unsigned prototype may show a Windows security
prompt on a new PC.

- **WASD / mouse:** move and look. **Shift:** sprint. **Space:** jump.
- **E / left click:** pick up an item or interact. **E:** open and close doors.
- **Q:** return or set aside a held item, or remove the last tray item.
- **Esc:** pause/resume (Resume, Save Game, Load Game, Restart Day, Quit to Desktop). **R:** respawn.
- **F6:** restart the customer demo. **F7:** jump to nighttime closing chores.

Take an order from the customer. Carry one item at a time and click the stationary
counter tray to set it down. The customer interaction repeats the order;
**the bell submits the tray**.

Pies from the cooler must be baked in the double-door kitchen oven. Open both
doors, click inside with a pie in hand to load it, then close both doors.
Open the doors at 5 seconds and before 10 seconds for a perfect toasted pie.
Press E on either oven door to open or close both together; opening pauses heat. Open both and click inside with an empty hand
to collect the pie, then put it on the counter tray. At 10 seconds it burns;
customers reject burnt or undercooked pies. The timer is above the oven doors.

Take an empty cup from the stack beside the coffee machine. Use the machine
to fill it, collect it when READY, then put it on the tray. Soda uses
the cups in the dispenser's **front-mounted cup holders**, with the same cup
model in your hand, under the nozzle, and on the tray.

Service lasts three minutes after opening. At zero, new arrivals stop and queued
customers leave. An already accepted order can be finished before closing chores.

Use **Esc → Save Game / Load Game** for three manual save-state slots. These are
separate from autosave and retain the current shift, order, food, position and
Grandpa's health. The death ending also offers **Load Saved Game** alongside
**Start a New Campaign**. New campaigns keep manual slots. Saves live under
Godot's user data directory in `manual_saves/`.
Nighttime closing chores begin after the final accepted order (or immediately if
there is none): clean the bathroom
and kitchen, collect the trash, and take it through the kitchen back door to
the dumpster in the fenced service yard. Press E on the back door to open or
close it, and click or press E at the dumpster to throw away the held bag.
All chores must be finished before the day's summary and the next day. See
[GAMEPLAY.md](GAMEPLAY.md) for more detail.

## Continue development on another PC

1. Install **Godot 4.7.2 Standard**. This project uses GDScript, not .NET.
2. Clone this repository, or download and extract its source ZIP.
3. Import `project.godot` in Godot. Allow its first asset import to finish.
4. Press **F6 in the running game** for the customer demo, or play the full
   day flow normally. From the terminal, use:

   ```text
   godot --path . -- --customer-demo
   ```

All runtime assets are included. No Downloads-folder files, API keys, account
connections, or third-party Godot plugins are needed to run the project.

## Source art

`art/` contains editable Blender files, generation scripts, renders, and the
source humanoid used for the customer. Blender **5.0** was used for these files.
The folder is excluded from Godot importing with `.gdignore`; game-ready models
are in `assets/`. Blender is only needed to edit or regenerate source art.

- `art/customer/customer.blend`: connected, skinned customer body and skeleton.
- `art/pie/golden_pie_ps2.blend`: domed low-poly pie with a 256px texture atlas.
- `art/tray/black_cafeteria_tray.blend`: modeled black cafeteria tray.
- `art/clipboard/shift_clipboard.blend`: wall-mounted shift clipboard.
- `art/pie/toasted_pie_ps2.blend`: separate toasted pie variant.
- `art/pie/burnt_pie_ps2.blend`: separate unevenly charred pie variant.
- `service_yard.tscn`: editable yard layout; move `OutdoorDumpster` here.
- `assets/`: diner model and textures, exported models, and the bell sound.

See [ASSET_SOURCES.md](ASSET_SOURCES.md) for asset provenance. The repository does
not grant new rights to third-party assets beyond their original terms.

## Build a Windows release

Install Godot's **4.7.2 Windows export templates**, then run:

```text
godot --headless --path . --import
godot --headless --path . --export-release "Windows Desktop" builds/windows/PIEday.exe
```

Create `builds/windows` first. The release needs both the EXE and PCK. Generated
builds and Godot's import cache are ignored by Git.

## Checks

The `verify_*.gd` scripts exercise interactions, drink preparation, customer
outcomes, doors, and movement. For example:

```text
godot --headless --path . --script verify_soda.gd --quit-after 1800
godot --headless --path . --script verify_coffee.gd --quit-after 1800
godot --headless --path . --script verify_bell.gd --quit-after 1800
godot --headless --path . --script verify_balance.gd --quit-after 1800
godot --headless --path . --script verify_closing_chores.gd --quit-after 1800
```

Visual checks such as `verify_customer_pose.gd` need a graphical renderer. This
is a playable prototype; animations, task variety, audio, and final art are still
in development. Pie flavors currently share the same pastry mesh and are
identified by shelf labels and the interaction prompt.

Correctly served customers may dine at a booth. Some leave cups and wrappers behind. After closing, clear the tables into the indoor trash can before collecting its bag and taking it to the outdoor dumpster. Dirty tables and seated customers are preserved in manual save states.


## Encounter adjustment mode

Run `PIEday.exe -- --scare-test` to test all six nighttime encounters without
writing campaign progress. Keys **1–6** select bell, flicker, doorway monster,
stall knocks, cooler opening, and footsteps. **R** replays; **N** advances.
The doorway test starts with a trash bag: dispose of it and turn toward the diner.

Editable BeepBox music projects and song URLs are in `art/music/`.

Run the gameplay checks with PowerShell: .\run_checks.ps1 -Godot 'C:\path\to\Godot_console.exe'. Some checks open a window to verify input and layout; reports are written to .godot/verification/.
