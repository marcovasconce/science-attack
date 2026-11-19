extends SceneTree
var stage
var boss
var finale
func _initialize() -> void: call_deferred("run")
func capture(label: String) -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png("res://art/previews/shield_"+label+".png")
	return image
func effects(dt: float) -> void:
	for effect in get_nodes_in_group("tnt_explosion_fx")+get_nodes_in_group("shield_block_fx"):
		effect.set_process(false)
		effect._process(dt)
func run() -> void:
	stage = load("res://scenes/gameplay/lower_lab_stage.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	await process_frame
	stage.set_process(false)
	stage.elevator.set_physics_process(false)
	stage.elevator._physics_process(3)
	finale = stage.finale
	finale.set_process(false)
	stage.beat = stage.Beat.FINISHED
	finale.cleaned = true
	finale.state = finale.State.OPEN
	for player in stage.players:
		player.set_physics_process(false)
		player.sprite.play(player.equipped_weapon+"_idle")
		player.update_sprite_alignment()
	finale.begin_boss()
	boss = finale.boss
	boss.set_physics_process(false)
	finale._process(1.2)
	stage.get_node("Camera2D").position = Vector2(finale.CENTER,180)
	stage.get_node("Camera2D").zoom = Vector2.ONE*finale.CAMERA_ZOOM
	stage.get_node("Camera2D").offset = Vector2.ZERO
	boss._physics_process(0.2)
	await capture("wide_arena")
	finale.boss_hud.intro = false
	DirAccess.make_dir_recursive_absolute("res://.godot/shield_idle_frames")
	for i in 48:
		boss._physics_process(1.0/24)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/shield_idle_frames/%03d.png" % i)
	finale.start_fight()
	boss.position = Vector2(finale.CENTER,280)
	boss.state = boss.State.IDLE
	boss.age = 0
	boss._physics_process(0.1)
	boss.state = boss.State.CHARGE
	boss._use_action_art()
	boss.direction = -1
	for i in 8: boss._physics_process(0.016)
	await capture("charge_trail")
	boss.position = Vector2(finale.CENTER,280)
	boss.state = boss.State.IDLE
	boss.age = 0
	boss.trail_points.clear()
	boss._physics_process(0.1)
	var p = stage.players[0]
	p.position = boss.position-Vector2(64,0)
	p.facing = 1
	p.sprite.play("brush_idle")
	stage.damage_enemy(p,boss,100,1,boss.position)
	effects(0.08)
	await capture("block_impact")
	for effect in get_nodes_in_group("shield_block_fx"): effect.free()
	boss.hp = 975
	var orange := await capture("orange_over_red")
	assert(orange.get_pixel(240,30).is_equal_approx(Color("f29a27")),"Orange must cover the left of the bar")
	assert(orange.get_pixel(440,30).is_equal_approx(Color("e83f40")),"Lost orange must reveal red in the same bar")
	boss.hp = 325
	var red := await capture("red_over_empty")
	assert(red.get_pixel(240,30).is_equal_approx(Color("e83f40")),"Remaining red must occupy the left of the bar")
	assert(red.get_pixel(440,30).is_equal_approx(Color("352624")),"Lost red must expose the empty background")
	boss.hp = boss.MAX_HP
	var bomb = finale.TNT.new()
	bomb.position = boss.position-Vector2(56,0)
	bomb.target_boss = boss
	stage.add_child(bomb)
	bomb.set_physics_process(false)
	bomb.height = 0
	bomb._physics_process(0.01)
	p.position = bomb.position-Vector2(55,0)
	stage.strike(p,1,[])
	effects(0.24)
	await capture("explosion")
	for effect in get_nodes_in_group("tnt_explosion_fx"): effect.free()
	for crate in get_nodes_in_group("boss_tnt"): crate.free()
	boss.hp = boss.MAX_HP
	boss.position = Vector2(finale.RIGHT-100,280)
	boss.wind_up()
	p.position = Vector2(finale.CENTER-110,310)
	stage.players[1].position = Vector2(finale.LEFT+220,212)
	for player in stage.players:
		player.hp = 100
		player.sprite.play(player.equipped_weapon+"_idle")
		player.update_sprite_alignment()
	# Demonstrate a persistent TNT left on the floor, detonated by the next charge.
	bomb = finale.TNT.new()
	bomb.position = Vector2(finale.CENTER,310)
	bomb.target_boss = boss
	stage.add_child(bomb)
	bomb.set_physics_process(false)
	bomb.height = 0
	bomb._physics_process(0.01)
	DirAccess.make_dir_recursive_absolute("res://.godot/shield_revision_frames")
	for i in 216:
		boss._physics_process(1.0/30)
		stage.update_camera_shake(1.0/30)
		for crate in get_nodes_in_group("boss_tnt"):
			crate.set_physics_process(false)
			crate._physics_process(1.0/30)
		effects(1.0/30)
		finale._process(1.0/30)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/shield_revision_frames/%03d.png" % i)
	boss.position = Vector2(finale.CENTER,280)
	boss.direction = -1
	boss.hp = 10
	boss._apply_damage(10)
	boss._physics_process(0.6)
	await capture("death_prone")
	boss.age = 0.81
	boss._physics_process(0.001)
	await capture("death_blink")
	print("PASS: rendered orange-over-red and red-over-empty health bar pixels")
	quit()
