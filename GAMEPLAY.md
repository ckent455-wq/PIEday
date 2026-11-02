# PIEday prototype

Press **Esc** to pause. The menu offers Resume, Save Game, Load Game, Restart Day,
and Quit to Desktop.
The shift timer, customers, brewing, baking, chores, and closing encounters freeze
until you resume. Esc also resumes; in the restart confirmation it cancels the
restart first. Restart Day returns to preparation and retains cash already earned.

Save Game provides three manual slots, independent of the campaign autosave.
Each slot shows its day, Grandpa's health, cash, location and save time. Saving
over an occupied slot asks first. Save states retain player position, the current
shift and clock, customers and their orders/queue, tray and held food, pie stock
and baking, coffee/soda filling, doors, closing duties and hospital visit state.
Load Game is available while paused and on the death ending. Confirming a load
replaces current progress with that slot, including restoring Grandpa's earlier
health. Empty/unavailable slots cannot be loaded. Starting a new campaign resets
the active campaign but keeps all manual slots. Save at least one living state
before Grandpa dies if you want to return to it; death never overwrites a slot.

The HUD shows cash and treatment progress at the upper left, with shift status
and the current order at the upper right. Order items check off as their required
quantities reach the tray. During cleanup, the order card becomes a chore checklist.
Interaction prompts appear near the crosshair; temporary updates appear at the bottom.

Customers receive a randomly generated first and last name. Talking at the counter
starts a short conversation: everyday stories mix with awkward, absurd situations,
followed by your reply and their order. E, Space, Enter, or Continue advances it;
Esc ends the chat. The shift clock, tip timer, customer queue, cooking, and brewing
pause throughout the conversation, so reading costs no service time. Talking again
repeats only the order and keeps the same name and service timer.

Grandpa's health is shown at the top center. It starts at 100% and loses two
points once per completed day, after closing chores. It does not drain while
working, talking, or paused. At 0%, Grandpa dies and the campaign ends with a
hospital call after closing. Reloading the autosave returns to the ending; you can
load an earlier manual state, quit, or confirm starting a fresh campaign with $0
and full health. Reaching the
$15,000 surgery goal before health reaches zero stops decline and setbacks.

From the third completed day, eligible days have a 12% chance of a serious setback:
mistreatment, a fall, a bad night, or a rough chemotherapy session. These take another 8-12 health points and
are explained by Grandpa at his next hospital conversation, even if a visit was
skipped. Setbacks are at least six days apart, do not repeat the previous incident
type, and stop once surgery is funded. The schedule and outcomes are stable across
loading; incident history is saved. The HUD flags a recent setback.

Grandpa's hospital dialogue becomes more desperate over six stages as days pass,
from reassurance to anxious questions, absurd money-making ideas, and outright
begging. Poor health can accelerate the urgency. Funding surgery replaces the
pleas with relief and thanks. Letters, automatic reading popups, and the L archive
have been removed. Old saves retain cash, health, completed days and incident
history. Incident updates remain pending until a bedside conversation finishes.

Closing also requires replenishing pies used during service. The freezer room
has labeled meat, apple, and cherry pie crates. Take a needed flavor with E or
left click, carry it to the kitchen cooler, open both cooler doors, and interact
inside to refill that flavor's missing slots. One crate covers that flavor's
shortfall. Q returns a held crate. Replacement pies are raw and still need baking
when ordered the next day. Full shelves require no trip. The closing checklist
shows remaining pies; the day summary and Grandpa's update wait for replenishment.

Up to three customers can be in service or waiting in line. Waiting customers
step forward as soon as the previous order is served, while departing customers
walk out independently. When the timer reaches zero, service ends immediately:
the active customer and everyone queued walk out while nighttime chores begin.
Unfinished orders cause no earnings or streak penalty. Waiting in line has a 60-second grace
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

