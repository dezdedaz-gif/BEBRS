extends Node3D
## Живые детали подвала: паутина, капающая труба с лужей, крысы, луч света от лампы,
## щиток с искрами, инструменты на стене, следы волочения, бумаги на стенах.
## Всё строится из коробок и low-poly форм, как и остальной мир.

const LowPoly = preload("res://Scripts/LowPoly.gd")
const Sfx = preload("res://Scripts/Sfx.gd")

var game
var mats: Dictionary = {}
var rats: Array = []
var drips: Array = []
var sparks_light: OmniLight3D
var shaft: MeshInstance3D
var web_mat: StandardMaterial3D
var _spark_t: float = 4.0
var _spark_left: float = 0.0
var _clock: float = 0.0
var _drip_player: AudioStreamPlayer
var _squeak_player: AudioStreamPlayer

func _box(parent: Node3D, size: Vector3, mat: Material, pos: Vector3, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot_deg
	parent.add_child(mi)
	return mi

func setup(g, m: Dictionary) -> void:
	game = g
	mats = m
	web_mat = StandardMaterial3D.new()
	web_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	web_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	web_mat.albedo_color = Color(0.8, 0.82, 0.85, 0.32)
	web_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_build_webs()
	_build_light_shaft()
	_build_dripping_pipe()
	_build_fuse_box()
	_build_wall_stuff()
	_build_drag_marks()
	# крысы теперь живут в Game.gd (Rat.gd)
	_drip_player = AudioStreamPlayer.new()
	_drip_player.stream = Sfx.make("drip")
	_drip_player.volume_db = -16.0
	add_child(_drip_player)
	_squeak_player = AudioStreamPlayer.new()
	_squeak_player.stream = Sfx.make("squeak")
	_squeak_player.volume_db = -14.0
	add_child(_squeak_player)

# --- паутина в углах: тонкие полупрозрачные нити
func _web(corner: Vector3, dx: float, dy: float, dz: float) -> void:
	for i in 4:
		var f := float(i + 1) / 4.0
		var a := corner + Vector3(dx * f, 0.0, 0.0)
		var b := corner + Vector3(0.0, dy * (1.0 - f), dz * f * 0.0)
		var mid := (a + b) * 0.5
		var len_v := a.distance_to(b)
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.012, len_v, 0.006)
		mi.mesh = bm
		mi.material_override = web_mat
		mi.position = mid
		mi.rotation.z = atan2(b.x - a.x, -(b.y - a.y)) 
		add_child(mi)
	# дуги между нитями
	for r in [0.35, 0.6, 0.85]:
		var seg := _box(self, Vector3(0.012, 0.012, 0.006), web_mat, corner + Vector3(dx * r * 0.7, dy * r * 0.7, 0.0))
		seg.scale = Vector3(dx * r * 18.0, 1.0, 1.0)
		seg.rotation.z = -atan2(dy, dx) + PI / 2.0 * 0.0

func _build_webs() -> void:
	# верхние углы главной комнаты (задняя стена, чуть от неё)
	_web(Vector3(-5.9, 3.55, -4.95), 0.9, -0.9, 0.0)
	_web(Vector3(5.9, 3.55, -4.95), -0.9, -0.9, 0.0)
	_web(Vector3(-12.55, 3.55, -3.55), 0.8, -0.8, 0.0)
	_web(Vector3(12.55, 3.55, -3.55), -0.8, -0.8, 0.0)
	_web(Vector3(-0.3, 3.5, -4.95), 0.7, -0.5, 0.0)

# --- луч света под лампой
func _build_light_shaft() -> void:
	var sm := StandardMaterial3D.new()
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.albedo_color = Color(1.0, 0.82, 0.55, 0.07)
	sm.cull_mode = BaseMaterial3D.CULL_DISABLED
	shaft = MeshInstance3D.new()
	shaft.mesh = LowPoly.frustum(8, 1.7, 0.1, 2.6)
	shaft.material_override = sm
	shaft.position = Vector3(0, 1.4, -0.2)
	add_child(shaft)

# --- капающая труба и лужа
func _build_dripping_pipe() -> void:
	var pipe_x := -2.0
	_box(self, Vector3(0.14, 0.14, 1.2), mats["rust"], Vector3(pipe_x, 3.2, -4.5))
	_box(self, Vector3(0.1, 0.6, 0.1), mats["rust"], Vector3(pipe_x, 2.95, -4.1))
	# лужа под трубой с каймой
	var puddle := MeshInstance3D.new()
	puddle.mesh = LowPoly.frustum(9, 0.55, 0.5, 0.01)
	var pm := StandardMaterial3D.new()
	pm.albedo_color = Color(0.06, 0.09, 0.12, 0.8)
	pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pm.metallic = 0.6
	pm.roughness = 0.2
	puddle.material_override = pm
	puddle.position = Vector3(pipe_x, 0.014, -3.7)
	add_child(puddle)
	# капля
	var drop := MeshInstance3D.new()
	var dm := BoxMesh.new()
	dm.size = Vector3(0.025, 0.05, 0.025)
	drop.mesh = dm
	var dmat := StandardMaterial3D.new()
	dmat.albedo_color = Color(0.5, 0.65, 0.75, 0.85)
	dmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	drop.material_override = dmat
	drop.position = Vector3(pipe_x, 2.62, -3.7)
	add_child(drop)
	drips.append({"node": drop, "x": pipe_x, "z": -3.7, "t": randf() * 2.0, "ring": null})
	var ring := MeshInstance3D.new()
	ring.mesh = LowPoly.frustum(10, 0.1, 0.1, 0.004)
	var rm := StandardMaterial3D.new()
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rm.albedo_color = Color(0.6, 0.7, 0.8, 0.0)
	ring.material_override = rm
	ring.position = Vector3(pipe_x, 0.02, -3.7)
	add_child(ring)
	(drips[0] as Dictionary)["ring"] = ring
	(drips[0] as Dictionary)["ring_mat"] = rm

