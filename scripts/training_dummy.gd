extends StaticBody2D
const ART = preload("res://assets/animations/training_robot.tres")
const FONT = preload("res://assets/fonts/PressStart2P-Regular.ttf")
var dead := false
var total_damage := 0
var hits := 0
var last_damage := 0
var flash := 0.0
var hit_direction := 1.0
var visual: Sprite2D
var nearby: Node
@onready var arena = get_tree().get_first_node_in_group("arena")

func _ready() -> void:
	# Render the extracted robot on the same coarse pixel grid as the players.
	var viewport := SubViewport.new()
	viewport.size = Vector2i(44,48)
	viewport.transparent_bg = true
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	add_child(viewport)
	var image := Sprite2D.new()
	image.texture = ART
	image.position = Vector2(22,24)
	image.scale = Vector2(36.0/ART.get_width(),42.0/ART.get_height())
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; void fragment(){if(COLOR.a<0.8){discard;} COLOR.a=1.0;}"
	var material := ShaderMaterial.new()
	material.shader = shader
	image.material = material
	viewport.add_child(image)
	visual = Sprite2D.new()
	visual.texture = viewport.get_texture()
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual.scale = Vector2(2,2)
	visual.position = Vector2(0,-42)
	add_child(visual)

func _process(dt: float) -> void:
	if arena.controls_locked: return
	flash = maxf(0,flash-dt)
	visual.position.x = roundf(sin(flash*60)*flash*18)*hit_direction
	visual.modulate = Color(1.5,1.5,1.2) if flash > 0.16 else Color.WHITE
	nearby = null
	if arena.encounter.unlocked:
		for actor in arena.players:
			if not actor.ai_controlled and not actor.down and not actor.specials.active and actor.global_position.distance_to(global_position) < 82:
				nearby = actor
				break
	queue_redraw()

func take_hit(amount: int, direction: float) -> void:
	if amount <= 0 or not arena.encounter.unlocked: return
	total_damage += amount
	last_damage = amount
	hits += 1
	flash = 0.25
	hit_direction = direction
	queue_redraw()

func prepare_training(actor) -> void:
	if actor.specials.active: return
	actor.energy = 50.0 if actor.energy >= 100.0 else 100.0
	total_damage = 0
	hits = 0
	last_damage = 0
	queue_redraw()

func _draw() -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(-32,0),Vector2(-22,-5),Vector2(23,-5),Vector2(32,0),Vector2(22,6),Vector2(-22,6)]),Color(0.01,0.02,0.03,0.6))
	draw_string(FONT,Vector2(-24,-94),"TREINO",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("f9d771"))
	if hits > 0:
		draw_string(FONT,Vector2(-36,-106),"DANO %04d" % total_damage,HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color.WHITE)
	if nearby != null:
		var key := "E" if nearby.player_id == 0 else "U"
		var text := "%s: CARGA %d%%" % [key,50 if nearby.energy >= 100 else 100]
		draw_rect(Rect2(-64,12,128,16),Color("102346"))
		draw_string(FONT,Vector2(-58,24),text,HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("b2edff"))
