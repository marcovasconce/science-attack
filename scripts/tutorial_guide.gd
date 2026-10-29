extends Node
## Remote communicator: observes the team without a physical world entity.
var step := 0
var age := 0.0
var action_done := false
var moved := 0.0
var start_position := Vector2.ZERO
var hit_germ := false
var next_delay := 0.0
@onready var arena = get_parent()
@onready var bubble: Control = $"../HUD/Communicator"
@onready var message: Label = bubble.get_node("Message")
@onready var key: Label = bubble.get_node("Key")
const MESSAGES = ["", "Vamos andar!", "Vamos pular!", "Desvie!", "Quebre a caixa!", "Acerte o germe!", "Vamos montar juntos!", "Agora é com vocês!"]
const KEYS = ["", "W A S D", "ESPAÇO", "SHIFT", "F", "F", "E • segurar", ""]
func begin() -> void:
	arena.controls_locked=true
	arena.open_limit=340
	start_position=arena.players[0].position
	$"../WakeSequence".play("wake")
func _process(dt: float) -> void:
	if arena.get_node("HUD/ControlsPanel").visible and step>0: return
	age+=dt
	if step==0:
		bubble.visible=false
		if age>=3.6:
			arena.controls_locked=false
			advance()
		return
	var marker: Node2D=arena.get_node("GoalMarker")
	marker.visible=step in [1,4,5,6]
	marker.position=Vector2(290,225)
	if step==4 or (step==6 and arena.pieces<8):
		marker.visible=false
		for crate in arena.get_node("Breakables").get_children():
			if not crate.broken and crate.position.x<570:
				marker.position=crate.position+Vector2(0,-58)
				marker.visible=true
				break
	if step==5:
		var germ=arena.nearest_enemy(arena.players[0].position)
		if germ!=null: marker.position=germ.position+Vector2(0,-65)
	if step==6 and arena.pieces>=8: marker.position=Vector2(540,150)
	marker.position.y+=sin(age*4)*4
	var leader=arena.players[0]
	bubble.visible=step<7 or age<3.0
	message.text=MESSAGES[step]
	key.text=KEYS[step]
	if not arena.players[1].ai_controlled and step in [1,2,3,4,5,6]:
		key.text += "  /  " + ["","↑ ← ↓ →","K","L","J","J","U"][step]
	if step==1 and leader.position.distance_to(start_position)>95: complete()
	if step==2 and action_done and leader.jump_height<=0: complete()
	if step==3 and action_done and leader.dash<=0: complete()
	if step==4 and action_done: complete()
	if step==5 and arena.defeated>0 and hit_germ: complete()
	if step==6:
		message.text="Junte 8 peças!" if arena.pieces<8 and not arena.built else "Vamos montar juntos!"
		key.text=("F" if arena.pieces<8 else "E • segurar") if arena.players[1].ai_controlled else ("F / J" if arena.pieces<8 else "E / U • segurar")
		if arena.built: complete()
	if step==7 and arena.victory:
		bubble.visible=true
		message.text="Conseguimos!"
		key.text="✓"
	if next_delay>0:
		next_delay-=dt
		message.text="Boa!"
		key.text="✓"
		if next_delay<=0: advance()
func record_action(action: String, player) -> void:
	if player.ai_controlled or arena.controls_locked: return
	if (step==2 and action=="jump") or (step==3 and action=="dodge") or (step==4 and action=="crate"): action_done=true
	if action=="germ": hit_germ=true
func complete() -> void:
	if next_delay<=0: next_delay=0.65
func advance() -> void:
	step=mini(7,step+1)
	age=0
	action_done=false
	if step==3: arena.open_limit=450
	if step==4: arena.open_limit=570
	if step==5:
		var enemy=arena.GermScene.instantiate()
		enemy.position=Vector2(490,260)
		enemy.hp=36
		enemy.speed=23
		arena.get_node("Actors").add_child(enemy)
		arena.wave=1
