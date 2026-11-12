extends SubViewportContainer
## Фон главного меню: ночной лес в стиле PS1. Несколько планов деревьев (ели, лиственные, сухие),
## лунный свет с тенями, высотный туман и дымка между стволами, лучи сквозь кроны, звёзды,
## камни, пни, поваленное бревно, светящиеся грибы, светлячки с живым светом.
## Спрайт героини из Textures/sylphy_menu.png стоит в траве справа от кнопок.

const LowPoly = preload("res://Scripts/LowPoly.gd")
const PS1Mat = preload("res://Scripts/PS1Mat.gd")
const SPRITE_SHADER = preload("res://Shaders/sprite_ps1.gdshader")
const SPRITE_TEX = preload("res://Textures/sylphy_menu.png")

const SPRITE_H := 1.9
const SPRITE_POS := Vector3(1.35, 0.18, 0.0)

var _vp: SubViewport
var _cam: Camera3D
var _sprite: MeshInstance3D
var _sprite_mat: ShaderMaterial
var _flies: Array = []
var _mists: Array = []
var _rays: Array = []
var _fly_lights: Array = []
var _t := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	stretch = true
	_rng.seed = 777
	_vp = SubViewport.new()
	_vp.own_world_3d = true
	_vp.handle_input_locally = false
	_vp.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	_vp.positional_shadow_atlas_size = 0
	add_child(_vp)
	_build_environment()
	_build_ground()
	_build_plants()
	_build_forest()
	_build_mist()
	_build_rays()
	_build_sprite()
	_build_fireflies()
	_cam = Camera3D.new()
	_cam.fov = 50.0
	_cam.position = Vector3(0.0, 1.1, 3.3)
	_vp.add_child(_cam)
	_cam.look_at(Vector3(0.15, 0.95, 0.0), Vector3.UP)


func _grass_texture() -> ImageTexture:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for y in 32:
		for x in 32:
			var v := 0.75 + rng.randf_range(-0.12, 0.12)
			if (x * 7 + y * 3) % 11 == 0:
				v *= 0.7
			img.set_pixel(x, y, Color(v, v, v, 1.0))
	return ImageTexture.create_from_image(img)


func _add_mesh(mesh: Mesh, mat: Material, pos: Vector3, rot := Vector3.ZERO, shadow := false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_vp.add_child(mi)
	return mi


func _build_environment() -> void:
	var env := Environment.new()
	# небо: тёмный зенит, у горизонта холодная синеватая дымка
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.015, 0.02, 0.05)
	sky_mat.sky_horizon_color = Color(0.09, 0.12, 0.2)
	sky_mat.ground_bottom_color = Color(0.01, 0.015, 0.02)
	sky_mat.ground_horizon_color = Color(0.07, 0.09, 0.14)
	sky_mat.sun_angle_max = 0.0
	var sky := Sky.new()
	sky.sky_material = sky_mat
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.32, 0.38, 0.55)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.1
	# туман: общий по глубине + плотный у земли
	env.fog_enabled = true
	env.fog_light_color = Color(0.1, 0.13, 0.21)
	env.fog_light_energy = 1.0
	env.fog_density = 0.055
	env.fog_sky_affect = 0.35
	env.fog_height = 0.5
	env.fog_height_density = 0.35
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.glow_bloom = 0.08
	var we := WorldEnvironment.new()
	we.environment = env
	_vp.add_child(we)
	# луна: холодный направленный свет с тенями от стволов
	var moon := DirectionalLight3D.new()
	moon.light_color = Color(0.62, 0.72, 1.0)
	moon.light_energy = 1.05
	moon.rotation_degrees = Vector3(-32.0, 152.0, 0.0)
	moon.shadow_enabled = true
	moon.shadow_opacity = 0.85
	moon.shadow_blur = 1.5
	moon.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	moon.directional_shadow_max_distance = 22.0
	_vp.add_child(moon)
	# контровой свет спереди: подсвечивает края травы
	var rim := DirectionalLight3D.new()
	rim.light_color = Color(0.35, 0.42, 0.7)
	rim.light_energy = 0.35
	rim.rotation_degrees = Vector3(-12.0, -20.0, 0.0)
	_vp.add_child(rim)
	# луна с ореолом и звёзды (туман на них не действует)
	var moon_mat := StandardMaterial3D.new()
	moon_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	moon_mat.albedo_color = Color(0.92, 0.95, 1.0)
	moon_mat.disable_fog = true
	_add_mesh(LowPoly.sphere(Vector3(1.1, 1.1, 0.2), 10, 6), moon_mat, Vector3(-4.2, 6.2, -30.0))
	var halo := QuadMesh.new()
	halo.size = Vector2(9.0, 9.0)
	var hm := _soft_mat(Color(0.55, 0.65, 1.0, 0.32), true)
	hm.disable_fog = true
	_add_mesh(halo, hm, Vector3(-4.2, 6.2, -29.8))
	var star_mat := StandardMaterial3D.new()
	star_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	star_mat.albedo_color = Color(0.85, 0.9, 1.0)
	star_mat.disable_fog = true
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var sb := BoxMesh.new()
	sb.size = Vector3(0.06, 0.06, 0.06)
	mm.mesh = sb
	mm.instance_count = 160
	for i in 160:
		var p := Vector3(_rng.randf_range(-26.0, 26.0), _rng.randf_range(4.5, 16.0), -34.0 + _rng.randf_range(-2.0, 2.0))
		var sc := _rng.randf_range(0.5, 1.6)
		mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * sc), p))
	var stars := MultiMeshInstance3D.new()
	stars.multimesh = mm
	stars.material_override = star_mat
	stars.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_vp.add_child(stars)


