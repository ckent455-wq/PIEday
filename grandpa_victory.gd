extends Node3D
const CONTROLLER := preload("res://controller_input.gd")

const UI := preload("res://diner_ui.gd")
const RETRO := preload("res://retro_dialogue.gd")
const DIALOGUE_AT := 13.8
const JIG_START := 8.2
const JIG_END := 12.8
const BEAT_SECONDS := 60.0 / 114.0
const BAR_SECONDS := BEAT_SECONDS * 4.0
const FADE_SECONDS := BEAT_SECONDS * 2.0
const CREDITS_SECONDS := BAR_SECONDS * 12.0
const MUSIC_VOLUME := -10.0
const LINES: Array[String] = [
	"Look at me, kiddo. Walking through my own front door. The surgery worked. You did it.",
	"You kept the diner alive. You kept ME alive. I'm proud of you.",
	"Now get me a slice of pie. Hospital pudding doesn't count as food, and I've had enough of it for three lifetimes.",
	"We're back in business."]
var earnings: RefCounted
var grandpa: Node3D
var camera: Camera3D
var skeleton: Skeleton3D
var bones := {}
var front_door: MeshInstance3D
var closed_angle := 0.0
var elapsed := 0.0
var state := "walk"
var page := 0
var ui: Control
var opening: ColorRect
var opening_text: Label
var speech: PanelContainer
var body_text: Label
var typewriter: Node
var end_card: CenterContainer
var skip: Button
var restart_dialog: ConfirmationDialog
var music: AudioStreamPlayer
var credits: ColorRect
var credits_roll: ScrollContainer
var credits_lead_in: Control
var credits_elapsed := 0.0
var fade_countdown := 0.0
var previous_music_position := 0.0

