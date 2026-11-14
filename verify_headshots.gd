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
 for model in ["robber_1","robber_2"]:
  shift._reset_customer()
  var actor=shift.customer_line.make_actor(Vector3(-2.4,-.094,-3.6),model)
  actor.rotation.y=PI
  shift._bind_customer_actor(actor)
  shift.phase="waiting"
  shift.walking=false
  shift.carried_item="Pistol"
  shift._refresh_carried()
  await physics_frame
  await physics_frame
  var skeleton:Skeleton3D=actor.get_meta("skeleton")
  var head:Vector3=skeleton.global_transform*skeleton.get_bone_global_pose(skeleton.find_bone("DEF-spine.006")).origin
  assert(not shift.pistol.is_headshot(actor.global_position+Vector3.UP*1.35))
  assert(shift.pistol.is_headshot(head+Vector3.UP*.12))
  var eye=Vector3(-2.4,1.95,-5.8)
  var aim=head+Vector3.UP*.12
  shift.pistol.fire_ray(eye,eye.direction_to(aim))
  assert(not shift.refusal_required() and shift.robbery.robber_health==0,"Actual head ray defeats full-health "+model)
  assert(shift.notice.text.begins_with("Headshot!"))
  assert(not shift.find_children("BulletBlood","CPUParticles3D",true,false).is_empty())
  if DisplayServer.get_name()!="headless" and model=="robber_1":
   game.player.position=Vector3(-2.4,.03,-5.8)
   game.face_point(aim)
   Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
   await create_timer(.08).timeout
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("res://builds/headshot-blood-preview.png")
  shift.corpses.reset()
 var fresh=shift.customer_line.make_actor(Vector3(-2.4,-.094,-3.6),"robber_1")
 shift._bind_customer_actor(fresh)
 shift.phase="waiting"
 shift.robbery.damage_player()
 assert(shift.robbery.blood_flash.color.a>0,"Player damage produces brief red feedback")
 await create_timer(.55).timeout
 assert(shift.find_children("BulletBlood","CPUParticles3D",true,false).is_empty(),"Blood bursts clean themselves up")
 assert(shift.robbery.blood_flash.color.a<.01)
 print("PASS: head/body classification for both robber rigs, actual one-shot head rays, hit notice, transient blood cleanup and player damage flash")
 quit()
