extends Node
## In-place authored motion follows the existing customer routes without moving the actor.
var actor: Node3D
var player: AnimationPlayer
var last_position := Vector3.ZERO
var suspended := false
var sample_time := 0.0
var sample_distance := 0.0

func setup(host: Node3D, visual: Node3D, model: String) -> void:
	actor = host
	name = "Locomotion"
	var rig := "male_1" if model.begins_with("male") else "female_1" if model == "female_1" else "female_2"
	player = AnimationPlayer.new()
	visual.add_child(player)
	player.add_animation_library("",load("res://assets/animations/customers/"+rig+".res"))
	player.play("Idle")
	player.advance(0)
	last_position = actor.position
	process_priority = 10

func _process(delta: float) -> void:
	var distance := Vector2(actor.position.x-last_position.x,actor.position.z-last_position.z).length()
	last_position = actor.position
	if suspended: return
	sample_time += delta
	# A short measurement window also handles co-op snapshots arriving in steps.
	sample_distance += distance if distance < 2 else 0.0
	if sample_time < .08: return
	var speed := sample_distance/maxf(sample_time,.001)
	sample_time = 0
	sample_distance = 0
	# Ignore teleports and use a short crossfade when joining or leaving the queue.
	var clip := "Idle" if speed < .1 or speed > 12 else "Jog_Fwd" if speed > 6 else "Walk"
	if player.current_animation != clip: player.play(clip,.18)
	player.speed_scale = clampf(speed/(7.5 if clip == "Jog_Fwd" else 3.2),.75,1.5) if clip != "Idle" else 1.0

func suspend(value: bool) -> void:
	suspended = value
	player.active = not value
	last_position = actor.position
	sample_time = 0
	sample_distance = 0
	if not value:
		player.play("Idle")
		player.advance(0)
