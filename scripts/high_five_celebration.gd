extends Node2D
const ART = preload("res://assets/animations/duo_high_five.png")
var age := 0.0
var pose: Sprite2D
var contact_played := false
func _ready() -> void:
	z_index = 30
	pose = Sprite2D.new()
	pose.texture = ART
	pose.show_behind_parent = true
	pose.hframes = 4
	pose.vframes = 2
	pose.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pose.scale = Vector2.ONE*0.36
	pose.offset.y = ART.get_height()/4.0-437.0
	add_child(pose)
func advance(dt: float) -> void:
	age += dt
	# Hold the contact for the star, then show the landing and happy pose.
	pose.frame = mini(7,int(age/0.18)) if age < 0.72 else (4 if age < 1.1 else mini(7,5+int((age-1.1)/0.18)))
	if age >= 0.54 and not contact_played:
		contact_played = true
		GameAudio.effect("confirm",global_position)
	queue_redraw()
func _draw() -> void:
	if age < 0.54 or age > 1.1: return
	var glow := sin((age-0.54)/0.56*PI)
	if glow < 0.12: return
	var center := Vector2(0,-50)
	var poly := PackedVector2Array()
	for i in 8:
		var angle := i*TAU/8
		poly.append((center+Vector2.from_angle(angle)*(23 if i%2==0 else 5)*glow).round())
	draw_colored_polygon(poly,Color("75ecff"))
	for i in poly.size(): poly[i] = center+(poly[i]-center)*0.7
	draw_colored_polygon(poly,Color.WHITE)
	for i in 4:
		var at := center+Vector2.from_angle(i*PI/2+0.7)*26
		draw_rect(Rect2(at.round(),Vector2(2,2)),Color("fff6b7"))

