extends Node2D
## Deterministic staging after Amanda's last line. All time comes from the scene
## so pause, replay, and visual capture include walking, glass, and shrinking.

signal completed

const TUBE_POSES := preload("res://assets/characters/tube_poses.png")
const AMANDA_ARRIVAL := 2.75
const MAX_WAIT := 3.0
const MAX_TRAVEL := 3.4
const MAX_ARRIVAL := MAX_WAIT + MAX_TRAVEL
const ENTRY_START := MAX_ARRIVAL + 0.35
const ENTRY_DURATION := 0.8
const POWER_START := ENTRY_START + ENTRY_DURATION + 0.25
const CHARGE_DURATION := 1.8
const SHRINK_START := POWER_START + CHARGE_DURATION
const SHRINK_DURATION := 3.0
const SHRINK_END := SHRINK_START + SHRINK_DURATION
const END_TIME := SHRINK_END + 0.9
const GLASS := [Rect2(337, 143, 38, 55), Rect2(393, 143, 36, 55)]
const AMANDA_ROUTE := [Vector2(284, 340), Vector2(350, 334),
	Vector2(501, 266), Vector2(559, 230), Vector2(434, 227)]
const MAX_ROUTE := [Vector2(232, 337), Vector2(350, 334),
	Vector2(501, 266), Vector2(559, 230), Vector2(356, 227)]

var active := false
var is_complete := false
var elapsed := 0.0
var shrink_factor := 1.0
var entry_progress := 0.0
var power := 0.0
var max_actor: Node2D
var amanda_actor: Node2D
var tube_bodies: Array[Sprite2D] = []
var body_scales: Array[float] = []
var front_glass: Node2D
var glow: Node2D


func configure(maximum: Node2D, amanda: Node2D) -> void:
	max_actor = maximum
	amanda_actor = amanda
	var image := TUBE_POSES.get_image()
	var cell := Vector2i(image.get_width() / 2, image.get_height())
	glow = Node2D.new()
	glow.name = "GreenPulse"
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = additive
	add_child(glow)
	glow.draw.connect(_draw_glow)
	for index in range(2):
		var origin := Vector2i(index * cell.x, 0)
		var bounds := image.get_region(Rect2i(origin, cell)).get_used_rect()
		assert(bounds.has_area(), "A tube pose is missing from the atlas.")
		var texture := AtlasTexture.new()
		texture.atlas = TUBE_POSES
		texture.region = Rect2(origin + bounds.position, bounds.size)
		texture.filter_clip = true
		var body := Sprite2D.new()
		body.name = "DrMaxInside" if index == 0 else "DrAmandaInside"
		body.texture = texture
		body.centered = false
		body.offset = Vector2(-bounds.size.x * 0.5, -bounds.size.y)
		body.position = Vector2(GLASS[index].get_center().x, GLASS[index].end.y - 1)
		body.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(body)
		tube_bodies.append(body)
		body_scales.append(minf(49.0 / bounds.size.y, 28.0 / bounds.size.x))
	front_glass = Node2D.new()
	front_glass.name = "GlassInFrontOfScientists"
	add_child(front_glass)
	front_glass.draw.connect(_draw_glass)
	reset()


func begin() -> void:
	active = true
	is_complete = false
	visible = true
	sample(0.0)


func reset() -> void:
	active = false
	is_complete = false
	visible = false
	elapsed = 0.0
	entry_progress = 0.0
	shrink_factor = 1.0
	power = 0.0
	for actor in [max_actor, amanda_actor]:
		actor.scale = Vector2.ONE
		actor.modulate = Color.WHITE
	for index in range(tube_bodies.size()):
		tube_bodies[index].visible = false
		tube_bodies[index].scale = Vector2.ONE * body_scales[index]
		tube_bodies[index].modulate = Color.WHITE
	_refresh_effects()


func sample(time: float) -> void:
	if not active:
		return
	elapsed = maxf(0.0, time)
	_stage_route(amanda_actor, AMANDA_ROUTE, 0.0, AMANDA_ARRIVAL)
	_stage_route(max_actor, MAX_ROUTE, MAX_WAIT, MAX_TRAVEL)
	entry_progress = smoothstep(ENTRY_START, ENTRY_START + ENTRY_DURATION, elapsed)
	# The last step goes away from the player into the chambers. Crossfading the
	# side-view pose to the frontal pose makes the depth change readable.
	for index in range(2):
		var actor: Node2D = max_actor if index == 0 else amanda_actor
		var body := tube_bodies[index]
		if entry_progress > 0.0:
			var doorstep: Vector2 = MAX_ROUTE[-1] if index == 0 else AMANDA_ROUTE[-1]
			actor.position = doorstep.lerp(body.position + Vector2(0, 7), entry_progress)
			actor.modulate.a = 1.0 - smoothstep(0.0, 0.7, entry_progress)
		actor.visible = entry_progress < 0.7
		body.visible = entry_progress > 0.0 and elapsed < SHRINK_END
		body.modulate = Color(0.72, 1.0, 0.82, smoothstep(0.12, 0.92, entry_progress))
	# Both bodies physically scale down together, with their soles anchored.
	var reduction := clampf((elapsed - SHRINK_START) / SHRINK_DURATION, 0.0, 1.0)
	shrink_factor = pow(1.0 - reduction, 2.1)
	for index in range(2):
		tube_bodies[index].scale = Vector2.ONE * body_scales[index] * maxf(shrink_factor, 0.0001)
	var activation := smoothstep(POWER_START, POWER_START + 0.5, elapsed)
	var pulse := 0.5 + 0.5 * sin((elapsed - POWER_START) * TAU / 1.05 - PI * 0.5)
	var settle := 1.0 - smoothstep(SHRINK_END, END_TIME, elapsed)
	power = activation * (0.32 + pulse * 0.68) * settle
	_refresh_effects()
	if elapsed >= END_TIME and not is_complete:
		is_complete = true
		completed.emit()


