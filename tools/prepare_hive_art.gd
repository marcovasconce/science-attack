extends SceneTree
## Register generated art to game-sized textures without repainting the artwork.
func _initialize() -> void:
	var menu := Image.load_from_file("res://art/source/hive/menu.png")
	menu.resize(1280,720,Image.INTERPOLATE_NEAREST)
	menu.save_png("res://assets/menu/laboratory.png")
	var source := Image.load_from_file("res://art/source/hive/wall.png")
	# Remove the white export margins; split at the floor line to preserve lane depth.
	var top := 0
	while source.get_pixel(0,top).r > 0.8: top += 1
	var bottom := source.get_height()-1
	while source.get_pixel(0,bottom).r > 0.8: bottom -= 1
	var floor_y := int(source.get_height()*0.625)
	var wall := source.get_region(Rect2i(0,top,source.get_width(),floor_y-top))
	wall.resize(960,238,Image.INTERPOLATE_NEAREST)
	wall.save_png("res://assets/environment/hive/wall.png")
	var floor_art := source.get_region(Rect2i(0,floor_y,source.get_width(),bottom-floor_y+1))
	floor_art.resize(960,122,Image.INTERPOLATE_NEAREST)
	floor_art.save_png("res://assets/environment/hive/floor.png")
	source = Image.load_from_file("res://art/source/hive/pit.png")
	var pit := source.get_region(source.get_used_rect())
	pit.resize(88,148,Image.INTERPOLATE_NEAREST)
	pit.save_png("res://assets/environment/hive/pit.png")
	source = Image.load_from_file("res://art/source/hive/geyser.png")
	var atlas := Image.create(384,320,false,Image.FORMAT_RGBA8)
	var cell := Vector2i(source.get_width()/4,source.get_height()/2)
	for i in 8:
		var part := source.get_region(Rect2i(Vector2i(i%4,i/4)*cell,cell))
		var used := part.get_used_rect()
		var cropped := part.get_region(used)
		# A common source-to-output scale keeps the crater identical across all poses.
		var ratio := 80.0/(source.get_width()*0.18)
		cropped.resize(roundi(used.size.x*ratio),roundi(used.size.y*ratio),Image.INTERPOLATE_NEAREST)
		atlas.blit_rect(cropped,Rect2i(Vector2i.ZERO,cropped.get_size()),Vector2i(i%4*96+(96-cropped.get_width())/2,i/4*160+156-cropped.get_height()))
	atlas.save_png("res://assets/environment/hive/geyser.png")
	print("PASS: hive and menu art registered")
	quit()
