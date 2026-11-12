extends Node
## Динамика в духе Hotline Miami: камера с упреждением к курсору и лёгким наклоном, прицел мышью,
## комбо ударов, кулаки, рывок-перекат с выносливостью, стоп-кадр при попадании,
## гильзы и трассеры. Плюс укрытия для героя: клетка (можно закрыться изнутри), стол, конура.

const STAMINA_MAX := 100.0
const DODGE_COST := 28.0
const PUNCH_COST := 6.0

## Укрытия: где сидит герой, куда выходит, насколько пригибается.
const SPOTS := {
	"cage": {"in": Vector3(11.3, 0.0, 1.15), "out": Vector3(11.3, 0.0, 2.45), "crouch": 0.5, "name": "в клетке"},
	"table": {"in": Vector3(1.2, 0.0, -2.0), "out": Vector3(1.2, 0.0, -0.75), "crouch": 1.0, "name": "под столом"},
	"kennel": {"in": Vector3(9.2, 0.0, 1.5), "out": Vector3(9.2, 0.0, 2.45), "crouch": 1.0, "name": "в конуре"},
}

var g  # Game.gd
var stamina: float = STAMINA_MAX
var _stam_delay: float = 0.0
var invuln: float = 0.0
var combo: int = 0
var _combo_t: float = 0.0
var cam_kick: float = 0.0
var _kick_dir: Vector3 = Vector3.ZERO
var lead: Vector3 = Vector3.ZERO
var zoom: float = 1.0
var roll: float = 0.0
var mouse_aim: bool = false
var _mouse_idle: float = 99.0
var hiding: String = ""
var _moving_hide: bool = false
var _hitstop: bool = false
var _punch_side: int = 0
var _casings: Array = []
var _brass: StandardMaterial3D
var _tracer_mat: StandardMaterial3D
var _t: float = 0.0

func setup(game) -> void:
	g = game
	_brass = StandardMaterial3D.new()
	_brass.albedo_color = Color(0.85, 0.65, 0.25)
	_brass.metallic = 0.6
	_brass.roughness = 0.4
	_tracer_mat = StandardMaterial3D.new()
	_tracer_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_tracer_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_tracer_mat.albedo_color = Color(1.0, 0.85, 0.5, 0.85)

# ------------------------------------------------------------------ ввод

## Возвращает true, если событие обработано.
func on_input(event: InputEvent) -> bool:
	# мышь, сымитированную из касаний, не трогаем: на телефоне свои кнопки
	if event is InputEventMouseMotion:
		if event.device != InputEvent.DEVICE_ID_EMULATION:
			_mouse_idle = 0.0
		return false
	if event is InputEventMouseButton and event.pressed and event.device != InputEvent.DEVICE_ID_EMULATION:
		if event.button_index == MOUSE_BUTTON_LEFT and _can_fight():
			_mouse_idle = 0.0
			attack()
			return true
		if event.button_index == MOUSE_BUTTON_RIGHT and _can_fight():
			dodge()
			return true
	if event.is_action_pressed("dodge"):
		dodge()
		return true
	return false

func _can_fight() -> bool:
	return g.game_started and not g.input_locked() and not g.in_cutscene and hiding == "" and not _moving_hide

## Атака: оружие в руках — его приём, пустые руки — кулаки.
func attack() -> void:
	if not _can_fight():
		return
	if g.held_item == "":
		punch()
	else:
		g._use_held()

# ------------------------------------------------------------------ тик

func tick(delta: float) -> void:
	_t += delta
	invuln = maxf(0.0, invuln - delta)
	cam_kick = maxf(0.0, cam_kick - delta * 4.0)
	_combo_t = maxf(0.0, _combo_t - delta)
	if _combo_t <= 0.0:
		combo = 0
	_mouse_idle += delta
	_stam_delay = maxf(0.0, _stam_delay - delta)
	if _stam_delay <= 0.0:
		var pain: float = g.pdmg.total_pain()
		var regen := 30.0 * clampf(1.0 - pain / 140.0, 0.25, 1.0) * clampf(g.pdmg.consciousness, 0.3, 1.0)
		stamina = minf(STAMINA_MAX, stamina + regen * delta)
	_update_aim()
	_update_cam(delta)
	_update_casings(delta)

func spend(n: float) -> bool:
	if stamina < n * 0.5:
		return false
	stamina = maxf(0.0, stamina - n)
	_stam_delay = 0.7
	return true

