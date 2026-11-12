extends Node3D
## Low-poly человек: суставы, ходьба, дыхание, мимика, моргание, взгляд, предметы в руке.
## Смотрит в сторону +Z.

const LowPoly = preload("res://Scripts/LowPoly.gd")
const PS1Mat = preload("res://Scripts/PS1Mat.gd")

## Гардероб девушки. cloak — исходный плащ. Остальное — обычная одежда.
const OUTFIT_ORDER := ["cloak", "dress", "sweater", "pajamas", "jacket", "underwear"]
const OUTFITS := {
	"cloak": {"label": "ПЛАЩ", "cloth": Color(0.13, 0.13, 0.16), "trim": Color(0.72, 0.72, 0.76), "shoes": Color(0.05, 0.05, 0.06),
		"cloak": true, "skirt": true, "skirt_len": 1.0, "sleeve_len": 1.0},
	"dress": {"label": "ПЛАТЬЕ", "cloth": Color(0.5, 0.66, 0.9), "trim": Color(0.95, 0.95, 0.97), "shoes": Color(0.9, 0.88, 0.9),
		"skirt": true, "skirt_len": 1.2, "sleeve_len": 0.4, "belt": true, "hem": true},
	"sweater": {"label": "СВИТЕР", "cloth": Color(0.3, 0.55, 0.38), "trim": Color(0.88, 0.82, 0.68), "shoes": Color(0.3, 0.2, 0.15),
		"pants_on": true, "pants": Color(0.2, 0.26, 0.42), "sleeve_len": 1.0, "scarf": true},
	"pajamas": {"label": "ПИЖАМА", "cloth": Color(0.82, 0.72, 0.9), "trim": Color(1.0, 1.0, 1.0), "shoes": Color(0.9, 0.8, 0.7),
		"pants_on": true, "sleeve_len": 1.0, "zip": true},
	"jacket": {"label": "КУРТКА", "cloth": Color(0.7, 0.18, 0.18), "trim": Color(0.92, 0.9, 0.9), "shoes": Color(0.08, 0.08, 0.09),
		"pants_on": true, "pants": Color(0.14, 0.15, 0.2), "sleeve_len": 1.0, "sleeve_w": 1.2, "body_w": 1.12, "scarf": true, "zip": true},
	"underwear": {"label": "НИЖНЕЕ БЕЛЬЁ", "underwear": true, "cloth": Color(0.82, 0.94, 0.98), "trim": Color(0.72, 0.8, 0.9),
		"shoes": Color(0.05, 0.05, 0.06), "skirt": false, "sleeve_len": 0.07, "bra": true, "panties": true},
}

var move_amount: float = 0.0
var seated: bool = false
var tied: bool = false
var cuffed: bool = false
var taped: bool = false  # запястья замотаны скотчем
var gagged: bool = false  # рот заклеен
var tape_marks: Array = []
var gag_parts: Array = []
var tremble: float = 0.0
var eyes_closed: bool = false
var droop: float = 0.0
var aim: float = 0.0
var look_node: Node3D = null

var upper: Node3D
var hip_l: Node3D
var hip_r: Node3D
var knee_l: Node3D
var knee_r: Node3D
var arm_l: Node3D
var arm_r: Node3D
var head: Node3D
var brow_l: MeshInstance3D
var brow_r: MeshInstance3D
var eye_l: MeshInstance3D
var eye_r: MeshInstance3D
var mouth: MeshInstance3D
var tear_l: MeshInstance3D
var tear_r: MeshInstance3D
var held: Dictionary = {}
var rope_marks: Array = []
var cuff_marks: Array = []
var is_girl: bool = false
var emotion: String = "neutral"
var talking: bool = false
var ahoge: Node3D
var ear_l: Node3D
var ear_r: Node3D
var skirt: Node3D
var outfit: String = "cloak"
var _oc: ShaderMaterial
var _os: ShaderMaterial
var _ot: ShaderMaterial
var _op: ShaderMaterial
var _osh: ShaderMaterial
var _skirt_mesh: MeshInstance3D
var _chest_part: MeshInstance3D
var _bra_parts: Array = []
var _panty_parts: Array = []
var _skin_albedo: Color = Color(0.9, 0.85, 0.82)
var _body_parts: Array = []
var _cloak_parts: Array = []
var _sleeve_parts: Array = []
var _pants_parts: Array = []
var _scarf_part: MeshInstance3D
var _belt_part: MeshInstance3D
var _hem_part: MeshInstance3D
var _zip_part: MeshInstance3D
var _mouth_scale: Vector2 = Vector2(1, 1)
## Износ одежды: у каждого наряда свой (0..1) и свои пятна крови (0..1).
## Видно как потемнение ткани, грязные пятна, потёртости и тёмные прорехи. Покрытие не меняется.
var wear: Dictionary = {}
var stain: Dictionary = {}
var _wear_marks: Array = []  # [{node, thr, kind, part}]
var _grime_mat: Material
var _tear_mat: ShaderMaterial
var _stain_mat: Material
var _ear_t: float = 3.0
var _ear_kick: float = 0.0

