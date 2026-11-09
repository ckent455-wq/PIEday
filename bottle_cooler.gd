extends Node3D

const ITEMS := ["2-liter Lemon Fizz", "2-liter Dr. Paw Paw", "2-liter Orange Soda", "2-liter Cola"]
const SHELVES := ["Refreshments", "Refreshments_01", "Refreshments_02", "Refreshments_03"]
var shift: Node3D
var bottles: Array[Node3D] = []
var models: Dictionary = {}

func setup(owner_shift: Node3D) -> void:
	shift = owner_shift
	name = "GrabAndGoCooler"
	var left: MeshInstance3D = shift.game.find_child("Refrigerator_Door_01", true, false)
	var right: MeshInstance3D = shift.game.find_child("Refrigerator_Door", true, false)
	for index in SHELVES.size():
		var shelf: MeshInstance3D = shift.game.find_child(SHELVES[index], true, false)
		_install_shelf(shelf, ITEMS[index], left if index < 2 else right)
		var bounds := shelf.global_transform * shelf.get_aabb()
		var label_position := Vector3(bounds.get_center().x, bounds.position.y - 0.022, -6.94)
		var label: Label3D = shift._label(self, ITEMS[index].trim_prefix("2-liter ").to_upper(), label_position, 0.001)
		label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	var sign: Label3D = shift._label(self, "GRAB & GO  •  2-LITERS", Vector3(5.38, 2.66, -6.80), 0.003)
	sign.billboard = BaseMaterial3D.BILLBOARD_DISABLED

func _install_shelf(shelf: MeshInstance3D, item: String, door: MeshInstance3D) -> void:
	# The imported shelf is one mesh with six disconnected bottles. Weld
	# matching positions across UV seams to recover each textured bottle.
	var arrays := shelf.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var parents := PackedInt32Array()
	var positions := {}
	for index in vertices.size():
		var point := vertices[index].snapped(Vector3.ONE * 0.0001)
		if not positions.has(point): positions[point] = index
		parents.append(positions[point])
	for triangle in range(0, indices.size(), 3):
		var group := _root_of(parents, indices[triangle])
		parents[_root_of(parents, indices[triangle + 1])] = group
		parents[_root_of(parents, indices[triangle + 2])] = group
	var groups := {}
	for index in indices:
		var group := _root_of(parents, index)
		if not groups.has(group): groups[group] = []
		groups[group].append(index)
	for group in groups.values():
		var bounds := AABB(shelf.global_transform * vertices[group[0]], Vector3.ZERO)
		for index in group: bounds = bounds.expand(shelf.global_transform * vertices[index])
		var base := Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z)
		var builder := SurfaceTool.new()
		builder.begin(Mesh.PRIMITIVE_TRIANGLES)
		builder.set_material(shelf.get_active_material(0))
		for index in group:
			builder.set_normal((shelf.global_basis * normals[index]).normalized())
			builder.set_uv(uvs[index])
			builder.add_vertex(shelf.global_transform * vertices[index] - base)
		var mesh := builder.commit()
		models[item] = mesh
		_add_bottle(item, door, mesh, base, bounds.size)
	shift._set_pickup_visible(shelf, false)

func _root_of(parents: PackedInt32Array, index: int) -> int:
	while parents[index] != index: index = parents[index]
	return index

func _add_bottle(item: String, door: MeshInstance3D, mesh: Mesh, base: Vector3, size: Vector3) -> void:
	var bottle := Node3D.new()
	bottle.name = "Bottle_%d" % bottles.size()
	bottle.set_meta("action", "bottle")
	bottle.set_meta("item", item)
	bottle.set_meta("cooler_door", door)
	add_child(bottle)
	bottle.global_position = base
	bottles.append(bottle)
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	bottle.add_child(visual)
	var body := StaticBody3D.new()
	bottle.add_child(body)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size * Vector3(0.92, 0.98, 0.92)
	collision.shape = shape
	collision.position.y = size.y * 0.5
	body.add_child(collision)

func take(bottle: Node3D) -> void:
	if not bottle.visible or not bottle.get_meta("cooler_door").get_meta("open"): return
	shift.pickup_item(bottle.get_meta("item"), bottle)

func model(holder: Node3D, item: String) -> void:
	var visual := MeshInstance3D.new()
	visual.mesh = models[item]
	visual.scale = Vector3.ONE * 0.46
	holder.add_child(visual)

func available_items() -> Array[String]:
	var stocked: Array[String] = []
	for bottle in bottles:
		var item: String = bottle.get_meta("item")
		if bottle.visible and not stocked.has(item): stocked.append(item)
	return stocked

func snapshot() -> Array:
	return bottles.map(func(bottle): return bottle.visible)

func restore(stock: Array) -> void:
	for index in mini(stock.size(), bottles.size()):
		if bottles[index].visible != stock[index]:
			shift._set_pickup_visible(bottles[index], stock[index])

func refill() -> void:
	for bottle in bottles: shift._set_pickup_visible(bottle, true)