func _ready() -> void:
	if get_tree().root.has_meta("restore_manual_state"): get_tree().root.remove_meta("restore_manual_state")
	if get_tree().root.has_meta("pie_day_wallet"):
		earnings = get_tree().root.get_meta("pie_day_wallet")
		get_tree().root.remove_meta("pie_day_wallet")
	else:
		# Opening this scene directly in the editor is a non-persistent preview.
		earnings = preload("res://earnings.gd").new(false)
		earnings.cash = earnings.TREATMENT_GOAL
		earnings.complete_campaign()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var layout = preload("res://diner_layout.tscn").instantiate()
	add_child(layout)
	for mesh in layout.find_children("*","MeshInstance3D",true,false):
		if "Collision" in mesh.name: mesh.hide()
	front_door = layout.find_child("Door_03",true,false)
	closed_angle = front_door.rotation.y
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48,-32,0)
	sun.light_color = Color(1,.91,.76)
	sun.light_energy = 1.3
	sun.shadow_enabled = true
	add_child(sun)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(.45,.64,.8)
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color(.94,.94,1)
	world.environment.ambient_light_energy = .8
	add_child(world)
	grandpa = preload("res://assets/customers/grandpa.glb").instantiate()
	grandpa.name = "Grandpa"
	grandpa.scale = Vector3.ONE*1.17
	add_child(grandpa)
	for node in grandpa.find_children("*","Skeleton3D",true,false):
		skeleton = node
		break
	for bone_name in ["Arm_L","Arm_R","Leg_L","Leg_R","DEF-shin.L","DEF-shin.R","DEF-forearm.L","DEF-forearm.R"]:
		var id := skeleton.find_bone(bone_name)
		var rotation := skeleton.get_bone_pose_rotation(id)
		if bone_name.begins_with("Arm"):
			var rest := skeleton.get_bone_global_rest(id).basis.get_rotation_quaternion()
			rotation *= rest.inverse()*Quaternion(Vector3.FORWARD,.65 if bone_name == "Arm_L" else -.65)*rest
		bones[id] = rotation
	camera = Camera3D.new()
	camera.fov = 65
	add_child(camera)
	_build_ui()
	music = AudioStreamPlayer.new()
	var track: AudioStreamWAV = preload("res://assets/music/grandpas_home.wav").duplicate()
	track.loop_mode = AudioStreamWAV.LOOP_FORWARD
	track.loop_end = roundi(track.get_length() * track.mix_rate)
	music.stream = track
	music.volume_db = MUSIC_VOLUME
	add_child(music)
	music.play()
	_update_shot()

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.theme = UI.theme()
	layer.add_child(ui)
	for top in [true,false]:
		var bar := ColorRect.new()
		bar.color = Color.BLACK
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ui.add_child(bar)
		bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE if top else Control.PRESET_BOTTOM_WIDE)
		bar.offset_top = 0 if top else -48
		bar.offset_bottom = 48 if top else 0
	skip = _button(ui,"Skip cutscene [Esc]",_begin_credits)
	skip.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	skip.position = Vector2(-245,8)
	skip.size = Vector2(225,34)
	var dialogue_ui := Control.new()
	ui.add_child(dialogue_ui)
	dialogue_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dialogue_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_ui.theme = RETRO.theme()
	speech = RETRO.panel(dialogue_ui)
	var column := VBoxContainer.new()
	speech.add_child(column)
	column.add_child(RETRO.label("GRANDPA",12))
	body_text = RETRO.label("",18)
	body_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(body_text)
	_button(column,"Continue [E]",advance)
	typewriter = preload("res://dialogue_typewriter.gd").new()
	add_child(typewriter)
	typewriter.arrow = RETRO.arrow(column)
	speech.hide()
	end_card = CenterContainer.new()
	ui.add_child(end_card)
	end_card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := UI.card()
	end_card.add_child(panel)
	var ending := VBoxContainer.new()
	ending.custom_minimum_size.x = 560
	ending.add_theme_constant_override("separation",16)
	panel.add_child(ending)
	var heading := UI.label("GRANDPA'S BACK!",28,UI.GOLD)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ending.add_child(heading)
	var message := UI.label("The surgery was a success.\nYou saved Grandpa's life—and his diner.\n\n$%d raised · %d shifts completed" % [earnings.cash,earnings.grandpa.victory_day],21)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ending.add_child(message)
	_button(ending,"Replay Grandpa's Homecoming",replay)
	_button(ending,"View Credits",_begin_credits)
	var new_game := _button(ending,"Start a New Campaign",func(): restart_dialog.popup_centered())
	var coop = preload("res://coop_session.gd").active(self)
	if coop != null: new_game.disabled = not coop.hosting
	_button(ending,"Main Menu",main_menu)
	_button(ending,"Quit to Desktop",func(): get_tree().quit())
	end_card.hide()
	restart_dialog = ConfirmationDialog.new()
	restart_dialog.title = "Start a New Campaign"
	restart_dialog.dialog_text = "Start over with $0 and Grandpa at full health? Manual save slots are kept."
	restart_dialog.confirmed.connect(start_new_campaign)
	add_child(restart_dialog)
	opening = ColorRect.new()
	ui.add_child(opening)
	opening.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	opening.color = Color.BLACK
	opening.mouse_filter = Control.MOUSE_FILTER_IGNORE
	opening_text = UI.label("The surgery was a success.\n\nA few weeks later...",26)
	opening.add_child(opening_text)
	opening_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	opening_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	opening_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_build_credits()

