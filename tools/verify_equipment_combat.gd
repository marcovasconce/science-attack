extends SceneTree
var failures: Array[String] = []
var arena: Node2D
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)
func _initialize() -> void: call_deferred("run")
func press(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	arena.encounter._unhandled_input(event)
func enemy(at: Vector2) -> Node2D:
	var germ = arena.GermScene.instantiate()
	germ.position = at
	germ.hp = 200
	arena.get_node("Actors").add_child(germ)
	germ.set_physics_process(false)
	return germ
func bubble(player) -> Node2D:
	var shot = arena.spawn_bubble(player)
	shot.set_physics_process(false)
	return shot
func clear_shots() -> void:
	for shot in arena.get_node("Projectiles").get_children(): shot.free()
func run() -> void:
	arena = load("res://scenes/gameplay/micro_arena.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	arena.set_process(false)
	arena.tutorial.set_process(false)
	arena.encounter.set_process(false)
	arena.get_node("WakeSequence").pause()
	arena.players[0].sprite.position = Vector2(0,-10)
	arena.players[0].sprite.frame = 1
	check(arena.players[0].sprite.position == Vector2(0,-10),"Detailed-sprite anchoring must not override the waking cutscene")
	arena.get_node("WakeSequence").seek(3.6,true)
	arena.get_node("WakeSequence").pause()
	arena.tutorial.step = 7
	arena.controls_locked = false
	for p in arena.players: p.set_physics_process(false)
	for crate in arena.get_node("Breakables").get_children():
		crate.freeze = true
		crate.broken = true
		crate.collision_layer = 0
	var player = arena.players[0]
	var partner = arena.players[1]
	check(player.equipped_weapon == "none" and partner.equipped_weapon == "none","Both avatars begin with their normal punches")
	check(not player.equip_weapon("invalid"),"Invalid weapon choices are rejected")
	for avatar in arena.players:
		var frames: SpriteFrames = avatar.sprite.sprite_frames
		check(frames.get_frame_count("build") == 12,"Assembly has twelve empty-handed frames")
		for i in 12:
			check("assets/avatars/" in frames.get_frame_texture("build",i).atlas.resource_path,"Assembly uses the original avatar body without the yellow part")
		for weapon in ["brush","bubbles"]:
			for state in ["idle","run","attack"]:
				var count := 8 if state == "idle" else (6 if state == "run" else (12 if weapon == "brush" and state == "attack" else 4))
				check(frames.has_animation(weapon+"_"+state) and frames.get_frame_count(weapon+"_"+state) == count,"Both avatars have original pixel idle, running and attack frames for each weapon")
	arena.encounter.unlock_route()
	player.position = Vector2(1700,305)
	partner.position = Vector2(1640,315)
	player.hp = 71
	var flasks: int = player.healing_flasks
	arena.encounter.try_interact(player)
	press("p0_down")
	press("p0_attack")
	check(player.equipped_weapon == "bubbles" and partner.equipped_weapon == "none","P1 equips their selected weapon independently")
	press("p0_right")
	press("p0_attack")
	check(partner.equipped_weapon == "brush","Solo player can choose the AI companion's weapon")
	check(player.hp == 71 and player.healing_flasks == flasks,"Equipping preserves health and healing inventory")
	press("p0_interact")
	check(not arena.controls_locked,"Leaving equipment restores gameplay")
	partner.ai_controlled = false
	partner.position = Vector2(1700,305)
	arena.encounter.try_interact(partner)
	press("p1_down")
	press("p1_attack")
	check(partner.equipped_weapon == "bubbles" and player.equipped_weapon == "bubbles","Both players may independently choose the same weapon")
	press("p0_up")
	press("p0_attack")
	check(player.equipped_weapon == "brush" and partner.equipped_weapon == "bubbles","Co-op P1 controls do not change P2's equipment")
	press("ui_cancel")
	player.position = Vector2(400,240)
	partner.position = Vector2(180,320)
	player.facing = 1
	var germ = enemy(Vector2(490,240))
	player.equipped_weapon = "none"
	var targets: Array = []
	arena.strike(player,1,targets)
	check(germ.hp == 200,"Normal punch does not reach a target 90 pixels away")
	player.equip_weapon("brush")
	arena.strike(player,1,targets)
	check(germ.hp == 172,"Toothbrush sword reaches beyond normal punches")
	arena.strike(player,1,targets)
	check(germ.hp == 172,"A sword swing only damages a target once")
	germ.position = Vector2(520,240)
	arena.strike(player,1,[])
	check(germ.hp == 172,"Toothbrush remains a short-range weapon")
	player.facing = -1
	germ.position = Vector2(310,240)
	arena.strike(player,1,[])
	check(germ.hp == 144,"Sword attacks work facing left")
	germ.position.y = 310
	arena.strike(player,1,[])
	check(germ.hp == 144,"Melee still respects lane depth")
	player.equip_weapon("bubbles")
	player.position = Vector2(200,240)
	player.facing = 1
	germ.position = Vector2(500,240)
	player.reset_hit_combo()
	partner.reset_hit_combo()
	var shot = bubble(player)
	check(germ.hp == 144,"Bubble damage is not instantaneous")
	shot._physics_process(1.0)
	check(germ.hp == 134 and shot.popping and shot.position.x > 470,"Travelling bubble hits a distant enemy with swept collision")
	check(player.hit_combo == 1 and partner.hit_combo == 0,"Projectile combo credit belongs only to its shooter")
	shot._physics_process(0.05)
	check(germ.hp == 134,"Popping bubbles cannot damage twice")
	clear_shots()
	player.position = Vector2(500,240)
	player.facing = -1
	germ.position = Vector2(200,240)
	shot = bubble(player)
	shot._physics_process(1.0)
	check(germ.hp == 124,"Bubbles travel and hit to the left")
	clear_shots()
	player.position = Vector2(200,240)
	player.facing = 1
	germ.position = Vector2(360,310)
	shot = bubble(player)
	shot._physics_process(0.6)
	check(germ.hp == 124 and not shot.popping,"Bubbles do not hit enemies in a different depth lane")
	var frozen_at: Vector2 = shot.position
	arena.controls_locked = true
	shot._physics_process(0.5)
	check(shot.position == frozen_at,"Projectiles freeze while equipment or help pauses gameplay")
	arena.controls_locked = false
	clear_shots()
	player.position = Vector2(520,240)
	germ.position = Vector2(800,240)
	arena.get_node("Gate/Collision").disabled = false
	await physics_frame
	shot = bubble(player)
	shot._physics_process(1.0)
	check(shot.popping and shot.position.x <= 580.1 and germ.hp == 124,"Bubbles stop at solid world blockers")
	clear_shots()
	arena.get_node("Gate/Collision").disabled = true
	germ.position = Vector2(1000,310)
	player.position = Vector2(200,240)
	var crate = arena.get_node("Breakables/Crate0")
	crate.broken = false
	crate.hp = 32
	crate.position = Vector2(450,240)
	shot = bubble(player)
	shot._physics_process(0.9)
	check(crate.hp == 22 and shot.popping,"Soap bubbles also strike breakable crates")
	crate.broken = true
	clear_shots()
	player.position = Vector2(100,240)
	shot = bubble(player)
	shot._physics_process(2.7)
	check(shot.popping,"Unused bubbles expire after their finite map range")
	clear_shots()
	player.position = Vector2(200,300)
	player.bubble_cooldown = 0
	Input.action_press("p0_attack")
	for i in 10: player._physics_process(0.05)
	Input.action_release("p0_attack")
	check(arena.get_node("Projectiles").get_child_count() == 2,"Holding attack fires at the slower 0.28-second interval")
	var count: int = arena.get_node("Projectiles").get_child_count()
	arena.controls_locked = true
	Input.action_press("p0_attack")
	player._physics_process(1.0)
	Input.action_release("p0_attack")
	check(arena.get_node("Projectiles").get_child_count() == count,"Paused players cannot fire")
	arena.controls_locked = false
	clear_shots()
	partner.ai_controlled = true
	partner.equip_weapon("bubbles")
	partner.position = Vector2(180,240)
	germ.position = Vector2(400,240)
	partner._physics_process(0.01)
	check(arena.get_node("Projectiles").get_child_count() == 1,"Equipped AI fires from ranged distance")
	clear_shots()
	arena.tutorial.step = 5
	partner.bubble_cooldown = 0
	partner._physics_process(0.2)
	check(arena.get_node("Projectiles").get_child_count() == 0,"AI still leaves tutorial combat to the human")
	if failures.is_empty(): print("PASS: original-pixel empty-hand build, equipped animations, individual/AI selection, inventory preservation, sword reach, automatic bubble travel/collision/damage/expiry, pause, ownership and ranged AI")
	else:
		for failure in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
