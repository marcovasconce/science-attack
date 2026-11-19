extends SceneTree
## Import-only cell normalization; preserve the generated transparency and pixel art.
const SOURCE := "res://art/source/lower_lab/king_captive_animated_v3.png"
const OUTPUT := "res://assets/enemies/king_captive_animated_v3.png"
const SIZE := 112
func _initialize() -> void:
	var source := Image.load_from_file(SOURCE)
	if source == null:
		push_error("Missing generated composite sheet")
		quit(1)
		return
	var cell := Vector2i(source.get_width() / 3, source.get_height() / 2)
	var result := Image.create(SIZE * 3, SIZE * 2, false, Image.FORMAT_RGBA8)
	var anchor := Vector2.ZERO
	for i in 6:
		var origin := Vector2i(i % 3, i / 3)
		var frame := source.get_region(Rect2i(origin * cell, cell))
		# Register each drawing on its crown, avoiding horizontal animation jitter.
		var crown := Rect2i()
		for y in int(cell.y * 0.25):
			for x in cell.x:
				var pixel := frame.get_pixel(x,y)
				if pixel.a > 0.8 and pixel.r > 0.5 and pixel.g > 0.35 and pixel.r > pixel.g * 1.05 and pixel.g > pixel.b * 1.4:
					var point := Rect2i(x,y,1,1)
					crown = crown.merge(point) if crown.has_area() else point
		var current_anchor := Vector2(crown.get_center().x, crown.position.y)
		if i == 0: anchor = current_anchor
		var offset := Vector2i(((anchor - current_anchor) * Vector2(SIZE,SIZE) / Vector2(cell)).round())
		frame.resize(SIZE, SIZE, Image.INTERPOLATE_NEAREST)
		var aligned := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
		aligned.blit_rect(frame, Rect2i(0,0,SIZE,SIZE), offset)
		result.blit_rect(aligned, Rect2i(0, 0, SIZE, SIZE), origin * SIZE)
	result.save_png(OUTPUT)
	print("Imported six composite animation frames: ", result.get_size())
	quit()

