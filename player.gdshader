shader_type canvas_item;

uniform float percent_health: hint_range(0.0, 1.0, 0.1);

void fragment() {
	float inv_health = 1.0 - percent_health;
	if (UV.x < inv_health) {
		COLOR = vec4(1.0, 0.0, 1.0, 1.0);
	}
}
