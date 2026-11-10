extends CanvasLayer
## Training runs before service. Only the standalone demo uses this wallet.
var wallet = preload("res://earnings.gd").new(false)
var talked_to_grandpa := false
var guide: Label
var tutorial_state := "welcome"
var practice_order_index := 0
var campaign_shift: Node
var lesson: CanvasLayer
const FRIES := preload("res://fries.gd")
const FRIES_LESSON := 3
const PRACTICE_ORDERS := [["Coffee", "Glazed donut"], ["Cola", "Apple pie"], ["Deluxe burger"], [FRIES.SERVING]]

func setup_lesson(shift: Node) -> void:
	lesson = preload("res://visit_modal.gd").new()
	lesson.name = "TutorialLesson"
	shift.add_child(lesson)
	lesson.setup(shift.game)
	lesson.selected.connect(func(choice: int):
		tutorial_state = "practice" if choice == 0 else "done"
		if choice == 1: shift._message("Stock all three donut flavors, then flip the OPEN sign.")
	)

func open_tutorial() -> void:
	lesson.show_choices("BEFORE WE OPEN",
		"WASD to move, mouse to look, E to interact and Q to return what you're holding. Practice donuts, drinks, pies, burgers and fries, then learn how to use the pistol.",
		["Start training", "Skip tutorial"])

func practice_hint(shift: Node) -> String:
	var instruction := _practice_instruction(shift)
	return "TRAINING  %d / %d\n%s" % [practice_order_index + 1, PRACTICE_ORDERS.size() + 1, instruction]

func _practice_instruction(shift: Node) -> String:
	if practice_order_index == PRACTICE_ORDERS.size():
		if shift.carried_item == "Pistol": return "Aim at the robber and left-click or press E to fire."
		if not shift.carried_item.is_empty() or shift.has_empty_cup(): return "Press Q to free your hands before taking the pistol."
		if shift.pistol.drawer_open: return "Look inside the drawer and press E on the pistol to take it."
		return "A masked robber is demanding cash at the counter. Press E to open the drawer beneath the service bell."
	if shift.carried_item.is_empty() and not shift.has_empty_cup() and shift.tray.any(func(item): return not item in PRACTICE_ORDERS[practice_order_index] or shift.tray.count(item) > 1):
		return "Take items off the tray with E and return any extras with Q."
	if practice_order_index == 2: return _burger_instruction(shift)
	if practice_order_index == FRIES_LESSON: return _fries_instruction(shift)
	if not shift.carried_item.is_empty():
		if not shift.carried_item in PRACTICE_ORDERS[practice_order_index]:
			return "Press Q to return the extra item."
		if shift.carried_item.ends_with("pie"):
			var quality: String = shift.carried_source.get_meta("bake_quality", "raw")
			if quality == "burnt": return "Press Q to return the burnt pie, then try again with a fresh one."
			if quality != "perfect":
				return "Put the pie in the oven with E." if shift.oven.all_open() else "Press E on either oven door to open both doors."
		return "Press E at the serving tray to set down the " + shift.carried_item + "."
	if practice_order_index == 1: return _soda_and_pie_instruction(shift)
	if shift.soda_station.holding_empty: return "Press Q to return the soda cup. Start with coffee."
	if not shift.tray.has("Coffee"):
		match shift.coffee_station.state:
			"brewing": return "Coffee is brewing. Wait for READY."
			"ready": return "Press E at the coffee machine again to collect your cup."
			_: return "Press E at the coffee machine to fill your empty cup." if shift.coffee_station.holding_empty else "Go behind the counter and press E at the coffee cup stack to take an empty cup."
	if not shift.tray.has("Glazed donut"):
		if shift.donut_fryer.stock[2] == 0:
			for batch in shift.donut_fryer.batches:
				if batch.state == "ready": return "Aim at the glazed shelf in the display case and press E to stock the batch."
			for batch in shift.donut_fryer.batches:
				if batch.state == "frying":
					return "Press E at %ds to lift the golden donuts. They burn at %ds." % [shift.donut_fryer.READY, shift.donut_fryer.BURNT]
			return "Find a fryer in the kitchen and press E to lower a basket of donut dough."
		return "Aim at the plain glazed donuts in the glass case and press E to grab one."
	return "Ring the bell beside the serving tray to finish the practice order."

