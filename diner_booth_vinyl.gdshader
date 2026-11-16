shader_type spatial;
render_mode cull_disabled;

uniform sampler2D original_atlas : source_color, filter_linear_mipmap;
varying vec3 seat_position;
varying vec3 seat_normal;

void vertex() {
	seat_position = VERTEX;
	seat_normal = NORMAL;
}

void fragment() {
	vec3 atlas = texture(original_atlas, UV).rgb;
	vec2 pixel = UV * 256.0;
	// The upholstery occupies several islands in the original booth atlas.
	bool upper_left = pixel.x < 99.0 && pixel.y < 142.0 && (pixel.x < 82.0 || pixel.y < 52.0 || pixel.y > 81.0);
	bool lower_center = pixel.x >= 91.0 && pixel.x < 156.0 && pixel.y >= 143.0;
	bool narrow_strip = pixel.x >= 133.0 && pixel.x < 151.0 && pixel.y > 81.0 && pixel.y < 143.0;
	bool right_edge = pixel.x >= 222.0 && pixel.y < 143.0;
	float fabric = float(upper_left || lower_center || narrow_strip || right_edge);
	float grain = mix(0.96, 1.03, smoothstep(0.06, 0.43, atlas.r));
	float back = smoothstep(0.13, 0.25, seat_position.y) * smoothstep(0.60, 0.86, abs(seat_normal.x));
	// Two diagonal seam families meet at the staggered button positions.
	vec2 panel = vec2(seat_position.z / 0.36, (seat_position.y - 0.36) / 0.23);
	vec2 diagonal = vec2(panel.x + panel.y * 0.5, panel.x - panel.y * 0.5);
	vec2 seam_distance = abs(fract(diagonal + 0.5) - 0.5);
	float seam = 1.0 - smoothstep(0.016, 0.069, min(seam_distance.x, seam_distance.y));
	vec2 grid = round(diagonal);
	vec2 button_center = vec2((grid.x + grid.y) * 0.5, grid.x - grid.y);
	float radius = length((panel - button_center) * vec2(0.36, 0.23));
	float dimple = 1.0 - smoothstep(0.018, 0.078, radius);
	float button = 1.0 - smoothstep(0.012, 0.021, radius);
	float highlight = 1.0 - smoothstep(0.003, 0.014, length((panel - button_center) * vec2(0.36, 0.23) - vec2(-0.005, 0.006)));
	float tuft = 1.04 - 0.21 * seam - 0.40 * dimple + 0.52 * button + 0.24 * highlight;
	vec3 red = vec3(0.59, 0.023, 0.034) * grain * mix(1.0, tuft, back);
	float side_cap = step(0.9, abs(seat_normal.z)) * step(1.13, abs(seat_position.z));
	float top = smoothstep(0.985, 1.015, seat_position.y);
	float frame = max(side_cap, top) * step(-0.09, seat_position.y);
	float upholstered = fabric * (1.0 - frame);
	ALBEDO = mix(vec3(0.018, 0.018, 0.02), red, upholstered);
	ROUGHNESS = mix(0.91, mix(0.34, 0.46, dimple * back), upholstered);
}
