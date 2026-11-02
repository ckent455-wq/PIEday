extends Node
var shift: Node3D
var menu: CanvasLayer
var offered_visit := false

func setup(host: Node3D) -> void:
	shift = host
	menu = preload("res://visit_modal.gd").new()
	add_child(menu)
	menu.setup(shift.game)
	menu.selected.connect(_selected)

func open_departure() -> void:
	if shift.phase != "closed": return
	offered_visit = shift.earnings.grandpa.visit_available()
	if offered_visit:
		menu.show_choices("HOSPITAL VISITING HOURS ARE OPEN", "Closing duties are finished. Visit Grandpa at the hospital, or head home and rest for tomorrow.", ["Visit Grandpa","Go Home","Stay a little longer"])
	else:
		menu.show_choices("READY TO HEAD HOME?", "The diner is closed and your duties are finished. Get some rest before the next morning.", ["Go Home","Stay a little longer"])

func _selected(index: int) -> void:
	if shift.phase != "closed": return
	if offered_visit and index == 0:
		if not shift.earnings.grandpa.start_visit(): return
		shift.earnings._save()
		preload("res://hospital_travel.gd").go(self,"res://hospital_room.tscn",shift.earnings)
	elif index == (1 if offered_visit else 0):
		shift.earnings.grandpa.finish_evening()
		shift.earnings._save()
		preload("res://hospital_travel.gd").go(self,"res://main.tscn",shift.earnings)
