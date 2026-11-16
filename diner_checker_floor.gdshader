shader_type spatial;
render_mode cull_disabled;

varying vec2 floor_position;

void vertex() {
	floor_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	vec2 tile = floor_position / 0.44;
	vec2 cell = floor(tile);
	float checker = mod(cell.x + cell.y, 2.0);
	float variation = fract(sin(dot(cell, vec2(12.9898, 78.233))) * 43758.5453);
	vec3 cream = vec3(0.83, 0.76, 0.66);
	vec3 charcoal = vec3(0.029, 0.024, 0.028);
	vec3 color = mix(cream, charcoal, checker) * mix(0.94, 1.04, variation);
	vec2 edge = min(fract(tile), 1.0 - fract(tile));
	float grout = smoothstep(0.0, 0.015, min(edge.x, edge.y));
	float footprint = max(fwidth(tile.x), fwidth(tile.y));
	ALBEDO = mix(mix(vec3(0.18, 0.16, 0.15), color, grout), (cream + charcoal) * 0.5, smoothstep(0.4, 1.0, footprint));
	ROUGHNESS = 0.29;
}
