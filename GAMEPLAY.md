# PIEday prototype

Run the Godot project normally to begin before opening. Hold **E** over the
bathroom and kitchen stains, collect the trash bag with **E**, and deposit it at
the refuse hatch inside the dining room. Use the green shift board behind the
counter to open. Four customers make one shift.

**F6** starts a fresh customer demo with chores completed. **F7** starts the next
pre-shift task list. The customer demo launches with `-- --customer-demo`.

Customers enter through the front door and stop at the counter. Look at the
customer and press **E** to hear their order. The serving tray stays on the counter. Pick up one item, then click the counter
tray (or press E) to place it. Collect the exact items:

- Pies: open the kitchen cooler. Left column is meat, middle apple, right cherry.
- Donuts: marked staff-side pickup behind the pastry display.
- Coffee: click the empty cup stack beside the machine, click the machine to
  place the cup and fill it, then click the full cup to pick it up. Click the counter tray to set it down.
  Filling takes 2.5 seconds. E also works. Q returns a held empty cup.
- Soda: pull an empty soda cup from the dispenser's built-in front cup holder, click
  the dispenser to fill it, then pick up the full cup and click the counter tray
  to place it. Soda filling takes 1.8 seconds. The soda cup uses the same mesh
  and texture as the cups in the holder. Q returns an empty cup to its source.

Click the tray with an empty hand to take the last item back off it.
**Q** returns a held pie to its shelf or sets aside a held item. With an empty
hand, Q removes the last tray item. Click or press **E** at
the service bell beside the tray to submit the order. Talking to the customer
only repeats the order. Exact item types and quantities must match.
Wrong orders trigger an angry response and a faster exit. Correct orders trigger
a thank-you. Another customer arrives after the previous one leaves.

The customer uses the user's downloaded **Base Humanoid Mesh**, converted in
Blender into a clothed low-poly character with a connected skinned body and a
five-bone skeleton for procedural walking. Flavor names currently distinguish
the pies; their pastry mesh is shared.
