extends SceneTree
## Atlas preparation only: register cells, crop transparent margins, nearest resize.
const SOURCE := "res://art/source/lower_lab/"
func bounds(image: Image) -> Rect2i:
	var rect := Rect2i()
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x,y).a < 0.5: continue
			var point := Rect2i(x,y,1,1)
			rect = rect.merge(point) if rect.has_area() else point
	return rect

func strip(name: String, output: String, size: Vector2i) -> void:
	var source := Image.load_from_file(SOURCE+name+".png")
	var cell := Vector2i(source.get_width()/4,source.get_height())
	var frames: Array[Image] = []
	var common := Rect2i()
	for i in 4:
		var frame := source.get_region(Rect2i(Vector2i(i*cell.x,0),cell))
		frames.append(frame)
		var rect := bounds(frame)
		common = common.merge(rect) if common.has_area() else rect
	var result := Image.create(size.x*4,size.y,false,Image.FORMAT_RGBA8)
	for i in 4:
		var frame := frames[i].get_region(common)
		frame.resize(size.x,size.y,Image.INTERPOLATE_NEAREST)
		result.blit_rect(frame,Rect2i(Vector2i.ZERO,size),Vector2i(i*size.x,0))
	result.save_png(output)
	print(name,": ",result.get_size())

func _initialize() -> void:
	strip("yellow_flying_bacteria","res://assets/enemies/yellow_flying_bacteria.png",Vector2i(56,44))
	strip("slime_ball","res://assets/enemies/slime_ball.png",Vector2i(24,28))
	var door := Image.load_from_file(SOURCE+"door_side.png")
	door = door.get_region(bounds(door))
	door.resize(20,160,Image.INTERPOLATE_NEAREST)
	door.save_png("res://assets/environment/lower_lab/door_side.png")
	var source := Image.load_from_file(SOURCE+"fire_animated.png")
	var cell := Vector2i(source.get_width()/6,source.get_height()/2)
	var result := Image.create(72*6,64*2,false,Image.FORMAT_RGBA8)
	for i in 12:
		var grid := Vector2i(i%6,i/6)
		var frame := source.get_region(Rect2i(grid*cell,cell))
		var rect := bounds(frame)
		var crop := frame.get_region(Rect2i(0,maxi(0,rect.end.y-220),cell.x,220))
		crop.resize(72,64,Image.INTERPOLATE_NEAREST)
		result.blit_rect(crop,Rect2i(0,0,72,64),grid*Vector2i(72,64))
	result.save_png("res://assets/environment/lower_lab/fire_animated.png")
	print("fire: ",result.get_size(),"; door: ",door.get_size())
	quit()
