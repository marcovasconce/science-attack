extends Node2D
const Effect = preload("res://scripts/lab_pixel_effect.gd")
const Puddle = preload("res://scripts/toxic_puddle.gd")
const Door = preload("res://scripts/lab_security_door.gd")
const Prompt = preload("res://scripts/interaction_prompt.gd")
const TERMINAL_AT := Vector2(2440,247)
var puddles: Array[Node2D] = []
var lockers: Array[Sprite2D] = []
var door: Node2D
var prompt: Control

func _ready() -> void:
	z_index = -4
	for x in [1140,1540,2110,2910]:
		prop("locker",Vector2(x,185),Vector2(104,136))
	for x in [1330,1840,2250]:
		prop("machines",Vector2(x,184),Vector2(138,117))
		var fire := Effect.new()
		# Anchor the flames on the torn casing of the shorter computer on the right.
		fire.position = Vector2(x+34,114)
		add_child(fire)
	for x in [1040,1700,2350,2820]:
		prop("sign",Vector2(x,70),Vector2(27,29))
	for at in [Vector2(1150,285),Vector2(1450,220),Vector2(1745,308),Vector2(2010,249),Vector2(2250,310)]:
		var puddle := Puddle.new()
		puddle.name = "ToxicPuddle%d" % puddles.size()
		puddle.position = at
		puddle.z_index = 1
		add_child(puddle)
		var sprite := Sprite2D.new()
		sprite.texture = load("res://assets/environment/lower_lab/puddle.png")
		sprite.scale = Vector2(124,47)/sprite.texture.get_size()
		sprite.position.y = -5
		sprite.show_behind_parent = true
		puddle.add_child(sprite)
		puddle.move_child(sprite,0)
		var steam := Effect.new()
		steam.effect = "steam"
		puddle.add_child(steam)
		puddles.append(puddle)
	prop("terminal",TERMINAL_AT,Vector2(88,104))
	prompt = Prompt.new()
	prompt.action_text = "ACESSAR"
	prompt.position = TERMINAL_AT + Vector2(-49,-134)
	prompt.hide()
	add_child(prompt)
	door = Door.new()
	door.name = "SecurityDoor"
	door.position = Vector2(2640,344)
	add_child(door)

func prop(kind: String, at: Vector2, size: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = load("res://assets/environment/lower_lab/%s.png" % kind)
	sprite.scale = size / sprite.texture.get_size()
	sprite.position = at - Vector2(0,size.y/2)
	add_child(sprite)
	if kind == "locker": lockers.append(sprite)
	return sprite

func can_use(player) -> bool:
	return not player.down and not player.ai_controlled and player.position.distance_to(TERMINAL_AT + Vector2(0,14)) < 65
