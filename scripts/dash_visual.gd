extends Node2D
## Short, faint silhouettes and pixel streaks follow the existing dodge clock.
const GHOST_LIFETIME := 0.11
var ghosts: Array[Dictionary] = []
var cadence := 0.0

func clear() -> void:
	ghosts.clear()
	cadence = 0
	queue_redraw()

func tick(dt: float, player: CharacterBody2D, moving: bool) -> void:
	for ghost in ghosts: ghost.age += dt
	ghosts = ghosts.filter(func(ghost): return ghost.age < GHOST_LIFETIME)
	cadence -= dt
	if moving and cadence <= 0:
		var equipped: bool = player.pixel_visual.visible
		var texture: Texture2D = player.pixel_visual.canvas.get_texture() if equipped else player.sprite.sprite_frames.get_frame_texture(player.sprite.animation,player.sprite.frame)
		ghosts.append({"age":0.0,"position":player.global_position+player.get_node("Visual").position,
			"facing":player.facing,"lean":player.get_node("Visual").rotation,"texture":texture,
			"rect":Rect2(-96,-128,256,192) if equipped else Rect2(-32,-62,64,64)})
		if ghosts.size() > 2: ghosts.pop_front()
		cadence = 0.045
	elif not moving: cadence = 0
	queue_redraw()

func _draw() -> void:
	for ghost in ghosts:
		var fade: float = 1.0-ghost.age/GHOST_LIFETIME
		var offset: Vector2 = (ghost.position-global_position).snapped(Vector2(2,2))
		draw_set_transform(offset,ghost.lean,Vector2(ghost.facing,1))
		draw_texture_rect(ghost.texture,ghost.rect,false,Color(0.65,0.88,1,fade*0.18))
		draw_set_transform(offset,0,Vector2(ghost.facing,1))
		draw_rect(Rect2(-24,-10,10,2),Color(0.72,0.91,1,fade*0.4))
		draw_rect(Rect2(-18,-4,6,2),Color(0.72,0.91,1,fade*0.3))
	draw_set_transform(Vector2.ZERO)
