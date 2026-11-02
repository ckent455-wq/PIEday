extends SceneTree
## One-time conversion of the prototype into an editable Godot scene.
func _initialize() -> void:
	var room = load("res://hospital_room.gd").new()
	room.name = "GrandpasHospitalRoom"
	room.furnishings = Node3D.new()
	room.furnishings.name = "Furniture"
	room.add_child(room.furnishings)
	room.fixtures = Node3D.new()
	room.fixtures.name = "RoomShell"
	room.add_child(room.fixtures)
	room._build_room()
	assign_owners(room,room)
	var scene := PackedScene.new()
	var result := scene.pack(room)
	if result == OK: result = ResourceSaver.save(scene,"res://hospital_room.tscn")
	print("EDITABLE_ROOM_SAVE ",result)
	room.free()
	quit(result)

func assign_owners(node: Node, scene_root: Node) -> void:
	for child in node.get_children():
		child.owner = scene_root
		assign_owners(child,scene_root)
