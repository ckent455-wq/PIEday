# PIEday prototype

Up to three customers can be in service or waiting in line. Waiting customers
step forward as soon as the previous order is served, while departing customers
walk out independently. At closing, arrivals stop and everyone already in line
is served before nighttime chores begin. Waiting in line has a 60-second grace
period before it can affect tips; nobody abandons the queue in this prototype.

Correct orders earn their menu total: meat pie $8, apple/cherry pie $6,
donut $2, coffee $3, soda $2. Incorrect orders earn nothing. A tip has a
50% base chance and is worth $3-$8. Service within 60 seconds adds 15 percentage
points; over 120 seconds subtracts 20. A perfectly baked pie adds another 15.
Timing starts when you first take the order, and hearing it again does not
restart the clock. A brief payment message shows order income, tip, and cash.
The closing summary shows sales, tips and total earnings. Cash saves locally
between sessions; daily sales and tips reset when opening the next shift.

Each correct order also earns a clearly labeled $35 service reward. Consecutive
correct orders add a streak bonus: $0, $5, $10, then $15 per order. A mistake
resets the streak but never deducts cash. Completing all closing chores after
at least one correct order earns $100 once per day. Empty days earn no bonus.
At 6-8 fast, correct orders per day, simulated earnings average roughly $460-$589:
about 26-33 days toward the $15,000 goal. This is a pacing target, not a deadline.

Open the diner at the shift clipboard. Service lasts five minutes. Finish the
last customer at closing; then it becomes night and closing chores begin.
Hold **E** over the
bathroom and kitchen stains, collect the trash bag with **E**, and deposit it at
the dumpster outside the kitchen back door. The door replaces the flat-top grill:
press E to open it, walk into the fenced service yard, and click or press E on
the dumpster while holding the bag. Return through the door to the kitchen.
Finish all three chores to see the day's earnings summary. Use the shift
clipboard to begin the next day; daylight returns and no morning chores are needed.

**F6** starts a fresh customer demo. **F7** jumps to nighttime closing chores
for testing. The customer demo launches with `-- --customer-demo`.

Customers enter through the front door and stop at the counter. Look at the
customer and press **E** to hear their order. The serving tray stays on the counter. Pick up one item, then click the counter
tray (or press E) to place it. Collect the exact items:

- Pies: open the kitchen cooler. Left column is meat, middle apple, right cherry.
  Carry a pie to the double-door kitchen oven. Press E on either oven door to open both, then click
  inside to load it. Close both doors to bake; the timer starts once they shut.
  Open the doors at 7 seconds and before 13 seconds for a perfect toasted pie.
  Opening the oven doors pauses cooking. With both doors open and an empty hand,
  click inside to take out the pie, then place it on the customer tray.
  Undercooked pies can go back in to finish. At 13 seconds the pie burns.
  Customers reject undercooked or burnt pies; raw pies cannot go on the tray.
  The oven display shows elapsed time and baking status. One pie fits at a time.
- Donuts: marked staff-side pickup behind the pastry display.
- Coffee: click the machine (or press E) with an empty hand to automatically
  place a cup and start filling. Click the machine again when READY to collect
  the coffee, then click the counter tray to set it down. You can also take an
  empty cup from the stack first and place it in the machine manually.
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
