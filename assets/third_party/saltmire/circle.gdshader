shader_type canvas_item;
// Circle iris wipe. progress 0 = fully open (transparent), 1 = fully closed (covered).
// Covers from the edges inward to the center. Aspect-corrected so it stays round.

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float feather : hint_range(0.0, 0.5) = 0.02;

void fragment() {
	// viewport resolution from the screen pixel size, to correct aspect ratio
	vec2 res = 1.0 / SCREEN_PIXEL_SIZE;
	float aspect = res.x / res.y;
	vec2 p = UV - vec2(0.5);
	p.x *= aspect;                 // stretch x so distance is circular
	float max_r = length(vec2(0.5 * aspect, 0.5)); // corner distance
	float dist = length(p) / max_r;                // normalized 0..1
	float radius = 1.0 - progress;                 // shrinks as we cover
	float a = smoothstep(radius - feather, radius, dist);
	a = progress <= 0.0 ? 0.0 : (progress >= 1.0 ? 1.0 : a);
	COLOR = vec4(COLOR.rgb, a);
}
