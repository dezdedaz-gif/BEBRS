extends Node3D
## Кровь без мультяшных кубиков: капли летят по дуге и вытягиваются вдоль полёта,
## на полу превращаются в неровные пятна с брызгами-спутниками, лужа растёт неровным
## контуром с тёмной серединой и толстой тёмной каймой (как у настоящей лужи крови),
## артериальный фонтан бьёт пульсами в направлении удара, из раны капает струя,
## на стенах остаются потёки, стекающие вниз.

const LowPoly = preload("res://Scripts/LowPoly.gd")
const MAX_DECALS := 240

var mats: Dictionary = {}
var decals: Array = []

func setup(m: Dictionary) -> void:
	mats = m

func _keep(n: Node3D) -> void:
	decals.append(n)
	while decals.size() > MAX_DECALS:
		var old = decals.pop_front()
		if is_instance_valid(old):
			old.queue_free()

func _disc(parent: Node3D, r: float, mat_id: String, y: float, pos: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = LowPoly.frustum(7, r, r * 0.88, 0.006)
	mi.material_override = mats[mat_id]
	mi.position = Vector3(pos.x, y, pos.z)
	mi.rotation.y = randf() * TAU
	parent.add_child(mi)
	return mi

## Пятно от упавшей капли: ядро и несколько мелких брызг вокруг. Пятно вытянуто по направлению.
func splat(p: Vector3, size: float, dir: Vector3 = Vector3.ZERO) -> void:
	var n := Node3D.new()
	n.position = Vector3(clampf(p.x, -12.3, 12.3), 0.011 + randf() * 0.003, clampf(p.z, -4.6, 4.9))
	add_child(n)
	var main := _disc(n, size, "blood_wet" if randf() < 0.5 else "blood", 0.0)
	if dir.length() > 0.01:
		var yaw := atan2(dir.x, dir.z)
		main.rotation.y = yaw
		main.scale = Vector3(1.0 + randf_range(0.2, 0.6), 1.0, 1.0)
	for i in randi_range(2, 4):
		var a := randf() * TAU
		var d := size * randf_range(1.2, 2.0)
		var s := size * randf_range(0.25, 0.5)
		_disc(n, s, "blood", 0.0005, Vector3(cos(a) * d, 0.0, sin(a) * d))
	_keep(n)

func _drop_pos(c: Node3D, start: Vector3, vel: Vector3, t: float) -> void:
	if is_instance_valid(c):
		c.position = Vector3(start.x + vel.x * t, maxf(0.012, start.y + vel.y * t - 4.9 * t * t), start.z + vel.z * t)

func _drop_land(c: Node3D, at: Vector3, size: float, dir: Vector3) -> void:
	if is_instance_valid(c):
		c.queue_free()
	splat(at, size, dir)

## Брызги: капли разного размера вытянуты по полёту, направление удара — dir, сила power.
func spatter(pos: Vector3, count: int = 10, dir: Vector3 = Vector3.ZERO, power: float = 1.0) -> void:
	var d := dir
	if d.length() < 0.01:
		d = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1))
	for i in count:
		var c := MeshInstance3D.new()
		var s := randf_range(0.02, 0.055)
		var bm := BoxMesh.new()
		bm.size = Vector3(s, s * randf_range(1.0, 1.8), s)
		c.mesh = bm
		c.material_override = mats["blood_wet"]
		c.position = pos
		add_child(c)
		var v := Vector3(randf_range(-1.3, 1.3), randf_range(0.6, 2.4), randf_range(-1.3, 1.3)) * power
		v += d.normalized() * randf_range(0.8, 2.4) * power
		var tl := (v.y + sqrt(v.y * v.y + 19.6 * maxf(pos.y, 0.0))) / 9.8
		var land := Vector3(pos.x + v.x * tl, 0.0, pos.z + v.z * tl)
		c.look_at(pos + v.normalized(), Vector3.UP)
		var tw := create_tween()
		tw.tween_method(func(t: float): _drop_pos(c, pos, v, t), 0.0, tl, tl)
		tw.tween_callback(func(): _drop_land(c, land, s * randf_range(0.9, 1.7), v))

