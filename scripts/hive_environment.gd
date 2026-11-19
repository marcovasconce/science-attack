extends Node2D
const BACKDROP = preload("res://assets/environment/hive/backdrop.png")
const PIT_ROCK = preload("res://assets/environment/hive/pit.png")
const LIVING = preload("res://assets/environment/hive/living_slime.gdshader")
const ART_REGION := Rect2(0, 54, 1672, 800)
const ART_SCALE := 0.45
var clock := 0.0
var organic: ShaderMaterial
@onready var arena = get_parent()
func _ready() -> void:
	arena = get_parent()
	var crop := AtlasTexture.new()
	crop.atlas = BACKDROP
	crop.region = ART_REGION
	crop.filter_clip = true
	organic = ShaderMaterial.new()
	organic.shader = LIVING
	organic.set_shader_parameter("pit_rock", PIT_ROCK)
	organic.set_shader_parameter("pit_centers", Vector4(arena.PITS[0], arena.PITS[1], arena.PITS[2], arena.PITS[3]))
	organic.set_shader_parameter("pit_half_width", arena.PIT_HALF)
	var tile_size := ART_REGION.size * ART_SCALE
	for i in ceili(arena.world_limit / tile_size.x):
		var tile := Sprite2D.new()
		tile.texture = crop
		tile.position = Vector2((i + 0.5) * tile_size.x, tile_size.y * 0.5)
		tile.scale = Vector2.ONE * ART_SCALE
		tile.flip_h = i % 2 == 1
		tile.material = organic
		add_child(tile)
	var drips := Node2D.new()
	drips.name = "FallingSlime"
	drips.z_index = 1
	add_child(drips)
	drips.draw.connect(_draw_drips.bind(drips))
func _process(dt: float) -> void:
	if arena.controls_locked: return
	clock += dt
	organic.set_shader_parameter("clock",clock)
	$FallingSlime.queue_redraw()
func _draw_drips(canvas: Node2D) -> void:
	for i in 40:
		var phase := fposmod(clock*0.27+i*0.317,1.0)
		var x := 50.0+i*83.0
		var start := 40.0+fposmod(i*37,95)
		var y := start+(239-start)*phase*phase
		canvas.draw_rect(Rect2(roundf(x),roundf(y),3,5+floorf(phase*4)),Color("7abf0d"))
		canvas.draw_rect(Rect2(roundf(x),roundf(y),1,4),Color("d1f647"))
		if phase > 0.92:
			var radius := (phase-0.92)*60
			canvas.draw_arc(Vector2(x,240),radius,0,PI,8,Color(0.52,0.9,0.12,(1-phase)*9),1,false)
