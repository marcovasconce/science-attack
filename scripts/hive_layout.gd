extends RefCounted
## Expand walkable distances while keeping the current sprites at their native scale.
const OLD := [0.0,300.0,787.0,1125.0,1216.0,1630.0,1716.0,2150.0,2290.0,2740.0,2910.0,3352.0,3472.0,3998.0,4044.0]
const NEW := [0.0,360.0,1180.0,1840.0,2040.0,2740.0,2910.0,3630.0,3910.0,4650.0,4930.0,5650.0,5900.0,6740.0,6786.0]
static func x(value: float) -> float:
	for i in range(1,OLD.size()):
		if value <= OLD[i]: return lerpf(NEW[i-1],NEW[i],inverse_lerp(OLD[i-1],OLD[i],value))
	return NEW[-1]+value-OLD[-1]
static func point(at: Vector2) -> Vector2:
	return Vector2(x(at.x),at.y)
static func expand(stage: Node2D) -> void:
	var scenery := stage.get_node("Scenery")
	for node in scenery.get_children():
		if node.name == "Floor" or String(node.name).begins_with("Curb"): continue
		if node.name == "WorkshopBrackets":
			node.position.x = x(575)-575
		elif node is Node2D:
			node.position.x = x(node.position.x)
	for path in ["BubblePuzzle","Arsenal","Actors/King"]:
		var node = stage.get_node(path)
		node.position.x = x(node.position.x)
	for vent in stage.get_node("Drains").get_children(): vent.position.x = x(vent.position.x)
	for path in ["Galerias","Runoff"]:
		var strip: Sprite2D = scenery.get_node(path)
		strip.region_rect.size.x = (6786+32)/strip.scale.x
	var floor_node := scenery.get_node("Floor")
	var columns := ceili(6786.0/64)
	for i in columns:
		if not floor_node.has_node("Stone%d_0" % i):
			for row in 3:
				var tile = floor_node.get_node("Stone0_%d" % row).duplicate()
				tile.name = "Stone%d_%d" % [i,row]
				tile.position.x = 32+i*64
				floor_node.add_child(tile)
			var ledge = floor_node.get_node("Ledge0").duplicate()
			ledge.name = "Ledge%d" % i
			ledge.position.x = 32+i*64
			floor_node.add_child(ledge)
		floor_node.get_node("Ledge%d" % i).position.y = 184
		var back_row = floor_node.get_node("Stone%d_0" % i).duplicate()
		back_row.name = "WiderFloor%d" % i
		back_row.position.y = 187
		floor_node.add_child(back_row)
		var foreground = back_row.duplicate()
		foreground.name = "Foreground%d" % i
		foreground.position.y = 443
		floor_node.add_child(foreground)
		if not scenery.has_node("Curb%d" % i):
			var curb = scenery.get_node("Curb0").duplicate()
			curb.name = "Curb%d" % i
			curb.position.x = i*64
			scenery.add_child(curb)
