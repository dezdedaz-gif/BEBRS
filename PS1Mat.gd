extends RefCounted
## Фабрика PS1-материалов (общий шейдер, дрожание вершин можно выключать).

const SHADER := preload("res://Shaders/ps1.gdshader")

static var registry: Array = []
static var snap: float = 1.0

static func reset() -> void:
	registry.clear()

static func make(color: Color, tex: Texture2D = null, tex_scale: float = 1.0, glow: float = 0.0) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SHADER
	m.set_shader_parameter("albedo", color)
	m.set_shader_parameter("use_tex", tex != null)
	if tex != null:
		m.set_shader_parameter("tex", tex)
	m.set_shader_parameter("tex_scale", tex_scale)
	m.set_shader_parameter("glow", glow)
	m.set_shader_parameter("snap_strength", snap)
	registry.append(m)
	return m

static func set_snap(value: float) -> void:
	snap = value
	for m in registry:
		(m as ShaderMaterial).set_shader_parameter("snap_strength", value)
