extends Node3D
## Играбельный «имп» по референсу: большая голова-капюшон с длинными ушами-лопастями, светящиеся глаза,
## клыкастая ухмылка, бледная грудь, длинные когтистые руки, маленькие ноги. Рост около 1.2 м.
## Смотрит в сторону +Z. Те же поля, что у Humanoid: move_amount, aim, show_held, set_emotion.

const LowPoly = preload("res://Scripts/LowPoly.gd")
const ItemModels = preload("res://Scripts/ItemModels.gd")

var move_amount: float = 0.0
var aim: float = 0.0
var swing: float = 0.0  # взмах рукой при использовании предмета
var pose: String = ""  # "" / "two" (пистолет двумя руками) / "tool" (нож, ломик) / "light" / "carry"
var kick: float = 0.0  # отдача после выстрела (1 -> 0)
var to_head: float = 0.0  # 0..1: правая рука поднимает предмет к виску (сцена «на себя»)
var to_throat: float = 0.0  # 0..1: нож у горла, голова запрокинута (сцена «на себя», нож)
var throw_t: float = -1.0  # бросок: 0 = замах, 1 = рука вытянута; -1 = не бросаем
var emotion: String = "neutral"
var collapse: float = 0.0  # 0 стоит, 0.5 на коленях, 1 лежит ничком (падение / смерть)
var collapse_side: float = 1.0  # куда повернётся голова лёжа (-1 / 1)
var dead_eyes: bool = false  # глаза закрыты, челюсть обмякла
var tremor: float = 0.0  # 0..1 дрожь рук от боли
var _was_down: bool = false
var draw: float = 0.0     # 0..1 рука тянется за спину к рюкзаку (достаёт / убирает предмет)
var punch_l: float = 0.0  # 0..1 левый прямой удар кулаком
var dash: float = 0.0     # 0..1 рывок: корпус наклонён вперёд
var sit: float = 0.0      # 0..1 сидит (ноги вперёд), высоту задаёт игра

var torso: Node3D
var head: Node3D
var jaw: Node3D
var ear_l: Node3D
var ear_r: Node3D
var arm_l: Node3D
var arm_r: Node3D
var fore_l: Node3D
var fore_r: Node3D
var hip_l: Node3D
var hip_r: Node3D
var eye_l: Node3D
var eye_r: Node3D
var pup_l: Node3D
var pup_r: Node3D
var held: Dictionary = {}

