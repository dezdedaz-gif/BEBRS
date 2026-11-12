extends Control
## Экранные элементы для Android: плавающий джойстик (левая половина) и кнопка действия.

signal action_pressed
signal attack_pressed
signal dodge_pressed

const STICK_R := 54.0
const KNOB_R := 22.0
const BTN_R := 40.0
const SMALL_R := 26.0

var vec: Vector2 = Vector2.ZERO
var highlight: bool = false
var active: bool = false

var _stick_id: int = -1
var _btn_id: int = -1
var _atk_id: int = -1
var _dodge_id: int = -1
var _origin: Vector2 = Vector2.ZERO
var _knob: Vector2 = Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false

func set_active(on: bool) -> void:
	if on == active:
		return
	active = on
	visible = on
	if not on:
		_stick_id = -1
		_btn_id = -1
		_atk_id = -1
		_dodge_id = -1
		vec = Vector2.ZERO
	queue_redraw()

func _btn_center() -> Vector2:
	return Vector2(size.x - 80.0, size.y - 78.0)

## Удар — левее кнопки E, рывок — над ней.
func _atk_center() -> Vector2:
	return Vector2(size.x - 160.0, size.y - 52.0)

func _dodge_center() -> Vector2:
	return Vector2(size.x - 80.0, size.y - 168.0)

func _hint_center() -> Vector2:
	return Vector2(100.0, size.y - 80.0)

func _input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			if _btn_id == -1 and event.position.distance_to(_btn_center()) <= BTN_R * 1.5:
				_btn_id = event.index
				queue_redraw()
				action_pressed.emit()
			elif _atk_id == -1 and event.position.distance_to(_atk_center()) <= SMALL_R * 1.4:
				_atk_id = event.index
				queue_redraw()
				attack_pressed.emit()
			elif _dodge_id == -1 and event.position.distance_to(_dodge_center()) <= SMALL_R * 1.4:
				_dodge_id = event.index
				queue_redraw()
				dodge_pressed.emit()
			elif _stick_id == -1 and event.position.x < size.x * 0.55:
				_stick_id = event.index
				_origin = event.position
				_knob = event.position
				vec = Vector2.ZERO
				queue_redraw()
		else:
			if event.index == _stick_id:
				_stick_id = -1
				vec = Vector2.ZERO
				queue_redraw()
			elif event.index == _btn_id:
				_btn_id = -1
				queue_redraw()
			elif event.index == _atk_id:
				_atk_id = -1
				queue_redraw()
			elif event.index == _dodge_id:
				_dodge_id = -1
				queue_redraw()
	elif event is InputEventScreenDrag and event.index == _stick_id:
		var d: Vector2 = event.position - _origin
		if d.length() > STICK_R:
			d = d.normalized() * STICK_R
		_knob = _origin + d
		vec = d / STICK_R
		if vec.length() < 0.18:
			vec = Vector2.ZERO
		queue_redraw()

func _draw() -> void:
	if not active:
		return
	var base := _origin if _stick_id != -1 else _hint_center()
	var knob := _knob if _stick_id != -1 else _hint_center()
	var a := 0.28 if _stick_id != -1 else 0.14
	draw_circle(base, STICK_R, Color(1, 1, 1, a * 0.5))
	draw_arc(base, STICK_R, 0.0, TAU, 28, Color(1, 1, 1, a + 0.1), 2.0)
	draw_circle(knob, KNOB_R, Color(0.85, 0.8, 0.7, a + 0.15))
	var c := _btn_center()
	var col := Color(0.75, 0.25, 0.25, 0.55) if (highlight or _btn_id != -1) else Color(0.5, 0.5, 0.5, 0.25)
	draw_circle(c, BTN_R, col)
	draw_arc(c, BTN_R, 0.0, TAU, 28, Color(1, 1, 1, 0.45), 2.0)
	var f := ThemeDB.fallback_font
	draw_string(f, c + Vector2(-BTN_R, 6.0), "E", HORIZONTAL_ALIGNMENT_CENTER, BTN_R * 2.0, 20, Color(1, 1, 1, 0.9))
	for b in [[_atk_center(), "УДАР", _atk_id != -1], [_dodge_center(), "РЫВОК", _dodge_id != -1]]:
		var bcol := Color(0.75, 0.55, 0.25, 0.55) if b[2] else Color(0.45, 0.45, 0.45, 0.25)
		draw_circle(b[0], SMALL_R, bcol)
		draw_arc(b[0], SMALL_R, 0.0, TAU, 24, Color(1, 1, 1, 0.4), 2.0)
		draw_string(f, b[0] + Vector2(-SMALL_R, 4.0), b[1], HORIZONTAL_ALIGNMENT_CENTER, SMALL_R * 2.0, 9, Color(1, 1, 1, 0.85))
