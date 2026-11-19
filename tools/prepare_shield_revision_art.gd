extends SceneTree
const SOURCE := "res://art/source/lower_lab/"
func bounds(image: Image) -> Rect2i:
	var rect := Rect2i()
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x,y).a < 0.5: continue
			var pixel := Rect2i(x,y,1,1)
			rect = rect.merge(pixel) if rect.has_area() else pixel
	return rect

func effect(name: String, grid: Vector2i, size: Vector2i) -> void:
	var source := Image.load_from_file(SOURCE+name+".png")
	var cell := source.get_size()/grid
	var sheet := Image.create(size.x*grid.x,size.y*grid.y,false,Image.FORMAT_RGBA8)
	for i in grid.x*grid.y:
		var at := Vector2i(i%grid.x,i/grid.x)
		var frame := source.get_region(Rect2i(at*cell,cell))
		frame.resize(size.x,size.y,Image.INTERPOLATE_NEAREST)
		sheet.blit_rect(frame,Rect2i(Vector2i.ZERO,size),at*size)
	sheet.save_png("res://assets/effects/"+name+".png")
	print(name," ",sheet.get_size()," corner alpha ",sheet.get_pixel(0,0).a)

func _initialize() -> void:
	effect("tnt_explosion",Vector2i(4,2),Vector2i(64,64))
	effect("shield_block_impact",Vector2i(4,1),Vector2i(48,64))
	var source := Image.load_from_file(SOURCE+"shield_germ_idle.png")
	var cell := Vector2i(source.get_width()/4,source.get_height())
	var frames: Array[Image] = []
	var height := 0
	for i in 4:
		var frame := source.get_region(Rect2i(Vector2i(i*cell.x,0),cell))
		var crop := frame.get_region(bounds(frame))
		frames.append(crop)
		height = maxi(height,crop.get_height())
	var ratio := 78.0/height
	var result := Image.create(448,112,false,Image.FORMAT_RGBA8)
	for i in 4:
		var size := Vector2i(Vector2(frames[i].get_size())*ratio)
		frames[i].resize(size.x,size.y,Image.INTERPOLATE_NEAREST)
		result.blit_rect(frames[i],Rect2i(Vector2i.ZERO,size),Vector2i(i*112+(112-size.x)/2,108-size.y))
	result.save_png("res://assets/enemies/shield_germ_idle.png")
	print("idle ",result.get_size()," alpha ",result.get_pixel(0,0).a)
	quit()
