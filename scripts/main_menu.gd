extends Control

const Chapters = preload("res://scripts/chapter_catalog.gd")
const FONT = preload("res://assets/fonts/PressStart2P-Regular.ttf")
const MenuSkin = preload("res://scripts/menu_button.gd")

var chapter_panel: Panel
var options_panel: Panel
var exit_panel: Panel
var shade: ColorRect
var chapter_list: ItemList
var fullscreen_toggle: CheckButton
var motion_toggle: CheckButton
var cancel_exit: Button
var chapter_ids: Array[int] = []
var modal: Panel
var return_focus: Control
var opening := false
var error_label: Label
var pad_hint: Label

@onready var play_button: Button = $Buttons/Play
@onready var chapters_button: Button = $Buttons/Chapters
@onready var options_button: Button = $Buttons/Options
@onready var exit_button: Button = $Buttons/Exit
@onready var coop_button: CheckButton = $Buttons/Coop
@onready var laboratory: Node2D = $Laboratory

func _ready() -> void:
	MenuSkin.apply(play_button, true)
	MenuSkin.apply(coop_button, false, "teal")
	MenuSkin.apply(chapters_button, false, "violet")
	MenuSkin.apply(options_button, false, "cyan")
	MenuSkin.apply(exit_button, false, "rose")
	play_button.pressed.connect(_open_chapter.bind(0))
	chapters_button.pressed.connect(show_chapters)
	options_button.pressed.connect(_show_options)
	exit_button.pressed.connect(_show_exit)
	shade = ColorRect.new()
	shade.color = Color(0.012, 0.015, 0.077, 0.78)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.hide()
	add_child(shade)
	_build_chapters()
	_build_options()
	_build_exit()
	error_label = Label.new()
	error_label.position = Vector2(320, 340)
	error_label.add_theme_font_size_override("font_size", 8)
	error_label.add_theme_color_override("font_color", Color("ffe3ac"))
	error_label.add_theme_color_override("font_outline_color", Color("080b2b"))
	error_label.add_theme_constant_override("outline_size", 5)
	add_child(error_label)
	pad_hint = Label.new()
	pad_hint.position = Vector2(481, 341)
	pad_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad_hint.add_theme_font_size_override("font_size", 8)
	add_child(pad_hint)
	GameInput.prompts_changed.connect(_update_pad_hint)
	_update_pad_hint()
	play_button.grab_focus()

func _update_pad_hint() -> void:
	GameInput.label_hint(pad_hint, -1, "accept", "", "SELECIONAR")

func _frame(title: String, bounds: Rect2) -> Panel:
	var panel := Panel.new()
	panel.position = bounds.position
	panel.size = bounds.size
	panel.add_theme_stylebox_override("panel", MenuSkin.panel())
	add_child(panel)
	var label := Label.new()
	label.position = Vector2(22, 20)
	label.text = title
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", 14)
	panel.add_child(label)
	panel.hide()
	return panel

func _action(panel: Panel, label: String, bounds: Rect2, action: Callable) -> Button:
	var button := Button.new()
	button.text = label
	button.position = bounds.position
	button.size = bounds.size
	MenuSkin.apply(button)
	button.pressed.connect(action)
	panel.add_child(button)
	return button

func _build_chapters() -> void:
	chapter_panel = _frame("CAPÍTULOS", Rect2(87, 23, 466, 314))
	chapter_list = ItemList.new()
	chapter_list.position = Vector2(20, 52)
	chapter_list.size = Vector2(426, 200)
	chapter_list.add_theme_font_size_override("font_size", 10)
	chapter_list.add_theme_constant_override("v_separation", 5)
	chapter_list.add_theme_stylebox_override("panel", MenuSkin.panel(Color(0.18, 0.24, 0.43)))
	chapter_list.add_theme_stylebox_override("selected", MenuSkin.panel(Color(0.50, 0.65, 0.92)))
	chapter_list.add_theme_stylebox_override("selected_focus", MenuSkin.panel(Color(0.50, 0.65, 0.92)))
	chapter_list.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var scroll := chapter_list.get_v_scroll_bar()
	var track := StyleBoxFlat.new()
	track.bg_color = Color("101b3b")
	track.content_margin_left = 4
	track.content_margin_right = 4
	var handle := track.duplicate() as StyleBoxFlat
	handle.bg_color = Color("629ccb")
	scroll.add_theme_stylebox_override("scroll", track)
	for state in ["grabber", "grabber_highlight", "grabber_pressed"]:
		scroll.add_theme_stylebox_override(state, handle)
	chapter_panel.add_child(chapter_list)
	_add_entry("COMEÇO DA AVENTURA", -1)
	for id in [0, 1]: _add_entry(Chapters.NAMES[id], id)
	_add_entry("FASE 1 • A BANCADA", -1)
	_add_entry("Chegada à bancada", 2)
	for i in Chapters.SECTORS.size(): _add_entry(Chapters.SECTORS[i], 10 + i)
	_add_entry("FASE 2 • SETOR INFERIOR", -1)
	_add_entry("Chegada ao laboratório", 3)
	for i in Chapters.LOWER_SECTORS.size(): _add_entry(Chapters.LOWER_SECTORS[i], 20 + i)
	_add_entry("DESCIDA E COLMEIA", -1)
	_add_entry("Elevador: sobreviva à descida", 4)
	_add_entry("Colmeia: chegada", 5)
	_add_entry("Colmeia: oficina e batalha final", 30)
	_add_entry(Chapters.KING_TITLE, Chapters.KING_CHAPTER)
	chapter_list.item_activated.connect(func(index: int): _open_chapter(chapter_ids[index]))
	_action(chapter_panel, "Voltar", Rect2(20, 266, 125, 30), hide_chapters)
	_action(chapter_panel, "Jogar capítulo", Rect2(267, 266, 179, 30), _play_selected_chapter)

