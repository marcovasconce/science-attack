extends SceneTree
## Register generated frames at one scale and a shared floor baseline; preserve alpha.
func bounds(image: Image) -> Rect2i:
	var result := Rect2i()
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x,y).a < 0.5: continue
			var pixel := Rect2i(x,y,1,1)
			result = result.merge(pixel) if result.has_area() else pixel
	return result

func _initialize() -> void:
	var source := Image.load_from_file("res://art/source/lower_lab/shield_germ_v2.png")
	var cell := source.get_size()/4
	var frames: Array[Image] = []
	var widest := 0
	for i in 16:
		var frame := source.get_region(Rect2i(Vector2i(i%4,i/4)*cell,cell))
		# Ignore near-invisible generated fringes when locating the feet, not when blitting.
		var rect := bounds(frame)
		frames.append(frame.get_region(rect))
		widest = maxi(widest,rect.size.x)
	var ratio := 104.0/widest
	var atlas := Image.create(448,448,false,Image.FORMAT_RGBA8)
	for i in 16:
		var size := Vector2i(Vector2(frames[i].get_size())*ratio)
		frames[i].resize(size.x,size.y,Image.INTERPOLATE_NEAREST)
		atlas.blit_rect(frames[i],Rect2i(Vector2i.ZERO,size),Vector2i(i%4,i/4)*112+Vector2i((112-size.x)/2,108-size.y))
	atlas.save_png("res://assets/enemies/shield_germ_v2.png")
	print("PASS: 16 shield poses registered with transparent alpha: ",atlas.get_size())
	quit()