## Мягкое пятно (радиальный градиент) для дымки, ореола и лучей.
func _soft_mat(col: Color, additive := false) -> StandardMaterial3D:
	var gt := GradientTexture2D.new()
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(0.5, 0.0)
	gt.width = 64
	gt.height = 64
	var gr := Gradient.new()
	gr.set_color(0, Color(1, 1, 1, 1))
	gr.set_color(1, Color(1, 1, 1, 0))
	gt.gradient = gr
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_texture = gt
	m.albedo_color = col
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	if additive:
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	return m


func _build_ground() -> void:
	var mat := PS1Mat.make(Color(0.2, 0.36, 0.17), _grass_texture(), 0.7)
	var box := BoxMesh.new()
	box.size = Vector3(60.0, 0.4, 60.0)
	_add_mesh(box, mat, Vector3(0.0, -0.2, -10.0))
	# холмы на дальнем плане — горизонт не плоский
	var hill := PS1Mat.make(Color(0.08, 0.14, 0.09))
	for i in 7:
		var hp := Vector3(-24.0 + i * 8.0 + _rng.randf_range(-2.0, 2.0), -1.2, _rng.randf_range(-27.0, -22.0))
		var hr := _rng.randf_range(5.0, 8.0)
		_add_mesh(LowPoly.sphere(Vector3(hr, _rng.randf_range(2.2, 3.4), hr * 0.6), 8, 4), hill, hp)
	# тёмные пятна земли
	var dirt := PS1Mat.make(Color(0.17, 0.12, 0.08))
	for i in 9:
		var p := Vector3(_rng.randf_range(-4.0, 4.0), 0.005, _rng.randf_range(-3.0, 2.0))
		_add_mesh(LowPoly.frustum(7, _rng.randf_range(0.3, 0.7), _rng.randf_range(0.3, 0.7), 0.01), dirt, p)
	# тень под героиней
	var shadow := PS1Mat.make(Color(0.02, 0.03, 0.02))
	_add_mesh(LowPoly.frustum(8, 0.38, 0.38, 0.01, 0.6), shadow, SPRITE_POS + Vector3(0.0, -0.17, 0.02))


