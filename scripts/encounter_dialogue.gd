extends "res://scripts/tutorial_box.gd"
signal closed
var active := false
var interact_key := "E"
var speaker_player := 0
func _ready() -> void:
	super._ready()
	hide()
func _layout() -> void:
	super._layout()
	if not is_node_ready(): return
	$Message.size.y = size.y - 55
	$RadioPortrait.position.y = size.y * 0.5
func open_line(speaker: String, words: String, player_id: int) -> void:
	active = true
	speaker_player = player_id
	interact_key = "E" if player_id == 0 else "U"
	$Speaker.text = speaker
	$Message.text = words
	previous_text = words
	reveal = 0
	$Message.visible_characters = 0
	show()
	_update_hint()
func _process(dt: float) -> void:
	if not active: return
	reveal += dt * 38.0
	$Message.visible_characters = mini(int(reveal), previous_text.length())
	_update_hint()
func advance() -> void:
	if not active: return
	if $Message.visible_characters < previous_text.length():
		reveal = previous_text.length()
		$Message.visible_characters = previous_text.length()
		_update_hint()
	else:
		active = false
		hide()
		closed.emit()
func _update_hint() -> void:
	var label := "CONTINUAR" if $Message.visible_characters >= previous_text.length() else "MOSTRAR FALA"
	GameInput.label_hint($Key, speaker_player, "interact", interact_key + "  " + label, label)
