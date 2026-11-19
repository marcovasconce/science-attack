extends RefCounted
## Reuse the detailed laboratory atlas from phase one, with no stretched smooth art.
const ATLAS = preload("res://assets/environment/machines/lab_atlas.png")
const CONTROLS = preload("res://assets/environment/machines/lab_controls.png")
static func frame(column: int, row: int = 0) -> AtlasTexture:
	var result := AtlasTexture.new()
	result.atlas = ATLAS
	result.region = Rect2(column*320,row*320,320,320)
	result.filter_clip = true
	return result
static func skin(sprite: Sprite2D, texture: Texture2D, size: Vector2) -> void:
	sprite.texture = texture
	sprite.scale = size/texture.get_size()
	sprite.rotation = 0
	sprite.modulate = Color.WHITE
	sprite.self_modulate = Color.WHITE
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
static func apply(stage: Node2D) -> void:
	var puzzle := stage.get_node("BubblePuzzle")
	for name in ["LauncherStand","LowSupport","HighSupport"]: puzzle.get_node(name).hide()
	skin(puzzle.get_node("Launcher"),frame(3),Vector2(98,116))
	puzzle.get_node("Launcher").position = Vector2(-170,-75)
	skin(puzzle.get_node("LauncherFoot"),frame(0),Vector2(86,48))
	puzzle.get_node("LauncherFoot").position = Vector2(-170,0)
	skin(puzzle.get_node("Receiver"),frame(2),Vector2(84,94))
	puzzle.get_node("Receiver").position = Vector2(140,-44)
	for spring in puzzle.springs:
		skin(spring.get_node("Body"),frame(0),Vector2(64,64))
		spring.get_node("Body").position.y = -2
		skin(spring.get_node("Deck"),frame(1),Vector2(46,18))
		# The trajectory markers and barrier bounds remain identical to the solved puzzle.
		for arrow in ["Arrow","BoostArrow"]:
			spring.get_node(arrow).position.x = -34
	skin(stage.get_node("Arsenal/Terminal"),frame(2,3),Vector2(92,78))
	stage.get_node("Arsenal/Terminal").position = Vector2(28,-48)
