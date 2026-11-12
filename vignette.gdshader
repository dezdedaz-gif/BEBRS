shader_type canvas_item;

void fragment() {
	vec2 uv = UV - 0.5;
	float v = smoothstep(0.30, 0.80, length(uv * vec2(1.0, 0.95)));
	COLOR = vec4(0.0, 0.0, 0.02, v * 0.7);
}
