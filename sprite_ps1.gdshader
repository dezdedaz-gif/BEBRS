shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;
// PS1-спрайт: текстура без фильтрации, дрожание вершин, отсечение прозрачности, холодная подсветка луны.
uniform sampler2D tex : source_color, filter_nearest;
uniform vec3 tint = vec3(0.95, 1.0, 1.15);
uniform float brightness = 1.2;
uniform float snap_res = 160.0;
uniform float snap_strength = 1.0;

void vertex() {
	vec4 p = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	vec2 grid = vec2(snap_res, snap_res * 0.5625);
	vec2 ndc = p.xy / p.w;
	vec2 snapped = floor(ndc * grid + 0.5) / grid;
	p.xy = mix(ndc, snapped, snap_strength) * p.w;
	POSITION = p;
}

void fragment() {
	vec4 c = texture(tex, UV);
	if (c.a < 0.5) {
		discard;
	}
	ALBEDO = c.rgb * tint * brightness;
}
