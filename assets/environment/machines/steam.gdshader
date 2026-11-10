shader_type canvas_item;
render_mode unshaded;
uniform float frame_index = 0.0;
varying vec4 tint;
void vertex() { tint = COLOR; }
void fragment() {
	vec4 vapor = texture(TEXTURE,UV);
	vec2 local_uv = vec2(UV.x*4.0-frame_index,UV.y*2.0);
	float sides = 1.0-smoothstep(0.24,0.49,abs(local_uv.x-0.5));
	float top = smoothstep(0.0,0.18,local_uv.y);
	float base = 1.0-smoothstep(0.94,1.0,local_uv.y);
	COLOR = vec4(vec3(0.84,0.94,0.98),vapor.a*sides*top*base*0.42)*tint;
}