Open the diner at the shift clipboard. Service lasts three minutes. At closing,
waiting customers leave and new arrivals stop. If you already took the current
customer's order, you can finish it, with the HUD showing CLOSED · LAST ORDER.
Serving it (correctly or incorrectly) starts closing chores. If no order was
accepted, everyone leaves and closing chores begin immediately.
Hold **E** over the
bathroom and kitchen stains, collect the trash bag with **E**, and deposit it at
the dumpster outside the kitchen back door. The door replaces the flat-top grill:
press E to open it, walk into the fenced service yard, and click or press E on
the dumpster while holding the bag. Return through the door to the kitchen.
Finish all closing duties to see the day's earnings summary. Use the shift
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

Customers randomly use six textured male and female variants from the downloaded
**PSX Rigged Character Bases 1.2** and **new heads** packs. Each keeps a full
deform skeleton, relaxed arms, and procedural walking. Consecutive customers use
different appearances. Editable sources and the conversion script are in
`art/customer_psx/`. Flavor names distinguish the pies; their pastry mesh is shared.

There is an 8% chance an arriving customer uses a randomly selected male or female unclothed adult base. These
customers never arrive back-to-back. At the counter, their prompt changes to
**E: Refuse service - clothing required**. Refuse them instead of making an
order; they leave and the queue continues. Refusal preserves your cash, streak,
and prepared food, and does not count as a wrong order. The bell cannot serve
these customers. Launch with `-- --refusal-demo` for the male variant or
`-- --female-refusal-demo` for the female variant immediately.

During nighttime closing chores, the counter bell may ring by itself and the
interior lights may briefly flicker. A silent human-sized figure can briefly appear
at the dark back of the yard when you take out the trash. It disappears
when you look away or after a short glimpse. Other encounters include three knocks
from an empty bathroom cubicle, a cooler door creaking open while you look away,
and six footsteps moving through an empty area behind you. Cooler doors remain
interactable, so you can close them normally. Footsteps wait until customers leave.
Each closing has a 30% chance of being quiet; otherwise it selects exactly one
of the six encounters with equal probability. Timing and location checks vary
when it happens, so you may miss an encounter. The first closing uses the same
selection. Effects stop when closing finishes. Press **F7** during gameplay to
test closing chores directly.

After all closing duties, use E at the diner front exit (or the shift clipboard)
to head out. Hospital visiting hours open after Day 1, then every third completed
day (Days 4, 7, 10, ...). Choose Visit Grandpa, Go Home, or stay in the diner.
Going home skips that evening's visit. A short fade takes you between locations.
In Room 204, use E at Grandpa's bedside to talk. His conversation reflects his
health, recent setbacks, and the surgery savings. E/Space/Enter advances dialogue;
Esc ends it. Leaving through the hospital door ends the visit and starts the next
morning. Visiting adds no extra health loss or shift time. Quitting during a visit
resumes at the hospital; quitting after cleanup preserves the evening choice.
Use -- --hospital-demo or open hospital_room.tscn for a standalone room preview.

Dialogue uses black panels with square white borders, pixel lettering and a blinking continuation arrow. Customer conversations, Grandpa visits and departure choices type out gradually while gameplay stays paused. E/Space/Enter or the dialogue button first reveals the current text; the next press continues. Esc closes dialogue.

About 55% of correctly served customers choose an available clean booth. They carry their meal over, sit and eat for 18-35 seconds, then leave. About 45% of diners leave a used cup and wrappers. Dirty or occupied tables cannot be assigned to another customer. Wrong orders and the final after-hours order are takeout departures. Closing sends seated diners home immediately and preserves their litter.

During closing, use E on table litter, carry it to the labeled indoor trash can by the kitchen-side trash pickup, and use E to deposit it. Q returns litter to its original table. The Clear table trash chore tracks how many dirty tables remain. Once every table is cleared into the bin, use E on the bin to collect the bag and take it to the outdoor dumpster. A clean dining room auto-completes the table chore, but the nightly bag still has to go out. Dining customers, meal progress, dirty tables and carried litter are included in manual save states.
