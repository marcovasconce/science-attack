extends CanvasLayer

const Chapters = preload("res://scripts/chapter_catalog.gd")
const MenuSkin = preload("res://scripts/menu_button.gd")
const MAIN_MENU := "res://scenes/main_menu.tscn"

var previous_focus: Control
@onready var panel: PanelContainer = $Overlay/Center/Panel
@onready var resume_button: Button = $Overlay/Center/Panel/Content/Resume
@onready var menu_button: Button = $Overlay/Center/Panel/Content/MainMenu

func _ready() -> void:
	panel.add_theme_stylebox_override("panel", MenuSkin.panel())
	MenuSkin.apply(resume_button, true)
	MenuSkin.apply(menu_button)
	resume_button.pressed.connect(_resume)
	menu_button.pressed.connect(_return_to_menu)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo() or not event.is_action_pressed("ui_cancel"): return
	if visible:
		get_viewport().set_input_as_handled()
		_resume()
	elif event is InputEventKey and not get_tree().paused:
		get_viewport().set_input_as_handled()
		previous_focus = get_viewport().gui_get_focus_owner()
		get_tree().paused = true
		show()
		resume_button.grab_focus()

func _resume() -> void:
	hide()
	get_tree().paused = false
	if is_instance_valid(previous_focus) and previous_focus.is_visible_in_tree():
		previous_focus.grab_focus()
	previous_focus = null

func _return_to_menu() -> void:
	var tree := get_tree()
	var result := tree.change_scene_to_file(MAIN_MENU)
	if result != OK:
		push_error("Não foi possível voltar ao menu principal: %s" % error_string(result))
		return
	Chapters.reset(tree)
	if tree.has_meta("local_coop"): tree.remove_meta("local_coop")

func _exit_tree() -> void:
	if visible: get_tree().paused = false
