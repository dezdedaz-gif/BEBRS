extends Control
## Панель состояний (moodles) внизу экрана, как в Casualties: Unknown.
## Отрицательные состояния — в круглой рамке, положительные — в квадратной.
## Цвет рамки = тяжесть (1 жёлтый, 2 оранжевый, 3 красный, 4 тёмно-красный с пульсом).
## Наведи мышь или коснись иконки — над панелью появится название и описание.
## Иконки нарисованы пикселями прямо в коде (12x12), без внешних файлов.

const CELL := 24          # шаг между иконками
const R := 10.5           # радиус круглой рамки
const ICON := 12

## . пусто, o контур, X основной цвет, w блик, r красный, d тёмный, y жёлтый
const ICONS := {
	"drop": [
		".....oo.....",
		"....orro....",
		"....orro....",
		"...orrrro...",
		"...orrrro...",
		"..orrrrrro..",
		"..orwrrrro..",
		".orwrrrrrro.",
		".orwrrrrrro.",
		".orrrrrrrro.",
		"..orrrrrro..",
		"...oooooo...",
	],
	"drop_low": [
		".....oo.....",
		"....oddo....",
		"....oddo....",
		"...oddddo...",
		"...oddddo...",
		"..oddddddo..",
		"..oddddddo..",
		".orrrrrrrro.",
		".orwrrrrrro.",
		".orrrrrrrro.",
		"..orrrrrro..",
		"...oooooo...",
	],
	"pain": [
		"......oooo..",
		".....oyyyo..",
		"....oyyyo...",
		"...oyyyo....",
		"..oyyyyoooo.",
		".oyyyyyyyyo.",
		".ooooyyyyo..",
		"....oyyyo...",
		"...oyyyo....",
		"..oyyyo.....",
		"..oyyo......",
		"..ooo.......",
	],
	"bolt": [
		"......oooo..",
		".....owwwo..",
		"....owwwo...",
		"...owwwo....",
		"..owwwwoooo.",
		".owwwwwwwwo.",
		".oooowwwwo..",
		"....owwwo...",
		"...owwwo....",
		"..owwwo.....",
		"..owwo......",
		"..ooo.......",
	],
	"shock": [
		"....oooo....",
		"....oXXo....",
		"....oXXo....",
		"....oXXo....",
		"....oXXo....",
		"....oXXo....",
		"....oXXo....",
		"....oooo....",
		"............",
		"....oooo....",
		"....oXXo....",
		"....oooo....",
	],
	"heart": [
		"............",
		".ooo...ooo..",
		"orrro.orrro.",
		"orwrrorrrro.",
		"orwrrrrrrro.",
		"orrrrrrrrro.",
		".orrrrrrro..",
		"..orrrrro...",
		"...orrro....",
		"....oro.....",
		".....o......",
		"............",
	],
	"eye": [
		"............",
		"............",
		"...oooooo...",
		"..oXXXXXXo..",
		".oXXoooXXXo.",
		"oXXodddoXXXo",
		"oXXodwdoXXXo",
		".oXXoooXXXo.",
		"..oXXXXXXo..",
		"...oooooo...",
		"............",
		"............",
	],
	"bone": [
		"..oo........",
		".oXXo.......",
		"oXXXXo......",
		"oXXXXXo.....",
		".oXXXXXo....",
		"..ooXXXXo...",
		"...oXXXXoo..",
		"....oXXXXXo.",
		".....oXXXXXo",
		"......oXXXXo",
		".......oXXo.",
		"........oo..",
	],
	"bone_broken": [
		"..oo........",
		".oXXo.......",
		"oXXXXo......",
		"oXXXXXo.....",
		".oXXXXro....",
		"..ooXrr.....",
		"....rrXoo...",
		"....orXXXXo.",
		".....oXXXXXo",
		"......oXXXXo",
		".......oXXo.",
		"........oo..",
	],
	"germ": [
		".o..o..o....",
		"..o.o.o.....",
		"..ooooooo...",
		".oyyyyyyyo..",
		"ooyoyyyoyyoo",
		".oyyyyyyyo..",
		".oyyyoyyyo..",
		"ooyyyyyyyyoo",
		".oyoyyyyyo..",
		"..ooooooo...",
		"..o.o.o.....",
		".o..o..o....",
	],
	"storm": [
		"............",
		"....oooo....",
		"..ooXXXXoo..",
		".oXXXXXXXXo.",
		"oXXXXXXXXXXo",
		"oXXXXXXXXXXo",
		".oooooooooo.",
		"....oyo.....",
		"...oyyo.....",
		"..oyyyyoo...",
		".....oyo....",
		".....oo.....",
	],
	"face_sad": [
		"...oooooo...",
		"..oXXXXXXo..",
		".oXXXXXXXXo.",
		"oXXoXXXXoXXo",
		"oXXoXXXXoXXo",
		"oXXXXXXXXXXo",
		"oXXXooooXXXo",
		"oXXoXXXXoXXo",
		".oXXXXXXXXo.",
		"..oXXXXXXo..",
		"...oooooo...",
		"............",
	],
	"face_happy": [
		"...oooooo...",
		"..oXXXXXXo..",
		".oXXXXXXXXo.",
		"oXXoXXXXoXXo",
		"oXXoXXXXoXXo",
		"oXXXXXXXXXXo",
		"oXXoXXXXoXXo",
		"oXXXooooXXXo",
		".oXXXXXXXXo.",
		"..oXXXXXXo..",
		"...oooooo...",
		"............",
	],
	"pill": [
		"............",
		"............",
		"......oooo..",
		".....orrrro.",
		"....orrrrro.",
		"...owwwrro..",
		"..owwwwwo...",
		".owwwwwo....",
		".owwwwo.....",
		"..oooo......",
		"............",
		"............",
	],
	"cross": [
		"....oooo....",
		"....owwo....",
		"....owwo....",
		"oooooXXooooo",
		"owwwwXXwwwwo",
		"owwwwXXwwwwo",
		"oooooXXooooo",
		"....owwo....",
		"....owwo....",
		"....oooo....",
		"............",
		"............",
	],
}

