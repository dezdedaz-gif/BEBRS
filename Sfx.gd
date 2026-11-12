extends RefCounted
## Процедурные звуки без внешних файлов. Sfx.make("shot") -> AudioStreamWAV.

const RATE := 22050

static func _wav(data: PackedFloat32Array) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(data.size() * 2)
	for i in data.size():
		bytes.encode_s16(i * 2, int(clampf(data[i], -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = bytes
	return w

static func _buf(secs: float) -> PackedFloat32Array:
	var d := PackedFloat32Array()
	d.resize(int(RATE * secs))
	return d

static func make(id: String) -> AudioStreamWAV:
	match id:
		"shot":
			return _shot()
		"click":
			return _click()
		"rip":
			return _rip()
		"slash":
			return _swish(0.28, 0.9, 0.55)
		"whoosh":
			return _swish(0.4, 0.55, 0.4)
		"hit":
			return _hit(0.22, 140.0)
		"thump":
			return _hit(0.3, 70.0)
		"heartbeat":
			return _heartbeat()
		"glass":
			return _glass()
		"drip":
			return _drip()
		"squeak":
			return _squeak()
		"stab":
			return _stab()
		"gurgle":
			return _gurgle()
		"bloodflow":
			return _bloodflow()
		"rattle":
			return _rattle()
		"power_on":
			return _power_on()
	return _click()

## Звук включения меню: щелчок тумблера, нарастающий гул трансформатора,
## треск статики, тонкий писк кинескопа и низкий тянущийся аккорд.
static func _power_on() -> AudioStreamWAV:
	var secs := 2.6
	var d := _buf(secs)
	var lp := 0.0
	var ph_hum := 0.0
	var ph_pad := 0.0
	var ph_pad2 := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for i in d.size():
		var t := float(i) / RATE
		var v := 0.0
		# щелчок тумблера
		if t < 0.025:
			v += (rng.randf() * 2.0 - 1.0) * (1.0 - t / 0.025) * 0.7
		# гул: частота растёт 38 → 100 Гц, с обертонами
		var hf := 38.0 + 62.0 * (1.0 - exp(-t * 3.0))
		ph_hum += TAU * hf / RATE
		var hum_env := (1.0 - exp(-t * 7.0)) * exp(-maxf(t - 0.9, 0.0) * 1.6)
		v += (sin(ph_hum) * 0.32 + sin(ph_hum * 2.0) * 0.16 + sin(ph_hum * 3.0) * 0.07) * hum_env
		# статика: отфильтрованный шум, затухает
		lp = lerpf(lp, rng.randf() * 2.0 - 1.0, 0.35)
		var crackle := 1.0 if rng.randf() < 0.02 else 0.0
		v += (lp * 0.18 + crackle * (rng.randf() - 0.5) * 0.5) * exp(-t * 2.4) * clampf(t * 20.0, 0.0, 1.0)
		# писк кинескопа
		v += sin(TAU * 7800.0 * t) * 0.025 * clampf((t - 0.15) * 4.0, 0.0, 1.0) * exp(-maxf(t - 0.6, 0.0) * 2.5)
		# низкий тёмный аккорд, вступает мягко
		ph_pad += TAU * 55.0 / RATE
		ph_pad2 += TAU * 82.4 / RATE
		var pad_env := clampf((t - 0.35) / 0.8, 0.0, 1.0) * exp(-maxf(t - 1.4, 0.0) * 1.5)
		v += (sin(ph_pad) * 0.22 + sin(ph_pad2) * 0.14 + sin(ph_pad * 4.0) * 0.03) * pad_env
		# мягкое затухание в конце
		v *= clampf((secs - t) / 0.3, 0.0, 1.0)
		d[i] = v * 0.8
	return _wav(d)

## Влажный укол ножа: низкий шлепок + короткий шипящий срез.
static func _stab() -> AudioStreamWAV:
	var d := _buf(0.3)
	var lp := 0.0
	for i in d.size():
		var t := float(i) / RATE
		var noise := randf_range(-1.0, 1.0)
		lp = lerpf(lp, noise, 0.18)
		var thump := sin(TAU * (120.0 - 60.0 * t) * t) * exp(-t * 26.0) * 0.9
		var wet := lp * exp(-t * 16.0) * 0.8
		var hiss := noise * exp(-t * 9.0) * clampf(t * 60.0, 0.0, 1.0) * 0.35
		d[i] = (thump + wet + hiss) * 0.9
	return _wav(d)

## Бульканье в перерезанном горле: пузыри воздуха в крови.
static func _gurgle() -> AudioStreamWAV:
	var d := _buf(2.2)
	var lp := 0.0
	var bubbles: Array = []
	for i in 14:
		bubbles.append([randf() * 1.9, randf_range(250.0, 700.0), randf_range(500.0, 1400.0)])
	for i in d.size():
		var t := float(i) / RATE
		var env := clampf(t * 6.0, 0.0, 1.0) * clampf((2.2 - t) * 1.2, 0.0, 1.0)
		lp = lerpf(lp, randf_range(-1.0, 1.0), 0.08)
		var bed := lp * 0.4
		var g := 0.0
		for b in bubbles:
			var bt: float = b[0]
			if t > bt and t < bt + 0.09:
				var bt2 := t - bt
				g += sin(TAU * (float(b[1]) + float(b[2]) * bt2 * 4.0) * bt2) * (1.0 - bt2 / 0.09) * 0.5
		d[i] = (bed + g) * env * 0.85
	return _wav(d)

## Шум вытекающей крови: густой низкий поток с пульсацией.
static func _bloodflow() -> AudioStreamWAV:
	var d := _buf(3.0)
	var lp := 0.0
	for i in d.size():
		var t := float(i) / RATE
		var env := clampf(t * 5.0, 0.0, 1.0) * clampf((3.0 - t) * 0.8, 0.0, 1.0)
		var pulse := 0.6 + 0.4 * sin(TAU * 1.1 * t) * sin(TAU * 0.35 * t)
		lp = lerpf(lp, randf_range(-1.0, 1.0), 0.06)
		var pour := lp * pulse
		var gush := lp * 0.5 * clampf(sin(TAU * 2.2 * t) * 0.5 + 0.5, 0.0, 1.0)
		d[i] = (pour + gush) * env * 0.75
	return _wav(d)

## Предсмертный хрип: рваное дыхание с клапанным присвистом.
static func _rattle() -> AudioStreamWAV:
	var d := _buf(1.6)
	var lp := 0.0
	for i in d.size():
		var t := float(i) / RATE
		var env := exp(-t * 1.1)
		var gate := 1.0 if fmod(t, 0.8) < 0.45 else 0.12
		lp = lerpf(lp, randf_range(-1.0, 1.0), 0.12)
		var whis := lp * gate
		var creak := sin(TAU * (85.0 + 20.0 * sin(t * 3.0)) * t) * gate * 0.3
		d[i] = (whis + creak) * env * 0.6
	return _wav(d)

static func _shot() -> AudioStreamWAV:
	var d := _buf(0.8)
	var lp := 0.0
	for i in d.size():
		var t := float(i) / RATE
		var noise := randf_range(-1.0, 1.0)
		lp = lerpf(lp, noise, 0.3)
		var crack := noise * exp(-t * 70.0) * 0.9
		var boom := sin(TAU * (95.0 - 55.0 * minf(t, 0.8)) * t) * exp(-t * 8.0) * 0.9
		var tail := lp * exp(-t * 5.5) * 0.5
		d[i] = (crack + boom + tail) * 0.95
	return _wav(d)

static func _click() -> AudioStreamWAV:
	var d := _buf(0.12)
	for i in d.size():
		var t := float(i) / RATE
		d[i] = (randf_range(-1.0, 1.0) * exp(-t * 90.0) + sin(TAU * 1800.0 * t) * exp(-t * 120.0) * 0.5) * 0.6
	return _wav(d)

## Отрыв куска скотча: шуршащий рывок с «дрожью».
static func _rip() -> AudioStreamWAV:
	var d := _buf(0.6)
	for i in d.size():
		var t := float(i) / RATE
		var env := clampf(t * 25.0, 0.0, 1.0) * clampf((0.6 - t) * 4.0, 0.0, 1.0)
		var gate := 1.0 if fmod(t * 90.0, 1.0) < 0.55 else 0.3
		var wob := 0.65 + 0.35 * sin(TAU * 11.0 * t)
		d[i] = randf_range(-1.0, 1.0) * gate * env * wob * 0.55
	return _wav(d)

## Взмах (нож, бросок): полосовой шум с горбом громкости.
static func _swish(secs: float, amp: float, smooth: float) -> AudioStreamWAV:
	var d := _buf(secs)
	var lp := 0.0
	for i in d.size():
		var t := float(i) / RATE
		var env := sin(PI * t / secs)
		env = env * env
		lp = lerpf(lp, randf_range(-1.0, 1.0), smooth)
		d[i] = lp * env * amp * 0.8
	return _wav(d)

static func _hit(secs: float, freq: float) -> AudioStreamWAV:
	var d := _buf(secs)
	for i in d.size():
		var t := float(i) / RATE
		d[i] = (sin(TAU * freq * t) * 0.8 + randf_range(-0.4, 0.4) * exp(-t * 40.0)) * exp(-t * 14.0)
	return _wav(d)

static func _heartbeat() -> AudioStreamWAV:
	var d := _buf(1.6)
	for i in d.size():
		var t := float(i) / RATE
		var b1 := sin(TAU * 52.0 * t) * exp(-t * 14.0)
		var t2 := t - 0.22
		var b2 := 0.0
		if t2 > 0.0:
			b2 = sin(TAU * 46.0 * t2) * exp(-t2 * 16.0) * 0.8
		d[i] = (b1 + b2) * 0.9
	return _wav(d)

static func _glass() -> AudioStreamWAV:
	var d := _buf(0.7)
	for i in d.size():
		var t := float(i) / RATE
		var ring := sin(TAU * 2900.0 * t) * 0.25 + sin(TAU * 4100.0 * t) * 0.18
		d[i] = (randf_range(-1.0, 1.0) * exp(-t * 35.0) * 0.8 + ring * exp(-t * 9.0)) * 0.7
	return _wav(d)

static func _drip() -> AudioStreamWAV:
	var d := _buf(0.22)
	for i in d.size():
		var t := float(i) / RATE
		d[i] = sin(TAU * (1500.0 - 2800.0 * t) * t) * exp(-t * 26.0) * 0.6
	return _wav(d)

static func _squeak() -> AudioStreamWAV:
	var d := _buf(0.18)
	for i in d.size():
		var t := float(i) / RATE
		d[i] = sin(TAU * (3200.0 + 900.0 * sin(t * 40.0)) * t) * sin(PI * t / 0.18) * 0.18
	return _wav(d)