var _phase: float = 0.0
var _amp: float = 0.0
var _t: float = 0.0
var _eye_s: float = 1.0
var _jaw_open: float = 0.2
var _ear_lift: float = 0.0
var _blink: float = 0.0
var _next_blink: float = 2.0
var _look_t: float = 2.0
var _look_yaw: float = 0.0
var _hop: float = 0.0
var _pl0: Vector3 = Vector3.ZERO
var _pr0: Vector3 = Vector3.ZERO

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
	var skin: Material = m["imp_skin"]
	var pale: Material = m["imp_pale"]
	var ear: Material = m["imp_ear"]
	var teeth: Material = m["imp_teeth"]
	# туловище
	torso = _pivot(self, Vector3(0, 0.55, 0))
	torso.rotation.x = 0.12
	_mi(torso, LowPoly.frustum(6, 0.14, 0.2, 0.42, 0.85), skin, Vector3(0, 0.0, 0))
	_mi(torso, _box(Vector3(0.17, 0.24, 0.03)), pale, Vector3(0, 0.02, 0.15))
	_mi(torso, _box(Vector3(0.1, 0.12, 0.03)), pale, Vector3(0, -0.14, 0.13))
	# голова
	head = _pivot(torso, Vector3(0, 0.46, 0.04))
	_mi(head, LowPoly.sphere(Vector3(0.3, 0.26, 0.28), 6, 4), skin)
	_mi(head, LowPoly.frustum(4, 0.22, 0.01, 0.22), skin, Vector3(0, 0.26, 0.0), Vector3(0, 45, 0))
	_mi(head, _box(Vector3(0.1, 0.03, 0.12)), pale, Vector3(0.0, 0.3, 0.07), Vector3(20, 0, 0))
	_mi(head, _box(Vector3(0.18, 0.02, 0.06)), pale, Vector3(-0.05, 0.2, 0.18), Vector3(0, 0, 20))
	# глаза: левый крупнее
	var wl: Material = m["imp_eye"]
	eye_l = _pivot(head, Vector3(-0.11, 0.04, 0.22))
	eye_r = _pivot(head, Vector3(0.12, 0.03, 0.2))
	_mi(eye_l, LowPoly.sphere(Vector3(0.085, 0.085, 0.05), 6, 4), wl)
	_mi(eye_r, LowPoly.sphere(Vector3(0.07, 0.07, 0.045), 6, 4), wl)
	pup_l = _pivot(eye_l, Vector3(0, 0, 0.04))
	pup_r = _pivot(eye_r, Vector3(0, 0, 0.035))
	_mi(pup_l, LowPoly.frustum(8, 0.06, 0.06, 0.012), m["imp_iris"], Vector3.ZERO, Vector3(90, 0, 0))
	_mi(pup_l, LowPoly.frustum(6, 0.028, 0.028, 0.02), m["imp_pupil"], Vector3(0, 0, 0.005), Vector3(90, 0, 0))
	_mi(pup_r, LowPoly.frustum(8, 0.05, 0.05, 0.012), m["imp_iris"], Vector3.ZERO, Vector3(90, 0, 0))
	_mi(pup_r, LowPoly.frustum(6, 0.022, 0.022, 0.02), m["imp_pupil"], Vector3(0, 0, 0.005), Vector3(90, 0, 0))
	_pl0 = pup_l.position
	_pr0 = pup_r.position
	# голубой нос-гребень
	_mi(head, _box(Vector3(0.04, 0.13, 0.04)), m["imp_glow"], Vector3(0.0, -0.01, 0.27), Vector3(-10, 0, 0))
	# верхняя челюсть и зубы, нижняя челюсть анимируется
	_mi(head, _box(Vector3(0.3, 0.05, 0.1)), skin, Vector3(-0.01, -0.1, 0.2))
	for i in 8:
		_mi(head, LowPoly.frustum(3, 0.003, 0.014, 0.06), teeth, Vector3(-0.14 + i * 0.037, -0.145, 0.25))
	jaw = _pivot(head, Vector3(0, -0.12, 0.12))
	_mi(jaw, _box(Vector3(0.28, 0.04, 0.12)), skin, Vector3(0, -0.02, 0.08))
	for i in 7:
		_mi(jaw, LowPoly.frustum(3, 0.014, 0.003, 0.05), teeth, Vector3(-0.12 + i * 0.04, 0.03, 0.12))
	_mi(jaw, _box(Vector3(0.22, 0.02, 0.012)), m["imp_glow"], Vector3(0, -0.04, 0.14))
	# большие боковые лопасти-уши
	ear_l = _pivot(head, Vector3(-0.27, 0.12, -0.04))
	ear_r = _pivot(head, Vector3(0.27, 0.12, -0.04))
	for e in [ear_l, ear_r]:
		var sgn := -1.0 if e == ear_l else 1.0
		_mi(e, _box(Vector3(0.03, 0.34, 0.2)), ear, Vector3(sgn * 0.06, -0.15, 0), Vector3(0, 0, sgn * -14))
		_mi(e, _box(Vector3(0.03, 0.22, 0.14)), ear, Vector3(sgn * 0.13, -0.38, 0.0), Vector3(0, 0, sgn * -26))
	# руки: длинные, с когтями
	arm_l = _pivot(torso, Vector3(-0.2, 0.18, 0))
	arm_r = _pivot(torso, Vector3(0.2, 0.18, 0))
	for a in [arm_l, arm_r]:
		_mi(a, LowPoly.frustum(5, 0.035, 0.055, 0.34), skin, Vector3(0, -0.17, 0))
		var f := _pivot(a, Vector3(0, -0.34, 0))
		_mi(f, LowPoly.frustum(5, 0.03, 0.04, 0.34), skin, Vector3(0, -0.17, 0))
		_mi(f, _box(Vector3(0.07, 0.06, 0.07)), pale, Vector3(0, -0.36, 0))
		for c in 3:
			_mi(f, LowPoly.frustum(3, 0.002, 0.014, 0.12), teeth, Vector3(-0.025 + c * 0.025, -0.45, 0.01))
		if a == arm_l:
			fore_l = f
		else:
			fore_r = f
	# ноги с бледными ступнями
	hip_l = _pivot(self, Vector3(-0.09, 0.34, 0))
	hip_r = _pivot(self, Vector3(0.09, 0.34, 0))
	for h in [hip_l, hip_r]:
		_mi(h, LowPoly.frustum(5, 0.045, 0.07, 0.34), skin, Vector3(0, -0.17, 0))
		_mi(h, _box(Vector3(0.1, 0.05, 0.17)), pale, Vector3(0, -0.34, 0.04))
		_mi(h, LowPoly.frustum(3, 0.002, 0.03, 0.08), teeth, Vector3(0, -0.34, 0.14), Vector3(90, 0, 0))
	_build_held(m)
	set_emotion("neutral")

