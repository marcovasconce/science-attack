extends "res://scripts/micro_arena.gd"
const Party = preload("res://scripts/party_transfer.gd")
var entry_key := "shaft_entry_state"
var transitioning := true
var floor_min := 202.0
var room_left := 64.0
var room_right := 576.0
func _ready() -> void:
	players = [$Actors/MaxAvatar,$Actors/AmandaAvatar]
	players[1].sprite.sprite_frames = preload("res://assets/avatars/Pink_Monster.tres")
	world_limit = 640
	open_limit = room_right
	camera_max_x = 320
	built = true
	Party.restore(self,entry_key)
	for player in players: player.set_collision_mask_value(5,true)
	bind_team_hud()
	var progress: ProgressBar = $HUD/TravelProgress
	var track := MenuSkin.panel(Color(0.13, 0.20, 0.37))
	var fill := MenuSkin.panel(Color(0.70, 1.0, 1.0))
	for style in [track, fill]:
		for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			style.set_texture_margin(side, 2.0)
			style.set_content_margin(side, 0.0)
	progress.add_theme_stylebox_override("background", track)
	progress.add_theme_stylebox_override("fill", fill)
	controls_locked = true
func _on_hud_layout_changed(two_players: bool) -> void:
	$HUD/TeamHUD/Partner.position = Vector2(12,75)
	$HUD/TeamHUD/Primary/HitCombo.position = Vector2(0,132) if two_players else Vector2(130,104)
	$HUD/TeamHUD/Partner/HitCombo.position = Vector2(130,67)
func _process(dt: float) -> void:
	if GameInput.retry_requested(self):
		restart_with_current_team()
		return
	if not transitioning and GameInput.help_requested():
		$HUD/ControlsPanel.visible = not $HUD/ControlsPanel.visible
		controls_locked = $HUD/ControlsPanel.visible
	if not transitioning and not controls_locked and Input.is_action_just_pressed("join"):
		players[1].ai_controlled = not players[1].ai_controlled
	if players[0].down and players[1].down:
		controls_locked = true
	GameInput.defeat_hint(status, "F2  TENTAR DE NOVO", players[0].down and players[1].down)
	if controls_locked: return
	for player in players:
		if player.down: continue
		player.position.x = clampf(player.position.x,room_left,room_right)
		player.position.y = clampf(player.position.y,floor_min,326)
	update_camera_shake(dt)
func germ_defeated(_at: Vector2) -> void: defeated += 1
func transfer_to(path: String) -> void:
	get_tree().set_meta("party_state",Party.capture(self))
	var error := get_tree().change_scene_to_file(path)
	if error != OK:
		$Transition/Black/Message.text = "NÃO FOI POSSÍVEL CARREGAR\nF2  TENTAR DE NOVO"
		push_error("Could not open journey scene: "+path)
