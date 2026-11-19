extends Control

const FONT = preload("res://assets/fonts/PressStart2P-Regular.ttf")
const ROWS := [
	["Mover", "move", "WASD", "Setas"], ["Pular", "jump", "Espaço", "K"],
	["Golpe", "attack", "F", "J"], ["Desviar", "dodge", "Shift", "L"],
	["Usar", "interact", "E", "U"], ["Curar", "heal", "R", "O"],
	["Especial", "special", "Q", "I"],
]
var show_player_ids := false
@onready var keyboard: Label = get_parent().get_node("Keys")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	GameInput.prompts_changed.connect(refresh)
	refresh()

func refresh() -> void:
	visible = GameInput.glyph(0, "jump") != null or GameInput.glyph(1, "jump") != null
	keyboard.visible = not visible
	queue_redraw()

func _put(text: String, x: int, y: int, ink := Color.WHITE) -> void:
	draw_string(FONT, Vector2(x, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, ink)

func _control(at: Vector2, player: int, action: String, key: String) -> void:
	var glyph := GameInput.glyph(player, action)
	if glyph != null: draw_texture_rect(glyph, Rect2(at - Vector2(0, 12), Vector2(16, 16)), false)
	else: _put(key, int(at.x), int(at.y))

func _draw() -> void:
	var accent := Color("9ee6ff")
	_put("CONTROLES", 20, 29, accent)
	_put("P1" if show_player_ids else "MAX", 154, 52, accent)
	_put("P2" if show_player_ids else "AMANDA", 305, 52, Color("f6befd"))
	for i in ROWS.size():
		var y := 71 + i * 17
		_put(ROWS[i][0], 20, y)
		for player in 2:
			_control(Vector2(154 + player * 151, y), player, ROWS[i][1], ROWS[i][player + 2])
	_control(Vector2(20, 199), 0, "controls", "F1")
	_put("Fechar", 47, 199)
	_control(Vector2(133, 199), 1, "join", "Enter")
	_put("Entrar P2" if show_player_ids else "Entrar/sair", 183, 199)
	var restart_owner := 0 if GameInput.glyph(0, "restart") != null else 1
	_control(Vector2(20, 219), restart_owner, "restart", "F2")
	_put("Reiniciar fase", 47, 219)
