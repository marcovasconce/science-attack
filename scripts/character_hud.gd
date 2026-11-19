@tool
extends Control
const MenuSkin = preload("res://scripts/menu_button.gd")
var bezel := MenuSkin.panel(Color(0.18, 0.24, 0.38))
## One reusable, screen-space panel. The compact version is the AI companion row.
@export var compact := false:
	set(value):
		compact = value
		if is_node_ready(): _layout()
@export var accent := Color("55cced"):
	set(value):
		accent = value
		queue_redraw()
var player: Node
var last_hp := -1
var damage_delay := 0.0
var heal_flash := 0.0
var last_combo := 0
var combo_pop := 0.0
var special_level := 0
var special_glow := 0.0

func _ready() -> void:
	_layout()

func bind(actor: Node) -> void:
	player = actor
	$Portrait.texture = actor.sprite.sprite_frames.get_frame_texture("idle", 0)
	accent = Color("c391f2") if actor.player_id == 1 else Color("55cced")
	last_hp = actor.hp
	special_level = int(actor.energy / 50.0)
	$DamageTrail.max_value = actor.max_hp
	$DamageTrail.value = actor.hp
	refresh(0.0)

func refresh(dt: float) -> void:
	if not is_instance_valid(player): return
	var hits: int = player.hit_combo
	if hits > last_combo: combo_pop = 0.16
	last_combo = hits
	combo_pop = maxf(0.0, combo_pop - dt)
	$HitCombo.visible = hits > 0 and not compact
	$HitCombo.text = "x%d" % hits
	$HitCombo.scale = Vector2.ONE * (1.0 + 0.12 * sin(combo_pop / 0.16 * PI))
	var hp: int = player.hp
	if hp < last_hp: damage_delay = 0.4
	if hp > last_hp:
		heal_flash = 0.45
		$DamageTrail.value = hp
	last_hp = hp
	damage_delay = maxf(0.0, damage_delay - dt)
	heal_flash = maxf(0.0, heal_flash - dt)
	if damage_delay <= 0.0:
		$DamageTrail.value = move_toward($DamageTrail.value, hp, 55.0 * dt)
	$Health.max_value = player.max_hp
	$DamageTrail.max_value = player.max_hp
	$Health.value = hp
	$Special.value = player.energy
	var level := int(player.energy / 50.0)
	if level > special_level: special_glow = 0.42
	special_level = level
	special_glow = maxf(0.0, special_glow - dt)
	$SpecialLabel.modulate = Color.WHITE.lerp(Color("ffe18c"), special_glow / 0.42)
	var character_name := "MAX" if player.player_id == 0 else "AMANDA"
	var player_id := "IA" if player.ai_controlled else "P%d" % (player.player_id + 1)
	$Name.text = "%s  %s" % [player_id, character_name] if player.arena.show_player_ids() else character_name
	$HealthValue.text = "CAÍDO" if player.down else "%d/%d" % [hp, player.max_hp]
	$HealthValue.modulate = Color("ff9f88") if player.down else Color.WHITE
	$Count.text = str(player.healing_flasks)
	$Count.modulate = Color("748392") if player.healing_flasks == 0 else Color("eaffb9")
	$Flask.modulate = Color("748392") if player.healing_flasks == 0 else Color.WHITE
	$HealKey.text = "AUTO" if player.ai_controlled else ("[R]" if player.player_id == 0 else "[O]")
	var special_key := "Q" if player.player_id == 0 else "I"
	var special_text := "100%" if level == 2 else ("50%" if level == 1 else "ESPEC.")
	$SpecialLabel.text = "%s %s" % [special_key, special_text]
	if not Engine.is_editor_hint():
		if player.ai_controlled:
			GameInput.clear_hint($HealKey)
			GameInput.clear_hint($SpecialLabel)
		else:
			GameInput.label_hint($HealKey, player.player_id, "heal", $HealKey.text)
			GameInput.label_hint($SpecialLabel, player.player_id, "special", $SpecialLabel.text, special_text)
	$SpecialDivider.color = Color("f9de7c") if player.energy >= 100 else Color("ddf7ff")
	$Portrait.modulate = Color("7b8391") if player.down else Color.WHITE
	queue_redraw()

func _place(path: String, rect: Rect2) -> void:
	var control: Control = get_node(path)
	control.position = rect.position
	control.size = rect.size

func _layout() -> void:
	size = Vector2(204, 36) if compact else Vector2(232, 62)
	_place("Portrait", Rect2(6, 5, 26, 26) if compact else Rect2(9, 9, 36, 36))
	_place("Name", Rect2(40, 3, 120, 8) if compact else Rect2(54, 6, 164, 10))
	$Name.add_theme_font_size_override("font_size", 8)
	var health_rect := Rect2(40, 14, 114, 7) if compact else Rect2(54, 20, 164, 9)
	_place("DamageTrail", health_rect)
	_place("Health", health_rect)
	_place("Special", Rect2(40, 25, 90, 5) if compact else Rect2(54, 34, 124, 7))
	_place("SpecialDivider",Rect2(84,24,2,7) if compact else Rect2(115,33,2,9))
	_place("Flask", Rect2(160, 8, 12, 18) if compact else Rect2(184, 31, 16, 24))
	_place("Count", Rect2(178, 12, 26, 12) if compact else Rect2(204, 35, 26, 14))
	$Count.add_theme_font_size_override("font_size", 8 if compact else 10)
	_place("HealthValue", Rect2(54, 47, 58, 12))
	_place("SpecialLabel", Rect2(114, 47, 68, 12))
	_place("HealKey", Rect2(202, 48, 28, 11))
	$HitCombo.pivot_offset = Vector2(102, 12)
	$HealthValue.visible = not compact
	$SpecialLabel.visible = not compact
	$HealKey.visible = not compact
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	var border := PackedVector2Array([Vector2(5, 0), Vector2(w - 2, 0), Vector2(w, 2), Vector2(w, h - 8), Vector2(w - 8, h), Vector2(0, h), Vector2(0, 5)])
	draw_style_box(bezel, Rect2(Vector2.ZERO, size))
	var line := border.duplicate()
	line.append(border[0])
	draw_polyline(line, Color("54667c"), 1.0)
	draw_rect(Rect2(5, 2, w - 10, 2), accent.darkened(0.35))
	draw_rect(Rect2(2, 6, 2, h - 12), accent)
	draw_line(Vector2(7, h - 3), Vector2(w - 11, h - 3), Color("263b51"))
	var portrait_rect := Rect2(5, 4, 28, 28) if compact else Rect2(7, 7, 40, 40)
	draw_rect(portrait_rect, accent.darkened(0.76))
	draw_rect(portrait_rect, accent.darkened(0.15), false, 1.0)
	if heal_flash > 0.0:
		draw_polyline(line, Color(0.57, 1.0, 0.3, heal_flash / 0.45), 2.0)
