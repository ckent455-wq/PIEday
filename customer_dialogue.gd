extends CanvasLayer
const CONTROLLER := preload("res://controller_input.gd")

const UI := preload("res://diner_ui.gd")
const RETRO := preload("res://retro_dialogue.gd")
const SMALL_TALK_CHANCE := 0.25
const CHATS := [
 "Long day. I needed this.",
 "The job interview went well! I think.",
 "My dog found every puddle today.",
 "I burned dinner again.",
 "Day off. Just treating myself.",
 "I finished my book. Now what?",
 "The bus broke down. I walked here.",
 "Nothing happened today. Perfect.",
 "I brought my own interview chair. Bad move.",
 "A pigeon thinks I'm its landlord.",
 "Someone called my lunch ambitious.",
 "I waved at a mannequin. Can't go back.",
 "Apparently I'm the elevator DJ now.",
 "My thermostat got promoted. I'm furious.",
 "I said I built a shopping cart. They want eleven.",
 "My ladder is in a custody dispute.",
]
var shift: Node3D
var overlay: Control
var speaker: Label
var body: Label
var next_button: Button
var pages: Array = []
var page := 0
var is_open := false
var last_chat := -1
var customer_name := "Customer"
var typewriter: Node

func setup(host: Node3D) -> void:
	shift = host
	name = "CustomerDialogue"
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.theme = RETRO.theme()
	add_child(overlay)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.08)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var card := RETRO.panel(overlay)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	card.add_child(column)
	speaker = RETRO.label("", 12)
	column.add_child(speaker)
	body = RETRO.label("", 18)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(body)
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 18)
	column.add_child(footer)
	var hint := RETRO.label("E / SPACE: NEXT   ESC: CLOSE", 10)
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(hint)
	next_button = Button.new()
	next_button.custom_minimum_size = Vector2(134, 42)
	next_button.pressed.connect(func(): advance.call_deferred())
	footer.add_child(next_button)
	typewriter = preload("res://dialogue_typewriter.gd").new()
	add_child(typewriter)
	typewriter.arrow = RETRO.arrow(column)
	typewriter.finished.connect(_page_ready)
	overlay.hide()

func begin(actor: Node3D, items: Array, reminder := false) -> void:
	if is_open or get_tree().paused: return
	show_pages(make_pages(actor, items, reminder))

func make_pages(actor: Node3D, items: Array, reminder := false) -> Array:
	pages.clear()
	customer_name = str(actor.get_meta("display_name", "Customer"))
	var line := ""
	if not reminder and randf() < SMALL_TALK_CHANCE:
		var index := randi_range(0, CHATS.size() - 1)
		if last_chat >= 0: index = (last_chat + randi_range(1, CHATS.size() - 1)) % CHATS.size()
		last_chat = index
		actor.set_meta("chat_index", index)
		line = CHATS[index] + "\n\n"
	pages.append([customer_name.to_upper(), line + "Could I get " + ", ".join(items) + ", please?"])
	return pages.duplicate(true)

func show_pages(lines: Array) -> void:
	if is_open or get_tree().paused: return
	pages.assign(lines)
	page = 0
	is_open = true
	overlay.show()
	shift._refresh_hud()
	shift.notice_panel.hide()
	shift.game.interaction_label.hide()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_show_page()
	next_button.grab_focus()

func _show_page() -> void:
	speaker.text = str(pages[page][0]) + "  /  CLOCK PAUSED"
	next_button.text = "Reveal text"
	typewriter.start(body,str(pages[page][1]))

func _page_ready() -> void:
	var takes_order: bool = pages[page][0] != "MASKED ROBBER" and not shift.is_complaint_customer(shift.customer)
	next_button.text = "Start order" if page == pages.size() - 1 and takes_order else "Continue"

func advance() -> void:
	var coop = preload("res://coop_session.gd").active(self)
	if coop != null and not coop.ui_applying:
		coop.customer_dialogue_input()
		return
	if not is_open: return
	if typewriter.reveal_if_typing(): return
	page += 1
	if page >= pages.size():
		finish()
	else:
		_show_page()

func finish() -> void:
	if not is_open: return
	var coop = preload("res://coop_session.gd").active(self)
	if coop != null and not coop.ui_applying:
		coop.customer_dialogue_input(true)
		return
	is_open = false
	typewriter.stop()
	overlay.hide()
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Finishing on E must not immediately talk to the same customer again.
	shift.game.interaction_release_required = true
	shift._refresh_hud()

func _input(event: InputEvent) -> void:
	if not is_open: return
	if event.is_action_pressed("ui_cancel") or CONTROLLER.advance(event):
		get_viewport().set_input_as_handled()
		if event.is_action_pressed("ui_cancel"): finish()
		else: advance()

func _exit_tree() -> void:
	if is_open: get_tree().paused = false
