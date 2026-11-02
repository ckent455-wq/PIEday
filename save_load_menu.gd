extends CanvasLayer
const SAVES := preload("res://save_states.gd")
const UI := preload("res://diner_ui.gd")
var host: Node
var origin_pause: Node
var overlay: Control
var heading: Label
var status: Label
var rows: VBoxContainer
var confirm: ConfirmationDialog
var is_open := false
var saving := false
var previously_paused := false
var selected_slot := 0
var directory := SAVES.DIRECTORY

func setup(scene: Node, pause_owner: Node = null) -> void:
	host = scene
	origin_pause = pause_owner
	layer = 110
	process_mode = Node.PROCESS_MODE_ALWAYS
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.theme = UI.theme()
	add_child(overlay)
	var shade := ColorRect.new()
	shade.color = Color(0,0,0,.85)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel := UI.card()
	panel.custom_minimum_size.x = 720
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",18)
	panel.add_child(column)
	heading = UI.label("",28,UI.GOLD)
	column.add_child(heading)
	status = UI.label("",17,UI.MUTED)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(status)
	rows = VBoxContainer.new()
	rows.add_theme_constant_override("separation",12)
	column.add_child(rows)
	var back := Button.new()
	back.text = "Back [Esc]"
	back.custom_minimum_size.y = 42
	column.add_child(back)
	back.pressed.connect(func(): close.call_deferred())
	confirm = ConfirmationDialog.new()
	confirm.theme = UI.theme()
	add_child(confirm)
	confirm.confirmed.connect(func(): execute.call_deferred(selected_slot))
	overlay.hide()

func open(save_mode: bool) -> void:
	if is_open: return
	saving = save_mode
	previously_paused = get_tree().paused
	is_open = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	heading.text = "SAVE GAME" if saving else "LOAD GAME"
	status.text = "Choose a slot. Manual saves are kept separately from autosave."
	if saving and not SAVES.wallet_for(host).save_enabled: status.text = "Preview mode: saving is disabled to protect your real slots."
	refresh()
	overlay.show()
	for button in rows.get_children():
		if not button.disabled:
			button.grab_focus()
			break

func refresh() -> void:
	for child in rows.get_children():
		rows.remove_child(child)
		child.queue_free()
	for slot in range(1,SAVES.SLOTS+1):
		var data := SAVES.read(slot,directory)
		var button := Button.new()
		button.custom_minimum_size = Vector2(680,88)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if data.is_empty(): button.text = "Slot %d — Empty or unavailable" % slot
		else:
			var progress := ConfigFile.new()
			progress.parse(data.grandpa)
			var location := "Hospital" if data.scene == "res://hospital_room.tscn" else str(data.shift.phase).capitalize()
			button.text = "Slot %d  ·  Day %d  ·  Grandpa %d%%  ·  $%d\n%s  ·  %s" % [slot,int(progress.get_value("grandpa","days",0))+int(not progress.get_value("grandpa","evening_pending",false)),int(progress.get_value("grandpa","health",100)),int(data.wallet.cash),location,str(data.timestamp).replace("T"," ")]
		button.disabled = (not saving and data.is_empty()) or (saving and (not SAVES.wallet_for(host).save_enabled or SAVES.wallet_for(host).grandpa.is_dead()))
		rows.add_child(button)
		button.pressed.connect(func(): choose.call_deferred(slot))

func choose(slot: int) -> void:
	selected_slot = slot
	var existing := SAVES.read(slot,directory)
	if saving and existing.is_empty():
		execute(slot)
		return
	confirm.title = "Overwrite Save?" if saving else "Load Save?"
	confirm.dialog_text = "Replace the save in Slot %d?" % slot if saving else "Load Slot %d?\nYour current unsaved progress will be replaced." % slot
	confirm.ok_button_text = "Save" if saving else "Load"
	confirm.popup_centered()

func execute(slot: int) -> void:
	confirm.hide()
	if saving:
		if not SAVES.wallet_for(host).save_enabled or SAVES.wallet_for(host).grandpa.is_dead(): return
		var error := SAVES.write(slot,SAVES.capture(host),directory)
		status.text = "Saved to Slot %d." % slot if error == OK else "Could not save (error %d). Your previous slot was kept." % error
		refresh()
	else:
		var data := SAVES.read(slot,directory)
		if data.is_empty():
			status.text = "This save is unavailable. Choose another slot."
			return
		var persist: bool = SAVES.wallet_for(host).save_enabled
		close()
		if is_instance_valid(origin_pause): origin_pause.resume_game()
		get_tree().paused = false
		SAVES.load_state(host,data,persist)

func close() -> void:
	if not is_open: return
	confirm.hide()
	is_open = false
	overlay.hide()
	get_tree().paused = previously_paused
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if previously_paused or host.scene_file_path == "res://grandpa_ending.tscn" else Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	if not is_open: return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		if confirm.visible: confirm.hide()
		else: close()
