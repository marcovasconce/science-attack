shader_type canvas_item;
// Pixelate-to-solid cover. As progress rises the screen blocks grow and the
// color fades in, ending fully covered. It samples the screen texture so the
// dissolve reads as the scene itself breaking into blocks.

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;

void fragment() {
	// Grow square blocks in viewport pixels even on a wide canvas.
	vec2 resolution = 1.0 / SCREEN_PIXEL_SIZE;
	float block_size = mix(1.0, 48.0, smoothstep(0.06, 0.85, progress));
	vec2 grid = (floor(SCREEN_UV * resolution / block_size) + vec2(0.5)) * block_size / resolution;
	vec3 scene = texture(screen_tex, grid).rgb;
	// crossfade from the pixelated scene toward the solid cover color
	vec3 rgb = mix(scene, COLOR.rgb, smoothstep(0.38, 1.0, progress));
	float a = smoothstep(0.0, 0.38, progress);
	COLOR = vec4(rgb, a);
}
