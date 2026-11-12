extends Node3D
## Standalone, unsaved viewer for the three imported customer locomotion clips.
const MODELS = preload("res://customer_line.gd").CUSTOMER_MODELS
const CLIPS := ["Idle","Walk","Jog_Fwd"]
var actors: Array[Node3D] = []
var players: Array[AnimationPlayer] = []
var model_index := 0
var paused := false
var model_label: Label
var pause_button: Button
var side_view := true

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var environment := WorldEnvironment.new()
	var world := Environment.new()
	world.background_mode = Environment.BG_COLOR
	world.background_color = Color("18232d")
	world.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.ambient_light_color = Color("dce5ed")
	world.ambient_light_energy = .75
	environment.environment = world
	add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45,-30,0)
	light.light_energy = 1.3
	light.shadow_enabled = true
	add_child(light)
	var floor_mesh := MeshInstance3D.new()
	var floor_shape := PlaneMesh.new()
	floor_shape.size = Vector2(30,30)
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color("394854")
	floor_material.roughness = 1
	floor_shape.material = floor_material
	floor_mesh.mesh = floor_shape
	add_child(floor_mesh)
	var camera := Camera3D.new()
	camera.fov = 43
	add_child(camera)
	camera.position = Vector3(0,2.9,8.5)
	camera.look_at(Vector3(0,1.15,0))
	for i in 3:
		var label := Label3D.new()
		label.text = ["IDLE","WALK","JOG"][i]
		label.position = Vector3((i-1)*2.35,2.5,0)
		label.pixel_size = .006
		label.font_size = 40
		label.modulate = Color("f5cd68")
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(label)
	var layer := CanvasLayer.new()
	add_child(layer)
	var ui := VBoxContainer.new()
	ui.position = Vector2(24,20)
	ui.add_theme_constant_override("separation",10)
	ui.theme = preload("res://diner_ui.gd").theme()
	layer.add_child(ui)
	var title := Label.new()
	title.text = "CUSTOMER ANIMATION PREVIEW"
	title.add_theme_font_size_override("font_size",25)
	ui.add_child(title)
	model_label = Label.new()
	ui.add_child(model_label)
	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation",12)
	ui.add_child(controls)
	var next := Button.new()
	next.text = "Next customer [Tab]"
	next.pressed.connect(func(): show_model((model_index+1)%MODELS.size()))
	controls.add_child(next)
	pause_button = Button.new()
	pause_button.text = "Pause [Space]"
	pause_button.pressed.connect(toggle_pause)
	controls.add_child(pause_button)
	var view_button := Button.new()
	view_button.text = "Front / side [V]"
	view_button.pressed.connect(toggle_view)
	controls.add_child(view_button)
	var hint := Label.new()
	hint.text = "1–9, 0: choose customer  ·  Esc: close preview\nIn-place loops: customer routes control movement in the game."
	hint.add_theme_font_size_override("font_size",16)
	ui.add_child(hint)
	show_model(0)
	if "--capture" in OS.get_cmdline_user_args():
		await get_tree().create_timer(1).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://builds/all-customer-animations.png")
		get_tree().quit()

func show_model(index: int) -> void:
	model_index = index
	for actor in actors: actor.queue_free()
	actors.clear()
	players.clear()
	for i in 3:
		var actor := Node3D.new()
		add_child(actor)
		actor.position.x = (i-1)*2.35
		actor.rotation.y = PI/2 if side_view else 0.0
		preload("res://customer_line.gd").attach_visual(actor,MODELS[index])
		var motion: Node = actor.get_meta("locomotion")
		motion.set_process(false)
		var player: AnimationPlayer = motion.player
		player.play(CLIPS[i])
		player.speed_scale = 0 if paused else 1
		actors.append(actor)
		players.append(player)
	model_label.text = "Customer %d / %d  ·  %s  ·  Quaternius Universal Animation Library" % [index+1,MODELS.size(),MODELS[index].replace("_"," ").capitalize()]

func toggle_pause() -> void:
	paused = not paused
	for player in players: player.speed_scale = 0 if paused else 1
	pause_button.text = "Resume [Space]" if paused else "Pause [Space]"

func toggle_view() -> void:
	side_view = not side_view
	for actor in actors: actor.rotation.y = PI/2 if side_view else 0.0

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo(): return
	if event.keycode == KEY_ESCAPE: get_tree().quit()
	elif event.keycode == KEY_SPACE: toggle_pause()
	elif event.keycode == KEY_TAB: show_model((model_index+1)%MODELS.size())
	elif event.keycode == KEY_V: toggle_view()
	elif event.keycode == KEY_0 and MODELS.size() >= 10: show_model(9)
	elif event.keycode >= KEY_1 and event.keycode < KEY_1+MODELS.size(): show_model(event.keycode-KEY_1)
