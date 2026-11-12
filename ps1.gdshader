shader_type spatial;
render_mode cull_back, diffuse_lambert, specular_disabled;

// PS1-style material: vertex snapping (wobble), nearest-filtered triplanar texture, flat shading.
uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D tex : source_color, filter_nearest, repeat_enable;
uniform bool use_tex = false;
uniform float tex_scale = 1.0;
uniform float snap_res = 160.0;
uniform float snap_strength = 1.0;
uniform float glow = 0.0;

varying vec3 lpos;
varying vec3 lnrm;

void vertex() {
	lpos = VERTEX;
	lnrm = NORMAL;
	vec4 p = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	vec2 grid = vec2(snap_res, snap_res * 0.5625);
	vec2 ndc = p.xy / p.w;
	vec2 snapped = floor(ndc * grid + 0.5) / grid;
	p.xy = mix(ndc, snapped, snap_strength) * p.w;
	POSITION = p;
}

void fragment() {
	vec3 n = abs(normalize(lnrm));
	vec2 uv;
	if (n.y > n.x && n.y > n.z) {
		uv = lpos.xz;
	} else if (n.x > n.z) {
		uv = lpos.zy;
	} else {
		uv = lpos.xy;
	}
	vec3 c = albedo.rgb;
	if (use_tex) {
		c *= texture(tex, uv * tex_scale).rgb * 1.25;
	}
	ALBEDO = c;
	ROUGHNESS = 1.0;
	EMISSION = albedo.rgb * glow;
}
