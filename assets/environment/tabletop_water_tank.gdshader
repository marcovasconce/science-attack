shader_type canvas_item;
uniform float fill_level : hint_range(0.0,1.0) = 0.0;
uniform float water_time = 0.0;
void fragment() {
	vec4 base = texture(TEXTURE,UV);
	bool inside = UV.x > 0.24 && UV.x < 0.76 && UV.y > 0.15 && UV.y < 0.85;
	if (inside) {
		float top = mix(0.85,0.15,fill_level)+sin(UV.x*24.0+water_time*3.0)*0.008;
		base = vec4(0.52,0.69,0.73,0.35);
		if (fill_level > 0.001 && UV.y >= top) {
			base = vec4(0.14,0.68,0.97,0.96);
			if (UV.y < top+0.022) base.rgb = vec3(0.65,0.94,1.0);
			float bubble = length((UV-vec2(0.45+sin(water_time)*0.12,0.8-mod(water_time*0.13,0.6)))*vec2(1.0,1.0));
			if (bubble < 0.024) base.rgb = vec3(0.64,0.94,1.0);
		}
	}
	COLOR = base;
}