## Артериальный фонтан: пульс крови из перерезанной артерии. dir — куда бьёт.
## power — сила напора (1..2). Каждый вызов — один толчок сердца.
func spray(pos: Vector3, dir: Vector3, power: float = 1.6) -> void:
	var d := dir.normalized()
	# мелкая взвесь-туман летит далеко
	for i in 8:
		var c := MeshInstance3D.new()
		var s := randf_range(0.008, 0.02)
		var bm := BoxMesh.new()
		bm.size = Vector3(s, s, s)
		c.mesh = bm
		c.material_override = mats["blood_wet"]
		c.position = pos
		add_child(c)
		var v := (d + Vector3(randf_range(-0.35, 0.35), randf_range(0.5, 1.5), randf_range(-0.35, 0.35))).normalized() * randf_range(2.5, 4.5) * power
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(c, "position", pos + v * 0.16, 0.16)
		tw.tween_property(c, "modulate:a", 0.0, 0.3)
		tw.tween_callback(c.queue_free).set_delay(0.3)
	# крупные капли
	for i in 5:
		var c := MeshInstance3D.new()
		var s := randf_range(0.02, 0.05)
		var bm := BoxMesh.new()
		bm.size = Vector3(s, s * randf_range(1.5, 2.5), s)
		c.mesh = bm
		c.material_override = mats["blood_wet"]
		c.position = pos
		add_child(c)
		var v := (d + Vector3(randf_range(-0.25, 0.25), randf_range(0.4, 1.2), randf_range(-0.25, 0.25))).normalized() * randf_range(2.0, 3.6) * power
		var tl := (v.y + sqrt(v.y * v.y + 19.6 * maxf(pos.y, 0.0))) / 9.8
		var land := Vector3(pos.x + v.x * tl, 0.0, pos.z + v.z * tl)
		var tw := create_tween()
		tw.tween_method(func(t: float): _drop_pos(c, pos, v, t), 0.0, tl, tl)
		tw.tween_callback(func(): _drop_land(c, land, s * randf_range(1.0, 1.8), v))

## Струя из раны: кровотечение — капли падают с точки раны несколько секунд.
## callback on_drop вызывается при каждом падении (звук капли).
func stream(pos: Vector3, secs: float, interval: float = 0.22) -> void:
	var el := 0.0
	while el < secs and not is_queued_for_deletion():
		var c := MeshInstance3D.new()
		var s := randf_range(0.018, 0.04)
		var bm := BoxMesh.new()
		bm.size = Vector3(s, s * 2.0, s)
		c.mesh = bm
		c.material_override = mats["blood_wet"]
		c.position = pos + Vector3(randf_range(-0.03, 0.03), 0.0, randf_range(-0.03, 0.03))
		add_child(c)
		var v := Vector3(randf_range(-0.1, 0.1), -0.4, randf_range(-0.1, 0.1))
		var tl := sqrt(maxf(pos.y, 0.1) * 2.0 / 9.8)
		var start := c.position
		var land := Vector3(start.x + v.x * tl, 0.0, start.z + v.z * tl)
		var tw := create_tween()
		tw.tween_method(func(t: float): _drop_pos(c, start, v, t), 0.0, tl, tl)
		tw.tween_callback(func(): _drop_land(c, land, s * randf_range(0.8, 1.4), v))
		await get_tree().create_timer(interval).timeout
		el += interval