func _blades(count: int, color: Color, z_min: float, z_max: float, h_min: float, h_max: float, near_char := 0.0) -> void:
	var blade := LowPoly.frustum(3, 0.045, 0.0, 1.0)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = blade
	mm.instance_count = count
	for i in count:
		var pos := Vector3(_rng.randf_range(-6.0, 6.0), 0.0, _rng.randf_range(z_min, z_max))
		if near_char > 0.0 and i % 2 == 0:
			pos = SPRITE_POS + Vector3(_rng.randf_range(-0.7, 0.7), 0.0, _rng.randf_range(0.05, 0.6))
			pos.y = 0.0
		var h := _rng.randf_range(h_min, h_max)
		var b := Basis.from_euler(Vector3(_rng.randf_range(-0.4, 0.4), _rng.randf_range(0.0, TAU), _rng.randf_range(-0.4, 0.4)))
		b = b.scaled(Vector3(1.0, h, 1.0))
		mm.set_instance_transform(i, Transform3D(b, pos + Vector3(0.0, h * 0.5, 0.0)))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = PS1Mat.make(color)
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_vp.add_child(mmi)


func _build_plants() -> void:
	# трава: два оттенка, плотная в кадре и перед героиней (скрывает низ спрайта)
	_blades(520, Color(0.24, 0.5, 0.2), -6.0, 2.4, 0.25, 0.6, 1.0)
	_blades(420, Color(0.13, 0.33, 0.15), -8.0, 2.0, 0.3, 0.75)
	# папоротники: пучки наклонных листьев
	var fern_mat := PS1Mat.make(Color(0.1, 0.4, 0.22))
	for i in 14:
		var c := Vector3(_rng.randf_range(-3.6, 3.6), 0.0, _rng.randf_range(-3.5, 1.6))
		if absf(c.x - SPRITE_POS.x) < 0.5 and c.z > -0.5:
			c.x -= 1.2
		for k in 6:
			var a := TAU * float(k) / 6.0 + _rng.randf_range(-0.2, 0.2)
			var leaf := LowPoly.frustum(3, 0.07, 0.0, 0.7)
			var mi := _add_mesh(leaf, fern_mat, c + Vector3(cos(a) * 0.12, 0.25, sin(a) * 0.12))
			mi.rotation = Vector3(sin(a) * 1.0, 0.0, -cos(a) * 1.0)
	# кусты
	var bush_mat := PS1Mat.make(Color(0.08, 0.28, 0.12))
	for i in 9:
		var p := Vector3(_rng.randf_range(-5.5, 5.5), 0.25, _rng.randf_range(-6.0, -1.0))
		if absf(p.x - SPRITE_POS.x) < 0.9 and p.z > -3.0:
			p.x += 2.0
		var r := _rng.randf_range(0.45, 0.9)
		_add_mesh(LowPoly.sphere(Vector3(r, r * 0.65, r), 6, 4), bush_mat, p)
	# цветы
	var stem := PS1Mat.make(Color(0.15, 0.42, 0.18))
	var petals := [PS1Mat.make(Color(0.9, 0.85, 0.95), null, 1.0, 0.25), PS1Mat.make(Color(0.9, 0.35, 0.5), null, 1.0, 0.25)]
	for i in 26:
		var p := Vector3(_rng.randf_range(-4.5, 4.5), 0.0, _rng.randf_range(-3.5, 1.8))
		var h := _rng.randf_range(0.3, 0.55)
		_add_mesh(LowPoly.frustum(3, 0.012, 0.012, h), stem, p + Vector3(0.0, h * 0.5, 0.0))
		_add_mesh(LowPoly.sphere(Vector3(0.05, 0.035, 0.05), 5, 3), petals[i % 2], p + Vector3(0.0, h, 0.0))


