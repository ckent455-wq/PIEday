extends CanvasLayer

const REACTION_SECONDS := 5.0
const SHOT_INTERVAL := 1.6
const SHOT_RANGE := 14.0
const MAX_HEALTH := 100
const PLAYER_HIT_DAMAGE := 25
const ROBBER_HIT_DAMAGE := 50
var player_health := MAX_HEALTH
var robber_health := MAX_HEALTH
var health_actor: Node3D
var health_panel: PanelContainer
var player_bar: ProgressBar
var robber_bar: ProgressBar
var player_label: Label
var robber_label: Label
var blood_flash: ColorRect
var blood_tween: Tween
var shift: Node3D
var enemy_state := "idle"
var base_accuracy := .65
var shot_cooldown := 0.0
var shots_fired := 0
var rng := RandomNumberGenerator.new()
var chase: RefCounted
var partner_last := Vector3.ZERO
var partner_sample := 0.0
var partner_speed := 0.0
var remaining := -1.0
var blackout: ColorRect
var caption: Label

func _at_counter(position: Vector3) -> bool:
	return Rect2(-3.7,-6.45,3.5,1.6).has_point(Vector2(position.x,position.z)) and position.y < 1.0

func staff_at_counter() -> bool:
	if _at_counter(shift.game.player.position): return true
	var coop = shift.game.coop
	return coop != null and coop.partner_ready and _at_counter(coop.partner_target)

func can_start_encounter() -> bool:
	return shift.phase == "waiting" and shift.order_taken and is_instance_valid(shift.customer) and not shift.refusal_required() and not shift.closing_time and staff_at_counter()

func setup(host: Node3D) -> void:
	shift = host
	rng.randomize()
	chase = preload("res://robber_chase.gd").new()
	chase.setup(shift)
	layer = 110
	blood_flash = ColorRect.new()
	add_child(blood_flash)
	blood_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	blood_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	blood_flash.color = Color(.5,.015,.025,.0)
	_build_health_hud()
	blackout = ColorRect.new()
	blackout.color = Color.BLACK
	add_child(blackout)
	blackout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	caption = preload("res://diner_ui.gd").label("", 24)
	blackout.add_child(caption)
	caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	blackout.hide()

func _build_health_hud() -> void:
	health_panel = PanelContainer.new()
	add_child(health_panel)
	health_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	health_panel.offset_left = -170
	health_panel.offset_right = 170
	health_panel.offset_top = 64
	health_panel.offset_bottom = 174
	health_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	health_panel.add_theme_stylebox_override("panel",preload("res://diner_ui.gd").box(Color("191a1beF"),12))
	var rows := VBoxContainer.new()
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	health_panel.add_child(rows)
	rows.add_theme_constant_override("separation",5)
	player_label = preload("res://diner_ui.gd").label("PLAYER  100 / 100",16)
	rows.add_child(player_label)
	player_bar = _health_bar(rows,Color("85bf91"))
	robber_label = preload("res://diner_ui.gd").label("ROBBER  100 / 100",16)
	rows.add_child(robber_label)
	robber_bar = _health_bar(rows,Color("cc695d"))
	health_panel.hide()

