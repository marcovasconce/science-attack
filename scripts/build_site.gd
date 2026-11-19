extends Node2D
const PART_SHEET = preload("res://assets/pickups/construction_bolts.png")
const DROP_DURATION := 0.6
const STAGING_POINT := Vector2(553, 288)
const TARGETS := [Vector2(590,207), Vector2(592,299), Vector2(628,253), Vector2(654,207), Vector2(666,299), Vector2(690,253), Vector2(722,207), Vector2(746,299)]
const SECTION_UNITS := [3, 6, 8]
var snapped_units := 0
var bursts: Array[Dictionary] = []
var section_ages := [10.0, 10.0, 10.0]
var deck_origins: Array[Vector2] = []
var camera_blend := 0.0
var completion_hold := 0.0
var effects: Node2D
@onready var arena = get_parent()

func _ready() -> void:
	for i in 3:
		deck_origins.append(arena.get_node("Bridge/Deck%d" % i).position)
	effects = Node2D.new()
	effects.z_index = 30
	add_child(effects)
	effects.draw.connect(_draw_effects)

func _process(dt: float) -> void:
	if arena.controls_locked: return
	completion_hold = maxf(0.0, completion_hold - dt)
	for i in 3: section_ages[i] += dt
	for burst in bursts: burst["age"] += dt
	bursts = bursts.filter(func(burst): return burst["age"] < 0.65)
	for i in arena.part_drop_ages.size():
		arena.part_drop_ages[i] = minf(DROP_DURATION, arena.part_drop_ages[i] + dt)
	sample(arena.build_progress / arena.BUILD_DURATION)
	effects.queue_redraw()

func update_camera(dt: float, center: Vector2) -> void:
	if arena.controls_locked: return
	var active: bool = (is_instance_valid(arena.bridge_builder) and arena.is_assembling(arena.bridge_builder)) or completion_hold > 0
	camera_blend = move_toward(camera_blend, 1.0 if active else 0.0, dt * (2.8 if active else 1.8))
	var weight := smoothstep(0.0, 1.0, camera_blend)
	var camera: Camera2D = arena.get_node("Camera2D")
	var progress: float = arena.build_progress / arena.BUILD_DURATION
	# Frame both builders and the far end; pan gently as the bridge grows.
	var target := Vector2(604 + progress * 18, 204)
	var normal := Vector2(clampf(center.x, 320, arena.camera_max_x), 180)
	camera.position = normal.lerp(target, weight)
	camera.zoom = Vector2.ONE * lerpf(1.0, 1.12, weight)

func sample(progress: float) -> void:
	progress = clampf(progress, 0.0, 1.0)
	var completed_units := int(progress * 8 + 0.001)
	if completed_units < snapped_units:
		bursts.clear()
		section_ages = [10.0, 10.0, 10.0]
		completion_hold = 0.0
	for unit in range(snapped_units, completed_units):
		bursts.append({"at": TARGETS[unit], "age": 0.0, "big": unit == 7})
		for section in 3:
			if unit + 1 == SECTION_UNITS[section]: section_ages[section] = 0.0
		arena.start_camera_shake(1.6 if unit < 7 else 3.0, 0.10 if unit < 7 else 0.22)
		if unit == 7: completion_hold = 0.55
	snapped_units = completed_units
	var bridge = arena.get_node("Bridge")
	bridge.visible = progress > 0
	for i in range(3):
		var deck: Sprite2D = bridge.get_node("Deck%d" % i)
		deck.visible = completed_units >= SECTION_UNITS[i]
		var age: float = section_ages[i]
		deck.position = deck_origins[i] + Vector2(0, -sin(age * 23.0) * 5.0 * exp(-age * 10.0))
		deck.modulate = Color.WHITE.lerp(Color(1.5, 1.65, 1.45), maxf(0.0, 1.0 - age / 0.22))
		$Blueprint.get_child(i).visible = arena.tutorial.step >= 6 and arena.bridge_has_parts() and not arena.built and completed_units < SECTION_UNITS[i]
	# The eight authored nodes supply the bridge; later drops remain on the floor.
	while $Pieces.get_child_count() < arena.part_origins.size():
		var extra := Sprite2D.new()
		extra.name = "Piece%d" % $Pieces.get_child_count()
		extra.texture = PART_SHEET
		extra.hframes = 3
		extra.vframes = 2
		extra.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		$Pieces.add_child(extra)
	for i in $Pieces.get_child_count():
		var piece: Sprite2D = $Pieces.get_child(i)
		piece.visible = i < arena.part_origins.size()
		if not piece.visible: continue
		piece.frame = i % 6
		var start: Vector2 = arena.part_origins[i]
		var target: Vector2 = TARGETS[mini(i, 7)]
		var travel := clampf(progress * 8 - i, 0, 1) if i < 8 else 0.0
		var drop := clampf(arena.part_drop_ages[i] / DROP_DURATION, 0, 1)
		var reserved: bool = arena.bridge_parts_reserved and i < arena.BRIDGE_COST
		if reserved:
			start = STAGING_POINT + Vector2((i % 4) * 9, (i / 4) * 9)
		if not reserved and travel == 0 and drop < 1:
			piece.position = arena.part_drop_sources[i].lerp(start, drop) + Vector2(0, -sin(drop * PI) * 20)
			piece.rotation = (i % 3 - 1) * (1.0 - drop) * 0.9
		else:
			# Lift and turn first, hover above the socket, then snap straight down.
			var flight := smoothstep(0.0, 0.80, travel)
			var snap := smoothstep(0.80, 1.0, travel)
			piece.position = start.lerp(target + Vector2(0, -12), flight) + Vector2(0, -sin(flight * PI) * 42 + snap * 12)
			piece.rotation = sin(flight * PI) * (1.1 if i % 2 == 0 else -1.1)
		var cell_height: float = PART_SHEET.get_height() / 2.0
		piece.scale = Vector2.ONE * lerpf(28.0, 14.0, travel) / cell_height
		piece.z_as_relative = false
		piece.z_index = 6 if travel > 0 and travel < 1 else (-3 if travel >= 1 else 0)
	$Count.visible = arena.tutorial.step >= 4 and not arena.built
	$Count.text = "%d/8" % (arena.BRIDGE_COST if arena.bridge_parts_reserved else mini(arena.BRIDGE_COST, arena.pieces))
	effects.queue_redraw()

func _draw_effects() -> void:
	for burst in bursts:
		var age: float = burst["age"]
		var origin: Vector2 = burst["at"]
		var big: bool = burst["big"]
		var fade := maxf(0, 1.0 - age / 0.55)
		var radius := 4.0 + age * (65.0 if big else 40.0)
		effects.draw_arc(origin, radius, 0, TAU, 24, Color(0.55, 1.0, 0.86, fade * 0.7), 1.2, true)
		for spark in (14 if big else 8):
			var direction := Vector2.from_angle(spark * 2.39996)
			var at := origin + direction * age * (95.0 if big else 58.0) + Vector2(0, age * age * 65)
			var color := Color(1.0, 0.85, 0.36, fade) if spark % 2 == 0 else Color(0.65, 1.0, 0.95, fade)
			effects.draw_rect(Rect2(at - Vector2.ONE, Vector2.ONE * (3 if big else 2)), color)
		if age < 0.16:
			var strength := 1.0 - age / 0.16
			effects.draw_line(origin - Vector2(7,0), origin + Vector2(7,0), Color(1,1,0.8,strength), 2)
			effects.draw_line(origin - Vector2(0,7), origin + Vector2(0,7), Color(1,1,0.8,strength), 2)
