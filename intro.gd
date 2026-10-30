extends Control

const PASSAGES := [
	"Your grandfather has just been diagnosed with cancer.",
	"The doctors say it’s very treatable—but his insurance won’t cover the treatment.",
	"He needs $15,000 out of pocket.",
	"Grandpa paid into that insurance his whole life.",
	"Now, when he needs it most, they’ve left him on his own.",
	"You have to run this diner like your grandpa’s life depends on it.",
	"Because it does.",
]
var passage_index := 0
var narrative: RichTextLabel
var continue_button: Button
var goal_label: Label
var next_character := 0.6
var complete := false
var starting := false
var key_audio: AudioStreamPlayer
var key_sounds_played := 0
var sound_rng := RandomNumberGenerator.new()

func _ready() -> void:
	if "--customer-demo" in OS.get_cmdline_user_args():
		_start_game(false)
		return
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	sound_rng.randomize()
	key_audio = AudioStreamPlayer.new()
	key_audio.stream = preload("res://assets/typewriter/key_press.wav")
	key_audio.max_polyphony = 4
	key_audio.volume_db = -16
	add_child(key_audio)
	var black := ColorRect.new()
	black.color = Color.BLACK
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(black)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 100)
	margin.add_theme_constant_override("margin_right", 100)
	margin.add_theme_constant_override("margin_top", 35)
	margin.add_theme_constant_override("margin_bottom", 30)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	margin.add_child(column)
	var title := Label.new()
	title.text = "P I E D A Y"
	title.add_theme_font_size_override("font_size", 20)
	title.modulate = Color(0.65, 0.57, 0.43)
	column.add_child(title)
	var upper_space := Control.new()
	upper_space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(upper_space)
	narrative = RichTextLabel.new()
	narrative.bbcode_enabled = true
	narrative.visible_characters = 0
	narrative.scroll_active = false
	narrative.custom_minimum_size.y = 160
	var typewriter_font: FontFile = preload("res://assets/typewriter/atwriter.ttf").duplicate()
	var fallback := SystemFont.new()
	fallback.font_names = PackedStringArray(["Courier New", "monospace"])
	typewriter_font.fallbacks = [fallback]
	narrative.add_theme_font_override("normal_font", typewriter_font)
	narrative.add_theme_font_size_override("normal_font_size", 30)
	narrative.add_theme_color_override("default_color", Color(0.89, 0.88, 0.82))
	column.add_child(narrative)
	var lower_space := Control.new()
	lower_space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(lower_space)
	goal_label = Label.new()
	goal_label.text = "EARN $15,000 FOR GRANDPA’S TREATMENT"
	goal_label.add_theme_font_size_override("font_size", 20)
	goal_label.modulate = Color(0.78, 0.68, 0.46, 0)
	column.add_child(goal_label)
	continue_button = Button.new()
	continue_button.text = "Reveal sentence  [E / Space]"
	continue_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	continue_button.flat = true
	continue_button.add_theme_font_size_override("font_size", 21)
	continue_button.add_theme_color_override("font_color", Color(0.78, 0.68, 0.46))
	continue_button.focus_mode = Control.FOCUS_NONE
	continue_button.pressed.connect(_continue)
	column.add_child(continue_button)
	_show_passage()

func _show_passage() -> void:
	key_audio.stop()
	complete = false
	next_character = 0.3
	narrative.text = "[center]" + PASSAGES[passage_index] + "[/center]"
	narrative.visible_characters = 0
	goal_label.modulate.a = 0
	continue_button.text = "Reveal sentence  [E / Space]"

func _process(delta: float) -> void:
	if complete or starting or not is_instance_valid(narrative): return
	next_character -= delta
	var passage: String = PASSAGES[passage_index]
	while next_character <= 0 and narrative.visible_characters < passage.length():
		var character := passage.substr(narrative.visible_characters, 1)
		narrative.visible_characters += 1
		if not character.strip_edges().is_empty():
			key_audio.volume_db = sound_rng.randf_range(-17.2, -14.8)
			key_audio.play()
			key_sounds_played += 1
		next_character += 0.055
		if character in [".", "—"]: next_character += 0.30
		elif character == ",": next_character += 0.13
		elif character == "\n": next_character += 0.20
	if narrative.visible_characters >= passage.length(): _reveal()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_E, KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
		_continue()
		get_viewport().set_input_as_handled()

func _reveal() -> void:
	key_audio.stop()
	complete = true
	narrative.visible_characters = -1
	var final_passage := passage_index == PASSAGES.size() - 1
	goal_label.modulate.a = 1 if final_passage else 0
	continue_button.text = "Open the Diner  [E / Space]" if final_passage else "Continue  [E / Space]"

func _continue() -> void:
	if starting: return
	if not complete: _reveal()
	elif passage_index < PASSAGES.size() - 1:
		passage_index += 1
		_show_passage()
	else: _start_game()

func _start_game(animate := true) -> void:
	if is_instance_valid(key_audio): key_audio.stop()
	starting = true
	if not animate:
		get_tree().change_scene_to_file.call_deferred("res://main.tscn")
		return
	var transition := preload("res://intro_transition.gd").new()
	get_tree().root.add_child(transition)
	transition.begin()
