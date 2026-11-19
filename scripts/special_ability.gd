extends Node2D
## One energy transaction per activation; every timer uses the paused player clock.
const WaterEffect = preload("res://scripts/pixel_water_effect.gd")
const BEAM_WINDUP := 0.25
const BEAM_SECONDS := 3.0
const BEAM_INTERVAL := 0.15
const BEAM_DAMAGE := 30
const SOLAR_PULSES := [Vector2(0.42, 0), Vector2(0.66, 112), Vector2(0.90, 224)]
const SOLAR_DAMAGE := [135, 150, 185]
const NOVA_PULSES := [Vector2(0.30, 0), Vector2(0.50, -34), Vector2(0.70, 34)]
var player: CharacterBody2D
var active := false
var kind := ""
var level := 0
var elapsed := 0.0
var duration := 0.0
var next_pulse := 0.0
var stage := 0
var cast_facing := 1.0
var beam_length := 0.0
var water_viewport: SubViewport
var water_canvas: Node2D
var water_display: Sprite2D

func setup(actor: CharacterBody2D) -> void:
	player = actor
	z_index = 3
	water_viewport = SubViewport.new()
	water_viewport.size = Vector2i(384,128)
	water_viewport.transparent_bg = true
	water_viewport.disable_3d = true
	water_viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	add_child(water_viewport)
	water_canvas = WaterEffect.new()
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; render_mode unshaded; void fragment(){if(COLOR.a<0.9){discard;} COLOR.a=1.0;}"
	var material := ShaderMaterial.new()
	material.shader = shader
	water_canvas.material = material
	water_viewport.add_child(water_canvas)
	water_display = Sprite2D.new()
	water_display.centered = false
	water_display.texture = water_viewport.get_texture()
	water_display.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(water_display)
	_sync_water()

func try_activate() -> bool:
	if active or player.arena.controls_locked or player.down or player.stun > 0: return false
	if player.arena.is_assembling(player) or player.equipped_weapon == "none" or player.energy < 50: return false
	level = 2 if player.energy >= 100.0 else 1
	player.energy = maxf(0,player.energy-(100 if level == 2 else 50))
	kind = player.equipped_weapon+str(level)
	if level == 2 and player.weapon_upgraded:
		kind = "solar" if player.equipped_weapon == "brush" else "nova"
	GameAudio.effect("solar" if player.equipped_weapon == "brush" else "nova", player.global_position)
	duration = {"brush1":6.0,"brush2":1.4,"bubbles1":1.1,"bubbles2":BEAM_WINDUP+BEAM_SECONDS,"solar":1.4,"nova":1.08}[kind]
	elapsed = 0
	next_pulse = BEAM_WINDUP+0.1 if kind == "bubbles2" else 0.0
	stage = 0
	cast_facing = player.facing
	beam_length = 0
	active = true
	if level == 2 and player.arena.encounter.has_method("record_ultimate"):
		player.arena.encounter.record_ultimate(player)
	player.attack_time = 0
	player.buffered = false
	player.chain_grace = 0
	player.dash = 0
	player.combo_idle_time = 0
	queue_redraw()
	_sync_water()
	return true

func tick(dt: float) -> void:
	if not active or player.arena.controls_locked: return
	if player.down:
		cancel()
		return
	var end := minf(duration,elapsed+dt)
	if kind == "solar" or kind == "nova":
		_tick_upgraded_ultimate(end)
	elif kind == "brush1":
		while next_pulse < end and next_pulse < duration:
			player.arena.special_area(player,player.global_position,86,38,10)
			next_pulse += 0.4
	elif kind == "brush2":
		if stage == 0 and end >= 0.5:
			player.arena.special_area(player,player.global_position,150,55,100)
			player.arena.start_camera_shake(6,0.22)
			stage = 1
		if stage == 1 and end >= 0.85:
			player.arena.special_area(player,player.global_position,220,70,65)
			player.arena.start_camera_shake(3,0.12)
			stage = 2
	elif kind == "bubbles1" and stage == 0 and end >= 0.35:
		player.arena.spawn_special_bubble(player,0,true)
		stage = 1
	elif kind == "bubbles2":
		beam_length = player.arena.water_beam_length(player,cast_facing)
		while next_pulse <= end+0.000001 and next_pulse < duration-0.000001:
			player.arena.water_beam_damage(player,cast_facing,beam_length,BEAM_DAMAGE)
			next_pulse += BEAM_INTERVAL
	elapsed = end
	player.combo_idle_time = 0
	if elapsed+0.000001 >= duration:
		elapsed = duration
		active = false
	queue_redraw()
	_sync_water()

