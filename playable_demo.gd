extends CanvasLayer
## A separate, disposable session: never writes campaign progress.
var wallet = preload("res://earnings.gd").new(false)
var talked_to_grandpa := false
var guide: Label
var tutorial_state := "welcome"
var practice_order_index := 0
const PRACTICE_ORDERS := [["Coffee", "Glazed donut"], ["Cola", "Apple pie"]]

func open_tutorial(shift: Node) -> void:
	var lesson = shift.get_node_or_null("TutorialLesson")
	if lesson == null:
		lesson = preload("res://visit_modal.gd").new()
		lesson.name = "TutorialLesson"
		shift.add_child(lesson)
		lesson.setup(shift.game)
		lesson.selected.connect(func(choice: int):
			tutorial_state = "practice" if choice == 0 else "done"
			lesson.queue_free()
			if choice == 1: shift.start_shift()
		)
	lesson.show_choices("BEFORE WE OPEN",
		"Move with WASD and look with the mouse. Aim and press E to interact. Practice two orders before opening: coffee and a donut, then a fountain soda and a baked pie.",
		["Practice order", "Skip tutorial"])

func practice_hint(shift: Node) -> String:
	var instruction := _practice_instruction(shift)
	return "TRAINING  %d / %d\n%s" % [practice_order_index + 1, PRACTICE_ORDERS.size(), instruction]

func _practice_instruction(shift: Node) -> String:
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

func ring_practice_bell(shift: Node) -> void:
	var expected: Array = PRACTICE_ORDERS[practice_order_index]
	if shift.tray.size() != 2 or not shift.tray.has(expected[0]) or not shift.tray.has(expected[1]) or not shift.carried_item.is_empty() or shift.has_empty_cup():
		shift._message("Practice order: %s and %s. Q returns an extra item." % expected)
		return
	if practice_order_index == 1:
		var pie: Node3D = shift.tray_sources[shift.tray.find("Apple pie")]
		if pie.get_meta("bake_quality", "raw") != "perfect":
			shift._message("The practice order needs a perfectly baked apple pie.")
			return
	shift._clear_tray(true)
	shift._reset_stock()
	if practice_order_index == 0:
		practice_order_index = 1
		shift._message("First order done. Next up: a cola and a baked apple pie.")
		return
	tutorial_state = "done"
	shift._message("Practice complete! Use the clipboard when you're ready to open.")

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
						"done": guide.text = "Use the clipboard to start your shift."
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
