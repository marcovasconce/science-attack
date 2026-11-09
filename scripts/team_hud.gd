extends Control
signal layout_changed(two_players: bool)
var players: Array = []
var two_players := false

func bind(actors: Array) -> void:
	players = actors
	$Primary.bind(players[0])
	$Partner.bind(players[1])
	_apply_mode()

func _process(dt: float) -> void:
	if players.size() != 2: return
	if two_players == players[1].ai_controlled: _apply_mode()
	$Primary.refresh(dt)
	$Partner.refresh(dt)

func _apply_mode() -> void:
	two_players = not players[1].ai_controlled
	$Partner.compact = not two_players
	$Partner.position = Vector2(254, 10) if two_players else Vector2(12, 75)
	$Primary/HitCombo.position = Vector2(130, 66) if two_players else Vector2(130, 104)
	$Partner/HitCombo.position = Vector2(130, 66)
	layout_changed.emit(two_players)
