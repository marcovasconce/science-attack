extends Node2D
## Animated bitmap effects and soap bubbles on a deliberately coarse 2x pixel grid.
const BEAM = preload("res://assets/animations/soap_water_beam.tres")
const SPLASH = preload("res://assets/animations/soap_water_splash.tres")
var mode := ""
var time := 0.0
var beam_length := 560.0
var pulses: Array = []
var use_arcade_effects := false
const ARCADE_BURST = preload("res://assets/third_party/ansimuz_hive/explosion-3.png")
const ARCADE_POP = preload("res://assets/third_party/ansimuz_hive/explosion-1.png")
const ARCADE_BUBBLE = preload("res://assets/third_party/alejandrohaibi/bubble.png")

func _draw() -> void:
	if mode == "bubbles2":
		if use_arcade_effects: _arcade_beam()
		else: _beam()
	elif mode == "brush2":
		if use_arcade_effects: _arcade_burst(Vector2(160, 96), time - 0.5, 1.2)
		else: _splash()
	elif mode == "solar": _solar()
	elif mode == "nova": _nova()

func bubble(at: Vector2, radius: float) -> void:
	var ring := PackedVector2Array()
	for i in 9: ring.append((at+Vector2.from_angle(i*TAU/8)*radius).round())
	draw_polyline(ring,Color("c6ffff"),1,false)
	draw_rect(Rect2((at+Vector2(-radius*0.4,-radius*0.5)).round(),Vector2(1,1)),Color.WHITE)
	if radius >= 3: draw_rect(Rect2((at+Vector2(radius*0.4,radius*0.4)).round(),Vector2(1,1)),Color("ffb6e4"))

func _beam() -> void:
	var nozzle := Vector2(40,54)
	if time < 0.25:
		var r := 3+time*32
		bubble(nozzle+Vector2(4,0),r)
		for i in 5:
			var at := nozzle+Vector2.from_angle(i*TAU/5-time*12)*(18-time*45)
			draw_rect(Rect2(at.round(),Vector2(2,2)),Color("70faff"))
		return
	if beam_length <= 1: return
	var length := beam_length*0.5
	var opening := clampf(minf((time-0.25)/0.1,(3.25-time)/0.1),0,1)
	var height := maxf(2,roundf(44*opening))
	var texture: AtlasTexture = BEAM.get_frame_texture("effect",int((time-0.25)*12)%6)
	var region := texture.region
	var cap := minf(44,length)
	draw_texture_rect_region(texture.atlas,Rect2(nozzle+Vector2(0,-height*0.5),Vector2(cap,height)),Rect2(region.position,Vector2(300,region.size.y)))
	if length > cap:
		draw_texture_rect_region(texture.atlas,Rect2(nozzle+Vector2(cap,-height*0.5),Vector2(length-cap,height)),Rect2(region.position+Vector2(300,0),Vector2(region.size.x-300,region.size.y)))
	# Individually travelling rings make the material read as soapy water.
	for i in 11:
		var phase := fposmod((time-0.25)*1.3+i/11.0,1)
		var at := nozzle+Vector2(phase*length,sin(i*2.3+time*5)*(7+i%4))
		bubble(at,2+i%3)
	for i in 6:
		var phase := fposmod(time*2+i/6.0,1)
		draw_rect(Rect2((nozzle+Vector2(phase*length,12+(i%3)*2)).round(),Vector2(3,1)),Color("e4ffff"))

func _splash() -> void:
	var age := time-0.5
	if age < 0 or age >= 0.9: return
	var origin := Vector2(160,96)
	_water_ripple(origin,age)
	var texture: AtlasTexture = SPLASH.get_frame_texture("effect",mini(5,int(age/0.9*6)))
	var size := (texture.region.size*0.14).round()
	draw_texture_rect(texture,Rect2((origin-Vector2(size.x*0.5,size.y)).round(),size),false)
	for i in 12:
		var a := i*TAU/12
		var radius := 12+age*(44+i%4*6)
		var at := origin+Vector2(cos(a)*radius,sin(a)*radius*0.22-8-age*(14+i%5*5))
		bubble(at,1+i%2)