func _build_held(m: Dictionary) -> void:
	var root := _pivot(fore_r, Vector3(0, -0.4, 0.03))
	for id in ["knife", "pistol", "syringe", "banana", "rope", "crowbar", "cuffs", "poison", "beartrap",
			"bandage", "medkit", "water", "chocolate", "canned", "beans", "lighter", "flashlight", "lockpick", "sylphy", "tape"]:
		var n: Node3D = ItemModels.make(id, m)
		root.add_child(n)
		held[id] = n
	show_held("")

const POSES := {"pistol": "two", "knife": "tool", "crowbar": "tool", "flashlight": "light", "lighter": "light"}

func show_held(id: String) -> void:
	for k in held:
		(held[k] as Node3D).visible = (k == id)
	if id == "" or not held.has(id):
		pose = ""
	else:
		pose = str(POSES.get(id, "carry"))

## neutral / happy / fear / angry / hurt
func set_emotion(e: String) -> void:
	emotion = e
	match e:
		"happy":
			_eye_s = 0.6; _jaw_open = 0.35; _ear_lift = 0.5
			_hop = 0.35
		"fear":
			_eye_s = 1.45; _jaw_open = 0.5; _ear_lift = -0.5
		"angry":
			_eye_s = 0.55; _jaw_open = 0.45; _ear_lift = -0.2
		"hurt":
			_eye_s = 0.3; _jaw_open = 0.6; _ear_lift = -0.7
		_:
			_eye_s = 1.0; _jaw_open = 0.2; _ear_lift = 0.0

