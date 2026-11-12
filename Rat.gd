extends Node3D
## Подвальная крыса. Сама не нападает: бродит вдоль стен и убегает от героя.
## Если её ударить или выстрелить рядом — злится, кусает за ноги, потом успокаивается.

const LowPoly = preload("res://Scripts/LowPoly.gd")
const PS1Mat = preload("res://Scripts/PS1Mat.gd")

var hp: int = 2
var dead: bool = false
var stun: float = 0.0
var bite_cd: float = 1.0
var retreat: float = 0.0
var knock: Vector3 = Vector3.ZERO
var speed: float = 2.3
var angry: float = 0.0   # >0 — крыса зла и атакует (секунды)
var _target: Vector3 = Vector3.ZERO
var _wait: float = 2.0
var _flee: float = 0.0
var lunge: float = 0.0
var _t: float = 0.0
var _body: Node3D
var _tail: Node3D
var _legs: Array = []
var _hit_flash: float = 0.0
var _fur: ShaderMaterial
var _dead_t: float = 0.0

func _mi(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	m.material_override = mat
	m.position = pos
	m.rotation = rot
	parent.add_child(m)
	return m

func build() -> void:
	_fur = PS1Mat.make(Color(0.24, 0.2, 0.18))
	var belly := PS1Mat.make(Color(0.38, 0.32, 0.28))
	var pink := PS1Mat.make(Color(0.72, 0.45, 0.45))
	var eye := PS1Mat.make(Color(0.9, 0.08, 0.05), null, 1.0, 1.6)
	var tooth := PS1Mat.make(Color(0.9, 0.85, 0.6))
	_body = Node3D.new()
	_body.position.y = 0.11
	add_child(_body)
	_mi(_body, LowPoly.sphere(Vector3(0.1, 0.085, 0.17), 6, 4), _fur, Vector3.ZERO)
	_mi(_body, LowPoly.sphere(Vector3(0.075, 0.05, 0.12), 5, 3), belly, Vector3(0, -0.04, 0.01))
	# горб на спине — шерсть дыбом
	_mi(_body, LowPoly.sphere(Vector3(0.07, 0.05, 0.1), 5, 3), _fur, Vector3(0, 0.06, -0.03))
	var head := Node3D.new()
	head.position = Vector3(0, 0.02, 0.15)
	_body.add_child(head)
	_mi(head, LowPoly.frustum(6, 0.065, 0.014, 0.15), _fur, Vector3(0, 0, 0.06), Vector3(PI * 0.5, 0, 0))
	_mi(head, LowPoly.sphere(Vector3(0.016, 0.014, 0.016), 4, 3), pink, Vector3(0, 0, 0.135))
	for sx in [-1.0, 1.0]:
		_mi(head, LowPoly.sphere(Vector3(0.03, 0.035, 0.01), 5, 3), pink, Vector3(sx * 0.045, 0.05, 0.0), Vector3(0, sx * 0.4, 0))
		_mi(head, LowPoly.sphere(Vector3(0.012, 0.012, 0.012), 4, 3), eye, Vector3(sx * 0.03, 0.025, 0.06))
		_mi(head, LowPoly.frustum(3, 0.002, 0.002, 0.09), tooth, Vector3(sx * 0.045, -0.005, 0.12), Vector3(0, 0, sx * 1.3))
	_mi(head, LowPoly.frustum(3, 0.006, 0.002, 0.02), tooth, Vector3(0, -0.02, 0.125))
	# хвост из трёх звеньев
	_tail = Node3D.new()
	_tail.position = Vector3(0, -0.01, -0.16)
	_body.add_child(_tail)
	var seg := _tail
	for i in 3:
		_mi(seg, LowPoly.frustum(4, 0.014 - i * 0.004, 0.01 - i * 0.003, 0.12), pink, Vector3(0, 0, -0.06), Vector3(PI * 0.5, 0, 0))
		var nxt := Node3D.new()
		nxt.position = Vector3(0, 0, -0.12)
		seg.add_child(nxt)
		seg = nxt
	# лапки
	for p in [Vector3(-0.07, -0.07, 0.09), Vector3(0.07, -0.07, 0.09), Vector3(-0.07, -0.07, -0.09), Vector3(0.07, -0.07, -0.09)]:
		var leg := Node3D.new()
		leg.position = p
		_body.add_child(leg)
		_mi(leg, LowPoly.frustum(4, 0.016, 0.012, 0.06), pink, Vector3(0, -0.02, 0))
		_legs.append(leg)

## Шаг ИИ. target — позиция игрока. Возвращает true, если крыса укусила в этом кадре.
func step(target: Vector3, delta: float, frozen: bool) -> bool:
	_t += delta
	_hit_flash = maxf(0.0, _hit_flash - delta * 4.0)
	_fur.set_shader_parameter("albedo", Color(0.24, 0.2, 0.18).lerp(Color(1.0, 0.9, 0.85), _hit_flash))
	if dead:
		_dead_t += delta
		for i in _legs.size():
			(_legs[i] as Node3D).rotation.x = sin(_dead_t * 30.0 + i) * 0.5 * maxf(0.0, 1.0 - _dead_t)
		_body.rotation.z = lerpf(_body.rotation.z, PI, clampf(delta * 10.0, 0.0, 1.0))
		_body.position.y = lerpf(_body.position.y, 0.09, clampf(delta * 8.0, 0.0, 1.0))
		position += knock * delta
		knock = knock.lerp(Vector3.ZERO, clampf(delta * 6.0, 0.0, 1.0))
		return false
	if frozen:
		return false
	stun = maxf(0.0, stun - delta)
	bite_cd = maxf(0.0, bite_cd - delta)
	retreat = maxf(0.0, retreat - delta)
	lunge = maxf(0.0, lunge - delta * 3.0)
	angry = maxf(0.0, angry - delta)
	var to := target - position
	to.y = 0.0
	var d := to.length()
	var dir := to / maxf(d, 0.001)
	var move := Vector3.ZERO
	var spd := speed
	if stun > 0.0:
		move = Vector3.ZERO
	elif angry > 0.0:
		if retreat > 0.0:
			move = (-dir + Vector3(-dir.z, 0, dir.x) * 0.8).normalized() * speed * 0.9
		elif d > 0.55:
			var wobble := Vector3(-dir.z, 0, dir.x) * sin(_t * 5.0) * 0.45
			move = (dir + wobble).normalized() * speed
	else:
		# мирная: бродит вдоль стен, от героя держится подальше
		spd = 1.5
		if d < 1.5:
			_flee = 0.6
		_flee = maxf(0.0, _flee - delta)
		if _flee > 0.0:
			move = (-dir + Vector3(-dir.z, 0, dir.x) * 0.3).normalized() * 2.0
			_target = position - dir * 2.5
		else:
			var tt := _target - position
			tt.y = 0.0
			if tt.length() < 0.15:
				_wait -= delta
				if _wait <= 0.0:
					_wait = randf_range(2.5, 9.0)
					var wall_z := -4.5 if randf() < 0.65 else 4.5
					_target = Vector3(randf_range(-5.4, 5.4), 0.0, wall_z + randf_range(-0.2, 0.2))
			else:
				move = tt.normalized() * spd
	position += (move + knock) * delta
	knock = knock.lerp(Vector3.ZERO, clampf(delta * 7.0, 0.0, 1.0))
	position.x = clampf(position.x, -5.9, 12.6)
	position.z = clampf(position.z, -4.7, 4.7)
	var face := move if move.length() > 0.1 else (dir if angry > 0.0 else Vector3.ZERO)
	if face.length() > 0.01:
		rotation.y = lerp_angle(rotation.y, atan2(face.x, face.z), clampf(delta * 12.0, 0.0, 1.0))
	var run := clampf(move.length() / speed, 0.0, 1.0)
	for i in _legs.size():
		(_legs[i] as Node3D).rotation.x = sin(_t * 26.0 + (PI if i % 2 == 0 else 0.0) + (0.0 if i < 2 else PI * 0.5)) * 0.9 * run
	_body.position.y = 0.11 + absf(sin(_t * 26.0)) * 0.02 * run + lunge * 0.06
	_body.rotation.x = -lunge * 0.4
	_tail.rotation.y = sin(_t * 9.0) * 0.5
	_tail.rotation.x = 0.15 + sin(_t * 3.0) * 0.1
	if angry > 0.0 and stun <= 0.0 and retreat <= 0.0 and bite_cd <= 0.0 and d < 0.62:
		bite_cd = randf_range(1.1, 1.7)
		retreat = randf_range(0.5, 0.9)
		lunge = 1.0
		return true
	return false

## Разозлить крысу (её задели или ударили рядом).
func provoke(secs: float = 18.0) -> void:
	if dead:
		return
	if angry <= 0.0:
		bite_cd = maxf(bite_cd, 0.6)
	angry = maxf(angry, secs)

## Удар по крысе. Возвращает true, если удар её убил.
func hit(dmg: int, from_dir: Vector3, force: float) -> bool:
	if dead:
		return false
	hp -= dmg
	_hit_flash = 1.0
	stun = 0.45
	retreat = 0.0
	knock = from_dir.normalized() * force
	provoke()
	if hp <= 0:
		dead = true
		knock *= 1.3
		return true
	return false
