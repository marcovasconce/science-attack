shader_type canvas_item;
render_mode unshaded;
uniform float fill_level : hint_range(0.0,1.0) = 0.0;
uniform vec4 liquid_color : source_color = vec4(0.04,0.72,0.97,1.0);
uniform float liquid_time = 0.0;
uniform bool dip_pipe = false;
varying vec4 tint;
void vertex() { tint = COLOR; }
void fragment() {
	vec2 p = UV / TEXTURE_PIXEL_SIZE;
	vec4 original = texture(TEXTURE, UV);
	// Interior of the existing cyan tube. Keep its rim, rounded base and glass highlights.
	float left = 258.0;
	float right = 396.0;
	float bottom = 589.0;
	float dx = abs(p.x-327.0)/69.0;
	float inner_bottom = bottom - 32.0*dx*dx*dx*dx;
	if (p.x > left && p.x < right && p.y > 125.0 && p.y < inner_bottom) {
		vec3 glass = texture(TEXTURE,vec2(p.x,220.0)*TEXTURE_PIXEL_SIZE).rgb;
		float time = floor(liquid_time*8.0)/8.0;
		float surface = bottom-fill_level*422.0 + sin((p.x-left)*0.06+time*3.0)*4.0;
		original.rgb = glass;
		if (fill_level > 0.005 && p.y > surface) {
			original.rgb = liquid_color.rgb * (0.83+0.17*(1.0-dx));
			if (p.y < surface+7.0) original.rgb = mix(liquid_color.rgb,vec3(0.85,1.0,1.0),0.65);
			for (int i=0; i<5; i++) {
				float seed = float(i);
				vec2 bubble = vec2(275.0+mod(seed*27.0,105.0),bottom-fract(time*0.15+seed*0.19)*fill_level*410.0);
				vec2 d = abs(p-bubble);
				if (max(d.x,d.y)<4.0 && max(d.x,d.y)>1.5) original.rgb = vec3(0.82,1.0,1.0);
			}
		}
		if (dip_pipe && abs(p.x-327.0)<13.0 && p.y < 430.0) {
			vec3 metal = abs(p.x-327.0)>8.0 ? vec3(0.22,0.42,0.48) : vec3(0.65,0.84,0.87);
			original.rgb = mix(original.rgb,metal,p.y>surface ? 0.42 : 0.75);
		}
		if (p.x < 280.0 && p.x > 268.0) original.rgb = mix(original.rgb,vec3(0.9,1.0,1.0),0.8);
	}
	COLOR = original*tint;
}
