extends SceneTree
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)
func run() -> void:
	var arena = load("res://scenes/gameplay/micro_arena.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	arena.set_process(false)
	arena.tutorial.set_process(false)
	arena.encounter.set_process(false)
	arena.get_node("WakeSequence").seek(3.6,true)
	arena.get_node("WakeSequence").pause()
	arena.tutorial.step = 7
	arena.controls_locked = false
	for actor in arena.players: actor.set_physics_process(false)
	for actor in arena.players:
		actor.ai_controlled = false
		actor.position = Vector2(200,240)
		actor.equip_weapon("brush")
		actor._physics_process(0.01)
		check(actor.pixel_visual.visible and not actor.sprite.visible,"Equipment composite replaces only the visible sprite")
		check(actor.pixel_visual.display.scale == Vector2(2,2),"Composite keeps original two-screen-pixels-per-art-pixel scale")
		for anim in actor.sprite.sprite_frames.get_animation_names():
			for i in actor.sprite.sprite_frames.get_frame_count(anim):
				var texture = actor.sprite.sprite_frames.get_frame_texture(anim,i)
				check(texture.get_size() == Vector2(32,32) and "assets/avatars/" in texture.atlas.resource_path,"Every body frame remains an untouched 32px original")
		for combo in 3:
			actor.start_attack()
			actor._physics_process(actor.attack_duration*0.55)
			check(actor.sprite.animation == actor.BRUSH_COMBO[combo],"Consecutive attacks play lateral, rising and overhead swings")
			check(actor.attack_contact_active(),"Contact window matches the visible swing")
			var frame: int = actor.sprite.frame
			var time: float = actor.attack_time
			arena.controls_locked = true
			actor._physics_process(1.0)
			check(actor.sprite.frame == frame and actor.attack_time == time,"Menu pause freezes the swing and its contact clock")
			arena.controls_locked = false
			actor._physics_process(actor.attack_time+0.01)
		actor._physics_process(0.6)
		actor.start_attack()
		check(actor.combo == 1,"An interrupted combo restarts with the first swing")
		actor.attack_time = 0
		actor.jump_height = 25
		actor.jump_speed = 0
		actor.start_attack()
		actor._physics_process(0.1)
		check(actor.sprite.animation == &"brush_air" and actor.get_node("Visual").position.y < 0,"Jump attacks use a distinct airborne swing")
		actor.facing = -1
		actor._physics_process(0.01)
		check(actor.pixel_visual.scale.x == -1,"The whole weapon and body animation mirrors together")
		actor.attack_time = 0
		actor.jump_height = 0
		actor.jump_speed = 0
		actor.stun = 0.2
		actor._physics_process(0.01)
		check(actor.sprite.animation == &"hurt" and actor.sprite.visible and not actor.pixel_visual.visible,"Hit reaction restores the matching original sprite")
	if failures.is_empty(): print("PASS: original 32px identity, integer pixel scale, three distinct brush combos, airborne swing, damage timing, pause, chain reset, mirroring and hit reaction")
	else:
		for message in failures: push_error(message)
	quit(0 if failures.is_empty() else 1)