## Лужа с неровным контуром, тёмной каймой и мокрой серединой.
## Растёт толчками сердца (beats — сколько ударов, interval — между ними).
func pool(pos: Vector3, r: float, grow: float = 4.0, beats: int = 0, interval: float = 0.8) -> void:
	var n := Node3D.new()
	n.position = Vector3(clampf(pos.x, -12.2, 12.2), 0.011, clampf(pos.z, -4.5, 4.8))
	add_child(n)
	_disc(n, r, "blood", 0.0)
	for i in randi_range(4, 6):
		var a := randf() * TAU
		var off := r * randf_range(0.45, 0.8)
		_disc(n, r * randf_range(0.35, 0.65), "blood", 0.0004 * float(i + 1), Vector3(cos(a) * off, 0.0, sin(a) * off))
	_disc(n, r * 0.55, "blood_dark", 0.003)
	_disc(n, r * 0.2, "blood_wet", 0.005, Vector3(r * 0.12, 0.0, -r * 0.08))
	n.scale = Vector3(0.05, 1.0, 0.05)
	var tw := create_tween()
	if beats > 1:
		# рост толчками: каждый удар — рывок, между ударами пауза
		for i in beats:
			tw.tween_property(n, "scale", Vector3.ONE * (1.0 - float(beats - 1 - i) / float(beats)), interval * 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_interval(interval * 0.75)
	else:
		tw.tween_property(n, "scale", Vector3.ONE, grow).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_keep(n)

## Пятно на одежде/коже с потёком вниз. parent — любой Node3D персонажа.
func wound(parent: Node3D, local_pos: Vector3, size: Vector2 = Vector2(0.1, 0.12), grow: float = 5.0) -> void:
	var pivot := Node3D.new()
	pivot.position = local_pos
	parent.add_child(pivot)
	var stain := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(size.x, size.y, 0.012)
	stain.mesh = bm
	stain.material_override = mats["blood_wet"]
	stain.scale = Vector3(0.15, 0.15, 1.0)
	pivot.add_child(stain)
	var core := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(size.x * 0.4, size.y * 0.4, 0.014)
	core.mesh = cm
	core.material_override = mats["blood_dark"]
	core.scale = Vector3(0.15, 0.15, 1.0)
	pivot.add_child(core)
	var drip := Node3D.new()
	drip.position = Vector3(size.x * randf_range(-0.25, 0.25), -size.y * 0.4, 0.002)
	pivot.add_child(drip)
	var dm := MeshInstance3D.new()
	var dbm := BoxMesh.new()
	dbm.size = Vector3(0.018, 0.34, 0.01)
	dm.mesh = dbm
	dm.material_override = mats["blood"]
	dm.position = Vector3(0.0, -0.17, 0.0)
	drip.add_child(dm)
	drip.scale = Vector3(1.0, 0.05, 1.0)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(stain, "scale", Vector3.ONE, grow * 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(core, "scale", Vector3.ONE, grow * 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(drip, "scale", Vector3.ONE, grow * 1.6).set_delay(0.8)

## Брызги на стену/предмет: пятно по нормали + стекающий вниз потёк.
func wall_mark(at: Vector3, normal: Vector3) -> void:
	var n := Node3D.new()
	add_child(n)
	var up := Vector3.UP
	if absf(normal.dot(Vector3.UP)) > 0.95:
		up = Vector3.RIGHT
	n.look_at_from_position(at + normal * 0.012, at + normal, up)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	var s := randf_range(0.05, 0.12)
	bm.size = Vector3(s, s * randf_range(1.0, 2.2), 0.006)
	mi.mesh = bm
	mi.material_override = mats["blood_wet"]
	n.add_child(mi)
	# потёк: узкая полоса медленно ползёт вниз от пятна
	var run := MeshInstance3D.new()
	var rb := BoxMesh.new()
	rb.size = Vector3(s * 0.25, s * 2.5, 0.004)
	run.mesh = rb
	run.material_override = mats["blood"]
	run.position = Vector3(randf_range(-s * 0.3, s * 0.3), -s * 1.2, 0.0)
	run.scale = Vector3(1.0, 0.1, 1.0)
	n.add_child(run)
	var tw := create_tween()
	tw.tween_property(run, "scale", Vector3.ONE, 3.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_keep(n)