func _stage_route(actor: Node2D, route: Array, delay: float, duration: float) -> void:
	var travel := clampf((elapsed - delay) / duration, 0.0, 1.0)
	var length := 0.0
	for index in range(1, route.size()):
		length += (route[index] as Vector2).distance_to(route[index - 1])
	var remaining := travel * length
	var look_left := false
	actor.position = route[0]
	for index in range(1, route.size()):
		var start: Vector2 = route[index - 1]
		var end: Vector2 = route[index]
		var segment_length := start.distance_to(end)
		if remaining <= segment_length or index == route.size() - 1:
			actor.position = start.lerp(end, clampf(remaining / segment_length, 0.0, 1.0))
			look_left = end.x < start.x
			break
		remaining -= segment_length
	var moving := elapsed >= delay and elapsed < delay + duration
	actor.visible = true
	actor.modulate = Color.WHITE
	# The rear walkway is farther from the camera than the foreground workbench.
	var depth := clampf((337.0 - actor.position.y) / 110.0, 0.0, 1.0)
	actor.scale = Vector2.ONE * lerpf(1.0, 0.73, depth)
	actor.show_pose(&"run" if moving else &"idle",
		maxf(0.0, elapsed - delay - (0.0 if moving else duration)), look_left)


func _refresh_effects() -> void:
	queue_redraw()
	glow.queue_redraw()
	front_glass.queue_redraw()


func _draw() -> void:
	if entry_progress <= 0.0:
		return
	for rect in GLASS:
		draw_rect(rect, Color(0.015, 0.14, 0.07, 0.18 * entry_progress))


func _draw_glow() -> void:
	if power <= 0.0:
		return
	for rect in GLASS:
		for layer in range(6):
			glow.draw_rect(rect.grow(2.0 + layer * 2.0), Color(0.04, 0.9, 0.30, power * 0.035))
		glow.draw_rect(rect, Color(0.1, 1.0, 0.45, power * 0.24))
		glow.draw_rect(Rect2(rect.position.x - 4, rect.end.y + 1, rect.size.x + 8, 3),
			Color(0.14, 1.0, 0.48, power * 0.8))


func _draw_glass() -> void:
	if entry_progress <= 0.0:
		return
	for index in range(2):
		var rect: Rect2 = GLASS[index]
		front_glass.draw_rect(rect, Color(0.18, 0.94, 0.47, entry_progress * (0.10 + power * 0.13)))
		front_glass.draw_rect(rect, Color(0.42, 1.0, 0.7, 0.25 + power * 0.65), false, 1.0)
		front_glass.draw_rect(Rect2(rect.position + Vector2(2, 1), Vector2(2, rect.size.y - 2)),
			Color(0.69, 1.0, 0.83, 0.38))
		front_glass.draw_rect(Rect2(rect.end.x - 4, rect.position.y + 2, 1, rect.size.y - 4),
			Color(0.65, 1.0, 0.8, 0.24))
		if elapsed < POWER_START or elapsed >= END_TIME:
			continue
		var scan_y := rect.position.y + fmod((elapsed - POWER_START) * 31.0, rect.size.y)
		front_glass.draw_rect(Rect2(rect.position.x + 1, floorf(scan_y), rect.size.x - 2, 2),
			Color(0.65, 1.0, 0.74, power * 0.6))
		for spark in range(7):
			var x := rect.position.x + 4 + fmod(spark * 7.0 + index * 3.0, rect.size.x - 8)
			var y := rect.end.y - fmod((elapsed - POWER_START) * (12.0 + spark * 2) + spark * 9, rect.size.y)
			front_glass.draw_rect(Rect2(floorf(x), floorf(y), 1, 2), Color(0.7, 1.0, 0.7, power))
		front_glass.draw_set_transform(Vector2(rect.get_center().x, rect.end.y - 1), 0, Vector2(1, 0.23))
		front_glass.draw_arc(Vector2.ZERO, rect.size.x * 0.45, 0, TAU, 24,
			Color(0.6, 1.0, 0.6, power * 0.9), 1.0)
		front_glass.draw_set_transform(Vector2.ZERO)
