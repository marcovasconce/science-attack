extends Node2D
## Draws on a native pixel canvas. The original avatar textures stay untouched.
const BRUSH = preload("res://assets/animations/toothbrush_pixel.tres")
const MAX_ARMED = preload("res://assets/animations/max_armed_poses.tres")
const AMANDA_ARMED = preload("res://assets/animations/amanda_armed_poses.tres")
const Motion = preload("res://scripts/brush_motion.gd")
const SWINGS = Motion.ANGLES
const BRUSH_RECT := Rect2(-4,-6,34,8)
var frames: SpriteFrames
var animation: StringName = &"idle"
var frame := 0
var amanda := false
var origin := Vector2(48,64)

func _draw() -> void:
	if frames != null: paint(self,frames,animation,frame,origin,amanda)

static func paint(canvas: CanvasItem, sprites: SpriteFrames, anim: StringName, index: int, foot: Vector2, pink: bool) -> void:
	var name := String(anim)
	if not sprites.has_animation(anim): return
	index = clampi(index,0,sprites.get_frame_count(anim)-1)
	# These are complete newly drawn armed sprites, including both gripping arms.
	if name in ["brush_idle","brush_run","brush_jump"] or name.begins_with("bubbles_"):
		_paint_carried(canvas,name,index,foot,pink)
		return
	var body := sprites.get_frame_texture(anim,index)
	if name == "brush_spin":
		_paint_spin(canvas,body,index,foot,pink)
		return
	var hand := hand_offset(body)
	var angle := -35.0
	var swing: bool = SWINGS.has(name)
	var body_origin := foot
	var lean := 0.0
	var ultimate := name == "brush_ultimate"
	var ultimate_angles := [-35,-60,-100,-130,-105,-30,50,75,65,30,-5,-35]
	if ultimate:
		angle = ultimate_angles[index]
		body_origin.y += [0,-2,-5,-8,-12,-8,0,2,3,1,0,0][index]
		lean = deg_to_rad(float([0,-5,-10,-12,-10,0,14,20,14,8,2,0][index]))
	if swing:
		angle = float(SWINGS[name][index])
		body_origin += Motion.body_offset(name,index)
		lean = deg_to_rad(float(Motion.LEAN[name][index]))
	var grip := (body_origin+hand.rotated(lean)).round()
	var contact := (swing and Motion.contact_active(name,float(index)/sprites.get_frame_count(anim))) or (ultimate and index in [5,6,7,8])
	if contact:
		var previous := deg_to_rad(float(ultimate_angles[maxi(0,index-2)] if ultimate else SWINGS[name][maxi(0,index-2)]))
		var current := deg_to_rad(angle)
		# Square, unfiltered streaks are drawn behind the weapon at the contact arc.
		for ring in 2:
			var radius := 28.0+ring*3
			for step in 6:
				var a := lerpf(previous,current,step/6.0)
				var b := lerpf(previous,current,(step+1)/6.0)
				canvas.draw_line((grip+Vector2.from_angle(a)*radius).round(),(grip+Vector2.from_angle(b)*radius).round(),Color("c8fcff") if ring == 0 else Color("42cadb"),2 if name == "brush_slam" else 1,false)
	# Lean around the feet; the small canvas keeps all rotated edges pixelated.
	canvas.draw_set_transform(body_origin,lean)
	canvas.draw_texture(body,Vector2(-16,-31))
	canvas.draw_set_transform(Vector2.ZERO)
	if contact and name != "brush_air":
		for i in 3:
			canvas.draw_rect(Rect2(foot+Vector2(-5-i*4-index%3,-1-i%2),Vector2(2,1)),Color("658396"))
	if name.begins_with("brush_"):
		var second_hand := (grip+Vector2.from_angle(deg_to_rad(angle))*6).round()
		_draw_arm(canvas,body_origin+Vector2(-3,-10).rotated(lean),second_hand,pink)
		_draw_arm(canvas,body_origin+Vector2(3,-10).rotated(lean),grip,pink)
		canvas.draw_set_transform(grip,deg_to_rad(angle))
		canvas.draw_texture_rect(BRUSH,BRUSH_RECT,false)
		canvas.draw_set_transform(Vector2.ZERO)
		_draw_hand(canvas,grip,pink)
		_draw_hand(canvas,second_hand,pink)
		if contact:
			for i in 3:
				var mote := grip+Vector2.from_angle(deg_to_rad(angle-12+i*10))*(33+i*2)
				canvas.draw_rect(Rect2(mote.round(),Vector2(2,2)),Color("e8ffff"))

