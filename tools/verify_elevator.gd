extends SceneTree
var failures: Array[String] = []
var arena: Node2D
var elevator: Node2D
var departures := 0
var transitions := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)
func tick(seconds := 0.1) -> void:
	elevator._physics_process(seconds)
	arena.encounter._process(0)
func run() -> void:
	arena = load("res://scenes/gameplay/micro_arena.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	arena.set_process(false)
	arena.tutorial.set_process(false)
	arena.encounter.set_process(false)
	elevator = arena.elevator
	check(elevator.next_scene_path=="res://scenes/gameplay/tabletop_stage.tscn","The first lift targets the playable laboratory tabletop")
	elevator.next_scene_path = ""
	elevator.set_physics_process(false)
	arena.get_node("WakeSequence").seek(3.6,true)
	arena.get_node("WakeSequence").pause()
	arena.tutorial.step = 7
	arena.controls_locked = false
	for player in arena.players:
		player.set_physics_process(false)
		player.ai_controlled = false
	for crate in arena.get_node("Breakables").get_children(): crate.freeze = true
	var p = arena.players[0]
	var q = arena.players[1]
	p.position = Vector2(2100,310)
	q.position = Vector2(2050,310)
	arena.encounter.unlock_route()
	arena.encounter.ultimate_done = true
	arena.encounter.arrived = true
	tick()
	check(not elevator.available and not arena.encounter.arrow.visible,"The elevator route stays closed with no equipment")
	p.equip_weapon("brush")
	tick()
	check(not elevator.available and arena.open_limit==2230,"One armed player cannot unlock the elevator route")
	q.equip_weapon("brush")
	arena.encounter.equipment.show()
	arena.controls_locked = true
	tick()
	check(not arena.encounter.arrow.visible,"Arrow remains hidden while the equipment panel is open")
	arena.encounter.close_equipment()
	tick()
	check(elevator.available and arena.encounter.arrow.visible,"Both equipped, including the same weapon, restore the right arrow")
	check(arena.open_limit==2860 and arena.camera_max_x==2550,"The new bay and camera unlock after equipping both players")
	p.position = Vector2(2235,318)
	q.position = Vector2(2210,318)
	await physics_frame
	check(p.move_and_collide(Vector2(120,0))==null,"The old boundary is physically removed from the way")
	var left: Vector2 = elevator.pads[0].global_position
	var right: Vector2 = elevator.pads[1].global_position
	p.position = left
	q.position = Vector2(2450,320)
	tick(0.6)
	check(elevator.pads[0].occupied and not elevator.pads[1].occupied and not elevator.is_transitioning(),"One player lights just one plate and cannot depart")
	p.position.y += 25
	tick()
	check(not elevator.pads[0].occupied,"Stepping off a plate resets it to red")
	p.position = left
	q.position = left+Vector2(4,0)
	tick(0.6)
	check(not elevator.is_transitioning() and not elevator.pads[1].occupied,"Two players on the same plate cannot depart")
	q.position = right
	q.jump_height = 12
	tick(0.6)
	check(not elevator.pads[1].occupied and not elevator.is_transitioning(),"An airborne player does not press a floor plate")
	q.jump_height = 0
	q.down = true
	p.position.y += 25
	tick(0.6)
	check(not elevator.pads[1].occupied and not elevator.is_transitioning(),"A downed player cannot activate a plate by themselves")
	q.down = false
	p.position = left
	arena.controls_locked = true
	tick(1)
	check(not elevator.is_transitioning(),"Pause cannot launch the elevator")
	arena.controls_locked = false
	q.position.y += 25
	tick()
	q.position = right
	tick(0.2)
	q.position.y += 25
	tick()
	check(elevator.ready_time==0,"Leaving before the short confirmation cancels departure")
	# Solo companion must find the free plate on either side, including the entrance.
	q.ai_controlled = true
	q.position = Vector2(2420,280)
	q.equip_weapon("bubbles")
	for frame in 240:
		await physics_frame
		q._physics_process(1.0/60.0)
		if elevator.plate_for(q)==1: break
	check(elevator.plate_for(q)==1,"AI walks around the column and occupies the opposite plate")
	p.position = right
	q.position = left
	check(elevator.ai_boarding_destination(q)==left,"AI also supports the human standing on the right plate")
	q.ai_controlled = false
	elevator.departure_started.connect(func(): departures+=1)
	elevator.next_phase_requested.connect(func(): transitions+=1)
	var player_start: Vector2 = p.position
	var partner_start: Vector2 = q.position
	tick(0.41)
	check(elevator.state==elevator.State.ASCENDING and arena.controls_locked,"Two distinct occupied plates launch the cabin")
	check(elevator.pads[0].occupied and elevator.pads[1].occupied,"Both plates stay green during travel")
	var mode_before: bool = q.ai_controlled
	Input.action_press("controls")
	Input.action_press("join")
	arena._process(0)
	Input.action_release("controls")
	Input.action_release("join")
	check(not arena.get_node("HUD/ControlsPanel").visible and q.ai_controlled==mode_before and arena.controls_locked,"Help/join cannot interrupt or unlock the ascent")
	tick(1.5)
	check(p.position.y<player_start.y-50 and (p.position-player_start).is_equal_approx(q.position-partner_start),"The cabin carries both players upward by the same offset")
	check(elevator.black.color.a>0 and elevator.black.color.a<1,"Black fade begins during ascent")
	tick(1.2)
	check(elevator.state==elevator.State.LOADING and elevator.black.color.a==1,"Travel ends on an opaque black loading screen")
	check(elevator.black.size.is_equal_approx(Vector2(640,360)),"Loading covers the complete viewport")
	tick(0.7)
	tick(2)
	check(departures==1 and transitions==1,"Departure and transition fire only once")
	check(elevator.state==elevator.State.COMPLETE and "EM BREVE" in elevator.loading_label.text,"Missing next stage ends clearly instead of loading forever")
	check(p.equipped_weapon=="brush" and q.equipped_weapon=="bubbles","Travel preserves each selected weapon")
	if failures.is_empty(): print("PASS: gear gate, right arrow, physical route, red/green plates, same-plate/solo/jump/down/pause guards, AI entrance, both players carried, fade, loading, one-shot completion")
	else:
		for failure in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
