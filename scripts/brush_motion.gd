extends RefCounted
## Shared choreography, sampled on the combat clock and rendered on the pixel grid.
const ANGLES := {
	"brush_attack": [-35,-50,-75,-92,-35,10,28,42,22,-3,-20,-35],
	"brush_rise": [-5,28,56,68,50,12,-35,-72,-100,-85,-55,-35],
	"brush_slam": [-35,-50,-75,-100,-115,-100,-70,-18,35,65,55,15,-15,-35],
	"brush_air": [-35,-70,-105,-80,-30,15,48,60,0,-35],
}
const LEAN := {
	"brush_attack": [0,-4,-8,-10,0,8,14,14,8,4,0,0],
	"brush_rise": [0,0,-8,-12,-5,0,-6,-10,-6,0,0,0],
	"brush_slam": [0,-5,-10,-12,-14,-10,0,12,18,20,15,8,3,0],
	"brush_air": [-6,-14,-18,-8,6,15,22,18,6,0],
}
const BODY_X := {
	"brush_attack": [0,-1,-2,-2,0,2,3,3,2,1,0,0],
	"brush_rise": [0,-1,-2,-2,-1,0,1,2,2,1,0,0],
	"brush_slam": [0,-1,-1,-2,-2,-1,0,2,3,3,2,1,0,0],
	"brush_air": [0,-1,-2,-1,0,2,3,2,1,0],
}
const BODY_Y := {
	"brush_attack": [0,1,1,1,0,0,0,0,0,0,0,0],
	"brush_rise": [0,1,3,3,1,-1,-3,-4,-3,-1,0,0],
	"brush_slam": [0,1,-1,-3,-4,-5,-3,-1,1,3,3,2,1,0],
	"brush_air": [0,0,0,0,0,0,0,0,0,0],
}
const DURATION := {"brush_attack":0.56,"brush_rise":0.58,"brush_slam":0.74,"brush_air":0.52}
const CONTACT := {"brush_attack":Vector2(4.0/12,9.0/12),"brush_rise":Vector2(4.0/12,9.0/12),"brush_slam":Vector2(6.0/14,11.0/14),"brush_air":Vector2(3.0/10,8.0/10)}
const STEP_TIME := [0.0,0.10,0.25,0.42,0.62,0.80,1.0]
const STEP_DISTANCE := {
	"brush_attack": [0,-2,-3,4,14,16,16],
	"brush_rise": [0,0,-2,2,8,10,10],
	"brush_slam": [0,-1,-2,-1,12,18,18],
	"brush_air": [0,0,0,1,5,8,8],
}

static func body_offset(animation: String, frame: int) -> Vector2:
	return Vector2(BODY_X[animation][frame],BODY_Y[animation][frame])

static func contact_active(animation: String, progress: float) -> bool:
	var window: Vector2 = CONTACT[animation]
	return progress >= window.x and progress < window.y

static func displacement(animation: String, progress: float) -> float:
	progress = clampf(progress,0,1)
	var distances: Array = STEP_DISTANCE[animation]
	for i in range(1,STEP_TIME.size()):
		if progress <= STEP_TIME[i]:
			return lerpf(float(distances[i-1]),float(distances[i]),inverse_lerp(STEP_TIME[i-1],STEP_TIME[i],progress))
	return float(distances[-1])
