extends CharacterBody3D
## «Хозяин подвала» — горбатая тварь: череп с гребнем, выпученные глаза с жёлтыми ободками,
## пасть с клыками и одиноким зубом, длинные волосы на одну сторону, длинные руки с когтями.

const LowPoly = preload("res://Scripts/LowPoly.gd")

var move_amount: float = 0.0
var stunned: bool = false
var dead: bool = false

var body: Node3D
var head: Node3D
var jaw: Node3D
var arm_l: Node3D
var arm_r: Node3D
var elbow_l: Node3D
var elbow_r: Node3D
var leg_l: Node3D
var leg_r: Node3D
var pupil_l: Node3D
var pupil_r: Node3D
var strands: Array = []
var _pl0: Vector3 = Vector3(-0.15, 0.0, 0.0)
var _pr0: Vector3 = Vector3(0.16, -0.01, 0.0)
var _t: float = 0.0
var _phase: float = 0.0

func _mi(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3 = Vector3.ZERO, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	m.material_override = mat
	m.position = pos
	m.rotation_degrees = rot
	parent.add_child(m)
	return m

func _pivot(parent: Node3D, pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	parent.add_child(n)
	return n

func _box(s: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = s
	return b

func build(m: Dictionary) -> void:
	var skin: Material = m["mon_skin"]
	var pale: Material = m["mon_pale"]
	var eye: Material = m["mon_eye"]
	var iris: Material = m["mon_iris"]
	var pupil: Material = m["mon_pupil"]
	var teeth: Material = m["mon_teeth"]
	var tongue: Material = m["mon_tongue"]
	var hair: Material = m["mon_hair"]
	var cs := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.34
	shape.height = 1.5
	cs.shape = shape
	cs.position.y = 0.75
	add_child(cs)

	# --- туловище (горб вперёд)
	body = _pivot(self, Vector3(0, 0.95, 0))
	body.rotation.x = 0.4
	_mi(body, LowPoly.frustum(7, 0.3, 0.42, 0.85, 0.75), skin, Vector3(0, 0.1, 0))
	for i in 5:
		_mi(body, LowPoly.frustum(3, 0.05, 0.004, 0.16), pale, Vector3(0, -0.2 + i * 0.16, -0.3), Vector3(-90, 0, 0))
	for i in 4:
		_mi(body, _box(Vector3(0.3 - i * 0.03, 0.035, 0.02)), pale, Vector3(0, 0.38 - i * 0.14, 0.29))

	# --- голова
	head = _pivot(body, Vector3(0, 0.62, 0.14))
	_mi(head, LowPoly.sphere(Vector3(0.36, 0.3, 0.34), 7, 5), skin)
	_mi(head, LowPoly.sphere(Vector3(0.2, 0.07, 0.3), 6, 3), pale, Vector3(0, 0.26, 0.0))
	_mi(head, _box(Vector3(0.3, 0.07, 0.14)), pale, Vector3(-0.17, 0.15, 0.27), Vector3(0, 0, -16))
	_mi(head, _box(Vector3(0.3, 0.07, 0.14)), pale, Vector3(0.17, 0.15, 0.27), Vector3(0, 0, 16))
	# глаза
	_mi(head, LowPoly.sphere(Vector3(0.13, 0.14, 0.12), 6, 4), m["mon_eye"], Vector3(-0.15, 0.0, 0.28))
	_mi(head, LowPoly.sphere(Vector3(0.11, 0.12, 0.1), 6, 4), m["mon_eye"], Vector3(0.16, -0.01, 0.27))
	pupil_l = _pivot(head, Vector3(-0.15, 0.0, 0.385))
	pupil_r = _pivot(head, Vector3(0.16, -0.01, 0.365))
	_pl0 = pupil_l.position
	_pr0 = pupil_r.position
	_mi(pupil_l, LowPoly.frustum(8, 0.085, 0.085, 0.02), iris, Vector3.ZERO, Vector3(90, 0, 0))
	_mi(pupil_l, LowPoly.frustum(6, 0.04, 0.04, 0.03), pupil, Vector3(0, 0, 0.01), Vector3(90, 0, 0))
	_mi(pupil_r, LowPoly.frustum(8, 0.07, 0.07, 0.02), iris, Vector3.ZERO, Vector3(90, 0, 0))
	_mi(pupil_r, LowPoly.frustum(6, 0.03, 0.03, 0.03), pupil, Vector3(0, 0, 0.01), Vector3(90, 0, 0))
	# нос
	_mi(head, _box(Vector3(0.07, 0.14, 0.06)), pale, Vector3(0, -0.02, 0.33))
	_mi(head, _box(Vector3(0.03, 0.05, 0.03)), pupil, Vector3(-0.04, -0.1, 0.35))
	_mi(head, _box(Vector3(0.03, 0.05, 0.03)), pupil, Vector3(0.04, -0.1, 0.35))
	# верхняя челюсть и клыки
	_mi(head, _box(Vector3(0.38, 0.1, 0.3)), skin, Vector3(0, -0.17, 0.2))
	for i in 7:
		var x := -0.15 + i * 0.05
		var long := i == 0 or i == 6
		_mi(head, LowPoly.frustum(3, 0.003, 0.02, 0.2 if long else 0.1), teeth, Vector3(x, -0.3 if long else -0.26, 0.33))
	# нижняя челюсть (анимируется)
	jaw = _pivot(head, Vector3(0, -0.22, 0.05))
	_mi(jaw, _box(Vector3(0.34, 0.07, 0.32)), skin, Vector3(0, -0.03, 0.2))
	for i in 5:
		_mi(jaw, LowPoly.frustum(3, 0.02, 0.003, 0.11), teeth, Vector3(-0.12 + i * 0.06, 0.07, 0.34))
	_mi(jaw, _box(Vector3(0.14, 0.03, 0.22)), tongue, Vector3(0, 0.01, 0.18))
	_mi(jaw, LowPoly.frustum(3, 0.025, 0.003, 0.16), teeth, Vector3(0, 0.1, 0.3))
	# волосы — длинные пряди на одну сторону
	for i in 10:
		var p := _pivot(head, Vector3(0.26 + (i % 3) * 0.04, 0.14 - (i % 2) * 0.05, -0.28 + i * 0.058))
		var slen := 0.85 - float(i % 4) * 0.12
		_mi(p, _box(Vector3(0.035, slen, 0.035)), hair, Vector3(0, -slen * 0.5, 0))
		strands.append(p)
	for i in 4:
		var p2 := _pivot(head, Vector3(-0.3, 0.1, -0.15 + i * 0.1))
		_mi(p2, _box(Vector3(0.03, 0.4, 0.03)), hair, Vector3(0, -0.2, 0))
		strands.append(p2)

	# --- руки
	arm_l = _pivot(body, Vector3(-0.46, 0.4, 0.0))
	arm_r = _pivot(body, Vector3(0.46, 0.4, 0.0))
	for a in [arm_l, arm_r]:
		_mi(a, LowPoly.frustum(5, 0.05, 0.075, 0.62), skin, Vector3(0, -0.31, 0))
		var el := _pivot(a, Vector3(0, -0.62, 0))
		_mi(el, LowPoly.frustum(5, 0.038, 0.052, 0.62), skin, Vector3(0, -0.31, 0))
		_mi(el, _box(Vector3(0.1, 0.1, 0.1)), pale, Vector3(0, -0.66, 0))
		for c in 3:
			_mi(el, LowPoly.frustum(3, 0.003, 0.018, 0.2), teeth, Vector3(-0.04 + c * 0.04, -0.8, 0.0))
		if a == arm_l:
			elbow_l = el
		else:
			elbow_r = el

	# --- ноги
	leg_l = _pivot(self, Vector3(-0.2, 0.62, 0))
	leg_r = _pivot(self, Vector3(0.2, 0.62, 0))
	for l in [leg_l, leg_r]:
		_mi(l, LowPoly.frustum(5, 0.07, 0.115, 0.6), skin, Vector3(0, -0.3, 0))
		_mi(l, _box(Vector3(0.18, 0.07, 0.3)), pale, Vector3(0, -0.6, 0.06))

func _process(delta: float) -> void:
	if dead:
		return
	_t += delta
	var amp := clampf(move_amount, 0.0, 1.4)
	if amp > 0.05:
		_phase += delta * (6.0 + 4.0 * amp)
	var s := sin(_phase)
	leg_l.rotation.x = -s * 0.7 * amp
	leg_r.rotation.x = s * 0.7 * amp
	if stunned:
		body.rotation.x = lerpf(body.rotation.x, 0.85, clampf(6.0 * delta, 0.0, 1.0))
		head.rotation.x = lerpf(head.rotation.x, 0.6, clampf(6.0 * delta, 0.0, 1.0))
		head.rotation.z = sin(_t * 4.0) * 0.15
		jaw.rotation.x = 0.6
		arm_l.rotation.x = 0.1
		arm_r.rotation.x = 0.1
		elbow_l.rotation.x = 0.0
		elbow_r.rotation.x = 0.0
		pupil_l.position = _pl0 + Vector3(0.05, 0, 0)
		pupil_r.position = _pr0 + Vector3(-0.05, 0, 0)
	else:
		body.rotation.x = lerpf(body.rotation.x, 0.4 + 0.2 * amp + sin(_t * 1.5) * 0.03, clampf(6.0 * delta, 0.0, 1.0))
		head.rotation.x = lerpf(head.rotation.x, sin(_t * 0.9) * 0.08, clampf(6.0 * delta, 0.0, 1.0))
		head.rotation.y = sin(_t * 1.3) * 0.25
		head.rotation.z = sin(_t * 23.0) * 0.04 + sin(_t * 3.0) * 0.08
		jaw.rotation.x = 0.25 + (0.5 + 0.5 * sin(_t * (8.0 + 6.0 * amp))) * (0.3 + 0.2 * amp)
		arm_l.rotation.x = -0.3 - 0.9 * amp + s * 0.4 * amp
		arm_r.rotation.x = -0.3 - 0.9 * amp - s * 0.4 * amp
		elbow_l.rotation.x = -0.4 * amp
		elbow_r.rotation.x = -0.4 * amp
		pupil_l.position = _pl0 + Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * 0.012
		pupil_r.position = _pr0 + Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * 0.012
	body.position.y = 0.95 + sin(_t * 2.0) * 0.015 + absf(s) * 0.05 * amp
	var i := 0
	for p in strands:
		(p as Node3D).rotation.z = sin(_t * 1.6 + i) * 0.08 + 0.05
		(p as Node3D).rotation.x = sin(_t * 1.2 + i * 0.7) * 0.06
		i += 1

## Двигаться к точке `to` со скоростью `speed` (вызывается из физического кадра игры).
func step(to: Vector3, speed: float, delta: float) -> void:
	var d := to - global_position
	d.y = 0.0
	if stunned or dead or d.length() < 0.05:
		velocity.x = 0.0
		velocity.z = 0.0
		move_amount = 0.0
	else:
		var n := d.normalized()
		velocity.x = n.x * speed
		velocity.z = n.z * speed
		rotation.y = lerp_angle(rotation.y, atan2(n.x, n.z), clampf(8.0 * delta, 0.0, 1.0))
		move_amount = clampf(speed / 1.6, 0.4, 1.4)
	if is_on_floor():
		velocity.y = -0.5
	else:
		velocity.y -= 20.0 * delta
	move_and_slide()