const PALETTE := {
	"o": Color(0.04, 0.03, 0.03, 1.0),
	"X": Color(0.9, 0.88, 0.84, 1.0),
	"w": Color(1.0, 1.0, 1.0, 1.0),
	"r": Color(0.82, 0.08, 0.07, 1.0),
	"d": Color(0.28, 0.06, 0.06, 1.0),
	"y": Color(1.0, 0.82, 0.25, 1.0),
}

const LVL_COL := [
	Color(0.5, 0.5, 0.5),
	Color(0.95, 0.85, 0.3),
	Color(0.97, 0.55, 0.18),
	Color(0.9, 0.2, 0.14),
	Color(0.6, 0.02, 0.04),
]
const GOOD_COL := Color(0.35, 0.85, 0.55)

var items: Array = []           # текущие moodles (Dictionary из BodyDamage.moodle_list)
var font: Font = null
var _tex: Dictionary = {}
var _born: Dictionary = {}      # id -> время появления (анимация «выскакивания»)
var _t: float = 0.0
var _hover: int = -1
var _tap: int = -1
var _tap_t: float = 0.0
var _tip: PanelContainer
var _tip_name: Label
var _tip_desc: Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	for k in ICONS:
		_tex[k] = _make_icon(ICONS[k])
	_tip = PanelContainer.new()
	_tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.03, 0.04, 0.92)
	sb.border_color = Color(0.25, 0.25, 0.28)
	sb.set_border_width_all(1)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 3
	sb.content_margin_bottom = 4
	_tip.add_theme_stylebox_override("panel", sb)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 1)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tip.add_child(v)
	_tip_name = Label.new()
	_tip_name.add_theme_font_size_override("font_size", 10)
	_tip_desc = Label.new()
	_tip_desc.add_theme_font_size_override("font_size", 9)
	_tip_desc.add_theme_color_override("font_color", Color(0.82, 0.82, 0.8))
	_tip_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tip_desc.custom_minimum_size = Vector2(180, 0)
	for l in [_tip_name, _tip_desc]:
		(l as Label).add_theme_color_override("font_outline_color", Color.BLACK)
		(l as Label).add_theme_constant_override("outline_size", 3)
		(l as Label).mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(l)
	_tip.visible = false
	add_child(_tip)

func set_font(f: Font) -> void:
	font = f
	if f != null:
		_tip_name.add_theme_font_override("font", f)
		_tip_desc.add_theme_font_override("font", f)

