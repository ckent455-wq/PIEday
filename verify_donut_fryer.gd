extends SceneTree
func _initialize(): call_deferred("check")
func check():
 var game = load("res://main.tscn").instantiate()
 root.add_child(game)
 game.shift.earnings.save_enabled = false
 var shift = game.shift
 shift.set_process(false)
 var fryer = shift.donut_fryer
 assert(fryer.batches.size() == 2)
 assert(not shift.start_shift())
 var target = game.find_children("Fryer*", "MeshInstance3D", true, false)[0]
 fryer.use(target)
 fryer._process(1)
 assert(fryer.batches[0].baskets.size() == 2)
 assert(fryer.batches[0].oil.size() == 2)
 assert(fryer.batches[0].oil[0].get_node("OilSurface").material_override.get_shader_parameter("frying") == 1.0)
 for basket in fryer.batches[0].baskets:
  assert(basket.mesh.position.y < basket.raised.y - 0.14)
 assert(fryer.batches[0].audio.playing)
 assert(fryer.batches[0].audio.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD)
 fryer.tick(3)
 fryer.use(target)
 assert(fryer.batches[0].state == "raw")
 assert(not fryer.batches[0].audio.playing)
 fryer._process(1)
 assert(fryer.batches[0].oil[0].get_node("OilSurface").material_override.get_shader_parameter("frying") == 0.0)
 for basket in fryer.batches[0].baskets:
  assert(basket.mesh.position.is_equal_approx(basket.raised))
 fryer.use(target)
 fryer.tick(2.5)
 fryer.use(target)
 fryer.use_case("Strawberry donut")
 assert(fryer.stock[0] == 6)
 fryer.use(target)
 fryer.tick(11)
 fryer.use(target)
 assert(fryer.batches[0].state == "empty" and fryer.stock[1] == 0)
 for flavor in ["Chocolate donut", "Glazed donut"]:
  fryer.use(target)
  fryer.tick(5)
  fryer.use(target)
  fryer.use_case(flavor)
 assert(shift.start_shift())
 var saved = fryer.snapshot()
 fryer.reset()
 assert(fryer.batches.all(func(batch): return not batch.audio.playing))
 fryer.restore(saved)
 assert(fryer.stock == [6,6,6])
 fryer.use_case("Glazed donut")
 assert(shift.carried_item == "Glazed donut" and fryer.stock[2] == 5)
 print("PASS: two existing fryers, opening gate, raw/golden/burnt batches, three flavors, stock consumption and snapshot restoration")
 quit()

