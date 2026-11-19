extends Node
## Throw -> foam -> one full second covered -> blue sewer -> team high-five -> victory.
const Soap = preload("res://scripts/finale_soap_overlay.gd")
const HighFive = preload("res://scripts/high_five_celebration.gd")
const CLEAN = preload("res://scripts/hive_clean_palette.gdshader")
const THROWS := [preload("res://assets/avatars/Owlet_Monster/Owlet_Monster_Throw_4.png"),preload("res://assets/avatars/Pink_Monster/Pink_Monster_Throw_4.png")]
const FILL_START := 0.55
const COVERED_AT := 1.35
const REVEAL_AT := COVERED_AT + 1.0
const WALK_AT := 2.8
const FIVE_AT := 3.8
const VICTORY_AT := 5.8
var stage: Node2D
var age := 0.0
var cleaned := false
var complete := false
var bottle: Sprite2D
var start := Vector2.ZERO
var target := Vector2.ZERO
var center := Vector2.ZERO
var overlay: Control
var high_five: Node2D
var clean_material: ShaderMaterial
var throwing_player: CharacterBody2D
func begin(arena: Node2D, thrower) -> void:
	stage = arena
	bottle = stage.jar.get_node("Bottle")
	start = thrower.global_position-Vector2(0,37)
	target = stage.king.global_position-Vector2(0,25)
	center = Vector2((stage.KING_WEST+stage.room_right)*0.5,300)
	throwing_player = thrower
	overlay = Soap.new()
	stage.get_node("HUD").add_child(overlay)
	stage.jar.get_node("Indicator").hide()
	stage.jar.get_node("Captured").hide()
	stage.get_node("HUD/TeamHUD").hide()
	stage.get_node("HUD/JourneyTitle").hide()
	stage.workshop_radio.hide()
	for teammate in stage.players:
		teammate.attack_time = 0
		teammate.specials.cancel()
		teammate.velocity = Vector2.ZERO
		teammate.jump_height = 0
		teammate.jump_speed = 0
		teammate.push_velocity = Vector2.ZERO
		teammate.dash = 0
		teammate.modulate.a = 1
		teammate.get_node("Visual").position = Vector2.ZERO
		teammate.get_node("Visual").rotation = 0
		teammate.sprite.play("idle")
	var poses: SpriteFrames = thrower.sprite.sprite_frames.duplicate()
	poses.add_animation("antidote_throw")
	poses.set_animation_loop("antidote_throw",false)
	poses.set_animation_speed("antidote_throw",8)
	for i in 4:
		var texture := AtlasTexture.new()
		texture.atlas = THROWS[thrower.player_id]
		texture.region = Rect2(i*32,0,32,32)
		poses.add_frame("antidote_throw",texture)
	thrower.sprite.sprite_frames = poses
	thrower.sprite.flip_h = target.x < start.x
	thrower.sprite.play("antidote_throw")
func advance(dt: float) -> void:
	if complete: return
	age += dt
	if age < COVERED_AT:
		var flight := smoothstep(0.0,FILL_START,age)
		bottle.global_position = start.lerp(target,flight)-Vector2(0,sin(flight*PI)*58)
		bottle.rotation = flight*TAU
		if age >= FILL_START: bottle.hide()
	if age >= FILL_START and throwing_player.sprite.animation == &"antidote_throw": throwing_player.sprite.play("idle")
	var cover := smoothstep(FILL_START,COVERED_AT,age)
	if age >= REVEAL_AT: cover = 1.0-smoothstep(REVEAL_AT,WALK_AT,age)
	overlay.update_cover(cover,age)
	if age >= COVERED_AT and not cleaned: _clean_sewer()
	var camera: Camera2D = stage.get_node("Camera2D")
	if age >= COVERED_AT:
		camera.position = Vector2(center.x,180)
		camera.zoom = Vector2.ONE*0.96
		camera.offset = Vector2.ZERO
	if age >= WALK_AT and age < FIVE_AT:
		var approach := smoothstep(WALK_AT,FIVE_AT,age)
		for i in stage.players.size():
			var p = stage.players[i]
			var side := -1.0 if i == 0 else 1.0
			p.position = center+Vector2(side*lerpf(100,27,approach),0)
			p.facing = -side
			p.sprite.flip_h = side > 0
			p.sprite.play("run" if approach < 0.98 else "idle")
			p.update_sprite_alignment()
	if age >= FIVE_AT:
		if high_five == null:
			for i in stage.players.size():
				stage.players[i].position = center+Vector2(-27 if i==0 else 27,0)
				stage.players[i].hide()
			high_five = HighFive.new()
			stage.get_node("Actors").add_child(high_five)
			high_five.position = center
		high_five.advance(maxf(0,age-FIVE_AT)-high_five.age)
	if age >= VICTORY_AT:
		complete = true
		overlay.hide()
		stage.get_node("HUD/TravelTime").text = ""
		stage.get_node("HUD/Finale").show()
		stage.get_node("HUD/Finale/Panel/Content/Menu").grab_focus()
		stage.victory = true
		stage.beat = stage.Beat.END
		GameAudio.music("ending",false)
func _clean_sewer() -> void:
	cleaned = true
	clean_material = ShaderMaterial.new()
	clean_material.shader = CLEAN
	clean_material.set_shader_parameter("cleaned",1.0)
	_recolor(stage.get_node("Scenery"))
	_recolor(stage.get_node("Drains"))
	stage.king.hide()
	stage.jar.hide()
	stage.captive.hide()
	for effect in stage.get_node("ImpactEffects").get_children(): effect.queue_free()
	for projectile in stage.get_node("Projectiles").get_children(): projectile.queue_free()
	var rescued: Sprite2D = stage.get_node("Actors/Tiburcio")
	rescued.position = center+Vector2(104,-4)
	rescued.show()
	for vent in stage.vents:
		vent.state = vent.State.REST
		vent.age = 0
		vent.queue_redraw()
	for i in stage.players.size():
		var p = stage.players[i]
		p.down = false
		p.hp = maxi(1,p.hp)
		p.stun = 0
		p.position = center+Vector2(-100 if i==0 else 100,0)
		p.sprite.play("idle")
		p.update_sprite_alignment()
	GameAudio.effect("bubble",center)
func _recolor(node: Node) -> void:
	if node is CanvasItem: node.material = clean_material
	for child in node.get_children(): _recolor(child)