var _phase: float = 0.0
var _amp: float = 0.0
var _t: float = 0.0
var _eye_scale: Vector2 = Vector2(1, 1)
var _blink: float = 0.0
var _next_blink: float = 2.0

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

func build(m: Dictionary, long_hair: bool = false, style: String = "man") -> void:
	is_girl = style == "girl"
	var white: Material = m.get("white", m["skin"])
	var blood: Material = m.get("blood", m["black"])
	var lips: Material = m.get("lips", m["black"])
	var tear: Material = m.get("tear", white)
	var bruise: Material = m.get("bruise", m["skin"])
	var rope: Material = m.get("rope", m["black"])
	var metal: Material = m.get("metal", m["black"])
	var tape: Material = m.get("tape", metal)
	if is_girl:
		var skin_mat: Material = m["skin"]
		if skin_mat is ShaderMaterial:
			var sc = (skin_mat as ShaderMaterial).get_shader_parameter("albedo")
			if sc is Color:
				_skin_albedo = sc
		_oc = PS1Mat.make(Color(0.13, 0.13, 0.16))
		_os = PS1Mat.make(Color(0.13, 0.13, 0.16))
		_ot = PS1Mat.make(Color(0.72, 0.72, 0.76))
		_op = PS1Mat.make(Color(0.14, 0.14, 0.17))
		_osh = PS1Mat.make(Color(0.05, 0.05, 0.06))
	var cl: Material = _oc if is_girl else m["cloth"]
	upper = _pivot(self, Vector3.ZERO)
	# Торс, шея
	var torso := _mi(upper, LowPoly.frustum(6, 0.17, 0.21, 0.5, 0.7), cl, Vector3(0, 0.8, 0))
	_body_parts.append(torso)
	_mi(upper, LowPoly.frustum(5, 0.045, 0.05, 0.12), m["skin"], Vector3(0, 1.1, 0))
	if is_girl:
		# тёмный плащ с высоким воротником, светлая окантовка, пуговицы
		var trim: Material = _ot
		skirt = _pivot(self, Vector3(0, 0.62, 0))
		_skirt_mesh = _mi(skirt, LowPoly.frustum(7, 0.33, 0.2, 0.44), cl, Vector3(0, -0.2, 0))
		_cloak_parts.append(_mi(skirt, _box(Vector3(0.05, 0.4, 0.02)), trim, Vector3(0.0, -0.2, 0.2)))
		_hem_part = _mi(skirt, LowPoly.frustum(7, 0.345, 0.335, 0.03), trim, Vector3(0, -0.41, 0))
		_chest_part = _mi(upper, LowPoly.frustum(6, 0.21, 0.31, 0.2, 0.8), cl, Vector3(0, 1.0, 0))
		_body_parts.append(_chest_part)
		# нижнее бельё: бюстгалтер и трусики (видны только в наряде «underwear»)
		var bra_mat: Material = PS1Mat.make(Color(0.86, 0.9, 0.94))
		var panty_mat: Material = PS1Mat.make(Color(0.86, 0.9, 0.94))
		_bra_parts.append(_mi(upper, LowPoly.frustum(6, 0.07, 0.085, 0.1, 0.55), bra_mat, Vector3(-0.07, 0.93, 0.15)))
		_bra_parts.append(_mi(upper, LowPoly.frustum(6, 0.07, 0.085, 0.1, 0.55), bra_mat, Vector3(0.07, 0.93, 0.15)))
		_bra_parts.append(_mi(upper, _box(Vector3(0.16, 0.014, 0.014)), bra_mat, Vector3(0, 0.965, 0.15)))
		_panty_parts.append(_mi(self, LowPoly.frustum(7, 0.155, 0.13, 0.11), panty_mat, Vector3(0, 0.56, 0.02)))
		_panty_parts.append(_mi(self, _box(Vector3(0.02, 0.09, 0.03)), panty_mat, Vector3(-0.15, 0.55, 0.02)))
		_panty_parts.append(_mi(self, _box(Vector3(0.02, 0.09, 0.03)), panty_mat, Vector3(0.15, 0.55, 0.02)))
		for n in _bra_parts + _panty_parts:
			(n as Node3D).visible = false
		_cloak_parts.append(_mi(upper, _box(Vector3(0.22, 0.15, 0.2)), cl, Vector3(0, 1.1, 0)))
		_cloak_parts.append(_mi(upper, _box(Vector3(0.23, 0.02, 0.21)), trim, Vector3(0, 1.17, 0)))
		_cloak_parts.append(_mi(upper, _box(Vector3(0.025, 0.52, 0.012)), trim, Vector3(-0.045, 0.82, 0.16)))
		_cloak_parts.append(_mi(upper, _box(Vector3(0.025, 0.52, 0.012)), trim, Vector3(0.045, 0.82, 0.16)))
		_cloak_parts.append(_mi(upper, _box(Vector3(0.12, 0.45, 0.01)), m["black"], Vector3(0, 0.8, 0.158)))
		_cloak_parts.append(_mi(upper, _box(Vector3(0.04, 0.04, 0.012)), trim, Vector3(0, 0.95, 0.166)))
		_cloak_parts.append(_mi(upper, _box(Vector3(0.04, 0.04, 0.012)), trim, Vector3(0, 0.8, 0.166)))
		_cloak_parts.append(_mi(upper, _box(Vector3(0.1, 0.08, 0.01)), blood, Vector3(0.13, 0.7, 0.152)))
		# съёмные детали других нарядов: шарф, пояс, молния/пуговицы
		_scarf_part = _mi(upper, LowPoly.frustum(6, 0.1, 0.1, 0.07), trim, Vector3(0, 1.1, 0))
		_belt_part = _mi(upper, LowPoly.frustum(6, 0.19, 0.19, 0.04, 0.7), trim, Vector3(0, 0.62, 0))
		_zip_part = _mi(upper, _box(Vector3(0.02, 0.5, 0.012)), trim, Vector3(0, 0.82, 0.162))
	else:
		_mi(upper, _box(Vector3(0.34, 0.06, 0.24)), m["black"], Vector3(0, 0.59, 0.0))
	# Голова
	head = _pivot(upper, Vector3(0, 1.27, 0))
	_mi(head, LowPoly.sphere(Vector3(0.15, 0.17, 0.155), 6, 4), m["skin"])
	_mi(head, LowPoly.sphere(Vector3(0.165, 0.13, 0.17), 6, 3), m["hair"], Vector3(0, 0.07, -0.01))
	if is_girl:
		# длинные острые эльфийские уши
		ear_l = _pivot(head, Vector3(-0.14, -0.01, 0.0))
		ear_r = _pivot(head, Vector3(0.14, -0.01, 0.0))
		_mi(ear_l, LowPoly.frustum(3, 0.035, 0.004, 0.22), m["skin"], Vector3(-0.1, 0.03, 0.0), Vector3(0, 0, 72))
		_mi(ear_r, LowPoly.frustum(3, 0.035, 0.004, 0.22), m["skin"], Vector3(0.1, 0.03, 0.0), Vector3(0, 0, -72))
	else:
		_mi(head, _box(Vector3(0.03, 0.05, 0.035)), m["skin"], Vector3(-0.155, -0.01, 0.0))
		_mi(head, _box(Vector3(0.03, 0.05, 0.035)), m["skin"], Vector3(0.155, -0.01, 0.0))
	_mi(head, _box(Vector3(0.028, 0.045, 0.035)), m["skin"], Vector3(0, -0.03, 0.158))
	if is_girl:
		# короткая причёска с чёлкой, боковыми прядями и хохолком
		_mi(head, _box(Vector3(0.3, 0.05, 0.05)), m["hair"], Vector3(-0.02, 0.11, 0.135), Vector3(0, 0, 6))
		_mi(head, _box(Vector3(0.06, 0.12, 0.04)), m["hair"], Vector3(-0.08, 0.04, 0.15), Vector3(0, 0, -12))
		_mi(head, _box(Vector3(0.06, 0.12, 0.04)), m["hair"], Vector3(0.06, 0.04, 0.15), Vector3(0, 0, 14))
		_mi(head, _box(Vector3(0.05, 0.26, 0.12)), m["hair"], Vector3(-0.165, -0.08, 0.0))
		_mi(head, _box(Vector3(0.05, 0.3, 0.12)), m["hair"], Vector3(0.165, -0.1, 0.0), Vector3(0, 0, -4))
		_mi(head, _box(Vector3(0.32, 0.26, 0.07)), m["hair"], Vector3(0, -0.04, -0.13))
		ahoge = _pivot(head, Vector3(0.0, 0.2, 0.0))
		_mi(ahoge, _box(Vector3(0.018, 0.14, 0.018)), m["hair"], Vector3(0, 0.07, 0), Vector3(0, 0, -12))
		_mi(ahoge, _box(Vector3(0.018, 0.1, 0.018)), m["hair"], Vector3(0.04, 0.17, 0), Vector3(0, 0, -60))
	elif long_hair:
		_mi(head, _box(Vector3(0.34, 0.46, 0.09)), m["hair"], Vector3(0, -0.12, -0.13))
		_mi(head, _box(Vector3(0.05, 0.3, 0.13)), m["hair"], Vector3(-0.165, -0.07, 0.0))
		_mi(head, _box(Vector3(0.05, 0.3, 0.13)), m["hair"], Vector3(0.165, -0.07, 0.0))
		_mi(head, _box(Vector3(0.28, 0.05, 0.05)), m["hair"], Vector3(0, 0.1, 0.13), Vector3(0, 0, 4))
	else:
		_mi(head, _box(Vector3(0.28, 0.025, 0.02)), m["hair"], Vector3(0, -0.075, 0.15))
	# Лицо
	var wl := _mi(head, _box(Vector3(0.05, 0.04, 0.02)), white, Vector3(-0.06, 0.02, 0.145))
	var wr := _mi(head, _box(Vector3(0.05, 0.04, 0.02)), white, Vector3(0.06, 0.02, 0.145))
	wl.name = "WhiteL"
	wr.name = "WhiteR"
	eye_l = _mi(head, _box(Vector3(0.022, 0.032, 0.01)), m["black"], Vector3(-0.06, 0.02, 0.157))
	eye_r = _mi(head, _box(Vector3(0.022, 0.032, 0.01)), m["black"], Vector3(0.06, 0.02, 0.157))
	brow_l = _mi(head, _box(Vector3(0.06, 0.012, 0.02)), m["black"], Vector3(-0.06, 0.065, 0.148))
	brow_r = _mi(head, _box(Vector3(0.06, 0.012, 0.02)), m["black"], Vector3(0.06, 0.065, 0.148))
	mouth = _mi(head, _box(Vector3(0.07, 0.015, 0.02)), lips if is_girl else m["black"], Vector3(0, -0.07, 0.148))
	tear_l = _mi(head, _box(Vector3(0.012, 0.06, 0.01)), tear, Vector3(-0.075, -0.03, 0.152))
	tear_r = _mi(head, _box(Vector3(0.012, 0.06, 0.01)), tear, Vector3(0.075, -0.03, 0.152))
	tear_l.visible = false
	tear_r.visible = false
	if is_girl:
		gag_parts.append(_mi(head, _box(Vector3(0.13, 0.05, 0.016)), tape, Vector3(0, -0.07, 0.165)))
		gag_parts.append(_mi(head, _box(Vector3(0.012, 0.05, 0.1)), tape, Vector3(-0.15, -0.07, 0.1)))
		gag_parts.append(_mi(head, _box(Vector3(0.012, 0.05, 0.1)), tape, Vector3(0.15, -0.07, 0.1)))
		for g in gag_parts:
			(g as Node3D).visible = false
		_mi(head, _box(Vector3(0.06, 0.045, 0.01)), bruise, Vector3(-0.08, -0.025, 0.153))
		_mi(head, _box(Vector3(0.02, 0.025, 0.01)), blood, Vector3(0.025, -0.075, 0.153))
		_mi(head, _box(Vector3(0.015, 0.05, 0.01)), blood, Vector3(0.1, 0.035, 0.145))
	# Руки
	arm_l = _pivot(upper, Vector3(-0.27, 1.03, 0))
	arm_r = _pivot(upper, Vector3(0.27, 1.03, 0))
	for a in [arm_l, arm_r]:
		if is_girl:
			_mi(a, LowPoly.frustum(5, 0.034, 0.044, 0.48), m["skin"], Vector3(0, -0.24, 0))
			_sleeve_parts.append(_mi(a, LowPoly.frustum(5, 0.04, 0.052, 0.48), _os, Vector3(0, -0.24, 0)))
		else:
			_mi(a, LowPoly.frustum(5, 0.04, 0.052, 0.48), m["cloth"], Vector3(0, -0.24, 0))
		_mi(a, _box(Vector3(0.075, 0.075, 0.075)), m["skin"], Vector3(0, -0.51, 0))
		rope_marks.append(_mi(a, _box(Vector3(0.09, 0.05, 0.09)), rope, Vector3(0, -0.46, 0)))
		cuff_marks.append(_mi(a, _box(Vector3(0.095, 0.035, 0.095)), metal, Vector3(0, -0.44, 0)))
		tape_marks.append(_mi(a, _box(Vector3(0.1, 0.05, 0.1)), tape, Vector3(0, -0.47, 0)))
		(tape_marks[tape_marks.size() - 1] as Node3D).visible = false
	# Ноги
	hip_l = _pivot(self, Vector3(-0.1, 0.55, 0))
	hip_r = _pivot(self, Vector3(0.1, 0.55, 0))
	for h in [hip_l, hip_r]:
		_mi(h, LowPoly.frustum(5, 0.065, 0.088, 0.28), m["pants"] if not is_girl else m["skin"], Vector3(0, -0.14, 0))
		if is_girl:
			_pants_parts.append(_mi(h, LowPoly.frustum(5, 0.077, 0.1, 0.28), _op, Vector3(0, -0.14, 0)))
		var k := _pivot(h, Vector3(0, -0.28, 0))
		if is_girl:
			_pants_parts.append(_mi(k, LowPoly.frustum(5, 0.062, 0.077, 0.27), _op, Vector3(0, -0.135, 0)))
		_mi(k, LowPoly.frustum(5, 0.05, 0.065, 0.27), m["pants"] if not is_girl else m["skin"], Vector3(0, -0.135, 0))
		_mi(k, _box(Vector3(0.1, 0.06, 0.19)), _osh if is_girl else m["black"], Vector3(0, -0.25, 0.04))
		if h == hip_l:
			knee_l = k
		else:
			knee_r = k
	if is_girl:
		_build_wear_marks(blood)
	_build_held(m)
	set_emotion("neutral")
	if is_girl:
		set_outfit("cloak")

