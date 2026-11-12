shader_type canvas_item;
// Окно с камерой девушки: лёгкая десатурация, строчки, зерно и тёмные края.
uniform float scan : hint_range(0.0, 1.0) = 0.22;

float h(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float l = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	vec3 col = mix(vec3(l), c.rgb, 0.78) * vec3(0.94, 1.0, 1.02);
	float line = 0.5 + 0.5 * sin(UV.y * 96.0 * 3.14159);
	col *= 1.0 - scan * 0.45 * line;
	float n = h(floor(UV * 96.0) + floor(TIME * 12.0));
	col += (n - 0.5) * 0.07;
	float v = smoothstep(0.32, 0.78, distance(UV, vec2(0.5)));
	col *= 1.0 - v * 0.65;
	COLOR = vec4(col, 1.0);
}
