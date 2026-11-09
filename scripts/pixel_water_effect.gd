extends Node2D
## Animated bitmap effects and soap bubbles on a deliberately coarse 2x pixel grid.
const BEAM = preload("res://assets/animations/soap_water_beam.tres")
const SPLASH = preload("res://assets/animations/soap_water_splash.tres")
var mode := ""
var time := 0.0
var beam_length := 560.0

func _draw() -> void:
	if mode == "bubbles2": _beam()
	elif mode == "brush2": _splash()

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

