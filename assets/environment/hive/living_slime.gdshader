shader_type canvas_item;

uniform float clock = 0.0;
uniform sampler2D pit_rock : filter_nearest, repeat_disable;
uniform vec4 pit_centers;
uniform float pit_half_width = 23.0;
varying vec2 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

vec3 recess(vec3 floor_color, vec2 at) {
	vec4 offsets = at.x - pit_centers;
	vec4 distance_to_pits = abs(offsets);
	float distance_to_center = min(min(distance_to_pits.x, distance_to_pits.y), min(distance_to_pits.z, distance_to_pits.w));
	if (distance_to_center > 35.0 || at.y < 235.0) {
		return floor_color;
	}

	float lane = smoothstep(235.0, 247.0, at.y);
	float near_end = smoothstep(335.0, 359.0, at.y);
	float chipped_edge = sin(floor(at.y / 3.0) * 1.37) * 2.1;
	float rim = mix(8.0, pit_half_width, lane) + near_end * 4.0 + chipped_edge;
	float edge = rim - distance_to_center;
	if (edge <= 0.0) {
		return floor_color * mix(0.78, 1.0, smoothstep(0.0, 4.0, -edge));
	}

	// Replace the floor pixels inside the opening. The original rock sprite
	// supplies the lip texture; the sides fall away into the unlit center.
	float side = distance_to_center == distance_to_pits.x ? offsets.x
		: (distance_to_center == distance_to_pits.y ? offsets.y
		: (distance_to_center == distance_to_pits.z ? offsets.z : offsets.w));
	float wall_depth = clamp(edge / (side < 0.0 ? 7.0 : 15.0), 0.0, 1.0);
	vec2 rock_uv = vec2(mix(0.27, 0.43, wall_depth), clamp((at.y - 229.0 + wall_depth * 24.0) / 150.0, 0.0, 1.0));
	vec4 rock = texture(pit_rock, rock_uv);
	vec3 inner_wall = mix(floor_color * 0.64, rock.rgb * vec3(0.75, 0.86, 0.94), rock.a * 0.53);
	vec3 depth = vec3(0.012, 0.036, 0.026);
	vec3 shaded_wall = mix(inner_wall, depth, pow(wall_depth, 1.3));
	float ledge = 1.0 - smoothstep(0.4, 1.55, edge);
	return mix(shaded_wall, floor_color * vec3(0.86, 1.10, 0.97), ledge * 0.8);
}

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	float sac = smoothstep(0.24,0.5,base.r)*step(base.r*1.2,base.g);
	vec2 wobble = vec2(sin(UV.y*19.0+clock*1.6),cos(UV.x*24.0+clock*1.4));
	vec2 offset = floor(wobble*1.8*sac+0.5)*TEXTURE_PIXEL_SIZE;
	vec4 color = texture(TEXTURE,clamp(UV+offset,vec2(0.0),vec2(1.0)));
	color.rgb *= 1.0+sac*sin(clock*2.1+UV.x*13.0)*0.09;
	if (world_position.y >= 235.0) {
		color = vec4(recess(base.rgb, world_position), base.a);
	}
	COLOR = color;
}
