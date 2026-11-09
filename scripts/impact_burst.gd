extends Node2D
## A short world-space animation, independent of the struck object's lifetime.
enum Kind { CRATE, ENEMY }
const SHEETS := [preload("res://assets/effects/crate_impact.png"), preload("res://assets/effects/enemy_impact.png")]
const FRAME_COUNT := 6
@export var kind: Kind = Kind.CRATE
var facing := 1.0
var age := 0.0
var lifetime := 0.32
var frame_index := 0
var frames: Array[AtlasTexture] = []
@onready var arena = get_tree().get_first_node_in_group("arena")

func _ready() -> void:
	var sheet: Texture2D = SHEETS[kind]
	var cell := sheet.get_size() / Vector2(3, 2)
	for index in FRAME_COUNT:
		var frame := AtlasTexture.new()
		frame.atlas = sheet
		frame.region = Rect2(Vector2(index % 3, index / 3) * cell, cell)
		frames.append(frame)
	var diameter := 72.0 if kind == Kind.CRATE else 64.0
	$Sprite.scale = Vector2.ONE * diameter / cell.y
	$Sprite.flip_h = facing < 0
	lifetime = 0.32 if kind == Kind.CRATE else 0.28
	sample(0.0)

func _process(dt: float) -> void:
	if is_instance_valid(arena) and arena.controls_locked: return
	age += dt
	if age >= lifetime:
		queue_free()
		return
	sample(age)

func sample(time: float) -> void:
	frame_index = clampi(int(time / lifetime * FRAME_COUNT), 0, FRAME_COUNT - 1)
	$Sprite.texture = frames[frame_index]
	$Sprite.modulate.a = 1.0 - smoothstep(lifetime * 0.84, lifetime, time)