## Заклеить / освободить рот.
func set_gag(on: bool) -> void:
	gagged = on
	for g in gag_parts:
		(g as Node3D).visible = on
	if mouth != null:
		mouth.visible = not on

## Сменить одежду девушки (id из OUTFIT_ORDER).
func set_outfit(id: String) -> void:
	if not is_girl or not OUTFITS.has(id):
		return
	outfit = id
	var o: Dictionary = OUTFITS[id]
	var uw: bool = o.get("underwear", false)
	# в белье торс и руки — голые (цвет кожи), иначе цвет одежды
	_oc.set_shader_parameter("albedo", _skin_albedo if uw else o["cloth"])
	_os.set_shader_parameter("albedo", _skin_albedo if uw else o.get("sleeve", o["cloth"]))
	_ot.set_shader_parameter("albedo", o["trim"])
	_op.set_shader_parameter("albedo", o.get("pants", o["cloth"]))
	_osh.set_shader_parameter("albedo", o["shoes"])
	var cloak: bool = o.get("cloak", false)
	for n in _cloak_parts:
		(n as Node3D).visible = cloak
	var has_skirt: bool = o.get("skirt", false)
	skirt.visible = has_skirt
	var sl: float = o.get("skirt_len", 1.0)
	_skirt_mesh.scale = Vector3(1.0 + (sl - 1.0) * 0.6, sl, 1.0 + (sl - 1.0) * 0.6)
	_skirt_mesh.position.y = 0.02 - 0.22 * sl
	_hem_part.position.y = 0.02 - 0.44 * sl + 0.015
	_hem_part.scale = Vector3(1.0 + (sl - 1.0) * 0.6, 1.0, 1.0 + (sl - 1.0) * 0.6)
	_hem_part.visible = has_skirt and o.get("hem", false)
	for n in _pants_parts:
		(n as Node3D).visible = o.get("pants_on", false)
	var len_s: float = o.get("sleeve_len", 1.0)
	var w_s: float = o.get("sleeve_w", 1.0)
	for n in _sleeve_parts:
		var sm := n as MeshInstance3D
		sm.scale = Vector3(w_s, len_s, w_s)
		sm.position.y = -0.24 * len_s
	var bw: float = o.get("body_w", 1.0)
	for n in _body_parts:
		(n as Node3D).scale = Vector3(bw, 1.0, bw)
	_scarf_part.visible = o.get("scarf", false)
	_belt_part.visible = o.get("belt", false)
	_zip_part.visible = o.get("zip", false)
	# нижнее бельё
	_chest_part.visible = not uw
	for n in _bra_parts:
		(n as Node3D).visible = uw
	for n in _panty_parts:
		(n as Node3D).visible = uw
	_apply_wear()

