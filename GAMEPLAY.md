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
mistreatment, a fall, a bad night, chemotherapy, or wrong medication. Nurse mistreatment takes another 20 health points; other incidents take 8-12 points. Nurse incidents have double selection weight (about 4-5% per eligible day when allowed) and include a one-time bedside cutscene. All incidents
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

Each correct order also earns a clearly labeled $80 service reward. Consecutive
correct orders add a streak bonus: $0, $5, $10, then $15 per order. A mistake
resets the streak but never deducts cash. Completing all closing chores after
at least one correct order earns $300 once per day. Empty days earn no bonus.
At 6–10 fast, correct orders per shift, simulated earnings reach the $15,000 goal
in about 8–12 shifts.

Opening duties are frying and stocking the three donut flavors, then switching on the neon OPEN sign in the front window. Service lasts five minutes. At closing,
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
clipboard to begin the next day; daylight returns and donut prep begins again.

**F6** starts a fresh customer demo. **F7** jumps to nighttime closing chores
for testing. The customer demo launches with `-- --customer-demo`.

Customers enter through the front door and stop at the counter. Look at the
customer and press **E** to hear their order. The serving tray stays on the counter. Pick up one item, then click the counter
tray (or press E) to place it. Collect the exact items:

- Pies: open the kitchen cooler. Left column is meat, middle apple, right cherry.
  Carry a pie to the double-door kitchen oven. Press E on either oven door to open both, then click
  inside to load it. Close both doors to bake; the timer starts once they shut.
  Open the doors at 5 seconds and before 10 seconds for a perfect toasted pie.
  Opening the oven doors pauses cooking. With both doors open and an empty hand,
  click inside to take out the pie, then place it on the customer tray.
  Undercooked pies can go back in to finish. At 10 seconds the pie burns.
  Customers reject undercooked or burnt pies; raw pies cannot go on the tray.
  The oven display shows elapsed time and baking status. One pie fits at a time.
- Donuts: strawberry icing, chocolate icing, and plain glazed, grouped left to right in the glass display. Aim at a flavor and click or press E to pick it up. Customers request a specific flavor; all three cost $2.
- Coffee: take an empty cup from the stack beside the machine. Use the machine
  to place and fill the cup, collect it when READY, then put it on the serving tray.
  Filling takes 2.5 seconds. Click or press E to interact. Q returns a held empty cup.
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
interior lights may briefly flicker. After you dispose of the trash, an animated shadowy monster may appear in the
back doorway while you face away. Turning toward it immediately starts a short
shadow-wisp dissolution with spatial sound. It stays clear of the dumpster. Other encounters include three knocks
from an empty bathroom cubicle, a cooler door opening on its own while you watch,
and six footsteps moving through an empty area behind you. Cooler doors remain
interactable, so you can close them normally. Footsteps wait until customers leave.
Each closing has a 30% chance of being quiet; otherwise it selects exactly one
of the six encounters with equal probability. Timing and location checks vary
when it happens, so you may miss an encounter. The first closing uses the same
selection. Effects stop when closing finishes, except an armed doorway encounter can finish
after trash completes the final chore. Press **F7** during gameplay to
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

About 75% of correctly served customers choose an available clean booth. They carry their meal over, sit and eat for 18-35 seconds, then leave. About 45% of diners leave a used cup and wrappers. Dirty or occupied tables cannot be assigned to another customer. Wrong orders and the final after-hours order are takeout departures. Closing sends seated diners home immediately and preserves their litter.

During closing, use E on table litter, carry it to the labeled indoor trash can by the kitchen-side trash pickup, and use E to deposit it. Q returns litter to its original table. The Clear table trash chore tracks how many dirty tables remain. Once every table is cleared into the bin, use E on the bin to collect the bag and take it to the outdoor dumpster. A clean dining room auto-completes the table chore, but the nightly bag still has to go out. Dining customers, meal progress, dirty tables and carried litter are included in manual save states.


Fountain soda flavors: Cola (red), Lemon Fizz (yellow-green), and Dr. Paw Paw (purple). Pull an empty cup, click a labeled flavor button, then collect the full cup and place it on the tray. Each flavor is $2, and customer orders require the exact flavor.

