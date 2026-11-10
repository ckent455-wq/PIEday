shader_type spatial;

uniform sampler2D uniform_texture : source_color, filter_nearest;
uniform bool blue_outfit = false;
uniform vec3 skin_tint = vec3(1.0);
varying vec2 body_position;

void vertex() {
	body_position = VERTEX.xy;
}

void fragment() {
	vec3 color = texture(uniform_texture, UV).rgb;
	float height = body_position.y;
	bool blue = color.b > color.r * 1.4 && color.g > color.r * 1.3;
	bool red = color.r > color.g * 1.8 && color.g < color.b * 1.28;
	bool dark_trousers = height < 1.02 && color.r < 0.18 && color.r > color.g * 1.12;
	if ((blue_outfit && blue) || (!blue_outfit && (red || blue || dark_trousers))) {
		bool sleeve = height > 0.86 && abs(body_position.x) > 0.19;
		bool shirt = blue_outfit ? height > 1.06 : red && (height > 1.06 || sleeve);
		float shade = max(color.r, max(color.g, color.b));
		vec3 cream = vec3(0.86, 0.74, 0.52);
		vec3 charcoal = vec3(0.09, 0.12, 0.14);
		color = (shirt ? cream : charcoal) * mix(0.44, 1.0, sqrt(shade));
	} else if (height > 0.72 && color.r > color.g * 1.08 && color.g > color.b * 1.05) {
		color *= skin_tint;
	}
	ALBEDO = color;
	ROUGHNESS = 0.92;
}