static func _paint_carried(canvas: CanvasItem, name: String, index: int, foot: Vector2, pink: bool) -> void:
	var armed: SpriteFrames = AMANDA_ARMED if pink else MAX_ARMED
	var weapon := "brush" if name.begins_with("brush_") else "bubbles"
	var state := "run" if name.ends_with("_run") or name.ends_with("_jump") else "idle"
	var pose_name := weapon+"_"+state
	var pose_index := index%armed.get_frame_count(pose_name)
	var offset := Vector2.ZERO
	if name in ["bubbles_attack","bubbles_special"]:
		pose_index = 0
		offset.x = [0,-1,-2,0][index%4]
	elif name == "bubbles_ultimate":
		pose_index = 0
		offset = Vector2([0,0,-1,-2,-1,0,0,0][index%8],[0,1,2,2,1,0,0,0][index%8])
	var texture: AtlasTexture = armed.get_frame_texture(pose_name,pose_index)
	var size: Vector2 = texture.get_meta("draw_size")
	var anchor: Vector2 = texture.get_meta("foot_anchor")
	canvas.draw_texture_rect(texture,Rect2((foot+offset-anchor).round(),size.round()),false)
	if name == "brush_run" and index%3 == 1:
		# A couple of floor pixels reinforce the bristles dragging behind the feet.
		canvas.draw_rect(Rect2((foot+Vector2(-24,1)).round(),Vector2(2,1)),Color("678b99"))
		canvas.draw_rect(Rect2((foot+Vector2(-28,0)).round(),Vector2(1,1)),Color("8fa9af"))

static func _draw_arm(canvas: CanvasItem, shoulder: Vector2, hand: Vector2, pink: bool) -> void:
	var elbow := shoulder.lerp(hand,0.5)+Vector2(-2,2)
	var outline := Color("04193f") if pink else Color("2a304e")
	var color := Color("b827f5") if pink else Color("94a0ba")
	for segment in [[shoulder,elbow],[elbow,hand]]:
		canvas.draw_line(segment[0].round(),segment[1].round(),outline,4,false)
		canvas.draw_line(segment[0].round(),segment[1].round(),color,2,false)

static func _paint_spin(canvas: CanvasItem, body: Texture2D, index: int, foot: Vector2, pink: bool) -> void:
	var angle := index*TAU/12.0
	var center := foot+Vector2(0,-14)
	var grip := (center+Vector2(cos(angle)*4,sin(angle)*2)).round()
	for ring in 2:
		var points := PackedVector2Array()
		for i in 13:
			var a := angle-PI*0.85+i*PI*0.85/12.0
			points.append((center+Vector2(cos(a)*(33+ring*3),sin(a)*(20+ring*2))).round())
		canvas.draw_polyline(points,Color("f0ffff") if ring == 0 else Color("48d3e3"),2 if ring == 0 else 1,false)
	var weapon_angle := atan2(sin(angle)*0.65,cos(angle))
	if sin(angle)<0: _spin_brush(canvas,grip,weapon_angle,pink)
	var turn := (0.5+absf(cos(angle))*0.5)*(-1 if cos(angle)<0 else 1)
	canvas.draw_set_transform(foot+Vector2(0,-index%2),0,Vector2(turn,1))
	canvas.draw_texture(body,Vector2(-16,-31))
	canvas.draw_set_transform(Vector2.ZERO)
	if sin(angle)>=0: _spin_brush(canvas,grip,weapon_angle,pink)
	for i in 3:
		var a := angle-i*0.4
		canvas.draw_rect(Rect2((center+Vector2(cos(a)*38,sin(a)*24)).round(),Vector2(2,2)),Color("d9ffff"))

static func _spin_brush(canvas: CanvasItem, grip: Vector2, angle: float, pink: bool) -> void:
	canvas.draw_set_transform(grip,angle)
	canvas.draw_texture_rect(BRUSH,BRUSH_RECT,false)
	canvas.draw_set_transform(Vector2.ZERO)
	_draw_hand(canvas,grip,pink)
	_draw_hand(canvas,(grip+Vector2.from_angle(angle)*6).round(),pink)

static func hand_offset(body: AtlasTexture) -> Vector2:
	# Anchors are the front glove positions in the untouched 32px source sheets.
	var sheet := body.atlas.resource_path
	var index := int(body.region.position.x/32)
	if "Attack1" in sheet: return [Vector2(4,-5),Vector2(6,-8),Vector2(12,-10),Vector2(5,-6)][index]
	if "Attack2" in sheet: return [Vector2(4,-5),Vector2(5,-6),Vector2(7,-7),Vector2(7,-6),Vector2(10,-9),Vector2(5,-6)][index]
	if "Run" in sheet: return [Vector2(5,-6),Vector2(5,-7),Vector2(7,-6),Vector2(5,-5),Vector2(4,-5),Vector2(5,-6)][index]
	if "Walk+Attack" in sheet: return [Vector2(5,-8),Vector2(7,-9),Vector2(12,-10),Vector2(10,-9),Vector2(7,-8),Vector2(5,-6)][index]
	if "Push" in sheet: return Vector2(7,-9)
	if "Jump" in sheet: return Vector2(5,-8)
	return Vector2(4,-5)

static func _draw_hand(canvas: CanvasItem, at: Vector2, pink: bool) -> void:
	canvas.draw_rect(Rect2(at+Vector2(-2,-1),Vector2(4,4)),Color("04193f") if pink else Color("2a304e"))
	canvas.draw_rect(Rect2(at+Vector2(-1,-1),Vector2(3,3)),Color("780bf7") if pink else Color("667291"))
	canvas.draw_rect(Rect2(at+Vector2(-1,-1),Vector2(2,1)),Color("d840fb") if pink else Color("94a0ba"))
