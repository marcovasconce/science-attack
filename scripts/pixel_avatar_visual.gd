extends Node2D
## Composite animated equipment at the same 32px density as the source avatars.
## The small viewport also keeps rotated equipment on this exact pixel grid.
const Pose = preload("res://scripts/pixel_equipment_pose.gd")
var canvas: SubViewport
var pose: Node2D
var display: Sprite2D
var source: AnimatedSprite2D
var player: CharacterBody2D
var last_key := ""

func setup(owner_player: CharacterBody2D, original: AnimatedSprite2D) -> void:
	player = owner_player
	source = original
	canvas = SubViewport.new()
	canvas.name = "PixelCanvas"
	canvas.size = Vector2i(128,96)
	canvas.transparent_bg = true
	canvas.disable_3d = true
	canvas.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	canvas.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	add_child(canvas)
	pose = Pose.new()
	pose.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
render_mode unshaded;

varying vec4 tint;

void vertex() {
	tint = COLOR;
}

void fragment() {
	if (COLOR.a < 0.8) { discard; }
	if (abs(tint.b - 0.51) < 0.005 && tint.r > 0.99 && tint.g > 0.99) {
		float light = dot(texture(TEXTURE, UV).rgb, vec3(0.25, 0.55, 0.2));
		vec3 ochre = mix(vec3(0.17, 0.06, 0.08), vec3(1.0, 0.58, 0.15), smoothstep(0.08, 0.60, light));
		COLOR.rgb = mix(ochre, vec3(1.0, 0.96, 0.72), smoothstep(0.59, 0.86, light));
	}
	COLOR.a = 1.0;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	pose.material = material
	canvas.add_child(pose)
	display = Sprite2D.new()
	display.texture = canvas.get_texture()
	display.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	display.position = Vector2(32,-32)
	display.scale = Vector2(2,2)
	add_child(display)
	sync()

func _process(_delta: float) -> void: sync()

func sync() -> void:
	if source == null: return
	var name := String(source.animation)
	var active := name.begins_with("brush_") or name.begins_with("bubbles_")
	visible = active
	source.visible = not active
	canvas.render_target_update_mode = SubViewport.UPDATE_ALWAYS if active else SubViewport.UPDATE_DISABLED
	if not active: return
	scale.x = -1.0 if source.flip_h else 1.0
	var key := "%d/%s/%d/%d/%s" % [source.sprite_frames.get_instance_id(),name,source.frame,player.player_id,player.weapon_upgraded]
	if key == last_key: return
	last_key = key
	pose.frames = source.sprite_frames
	pose.animation = source.animation
	pose.frame = source.frame
	pose.amanda = player.player_id == 1
	pose.upgraded = player.weapon_upgraded
	pose.queue_redraw()
