extends SceneTree
func _initialize(): call_deferred("check")
func check():
	root.set_meta("pie_day_wallet",preload("res://earnings.gd").new(false))
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.shift.set_process(false)
	game.shift.start_demo()
	var count := 0
	for door in game.doors:
		if not door.has_meta("cooler"): continue
		count += 1
		var sound=door.get_node("OpeningSound")
		assert(not sound.playing)
		game._toggle_door(door)
		assert(sound.playing and door.get_meta("open"))
		sound.stop()
		game._set_door_open(door,true)
		assert(not sound.playing,"Already-open door does not play sound again")
		game._toggle_door(door)
		assert(not sound.playing,"Opening sample is not used for closing")
		game._toggle_door(door)
		assert(sound.playing,"Reopening sounds again")
	assert(count==2)
	print("PASS: both cooler leaves play shared sound on opening, no repeat for unchanged state, closing silent, reopening works")
	quit()
