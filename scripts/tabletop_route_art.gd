extends Node2D
const PIPE = preload("res://assets/third_party/cartoon/industrial/PNG/Default size/platformIndustrial_085.png")
const HUB = preload("res://assets/third_party/cartoon/industrial/PNG/Default size/platformIndustrial_067.png")
const LAMP = preload("res://assets/third_party/cartoon/industrial/PNG/Default size/platformIndustrial_040.png")
@onready var route = get_parent()
var pipe_texture: AtlasTexture
var lamp_texture: AtlasTexture

func _ready() -> void:
	pipe_texture = AtlasTexture.new()
	pipe_texture.atlas = PIPE
	pipe_texture.region = Rect2(10,0,50,70)
	lamp_texture = AtlasTexture.new()
	lamp_texture.atlas = LAMP
	lamp_texture.region = Rect2(10,30,50,40)

func _draw() -> void:
	if pipe_texture == null: return
	# The same exact endpoints drive the shell, water and connection logic.
	for link in 6:
		var ends: PackedVector2Array = route.link_points(link)
		_pipe(ends[0],ends[1])
		_water(ends,route.water_fill[link*2],link)
	for i in 5:
		var at: Vector2 = route.PIPE_POINTS[i]
		for port in route.BASE_PORTS[i]:
			var direction: Vector2 = route.DIRECTIONS[port].rotated(route.pipe_angle(i))
			_pipe(at,at+direction*route.PIPE_RADIUS)
		draw_texture_rect(HUB,Rect2(at-Vector2(15,15),Vector2(30,30)),false,Color("b6d6de"))
		_water(route.water_path(i),route.water_fill[1+i*2],i+6)
	for point in route.VALVE_POINTS:
		draw_line(point-Vector2(0,62),point-Vector2(0,27),Color("546e79"),5)
	draw_line(Vector2(2300,211),Vector2(2420,211),Color("6be8bc") if route.powered else Color("465b66"),3)
	for i in 3:
		var x: float = route.VENTS[i]
		var phase: float = route.vent_phase(i)
		var warning: bool = route.drained and phase >= 1.6 and phase < 2.8
		var active: bool = route.vent_active(i)
		var tint := Color.WHITE if warning or active else Color(0.25,0.35,0.4)
		draw_texture_rect(lamp_texture,Rect2(x-10,182,20,16),false,tint)
		if not active: continue
		var strength := sin((phase-2.8)*PI)
		for puff in 9:
			var rise := fposmod(route.steam_clock*1.3+puff*0.13,1)
			var at := Vector2(x+sin(puff*2.1+route.steam_clock*4)*11,326-rise*132)
			draw_circle(at,5+rise*9,Color(0.8,0.97,1,0.3*strength*(1-rise)))
	if not route.drained:
		for bubble in 7:
			var at := Vector2(3160+bubble*22,265+sin(route.steam_clock*2+bubble)*21)
			draw_arc(at,3+fposmod(route.steam_clock+float(bubble),3),0,TAU,12,Color(0.7,1,0.8,0.5*(1-route.drain_age/2.4)),1)
	# Gentle sparkles make optional finds readable without instructions over every prop.
	for i in 2:
		if not route.batteries[i]: _sparkle(route.BATTERY_POINTS[i]+Vector2(0,-25),i)
	for i in 3:
		if not route.records[i]: _sparkle(route.RECORD_POINTS[i]+Vector2(0,-24),i+2)
	if route.step == route.Step.SAMPLE: _sparkle(route.SAMPLE_POINT+Vector2(0,-25),5)

func _pipe(start: Vector2, end: Vector2) -> void:
	var length := start.distance_to(end)
	if length < 0.1: return
	draw_set_transform((start+end)*0.5,(end-start).angle()-PI*0.5)
	draw_texture_rect(pipe_texture,Rect2(-12,-length*0.5,24,length),false,Color("b6d6de"))
	draw_set_transform(Vector2.ZERO)

func _water(path: PackedVector2Array, fill: float, index: int) -> void:
	if fill <= 0.001: return
	var length := 0.0
	for i in range(1,path.size()): length += path[i-1].distance_to(path[i])
	if length < 0.1: return
	var remaining := length*fill
	var visible_path := PackedVector2Array([path[0]])
	for i in range(1,path.size()):
		var segment := path[i-1].distance_to(path[i])
		if remaining <= segment:
			visible_path.append(path[i-1].lerp(path[i],remaining/segment))
			break
		visible_path.append(path[i])
		remaining -= segment
	draw_polyline(visible_path,Color("189acb"),16,true)
	draw_polyline(visible_path,Color("53d6f7"),12,true)
	if visible_path.size() > 2: draw_circle(visible_path[1],6,Color("53d6f7"))
	var gloss := PackedVector2Array()
	for point in visible_path: gloss.append(point+Vector2(-2,-2))
	draw_polyline(gloss,Color(0.76,0.98,1,0.65),2,true)
	if length*fill > 14:
		var travel := 6+fposmod(route.steam_clock*0.6+index*0.17,1)*(length*fill-12)
		for i in range(1,path.size()):
			var segment := path[i-1].distance_to(path[i])
			if travel <= segment:
				draw_circle(path[i-1].lerp(path[i],travel/segment),2,Color("d8fbff"))
				break
			travel -= segment

func _sparkle(at: Vector2, index: int) -> void:
	var brightness: float = 0.4+sin(route.steam_clock*3+index)*0.25
	draw_line(at-Vector2(3,0),at+Vector2(3,0),Color(0.8,1,0.8,brightness),2)
	draw_line(at-Vector2(0,3),at+Vector2(0,3),Color(0.8,1,0.8,brightness),2)
