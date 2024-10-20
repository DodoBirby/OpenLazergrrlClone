shader_type canvas_item;
uniform float percent_health: hint_range(0.0, 1.0, 0.1);

void fragment() {
	vec4 white = vec4(0.8);
	if (all(greaterThan(COLOR, white)) && UV.y < (1.0 - percent_health)) {
		vec4 new_color = COLOR;
		new_color.g = 0.0;
		COLOR = new_color;
	}
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
