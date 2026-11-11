extends CanvasLayer

const REACTION_SECONDS := 3.0
var shift: Node3D
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
	layer = 110
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

func tick(delta: float) -> void:
	if not shift.refusal_required() or (shift.phase != "waiting" and not shift.is_practicing()):
		remaining = -1.0
		return
	if shift.dialogue.is_open: return
	if remaining < 0.0:
		# A restored encounter must not silently arm while staff are in back.
		if not staff_at_counter(): return
		remaining = REACTION_SECONDS
		return
	remaining = maxf(0.0, remaining - delta)
	if remaining <= 0.0: fail()

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
