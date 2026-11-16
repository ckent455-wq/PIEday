extends Control

const UI := preload("res://diner_ui.gd")
const EARNINGS := preload("res://earnings.gd")
const TITLE_FONT := preload("res://assets/ui/PressStart2P-Regular.ttf")

func _ready() -> void:
	if preload("res://game_updater.gd").redirect_to_installed(get_tree()): return
	var root := get_tree().root
	var first_open := not root.has_meta("main_menu_opened")
	root.set_meta("main_menu_opened", true)
	if OS.has_feature("playable_demo") or (first_open and not OS.get_cmdline_user_args().is_empty()):
		get_tree().change_scene_to_file.call_deferred("res://intro.tscn")
		return
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var splash: ColorRect
	if first_open:
		splash = await _show_studio_logo()
	theme = UI.theme()
	_build_backdrop()
	add_child(preload("res://diner_music.gd").new())
	var margin := MarginContainer.new()
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 44)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	scroll.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 340
	column.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	column.add_theme_constant_override("separation", 10)
	scroll.add_child(column)
	var title := UI.label("PIEday", 44, UI.GOLD)
	title.add_theme_font_override("font", TITLE_FONT)
	title.custom_minimum_size.y = 82
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	column.add_child(title)
	var has_autosave := FileAccess.file_exists(EARNINGS.SAVE_PATH)
	var resume := _add_button(column, "Continue", _continue_campaign)
	resume.disabled = not has_autosave
	var confirm := ConfirmationDialog.new()
	confirm.title = "Start a New Game?"
	confirm.dialog_text = "Start over with $0 and Grandpa at full health? Your manual save slots are kept."
	confirm.ok_button_text = "New Game"
	confirm.confirmed.connect(_new_game)
	add_child(confirm)
	var new_game := _add_button(column, "New Game", func():
		if has_autosave: confirm.popup_centered()
		else: _new_game()
	)
	var saves := preload("res://save_load_menu.gd").new()
	saves.name = "SaveLoadMenu"
	add_child(saves)
	saves.setup(self)
	_add_button(column, "Load Game", func(): saves.open(false))
	_add_button(column, "Online Co-op", func(): _open("res://coop_lobby.tscn"))
	_add_button(column, "Quit", func(): get_tree().quit())
	var version := UI.label("v" + str(ProjectSettings.get_setting("application/config/version")), 14, UI.MUTED)
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(version)
	if preload("res://game_updater.gd").enabled():
		var updater := preload("res://game_updater.gd").new()
		add_child(updater)
		updater.setup(column)
	if splash != null:
		move_child(splash, -1)
		var fade := create_tween()
		fade.tween_property(splash, "modulate:a", 0.0, 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await fade.finished
		splash.queue_free()
	(resume if has_autosave else new_game).grab_focus()

func _show_studio_logo() -> ColorRect:
	var splash := ColorRect.new()
	splash.color = Color("020609")
	add_child(splash)
	splash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var mark := Control.new()
	splash.add_child(mark)
	mark.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	mark.position.y -= 170.0
	var triangle := Line2D.new()
	triangle.points = PackedVector2Array([Vector2(0, 0), Vector2(77, 130), Vector2(-77, 130), Vector2(0, 0)])
	triangle.width = 3.6
	triangle.antialiased = true
	triangle.default_color = Color(0.76, 0.86, 0.78)
	mark.add_child(triangle)
	var presents := UI.label("Traingle Studios Presents...", 46, triangle.default_color)
	presents.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mark.add_child(presents)
	presents.position = Vector2(-320, 179)
	presents.size.x = 640
	mark.modulate.a = 0.0
	var animation := create_tween()
	animation.tween_property(mark, "modulate:a", 1.0, 0.65)
	animation.tween_interval(1.7)
	await animation.finished
	await _shatter_studio_mark(mark, triangle, presents)
	mark.hide()
	return splash

func _shatter_studio_mark(mark: Control, triangle: Line2D, presents: Label) -> void:
	var impact := Vector2(24, 79)
	var star := Polygon2D.new()
	var points := PackedVector2Array()
	for index in range(10):
		var radius := 25.0 if index % 2 == 0 else 10.0
		points.append(Vector2.from_angle(index * TAU / 10.0 - PI * 0.5) * radius)
	star.polygon = points
	star.color = Color("fff0a6")
	var tail := Line2D.new()
	tail.points = PackedVector2Array([Vector2(110, -55), Vector2(8, -4)])
	tail.width = 4.0
	tail.antialiased = true
	tail.default_color = Color(1.0, 0.78, 0.37, 0.68)
	var streak := Node2D.new()
	mark.add_child(streak)
	streak.add_child(tail)
	streak.add_child(star)
	streak.position = impact + Vector2(440, -220)
	var flight := create_tween().set_parallel()
	flight.tween_property(streak, "position", impact, 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	flight.tween_property(star, "rotation", -TAU, 0.38)
	await flight.finished
	streak.hide()
	triangle.hide()
	var ring := Line2D.new()
	for index in range(33):
		ring.add_point(Vector2.from_angle(index * TAU / 32.0) * 20.0)
	ring.width = 3.0
	ring.antialiased = true
	ring.default_color = star.color
	mark.add_child(ring)
	ring.position = impact
	var burst := create_tween().set_parallel()
	burst.tween_property(ring, "scale", Vector2.ONE * 7.0, 0.42).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	burst.tween_property(ring, "modulate:a", 0.0, 0.42)
	var travel := get_viewport_rect().size.length() + 64.0
	var shard_flight_time := 7.0
	var title_center := presents.position + presents.size * 0.5
	var half_text_width := presents.get_minimum_size().x * 0.5
	var hit_time := shard_flight_time
	var hit_x := title_center.x
	for edge in range(triangle.points.size() - 1):
		var start := triangle.points[edge]
		var finish := triangle.points[edge + 1]
		for index in range(7):
			var a := start.lerp(finish, index / 7.0)
			var b := start.lerp(finish, (index + 0.8) / 7.0)
			var shard := Line2D.new()
			shard.points = PackedVector2Array([Vector2.ZERO, b - a])
			shard.width = 3.6
			shard.antialiased = true
			shard.default_color = star.color.lerp(triangle.default_color, index / 7.0)
			mark.add_child(shard)
			shard.position = a
			var scatter := (a - impact).normalized() * (travel * (1.0 + index * 0.08))
			burst.tween_property(shard, "position", a + scatter, shard_flight_time)
			burst.tween_property(shard, "rotation", (index - 3) * 0.7, shard_flight_time)
			if scatter.y > 0.0:
				var progress := (title_center.y - a.y) / scatter.y
				var crossing_x := a.x + scatter.x * progress
				var crossing_time := progress * shard_flight_time
				if progress >= 0.0 and crossing_time < hit_time and absf(crossing_x - title_center.x) < half_text_width:
					hit_time = crossing_time
					hit_x = crossing_x
	_scatter_studio_letters(presents, burst, hit_time, hit_x, travel)
	await burst.finished

func _scatter_studio_letters(title: Label, burst: Tween, hit_time: float, hit_x: float, travel: float) -> void:
	var font := title.get_theme_font("font")
	var font_size := title.get_theme_font_size("font_size")
	var text_width := font.get_string_size(title.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var text_left := title.position.x + (title.size.x - text_width) * 0.5
	burst.tween_callback(title.hide).set_delay(hit_time)
	for index in range(title.text.length()):
		var character := title.text.substr(index, 1)
		if character == " ":
			continue
		var letter := UI.label(character, font_size, title.get_theme_color("font_color"))
		title.get_parent().add_child(letter)
		var advance := font.get_string_size(title.text.left(index), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		letter.position = Vector2(text_left + advance, title.position.y)
		letter.pivot_offset = letter.get_minimum_size() * 0.5
		letter.hide()
		var offset := letter.position.x + letter.pivot_offset.x - hit_x
		var delay := hit_time + absf(offset) / 750.0
		var direction := Vector2.from_angle(randf_range(0.0, TAU))
		burst.tween_callback(letter.show).set_delay(hit_time)
		burst.tween_property(letter, "position", letter.position + direction * travel, 3.8).set_delay(delay)
		burst.tween_property(letter, "rotation", randf_range(-TAU * 2.0, TAU * 2.0), 3.8).set_delay(delay)

func _build_backdrop() -> void:
	var diner := preload("res://diner_layout.tscn").instantiate()
	add_child(diner)
	for mesh in diner.find_children("*", "MeshInstance3D", true, false):
		if "Collision" in mesh.name: mesh.hide()
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color("222737")
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color("a9b1cb")
	world.environment.ambient_light_energy = 0.65
	add_child(world)
	var warm_light := OmniLight3D.new()
	warm_light.light_color = Color("ffb577")
	warm_light.light_energy = 2.2
	warm_light.omni_range = 10.0
	add_child(warm_light)
	warm_light.position = Vector3(1.6, 2.65, -3.0)
	var pie := preload("res://title_pie.gd").new()
	pie.title_kitchen_door = diner.get_node("Door_01")
	pie.title_door_closed_angle = pie.title_kitchen_door.rotation.y
	add_child(pie)
	var camera := Camera3D.new()
	camera.fov = 69
	add_child(camera)
	camera.position = Vector3(-3.2, 1.85, 1.0)
	camera.look_at(Vector3(-0.7, 1.30, -3.55))
	camera.make_current()
	var colors := Gradient.new()
	colors.offsets = PackedFloat32Array([0.0, 0.39, 0.70, 1.0])
	colors.colors = PackedColorArray([Color(0.05, 0.04, 0.05, 0.98), Color(0.05, 0.04, 0.05, 0.92), Color(0.05, 0.04, 0.05, 0.24), Color(0.05, 0.04, 0.05, 0.12)])
	var gradient := GradientTexture2D.new()
	gradient.gradient = colors
	gradient.fill_to = Vector2.RIGHT
	var backdrop := TextureRect.new()
	backdrop.texture = gradient
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _add_button(column: VBoxContainer, caption: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size.y = 48
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.pressed.connect(action)
	column.add_child(button)
	return button

func _new_game() -> void:
	var wallet := EARNINGS.new(false)
	wallet.save_enabled = true
	wallet._save()
	get_tree().root.set_meta("pie_day_wallet", wallet)
	_open("res://intro.tscn")

func _continue_campaign() -> void:
	var wallet := EARNINGS.new()
	get_tree().root.set_meta("pie_day_wallet", wallet)
	_open("res://hospital_room.tscn" if wallet.grandpa.visit_in_progress else "res://main.tscn")

func _open(scene: String) -> void:
	get_tree().change_scene_to_file.call_deferred(scene)
