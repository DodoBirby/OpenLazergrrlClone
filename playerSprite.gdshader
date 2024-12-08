shader_type canvas_item;
uniform vec3 primary_color: source_color;
uniform vec3 secondary_color: source_color;

void fragment() {
	vec4 yellow = vec4(1.0, 1.0, 0.0, 1.0);
	vec4 red = vec4(1.0, 0.0, 0.0, 1.0);
	if (COLOR == yellow) {
		COLOR = vec4(secondary_color, 1.0);
	} else if (COLOR == red) {
		COLOR = vec4(primary_color, 1.0);
	}
}
