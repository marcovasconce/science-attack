extends SceneTree
## Import-only normalization: preserve generated alpha; sample on the game's grid.
func _initialize() -> void:
	var king := Image.load_from_file("res://art/source/lower_lab/bacteria_king.png")
	var crop := king.get_region(king.get_used_rect())
	var king_height := roundi(88.0 * crop.get_height() / crop.get_width())
	crop.resize(88, king_height, Image.INTERPOLATE_NEAREST)
	crop.save_png("res://assets/enemies/bacteria_king.png")
	var flies := Image.load_from_file("res://art/source/lower_lab/flying_bacteria.png")
	var cell_width: int = flies.get_width() / 4
	var bounds := flies.get_used_rect()
	var sheet := Image.create(4 * 48, 40, false, Image.FORMAT_RGBA8)
	for i in 4:
		var frame := flies.get_region(Rect2i(i * cell_width, bounds.position.y, cell_width, bounds.size.y))
		frame.resize(48, roundi(48.0 * bounds.size.y / cell_width), Image.INTERPOLATE_NEAREST)
		sheet.blit_rect(frame, Rect2i(Vector2i.ZERO, frame.get_size()), Vector2i(i * 48, (40 - frame.get_height()) / 2))
	sheet.save_png("res://assets/enemies/flying_bacteria.png")
	var slime := Image.load_from_file("res://art/source/lower_lab/elevator_slime.png")
	var slime_crop := slime.get_region(slime.get_used_rect())
	slime_crop.resize(142, 108, Image.INTERPOLATE_NEAREST)
	slime_crop.save_png("res://assets/environment/elevator_slime.png")
	print("Imported king ", crop.get_size(), ", flyer sheet ", sheet.get_size(), " and slime ", slime_crop.get_size())
	quit()
