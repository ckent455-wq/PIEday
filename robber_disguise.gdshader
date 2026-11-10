shader_type spatial;

uniform sampler2D original_texture : source_color, filter_nearest;
uniform bool head = false;
uniform vec3 jacket = vec3(0.075, 0.095, 0.12);

void fragment() {
	vec3 original = texture(original_texture, UV).rgb;
	float shade = mix(0.48, 1.35, dot(original, vec3(0.299, 0.587, 0.114)));
	if (head) {
		vec2 eye_slot = (UV - vec2(0.5, 0.432)) / vec2(0.295, 0.058);
		float opening = 1.0 - smoothstep(0.87, 1.0, length(eye_slot));
		vec3 fabric = vec3(0.028, 0.033, 0.042) * shade;
		ALBEDO = mix(fabric, original, opening);
	} else {
		bool skin = original.r > original.g * 1.10 && original.g > original.b * 1.09;
		ALBEDO = skin ? original * 0.65 : jacket * shade;
	}
	ROUGHNESS = 0.94;
}
