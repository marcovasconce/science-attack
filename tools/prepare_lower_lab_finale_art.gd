extends SceneTree
## Technical atlas registration only; source artwork and alpha are preserved.
const SOURCE := "res://art/source/lower_lab/"
func bounds(image: Image) -> Rect2i:
	var rect := Rect2i()
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x,y).a < 0.5: continue
			var point := Rect2i(x,y,1,1)
			rect = rect.merge(point) if rect.has_area() else point
	return rect

func single(name: String, size: Vector2i) -> void:
	var source := Image.load_from_file(SOURCE+name+".png")
	print(name," corner alpha: ",source.get_pixel(0,0).a)
	var crop := source.get_region(bounds(source))
	crop.resize(size.x,size.y,Image.INTERPOLATE_NEAREST)
	crop.save_png("res://assets/environment/lower_lab/"+name+".png")

func _initialize() -> void:
	single("soap_pickup",Vector2i(40,34))
	single("tnt_crate",Vector2i(36,42))
	single("slime_block",Vector2i(180,92))
	var source := Image.load_from_file(SOURCE+"shield_germ.png")
	print("boss corner alpha: ",source.get_pixel(0,0).a)
	var cell := Vector2i(source.get_width()/3,source.get_height()/2)
	var frames: Array[Image] = []
	var rects: Array[Rect2i] = []
	var extent := Vector2i.ZERO
	for i in 6:
		var frame := source.get_region(Rect2i(Vector2i(i%3,i/3)*cell,cell))
		var rect := bounds(frame)
		print("boss frame ",i," bounds ",rect)
		frames.append(frame)
		rects.append(rect)
		extent = extent.max(rect.size)
	var ratio := 104.0/maxi(extent.x,extent.y)
	var result := Image.create(336,224,false,Image.FORMAT_RGBA8)
	for i in 6:
		var crop := frames[i].get_region(rects[i])
		var size := Vector2i(Vector2(crop.get_size())*ratio)
		crop.resize(size.x,size.y,Image.INTERPOLATE_NEAREST)
		var at := Vector2i(i%3,i/3)*112+Vector2i((112-size.x)/2,108-size.y)
		result.blit_rect(crop,Rect2i(Vector2i.ZERO,size),at)
	result.save_png("res://assets/enemies/shield_germ.png")
	quit()
