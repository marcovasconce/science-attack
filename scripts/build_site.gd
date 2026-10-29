extends Node2D
@onready var arena=get_parent()
func _process(_dt: float) -> void:
	sample(arena.build_progress/arena.BUILD_DURATION)
func sample(progress: float) -> void:
	var completed_units=int(progress*8+0.001)
	var bridge=arena.get_node("Bridge")
	bridge.visible=progress>0
	for i in range(3):
		bridge.get_node("Deck%d"%i).visible=completed_units>=[3,6,8][i]
		$Blueprint.get_child(i).visible=not arena.built and completed_units<[3,6,8][i]
	for i in range(8):
		var piece: Sprite2D=$Pieces.get_child(i)
		piece.visible=i<arena.part_origins.size()
		if not piece.visible: continue
		var start: Vector2=arena.part_origins[i]
		var target=Vector2(580+(i%2)*45,196+floori(i/2.0)*30)
		var travel=clampf(progress*8-i,0,1)
		piece.position=start.lerp(target,travel)+Vector2(0,-sin(travel*PI)*50)
		piece.rotation=sin(travel*TAU)*0.35
		piece.scale=Vector2.ONE*lerpf(0.22,0.18,travel)
		piece.z_as_relative=false
		piece.z_index=6 if travel>0 and travel<1 else (-3 if travel>=1 else 0)
	$Count.visible=arena.tutorial.step>=4 and not arena.built
	$Count.text="%d / 8"%mini(8,arena.pieces)
