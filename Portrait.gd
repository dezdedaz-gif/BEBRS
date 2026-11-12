extends PanelContainer
## Окно с камерой девушки в диалогах: живой 3D-вид лица (мимика, моргание, слёзы, скотч)
## с подсветкой и «плёночным» шейдером. Камера идёт за головой, поэтому видно, как она дышит и дрожит.

const MCStyle = preload("res://Scripts/MCStyle.gd")
const PORTRAIT_SHADER = preload("res://Shaders/portrait.gdshader")

var vp: SubViewport
var cam: Camera3D
var light: OmniLight3D
var name_label: Label
var target: Node3D = null
var active: bool = false

func setup(game: Node3D, display_name: String = "СИЛЬФИ") -> void:
	add_theme_stylebox_override("panel", MCStyle.portrait_frame())
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	add_child(v)
	vp = SubViewport.new()
	vp.size = Vector2i(128, 128)
	vp.own_world_3d = false
	vp.world_3d = game.get_viewport().world_3d
	vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	vp.transparent_bg = false
	add_child(vp)
	cam = Camera3D.new()
	cam.fov = 32.0
	cam.near = 0.04
	cam.far = 25.0
	cam.current = true
	vp.add_child(cam)
	var tr := TextureRect.new()
	tr.texture = vp.get_texture()
	tr.custom_minimum_size = Vector2(92, 92)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var sm := ShaderMaterial.new()
	sm.shader = PORTRAIT_SHADER
	tr.material = sm
	v.add_child(tr)
	name_label = Label.new()
	name_label.text = display_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 10)
	MCStyle.style_label(name_label, Color(0.78, 0.8, 0.76))
	v.add_child(name_label)
	light = OmniLight3D.new()
	light.light_color = Color(1.0, 0.9, 0.8)
	light.light_energy = 1.1
	light.omni_range = 2.4
	light.shadow_enabled = false
	light.visible = false
	game.add_child(light)
	visible = false

func present(girl_node: Node3D) -> void:
	target = girl_node
	active = true
	visible = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	light.visible = true
	_follow()

func dismiss() -> void:
	active = false
	visible = false
	vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	if light != null:
		light.visible = false

func _process(_delta: float) -> void:
	if active and target != null and is_instance_valid(target):
		_follow()

func _follow() -> void:
	var head: Node3D = target.head
	var hp: Vector3 = head.global_position
	var fwd: Vector3 = target.global_transform.basis.z
	fwd.y = 0.0
	if fwd.length() < 0.01:
		fwd = Vector3(0, 0, 1)
	fwd = fwd.normalized()
	var side := Vector3(fwd.z, 0.0, -fwd.x)
	var from := hp + fwd * 0.64 + side * 0.1 + Vector3(0, 0.025, 0)
	cam.global_position = from
	cam.look_at(hp + Vector3(0, -0.005, 0), Vector3.UP)
	light.global_position = from + Vector3(0.12, 0.2, 0.05)
