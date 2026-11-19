extends RefCounted

const SHEET = preload("res://assets/third_party/kenney_input_pixel/gamepad_glyphs.png")
const ROW := {&"xbox": 0, &"ps": 1, &"switch": 2, &"generic": 3}
const COLUMN := {
	"move": 0, "jump": 1, "accept": 1, "attack": 2, "dodge": 3, "cancel": 3,
	"special": 4, "heal": 5, "interact": 6, "controls": 7, "join": 7, "restart": 8,
}
static var cached: Dictionary = {}

static func icon(family: StringName, action: String) -> Texture2D:
	var cell := Vector2i(COLUMN.get(action, -1), ROW.get(family, 3))
	if cell.x < 0: return null
	if not cached.has(cell):
		var glyph := AtlasTexture.new()
		glyph.atlas = SHEET
		glyph.region = Rect2(Vector2(cell * 16), Vector2(16, 16))
		glyph.filter_clip = true
		cached[cell] = glyph
	return cached[cell]
