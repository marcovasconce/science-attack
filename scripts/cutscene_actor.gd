extends Node2D
## Eight-frame atlas: six running poses followed by two empty-handed idle poses.
## The sprite sheet stays intact; AtlasTexture regions are prepared in memory.

const GRID := Vector2i(4, 2)
const RUN_FPS := 11.0
const IDLE_FPS := 1.6
const BREATH_PERIOD := 3.8
const BREATH_AMOUNT := 0.003

var facing_left := false
var current_pose: StringName = &"idle"
var current_frame := 0
var frame_bounds: Array[Rect2i] = []
var reference_height := 1.0
var actor_height := 74.0
var source_idle_faces_left := false
var sprite: AnimatedSprite2D


func configure(sheet: Texture2D, height: float, idle_faces_left := false) -> void:
	actor_height = height
	source_idle_faces_left = idle_faces_left
	var source := sheet.get_image()
	var cell := Vector2i(source.get_width() / GRID.x, source.get_height() / GRID.y)
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	frames.add_animation(&"run")
	frames.add_animation(&"idle")
	frames.set_animation_speed(&"run", RUN_FPS)
	frames.set_animation_speed(&"idle", IDLE_FPS)
	for index in range(8):
		var origin := Vector2i(index % GRID.x, index / GRID.x) * cell
		var bounds := source.get_region(Rect2i(origin, cell)).get_used_rect()
		assert(bounds.has_area(), "Empty character frame %d" % index)
		frame_bounds.append(bounds)
		var texture := AtlasTexture.new()
		texture.atlas = sheet
		texture.region = Rect2(origin + bounds.position, bounds.size)
		texture.filter_clip = true
		frames.add_frame(&"run" if index < 6 else &"idle", texture)
	# Standing height is the shared scale reference, so running poses keep proportions.
	reference_height = float(maxi(frame_bounds[6].size.y, frame_bounds[7].size.y))
	sprite = $AnimatedSprite
	sprite.name = "AnimatedSprite"
	sprite.sprite_frames = frames
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE * actor_height / reference_height
	show_pose(&"idle", 0.0, false)


func show_pose(pose: StringName, pose_time: float, look_left: bool) -> void:
	current_pose = pose
	facing_left = look_left
	var count := 6 if pose == &"run" else 2
	var fps := RUN_FPS if pose == &"run" else IDLE_FPS
	# The generated idle drawings differ in silhouette. Keep a single drawing and
	# breathe continuously instead of swapping silhouettes every half second.
	current_frame = int(maxf(pose_time, 0.0) * fps) % count if pose == &"run" else 0
	sprite.animation = pose
	sprite.frame = current_frame
	var bounds := frame_bounds[current_frame + (0 if pose == &"run" else 6)]
	sprite.offset = Vector2(-bounds.size.x * 0.5, -bounds.size.y)
	var flip := look_left != (source_idle_faces_left and pose == &"idle")
	sprite.scale.x = (-1.0 if flip else 1.0) * actor_height / reference_height
	var breath := sin(maxf(pose_time, 0.0) * TAU / BREATH_PERIOD) * BREATH_AMOUNT if pose == &"idle" else 0.0
	# The bottom of the atlas is at local y=0: scaling keeps both feet planted.
	sprite.scale.y = actor_height / reference_height * (1.0 + breath)
	# A small lift on the passing frames gives the run a grounded, readable cadence.
	sprite.position.y = -1.0 if pose == &"run" and current_frame in [1, 4] else 0.0
	queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2(0, -0.5), 0.0, Vector2(1.0, 0.24))
	draw_circle(Vector2.ZERO, 12.0, Color(0.015, 0.025, 0.05, 0.32))
	draw_set_transform(Vector2.ZERO)
