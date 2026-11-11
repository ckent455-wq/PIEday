extends Node3D

const APPLIANCES := {
	"oven":{"name":"Pie oven","cost":350},
	"grill":{"name":"Burger grill","cost":400},
	"fryer":{"name":"Fryer · donuts & fries","cost":300},
	"coffee":{"name":"Coffee machine","cost":250},
	"soda":{"name":"Soda fountain","cost":275}}
const BREAK_CHANCE := .4
const MAX_BROKEN := 2
var shift: Node3D
var enabled := true
var markers := {}
var status: Label
var smoke := {}
var bangs := {}
var previous := {}

func setup(host: Node3D) -> void:
	shift = host
	name = "ApplianceMaintenance"
	var anchors := {
		"oven":shift.oven.global_position+Vector3(0,.3,.5),
		"grill":shift.burger_station.grill.global_position+Vector3(.4,.55,0),
		"fryer":Vector3(1.0,1.9,-12.7),
		"coffee":shift.coffee_station.global_position+Vector3(0,.32,.4),
		"soda":shift.soda_station.global_position+Vector3(0,1.1,.15)}
	for id in APPLIANCES:
		var marker := StaticBody3D.new()
		marker.name = "Repair_"+id
		marker.set_meta("action","appliance_repair")
		marker.set_meta("appliance",id)
		add_child(marker)
		marker.global_position = anchors[id]
		var collider := CollisionShape3D.new()
		collider.shape = BoxShape3D.new()
		collider.shape.size = Vector3(.55,.32,.18)
		marker.add_child(collider)
		var plate := MeshInstance3D.new()
		plate.name = "OutOfOrderSign"
		var quad := QuadMesh.new()
		quad.size = Vector2(.78,.31)
		if id == "coffee": quad.size = Vector2(.48,.18)
		var material := StandardMaterial3D.new()
		material.albedo_color = Color("f5cd68")
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		if id == "coffee": material.billboard_mode = BaseMaterial3D.BILLBOARD_DISABLED
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		quad.material = material
		plate.mesh = quad
		marker.add_child(plate)
		var label: Label3D = shift._label(marker,"OUT OF ORDER\n%s\n[E] REPAIR $%d" % [APPLIANCES[id].name,APPLIANCES[id].cost],Vector3(0,0,.012),.001)
		label.modulate = Color("291b12")
		label.outline_size = 0
		if id == "coffee":
			label.text = "OUT OF ORDER\n[E] REPAIR $250"
			label.pixel_size = .00085
			label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
			collider.shape.size = Vector3(.5,.2,.06)
		markers[id] = marker
		_make_effects(id,anchors[id])
		previous[id] = is_broken(id)
	var hud := CanvasLayer.new()
	add_child(hud)
	status = preload("res://diner_ui.gd").label("",15,Color("ffad84"))
	hud.add_child(status)
	status.position = Vector2(24,64)
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	refresh()

func _make_effects(id: String, anchor: Vector3) -> void:
	var particles := CPUParticles3D.new()
	particles.name = "Smoke_"+id
	particles.emitting = false
	particles.amount = 24
	particles.lifetime = 2.8
	particles.direction = Vector3.UP
	particles.spread = 22
	particles.gravity = Vector3(.04,.12,0)
	particles.initial_velocity_min = .4
	particles.initial_velocity_max = .8
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = .1
	particles.scale_amount_min = .7
	particles.scale_amount_max = 1.5
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0,.15,.65,1])
	fade.colors = PackedColorArray([Color(.55,.55,.58,0),Color(.55,.55,.58,.12),Color(.65,.65,.68,.06),Color(.7,.7,.72,0)])
	particles.color_ramp = fade
	var radial := Gradient.new()
	radial.colors = PackedColorArray([Color.WHITE,Color(1,1,1,0)])
	var texture := GradientTexture2D.new()
	texture.gradient = radial
	texture.width = 32
	texture.height = 32
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(.5,.5)
	texture.fill_to = Vector2(1,.5)
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.albedo_color = Color(.48,.48,.5,.1)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = false
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var quad := QuadMesh.new()
	quad.size = Vector2(.55,.55)
	quad.material = material
	particles.mesh = quad
	var plume := preload("res://appliance_smoke.gd").new()
	plume.name = "Smoke_"+id
	plume.setup(particles)
	add_child(plume)
	plume.global_position = anchor+Vector3(.25,.28,.12)
	if id == "coffee":
		plume.global_position = shift.coffee_station.global_position+Vector3(-.25,.34,.02)
		if plume.uses_downloaded_asset:
			plume.effect.height = .6
			plume.effect.lifetime = 1.8
			plume.effect.puffs = 16
			plume.effect.source_radius = .045
			plume.effect.puff_size = Vector2(.08,.3)
			plume.effect.opacity = .42
		else:
			plume.effect.scale = Vector3.ONE*.5
	smoke[id] = plume
	var bang := AudioStreamPlayer3D.new()
	bang.stream = preload("res://assets/audio/appliance_breakdown.wav")
	bang.volume_db = 3
	bang.unit_size = 12
	bang.max_distance = 45
	add_child(bang)
	bang.global_position = anchor
	bangs[id] = bang

func is_broken(id: String) -> bool:
	return shift.earnings.equipment.broken.has(id)

