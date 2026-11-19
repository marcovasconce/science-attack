shader_type canvas_item;
// Preserve the tutorial panels and their contrast, shifting only the environment.
void fragment() {
	vec4 source = COLOR;
	float light = dot(source.rgb, vec3(0.22, 0.56, 0.22));
	vec3 green = vec3(light * 0.72, light * 1.22, light * 0.68);
	COLOR = vec4(mix(source.rgb, green, 0.78), source.a);
}
