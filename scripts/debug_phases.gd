extends CanvasLayer
## Shared chapter routes remain available during cutscenes and modal screens.
const Chapters = preload("res://scripts/chapter_catalog.gd")
const PHASES = Chapters.PHASES
const NAMES = Chapters.NAMES
const SECTORS = Chapters.SECTORS
var switching := false
var row: HBoxContainer
var show_tools := false
func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	row = HBoxContainer.new()
	row.position = Vector2(160,337)
	row.hide()
	add_child(row)
	var next := Button.new()
	next.text = "DEBUG: PULAR FASE [F6]"
	next.add_theme_font_size_override("font_size",11)
	next.focus_mode = Control.FOCUS_NONE
	next.pressed.connect(skip_next)
	row.add_child(next)
	var menu := MenuButton.new()
	menu.text = "ESCOLHER FASE"
	menu.add_theme_font_size_override("font_size",11)
	menu.focus_mode = Control.FOCUS_NONE
	row.add_child(menu)
	for i in PHASES.size(): menu.get_popup().add_item(NAMES[i],i)
	menu.get_popup().add_separator("SETORES DA BANCADA")
	for i in SECTORS.size(): menu.get_popup().add_item(SECTORS[i],10+i)
	menu.get_popup().add_separator("SETORES DO LABORATÓRIO")
	for i in Chapters.LOWER_SECTORS.size(): menu.get_popup().add_item(Chapters.LOWER_SECTORS[i],20+i)
	menu.get_popup().add_separator("COLMEIA")
	menu.get_popup().add_item("Oficina e batalha final",30)
	menu.get_popup().add_separator()
	menu.get_popup().add_item("Menu principal",99)
	menu.get_popup().id_pressed.connect(go_to_phase)
func _process(_dt: float) -> void:
	var scene := get_tree().current_scene
	row.visible = show_tools and is_instance_valid(scene) and scene.scene_file_path != "res://scenes/main_menu.tscn"
func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if event.keycode == KEY_F6: skip_next()
	elif event.keycode == KEY_F8: show_tools = not show_tools
	else: return
	get_viewport().set_input_as_handled()
func skip_next() -> void:
	var scene := get_tree().current_scene
	var index := PHASES.find(scene.scene_file_path) if is_instance_valid(scene) else -1
	go_to_phase((index+1)%PHASES.size())
func go_to_phase(id: int) -> void:
	if switching or (id != 99 and not Chapters.valid(id)): return
	switching = true
	_change_phase.call_deferred(id)
func _change_phase(id: int) -> void:
	var tree := get_tree()
	var result: Error
	if id == 99:
		Chapters.reset(tree)
		result = tree.change_scene_to_file("res://scenes/main_menu.tscn")
	else: result = Chapters.open(tree,id,true)
	if result != OK: push_error("Não foi possível abrir o capítulo %d" % id)
	await tree.process_frame
	switching = false
func _sector_checkpoint(sector: int, party: Array) -> Dictionary:
	return Chapters.sector_checkpoint(sector,party)