## Прицел мышью: герой разворачивается к курсору (только на ПК, пока мышь в деле).
func _update_aim() -> void:
	mouse_aim = false
	if g.touch_enabled or not _can_fight() or g.player.dash_t > 0.0 or _mouse_idle > 2.5:
		return
	var cam: Camera3D = g.camera
	var mp: Vector2 = g.get_viewport().get_mouse_position()
	var o := cam.project_ray_origin(mp)
	var n := cam.project_ray_normal(mp)
	if n.y > -0.05:
		return
	var hit := o + n * ((0.6 - o.y) / n.y)
	var to: Vector3 = hit - g.player.global_position
	to.y = 0.0
	if to.length() < 0.25:
		return
	mouse_aim = true
	g.player.facing = atan2(to.x, to.z)
	g.player.model.rotation.y = g.player.facing

## Камера: упреждение по взгляду/курсору, отъезд с оружием, мягкий крен и толчок от выстрелов.
func _update_cam(delta: float) -> void:
	var held: String = g.held_item
	var armed := held in ["knife", "crowbar", "pistol"]
	var f: Vector3 = g._facing_vec()
	var want := f * (0.35 if held == "" else (1.7 if held == "pistol" else 1.0))
	if mouse_aim:
		var cam: Camera3D = g.camera
		var mp: Vector2 = g.get_viewport().get_mouse_position()
		var vs: Vector2 = g.get_viewport().get_visible_rect().size
		var off := (mp - vs * 0.5) / (vs * 0.5)
		off = off.limit_length(1.0)
		var reach := 2.4 if held == "pistol" else (1.4 if armed else 0.9)
		want = (cam.global_basis.x * off.x + Vector3(0, 0, 1) * off.y)
		want.y = 0.0
		want *= reach
	if not g.game_started or g.in_cutscene or g.has_override or hiding != "":
		want = Vector3.ZERO
	lead = lead.lerp(want, clampf(delta * 3.5, 0.0, 1.0))
	var want_zoom := 1.0
	if armed and not g.in_cutscene:
		want_zoom = 1.14 if held == "pistol" else 1.06
	if hiding != "":
		want_zoom = 0.8
	zoom = lerpf(zoom, want_zoom, clampf(delta * 2.5, 0.0, 1.0))
	# крен: с оружием камера «дышит» как в Hotline Miami, на ходу клонится вбок
	var want_roll := 0.0
	if not g.in_cutscene and g.game_started:
		want_roll = -g.player.velocity.x * 0.006
		if armed:
			want_roll += sin(_t * 0.6) * 0.022
	roll = lerpf(roll, want_roll, clampf(delta * 3.0, 0.0, 1.0))

func kick_offset() -> Vector3:
	return _kick_dir * cam_kick * 0.22

func kick(dir: Vector3, amount: float) -> void:
	_kick_dir = -dir.normalized()
	cam_kick = maxf(cam_kick, amount)

# ------------------------------------------------------------------ рывок

func dodge() -> void:
	if not _can_fight() or g.player.dash_t > 0.0:
		return
	if not spend(DODGE_COST):
		g._toast("Нет сил на рывок.", 1.2)
		return
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var tv: Vector2 = g.touch_vector()
	if tv.length() > dir.length():
		dir = tv
	var d3 := Vector3(dir.x, 0, dir.y)
	if d3.length() < 0.2:
		d3 = g._facing_vec()
	d3 = d3.normalized()
	g.player.dash_t = 0.3
	g.player.dash_dir = d3
	g.player.facing = atan2(d3.x, d3.z)
	g.player.model.rotation.y = g.player.facing
	invuln = 0.38
	g._sfx("whoosh", -8.0)
	var m = g.player.model
	var tw: Tween = g.create_tween()
	tw.tween_property(m, "dash", 1.0, 0.08)
	tw.tween_property(m, "dash", 0.0, 0.3).set_trans(Tween.TRANS_SINE)

# ------------------------------------------------------------------ комбо и кулаки

## Следующий удар в серии: 1 → 2 → 3 (третий — тяжёлый, с выпадом).
func next_combo() -> int:
	combo = (combo % 3) + 1
	_combo_t = 0.95
	return combo

