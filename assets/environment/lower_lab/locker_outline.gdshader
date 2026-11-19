shader_type canvas_item;
uniform float pulse = 1.0;
void fragment() {
	vec4 base = texture(TEXTURE, UV);
	vec2 step_uv = TEXTURE_PIXEL_SIZE * 2.0;
	float edge = max(max(texture(TEXTURE,UV+vec2(step_uv.x,0.0)).a,texture(TEXTURE,UV-vec2(step_uv.x,0.0)).a),max(texture(TEXTURE,UV+vec2(0.0,step_uv.y)).a,texture(TEXTURE,UV-vec2(0.0,step_uv.y)).a));
	COLOR = mix(vec4(1.0,0.82,0.12,edge*pulse),base,step(0.3,base.a));
}
