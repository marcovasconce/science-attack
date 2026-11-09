extends SceneTree
const Pose = preload("res://scripts/pixel_equipment_pose.gd")
const FONT = preload("res://assets/fonts/PressStart2P-Regular.ttf")
var poses: Array[Node2D] = []
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size = Vector2i(960,540)
	root.content_scale_size = Vector2i(960,540)
	var background := ColorRect.new()
	background.color = Color("14273b")
	background.size = Vector2(960,540)
	root.add_child(background)
	label("SPRITES ORIGINAIS + EQUIPAMENTOS",Vector2(28,22),16)
	var animations := ["idle","build","brush_attack","brush_rise","brush_slam","bubbles_attack"]
	var labels := ["ORIGINAL","MONTAGEM","LATERAL","ASCENDENTE","FORTE","BOLHAS"]
	for row in 2:
		var sprites: SpriteFrames = load("res://assets/avatars/%s.tres" % ("Owlet_Monster" if row == 0 else "Pink_Monster"))
		for col in 6:
			var pose := Pose.new()
			pose.frames = sprites
			pose.animation = animations[col]
			pose.amanda = row == 1
			pose.origin = Vector2.ZERO
			pose.position = Vector2(70+col*156,225+row*250)
			pose.scale = Vector2(2,2)
			pose.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			root.add_child(pose)
			poses.append(pose)
			label(labels[col],Vector2(22+col*156,244+row*250),8)
	label("MAX",Vector2(28,72),12)
	label("AMANDA",Vector2(28,315),12)
	DirAccess.make_dir_recursive_absolute("res://.godot/pixel_gallery_frames")
	for frame in 40:
		for pose in poses:
			pose.frame = (frame/2)%pose.frames.get_frame_count(pose.animation)
			pose.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		var rendered := root.get_texture().get_image()
		rendered.save_png("res://.godot/pixel_gallery_frames/%03d.png" % frame)
		if frame == 8: rendered.save_png("res://art/previews/pixel_sprite_gallery.png")
	print("Captured original silhouettes, assembly and three distinct brush motions side by side.")
	quit()
func label(text: String, at: Vector2, size: int) -> void:
	var node := Label.new()
	node.text = text
	node.position = at
	node.add_theme_font_override("font",FONT)
	node.add_theme_font_size_override("font_size",size)
	root.add_child(node)
