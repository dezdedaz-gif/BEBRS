extends RefCounted
## Генератор low-poly мешей с плоскими гранями (без внешних ассетов).
## Все формы выпуклые и построены вокруг начала координат, поэтому ориентация
## треугольников подбирается автоматически (грань всегда смотрит наружу).

static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var n := (a - c).cross(a - b)
	var mid := (a + b + c) / 3.0
	if n.dot(mid) < 0.0:
		var t := b
		b = c
		c = t
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)

static func _begin() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	return st

## Усечённый конус / цилиндр с `sides` гранями. z_scale сплющивает по глубине.
static func frustum(sides: int, r_bottom: float, r_top: float, height: float, z_scale: float = 1.0) -> ArrayMesh:
	var st := _begin()
	var h := height * 0.5
	var bc := Vector3(0.0, -h, 0.0)
	var tc := Vector3(0.0, h, 0.0)
	r_top = maxf(r_top, 0.001)
	r_bottom = maxf(r_bottom, 0.001)
	for i in sides:
		var a0 := TAU * float(i) / float(sides)
		var a1 := TAU * float(i + 1) / float(sides)
		var b0 := Vector3(cos(a0) * r_bottom, -h, sin(a0) * r_bottom * z_scale)
		var b1 := Vector3(cos(a1) * r_bottom, -h, sin(a1) * r_bottom * z_scale)
		var t0 := Vector3(cos(a0) * r_top, h, sin(a0) * r_top * z_scale)
		var t1 := Vector3(cos(a1) * r_top, h, sin(a1) * r_top * z_scale)
		_tri(st, b0, b1, t1)
		_tri(st, b0, t1, t0)
		_tri(st, tc, t0, t1)
		_tri(st, bc, b1, b0)
	st.generate_normals()
	return st.commit()

## Низкополигональная сфера (эллипсоид) — для голов, камней, ламп.
static func sphere(radii: Vector3, segs: int = 6, rings: int = 4) -> ArrayMesh:
	var st := _begin()
	for j in rings:
		for i in segs:
			var p00 := _sp(radii, i, j, segs, rings)
			var p10 := _sp(radii, i + 1, j, segs, rings)
			var p01 := _sp(radii, i, j + 1, segs, rings)
			var p11 := _sp(radii, i + 1, j + 1, segs, rings)
			if j == 0:
				_tri(st, p00, p11, p01)
			elif j == rings - 1:
				_tri(st, p00, p10, p01)
			else:
				_tri(st, p00, p10, p11)
				_tri(st, p00, p11, p01)
	st.generate_normals()
	return st.commit()

static func _sp(r: Vector3, i: int, j: int, segs: int, rings: int) -> Vector3:
	var phi := PI * float(j) / float(rings)
	var th := TAU * float(i) / float(segs)
	return Vector3(sin(phi) * cos(th) * r.x, cos(phi) * r.y, sin(phi) * sin(th) * r.z)