## Пятна и прорехи. part: torso / skirt / sleeve / pants — показываются, только если эта часть одежды есть.
## Метки лежат прямо на гранях low-poly одежды (глубина считается по радиусу грани).
func _torso_z(y: float, back: bool) -> float:
	var z: float
	if y > 0.92:
		z = 0.866 * (0.21 + (y - 0.9) / 0.2 * 0.1) * 0.8   # грудь (_chest_part)
	else:
		z = 0.866 * (0.17 + (y - 0.55) / 0.5 * 0.04) * 0.7  # торс
	z += 0.006
	return -z if back else z

func _build_wear_marks(blood_mat: Material) -> void:
	_grime_mat = PS1Mat.make(Color(0.2, 0.17, 0.13))
	_tear_mat = PS1Mat.make(Color(0.04, 0.035, 0.035))
	_stain_mat = blood_mat
	var skirt_z := func(y: float, back: bool) -> float:
		var z := 0.93 * (0.265 - 0.2955 * y) + 0.006
		return -z if back else z
	var specs := [
		# [родитель, позиция, размер, порог, вид, часть]
		[upper, Vector3(-0.07, 0.68, _torso_z(0.68, false)), Vector3(0.08, 0.06, 0.008), 0.15, "dirt", "torso"],
		[upper, Vector3(0.06, 0.86, _torso_z(0.86, false)), Vector3(0.06, 0.05, 0.008), 0.3, "dirt", "torso"],
		[upper, Vector3(0.0, 0.78, _torso_z(0.78, true)), Vector3(0.12, 0.1, 0.008), 0.25, "dirt", "torso"],
		[upper, Vector3(0.07, 0.64, _torso_z(0.64, false)), Vector3(0.04, 0.022, 0.01), 0.55, "tear", "torso"],
		[upper, Vector3(-0.05, 0.88, _torso_z(0.88, true)), Vector3(0.05, 0.028, 0.01), 0.75, "tear", "torso"],
		[upper, Vector3(-0.08, 0.8, _torso_z(0.8, false)), Vector3(0.06, 0.08, 0.008), 0.2, "blood", "torso"],
		[upper, Vector3(0.04, 0.72, _torso_z(0.72, false)), Vector3(0.05, 0.1, 0.008), 0.55, "blood", "torso"],
		[_skirt_mesh, Vector3(0.1, -0.08, skirt_z.call(-0.08, false)), Vector3(0.09, 0.07, 0.008), 0.2, "dirt", "skirt"],
		[_skirt_mesh, Vector3(-0.12, -0.15, skirt_z.call(-0.15, false)), Vector3(0.07, 0.05, 0.008), 0.4, "dirt", "skirt"],
		[_skirt_mesh, Vector3(0.0, -0.1, skirt_z.call(-0.1, true)), Vector3(0.14, 0.1, 0.008), 0.35, "dirt", "skirt"],
		[_skirt_mesh, Vector3(-0.04, 0.02, skirt_z.call(0.02, false)), Vector3(0.04, 0.022, 0.01), 0.65, "tear", "skirt"],
		[_skirt_mesh, Vector3(0.06, 0.06, skirt_z.call(0.06, false)), Vector3(0.05, 0.08, 0.008), 0.4, "blood", "skirt"],
		[_sleeve_parts[0], Vector3(0.0, -0.06, 0.046), Vector3(0.035, 0.06, 0.008), 0.35, "dirt", "sleeve"],
		[_sleeve_parts[1], Vector3(0.0, 0.04, 0.046), Vector3(0.03, 0.025, 0.01), 0.7, "tear", "sleeve"],
		[_sleeve_parts[1], Vector3(0.0, -0.1, 0.046), Vector3(0.035, 0.07, 0.008), 0.3, "blood", "sleeve"],
		[_pants_parts[0], Vector3(0.0, -0.02, 0.078), Vector3(0.05, 0.06, 0.008), 0.3, "dirt", "pants"],
		[_pants_parts[2], Vector3(0.0, -0.06, 0.078), Vector3(0.04, 0.022, 0.01), 0.7, "tear", "pants"],
	]
	for sp in specs:
		var mat: Material = _grime_mat
		if sp[4] == "tear":
			mat = _tear_mat
		elif sp[4] == "blood":
			mat = _stain_mat
		var par: Node3D = sp[0]
		var pos: Vector3 = sp[1]
		if sp[5] == "torso":
			# крепим к мешу торса, чтобы метки росли вместе с шириной куртки
			par = _body_parts[0]
			pos.y -= 0.8
		var n := _mi(par, _box(sp[2]), mat, pos, Vector3(0, 0, randf_range(-25.0, 25.0)))
		n.visible = false
		_wear_marks.append({"node": n, "thr": sp[3], "kind": sp[4], "part": sp[5]})
		# у прорехи — светлые обтрёпанные нитки по краю
		if sp[4] == "tear":
			_mi(n, _box(Vector3(sp[2].x * 1.25, 0.006, 0.006)), _ot, Vector3(0, sp[2].y * 0.55, 0.003))