On nights selected for the figure encounter, disposing of the outdoor trash triggers the monster in the back doorway while the player is looking away. It begins dissipating immediately when seen or approached. This also works when trash is the final closing chore.


Counter Service, the original BeepBox diner loop, plays quietly during the daytime and service. It continues during dialogue, pauses in the Esc menu, and crossfades to the night track at closing; returning to daylight restores it.

Night music: Last Customer crossfades in over two seconds when closing begins, replacing Counter Service. The ominous loop continues during nighttime dialogue and pauses with the Esc menu. Daylight returns to Counter Service.

Scare adjustment mode: launch with -- --scare-test. Keys 1-6 select bell, flicker, doorway monster, stall knocks, cooler opening, and footsteps. R replays; N advances. This mode uses a temporary unsaved campaign and the real encounter effects. The doorway sequence still requires trash disposal and turning back toward the diner.

Both kitchen cooler doors play the selected refrigerator-opening sound during normal use as well as the haunted opening. It plays once on each closed-to-open transition.

Hospital visits play Still Here quietly on a loop, including while Grandpa's dialogue is open. Esc pauses the music, and leaving the room fades it out.

Door behavior: bathroom and kitchen doors start closed and open only through player interaction. Customers use the front door when entering or leaving, wait for its swing, and close it after the doorway clears, including the last departure at closing. A front door explicitly opened by the player remains under player control.
# Playable demo

Export the **Windows Demo** preset or launch source with `-- --play-demo`.
The demo follows the intro, one service shift, closing duties and doorway encounter,
then a visit to Grandpa and a final earnings screen. Talk to Grandpa before leaving
his room. Replay starts a fresh demo. Campaign autosaves and manual slots are kept
separate; saving/loading is disabled during the demo. Small contextual hints guide
new players. The full Windows Desktop preset retains the campaign.

During a clothing-required encounter, the pistol in the center of the kitchen's right-hand table can be picked up with E using an empty hand. Aim at the unclothed customer at the counter and click/E to fire. They collapse with jointed ragdoll physics, collide with the diner furniture and floor, and remain for cleanup without gore. Q returns the pistol. It cannot be put on the tray, used on ordinary customers, or kept after the encounter. Normal E refusal remains available when unarmed.

If bodies remain at closing, the checklist includes body disposal. With empty hands, press E on a body to pick it up, carry it through the kitchen to the outdoor dumpster, then press E at the dumpster to dispose of it. Q sets it down. The body holds a fixed carry pose while lifted and resumes ragdoll physics when set down. All bodies must be removed before the day can end. Manual saves preserve physical poses and the carried body.

## Donut frying and burgers

At either kitchen fryer, press E to lower six raw dough rings. Lift with E after 5 seconds and before 10 seconds. Aim at a flavor in the donut case to ice and stock six donuts. Stock strawberry, chocolate and glazed before switching the neon OPEN sign on. Fry more during service as stock runs low.

Take a raw patty from the raw-meat tray. Put it on the flat top, wait 3 seconds, press E to flip, wait 3 more seconds, then collect it. Take it to the separate bun tray and press E to assemble a Burger. Place the finished burger on the serving tray and ring the bell. Patties burn at 12 seconds total. Raw or unassembled patties cannot be placed on the serving tray.

Five-minute balance: correct orders earn $80 service pay plus menu prices, optional tips and capped streak rewards. Closing pays $300 after at least one correct order. About 9–16 correct orders per shift targets the $15,000 goal in roughly 8–12 shifts. Preparation, dialogue and closing chores do not consume service time. Existing savings are retained.

The donut case holds eight of each flavor (24 total). A six-donut batch can top off a partly full shelf; unused donuts remain in the basket and can be iced for another flavor. Picking a donut removes that exact displayed item. Q returns held/tray donuts and restores their stock. Empty shelves require fresh frying.

## Winning the campaign

Finish closing duties with at least $15,000 saved while Grandpa is still alive. The closing bonus counts toward the goal. His surgery succeeds, and a homecoming cutscene shows him walking back into the diner and thanking the player. The campaign saves as won, Grandpa recovers, and the ending offers replay, a new campaign, or the main menu. New campaigns keep manual save slots. Loading an earlier manual save restores that earlier campaign state. The separate playable demo retains its own ending.
