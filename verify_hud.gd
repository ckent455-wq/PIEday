extends SceneTree
var failures := 0
func _initialize(): call_deferred("check")
func require(value: bool, message: String):
	if not value:
		push_error(message)
		failures += 1
func capture(name: String):
	if DisplayServer.get_name() == "headless": return
	await create_timer(0.15).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://builds/" + name + ".png")
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.set_physics_process(false)
	game.set_process_unhandled_input(false)
	var shift = game.shift
	shift.set_process(false)
	shift.earnings.save_enabled = false
	shift.start_demo()
	shift.customer_line.next_arrival = INF
	for frame in range(620): shift._process(1.0 / 60.0)
	shift.interact(shift.customer.get_node("Interaction"))
	shift.dialogue.finish()
	shift.order.assign(["Donut", "Donut", "Coffee"])
	shift._refresh_hud()
	require(shift.order_text.text.contains("Donut ×2"), "Order groups duplicate items")
	shift.add_item("Donut")
	shift._refresh_hud()
	require(not shift.order_text.text.contains("✓  Donut"), "Partial quantity remains unchecked")
	shift.add_item("Donut")
	shift._refresh_hud()
	require(shift.order_text.text.contains("✓  Donut"), "Full tray quantity checks item off")
	shift.discard_last()
	shift._refresh_hud()
	require(not shift.order_text.text.contains("✓  Donut"), "Taking an item back updates order")
	game.camera.look_at(shift.customer.global_position + Vector3(0, 1.65, 0))
	game._update_interaction()
	await capture("clean-ui-order")
	game.pause_menu.pause_game()
	await capture("clean-ui-pause")
	game.pause_menu.resume_game()
	shift.begin_cleanup()
	shift.complete_task("kitchen")
	shift._refresh_hud()
	require(shift.order_heading.text == "CLOSING CHECKLIST" and shift.order_text.text.contains("✓  Clean the kitchen"), "Closing card tracks completed chores")
	await capture("clean-ui-closing")
	shift.notice.text = ""
	shift._refresh_hud()
	require(not shift.notice_panel.visible and not shift.payment_panel.visible, "Empty notices leave view clear")
	if failures == 0: print("PASS: order quantities, tray completion and undo, closing checklist, empty notice visibility")
	quit(1 if failures else 0)
