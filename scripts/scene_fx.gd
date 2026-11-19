extends CanvasLayer

const IRIS = preload("res://assets/third_party/saltmire/circle.gdshader")
const PIXELATE = preload("res://assets/third_party/saltmire/pixelate.gdshader")
const WIPE = preload("res://assets/third_party/saltmire/wipe.gdshader")
const SETTINGS := "user://presentation.cfg"
const COVER_COLOR := Color("070d27")
const ASPECT_UNIT := Vector2i(16, 9)

var reduced_motion := false
var fullscreen := false
var curtain: ColorRect

func _ready() -> void:
	layer = 130
	process_mode = Node.PROCESS_MODE_ALWAYS
	curtain = ColorRect.new()
	curtain.color = COVER_COLOR
	curtain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	curtain.hide()
	add_child(curtain)

	var saved := ConfigFile.new()
	if saved.load(SETTINGS) == OK:
		reduced_motion = bool(saved.get_value("video", "reduced_motion", false))
		fullscreen = bool(saved.get_value("video", "fullscreen", false))
	get_tree().root.size_changed.connect(_queue_window_fit)
	_apply_window_mode()

func save_video(use_fullscreen: bool, use_reduced_motion: bool) -> void:
	fullscreen = use_fullscreen
	reduced_motion = use_reduced_motion
	_apply_window_mode()
	var saved := ConfigFile.new()
	saved.set_value("video", "fullscreen", fullscreen)
	saved.set_value("video", "reduced_motion", reduced_motion)
	saved.save(SETTINGS)

func _apply_window_mode() -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
		_queue_window_fit()

func _queue_window_fit() -> void:
	if DisplayServer.get_name() != "headless":
		_fit_window.call_deferred()

func _fit_window() -> void:
	var window := get_tree().root
	if window.mode != Window.MODE_WINDOWED: return
	var units := floori(minf(float(window.size.x) / ASPECT_UNIT.x, float(window.size.y) / ASPECT_UNIT.y))
	var fitted := ASPECT_UNIT * units
	if units > 0 and window.size != fitted:
		window.size = fitted

func paint(rect: ColorRect, progress: float, shader: Shader, direction := Vector2.RIGHT) -> void:
	rect.color.a = progress
	if reduced_motion:
		rect.material = null
		return
	var material := rect.material as ShaderMaterial
	if material == null or material.shader != shader:
		material = ShaderMaterial.new()
		material.shader = shader
		if shader == WIPE: material.set_shader_parameter("direction", direction)
		rect.material = material
	material.set_shader_parameter("progress", progress)

func cover(shader: Shader) -> void:
	curtain.color = COVER_COLOR
	curtain.show()
	paint(curtain, 0.0, shader)
	var tween := create_tween()
	tween.tween_method(func(progress: float): paint(curtain, progress, shader), 0.0, 1.0, 0.35)
	await tween.finished

func reveal_next(shader: Shader, start_color := COVER_COLOR) -> void:
	curtain.color = start_color
	curtain.show()
	paint(curtain, 1.0, shader)
	get_tree().scene_changed.connect(reveal.bind(shader), CONNECT_ONE_SHOT)

func reveal(shader: Shader) -> void:
	var tween := create_tween()
	tween.tween_method(func(progress: float): paint(curtain, progress, shader), 1.0, 0.0, 0.42)
	await tween.finished
	curtain.hide()
