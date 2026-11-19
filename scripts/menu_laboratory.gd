extends Node2D

const GermVisual = preload("res://scripts/pixel_germ_visual.gd")
const Tube = preload("res://scenes/environment/test_tube.tscn")
const GERM_SETUP := [
	[Vector2(331, 308), "green", 0.75],
	[Vector2(594, 321), "red", 0.75],
	[Vector2(589, 210), "green", 0.5],
]

var germs: Array[Node2D] = []
var tubes: Array[Node2D] = []
var reactions: Dictionary = {}
var clock := 0.0
var departing := false
const AVATAR_FLOOR_Y := 299.0
@onready var avatars: Array[AnimatedSprite2D] = [$FirstAvatar, $Tiburcio, $SecondAvatar]

func _ready() -> void:
	for data in GERM_SETUP:
		var germ := GermVisual.new()
		germ.position = data[0]
		germ.scale = Vector2.ONE * data[2]
		add_child(germ)
		germ.setup(data[1], roundi(data[2] * 4))
		germs.append(germ)
	for i in 3:
		var tube := Tube.instantiate()
		tube.position = Vector2(408 + i * 35, 127)
		tube.tube_height = [57.0, 70.0, 47.0][i]
		tube.variant = "green" if i == 1 else "cyan"
		tube.phase_offset = i * 2.1
		tube.collision_layer = 0
		tube.collision_mask = 0
		add_child(tube)
		tube.get_node("Shadow").hide()
		tubes.append(tube)
	move_child($TubeRack, get_child_count() - 1)
	set_reduced(SceneFx.reduced_motion)

func set_reduced(reduced: bool) -> void:
	for avatar in avatars:
		if reduced: avatar.pause()
		else: avatar.play(&"idle")
	for tube in tubes: tube.set_process(not reduced)
	if reduced:
		for tween in reactions.values(): tween.kill()
		reactions.clear()
		for avatar in avatars: avatar.position.y = AVATAR_FLOOR_Y
		for tube in tubes: tube.modulate = Color.WHITE
		for i in germs.size():
			germs[i].position = GERM_SETUP[i][0]
			germs[i].rotation = 0
			germs[i].sync(i * 0.3, i % 2 == 1)
	set_process(not reduced)
	queue_redraw()

func _process(delta: float) -> void:
	clock += delta
	for i in germs.size():
		var germ := germs[i]
		var home: Vector2 = GERM_SETUP[i][0]
		var t := clock + i * 1.6
		var lift := 5.0 + sin(t * 2.3) * 4.0 if i < 2 else sin(t * 2.1) * 10.0
		germ.position = (home + Vector2(sin(t * 1.65) * (7 if i < 2 else 17), -lift)).round()
		germ.sync(t * 0.72, i % 2 == 1)
	queue_redraw()

func react_at(at: Vector2) -> bool:
	if SceneFx.reduced_motion or departing: return false
	for avatar in avatars:
		if Rect2(avatar.position + Vector2(-34, -74), Vector2(68, 75)).has_point(at):
			_jump(avatar)
			return true
	for tube in tubes:
		var height: float = tube.tube_height
		if Rect2(tube.position - Vector2(height * 0.21, height), Vector2(height * 0.42, height)).has_point(at):
			_stir(tube)
			return true
	for germ in germs:
		if Rect2(germ.position + Vector2(-28, -65), Vector2(56, 71)).has_point(at):
			if reactions.has(germ) and reactions[germ].is_running(): return true
			var tween := create_tween()
			reactions[germ] = tween
			tween.tween_property(germ, "rotation", -0.22, 0.11)
			tween.tween_property(germ, "rotation", 0.19, 0.15)
			tween.tween_property(germ, "rotation", 0.0, 0.15)
			return true
	return false

func _stir(tube: Node2D) -> void:
	if reactions.has(tube) and reactions[tube].is_running(): return
	var tween := create_tween()
	reactions[tube] = tween
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(tube, "modulate", Color(1.35, 1.35, 1.35), 0.11)
	tween.tween_property(tube, "modulate", Color.WHITE, 0.34)
	tube.liquid_time += 0.8

func _jump(avatar: AnimatedSprite2D) -> Tween:
	if reactions.has(avatar) and reactions[avatar].is_running(): return reactions[avatar]
	var base := avatar.position.y
	var tween := create_tween()
	reactions[avatar] = tween
	tween.tween_property(avatar, "position:y", base - 24.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(avatar, "position:y", base, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	return tween

func launch() -> void:
	if SceneFx.reduced_motion: return
	departing = true
	var hop: Tween
	for actor in avatars: hop = _jump(actor)
	await hop.finished

func _draw() -> void:
	for avatar in avatars:
		var foot := Vector2(avatar.position.x, AVATAR_FLOOR_Y)
		draw_set_transform(foot, 0.0, Vector2(1, 0.29))
		draw_circle(Vector2.ZERO, 26, Color(0.011, 0.025, 0.18, 0.38))
	draw_set_transform(Vector2.ZERO)
