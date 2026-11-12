shader_type canvas_item;
// Потеря сознания: размытие экрана и затемнение (amount 0..1). Без ран и крови.
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec3 c = textureLod(screen_tex, SCREEN_UV, amount * 4.5).rgb;
	float v = smoothstep(0.2, 0.9, distance(SCREEN_UV, vec2(0.5)) * (0.8 + amount));
	c *= (1.0 - amount * 0.85) * (1.0 - v * amount);
	c = mix(c, vec3(0.0), smoothstep(0.85, 1.0, amount));
	COLOR = vec4(c, 1.0);
}