# --- щиток с искрами (в левом нижнем углу задней стены)
func _build_fuse_box() -> void:
	_box(self, Vector3(0.55, 0.7, 0.12), mats["metal"], Vector3(-3.6, 1.9, -4.95))
	_box(self, Vector3(0.45, 0.6, 0.02), mats["black"], Vector3(-3.6, 1.9, -4.88))
	for i in 3:
		_box(self, Vector3(0.06, 0.03, 0.03), mats["lamp"], Vector3(-3.75 + i * 0.15, 2.12, -4.86))
	# кабели
	_box(self, Vector3(0.03, 0.9, 0.03), mats["black"], Vector3(-3.5, 1.1, -4.93), Vector3(0, 0, 8))
	_box(self, Vector3(0.03, 0.7, 0.03), mats["black"], Vector3(-3.7, 1.2, -4.93), Vector3(0, 0, -12))
	sparks_light = OmniLight3D.new()
	sparks_light.position = Vector3(-3.6, 1.5, -4.5)
	sparks_light.light_color = Color(0.6, 0.8, 1.0)
	sparks_light.light_energy = 0.0
	sparks_light.omni_range = 3.5
	add_child(sparks_light)

# --- стена: бумаги, инструменты на крючках, фото
func _build_wall_stuff() -> void:
	# инструменты над верстаком (левая стена)
	var tools_x := -5.97
	_box(self, Vector3(0.04, 0.05, 1.3), mats["wood"], Vector3(tools_x, 1.95, -1.7))
	# молоток
	_box(self, Vector3(0.03, 0.4, 0.04), mats["wood_light"], Vector3(tools_x + 0.03, 1.75, -2.1))
	_box(self, Vector3(0.05, 0.08, 0.16), mats["metal"], Vector3(tools_x + 0.03, 1.97, -2.1))
	# пила
	_box(self, Vector3(0.015, 0.14, 0.55), mats["metal_light"], Vector3(tools_x + 0.03, 1.6, -1.55), Vector3(0, 0, 0))
	_box(self, Vector3(0.04, 0.1, 0.12), mats["wood"], Vector3(tools_x + 0.03, 1.6, -1.2))
	# клещи
	_box(self, Vector3(0.02, 0.34, 0.03), mats["metal"], Vector3(tools_x + 0.03, 1.72, -1.0), Vector3(0, 0, 4))
	_box(self, Vector3(0.02, 0.34, 0.03), mats["metal"], Vector3(tools_x + 0.03, 1.72, -0.96), Vector3(0, 0, -4))
	# бумаги и фото на задней стене
	var papers := [[Vector3(-1.75, 2.0, -4.97), 8.0], [Vector3(-1.3, 1.75, -4.97), -6.0], [Vector3(2.75, 2.1, -4.97), 4.0]]
	for p in papers:
		_box(self, Vector3(0.28, 0.36, 0.01), mats["paper"], p[0], Vector3(0, 0, p[1]))
		for i in 3:
			_box(self, Vector3(0.2, 0.012, 0.012), mats["black"], (p[0] as Vector3) + Vector3(0, 0.1 - i * 0.07, 0.008), Vector3(0, 0, p[1]))
	# календарь с обведёнными днями
	_box(self, Vector3(0.5, 0.65, 0.01), mats["white"], Vector3(1.9, 2.0, -4.97))
	for i in 4:
		for j in 3:
			if (i + j) % 3 == 0:
				_box(self, Vector3(0.07, 0.07, 0.01), mats["blood_dark"], Vector3(1.75 + j * 0.12, 1.95 - i * 0.1, -4.96))
	# царапины: засечки на стене у кровати (правая стена)
	for g in 4:
		for i in 4:
			_box(self, Vector3(0.012, 0.22, 0.012), mats["black"], Vector3(5.97, 1.2 - g * 0.0, -2.6 + g * 0.18 + i * 0.03), Vector3(0, 0, 0))
		_box(self, Vector3(0.012, 0.012, 0.16), mats["black"], Vector3(5.97, 1.2, -2.54 + g * 0.18), Vector3(0, 0, 0))

