@tool
extends StaticBody2D
const SHEET = preload("res://assets/environment/tabletop_props.png")
const LIQUID = preload("res://assets/environment/test_tube_liquid.gdshader")
@export_enum("cyan","green") var variant := "cyan"
@export var tube_height := 198.0
@export var phase_offset := 0.0
var liquid_time := 0.0
var liquid_material: ShaderMaterial

func _ready() -> void:
	var region := Rect2(214,54,230,576) if variant=="cyan" else Rect2(866,65,230,576)
	var crop := AtlasTexture.new()
	crop.atlas = SHEET
	crop.region = region
	$Sprite.texture = crop
	$Sprite.position = Vector2(0,-tube_height*0.5)
	$Sprite.scale = Vector2.ONE*tube_height/576.0
	liquid_material = ShaderMaterial.new()
	liquid_material.shader = LIQUID
	liquid_material.set_shader_parameter("liquid_bounds",Vector4(258,315,396,590) if variant=="cyan" else Vector4(909,331,1045,600))
	$Sprite.material = liquid_material
	liquid_time = phase_offset
	liquid_material.set_shader_parameter("liquid_time",liquid_time)

func _process(dt: float) -> void:
	if Engine.is_editor_hint(): return
	var arena = get_tree().get_first_node_in_group("arena")
	if is_instance_valid(arena) and (arena.encounter.is_modal() or arena.get_node("HUD/ControlsPanel").visible): return
	liquid_time += dt
	liquid_material.set_shader_parameter("liquid_time",liquid_time)
