shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, cull_back;

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap;
uniform vec4 base_color : source_color = vec4(1.0);
uniform float dissolve : hint_range(0.0, 1.0) = 0.0;
varying vec3 body_position;

float hash(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

float noise3(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i), hash(i + vec3(1,0,0)), f.x),
		mix(hash(i + vec3(0,1,0)), hash(i + vec3(1,1,0)), f.x), f.y),
		mix(mix(hash(i + vec3(0,0,1)), hash(i + vec3(1,0,1)), f.x),
		mix(hash(i + vec3(0,1,1)), hash(i + vec3(1,1,1)), f.x), f.y), f.z);
}

void vertex() {
	body_position = VERTEX;
	float pull = dissolve * dissolve;
	VERTEX.x += sin(VERTEX.y * 11.0 + dissolve * 8.0) * pull * 0.13;
	VERTEX.z += cos(VERTEX.y * 9.0 + VERTEX.x * 13.0) * pull * 0.09;
	VERTEX.y += pull * 0.17;
}

void fragment() {
	vec4 color = texture(albedo_texture, UV) * base_color;
	vec3 drifting = body_position * vec3(5.0, 2.5, 5.0) - vec3(dissolve * 0.6, dissolve * 1.8, 0.0);
	float patches = mix(noise3(drifting), noise3(drifting * 2.4), 0.25);
	float threshold = mix(-0.15, 1.1, dissolve);
	float density = smoothstep(threshold - 0.16, threshold + 0.10, patches);
	ALBEDO = mix(color.rgb, vec3(0.025, 0.03, 0.04), smoothstep(0.0, 0.5, dissolve));
	ROUGHNESS = 0.95;
	ALPHA = color.a * density * (1.0 - dissolve * 0.65);
}