## Лес в несколько планов: тёмные стволы по краям кадра, средний план, дальняя стена елей.
func _build_forest() -> void:
	var bark := [PS1Mat.make(Color(0.2, 0.13, 0.09)), PS1Mat.make(Color(0.15, 0.11, 0.08)), PS1Mat.make(Color(0.25, 0.2, 0.16))]
	var needles := [PS1Mat.make(Color(0.05, 0.2, 0.12)), PS1Mat.make(Color(0.04, 0.16, 0.11)), PS1Mat.make(Color(0.07, 0.25, 0.14))]
	var leaves := [PS1Mat.make(Color(0.08, 0.26, 0.13)), PS1Mat.make(Color(0.1, 0.3, 0.12)), PS1Mat.make(Color(0.06, 0.21, 0.1))]
	var dead := PS1Mat.make(Color(0.3, 0.27, 0.24))
	# передний план: крупные ели по бокам кадра
	for p in [Vector3(-4.8, 0, -1.6), Vector3(-3.4, 0, -3.8), Vector3(4.6, 0, -2.2), Vector3(3.3, 0, -4.4)]:
		_conifer(p, _rng.randf_range(5.0, 6.5), bark, needles)
	# средний план
	for i in 16:
		var p := Vector3(_rng.randf_range(-8.0, 8.0), 0, _rng.randf_range(-11.0, -4.5))
		if absf(p.x - SPRITE_POS.x) < 1.2 and p.z > -6.0:
			p.x += 2.4
		var k := _rng.randi() % 5
		if k <= 2:
			_conifer(p, _rng.randf_range(3.2, 5.2), bark, needles)
		elif k == 3:
			_broadleaf(p, _rng.randf_range(2.6, 3.8), bark, leaves)
		else:
			_dead_tree(p, _rng.randf_range(2.4, 3.4), dead)
	# дальний план: плотная стена елей, туман делает её синеватым силуэтом
	for i in 34:
		var p := Vector3(-20.0 + i * 1.2 + _rng.randf_range(-0.5, 0.5), 0, _rng.randf_range(-21.0, -12.0))
		_conifer(p, _rng.randf_range(4.0, 7.0), bark, needles, false)
	_build_ground_detail(bark)

func _conifer(p: Vector3, h: float, bark: Array, needles: Array, shadow := true) -> void:
	var bm: Material = bark[_rng.randi() % bark.size()]
	_add_mesh(LowPoly.frustum(6, 0.14 * h / 4.0, 0.05, h), bm, p + Vector3(0, h * 0.5, 0), Vector3.ZERO, shadow)
	# корни-утолщения у основания
	_add_mesh(LowPoly.frustum(6, 0.26 * h / 4.0, 0.12 * h / 4.0, 0.3), bm, p + Vector3(0, 0.15, 0))
	var tiers := 4 + _rng.randi() % 2
	var rot := _rng.randf() * TAU
	for t in tiers:
		var f := float(t) / float(tiers)
		var r := lerpf(1.25, 0.35, f) * h / 5.0
		var th := h * 0.32
		var y := h * (0.28 + f * 0.62)
		var nm: Material = needles[(t + _rng.randi()) % needles.size()]
		_add_mesh(LowPoly.frustum(7, r, 0.0, th), nm, p + Vector3(_rng.randf_range(-0.05, 0.05), y, 0), Vector3(_rng.randf_range(-0.06, 0.06), rot + t * 0.5, 0), shadow)

func _broadleaf(p: Vector3, h: float, bark: Array, leaves: Array) -> void:
	var bm: Material = bark[_rng.randi() % bark.size()]
	_add_mesh(LowPoly.frustum(6, 0.16, 0.08, h), bm, p + Vector3(0, h * 0.5, 0), Vector3(0, 0, _rng.randf_range(-0.08, 0.08)), true)
	for sx in [-1.0, 1.0]:
		_add_mesh(LowPoly.frustum(4, 0.05, 0.02, h * 0.45), bm, p + Vector3(sx * 0.35, h * 0.72, 0), Vector3(0, 0, -sx * 0.7))
	for i in 5:
		var off := Vector3(_rng.randf_range(-0.8, 0.8), h * _rng.randf_range(0.8, 1.15), _rng.randf_range(-0.5, 0.5))
		var r := _rng.randf_range(0.6, 1.0)
		_add_mesh(LowPoly.sphere(Vector3(r, r * 0.75, r), 7, 4), leaves[i % leaves.size()], p + off, Vector3.ZERO, true)

func _dead_tree(p: Vector3, h: float, mat: Material) -> void:
	_add_mesh(LowPoly.frustum(5, 0.12, 0.03, h), mat, p + Vector3(0, h * 0.5, 0), Vector3(0, 0, _rng.randf_range(-0.12, 0.12)), true)
	for i in 4:
		var y := h * _rng.randf_range(0.4, 0.85)
		var a := _rng.randf() * TAU
		var l := _rng.randf_range(0.5, 1.0)
		var br := _add_mesh(LowPoly.frustum(4, 0.035, 0.008, l), mat, p + Vector3(cos(a) * l * 0.35, y + l * 0.3, sin(a) * l * 0.35), Vector3(0, -a, 0))
		br.rotation = Vector3(sin(a) * 0.9, 0, -cos(a) * 0.9)

