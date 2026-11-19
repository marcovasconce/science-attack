extends "res://scripts/journey_arena.gd"
signal descent_finished
const DURATION := 40.0
const NEXT_SCENE := "res://scenes/gameplay/hive_stage.tscn"
const Yellow = preload("res://scenes/actors/yellow_flying_bacterium.tscn")
const DropGerm = preload("res://scripts/shaft_drop_germ.gd")
const ORDER := ["red","yellow","red","yellow","red","green","yellow","red"]
enum Ride { ARRIVAL, DESCENDING, ARRIVED, TRANSFER }
var ride := Ride.ARRIVAL
var age := 0.0
var elapsed := 0.0
var spawn_clock := 1.8
var spawned := 0
var composition := {"green":0,"red":0,"yellow":0}
var auto_transfer := true
func _ready() -> void:
	entry_key = "shaft_entry_state"
	super._ready()
	$HUD/JourneyTitle.text = "DESCIDA À COLMEIA"
	$Transition/Black.color.a = 1
	$Transition/Black/Message.hide()
	_update_timer()
func _process(dt: float) -> void:
	super._process(dt)
	if $HUD/ControlsPanel.visible or (players[0].down and players[1].down): return
	age += dt
	if ride == Ride.ARRIVAL:
		SceneFx.paint($Transition/Black, 1-smoothstep(0,1.0,age), SceneFx.WIPE, Vector2.DOWN)
		if age >= 1.1:
			ride = Ride.DESCENDING
			age = 0
			controls_locked = false
			transitioning = false
	elif ride == Ride.DESCENDING:
		if controls_locked: return
		elapsed = minf(DURATION,elapsed+dt)
		$Environment.travel = elapsed
		spawn_clock -= dt
		while spawn_clock <= 0 and elapsed < DURATION-2.5:
			spawn_clock += 2.6
			for i in 2:
				if get_tree().get_nodes_in_group("germs").size() < 8: _spawn_attacker()
		if elapsed >= DURATION: _arrive()
	elif ride == Ride.ARRIVED:
		SceneFx.paint($Transition/Black, smoothstep(0.25,1.2,age), SceneFx.IRIS)
		if age >= 1.3:
			ride = Ride.TRANSFER
			$Transition/Black/Message.text = "A COLMEIA"
			$Transition/Black/Message.show()
			if auto_transfer: transfer_to.call_deferred(NEXT_SCENE)
	_update_timer()
func _spawn_attacker() -> void:
	var kind: String = ORDER[spawned%ORDER.size()]
	var enemy = Yellow.instantiate() if kind == "yellow" else GermScene.instantiate()
	if kind != "yellow":
		enemy.set_script(DropGerm)
		enemy.variant = kind
		enemy.speed = 48 if kind == "red" else 55
	enemy.position = Vector2(86 if spawned%2 == 0 else 554,214+(spawned%4)*30)
	$Actors.add_child(enemy)
	spawned += 1
	composition[kind] += 1
func _arrive() -> void:
	if ride != Ride.DESCENDING: return
	GameAudio.effect("lever")
	ride = Ride.ARRIVED
	age = 0
	transitioning = true
	controls_locked = true
	for player in players:
		player.velocity = Vector2.ZERO
		player.attack_time = 0
		player.push_velocity = Vector2.ZERO
		player.specials.cancel()
	for enemy in get_tree().get_nodes_in_group("germs"): enemy.queue_free()
	for shot in $Projectiles.get_children(): shot.queue_free()
	descent_finished.emit()
func _update_timer() -> void:
	$HUD/TravelTime.text = "%02d s" % int(ceil(DURATION-elapsed)) if ride != Ride.ARRIVED and ride != Ride.TRANSFER else "CHEGAMOS!"
	$HUD/TravelProgress.value = elapsed/DURATION*100
