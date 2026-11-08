shader_type spatial;
render_mode cull_disabled;
uniform float frying = 0.0;
void vertex() {
	VERTEX.y += sin(VERTEX.x * 43.0 + TIME * 3.0) * cos(VERTEX.z * 39.0 - TIME * 2.0) * (0.0007 + frying * 0.0015);
}
void fragment() {
	float ripple = sin(UV.x * 65.0 + TIME * 2.5) * cos(UV.y * 53.0 - TIME * 1.7);
	ALBEDO = mix(vec3(0.48, 0.32, 0.025), vec3(0.76, 0.58, 0.08), 0.5 + ripple * 0.15);
	ROUGHNESS = 0.24;
	METALLIC = 0.12;
	SPECULAR = 0.65;
}