func get_wear() -> float:
	return float(wear.get(outfit, 0.0))

func get_stain() -> float:
	return float(stain.get(outfit, 0.0))

## Износить текущий наряд (amount 0..1) и/или запачкать кровью.
func add_wear(amount: float, blood_amount: float = 0.0) -> void:
	if not is_girl or OUTFITS[outfit].get("underwear", false):
		return
	wear[outfit] = clampf(get_wear() + amount, 0.0, 1.0)
	stain[outfit] = clampf(get_stain() + blood_amount, 0.0, 1.0)
	_apply_wear()

## Почистить / зашить.
func repair(amount: float, wash: bool = false) -> void:
	wear[outfit] = clampf(get_wear() - amount, 0.0, 1.0)
	if wash:
		stain[outfit] = 0.0
	_apply_wear()

func _apply_wear() -> void:
	if not is_girl or _wear_marks.is_empty():
		return
	var o: Dictionary = OUTFITS[outfit]
	var uw: bool = o.get("underwear", false)
	var w := get_wear()
	var b := get_stain()
	if not uw:
		# ткань тускнеет и сереет от грязи
		var grime := Color(0.22, 0.19, 0.15)
		var cc: Color = o["cloth"]
		_oc.set_shader_parameter("albedo", cc.lerp(grime, w * 0.45).darkened(w * 0.15))
		var sc: Color = o.get("sleeve", o["cloth"])
		_os.set_shader_parameter("albedo", sc.lerp(grime, w * 0.45).darkened(w * 0.15))
		var pc: Color = o.get("pants", o["cloth"])
		_op.set_shader_parameter("albedo", pc.lerp(grime, w * 0.4))
		var tc: Color = o["trim"]
		_ot.set_shader_parameter("albedo", tc.lerp(grime, w * 0.5))
		var cl: Color = o["cloth"]
		_tear_mat.set_shader_parameter("albedo", cl.darkened(0.8))
	var has := {
		"torso": not uw,
		"skirt": not uw and o.get("skirt", false),
		"sleeve": not uw and o.get("sleeve_len", 1.0) > 0.5,
		"pants": not uw and o.get("pants_on", false),
	}
	for mk in _wear_marks:
		var n: Node3D = mk["node"]
		var lvl := b if mk["kind"] == "blood" else w
		n.visible = has.get(mk["part"], false) and lvl >= float(mk["thr"])

