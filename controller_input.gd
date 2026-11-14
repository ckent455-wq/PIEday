extends RefCounted

const LOOK_SPEED := 2.4

static func movement() -> Vector2:
	var keyboard := Vector2(
		float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
		float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
	)
	return (keyboard + Input.get_vector("move_left", "move_right", "move_forward", "move_back")).limit_length()

static func look(delta: float) -> Vector2:
	var stick := Input.get_vector("look_left", "look_right", "look_up", "look_down")
	return stick * stick.length() * LOOK_SPEED * delta

static func advance(event: InputEvent) -> bool:
	return event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E)

static func back(event: InputEvent) -> bool:
	return event.is_action_pressed("ui_cancel") or event.is_action_pressed("pad_pause")