func _soda_and_pie_instruction(shift: Node) -> String:
	if shift.coffee_station.holding_empty: return "Press Q to return the coffee cup."
	if not shift.tray.has("Cola") or shift.soda_station.holding_empty:
		match shift.soda_station.state:
			"brewing": return "Wait for the soda to finish pouring."
			"ready": return "Press E on a fountain button again to collect the filled cup."
			_: return "Press E on the COLA button to fill your cup." if shift.soda_station.holding_empty else "Take an empty soda cup from the holder on the front of the fountain."
	if shift.tray.has("Apple pie"):
		var source: Node3D = shift.tray_sources[shift.tray.find("Apple pie")]
		if source.get_meta("bake_quality", "raw") == "perfect":
			return "Ring the bell to serve the cola and baked apple pie."
		return "Take the pie back off the tray with E so you can finish baking it or return it with Q."
	if shift.oven.pie_item.is_empty(): return "Open the kitchen cooler and take an Apple pie."
	match shift.oven.quality():
		"undercooked": return "Close both doors. Ready at %ds. Burns at %ds. Stay by the oven." % [shift.oven.PERFECT_AT, shift.oven.BURNS_AT]
		"perfect": return "Pie is ready! Open the doors now to stop it from burning." if not shift.oven.all_open() else "The heat is off. Press E inside the oven to collect the pie."
		_: return "The pie burned. Open the doors, take it out, and press Q to retry."

func _burger_instruction(shift: Node) -> String:
	var grill = shift.burger_station
	match shift.carried_item:
		"Raw patty": return "Press E at the flat top to start cooking the raw patty."
		"Cooked patty": return "Press E at the separate bun tray to assemble the burger."
		"Deluxe burger": return "Place the Deluxe burger on the serving tray with E."
		"":
			if shift.tray.has("Deluxe burger"): return "Ring the bell to serve the Deluxe burger."
			if not shift.tray.is_empty(): return "Take the extra item off the tray with E, then return it with Q."
			if shift.has_empty_cup(): return "Press Q to return the empty cup."
			if not grill.cooking: return "Take a raw patty from the metal tray beside the flat top."
			match grill.quality():
				"burnt": return "Press E at the flat top to discard the burnt patty, then start again."
				"ready": return "Press E at the flat top to collect the cooked patty."
			if grill.flipped_at < 0: return "Cook the first side for 3 seconds, then press E to flip it. The patty burns at 12 seconds total."
			return "Cook the second side for 3 seconds, then press E to collect it."
		_:
			var toppings: int = grill.BURGERS.find(shift.carried_item)
			if toppings < 0: return "Press Q to return the extra item."
			for index in grill.TOPPINGS.size():
				if not (toppings & (1 << index)):
					return "At the toppings table, press E on the %s tray. The wall sheet lists the Deluxe recipe." % grill.TOPPINGS[index].to_lower()
	return ""

func _fries_instruction(shift: Node) -> String:
	match shift.carried_item:
		FRIES.RAW: return "Aim directly at one basket in an empty kitchen fryer and press E to lower the fries."
		FRIES.SERVING: return "Press E at the serving tray to set down the basket of fries."
		"":
			if shift.has_empty_cup(): return "Press Q to return the empty cup."
			if shift.tray.has(FRIES.SERVING): return "Ring the bell to serve the fries."
			for batch in shift.donut_fryer.batches:
				if batch.state == "fries":
					if batch.elapsed >= FRIES.COOK_SECONDS:
						return "The fries are golden! Aim at the same basket and press E to collect them."
					return "Wait 3 seconds for the fries to turn golden and the basket to lift."
			return "Open the freezer room off the kitchen and press E at the FROZEN FRIES rack to take a pack."
		_: return "Press Q to return the extra item."

func ring_practice_bell(shift: Node) -> void:
	if practice_order_index == PRACTICE_ORDERS.size():
		shift._message("The pistol is in the drawer beneath the service bell.")
		return
	var expected: Array = PRACTICE_ORDERS[practice_order_index]
	if shift.tray.size() != expected.size() or not expected.all(func(item): return shift.tray.has(item)) or not shift.carried_item.is_empty() or shift.has_empty_cup():
		shift._message("Practice order: %s. Q returns an extra item." % " and ".join(expected))
		return
	if practice_order_index == 1:
		var pie: Node3D = shift.tray_sources[shift.tray.find("Apple pie")]
		if pie.get_meta("bake_quality", "raw") != "perfect":
			shift._message("The practice order needs a perfectly baked apple pie.")
			return
	shift._clear_tray(true)
	shift._reset_stock()
	practice_order_index += 1
	if practice_order_index == PRACTICE_ORDERS.size():
		shift.donut_fryer.clear_fries()
		begin_encounter(shift)
		return
	match practice_order_index:
		1: shift._message("First order done. Next up: a cola and a baked apple pie.")
		2: shift._message("Next up: a Deluxe burger with cheese, lettuce and tomato.")
		FRIES_LESSON: shift._message("Next up: a basket of fries. Start at the frozen fries rack in the freezer.")