func _build_held(m: Dictionary) -> void:
	var root := _pivot(arm_r, Vector3(0, -0.5, 0.05))
	var metal: Material = m.get("metal", m["black"])
	var wood: Material = m.get("wood", m["black"])
	var glass: Material = m.get("glass", m["black"])
	var blood: Material = m.get("blood", m["black"])
	var banana: Material = m.get("banana", m["skin"])
	var rope: Material = m.get("rope", m["black"])
	# Нож
	var knife := _pivot(root, Vector3.ZERO)
	_mi(knife, _box(Vector3(0.03, 0.035, 0.11)), wood, Vector3(0, 0, 0.0))
	_mi(knife, _box(Vector3(0.012, 0.05, 0.22)), metal, Vector3(0, 0.0, 0.16))
	_mi(knife, _box(Vector3(0.014, 0.02, 0.08)), blood, Vector3(0, 0.0, 0.2))
	held["knife"] = knife
	# Пистолет
	var pistol := _pivot(root, Vector3.ZERO)
	_mi(pistol, _box(Vector3(0.04, 0.06, 0.18)), m["black"], Vector3(0, 0.0, 0.08))
	_mi(pistol, _box(Vector3(0.025, 0.025, 0.1)), metal, Vector3(0, 0.01, 0.22))
	_mi(pistol, _box(Vector3(0.035, 0.09, 0.04)), m["black"], Vector3(0, -0.06, 0.02), Vector3(-12, 0, 0))
	held["pistol"] = pistol
	# Шприц
	var syr := _pivot(root, Vector3.ZERO)
	_mi(syr, LowPoly.frustum(6, 0.02, 0.02, 0.14), glass, Vector3(0, 0, 0.09), Vector3(90, 0, 0))
	_mi(syr, _box(Vector3(0.006, 0.006, 0.08)), metal, Vector3(0, 0, 0.2))
	_mi(syr, _box(Vector3(0.05, 0.012, 0.012)), m["black"], Vector3(0, 0, 0.0))
	held["syringe"] = syr
	# Банан
	var ban := _pivot(root, Vector3.ZERO)
	_mi(ban, _box(Vector3(0.04, 0.04, 0.12)), banana, Vector3(0, 0, 0.08))
	_mi(ban, _box(Vector3(0.035, 0.035, 0.07)), banana, Vector3(0, 0.025, 0.16), Vector3(-30, 0, 0))
	held["banana"] = ban
	# Верёвка
	var rp := _pivot(root, Vector3.ZERO)
	_mi(rp, LowPoly.frustum(7, 0.07, 0.07, 0.06), rope, Vector3(0, 0, 0.06), Vector3(90, 0, 0))
	held["rope"] = rp
	# Ломик
	var bar := _pivot(root, Vector3.ZERO)
	_mi(bar, _box(Vector3(0.025, 0.025, 0.36)), metal, Vector3(0, 0, 0.14))
	_mi(bar, _box(Vector3(0.025, 0.07, 0.025)), metal, Vector3(0, 0.03, 0.31))
	held["crowbar"] = bar
	# Наручники
	var cf := _pivot(root, Vector3.ZERO)
	_mi(cf, LowPoly.frustum(6, 0.045, 0.045, 0.02), metal, Vector3(-0.04, 0, 0.05), Vector3(90, 0, 0))
	_mi(cf, LowPoly.frustum(6, 0.045, 0.045, 0.02), metal, Vector3(0.04, 0, 0.05), Vector3(90, 0, 0))
	_mi(cf, _box(Vector3(0.06, 0.01, 0.01)), metal, Vector3(0, 0, 0.05))
	held["cuffs"] = cf
	# Банка с ядом
	var jar := _pivot(root, Vector3.ZERO)
	_mi(jar, LowPoly.frustum(6, 0.05, 0.05, 0.1), glass, Vector3(0, 0, 0.07))
	_mi(jar, LowPoly.frustum(6, 0.03, 0.03, 0.03), m["black"], Vector3(0, 0.065, 0.07))
	held["poison"] = jar
	show_held("")

