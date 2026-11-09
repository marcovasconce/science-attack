extends Node2D
signal opened
const FADE_TIME := 0.8
const OPEN_START := 1.0
const OPEN_TIME := 1.4
var age := 0.0
var arrived := false
@onready var arena = get_tree().get_first_node_in_group("arena")
@onready var doors: Control = $Doors
@onready var black: ColorRect = $Transition/Black

func _ready() -> void:
	$Hint.hide()
	$Shaft.hide()
	$LeftRail.hide()
	$RightRail.hide()
	$Transition/Black/Message.hide()
	$Cabin/LeftPad.occupied = true
	$Cabin/RightPad.occupied = true
	black.color.a = 1
	doors.openness = 0

func is_transitioning() -> bool:
	return not arrived

func ai_boarding_destination(_player) -> Variant:
	return null

func _physics_process(dt: float) -> void:
	if arrived: return
	age += dt
	black.color.a = 1.0-smoothstep(0.0,FADE_TIME,age)
	doors.openness = smoothstep(OPEN_START,OPEN_START+OPEN_TIME,age)
	if age>=OPEN_START+OPEN_TIME:
		arrived = true
		doors.hide()
		$DoorBlocker/Collision.set_deferred("disabled",true)
		$Hint.text = "SAIA PELA FRENTE"
		$Hint.show()
		arena.controls_locked = false
		opened.emit()
