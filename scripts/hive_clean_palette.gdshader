shader_type canvas_item;
uniform float cleaned : hint_range(0.0,1.0) = 0.0;
void fragment() {
	vec4 original = COLOR;
	float light = dot(original.rgb,vec3(0.26,0.61,0.13));
	vec3 blue = mix(vec3(0.025,0.065,0.13),vec3(0.50,0.87,1.0),clamp(light*1.18,0.0,1.0));
	// Keep texture detail and highlights, replace the contaminated olive palette.
	blue += max(original.rgb-vec3(0.68),vec3(0.0))*0.22;
	COLOR = vec4(mix(original.rgb,blue,cleaned),original.a);
}

