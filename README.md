# PIEday

A first-person diner prototype built with **Godot 4.7.2**. Prepare customer orders
with meat, apple, or cherry pies, donuts, coffee, and fountain soda. Assemble the
order on the counter tray and **ring the service bell to serve it**. Wrong orders
make customers angry; correct orders make them leave happy.

## Play the Windows release

Download the Windows ZIP from this repository's **Releases** page and extract
the entire folder. Keep `PIEday.exe` and `PIEday.pck` together. Run `PIEday.exe`
for the full shift flow, or press **F6 in the game** to start with the daily
tasks already complete. The unsigned prototype may show a Windows security
prompt on a new PC.

- **WASD / mouse:** move and look. **Shift:** sprint. **Space:** jump.
- **E / left click:** pick up an item or interact. **E:** open and close doors.
- **Q:** return or set aside a held item, or remove the last tray item.
- **Esc:** release the mouse; click to capture it again. **R:** respawn.
- **F6:** restart the customer demo. **F7:** begin a new shift with daily tasks.

Take an order from the customer. Carry one item at a time and click the stationary
counter tray to set it down. The customer interaction repeats the order;
**the bell submits the tray**.

Coffee requires an empty cup from the stack beside the coffee machine. Place it
under the spout, wait for it to fill, pick it up, and put it on the tray. Soda uses
the cups in the dispenser's **front-mounted cup holders**, with the same cup
model in your hand, under the nozzle, and on the tray.

Four customers make a shift. Before opening a normal shift, clean the bathroom
and kitchen, collect the trash, and take it to the indoor refuse hatch. See
[GAMEPLAY.md](GAMEPLAY.md) for more detail.

## Continue development on another PC

1. Install **Godot 4.7.2 Standard**. This project uses GDScript, not .NET.
2. Clone this repository, or download and extract its source ZIP.
3. Import `project.godot` in Godot. Allow its first asset import to finish.
4. Press **F6 in the running game** for the customer demo, or play the full
   pre-shift flow normally. From the terminal, use:

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
```

Visual checks such as `verify_customer_pose.gd` need a graphical renderer. This
is a playable prototype; animations, task variety, audio, and final art are still
in development. Pie flavors currently share the same pastry mesh and are
identified by shelf labels and the interaction prompt.