func _build_credits() -> void:
	credits = ColorRect.new()
	credits.color = Color.BLACK
	ui.add_child(credits)
	credits.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	credits_roll = ScrollContainer.new()
	credits.add_child(credits_roll)
	credits_roll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	credits_roll.offset_bottom = -64
	credits_roll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	credits_roll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	var column := VBoxContainer.new()
	credits_roll.add_child(column)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 18)
	credits_lead_in = Control.new()
	column.add_child(credits_lead_in)
	_credit_text(column, "PIEday", 48, UI.GOLD)
	_credit_text(column, "Written by ckent455-wq", 36)
	_credit_text(column, "Created by ckent455-wq", 32)
	_credit_text(column, "Game Design · Development · Original Art", 20, UI.MUTED)
	_credit_text(column, "Original Food Models · ckent455-wq\nDonuts · Burgers · Cheese · Lettuce · Tomato · Fries", 20)
	_credit_text(column, "Original Music\nckent455-wq · BeepBox", 20)
	_credit_text(column, "THIRD-PARTY ASSETS", 24, UI.GOLD)
	_credit_text(column, "Character models\nPSX Rigged Character Bases · New Heads · Base Humanoid Mesh", 20)
	_credit_text(column, "Environment and props\nDINER · Hospital Assets · Trash Dumpster · Retro PSX Trash Bag", 20)
	_credit_text(column, "Yard monster\nZombie pack by Pxltiger", 20)
	_credit_text(column, "Food reference sprites and pistol model\nPolyy", 20)
	_credit_text(column, "Typography and typewriter assets\nPress Start 2P Project Authors · Text Typerwriter pack\nTypewriter code adapted from George Blackwell", 20)
	_credit_text(column, "Freesound recordings\ntheplax · Rudmer_Rotteveel · Maajora · sethlind\nBeeProductive · naxxfish · okieactor · elynch0901", 20)
	_credit_text(column, "Thanks for playing.", 28, UI.GOLD)
	var continue_button := _button(credits, "Continue [E]", finish)
	continue_button.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	continue_button.offset_left = -95
	continue_button.offset_right = 95
	continue_button.offset_top = -56
	continue_button.offset_bottom = -12
	credits.hide()

func _credit_text(parent: VBoxContainer, text: String, font_size: int, color := UI.CREAM) -> void:
	var label := UI.label(text, font_size, color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)

