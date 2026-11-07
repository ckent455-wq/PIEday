extends Control

const UI := preload("res://diner_ui.gd")
const SESSION := preload("res://coop_session.gd")
var status: Label
var address: LineEdit
var host_button: Button
var join_button: Button

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	theme = UI.theme()
	var background := ColorRect.new()
	background.color = Color("111113")
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := UI.card()
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 440
	column.add_theme_constant_override("separation", 14)
	panel.add_child(column)
	column.add_child(UI.label("PIEday  /  ONLINE CO-OP", 28, UI.GOLD))
	column.add_child(UI.label("Two players · The full diner campaign", 18))
	column.add_child(UI.label("Build v%s · Both PCs must match" % ProjectSettings.get_setting("application/config/version"), 16, UI.GOLD))
	host_button = _button(column, "Host Shift", func(): _connect_game(true))
	address = LineEdit.new()
	address.placeholder_text = "Host IP address"
	address.custom_minimum_size.y = 42
	address.text_submitted.connect(func(_value): _connect_game(false))
	column.add_child(address)
	join_button = _button(column, "Join Shift", func(): _connect_game(false))
	status = UI.label("Direct connection over UDP port %d." % SESSION.PORT, 16, UI.MUTED)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if get_tree().root.has_meta("coop_status"):
		status.text = get_tree().root.get_meta("coop_status")
		get_tree().root.remove_meta("coop_status")
	column.add_child(status)
	_button(column, "Back to Main Menu", func(): _back.call_deferred())

func _button(parent: Control, caption: String, pressed: Callable) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size.y = 44
	parent.add_child(button)
	button.pressed.connect(pressed)
	return button

func _connect_game(hosting: bool) -> void:
	if SESSION.active(self) != null: return
	var target := address.text.strip_edges()
	if not hosting and target.is_empty():
		status.text = "Enter the host's IP address."
		return
	var session := SESSION.new()
	session.name = "CoopSession"
	get_tree().root.add_child(session)
	var error := session.connect_game(hosting, target)
	if error != OK:
		session.queue_free()
		status.text = "Could not %s: %s" % ["host" if hosting else "join", error_string(error)]
		return
	host_button.disabled = true
	join_button.disabled = true
	if hosting:
		var addresses := PackedStringArray()
		for ip in IP.get_local_addresses():
			if ip.is_valid_ip_address() and ":" not in ip and not ip.begins_with("127.") and not ip.begins_with("169.254."):
				addresses.append(ip)
		status.text = "Waiting for your partner on UDP %d.\nLocal addresses: %s" % [SESSION.PORT, ", ".join(addresses)]
	else:
		status.text = "Connecting to %s…" % target

func _back() -> void:
	var session = SESSION.active(self)
	if session != null: session.shutdown()
	get_tree().change_scene_to_file("res://main_menu.tscn")