func _process(delta: float) -> void:
	_t += delta
	_amp = lerpf(_amp, move_amount, clampf(10.0 * delta, 0.0, 1.0))
	if _amp > 0.05:
		_phase += delta * (8.0 + 4.0 * _amp)
	var s := sin(_phase)
	# ходьба: ноги, руки, покачивание корпуса, прыжки радости
	hip_l.rotation.x = -s * 0.8 * _amp
	hip_r.rotation.x = s * 0.8 * _amp
	_hop = maxf(0.0, _hop - delta)
	var hop_y := absf(sin(_t * 12.0)) * 0.08 if _hop > 0.0 else 0.0
	torso.position.y = 0.55 + sin(_t * 2.4) * 0.008 + absf(s) * 0.035 * _amp + hop_y
	torso.rotation.z = s * 0.05 * _amp
	torso.rotation.x = 0.12 + 0.12 * _amp
	# руки: по умолчанию ходьба, но если в руке предмет — своя поза
	var k := clampf(18.0 * delta, 0.0, 1.0)
	var tal := s * 0.7 * _amp
	var tfl := -0.3 - 0.3 * _amp
	var tar := -s * 0.7 * _amp
	var tfr := -0.3 - 0.3 * _amp
	var breathe := sin(_t * 1.7) * 0.025
	kick = maxf(0.0, kick - delta * 5.0)
	if to_head > 0.01:
		tar = -2.35 * to_head + breathe * 0.3
		tfr = -2.05 * to_head
		tal = s * 0.2
		tfl = -0.3
	elif to_throat > 0.01:
		# нож у горла: рука согнута, лезвие у шеи, голова чуть запрокинута
		tar = -1.75 * to_throat + breathe * 0.25
		tfr = -2.1 * to_throat
		tal = -0.35 * to_throat
		tfl = -1.0 * to_throat
	elif throw_t >= 0.0:
		tar = lerpf(-2.7, 0.5, throw_t * throw_t)
		tfr = lerpf(-1.4, -0.05, throw_t)
		tal = lerpf(-0.9, 0.3, throw_t)
		tfl = -0.3
	elif pose == "two":
		tar = -1.4 - kick * 0.6 + breathe
		tfr = -0.08 - kick * 0.3
		tal = -1.25 + breathe
		tfl = -0.3
	elif pose == "tool" or aim > 0.01:
		var a := maxf(aim, 0.75) if pose == "tool" else aim
		tar = -1.45 * a + swing * 0.5 + breathe
		tfr = -0.1 + swing * 0.9
	elif pose == "light":
		tar = -1.0 + breathe
		tfr = -0.7
	elif pose == "carry":
		tar = -0.6 + breathe
		tfr = -1.15
	if punch_l > 0.01:
		tal = lerpf(tal, -1.6, punch_l)
		tfl = lerpf(tfl, -0.05, punch_l)
	if draw > 0.01:
		tar = lerpf(tar, 0.95, draw)
		tfr = lerpf(tfr, -1.3, draw)
	arm_l.rotation.x = lerpf(arm_l.rotation.x, tal, k)
	fore_l.rotation.x = lerpf(fore_l.rotation.x, tfl, k)
	arm_r.rotation.x = lerpf(arm_r.rotation.x, tar, k)
	fore_r.rotation.x = lerpf(fore_r.rotation.x, tfr, k)
	# голова: осматривается, наклоняется на ходу
	_look_t -= delta
	if _look_t <= 0.0:
		_look_t = randf_range(1.5, 4.0)
		_look_yaw = randf_range(-0.6, 0.6) if _amp < 0.1 else 0.0
	head.rotation.y = lerpf(head.rotation.y, _look_yaw, clampf(3.0 * delta, 0.0, 1.0))
	head.rotation.z = sin(_t * 1.1) * 0.04 + s * 0.04 * _amp
	head.rotation.x = -0.1 * _amp - 0.38 * to_throat + sin(_t * 6.0) * 0.02 * to_throat
	# уши-лопасти колышутся
	var sway := sin(_t * 2.0) * 0.06 + sin(_phase * 2.0) * 0.15 * _amp
	ear_l.rotation.z = -(0.0 + _ear_lift * 0.5) + sway
	ear_r.rotation.z = (0.0 + _ear_lift * 0.5) + sway
	# челюсть: дрожит в страхе, чавкает на ходу
	var tremble := sin(_t * 40.0) * 0.08 if emotion == "fear" else 0.0
	jaw.rotation.x = _jaw_open + absf(sin(_t * 9.0)) * 0.1 * _amp + tremble
	# глаза: моргание, дрожание зрачков
	_next_blink -= delta
	if _next_blink <= 0.0:
		_blink = 0.12
		_next_blink = randf_range(1.5, 4.0)
	_blink -= delta
	var es := 0.1 if _blink > 0.0 else _eye_s
	eye_l.scale = Vector3(1.0, es, 1.0)
	eye_r.scale = Vector3(1.0, es, 1.0)
	pup_l.position = _pl0 + Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * 0.004
	pup_r.position = _pr0 + Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * 0.004
	_apply_tremor()
	_apply_pose_extras()
	_apply_collapse()

## Доп. позы: доставание из рюкзака, рывок, сидение (в укрытии).
func _apply_pose_extras() -> void:
	torso.rotation.y = -0.4 * draw + 0.25 * punch_l
	if dash > 0.01:
		torso.rotation.x += 0.55 * dash
		hip_l.rotation.x = lerpf(hip_l.rotation.x, -0.7, dash)
		hip_r.rotation.x = lerpf(hip_r.rotation.x, 0.6, dash)
	if sit > 0.01:
		hip_l.rotation.x = lerpf(hip_l.rotation.x, -1.45, sit)
		hip_r.rotation.x = lerpf(hip_r.rotation.x, -1.35, sit)
		hip_l.rotation.z = -0.1 * sit
		hip_r.rotation.z = 0.1 * sit
		torso.rotation.x = lerpf(torso.rotation.x, -0.05, sit)
		torso.position.y = lerpf(torso.position.y, 0.5, sit)
	if draw <= 0.01 and collapse <= 0.001 and tremor < 0.12:
		arm_l.rotation.z = 0.0
		arm_r.rotation.z = 0.0