func _add_entry(title: String, id: int) -> void:
	var index := chapter_list.add_item(title)
	chapter_ids.append(id)
	if id < 0:
		chapter_list.set_item_selectable(index, false)
		chapter_list.set_item_custom_fg_color(index, Color("89e2ff"))

func _play_selected_chapter() -> void:
	var selected := chapter_list.get_selected_items()
	if not selected.is_empty(): _open_chapter(chapter_ids[selected[0]])

func show_chapters() -> void:
	if opening or is_instance_valid(modal): return
	_show_modal(chapter_panel, chapters_button)
	chapter_list.select(1)
	chapter_list.ensure_current_is_visible()
	chapter_list.grab_focus()

func hide_chapters() -> void:
	if modal == chapter_panel: _close_modal()

func _build_options() -> void:
	options_panel = _frame("OPÇÕES", Rect2(153, 43, 334, 274))
	fullscreen_toggle = _toggle("Tela cheia", 56, SceneFx.fullscreen)
	motion_toggle = _toggle("Reduzir animações", 93, SceneFx.reduced_motion)
	fullscreen_toggle.toggled.connect(_update_settings)
	motion_toggle.toggled.connect(_update_settings)
	_volume_slider("Música", "Music", 137)
	_volume_slider("Efeitos", "Effects", 173)
	_action(options_panel, "Voltar", Rect2(22, 222, 112, 29), _close_modal)

func _volume_slider(title: String, channel: String, y: int) -> void:
	var label := Label.new()
	label.text = title
	label.position = Vector2(23, y)
	label.add_theme_font_size_override("font_size", 13)
	options_panel.add_child(label)
	var slider := HSlider.new()
	slider.accessibility_name = title
	slider.position = Vector2(130, y)
	slider.size = Vector2(163, 23)
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = GameAudio.level(channel)
	slider.value_changed.connect(func(value: float):
		GameAudio.set_level(channel, value)
		if channel == "Effects": GameAudio.effect("lever"))
	options_panel.add_child(slider)

func _toggle(label: String, y: float, enabled: bool) -> CheckButton:
	var toggle := CheckButton.new()
	toggle.text = label
	toggle.position = Vector2(22, y)
	toggle.size = Vector2(290, 31)
	MenuSkin.apply(toggle)
	toggle.button_pressed = enabled
	options_panel.add_child(toggle)
	return toggle

func _update_settings(_enabled: bool) -> void:
	SceneFx.save_video(fullscreen_toggle.button_pressed, motion_toggle.button_pressed)
	laboratory.set_reduced(SceneFx.reduced_motion)

func _show_options() -> void:
	if opening or is_instance_valid(modal): return
	_show_modal(options_panel, options_button)
	fullscreen_toggle.grab_focus()

func _build_exit() -> void:
	exit_panel = _frame("SAIR DO JOGO?", Rect2(160, 115, 320, 130))
	cancel_exit = _action(exit_panel, "Voltar", Rect2(22, 74, 120, 33), _close_modal)
	_action(exit_panel, "Sair", Rect2(178, 74, 120, 33), func(): get_tree().quit())

func _show_exit() -> void:
	if opening or is_instance_valid(modal): return
	_show_modal(exit_panel, exit_button)
	cancel_exit.grab_focus()

func _show_modal(panel: Panel, origin: Control) -> void:
	modal = panel
	return_focus = origin
	shade.show()
	pad_hint.hide()
	panel.show()
	for button in [play_button, chapters_button, options_button, exit_button, coop_button]:
		button.disabled = true

func _close_modal() -> void:
	if opening or not is_instance_valid(modal): return
	modal.hide()
	modal = null
	shade.hide()
	pad_hint.show()
	for button in [play_button, chapters_button, options_button, exit_button, coop_button]:
		button.disabled = false
	return_focus.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if opening: return
	if event.is_action_pressed("ui_cancel") and is_instance_valid(modal):
		_close_modal()
		get_viewport().set_input_as_handled()
	elif modal == null and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if laboratory.react_at(event.position):
			get_viewport().set_input_as_handled()

func _open_chapter(id: int) -> void:
	if opening or not Chapters.valid(id): return
	opening = true
	error_label.text = ""
	_load.call_deferred(id)

func _load(id: int) -> void:
	var effect: Shader = SceneFx.IRIS if id == 0 else SceneFx.WIPE
	if id == 0 and modal == null:
		await laboratory.launch()
	await SceneFx.cover(effect)
	GameInput.choose_party(coop_button.button_pressed)
	get_tree().set_meta("local_coop", coop_button.button_pressed)
	var result := Chapters.open(get_tree(), id)
	if result == OK:
		SceneFx.reveal_next(effect)
	else:
		get_tree().remove_meta("local_coop")
		laboratory.departing = false
		await SceneFx.reveal(effect)
		opening = false
		error_label.text = "Tente abrir o capítulo de novo."
