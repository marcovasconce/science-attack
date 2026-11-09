shader_type canvas_item;
render_mode unshaded;
uniform float liquid_time = 0.0;
// Pixel coordinates in the shared, unmodified PNG: left, surface, right, bottom.
uniform vec4 liquid_bounds = vec4(258.0, 315.0, 396.0, 590.0);
varying vec4 tint;

void vertex() {
	tint = COLOR;
}

void fragment() {
	vec2 pixel = UV / TEXTURE_PIXEL_SIZE;
	vec4 original = texture(TEXTURE,UV);
	vec2 center = (liquid_bounds.xy+liquid_bounds.zw)*0.5;
	float width = liquid_bounds.z-liquid_bounds.x;
	float height = liquid_bounds.w-liquid_bounds.y;
	if (pixel.x > liquid_bounds.x && pixel.x < liquid_bounds.z && pixel.y > liquid_bounds.y-12.0 && pixel.y < liquid_bounds.w-16.0) {
		float wave = sin((pixel.x-liquid_bounds.x)/width*6.283+liquid_time*2.4)*7.0;
		float surface = exp(-abs(pixel.y-liquid_bounds.y)/32.0);
		vec2 moved = UV+vec2(0.0,wave*surface)*TEXTURE_PIXEL_SIZE;
		original = texture(TEXTURE,moved);
		for (int i=0;i<6;i++) {
			float seed = float(i);
			float rise = fract(liquid_time*(0.11+seed*0.009)+seed*0.173);
			vec2 bubble = vec2(center.x+sin(seed*2.37+liquid_time*0.7)*width*0.27,liquid_bounds.w-22.0-rise*(height-44.0));
			vec2 d = abs(pixel-bubble);
			float radius = 4.0+mod(seed,3.0)*2.0;
			float square_distance = max(d.x,d.y);
			if (square_distance<radius && square_distance>radius-2.5) {
				original.rgb = mix(original.rgb,vec3(0.84,1.0,0.99),0.65);
			}
		}
	}
	COLOR = vec4(original.rgb,original.a)*tint;
}
