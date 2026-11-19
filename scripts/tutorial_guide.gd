extends Node
## Tibúrcio guides the tutorial remotely, then meets the team at the supply outpost.
var step := 0
var age := 0.0
var action_done := false
var start_position := Vector2.ZERO
var partner_start := Vector2.ZERO
var acting_player: Node2D
var hit_germ := false
var next_delay := 0.0
@onready var arena = get_parent()
@onready var bubble: Control = $"../HUD/Communicator"
@onready var message: Label = bubble.get_node("Message")
@onready var key: Label = bubble.get_node("Key")
const MESSAGES = ["", "Sigam a seta!", "Vamos pular!", "Desvie!", "Quebre a caixa metálica!", "Derrote a bactéria!", "Vamos montar a ponte!", "Agora é com vocês!"]
const KEYS = ["", "", "ESPAÇO", "SHIFT", "F", "F", "SEGURE E", ""]
const ACTIONS = ["", "", "jump", "dodge", "attack", "attack", "interact", ""]
const PARTNER_KEYS = ["", "", "K", "L", "J", "J", "U", ""]
func begin() -> void:
	arena.controls_locked=true
	arena.open_limit=340
	start_position=arena.players[0].position
	partner_start=arena.players[1].position
	$"../WakeSequence".play("wake")
func _process(dt: float) -> void:
	if arena.encounter.is_modal() or arena.encounter.unlocked:
		bubble.visible=false
		arena.get_node("GoalMarker").hide()
		arena.encounter.update_ultimate_lesson(dt)
		return
	if arena.get_node("HUD/ControlsPanel").visible and step>0: return
	age+=dt
	if step==0:
		bubble.visible=false
		if age>=3.6:
			arena.controls_locked=arena.get_node("HUD/ControlsPanel").visible
			advance()
		return
	var marker: Node2D=arena.get_node("GoalMarker")
	marker.visible=step in [1,4,5,6]
	marker.position=Vector2(290,225)
	if step==4 or (step==6 and not arena.bridge_has_parts()):
		marker.visible=false
		for crate in arena.get_node("Breakables").get_children():
			if not crate.broken and crate.position.x<570:
				marker.position=crate.position+Vector2(0,-58)
				marker.visible=true
				break
	if step==5:
		var germ=arena.nearest_enemy(arena.players[0].position)
		if germ!=null: marker.position=germ.position+Vector2(0,-65)
	if step==6 and arena.bridge_has_parts(): marker.position=Vector2(566,220)
	marker.position.y+=sin(age*4)*4
	var leader=arena.players[0]
	var partner=arena.players[1]
	bubble.visible=step<7 or age<3.0
	message.text=MESSAGES[step]
	key.text=KEYS[step]
	var action: String = ACTIONS[step]
	var keyboard_keys := [KEYS[step], PARTNER_KEYS[step]]
	var caption := ""
	if not partner.ai_controlled and step in [2,3,4,5,6]:
		key.text += "  /  " + PARTNER_KEYS[step]
	if step==1 and (leader.position.distance_to(start_position)>95 or (not partner.ai_controlled and partner.position.distance_to(partner_start)>95)): complete()
	if step==2 and is_instance_valid(acting_player) and acting_player.jump_height<=0: complete()
	if step==3 and is_instance_valid(acting_player) and acting_player.dash<=0: complete()
	if step==4 and action_done: complete()
	if step==5 and arena.defeated>0 and hit_germ: complete()
	if step==6:
		var missing_parts: bool = not arena.bridge_has_parts()
		message.text="Parafusos: %d de 8."%mini(8,arena.pieces) if missing_parts and not arena.built else "Vamos montar a ponte!"
		key.text=("F" if missing_parts else "SEGURE E") if arena.players[1].ai_controlled else ("F / J" if missing_parts else "SEGURE E / U")
		action = "attack" if missing_parts else "interact"
		keyboard_keys = ["F", "J"] if missing_parts else ["E", "U"]
		caption = "" if missing_parts else "SEGURE"
		if arena.built: complete()
	if step==7 and arena.victory:
		bubble.visible=true
		message.text="Conseguimos!"
		key.text=""
	if next_delay>0:
		next_delay-=dt
		message.text="Boa!"
		key.text=""
		action = ""
		if next_delay<=0: advance()
	if action.is_empty():
		GameInput.clear_hint(key)
	else:
		GameInput.multi_hint(key, [0] if partner.ai_controlled else [0, 1], action, keyboard_keys, key.text, caption)
func record_action(action: String, player) -> void:
	if player.ai_controlled or arena.controls_locked: return
	if ((step==2 and action=="jump") or (step==3 and action=="dodge")) and not is_instance_valid(acting_player):
		acting_player=player
	if step==4 and action=="crate": action_done=true
	if action=="germ": hit_germ=true
func complete() -> void:
	if next_delay>0: return
	next_delay=0.65
	bubble.modulate=Color("b6ffdf")
	create_tween().tween_property(bubble,"modulate",Color.WHITE,0.4)
func advance() -> void:
	step=mini(7,step+1)
	age=0
	action_done=false
	acting_player=null
	if step==3: arena.open_limit=450
	if step==4: arena.open_limit=570
	if step==5:
		var enemy=arena.GermScene.instantiate()
		enemy.position=Vector2(490,260)
		enemy.hp=72
		enemy.speed=23
		arena.get_node("Actors").add_child(enemy)
		arena.wave=1
