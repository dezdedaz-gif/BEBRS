shader_type canvas_item;
// Тёмный «каменный» фон главного меню: медленно ползущая плитка с красноватой пульсацией.
uniform sampler2D tex : filter_nearest, repeat_enable;
uniform vec2 tiles = vec2(20.0, 11.25);

void fragment() {
	vec2 uv = UV * tiles + vec2(TIME * 0.025, TIME * 0.012);
	vec3 c = texture(tex, uv).rgb;
	float pulse = 0.85 + 0.15 * sin(TIME * 0.8);
	vec3 col = c * vec3(0.5, 0.36, 0.36) * pulse;
	float v = smoothstep(0.95, 0.2, distance(UV, vec2(0.5)));
	col *= mix(0.25, 1.0, v);
	COLOR = vec4(col, 1.0);
}