func begin_encounter(shift: Node) -> void:
	var actor: Node3D = shift.customer_line.make_actor(Vector3(-2.4, -0.094, -3.6), "robber_1")
	actor.rotation.y = PI
	shift._bind_customer_actor(actor)
	shift.start_robbery_dialogue()

func complete_encounter(shift: Node) -> void:
	shift._reset_customer()
	tutorial_state = "done"
	shift._message("Training complete. The pistol is back in the drawer. Stock all three donut flavors and flip OPEN to clear the practice body and start service.")

static func session(host: Node):
	return host.get_tree().root.get_node_or_null("PlayableDemo")

static func prepare(host: Node) -> void:
	var demo = session(host)
	if demo == null and (OS.has_feature("playable_demo") or "--play-demo" in OS.get_cmdline_user_args()):
		demo = load("res://playable_demo.gd").new()
		demo.name = "PlayableDemo"
		host.get_tree().root.add_child(demo)
	if demo != null: host.get_tree().root.set_meta("pie_day_wallet", demo.wallet)

func _ready() -> void:
	layer = 25
	guide = Label.new()
	guide.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	guide.position = Vector2(-360, 54)
	guide.size = Vector2(720, 60)
	guide.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	guide.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	guide.add_theme_font_size_override("font_size", 22)
	guide.add_theme_color_override("font_color", Color("eee6d8"))
	guide.add_theme_color_override("font_outline_color", Color("111113"))
	guide.add_theme_constant_override("outline_size", 7)
	guide.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(guide)

func _process(_delta: float) -> void:
	if campaign_shift != null:
		guide.visible = campaign_shift.is_practicing() and not get_tree().paused
		if guide.visible: guide.text = practice_hint(campaign_shift)
		return
	var scene = get_tree().current_scene
	guide.visible = scene != null and not get_tree().paused
	if scene == null: return
	match scene.scene_file_path:
		"res://main.tscn":
			var shift = scene.shift
			if not is_instance_valid(shift): return
			if is_instance_valid(shift.dialogue) and shift.dialogue.is_open:
				guide.hide()
				return
			match shift.phase:
				"prep":
					match tutorial_state:
						"practice": guide.text = practice_hint(shift)
						"done": guide.text = "Stock all three donut flavors, then flip the OPEN sign."
						_: guide.text = "WASD to move · Mouse to look · E to interact\nFind the wall clipboard behind the counter to begin."
				"cleanup": guide.text = "Finish the closing checklist. Hold E to scrub floors.\nCarry the trash through the back door to the dumpster."
				"closed": guide.text = "Your work is done. Use the front exit or clipboard to visit Grandpa."
				_:
					if not shift.order_taken:
						guide.text = "Speak to the customer at the counter with E.\nPut their items on the tray, then ring the bell."
					elif shift.order_index == 0:
						guide.text = "Coffee: take an empty cup, use the machine to fill it, then collect when READY.\nGrab a glazed donut from the case. Place both on the tray; ring the bell."
					else:
						guide.text = "Pies: ready at %ds, burn at %ds. Open the doors at the ding.\nSoda: take an empty cup, choose a flavor, then collect when full." % [shift.oven.PERFECT_AT, shift.oven.BURNS_AT]
		"res://hospital_room.tscn":
			guide.text = "Talk to Grandpa at his bedside. E / Space advances dialogue." if not talked_to_grandpa else "When you’re ready, use the room exit to finish the demo."
		_: guide.hide()

func restart() -> void:
	wallet = preload("res://earnings.gd").new(false)
	talked_to_grandpa = false
	tutorial_state = "welcome"
	practice_order_index = 0
	get_tree().paused = false
	get_tree().root.set_meta("pie_day_wallet", wallet)
	get_tree().change_scene_to_file("res://intro.tscn")