func _health_bar(parent: Node, color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	parent.add_child(bar)
	bar.custom_minimum_size = Vector2(316,12)
	bar.max_value = MAX_HEALTH
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("background",preload("res://diner_ui.gd").box(Color("343435"),0))
	bar.add_theme_stylebox_override("fill",preload("res://diner_ui.gd").box(color,0))
	return bar

func _process(_delta: float) -> void:
	update_health_hud()

func ensure_health() -> void:
	if shift.refusal_required() and health_actor != shift.customer:
		health_actor = shift.customer
		player_health = MAX_HEALTH
		robber_health = MAX_HEALTH

func update_health_hud() -> void:
	if not is_instance_valid(health_panel): return
	ensure_health()
	health_panel.visible = shift.refusal_required() and not blackout.visible and (shift.phase in ["arriving","waiting"] or shift.is_practicing())
	player_bar.value = player_health
	robber_bar.value = robber_health
	var who := "TEAM" if shift.game.coop != null else "PLAYER"
	player_label.text = "%s  %d / %d" % [who,player_health,MAX_HEALTH]
	robber_label.text = "ROBBER  %d / %d" % [robber_health,MAX_HEALTH]

func damage_player() -> void:
	if not shift.refusal_required() or blackout.visible: return
	ensure_health()
	flash_damage()
	player_health = maxi(0,player_health-PLAYER_HIT_DAMAGE)
	if player_health == 0:
		fail()
	else:
		play_enemy_shot(shift.customer.global_position+Vector3(0,1.65,0))
		if shift.game.coop != null: shift.game.coop.share_robber_shot(shift.customer.global_position+Vector3(0,1.65,0))
		shift._message("You've been hit! Get behind cover. Health: %d / 100" % player_health)
	update_health_hud()

func flash_damage() -> void:
	if not is_instance_valid(blood_flash): return
	if blood_tween != null and blood_tween.is_valid(): blood_tween.kill()
	blood_flash.color.a = .24
	blood_tween = create_tween()
	blood_tween.tween_property(blood_flash,"color:a",0.0,.35)

func damage_robber(damage := ROBBER_HIT_DAMAGE) -> bool:
	ensure_health()
	robber_health = maxi(0,robber_health-damage)
	update_health_hud()
	return robber_health == 0

func health_state() -> Dictionary:
	ensure_health()
	return {"player":player_health,"robber":robber_health,"cooldown":shot_cooldown}

func restore_health(data: Dictionary) -> void:
	health_actor = shift.customer
	if shift.game.coop != null and not shift.game.coop.hosting and int(data.get("player",MAX_HEALTH)) < player_health: flash_damage()
	player_health = clampi(int(data.get("player",MAX_HEALTH)),0,MAX_HEALTH)
	robber_health = clampi(int(data.get("robber",MAX_HEALTH)),0,MAX_HEALTH)
	shot_cooldown = maxf(0,float(data.get("cooldown",0)))
	update_health_hud()

func tick(delta: float) -> void:
	ensure_health()
	if not shift.refusal_required() or (shift.phase != "waiting" and not shift.is_practicing()):
		remaining = -1.0
		enemy_state = "idle"
		return
	if shift.dialogue.is_open: return
	if remaining < 0.0:
		# A restored encounter must not silently arm while staff are in back.
		if not staff_at_counter(): return
		remaining = REACTION_SECONDS
		shot_cooldown = 0
		shots_fired = 0
		enemy_state = "warning"
		partner_last = shift.game.coop.partner_target if shift.game.coop != null else Vector3.ZERO
		partner_sample = 0
		partner_speed = 0
		chase.grid = null
		return
	remaining = maxf(0.0, remaining - delta)
	shot_cooldown = maxf(0,shot_cooldown-delta)
	var target: Vector3 = shift.game.player.global_position
	var moving: float = shift.game.player.velocity.length()
	var coop = shift.game.coop
	if coop != null and coop.partner_ready:
		partner_sample += delta
		if partner_sample >= .12:
			partner_speed = partner_last.distance_to(coop.partner_target)/partner_sample
			partner_last = coop.partner_target
			partner_sample = 0
	if coop != null and coop.partner_ready and shift.customer.global_position.distance_to(coop.partner_target) < shift.customer.global_position.distance_to(target):
		target = coop.partner_target
		moving = partner_speed
	var visible_target := can_see(target)
	var distance: float = shift.customer.global_position.distance_to(target)
	var pursuing := not _at_counter(target) or not visible_target or distance > 4.5
	enemy_state = "chasing" if pursuing else "warning" if remaining > 0 else "aiming"
	if pursuing and (distance > 2.25 or not visible_target):
		var moved: bool = chase.move(shift.customer,target,delta)
		shift._pose_customer(sin(shift.animation_time*19)*.8 if moved else 0)
	if visible_target:
		var direction: Vector3 = target-shift.customer.global_position
		shift.customer.rotation.y = atan2(direction.x,direction.z)
	if remaining <= 0 and shot_cooldown <= 0 and visible_target and distance <= SHOT_RANGE:
		shot_cooldown = SHOT_INTERVAL
		shots_fired += 1
		var chance := clampf(base_accuracy-(.30 if moving > 2 else 0.0)-maxf(0,distance-4)*.025,0,1)
		if rng.randf() < chance:
			damage_player()
		else:
			play_enemy_shot(shift.customer.global_position+Vector3(0,1.65,0))
			if coop != null: coop.share_robber_shot(shift.customer.global_position+Vector3(0,1.65,0))
			shift._message("The robber missed! Keep moving or get behind cover.")

func can_see(target: Vector3) -> bool:
	if not shift.refusal_required(): return false
	var origin: Vector3 = shift.customer.global_position+Vector3(0,1.65,0)
	var excluded: Array[RID] = [shift.game.player.get_rid()]
	for node in shift.customer.find_children("*","CollisionObject3D",true,false): excluded.append(node.get_rid())
	var ray := PhysicsRayQueryParameters3D.create(origin,target+Vector3(0,1.4,0),3,excluded)
	return shift.get_world_3d().direct_space_state.intersect_ray(ray).is_empty()

func play_enemy_shot(at: Vector3) -> void:
	shift.pistol.shot.play()
	var flash := OmniLight3D.new()
	shift.add_child(flash)
	flash.global_position = at
	flash.light_color = Color(1,.65,.2)
	flash.light_energy = 4
	flash.omni_range = 3
	var tween := flash.create_tween()
	tween.tween_property(flash,"light_energy",0.0,.09)
	tween.tween_callback(flash.queue_free)

func fail() -> void:
	if blackout.visible or not shift.refusal_required() or shift.dialogue.is_open: return
	var practice: bool = shift.is_practicing()
	var stolen: int = 0 if practice else shift.earnings.lose_shift_takings()
	remaining = -1.0
	show_blackout(stolen, practice)
	if shift.game.coop != null: shift.game.coop.share_robbery_failure(stolen, practice)
	if shift.carried_item == "Pistol": shift._clear_carried(false)
	if practice:
		shift._reset_customer()
		return
	shift._update_cash_display()
	shift.customers_this_shift += 1
	shift._depart_customer(false)
	shift._message("The robber escaped with $%d of this shift's earnings. Previous days' savings are safe." % stolen)

func show_blackout(stolen: int, practice: bool) -> void:
	blackout.modulate.a = 1.0
	caption.text = "You were shot. Try the practice encounter again." if practice else "You were shot.\nThe robber stole $%d of this shift's earnings.\nPrevious days' savings are safe." % stolen
	blackout.show()
	shift.pistol.shot.play()
	var recovery := create_tween()
	recovery.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	recovery.tween_interval(1.8)
	recovery.tween_property(blackout, "modulate:a", 0.0, 0.55)
	recovery.tween_callback(func():
		blackout.hide()
		if practice and (shift.game.coop == null or shift.game.coop.hosting):
			shift.tutorial.begin_encounter(shift)
	)
