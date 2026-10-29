extends Node2D
## Reuse only the existing rail surfaces in front of actors. The spaces between
## posts remain transparent, so legs stay visible through the railings.

const LAB := preload("res://assets/backgrounds/laboratory.png")
const VIEW := Vector2(640, 360)


func _draw() -> void:
	# Middle-floor handrail and posts.
	_patch(Rect2(0, 209, 498, 3))
	_patch(Rect2(0, 228, 498, 2))
	for x in [5, 46, 86, 126, 165, 205, 245, 285, 325, 365, 404, 444, 484]:
		_patch(Rect2(x, 212, 2, 16))
	# Diagonal stair rail, sampled directly from the unchanged background.
	var points := PackedVector2Array([Vector2(348, 308), Vector2(497, 229),
		Vector2(500, 231), Vector2(351, 311)])
	var uvs := PackedVector2Array()
	for point in points:
		uvs.append(point / VIEW)
	draw_polygon(points, PackedColorArray([Color.WHITE]), uvs, LAB)
	for post in [Rect2(349, 311, 2, 18), Rect2(380, 294, 2, 20), Rect2(410, 278, 2, 21),
		Rect2(440, 262, 2, 22), Rect2(469, 247, 2, 22), Rect2(497, 232, 2, 22)]:
		_patch(post)


func _patch(rect: Rect2) -> void:
	var image_scale := Vector2(LAB.get_size()) / VIEW
	draw_texture_rect_region(LAB, rect, Rect2(rect.position * image_scale, rect.size * image_scale))