func item_available(item: String) -> bool:
	if item.ends_with("pie"): return not is_broken("oven")
	if item in shift.BURGER_STATION.BURGERS: return not is_broken("grill")
	if item in shift.DONUTS.TYPES or item == shift.FRIES.SERVING: return not is_broken("fryer")
	if item == "Coffee": return not is_broken("coffee")
	if item in shift.soda_station.FLAVORS or item == "Soda": return not is_broken("soda")
	return true

func adapt_order(items: Array) -> Array[String]:
	var result: Array[String] = []
	for item in items:
		if item_available(item): result.append(item)
	if result.is_empty():
		var fallback: Array[String] = []
		for item in ["Apple pie","Burger","Glazed donut","Coffee","Cola"]:
			if item_available(item): fallback.append(item)
		if not fallback.is_empty(): result.append(fallback.pick_random())
	return result

func action_id(action: String, node: Node) -> String:
	match action:
		"appliance_repair": return str(node.get_meta("appliance",""))
		"oven": return "oven"
		"burger_grill","burger_raw","burger_prep","burger_topping": return "grill"
		"donut_fryer","donut","frozen_fries": return "fryer"
		"coffee","cup_stack": return "coffee"
		"soda","soda_cup_stack": return "soda"
	return ""

func repair_prompt(id: String) -> String:
	var cost: int = APPLIANCES[id].cost
	return "[E] Repair %s — $%d from surgery fund" % [APPLIANCES[id].name,cost] if shift.earnings.cash >= cost else "%s BROKEN · repair $%d · need $%d more" % [APPLIANCES[id].name,cost,cost-shift.earnings.cash]

func repair(id: String) -> bool:
	if not is_broken(id): return false
	var cost: int = APPLIANCES[id].cost
	if shift.earnings.cash < cost:
		shift._message("Repairs cost $%d. Earn $%d more by serving the working menu." % [cost,cost-shift.earnings.cash])
		return false
	if shift.earnings.grandpa.is_dead() or shift.earnings.grandpa.campaign_won: return false
	shift.earnings.cash -= cost
	# Repairs spend the current shift's takings before dipping into savings.
	shift.earnings.shift_takings = maxi(0,shift.earnings.shift_takings-cost)
	shift.earnings.equipment.broken.erase(id)
	shift.earnings.equipment.spent += cost
	shift.earnings._save()
	shift._update_cash_display()
	shift._update_shift_clock()
	refresh()
	shift._message("%s repaired for $%d. Its menu items are available again. Surgery fund: $%d." % [APPLIANCES[id].name,cost,shift.earnings.cash])
	return true

func busy(id: String) -> bool:
	match id:
		"oven": return not shift.oven.pie_item.is_empty()
		"grill": return shift.burger_station.cooking
		"fryer": return shift.donut_fryer.batches.any(func(batch): return batch.state != "empty")
		"coffee": return shift.coffee_station.state != "empty"
		"soda": return shift.soda_station.state != "empty"
	return false

func break_appliance(id: String) -> bool:
	if not APPLIANCES.has(id) or is_broken(id) or shift.earnings.equipment.broken.size() >= MAX_BROKEN: return false
	if shift.order_taken or not shift.carried_item.is_empty() or shift.has_empty_cup() or not shift.tray.is_empty() or busy(id): return false
	shift.earnings.equipment.broken[id] = true
	shift.earnings._save()
	refresh()
	shift._message("BREAKDOWN: %s is out of service. Its items are off the menu until you pay $%d to repair it." % [APPLIANCES[id].name,APPLIANCES[id].cost])
	return true

func begin_shift(random_orders: bool) -> void:
	enabled = random_orders and preload("res://playable_demo.gd").session(self) == null
	if not enabled: return
	var data: Dictionary = shift.earnings.equipment
	var day: int = shift.earnings.grandpa.days
	if data.roll_day == day: return
	if data.seed == 0: data.seed = randi_range(1,2147483646)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(data.seed)+day*104729
	data.roll_day = day
	data.pending = day >= 1 and data.broken.size() < MAX_BROKEN and rng.randf() < BREAK_CHANCE
	data.break_at = rng.randf_range(75,140)
	shift.earnings._save()

func before_customer() -> void:
	var data: Dictionary = shift.earnings.equipment
	if not enabled or not data.pending or shift.shift_remaining > data.break_at: return
	var candidates: Array[String] = []
	for id in APPLIANCES:
		if not is_broken(id) and not busy(id): candidates.append(id)
	if candidates.is_empty(): return
	var rng := RandomNumberGenerator.new()
	rng.seed = int(data.seed)+int(data.roll_day)*8191
	if break_appliance(candidates[rng.randi_range(0,candidates.size()-1)]):
		data.pending = false
		shift.earnings._save()

func _process(_delta: float) -> void:
	refresh()

func refresh() -> void:
	var lines := PackedStringArray()
	for id in APPLIANCES:
		var broken := is_broken(id)
		markers[id].visible = broken
		markers[id].collision_layer = 4 if broken else 0
		if id == "coffee": shift.coffee_station.status.visible = not broken
		if broken != bool(previous[id]):
			if broken: bangs[id].play()
			else: bangs[id].stop()
			previous[id] = broken
		smoke[id].emitting = broken
		smoke[id].visible = broken
		if broken: lines.append("%s: repair $%d" % [APPLIANCES[id].name,APPLIANCES[id].cost])
	status.text = "OUT OF SERVICE\n"+"\n".join(lines)
	status.visible = not lines.is_empty()