func _tick_upgraded_ultimate(end: float) -> void:
	var pulses := SOLAR_PULSES if kind == "solar" else NOVA_PULSES
	while stage < pulses.size() and end >= pulses[stage].x:
		var pulse: Vector2 = pulses[stage]
		if kind == "solar":
			var center := player.global_position + Vector2(cast_facing * pulse.y, 0)
			player.arena.special_area(player, center, 86.0, 57.0, SOLAR_DAMAGE[stage], 28.0)
			if player.arena.has_method("ultimate_camera"): player.arena.ultimate_camera(kind)
			else: player.arena.start_camera_shake(3 + stage, 0.17)
		else:
			var bubble = player.arena.spawn_bubble(player, true, true)
			bubble.lane_target = clampf(bubble.global_position.y + pulse.y, player.arena.floor_min + 3.0, 323.0)
			bubble.special_shot = true
			bubble.giant = true
			bubble.radius = 29.0 if stage == 0 else 21.0
			bubble.damage = 190 if stage == 0 else 115
			bubble.blast_radius = 135.0 if stage == 0 else 100.0
			bubble.speed = 320.0 if stage == 0 else 380.0
			bubble.max_distance = 550.0
			if stage == 0 and player.arena.has_method("ultimate_camera"): player.arena.ultimate_camera(kind)
			else: player.arena.start_camera_shake(2.6, 0.13)
		stage += 1

func cancel() -> void:
	active = false
	queue_redraw()
	_sync_water()

func locks_aim() -> bool:
	return active and kind in ["bubbles2", "solar", "nova"]

func _sync_water() -> void:
	if water_display == null: return
	var show_water := active and kind in ["brush2","bubbles2","solar","nova"]
	water_display.visible = show_water
	water_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if show_water else SubViewport.UPDATE_DISABLED
	if not show_water: return
	water_canvas.mode = kind
	water_canvas.use_arcade_effects = player.arena.use_arcade_effects
	water_canvas.time = elapsed
	water_canvas.beam_length = beam_length
	if kind == "nova":
		water_canvas.pulses = NOVA_PULSES
	elif kind == "solar":
		water_canvas.pulses = SOLAR_PULSES
	if kind in ["bubbles2", "nova"]:
		water_display.scale = Vector2(cast_facing*2,2)
		water_display.position = Vector2(-32*cast_facing,-128-player.jump_height)
	elif kind == "solar":
		water_display.scale = Vector2(cast_facing * 2, 2)
		water_display.position = Vector2(-320 * cast_facing, -192)
	else:
		water_display.scale = Vector2(2,2)
		water_display.position = Vector2(-320,-192)
	water_canvas.queue_redraw()

func animation_name() -> String:
	return {"brush1":"brush_spin","brush2":"brush_ultimate","bubbles1":"bubbles_special","bubbles2":"bubbles_ultimate","solar":"brush_ultimate","nova":"bubbles_ultimate"}.get(kind,"")

func animation_frame(count: int) -> int:
	if kind == "brush1": return int(elapsed*20)%count
	if kind == "bubbles2": return int(elapsed*18)%count
	if kind == "nova": return mini(count - 1, stage * 2 + int(elapsed * 16) % 2)
	if kind == "solar": return mini(count - 1, int(elapsed / 0.84 * count))
	return mini(count-1,int(elapsed/maxf(duration,0.01)*count))

