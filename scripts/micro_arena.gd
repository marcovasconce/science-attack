extends Node2D
const GermScene = preload("res://scenes/actors/germ.tscn")
var players: Array = []
var open_limit := 570.0
var wave := 0
var defeated := 0
var pieces := 0
var build_progress := 0.0
var built := false
var victory := false
var hitstop := 0.0
var combo_hits := 0
var combo_timer := 0.0
var effects: Array = []
@onready var status: Label = $HUD/Status
func _ready() -> void:
	players=[$Actors/MaxAvatar,$Actors/AmandaAvatar]
	players[1].sprite.sprite_frames=preload("res://assets/avatars/Pink_Monster.tres")
	spawn_wave()
func nearest_enemy(at: Vector2):
	var best=null
	var distance=INF
	for enemy in get_tree().get_nodes_in_group("germs"):
		if not is_instance_valid(enemy) or enemy.dead: continue
		var d: float=at.distance_squared_to(enemy.position)
		if d<distance: best=enemy; distance=d
	return best
func nearest_player(at: Vector2):
	var best=null
	var distance=INF
	for player in players:
		if player.down: continue
		var d: float=at.distance_squared_to(player.position)
		if d<distance: best=player; distance=d
	return best
func spawn_wave() -> void:
	wave+=1
	for i in range(3+wave):
		var enemy=GermScene.instantiate()
		enemy.position=Vector2(420+i*28 if wave==1 else 900+i*34,205+(i%4)*30)
		enemy.speed=38+wave*6
		$Actors.add_child(enemy)
func strike(player, combo: int, targets: Array) -> void:
	for enemy in get_tree().get_nodes_in_group("germs"):
		if enemy in targets or enemy.dead: continue
		var offset: Vector2=enemy.position-player.position
		if absf(offset.y)<22 and offset.x*player.facing>-12 and offset.x*player.facing<65:
			targets.append(enemy)
			var assisted: bool=players[0].attack_time>0 and players[1].attack_time>0 and players[0].position.distance_to(players[1].position)<100
			enemy.take_hit((28 if combo==3 else 18)+(15 if assisted else 0),player.facing)
			combo_hits+=1
			combo_timer=2
			player.energy=minf(100,player.energy+8)
			effects.append({"p":enemy.position+Vector2(0,-20),"t":0.2})
			$Camera2D.offset=Vector2(3,-2)
	for prop in $Breakables.get_children():
		if not prop.visible or prop in targets: continue
		var offset: Vector2=prop.position-player.position
		if absf(offset.y)<24 and offset.x*player.facing>-10 and offset.x*player.facing<65:
			targets.append(prop)
			prop.visible=false
			pieces+=3
			effects.append({"p":prop.position+Vector2(0,-18),"t":0.3})
func germ_defeated(at: Vector2) -> void:
	defeated+=1
	pieces+=2
	effects.append({"p":at+Vector2(0,-18),"t":0.4})
func interact(player, dt: float) -> void:
	for other in players:
		if other!=player and other.down and player.position.distance_to(other.position)<40:
			other.revive_progress+=dt
			if other.revive_progress>2:
				other.down=false
				other.hp=50
				other.invulnerable=2
				other.revive_progress=0
	if built or pieces<8 or player.position.distance_to(Vector2(540,250))>62: return
	var partner=players[1] if player==players[0] else players[0]
	if partner.position.distance_to(Vector2(540,250))<85 and not partner.down:
		build_progress+=dt
		if build_progress>=2:
			built=true
			pieces-=8
			open_limit=1230
			$Bridge.visible=true
			$Gate.visible=false
			spawn_wave()
func _process(dt: float) -> void:
	if Input.is_action_just_pressed("join"):
		players[1].ai_controlled=not players[1].ai_controlled
	if Input.is_action_just_pressed("restart"): get_tree().reload_current_scene()
	combo_timer=maxf(0,combo_timer-dt)
	if combo_timer<=0: combo_hits=0
	var center: Vector2=(players[0].position+players[1].position)*0.5
	$Camera2D.position.x=clampf(center.x,320,960)
	$Camera2D.offset=$Camera2D.offset.lerp(Vector2.ZERO,dt*20)
	for player in players:
		player.position.x=clampf(player.position.x,$Camera2D.position.x-300,$Camera2D.position.x+300)
	$HUD/P1.value=players[0].hp
	$HUD/P2.value=players[1].hp
	$HUD/Combo.text="%d HITS" % combo_hits if combo_hits>1 else ""
	if defeated>=9 and built and get_tree().get_nodes_in_group("germs").is_empty(): victory=true
	status.text="SETOR LIMPO!  •  R para repetir" if victory else ("AVANCEM!  →  Eliminem os germes" if built else "Quebrem caixas • 8 peças + dupla no terminal [E / O]")
	if players[0].down and players[1].down: status.text="CONEXÃO PERDIDA • R para tentar novamente"
	$HUD/Pieces.text="PEÇAS %02d   |   COOP %d%%" % [pieces,int(build_progress/2*100)]
	for fx in effects: fx.t-=dt
	effects=effects.filter(func(fx): return fx.t>0)
	queue_redraw()
func _draw() -> void:
	for fx in effects:
		for i in range(8):
			var ray=Vector2.from_angle(i*TAU/8)
			draw_line(fx.p+ray*5,fx.p+ray*(12+fx.t*35),Color("fff19a"),3)