## Камни с мхом, пни, бревно, светящиеся грибы.
func _build_ground_detail(bark: Array) -> void:
	var stone := PS1Mat.make(Color(0.3, 0.32, 0.34))
	var moss := PS1Mat.make(Color(0.12, 0.3, 0.14))
	for i in 10:
		var p := Vector3(_rng.randf_range(-5.0, 5.0), 0.05, _rng.randf_range(-6.0, 1.0))
		if absf(p.x - SPRITE_POS.x) < 0.7 and p.z > -1.0:
			p.x -= 1.5
		var r := _rng.randf_range(0.12, 0.35)
		_add_mesh(LowPoly.sphere(Vector3(r * 1.3, r * 0.7, r), 6, 3), stone, p, Vector3(0, _rng.randf() * TAU, 0), true)
		_add_mesh(LowPoly.sphere(Vector3(r * 1.0, r * 0.3, r * 0.8), 6, 3), moss, p + Vector3(0, r * 0.45, 0))
	for p in [Vector3(-1.9, 0, -1.6), Vector3(2.6, 0, -4.4), Vector3(-0.4, 0, -5.2)]:
		_add_mesh(LowPoly.frustum(7, 0.24, 0.2, 0.32), bark[0], p + Vector3(0, 0.16, 0), Vector3.ZERO, true)
		_add_mesh(LowPoly.frustum(7, 0.2, 0.2, 0.01), PS1Mat.make(Color(0.45, 0.35, 0.22)), p + Vector3(0, 0.325, 0))
	# поваленное бревно поперёк поляны
	var log_m := _add_mesh(LowPoly.frustum(7, 0.2, 0.17, 3.0), bark[1], Vector3(-1.4, 0.18, -3.2), Vector3.ZERO, true)
	log_m.rotation = Vector3(0, 0.35, PI * 0.5)
	_add_mesh(LowPoly.sphere(Vector3(0.9, 0.08, 0.2), 6, 3), moss, Vector3(-1.4, 0.36, -3.2), Vector3(0, 0.35, 0))
	# грибы со слабым свечением
	var cap := PS1Mat.make(Color(0.55, 0.85, 0.75), null, 1.0, 1.2)
	var stem := PS1Mat.make(Color(0.75, 0.72, 0.65))
	for i in 14:
		var c := Vector3(-1.4, 0, -3.2) + Vector3(_rng.randf_range(-1.4, 1.4), 0, _rng.randf_range(0.15, 0.5))
		if i > 8:
			c = Vector3(-1.9, 0, -1.6) + Vector3(_rng.randf_range(-0.35, 0.35), 0, _rng.randf_range(-0.3, 0.3))
		var h := _rng.randf_range(0.05, 0.11)
		_add_mesh(LowPoly.frustum(4, 0.01, 0.01, h), stem, c + Vector3(0, h * 0.5, 0))
		_add_mesh(LowPoly.sphere(Vector3(0.03, 0.015, 0.03), 5, 3), cap, c + Vector3(0, h, 0))
	var glow := OmniLight3D.new()
	glow.light_color = Color(0.4, 0.9, 0.75)
	glow.light_energy = 0.5
	glow.omni_range = 1.4
	glow.position = Vector3(-1.4, 0.2, -2.9)
	_vp.add_child(glow)

## Дымка между стволами: полупрозрачные мягкие пятна на разной глубине, медленно плывут.
func _build_mist() -> void:
	for i in 22:
		var z := _rng.randf_range(-16.0, 0.5)
		var q := QuadMesh.new()
		var w := _rng.randf_range(3.0, 7.0) * (1.0 + absf(z) * 0.06)
		q.size = Vector2(w, w * _rng.randf_range(0.2, 0.35))
		var a := _rng.randf_range(0.1, 0.22) * (0.6 if z > -2.0 else 1.0)
		var m := _soft_mat(Color(0.55, 0.62, 0.8, a))
		var p := Vector3(_rng.randf_range(-9.0, 9.0), _rng.randf_range(0.15, 0.9), z)
		var mi := _add_mesh(q, m, p)
		_mists.append([mi, p, _rng.randf_range(0.05, 0.18), _rng.randf() * TAU])

