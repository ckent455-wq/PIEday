extends SceneTree
func _initialize() -> void:
	var room = load("res://hospital_room.tscn").instantiate()
	room.ensure_furniture_collisions()
	var scene := PackedScene.new()
	var error := scene.pack(room)
	if error == OK: error = ResourceSaver.save(scene,"res://hospital_room.tscn")
	print("SAVED_FURNITURE_COLLISIONS ",error)
	room.free()
	quit(error)
