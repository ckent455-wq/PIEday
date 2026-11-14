extends SceneTree
func _initialize(): call_deferred("run")
func run():
 root.set_meta("pie_day_wallet",preload("res://earnings.gd").new(false))
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 current_scene=game
 game.set_physics_process(false)
 var shift=game.shift
 shift.start_demo()
 shift.set_process(false)
 var ai=shift.robbery
 ai.update_health_hud()
 assert(not ai.health_panel.visible,"Bars hidden in ordinary service")
 shift._reset_customer()
 var actor=shift.customer_line.make_actor(Vector3(-2.4,-.094,-3.6),"robber_1")
 shift._bind_customer_actor(actor)
 shift.phase="waiting"
 shift.walking=false
 ai.update_health_hud()
 assert(ai.health_panel.visible and ai.player_health==100 and ai.robber_health==100)
 ai.damage_player()
 assert(ai.player_health==75 and not ai.blackout.visible)
 shift.carried_item="Pistol"
 shift._refresh_carried()
 assert(shift.pistol.fire(actor.get_node("Interaction")))
 assert(ai.robber_health==50 and shift.carried_item=="Pistol" and shift.refusal_required())
 var data=preload("res://save_states.gd").capture(game)
 ai.player_health=1
 ai.robber_health=1
 preload("res://save_states.gd").restore(game,data)
 ai.update_health_hud()
 assert(ai.player_health==75 and ai.robber_health==50 and ai.health_panel.visible,"Health survives full manual restore")
 if DisplayServer.get_name()!="headless":
  Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
  await create_timer(.2).timeout
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://builds/robbery-health-bars.png")
 ai.damage_player()
 ai.damage_player()
 assert(ai.player_health==25 and not ai.blackout.visible)
 ai.damage_player()
 assert(ai.player_health==0 and ai.blackout.visible)
 ai.update_health_hud()
 assert(not ai.health_panel.visible)
 shift.start_demo()
 ai.update_health_hud()
 assert(not ai.health_panel.visible)
 shift._reset_customer()
 var fresh=shift.customer_line.make_actor(Vector3(-2.4,-.094,-3.6),"robber_1")
 shift._bind_customer_actor(fresh)
 shift.phase="waiting"
 shift.walking=false
 ai.update_health_hud()
 assert(ai.player_health==100 and ai.robber_health==100,"Next robbery resets both bars")
 shift.carried_item="Pistol"
 shift._refresh_carried()
 shift.pistol.fire(fresh.get_node("Interaction"))
 shift.pistol.fire(fresh.get_node("Interaction"))
 ai.update_health_hud()
 assert(not ai.health_panel.visible and shift.corpses.bodies.size()==1,"Second hit defeats robber and hides bars")
 print("PASS: encounter-only HUD, four-hit player health, two-hit robber health, gun retained, save restoration, defeat/cleanup hiding and fresh encounter reset")
 quit()