func punch() -> void:
	if g._atk_cd > 0.0:
		return
	if not spend(PUNCH_COST):
		return
	var step := next_combo()
	var heavy := step == 3
	g._atk_cd = (0.55 if heavy else 0.3) / maxf(g.pdmg.limb_force("arm_r"), 0.35)
	var m = g.player.model
	g._sfx("whoosh" if heavy else "slash", -10.0)
	_punch_side = 1 - _punch_side
	var tw: Tween = g.create_tween()
	if _punch_side == 0 and not heavy:
		tw.tween_property(m, "punch_l", 1.0, 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_callback(func(): _punch_hit(false))
		tw.tween_property(m, "punch_l", 0.0, 0.18)
	else:
		if heavy:
			lunge(0.12)
		tw.tween_property(m, "aim", 1.0, 0.09 if heavy else 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(m, "swing", 0.8 if heavy else 0.3, 0.09)
		tw.tween_callback(func(): _punch_hit(heavy))
		tw.tween_property(m, "aim", 0.0, 0.2)
		tw.parallel().tween_property(m, "swing", 0.0, 0.2)

func _punch_hit(heavy: bool) -> void:
	var f: Vector3 = g._facing_vec()
	var origin: Vector3 = g.player.global_position
	if g.monster_on and not g.monster_dead:
		var to: Vector3 = g.monster.global_position - origin
		to.y = 0.0
		if to.length() < 1.25 and f.dot(to.normalized()) > 0.3:
			g._sfx("thump", -4.0)
			g.monster_stun = maxf(g.monster_stun, 0.9 if heavy else 0.4)
			g._damage_monster(1, "Кулак врезается в тварь." if not heavy else "Хук отбрасывает тварь назад.")
			on_hit(f, 1.4 if heavy else 0.8)
			return
	for r in g.rats:
		if r.dead:
			continue
		var rt: Vector3 = r.global_position - origin
		rt.y = 0.0
		if rt.length() < 1.0 and (rt.length() < 0.35 or f.dot(rt.normalized()) > 0.25):
			g._sfx("thump", -6.0)
			g._hit_rat(r, 2 if heavy else 1, f, 3.0 if heavy else 1.6)
			on_hit(f, 1.0 if heavy else 0.6)
			return
	g._bump_nearby(origin + f * 0.8, 0.8, 1.0 if heavy else 0.5)

## Короткий выпад вперёд (тяжёлый удар).
func lunge(secs: float) -> void:
	g.player.dash_t = secs
	g.player.dash_dir = g._facing_vec()

## Попадание: стоп-кадр, толчок камеры, тряска.
func on_hit(dir: Vector3, strength: float) -> void:
	kick(-dir, 0.6 * strength)
	g.shake = maxf(g.shake, 0.12 * strength)
	if _hitstop or not g.shake_on:
		return
	_hitstop = true
	Engine.time_scale = 0.06
	await g.get_tree().create_timer(0.05 * strength, true, false, true).timeout
	Engine.time_scale = 1.0
	_hitstop = false

# ------------------------------------------------------------------ оружие: анимации и эффекты

## Достать предмет: рука тянется к рюкзаку, предмет появляется на пике движения.
func draw_anim(show: Callable) -> void:
	var m = g.player.model
	var tw: Tween = g.create_tween()
	tw.tween_property(m, "draw", 1.0, 0.14).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(show)
	tw.tween_property(m, "draw", 0.0, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

## Подобранное убирается в рюкзак: наклон вперёд, затем рука за спину.
func stash_anim() -> void:
	var m = g.player.model
	var tw: Tween = g.create_tween()
	tw.tween_property(m, "punch_l", 0.7, 0.1)
	tw.tween_property(m, "punch_l", 0.0, 0.12)
	tw.parallel().tween_property(m, "draw", 1.0, 0.16).set_trans(Tween.TRANS_SINE)
	tw.tween_property(m, "draw", 0.0, 0.2)

## Выстрел: трассер, вылет гильзы, толчок камеры против направления.
func shot_fx(from: Vector3, to: Vector3, dir: Vector3) -> void:
	kick(dir, 1.0)
	var len := from.distance_to(to)
	if len > 0.2:
		var tr := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.025, 0.025, len)
		tr.mesh = bm
		var mat := _tracer_mat.duplicate() as StandardMaterial3D
		tr.material_override = mat
		g.add_child(tr)
		tr.global_position = (from + to) * 0.5
		tr.look_at(to, Vector3.UP)
		var tw: Tween = g.create_tween()
		tw.tween_property(mat, "albedo_color:a", 0.0, 0.09)
		tw.tween_callback(tr.queue_free)
	var c := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(0.02, 0.02, 0.045)
	c.mesh = cm
	c.material_override = _brass
	g.add_child(c)
	c.global_position = from - dir * 0.25
	var side := Vector3(dir.z, 0, -dir.x)
	_casings.append({"n": c, "v": side * randf_range(1.4, 2.0) + Vector3(0, 2.2, 0) - dir * 0.4, "life": 6.0, "spin": randf_range(10.0, 20.0)})
	if _casings.size() > 14:
		var old: Dictionary = _casings.pop_front()
		(old["n"] as Node3D).queue_free()

func _update_casings(delta: float) -> void:
	for c in _casings.duplicate():
		var n: Node3D = c["n"]
		c["life"] = float(c["life"]) - delta
		if float(c["life"]) <= 0.0:
			n.queue_free()
			_casings.erase(c)
			continue
		var v: Vector3 = c["v"]
		if n.position.y > 0.012 or v.y > 0.0:
			v.y -= 9.8 * delta
			n.position += v * delta
			n.rotate_x(float(c["spin"]) * delta)
			if n.position.y <= 0.012:
				n.position.y = 0.012
				if absf(v.y) > 0.8:
					v = Vector3(v.x * 0.4, -v.y * 0.3, v.z * 0.4)
					g._sfx("click", -24.0)
				else:
					v = Vector3.ZERO
					n.rotation = Vector3(0, randf() * TAU, PI * 0.5)
			c["v"] = v

# ------------------------------------------------------------------ укрытия

func is_safe() -> bool:
	if hiding == "":
		return false
	if hiding == "cage":
		return not g.cage_open
	return true

func enter(spot: String) -> void:
	if hiding != "" or _moving_hide or not SPOTS.has(spot):
		return
	if spot == "cage" and not g.cage_open:
		g._toast("Дверца закрыта.", 1.4)
		return
	g._unequip()
	_moving_hide = true
	var s: Dictionary = SPOTS[spot]
	var p = g.player
	var m = p.model
	p.collision_layer = 0
	p.collision_mask = 0
	var dest: Vector3 = s["in"]
	var to: Vector3 = dest - p.global_position
	p.facing = atan2(to.x, to.z)
	m.rotation.y = p.facing
	m.move_amount = 1.0
	var tw: Tween = g.create_tween()
	tw.tween_property(p, "global_position", Vector3(dest.x, p.global_position.y, dest.z), 0.55).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(m, "dash", float(s["crouch"]) * 0.8, 0.4)
	tw.tween_callback(func():
		m.move_amount = 0.0
		p.facing = 0.0
		m.rotation.y = 0.0)
	tw.tween_property(m, "sit", 1.0, 0.3).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(m, "dash", 0.0, 0.3)
	tw.parallel().tween_property(m, "position:y", -0.24, 0.3)
	await tw.finished
	hiding = spot
	_moving_hide = false
	g._sfx("thump", -14.0)
	g._toast("Ты прячешься %s. [E] — меню укрытия." % str(s["name"]) if not g.touch_enabled else "Ты прячешься %s." % str(s["name"]), 2.2)

func leave() -> void:
	if hiding == "" or _moving_hide:
		return
	if hiding == "cage" and not g.cage_open:
		g._toast("Сначала открой дверцу.", 1.4)
		return
	_moving_hide = true
	var s: Dictionary = SPOTS[hiding]
	var p = g.player
	var m = p.model
	var dest: Vector3 = s["out"]
	var tw: Tween = g.create_tween()
	tw.tween_property(m, "sit", 0.0, 0.25)
	tw.parallel().tween_property(m, "position:y", 0.0, 0.25)
	tw.tween_callback(func():
		m.move_amount = 1.0
		p.facing = atan2(dest.x - p.global_position.x, dest.z - p.global_position.z)
		m.rotation.y = p.facing)
	tw.tween_property(p, "global_position", Vector3(dest.x, p.global_position.y, dest.z), 0.5).set_trans(Tween.TRANS_SINE)
	await tw.finished
	m.move_amount = 0.0
	p.collision_layer = 1
	p.collision_mask = 1
	hiding = ""
	_moving_hide = false

## Меню изнутри укрытия.
func hide_menu() -> void:
	var opts: Array = []
	var txt := "Тесно и темно. Снаружи слышно, как капает вода."
	if hiding == "cage":
		txt = "Ты сидишь в клетке. Прутья холодные, пахнет ржавчиной." + ("\nДверца закрыта изнутри." if not g.cage_open else "")
		if g.cage_open:
			opts.append(["ЗАКРЫТЬСЯ ИЗНУТРИ", func(): g._toggle_cage(true)])
		else:
			opts.append(["ОТКРЫТЬ ДВЕРЦУ", func(): g._toggle_cage(true)])
	elif hiding == "table":
		txt = "Ты под столом. Из-под столешницы видно только ноги и пол."
	elif hiding == "kennel":
		txt = "Ты втиснулся в конуру. Солома колется."
	opts.append(["ВЫЛЕЗТИ", leave])
	opts.append(["ПОСИДЕТЬ ЕЩЁ", Callable()])
	g._dialog(txt, opts)