## Дрожь рук от боли: мелкая неровная тряска, сильнее с предметом в руке.
func _apply_tremor() -> void:
	if tremor < 0.12 or collapse > 0.3:
		return
	var a := (tremor - 0.12) * (0.09 if pose != "" else 0.04)
	arm_r.rotation.x += (sin(_t * 23.0) + sin(_t * 37.0) * 0.6) * a
	arm_r.rotation.z = (sin(_t * 29.0)) * a * 0.7
	fore_r.rotation.x += sin(_t * 41.0) * a * 0.6
	arm_l.rotation.x += sin(_t * 19.0 + 1.0) * a * 0.6

## Падение: пошатывание -> колени подгибаются -> заваливается ничком.
func _apply_collapse() -> void:
	if collapse <= 0.001:
		if _was_down:
			_was_down = false
			rotation.x = 0.0
			rotation.z = 0.0
			position.y = 0.0
		return
	_was_down = true
	var c := clampf(collapse, 0.0, 1.0)
	var k := clampf(c / 0.5, 0.0, 1.0)          # фаза «на колени»
	var f := clampf((c - 0.5) / 0.5, 0.0, 1.0)  # фаза «падает вперёд»
	var ke := k * k * (3.0 - 2.0 * k)
	var fe := f * f
	# ноги складываются назад, тело опускается
	# лёжа ноги снова выпрямляются вдоль тела
	hip_l.rotation.x = lerpf(lerpf(hip_l.rotation.x, 1.25, ke), 0.12, fe)
	hip_r.rotation.x = lerpf(lerpf(hip_r.rotation.x, 1.35, ke), 0.22, fe)
	hip_l.rotation.z = -0.12 * ke
	hip_r.rotation.z = 0.12 * ke
	# корпус обмякает и клонится, голова падает на грудь
	torso.rotation.x = lerpf(torso.rotation.x, 0.55, ke) - 0.45 * fe
	torso.rotation.z = sin(_t * 1.3) * 0.04 * (1.0 - f) * k
	torso.position.y = lerpf(torso.position.y, 0.5, ke)
	head.rotation.x = lerpf(head.rotation.x, 0.45, ke) * (1.0 - fe) - 0.15 * fe
	head.rotation.y = lerpf(head.rotation.y, 0.0, ke) + collapse_side * 1.1 * fe
	head.rotation.z = collapse_side * 0.25 * fe
	# руки повисают, потом раскидываются по полу
	var hang := -0.15 * ke
	arm_l.rotation.x = lerpf(arm_l.rotation.x, hang, ke) - 2.3 * fe * 0.5
	arm_r.rotation.x = lerpf(arm_r.rotation.x, hang, ke) - 2.3 * fe * 0.35
	arm_l.rotation.z = -0.35 * fe
	arm_r.rotation.z = 0.5 * fe
	fore_l.rotation.x = lerpf(fore_l.rotation.x, -0.1, ke) - 0.4 * fe
	fore_r.rotation.x = lerpf(fore_r.rotation.x, -0.1, ke) - 0.2 * fe
	# всё тело: опускается на колени и падает лицом вниз
	rotation.x = fe * PI * 0.47
	rotation.z = collapse_side * 0.12 * fe
	position.y = lerpf(-0.24 * ke, 0.1, fe)
	# уши опадают
	ear_l.rotation.z = lerpf(ear_l.rotation.z, 0.5, ke)
	ear_r.rotation.z = lerpf(ear_r.rotation.z, -0.5, ke)
	if dead_eyes:
		eye_l.scale = Vector3(1.0, 0.08, 1.0)
		eye_r.scale = Vector3(1.0, 0.08, 1.0)
		jaw.rotation.x = 0.45
