shader_type canvas_item;

float area_weight(vec2 pixel, vec2 center, vec2 radius) {
	vec2 distance_to_center = abs(pixel - center) / radius;
	return 1.0 - smoothstep(0.63, 1.0, max(distance_to_center.x, distance_to_center.y));
}

vec2 drift(vec2 pixel, vec2 center, vec2 radius, float phase) {
	return vec2(round(sin(phase) * 2.0), round(cos(phase) * 3.0))
		* area_weight(pixel, center, radius);
}

void fragment() {
	vec2 pixel = UV * vec2(640.0, 360.0);
	float clock = TIME * 2.0;
	vec2 offset = drift(pixel, vec2(224.0, 233.0), vec2(28.0, 28.0), clock);
	offset += drift(pixel, vec2(221.0, 311.0), vec2(46.0, 38.0), clock + 2.2);
	offset += drift(pixel, vec2(590.0, 186.0), vec2(43.0, 29.0), clock + 3.5);
	offset += drift(pixel, vec2(544.0, 264.0), vec2(53.0, 43.0), clock + 1.1);

	// The orbit is baked into the backdrop. Move only its exposed segments.
	float orbit = area_weight(pixel, vec2(280.0, 39.0), vec2(26.0, 10.0));
	orbit += area_weight(pixel, vec2(373.0, 34.0), vec2(24.0, 16.0));
	orbit += area_weight(pixel, vec2(323.0, 162.0), vec2(48.0, 8.0));
	offset.y += round(sin(clock * 0.8) * 2.0) * orbit;
	COLOR = texture(TEXTURE, (pixel - offset) / vec2(640.0, 360.0));
}