static func _make_icon(rows: Array) -> ImageTexture:
	var img := Image.create(ICON, ICON, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in mini(rows.size(), ICON):
		var row: String = rows[y]
		for x in mini(row.length(), ICON):
			var ch := row[x]
			if PALETTE.has(ch):
				img.set_pixel(x, y, PALETTE[ch])
	return ImageTexture.create_from_image(img)

## Обновить список. Вызывается из Game каждый кадр.
func set_items(list: Array) -> void:
	var now_ids := {}
	for m in list:
		var id: String = m["id"]
		now_ids[id] = true
		if not _born.has(id):
			_born[id] = _t
	for k in _born.keys():
		if not now_ids.has(k):
			_born.erase(k)
	items = list
	var w := maxf(float(items.size()) * CELL, 1.0)
	custom_minimum_size = Vector2(w, CELL)
	size = Vector2(w, CELL)

func _process(delta: float) -> void:
	_t += delta
	if _tap >= 0:
		_tap_t -= delta
		if _tap_t <= 0.0:
			_tap = -1
	var mp := get_local_mouse_position()
	_hover = -1
	if visible and Rect2(Vector2.ZERO, size).has_point(mp):
		_hover = clampi(int(mp.x / CELL), 0, items.size() - 1)
	var show := _hover if _hover >= 0 else _tap
	if show >= 0 and show < items.size() and visible:
		var m: Dictionary = items[show]
		_tip_name.text = str(m["name"])
		_tip_name.add_theme_color_override("font_color", GOOD_COL if m["good"] else LVL_COL[clampi(int(m["lvl"]), 0, 4)].lightened(0.4))
		_tip_desc.text = str(m["desc"])
		_tip.visible = true
		_tip.reset_size()
		var tx := clampf(show * CELL + CELL * 0.5 - _tip.size.x * 0.5, -global_position.x + 4.0, get_viewport_rect().size.x - global_position.x - _tip.size.x - 4.0)
		_tip.position = Vector2(tx, -_tip.size.y - 4.0)
	else:
		_tip.visible = false
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	var p := Vector2(-1, -1)
	if event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		p = (event as InputEventScreenTouch).position
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		p = (event as InputEventMouseButton).position
	if p.x >= 0.0 and items.size() > 0:
		var i := clampi(int(p.x / CELL), 0, items.size() - 1)
		_tap = -1 if _tap == i else i
		_tap_t = 3.0

func _draw() -> void:
	for i in items.size():
		var m: Dictionary = items[i]
		var lvl: int = clampi(int(m["lvl"]), 0, 4)
		var good: bool = m["good"]
		var c := Vector2(i * CELL + CELL * 0.5, CELL * 0.5)
		# появление: выскакивает и чуть подпрыгивает
		var age: float = _t - float(_born.get(m["id"], 0.0))
		var pop := 1.0
		if age < 0.35:
			pop = 0.4 + 0.6 * sin(clampf(age / 0.35, 0.0, 1.0) * PI * 0.5) + sin(clampf(age / 0.35, 0.0, 1.0) * PI) * 0.25
		var col: Color = GOOD_COL if good else LVL_COL[lvl]
		if lvl >= 4 and not good:
			col = col.lerp(Color(1.0, 0.15, 0.1), 0.5 + 0.5 * sin(_t * 7.0))
		if lvl == 3 and not good:
			col = col.lerp(Color(1.0, 0.4, 0.3), 0.25 + 0.25 * sin(_t * 3.5))
		var hl := (i == _hover or i == _tap)
		var bg := Color(0.05, 0.045, 0.05, 0.88) if not hl else Color(0.14, 0.13, 0.14, 0.95)
		var rr := R * pop
		if good:
			var rect := Rect2(c - Vector2(rr, rr), Vector2(rr, rr) * 2.0)
			draw_rect(rect, bg, true)
			draw_rect(rect, Color.BLACK, false, 3.0)
			draw_rect(rect.grow(-1.0), col, false, 1.5)
		else:
			draw_circle(c, rr + 1.0, Color.BLACK)
			draw_circle(c, rr, col)
			draw_circle(c, rr - 1.8, bg)
		var tex: Texture2D = _tex.get(str(m["icon"]), _tex["shock"])
		var s := float(ICON) * pop
		# тяжёлые состояния слегка дрожат
		var jit := Vector2.ZERO
		if lvl >= 4 and not good:
			jit = Vector2(round(sin(_t * 31.0) * 0.6), 0)
		draw_texture_rect(tex, Rect2(c - Vector2(s, s) * 0.5 + jit, Vector2(s, s)), false)
		# метка уровня: точки под иконкой
		if not good and lvl > 1:
			for d in lvl - 1:
				var dx := (float(d) - float(lvl - 2) * 0.5) * 3.0
				draw_rect(Rect2(c + Vector2(dx - 1.0, rr - 1.0), Vector2(2, 2)), col.lightened(0.3), true)
