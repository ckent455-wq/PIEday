extends CanvasLayer
signal selected(index: int)
signal dialogue_completed
const UI := preload("res://diner_ui.gd")
const RETRO := preload("res://retro_dialogue.gd")
var overlay: Control
var title: Label
var body: Label
var footer: HBoxContainer
var is_open := false
var pages: Array[String] = []
var page := 0
var dialogue_mode := false
var host: Node
var typewriter: Node

func setup(owner_node: Node) -> void:
	host = owner_node
	layer = 86
	process_mode = Node.PROCESS_MODE_ALWAYS
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.theme = RETRO.theme()
	add_child(overlay)
	var shade := ColorRect.new()
	shade.color = Color(0,0,0,.08)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)
	var panel := RETRO.panel(overlay)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",10)
	panel.add_child(column)
	title = RETRO.label("",12)
	column.add_child(title)
	body = RETRO.label("",18)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(body)
	footer = HBoxContainer.new()
	footer.add_theme_constant_override("separation",14)
	column.add_child(footer)
	typewriter = preload("res://dialogue_typewriter.gd").new()
	add_child(typewriter)
	typewriter.arrow = RETRO.arrow(column)
	typewriter.finished.connect(_page_ready)
	overlay.hide()

func show_choices(heading: String, text: String, options: Array) -> void:
	if is_open or get_tree().paused: return
	dialogue_mode = false
	title.text = heading
	typewriter.start(body,text)
	_clear_buttons()
	for i in options.size():
		var button := _button(options[i])
		button.pressed.connect(func(): _choose.call_deferred(i))
	_open()

func show_dialogue(lines: Array[String]) -> void:
	if is_open or get_tree().paused: return
	dialogue_mode = true
	pages = lines
	page = 0
	title.text = "GRANDPA"
	_clear_buttons()
	_button("Continue [E]").pressed.connect(func(): advance.call_deferred())
	_update_page()
	_open()

func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(180,46)
	footer.add_child(button)
	return button

func _clear_buttons() -> void:
	for button in footer.get_children():
		footer.remove_child(button)
		button.queue_free()

func _open() -> void:
	is_open = true
	overlay.show()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	footer.get_child(0).grab_focus()

func _update_page() -> void:
	footer.get_child(0).text = "Reveal text [E]"
	typewriter.start(body,pages[page])

func _page_ready() -> void:
	if dialogue_mode and footer.get_child_count() > 0:
		footer.get_child(0).text = "Finish conversation [E]" if page == pages.size()-1 else "Continue [E]"

func advance() -> void:
	if not is_open or not dialogue_mode: return
	if typewriter.reveal_if_typing(): return
	page += 1
	if page >= pages.size():
		dialogue_completed.emit()
		finish()
	else: _update_page()

func _choose(index: int) -> void:
	if typewriter.reveal_if_typing(): return
	finish()
	selected.emit(index)

func finish() -> void:
	if not is_open: return
	is_open = false
	typewriter.stop()
	overlay.hide()
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if is_instance_valid(host): host.set("interaction_release_required",true)

func _input(event: InputEvent) -> void:
	if not is_open: return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			finish()
		elif dialogue_mode and event.keycode in [KEY_E,KEY_SPACE,KEY_ENTER,KEY_KP_ENTER]:
			get_viewport().set_input_as_handled()
			advance()
		elif not dialogue_mode and typewriter.typing and event.keycode in [KEY_E,KEY_SPACE,KEY_ENTER,KEY_KP_ENTER]:
			get_viewport().set_input_as_handled()
			typewriter.reveal()

func _exit_tree() -> void:
	if is_open: get_tree().paused = false