# --- следы волочения от стула к кровати (грязь и кровь)
func _build_drag_marks() -> void:
	for i in 7:
		var f := float(i) / 6.0
		var p := Vector3(3.6 + f * 1.3, 0.011, 0.9 - f * 2.2)
		var mi := _box(self, Vector3(0.1, 0.004, 0.55), mats["blood_dark"], p, Vector3(0, 20.0 + i * 3.0, 0))
		mi.scale = Vector3(1.0 - f * 0.4, 1.0, 1.0)

# --- крысы
func _build_rats() -> void:
	for i in 2:
		var rat := Node3D.new()
		var body := _box(rat, Vector3(0.12, 0.07, 0.24), mats["mon_skin"], Vector3(0, 0.05, 0))
		_box(rat, Vector3(0.07, 0.06, 0.08), mats["mon_skin"], Vector3(0, 0.055, 0.15))
		_box(rat, Vector3(0.02, 0.02, 0.02), mats["mon_iris"], Vector3(-0.025, 0.07, 0.19))
		_box(rat, Vector3(0.02, 0.02, 0.02), mats["mon_iris"], Vector3(0.025, 0.07, 0.19))
		_box(rat, Vector3(0.015, 0.015, 0.2), mats["blood_dark"], Vector3(0, 0.03, -0.2))
		body.name = "Body"
		rat.position = Vector3(-4.0 + i * 8.0, 0.0, -4.5)
		add_child(rat)
		rats.append({"node": rat, "target": rat.position, "wait": randf_range(2.0, 8.0), "speed": 1.6})

func _process(delta: float) -> void:
	_clock += delta
	# луч лампы мерцает вместе с лампой
	if shaft != null and game != null and game.lamp != null:
		var e: float = game.lamp.light_energy / 1.7
		(shaft.material_override as StandardMaterial3D).albedo_color.a = 0.07 * clampf(e, 0.0, 1.2)
	_update_drips(delta)
	_update_sparks(delta)
	_update_rats(delta)

func _update_drips(delta: float) -> void:
	for d in drips:
		var n: MeshInstance3D = d["node"]
		d["t"] = float(d["t"]) + delta
		var t: float = float(d["t"])
		var period := 2.6
		var ph := fmod(t, period)
		var ring: MeshInstance3D = d["ring"]
		var rm: StandardMaterial3D = d["ring_mat"]
		if ph < 1.0:
			n.visible = true
			var f := ph / 1.0
			n.position.y = lerpf(2.62, 0.04, f * f)
			rm.albedo_color.a = 0.0
		else:
			if n.visible:
				n.visible = false
				if game != null and game.game_started and not game.menu_panel.visible:
					_drip_player.pitch_scale = randf_range(0.85, 1.2)
					_drip_player.play()
			var r := (ph - 1.0) / 1.2
			ring.scale = Vector3.ONE * (0.4 + r * 3.0)
			rm.albedo_color.a = clampf(0.45 * (1.0 - r), 0.0, 1.0)

func _update_sparks(delta: float) -> void:
	if sparks_light == null:
		return
	if _spark_left > 0.0:
		_spark_left -= delta
		sparks_light.light_energy = randf_range(0.0, 2.4) if randf() < 0.6 else 0.0
		if _spark_left <= 0.0:
			sparks_light.light_energy = 0.0
		return
	_spark_t -= delta
	if _spark_t <= 0.0:
		_spark_t = randf_range(5.0, 16.0)
		_spark_left = randf_range(0.15, 0.5)

func _update_rats(delta: float) -> void:
	for r in rats:
		var n: Node3D = r["node"]
		var to: Vector3 = (r["target"] as Vector3) - n.position
		to.y = 0.0
		if to.length() < 0.15:
			r["wait"] = float(r["wait"]) - delta
			if float(r["wait"]) <= 0.0:
				r["wait"] = randf_range(3.0, 12.0)
				# новая точка вдоль стены (в основной комнате или у боковых дверей)
				var wall_z := -4.6 if randf() < 0.7 else 4.7
				r["target"] = Vector3(randf_range(-5.4, 5.4), 0.0, wall_z + randf_range(-0.2, 0.2))
				if randf() < 0.35 and game != null and game.game_started:
					_squeak_player.pitch_scale = randf_range(0.9, 1.3)
					_squeak_player.play()
		else:
			var dir := to.normalized()
			# убегают от игрока
			if game != null and game.player != null:
				var pd: Vector3 = n.position - game.player.global_position
				pd.y = 0.0
				if pd.length() < 1.6:
					r["target"] = Vector3(clampf(n.position.x + pd.normalized().x * 3.0, -5.4, 5.4), 0.0, clampf(n.position.z + pd.normalized().z * 3.0, -4.6, 4.7))
					dir = pd.normalized()
			n.position += dir * float(r["speed"]) * delta
			n.rotation.y = lerp_angle(n.rotation.y, atan2(dir.x, dir.z), clampf(12.0 * delta, 0.0, 1.0))
			var body: Node3D = n.get_node("Body")
			body.position.y = 0.05 + absf(sin(_clock * 28.0)) * 0.012
