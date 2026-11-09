extends StaticBody2D
var hp := 32
var broken := false
var collected := false
var age := 0.0
var fragments: Array[Sprite2D] = []
@onready var route = get_parent()
@onready var arena = get_parent().get_parent()
@export var supply_index := 0

func take_hit(damage: int, direction: float, _player) -> void:
	if broken or damage <= 0: return
	hp = maxi(0,hp-damage)
	arena.spawn_impact(0,global_position+Vector2(0,-20),direction)
	if hp > 0: return
	broken = true
	set_deferred("collision_layer",0)
	$Collision.set_deferred("disabled",true)
	$Box.hide()
	$Cross.hide()
	$Contents.show()
	for i in 4:
		var piece := Sprite2D.new()
		piece.texture = $Box.texture
		piece.region_enabled = true
		piece.region_rect = Rect2((i%2)*35,int(i/2)*35,35,35)
		piece.scale = Vector2.ONE*0.65
		add_child(piece)
		fragments.append(piece)
	_update_art()

func _process(dt: float) -> void:
	if not broken or collected or arena.controls_locked: return
	age += dt
	_update_art()
	if age < 0.8: return
	for player in arena.players:
		if not route._can_act(player,global_position+Vector2(30,0),28): continue
		collected = true
		route.supplies[supply_index] = true
		$Contents.hide()
		for actor in arena.players:
			if not actor.down: actor.hp = mini(actor.max_hp,actor.hp+30)
			actor.healing_flasks += 1
		route._pickup_feedback("+ Vida e 1 frasco",global_position+Vector2(30,0))
		break

func _update_art() -> void:
	var t := clampf(age/0.8,0,1)
	$Contents.position = Vector2(30*t,-14-64*sin(t*PI))
	for i in fragments.size():
		var travel := clampf(age/0.55,0,1)
		fragments[i].position = Vector2((-1 if i%2==0 else 1)*(10+22*travel),-6-int(i/2)*6-30*sin(travel*PI))
		fragments[i].rotation = (-1 if i%2==0 else 1)*travel*(0.6+i*0.2)

func restore_collected() -> void:
	if not broken: take_hit(32,1,null)
	collected = true
	age = 1
	_update_art()
	$Contents.hide()