func _solar() -> void:
	for i in pulses.size():
		var pulse: Vector2 = pulses[i]
		var age := time - pulse.x
		if age < 0.0 or age >= 0.48: continue
		var origin := Vector2(160 + pulse.y * 0.5, 96)
		if use_arcade_effects:
			_arcade_burst(origin, age, 1.0 + i * 0.17)
			continue
		var texture: AtlasTexture = SPLASH.get_frame_texture("effect", mini(5, int(age / 0.08)))
		var size := (texture.region.size * Vector2(0.14, 0.15 + i * 0.035)).round()
		draw_texture_rect(texture, Rect2((origin - Vector2(size.x * 0.5, size.y)).round(), size), false, Color("ffc16f"))
		for j in 6:
			var angle := float(j) * TAU / 6
			var at := origin + Vector2(cos(angle) * age * 93, sin(angle) * age * 32 - (28 + j * 3) * sin(age * PI))
			bubble(at, 2 + j % 2)

func _nova() -> void:
	var nozzle := Vector2(40, 54)
	if time < 0.30:
		bubble(nozzle + Vector2(6, 0), 2.0 + time * 32.0)
		return
	for pulse in pulses:
		var age: float = time - pulse.x
		if age < 0 or age >= 0.18: continue
		if use_arcade_effects:
			draw_texture_rect_region(ARCADE_POP, Rect2(nozzle - Vector2(14, 14), Vector2(28, 28)), Rect2(floorf(age / 0.03) * 32, 0, 32, 32), Color("edbdff"))
			continue
		var texture: AtlasTexture = SPLASH.get_frame_texture("effect", mini(5, int(age / 0.03)))
		var size := (texture.region.size * 0.08).round()
		draw_set_transform(nozzle, PI * 0.5)
		draw_texture_rect(texture, Rect2(Vector2(-size.x * 0.5, -size.y), size), false, Color("eeb0ff"))
		draw_set_transform(Vector2.ZERO)

func _arcade_burst(at: Vector2, age: float, size: float) -> void:
	if age < 0.0 or age >= 0.5: return
	var frame := mini(9, int(age * 20.0))
	var dims := Vector2(94, 56) * size
	draw_texture_rect_region(ARCADE_BURST, Rect2(at - dims * Vector2(0.5, 0.83), dims), Rect2(frame * 128, 0, 128, 80))

func _arcade_beam() -> void:
	var nozzle := Vector2(40, 54)
	var length := maxf(0.0, beam_length * 0.5)
	if time < 0.25:
		var rim := Vector2.ONE * (6 + time * 48)
		draw_texture_rect_region(ARCADE_BUBBLE, Rect2(nozzle - rim * 0.5, rim), Rect2(14, 14, 38, 38), Color("9dedff"))
		return
	if length <= 1.0: return
	for i in 14:
		var phase := fposmod((time - 0.25) * 2.7 + float(i) / 14.0, 1.0)
		var center := nozzle + Vector2(phase * length, sin(time * 16.0 + i * 1.6) * 9.0)
		var rim := Vector2.ONE * minf(length, 18.0 + i % 4 * 3.0)
		draw_texture_rect_region(ARCADE_BUBBLE, Rect2(center - rim * 0.5, rim), Rect2(14, 14, 38, 38), Color("8ceeff"))

func _water_ripple(origin: Vector2, age: float) -> void:
	# Same 220-world-pixel reach, with a low, breaking sheet of water and foam.
	var radius := minf(110,age*155)
	if radius < 4: return
	var settling := clampf((0.9-age)/0.25,0,1)
	for half in 2:
		# Vertical pixel columns avoid degenerate polygons as a ripple grows/settles.
		for x in range(-int(radius),int(radius)+1):
			var angle := acos(clampf(x/radius,-1,1))
			var depth := sin(angle)*radius*0.28*(-1 if half == 0 else 1)
			var foam := (2+pow(maxf(0,sin(angle*13-time*22+half)),3)*5)*settling
			var at := (origin+Vector2(x,depth-2-foam)).round()
			draw_rect(Rect2(at,Vector2(1,maxf(2,roundf(foam+2*settling)))),Color("2995b5"))
			draw_rect(Rect2(at,Vector2(1,3)),Color("74e9ee"))
			draw_rect(Rect2(at,Vector2.ONE),Color("e6ffff"))
		for i in 7:
			var angle := PI+half*PI+(i+0.3)*PI/7
			var at := origin+Vector2(cos(angle)*radius,sin(angle)*radius*0.28-6-settling*(i%3)*2)
			draw_rect(Rect2(at.round(),Vector2(1,2)),Color("b3ffff"))