func show_held(id: String) -> void:
	for k in held:
		(held[k] as Node3D).visible = (k == id)

## neutral / fear / happy / sad / angry
func set_emotion(e: String) -> void:
	emotion = e
	var tilt := 0.0
	var lift := 0.0
	var eye_s := Vector2(1, 1)
	var mouth_s := Vector2(1, 1)
	var mouth_y := -0.07
	match e:
		"fear":
			tilt = 0.5; lift = 0.014; eye_s = Vector2(1.3, 1.5); mouth_s = Vector2(0.7, 3.2); mouth_y = -0.075
		"happy":
			tilt = 0.0; lift = 0.012; eye_s = Vector2(1.1, 0.55); mouth_s = Vector2(1.6, 1.4); mouth_y = -0.065
		"sad":
			tilt = 0.35; lift = 0.0; eye_s = Vector2(1.0, 0.8); mouth_s = Vector2(0.8, 1.0); mouth_y = -0.085
		"angry":
			tilt = -0.45; lift = -0.012; eye_s = Vector2(1.0, 0.7); mouth_s = Vector2(1.1, 1.3); mouth_y = -0.075
		_:
			if is_girl:
				eye_s = Vector2(1.2, 0.8)
	brow_l.rotation.z = tilt
	brow_r.rotation.z = -tilt
	brow_l.position.y = 0.065 + lift
	brow_r.position.y = 0.065 + lift
	_eye_scale = eye_s
	_mouth_scale = mouth_s
	mouth.scale = Vector3(mouth_s.x, mouth_s.y, 1.0)
	mouth.position.y = mouth_y
	var cry := is_girl and (e == "fear" or e == "sad")
	tear_l.visible = cry
	tear_r.visible = cry

