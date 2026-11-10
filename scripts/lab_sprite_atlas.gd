extends RefCounted
## Shared atlas cells: no source textures are modified at runtime.
const SHEET = preload("res://assets/environment/machines/lab_atlas.png")
const CONTROLS = preload("res://assets/environment/machines/lab_controls.png")
static var cells: Dictionary = {}

static func control(column: int, row: int = 1) -> AtlasTexture:
	var key := Vector2i(column,row+10)
	if not cells.has(key):
		var texture := AtlasTexture.new()
		texture.atlas = CONTROLS
		texture.region = Rect2(column*CONTROLS.get_width()/4.0,row*CONTROLS.get_height()/2.0,CONTROLS.get_width()/4.0,CONTROLS.get_height()/2.0)
		cells[key] = texture
	return cells[key]

static func apply_control(sprite: Sprite2D, column: int, size: float) -> void:
	sprite.texture = control(column)
	sprite.region_enabled = false
	sprite.scale = Vector2.ONE*size/(CONTROLS.get_width()/4.0)
	sprite.modulate = Color.WHITE

static func cell(column: int, row: int) -> AtlasTexture:
	var key := Vector2i(column,row)
	if not cells.has(key):
		var texture := AtlasTexture.new()
		texture.atlas = SHEET
		var edge := SHEET.get_width()/4.0
		texture.region = Rect2(column*edge,row*edge,edge,edge)
		cells[key] = texture
	return cells[key]

static func apply(sprite: Sprite2D, column: int, row: int, size: float) -> void:
	sprite.texture = cell(column,row)
	sprite.region_enabled = false
	sprite.scale = Vector2.ONE*size/(SHEET.get_width()/4.0)
	sprite.modulate = Color.WHITE

static func gear(sprite: Sprite2D, angle: float, size: float) -> void:
	# Eight teeth repeat every quarter-turn of the four-frame animation.
	apply(sprite,posmod(int(floor(angle/(PI/16.0))),4),1,size)
	sprite.rotation = 0
