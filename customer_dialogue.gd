extends CanvasLayer

const UI := preload("res://diner_ui.gd")
const RETRO := preload("res://retro_dialogue.gd")
const CHATS := [
	["Work was nonstop today. This is the first chance I've had to sit down.", "Then let's get you something good."],
	["I had a job interview this morning. I think it went pretty well!", "Good luck! Sounds like a little celebration is in order."],
	["My dog found every muddy puddle on our walk. One of us had a great morning.", "Sounds like you've earned a break."],
	["I've been helping my sister move all day. I never want to see another staircase.", "You've done enough heavy lifting. I'll take it from here."],
	["I finally finished the book I've been reading for months. Not sure what to do with myself now.", "Pie is a pretty good next chapter."],
	["The bus broke down, so I walked the last few blocks. At least it brought me here.", "Well, I'm glad you made it."],
	["It's my day off. No plans, no errands. Just wanted to treat myself.", "That sounds like a good way to spend it."],
	["My kid learned to ride a bike today. I think I ran farther than they rode.", "That's a good day. A tiring one, but a good one."],
	["I burned dinner. Again. Figured I'd leave the cooking to somebody else tonight.", "We've got you covered."],
	["Nothing special happened today. Honestly, I needed a quiet one.", "Quiet days deserve good food too."],
	["The automatic doors at the bank only opened for me halfway. Now the manager thinks I want a smaller bank.", "I'll make sure you get a full-sized slice."],
	["I brought my own chair to a job interview. They already had a chair, so now it looks like I'm interviewing THEM.", "You can use one of ours. No interview required."],
	["I told my dentist I floss every day. He asked what brand. I said 'loose.' I haven't answered his calls since.", "We can probably keep this conversation off your dental record."],
	["A pigeon followed me for six blocks. I bought it a bus ticket. The driver says that makes it MY pigeon.", "Let's start with food for you."],
	["I tried returning a birthday cake because nobody came. The bakery said that isn't a defect in the cake.", "I'm sorry. I can at least help with dessert."],
	["My coworker called my lunch 'ambitious.' It was just a sandwich in a shoebox. The lid was VERY secure.", "We usually use plates here."],
	["I accidentally waved at a mannequin. The employee waved back, so now there are TWO people I can't go near.", "This counter should be a safe distance from both of them."],
	["I complained that the elevator music was too quiet. They turned it up. People think I'm the elevator DJ now.", "You're off duty in here."],
	["My neighbor keeps borrowing my ladder to look over my fence. I raised the fence. Now he's asking for a taller ladder.", "That sounds like a very expensive conversation."],
	["I called a meeting to find out who keeps calling meetings. Six people asked if there would be snacks.", "At least we can solve the snack part."],
	["Someone at the grocery store said 'nice cart.' I panicked and said I built it. They want me to build eleven more.", "Your secret is safe here."],
	["I put a tiny tie on my thermostat. My landlord says I can't promote appliances without written permission.", "Sounds like you both need a break."],
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
	if not reminder:
		var index := randi_range(0, CHATS.size() - 1)
		if last_chat >= 0: index = (last_chat + randi_range(1, CHATS.size() - 1)) % CHATS.size()
		last_chat = index
		actor.set_meta("chat_index", index)
		pages.append([customer_name.to_upper(), CHATS[index][0]])
		pages.append(["YOU", CHATS[index][1]])
	pages.append([customer_name.to_upper(), "Could I get " + ", ".join(items) + ", please?"])
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
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_E, KEY_SPACE, KEY_ENTER, KEY_KP_ENTER, KEY_ESCAPE]:
			get_viewport().set_input_as_handled()
			if event.keycode == KEY_ESCAPE: finish()
			else: advance()

func _exit_tree() -> void:
	if is_open: get_tree().paused = false