func _process(delta: float) -> void:
	_t += delta
	_amp = lerpf(_amp, move_amount, clampf(10.0 * delta, 0.0, 1.0))
	if _amp > 0.05:
		_phase += delta * (7.0 + 5.0 * _amp)
	var s := sin(_phase)
	if seated:
		hip_l.rotation = Vector3(-1.5, 0, 0)
		hip_r.rotation = Vector3(-1.5, 0, 0)
		knee_l.rotation = Vector3(1.5, 0, 0)
		knee_r.rotation = Vector3(1.5, 0, 0)
	else:
		hip_l.rotation = Vector3(-s * 0.75 * _amp, 0, 0)
		hip_r.rotation = Vector3(s * 0.75 * _amp, 0, 0)
		knee_l.rotation = Vector3(maxf(0.0, s) * 0.9 * _amp, 0, 0)
		knee_r.rotation = Vector3(maxf(0.0, -s) * 0.9 * _amp, 0, 0)
	if tied or cuffed or taped:
		arm_l.rotation = Vector3(0.55, 0, 0.35)
		arm_r.rotation = Vector3(0.55, 0, -0.35)
	elif aim > 0.01:
		arm_l.rotation = Vector3(s * 0.65 * _amp, 0, 0.04)
		arm_r.rotation = Vector3(-1.45 * aim, 0, -0.05)
	else:
		arm_l.rotation = Vector3(s * 0.65 * _amp, 0, 0.04)
		arm_r.rotation = Vector3(-s * 0.65 * _amp, 0, -0.04)
	for r in rope_marks:
		(r as Node3D).visible = tied
	for c in cuff_marks:
		(c as Node3D).visible = cuffed and not tied
	for t in tape_marks:
		(t as Node3D).visible = taped and not tied and not cuffed
	upper.position.y = sin(_t * 2.2) * 0.006 + absf(s) * 0.025 * _amp
	head.rotation.z = sin(_t * 31.0) * 0.03 * tremble
	head.rotation.x = (0.12 if tied else 0.0) + droop
	# взгляд
	var yaw := 0.0
	if look_node != null and is_instance_valid(look_node) and not eyes_closed:
		var d := to_local(look_node.global_position)
		yaw = clampf(atan2(d.x, d.z), -0.9, 0.9)
	head.rotation.y = lerpf(head.rotation.y, yaw, clampf(6.0 * delta, 0.0, 1.0))
	# моргание / закрытые глаза
	_next_blink -= delta
	if _next_blink <= 0.0:
		_blink = 0.12
		_next_blink = randf_range(1.5, 4.5)
	_blink -= delta
	var ey := _eye_scale.y
	if eyes_closed or _blink > 0.0:
		ey = 0.12
	eye_l.scale = Vector3(_eye_scale.x, ey, 1.0)
	eye_r.scale = Vector3(_eye_scale.x, ey, 1.0)
	if is_girl:
		head.rotation.z += sin(_t * 0.8) * 0.05
		head.rotation.x += sin(_t * 7.0) * 0.04 if talking else 0.0
		ahoge.rotation.z = sin(_t * 2.0) * 0.25
		skirt.rotation.x = s * 0.12 * _amp
		_ear_t -= delta
		if _ear_t <= 0.0:
			_ear_t = randf_range(3.0, 7.0)
			_ear_kick = 0.25
		_ear_kick = maxf(0.0, _ear_kick - delta)
		var tw := sin(_ear_kick * 50.0) * 0.3 if _ear_kick > 0.0 else 0.0
		ear_l.rotation.z = -tw
		ear_r.rotation.z = tw
	if talking:
		mouth.scale = Vector3(_mouth_scale.x, _mouth_scale.y * (1.0 + 1.2 * absf(sin(_t * 11.0))), 1.0)
	else:
		mouth.scale = Vector3(_mouth_scale.x, _mouth_scale.y, 1.0)