func _button(parent: Node, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 42
	parent.add_child(button)
	button.pressed.connect(callback)
	return button

func _process(delta: float) -> void:
	if state == "ending": return
	if state in ["credits_fade", "credits"]:
		var position := _music_position()
		var step := fposmod(position - previous_music_position, music.stream.get_length())
		# Ignore tiny backwards jumps from the audio mixer clock.
		if step > music.stream.get_length() - 0.02: return
		previous_music_position = position
		_advance_credits(step)
		return
	if state == "walk": elapsed += delta
	_update_shot()
	if state == "walk" and elapsed >= DIALOGUE_AT:
		state = "speech"
		page = 0
		speech.show()
		skip.hide()
		typewriter.start(body_text,LINES[page])

func _update_shot() -> void:
	var progress := clampf((elapsed-2.8)/5.0,0,1)
	grandpa.position = Vector3(.76,-.094,lerpf(5.5,1.8,progress))
	grandpa.rotation.y = PI
	grandpa.rotation.z = 0
	var stride := sin((elapsed-2.8)*10)*minf(1,progress*12)*minf(1,(1-progress)*12)
	var jig := smoothstep(JIG_START,JIG_START+.4,elapsed)*(1-smoothstep(JIG_END-.4,JIG_END,elapsed))
	var beat := elapsed * TAU / BEAT_SECONDS
	if jig > 0:
		grandpa.position.x += sin(beat*.5)*.24*jig
		grandpa.position.y += (1-cos(beat*2))*.035*jig
		grandpa.rotation.y += sin(beat*.5)*.13*jig
		grandpa.rotation.z = sin(beat)*.035*jig
	for id in bones:
		var bone_name := skeleton.get_bone_name(id)
		var amplitude := .16 if bone_name.begins_with("Arm") else .3 if bone_name.begins_with("Leg") else 0.0
		var angle := stride*amplitude*(-1 if bone_name in ["Arm_L","Leg_R"] else 1)
		var side := -1.0 if bone_name.ends_with("R") else 1.0
		if bone_name.begins_with("Leg"): angle += sin(beat)*.36*side*jig
		elif "shin" in bone_name: angle += maxf(0,sin(beat)*side)*.65*jig
		elif "forearm" in bone_name: angle += (-.85+sin(beat)*.2*side)*jig
		elif bone_name.begins_with("Arm"): angle += sin(beat)*.25*side*jig
		var rest := skeleton.get_bone_global_rest(id).basis.get_rotation_quaternion()
		skeleton.set_bone_pose_rotation(id,bones[id]*rest.inverse()*Quaternion(Vector3.RIGHT,angle)*rest)
	if elapsed > JIG_END:
		var arm := skeleton.find_bone("Arm_R")
		var rest := skeleton.get_bone_global_rest(arm).basis.get_rotation_quaternion()
		var wave := smoothstep(JIG_END,JIG_END+.8,elapsed)*(2.25+sin(Time.get_ticks_msec()*.006)*.10)
		skeleton.set_bone_pose_rotation(arm,bones[arm]*rest.inverse()*Quaternion(Vector3.FORWARD,wave)*rest)
	var door_open := smoothstep(2.3,3.1,elapsed)*(1-smoothstep(6.8,7.6,elapsed))
	front_door.rotation.y = closed_angle+deg_to_rad(95)*door_open
	var closeup := smoothstep(JIG_END,DIALOGUE_AT,elapsed)
	camera.fov = lerpf(65,55,closeup)
	# Keep the camera in the open center aisle, never inside the booths.
	var entrance_camera := Vector3(.76,1.55,lerpf(-.8,-1.5,progress))
	camera.position = entrance_camera.lerp(Vector3(.76,1.7,-.7),closeup)
	camera.look_at(Vector3(.76,lerpf(1.15,1.7,closeup),grandpa.position.z))
	opening.modulate.a = 1-smoothstep(2.0,2.8,elapsed)
	opening.visible = elapsed < 2.8

func advance() -> void:
	if state != "speech": return
	if typewriter.reveal_if_typing(): return
	page += 1
	if page >= LINES.size(): _begin_credits()
	else: typewriter.start(body_text,LINES[page])

func _music_position() -> float:
	return fposmod(music.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency(), music.stream.get_length())

func _begin_credits() -> void:
	state = "credits_fade"
	typewriter.stop()
	speech.hide()
	skip.hide()
	end_card.hide()
	opening.show()
	opening_text.hide()
	previous_music_position = _music_position()
	# Reserve two beats for the fade and land on a bar line.
	fade_countdown = BAR_SECONDS - fposmod(previous_music_position + FADE_SECONDS, BAR_SECONDS) + FADE_SECONDS
	credits_elapsed = 0.0

func _advance_credits(step: float) -> void:
	if state == "credits_fade":
		fade_countdown -= step
		opening.modulate.a = maxf(opening.modulate.a, 1.0 - clampf(fade_countdown / FADE_SECONDS, 0.0, 1.0))
		if fade_countdown > 0.0: return
		step = -fade_countdown
		state = "credits"
		credits.show()
		credits_lead_in.custom_minimum_size.y = credits_roll.size.y - 32
		credits_roll.scroll_vertical = 0
	credits_elapsed += step
	var scroll := credits_roll.get_v_scroll_bar()
	var progress := clampf(credits_elapsed / CREDITS_SECONDS, 0.0, 1.0)
	credits_roll.scroll_vertical = roundi((scroll.max_value - scroll.page) * progress)
	if credits_elapsed >= CREDITS_SECONDS + FADE_SECONDS: finish()

func finish() -> void:
	state = "ending"
	elapsed = DIALOGUE_AT
	_update_shot()
	typewriter.stop()
	speech.hide()
	skip.hide()
	credits.hide()
	end_card.show()
	end_card.find_children("*", "Button", true, false)[0].grab_focus()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func replay() -> void:
	state = "walk"
	elapsed = 0
	end_card.hide()
	credits.hide()
	opening_text.show()
	speech.hide()
	skip.show()
	music.play()
	_update_shot()

func start_new_campaign() -> void:
	var fresh = preload("res://earnings.gd").new(false)
	fresh.save_enabled = earnings.save_enabled
	fresh.save_path = earnings.save_path
	fresh._save()
	preload("res://hospital_travel.gd").go(self,"res://intro.tscn",fresh)

func main_menu() -> void:
	var coop = preload("res://coop_session.gd").active(self)
	if coop != null: coop.leave()
	else: get_tree().change_scene_to_file("res://main_menu.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if CONTROLLER.back(event) or CONTROLLER.advance(event):
		if state == "credits": finish()
		elif CONTROLLER.back(event) and state in ["walk", "speech"]: _begin_credits()
		elif CONTROLLER.advance(event) and state == "speech": advance()
