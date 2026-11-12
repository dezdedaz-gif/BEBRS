extends RefCounted
## Low-poly модели предметов по референсу: тёмный металл, красные потёки, пиксельная фактура.
## Все модели лежат вдоль +Z (удобно держать в руке).

const LowPoly = preload("res://Scripts/LowPoly.gd")

static func _b(p: Node3D, size: Vector3, mat: Material, pos: Vector3 = Vector3.ZERO, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot
	p.add_child(mi)
	return mi

static func _f(p: Node3D, sides: int, rb: float, rt: float, h: float, mat: Material, pos: Vector3 = Vector3.ZERO, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = LowPoly.frustum(sides, rb, rt, h)
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot
	p.add_child(mi)
	return mi

static func _ring(p: Node3D, center: Vector3, r: float, mat: Material, n: int = 8) -> void:
	for k in n:
		var a := TAU * float(k) / float(n)
		_b(p, Vector3(0.022, 0.022, 0.03), mat, center + Vector3(cos(a) * r, sin(a) * r, 0.0), Vector3(0, 0, rad_to_deg(a)))

static func make(id: String, m: Dictionary) -> Node3D:
	var n := Node3D.new()
	var dark: Material = m.get("it_dark", m["black"])
	var red: Material = m.get("it_red", m["blood"])
	var metal: Material = m.get("it_metal", m["metal"])
	var rope: Material = m.get("it_rope", m["wood"])
	var yellow: Material = m.get("it_yellow", m["banana"])
	var glass: Material = m.get("glass", dark)
	var brass: Material = m.get("it_brass", metal)
	match id:
		"pistol":
			_b(n, Vector3(0.036, 0.04, 0.2), dark, Vector3(0, 0.03, 0.04))
			_b(n, Vector3(0.037, 0.02, 0.07), red, Vector3(0, 0.035, -0.02))
			_b(n, Vector3(0.02, 0.02, 0.04), metal, Vector3(0, 0.03, 0.15))
			_b(n, Vector3(0.034, 0.1, 0.05), dark, Vector3(0, -0.04, -0.03), Vector3(-15, 0, 0))
			_b(n, Vector3(0.01, 0.03, 0.05), metal, Vector3(0, -0.01, 0.03))
			_b(n, Vector3(0.012, 0.012, 0.012), metal, Vector3(0, 0.055, 0.12))
		"knife":
			_b(n, Vector3(0.026, 0.03, 0.1), dark, Vector3(0, 0, -0.05))
			_b(n, Vector3(0.05, 0.014, 0.02), red, Vector3(0, 0, 0.005))
			_b(n, Vector3(0.012, 0.04, 0.16), metal, Vector3(0, 0, 0.09))
			_b(n, Vector3(0.013, 0.025, 0.07), red, Vector3(0, -0.005, 0.07))
			_f(n, 4, 0.02, 0.002, 0.05, metal, Vector3(0, 0, 0.19), Vector3(90, 0, 0))
		"rope":
			for i in 3:
				_f(n, 8, 0.09, 0.09, 0.03, rope, Vector3(0, i * 0.026, 0.06))
			_f(n, 6, 0.04, 0.04, 0.09, dark, Vector3(0, 0.04, 0.06))
			_b(n, Vector3(0.02, 0.02, 0.09), rope, Vector3(0.1, 0.0, 0.1), Vector3(0, 40, 0))
		"cuffs":
			_ring(n, Vector3(-0.06, 0, 0), 0.04, metal)
			_ring(n, Vector3(0.06, 0, 0), 0.04, metal)
			_b(n, Vector3(0.03, 0.02, 0.03), dark, Vector3(-0.06, 0.05, 0))
			_b(n, Vector3(0.03, 0.02, 0.03), dark, Vector3(0.06, 0.05, 0))
			for k in 3:
				_b(n, Vector3(0.02, 0.012, 0.012), metal, Vector3(-0.02 + k * 0.02, 0.07 + (0.015 if k == 1 else 0.0), 0.0))
		"poison":
			_b(n, Vector3(0.07, 0.11, 0.04), dark, Vector3(0, 0, 0))
			_b(n, Vector3(0.05, 0.03, 0.035), dark, Vector3(0, 0.07, 0))
			_b(n, Vector3(0.03, 0.04, 0.03), dark, Vector3(0, 0.105, 0))
			_b(n, Vector3(0.04, 0.025, 0.04), red, Vector3(0, 0.14, 0))
			_b(n, Vector3(0.05, 0.045, 0.005), red, Vector3(0, 0.01, 0.022))
			_b(n, Vector3(0.01, 0.012, 0.006), dark, Vector3(-0.012, 0.012, 0.025))
			_b(n, Vector3(0.01, 0.012, 0.006), dark, Vector3(0.012, 0.012, 0.025))
			_b(n, Vector3(0.05, 0.008, 0.006), red, Vector3(0, -0.03, 0.022), Vector3(0, 0, 25))
			_b(n, Vector3(0.05, 0.008, 0.006), red, Vector3(0, -0.03, 0.022), Vector3(0, 0, -25))
		"crowbar":
			_b(n, Vector3(0.02, 0.02, 0.34), red, Vector3(0, 0, 0.14))
			_b(n, Vector3(0.02, 0.02, 0.08), red, Vector3(0, 0.03, 0.33), Vector3(-35, 0, 0))
			_b(n, Vector3(0.016, 0.016, 0.06), metal, Vector3(0, 0.065, 0.37), Vector3(-70, 0, 0))
			_b(n, Vector3(0.02, 0.02, 0.05), dark, Vector3(0, -0.02, -0.04), Vector3(30, 0, 0))
		"banana":
			_b(n, Vector3(0.04, 0.04, 0.07), yellow, Vector3(0, 0, 0))
			_b(n, Vector3(0.04, 0.04, 0.07), yellow, Vector3(0, 0.012, 0.065), Vector3(-15, 0, 0))
			_b(n, Vector3(0.036, 0.036, 0.07), yellow, Vector3(0, 0.04, 0.12), Vector3(-35, 0, 0))
			_b(n, Vector3(0.02, 0.02, 0.025), dark, Vector3(0, 0.07, 0.15))
			_b(n, Vector3(0.02, 0.02, 0.025), dark, Vector3(0, -0.005, -0.045))
			_b(n, Vector3(0.042, 0.018, 0.04), red, Vector3(0, 0.01, 0.03))
		"beartrap":
			for k in 10:
				var a := TAU * float(k) / 10.0
				_b(n, Vector3(0.06, 0.012, 0.02), dark, Vector3(cos(a) * 0.13, 0.01, sin(a) * 0.13), Vector3(0, -rad_to_deg(a), 0))
				_f(n, 3, 0.012, 0.002, 0.06, metal, Vector3(cos(a) * 0.13, 0.05, sin(a) * 0.13))
			_b(n, Vector3(0.26, 0.015, 0.03), dark, Vector3(0, 0.012, 0))
			_b(n, Vector3(0.08, 0.02, 0.05), red, Vector3(0, 0.02, 0))
		"syringe":
			_f(n, 6, 0.015, 0.015, 0.1, glass, Vector3(0, 0, 0.06), Vector3(90, 0, 0))
			_b(n, Vector3(0.02, 0.02, 0.05), red, Vector3(0, 0, 0.06))
			_b(n, Vector3(0.006, 0.006, 0.07), metal, Vector3(0, 0, -0.03))
			_b(n, Vector3(0.035, 0.006, 0.008), dark, Vector3(0, 0, -0.07))
			_b(n, Vector3(0.05, 0.008, 0.01), dark, Vector3(0, 0, 0.01))
			_b(n, Vector3(0.004, 0.004, 0.06), metal, Vector3(0, 0, 0.15))
		"key":
			_ring(n, Vector3(0, 0, -0.04), 0.03, brass)
			_b(n, Vector3(0.014, 0.014, 0.12), brass, Vector3(0, 0, 0.05))
			_b(n, Vector3(0.014, 0.03, 0.02), brass, Vector3(0, -0.02, 0.09))
			_b(n, Vector3(0.014, 0.02, 0.02), brass, Vector3(0, -0.015, 0.06))
		"note":
			_b(n, Vector3(0.1, 0.004, 0.14), m.get("paper", dark), Vector3(0, 0, 0.05), Vector3(0, 10, 0))
			_b(n, Vector3(0.06, 0.005, 0.008), dark, Vector3(0, 0.003, 0.03))
			_b(n, Vector3(0.05, 0.005, 0.008), dark, Vector3(0, 0.003, 0.06))
		"bandage":
			_f(n, 8, 0.05, 0.05, 0.06, m.get("white", dark), Vector3(0, 0, 0.0), Vector3(0, 0, 90))
			_b(n, Vector3(0.012, 0.062, 0.1), red, Vector3(0, 0, 0.0))
			_b(n, Vector3(0.1, 0.012, 0.04), m.get("white", dark), Vector3(0, 0.0, 0.07), Vector3(0, 20, 0))
		"medkit":
			_b(n, Vector3(0.16, 0.1, 0.07), m.get("white", dark), Vector3(0, 0, 0.0))
			_b(n, Vector3(0.1, 0.03, 0.01), red, Vector3(0, 0, 0.04))
			_b(n, Vector3(0.03, 0.1, 0.01), red, Vector3(0, 0, 0.04))
			_b(n, Vector3(0.06, 0.02, 0.03), dark, Vector3(0, 0.06, 0.0))
		"water":
			_f(n, 8, 0.03, 0.03, 0.12, glass, Vector3(0, 0, 0.0))
			_f(n, 6, 0.012, 0.012, 0.03, m.get("white", dark), Vector3(0, 0.075, 0.0))
			_b(n, Vector3(0.062, 0.03, 0.062), m.get("it_cyan", glass), Vector3(0, -0.01, 0.0))
		"chocolate":
			_b(n, Vector3(0.07, 0.012, 0.12), m.get("bruise", dark), Vector3(0, 0, 0.0))
			for r in 3:
				for c in 2:
					_b(n, Vector3(0.028, 0.006, 0.032), dark, Vector3(-0.017 + c * 0.034, 0.008, -0.04 + r * 0.04))
			_b(n, Vector3(0.072, 0.014, 0.05), red, Vector3(0, 0.0, 0.07))
		"canned":
			_f(n, 8, 0.04, 0.04, 0.08, metal, Vector3(0, 0, 0.0))
			_f(n, 8, 0.041, 0.041, 0.04, red, Vector3(0, 0, 0.0))
		"beans":
			_f(n, 8, 0.04, 0.04, 0.08, metal, Vector3(0, 0, 0.0))
			_f(n, 8, 0.034, 0.034, 0.012, m.get("bruise", red), Vector3(0, 0.04, 0.0))
			_b(n, Vector3(0.02, 0.004, 0.03), metal, Vector3(0.03, 0.05, 0.0), Vector3(0, 0, 40))
		"lighter":
			_b(n, Vector3(0.03, 0.06, 0.014), metal, Vector3(0, 0, 0.0))
			_b(n, Vector3(0.026, 0.02, 0.012), dark, Vector3(0, 0.04, 0.0))
			_b(n, Vector3(0.012, 0.022, 0.008), yellow, Vector3(0, 0.06, 0.0))
		"flashlight":
			_f(n, 6, 0.02, 0.02, 0.14, dark, Vector3(0, 0, 0.0), Vector3(90, 0, 0))
			_f(n, 8, 0.03, 0.03, 0.04, metal, Vector3(0, 0, 0.09), Vector3(90, 0, 0))
			_b(n, Vector3(0.036, 0.036, 0.006), yellow, Vector3(0, 0, 0.112))
			_b(n, Vector3(0.012, 0.008, 0.02), red, Vector3(0, 0.022, 0.0))
		"lockpick":
			_b(n, Vector3(0.008, 0.008, 0.14), metal, Vector3(0, 0, 0.05))
			_b(n, Vector3(0.008, 0.02, 0.01), metal, Vector3(0, 0.01, 0.12))
			_b(n, Vector3(0.012, 0.012, 0.05), dark, Vector3(0, 0, -0.05))
			_b(n, Vector3(0.008, 0.008, 0.12), metal, Vector3(0.02, 0, 0.04), Vector3(0, 8, 0))
		"sylphy":
			var fur: Material = m.get("trim", m.get("white", dark))
			var hair: Material = m.get("it_green", yellow)
			_b(n, Vector3(0.08, 0.1, 0.05), fur, Vector3(0, 0, 0.0))
			_b(n, Vector3(0.095, 0.085, 0.085), fur, Vector3(0, 0.1, 0.0))
			_b(n, Vector3(0.1, 0.03, 0.09), hair, Vector3(0, 0.15, 0.0))
			_b(n, Vector3(0.02, 0.012, 0.01), dark, Vector3(-0.022, 0.1, 0.044))
			_b(n, Vector3(0.02, 0.012, 0.01), dark, Vector3(0.022, 0.1, 0.044))
			_b(n, Vector3(0.012, 0.012, 0.03), fur, Vector3(-0.055, 0.1, 0.0), Vector3(0, 0, 20))
			_b(n, Vector3(0.012, 0.012, 0.03), fur, Vector3(0.055, 0.1, 0.0), Vector3(0, 0, -20))
			_b(n, Vector3(0.03, 0.09, 0.03), fur, Vector3(-0.058, 0.0, 0.0), Vector3(0, 0, 12))
			_b(n, Vector3(0.03, 0.09, 0.03), fur, Vector3(0.058, 0.0, 0.0), Vector3(0, 0, -12))
		"tape":
			var tp: Material = m.get("tape", metal)
			_f(n, 10, 0.05, 0.05, 0.05, tp, Vector3(0, 0, 0), Vector3(0, 0, 90))
			_f(n, 8, 0.028, 0.028, 0.054, dark, Vector3(0, 0, 0), Vector3(0, 0, 90))
			_b(n, Vector3(0.05, 0.004, 0.045), tp, Vector3(0, -0.05, 0.03), Vector3(18, 0, 0))
		_:
			_b(n, Vector3(0.08, 0.08, 0.08), dark)
	return n
