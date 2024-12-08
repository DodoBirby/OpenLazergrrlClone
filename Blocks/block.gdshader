shader_type canvas_item;
uniform float percent_health: hint_range(0.0, 1.0, 0.1);
uniform vec3 primary_color: source_color;
uniform vec3 secondary_color: source_color;

void fragment() {
	vec4 white = vec4(0.8);
	if (all(greaterThan(COLOR, white)) && UV.y < (1.0 - percent_health)) {
		vec4 new_color = COLOR;
		new_color.g = 0.0;
		COLOR = new_color;
	}
	vec4 red = vec4(1.0, 0.0, 0.0, 1.0);
	vec4 yellow = vec4(1.0, 1.0, 0.0, 1.0);
	if (COLOR == red) {
		COLOR = vec4(primary_color, 1.0);
	} else if (COLOR == yellow) {
		COLOR = vec4(secondary_color, 1.0);
	}
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
