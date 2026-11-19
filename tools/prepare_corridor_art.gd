extends SceneTree
## Technical atlas extraction only: trim transparent margins and downsample nearest.
const NAMES := ["locker","machines","puddle","sign","door","terminal"]
const SIZES := [Vector2i(78,102),Vector2i(108,92),Vector2i(124,47),Vector2i(28,30),Vector2i(112,160),Vector2i(66,78)]
func _initialize() -> void:
	var source := Image.load_from_file("res://art/source/lower_lab/damaged_corridor_atlas.png")
	if source == null:
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute("res://assets/environment/lower_lab")
	var cell := Vector2i(source.get_width()/3,source.get_height()/2)
	for i in 6:
		var frame := source.get_region(Rect2i(Vector2i(i%3,i/3)*cell,cell))
		# Ignore nearly invisible alpha noise when locating each sprite's bounds.
		var bounds := Rect2i()
		for y in cell.y:
			for x in cell.x:
				if frame.get_pixel(x,y).a < 0.5: continue
				var point := Rect2i(x,y,1,1)
				bounds = bounds.merge(point) if bounds.has_area() else point
		var trimmed := frame.get_region(bounds)
		trimmed.resize(SIZES[i].x,SIZES[i].y,Image.INTERPOLATE_NEAREST)
		trimmed.save_png("res://assets/environment/lower_lab/%s.png" % NAMES[i])
		print(NAMES[i]," ",bounds," -> ",SIZES[i])
	quit()