## Лучи лунного света сквозь кроны.
func _build_rays() -> void:
	for i in 5:
		var q := QuadMesh.new()
		q.size = Vector2(_rng.randf_range(0.5, 1.1), 9.0)
		var m := _soft_mat(Color(0.5, 0.6, 0.95, _rng.randf_range(0.05, 0.09)), true)
		var p := Vector3(-3.5 + i * 1.7 + _rng.randf_range(-0.4, 0.4), 3.4, _rng.randf_range(-9.0, -5.0))
		var mi := _add_mesh(q, m, p, Vector3(0, 0, -0.42))
		_rays.append([mi, m, m.albedo_color.a, _rng.randf() * TAU])


func _build_sprite() -> void:
	var aspect := float(SPRITE_TEX.get_width()) / float(SPRITE_TEX.get_height())
	var q := QuadMesh.new()
	q.size = Vector2(SPRITE_H * aspect, SPRITE_H)
	_sprite_mat = ShaderMaterial.new()
	_sprite_mat.shader = SPRITE_SHADER
	_sprite_mat.set_shader_parameter("tex", SPRITE_TEX)
	_sprite = _add_mesh(q, _sprite_mat, SPRITE_POS + Vector3(0.0, SPRITE_H * 0.5, 0.0))


func _build_fireflies() -> void:
	var mat := PS1Mat.make(Color(0.8, 1.0, 0.4), null, 1.0, 2.0)
	for i in 14:
		var base := Vector3(_rng.randf_range(-3.5, 3.5), _rng.randf_range(0.4, 1.8), _rng.randf_range(-3.0, 1.5))
		var mi := _add_mesh(BoxMesh.new(), mat, base)
		(mi.mesh as BoxMesh).size = Vector3(0.03, 0.03, 0.03)
		_flies.append([mi, base, _rng.randf_range(0.0, TAU), _rng.randf_range(0.4, 1.0)])
		if i < 3:
			var l := OmniLight3D.new()
			l.light_color = Color(0.75, 1.0, 0.4)
			l.omni_range = 1.3
			_vp.add_child(l)
			_fly_lights.append(l)


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_t += delta
	_cam.position.x = sin(_t * 0.25) * 0.22
	_cam.position.y = 1.1 + sin(_t * 0.4) * 0.03
	_cam.look_at(Vector3(0.15, 0.95, 0.0), Vector3.UP)
	# спрайт всегда смотрит на камеру по оси Y, дышит и чуть покачивается
	var d := _cam.position - _sprite.position
	_sprite.rotation.y = atan2(d.x, d.z)
	_sprite.position.y = SPRITE_POS.y + SPRITE_H * 0.5 + sin(_t * 1.6) * 0.006
	_sprite.rotation.z = sin(_t * 0.9) * 0.012
	_sprite_mat.set_shader_parameter("snap_strength", PS1Mat.snap)
	for f in _flies:
		var mi: MeshInstance3D = f[0]
		var base: Vector3 = f[1]
		var ph: float = f[2]
		var sp: float = f[3]
		mi.position = base + Vector3(sin(_t * sp + ph) * 0.4, sin(_t * sp * 1.3 + ph) * 0.2, cos(_t * sp * 0.8 + ph) * 0.3)
		mi.visible = sin(_t * 2.0 * sp + ph) > -0.5
	for i in _fly_lights.size():
		var l: OmniLight3D = _fly_lights[i]
		var f2: Array = _flies[i]
		l.position = (f2[0] as Node3D).position
		l.light_energy = 0.35 * (0.6 + 0.4 * sin(_t * 3.0 + i)) if (f2[0] as Node3D).visible else 0.0
	for m in _mists:
		var mi2: MeshInstance3D = m[0]
		var base2: Vector3 = m[1]
		mi2.position = base2 + Vector3(sin(_t * float(m[2]) + float(m[3])) * 1.2, sin(_t * 0.3 + float(m[3])) * 0.05, 0)
	for r in _rays:
		(r[1] as StandardMaterial3D).albedo_color.a = float(r[2]) * (0.7 + 0.3 * sin(_t * 0.5 + float(r[3])))
