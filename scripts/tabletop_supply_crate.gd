extends "res://scripts/cartoon_crate.gd"
## Reuse damage, salvage and physics with the machine's cartoon art family.
func _ready() -> void:
	super._ready()
	sprite_scale = Vector2.ONE*0.68
	sample_visual()

func sample_visual() -> void:
	$Sprite.frame = 0
	$Sprite.position = Vector2(0,-22)
	if broken:
		var progress := clampf(break_age/BREAK_DURATION,0,1)
		$Sprite.scale = sprite_scale*(1.0+progress*0.12)
		$Sprite.modulate.a = 1.0-progress
		$Shadow.hide()
		visible = progress < 1
	else:
		var recoil := sin(hit_age/0.18*PI)
		$Sprite.position.x = hit_direction*recoil*2
		$Sprite.scale = sprite_scale*(1.0+recoil*0.04)
		$Sprite.modulate = Color.WHITE if hp >= 32 else Color(0.85,0.91,0.96)
