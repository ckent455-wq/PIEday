extends SceneTree
var room
func _initialize():call_deferred("check")
func check():
 var wallet=preload("res://earnings.gd").new(false)
 wallet.grandpa.days=3
 wallet.grandpa.health=78
 wallet.grandpa.last_setback_day=3
 wallet.grandpa.last_setback_id="mistreatment"
 root.set_meta("pie_day_wallet",wallet)
 room=load("res://hospital_room.tscn").instantiate()
 root.add_child(room)
 current_scene=room
 await process_frame
 var incident=room.incident
 assert(incident.pending() and incident.begin())
 incident.set_process(false)
 assert(incident.active and incident.shot.current and not room.prompt.is_visible_in_tree())
 incident.elapsed=1.85
 incident._render()
 assert(incident.impacted)
 assert(incident.impact.playing and incident.impact.volume_db == 0)
 assert(not incident.grunted and not incident.grunt.playing)
 incident.elapsed=1.96
 incident._render()
 assert(incident.grunted and incident.grunt.playing)
 incident.elapsed=2.3
 incident._render()
 assert(incident.blackout.color.a > .99)
 incident.finish(true)
 assert(not incident.active and room.camera.current and room.conversation.is_open)
 assert(wallet.grandpa.health==78 and wallet.grandpa.last_witnessed_mistreatment_day==3)
 assert(not incident.begin())
 var config=ConfigFile.new()
 wallet.grandpa.write_config(config)
 var restored=preload("res://grandpa_progress.gd").new()
 restored.read_config(config)
 assert(restored.last_witnessed_mistreatment_day==3)
 await process_frame
 print("PASS: pending incident, cinematic camera, single impact, blackout, camera/control restoration, dialogue handoff, no extra health loss and saved replay guard")
 quit()

