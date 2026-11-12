extends Control
## Рюкзак: слева сетка ячеек, справа вращающийся 3D-предмет, описание и действия.
## Тёмная зернистая панель, холодные цвета, никакого красного свечения.

const MCStyle = preload("res://Scripts/MCStyle.gd")
const ItemModels = preload("res://Scripts/ItemModels.gd")

signal use_pressed(id)
signal equip_pressed(id)
signal drop_pressed(id)
signal closed

var game
var ids: Array = []
var selected: String = ""
var grid: GridContainer
var slot_btns: Dictionary = {}
var hand_label: Label
var name_label: Label
var desc_label: Label
var equip_btn: Button
var use_btn: Button
var drop_btn: Button
var preview_vp: SubViewport
var preview_pivot: Node3D
var _preview_id: String = ""

func _lbl(t: String, size_px: int, col: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", size_px)
	MCStyle.style_label(l, col)
	return l

func _btn(t: String, w: float) -> Button:
	var b := Button.new()
	b.text = t
	b.custom_minimum_size = Vector2(w, 26)
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_size_override("font_size", 12)
	MCStyle.style_button(b, false)
	return b

func setup(g) -> void:
	game = g
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.012, 0.74)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", MCStyle.grunge_panel())
	center.add_child(pc)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 6)
	pc.add_child(root)
	var top := HBoxContainer.new()
	root.add_child(top)
	var title := _lbl("РЮКЗАК", 16, Color(0.82, 0.83, 0.8))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	hand_label = _lbl("", 10, Color(0.55, 0.72, 0.6))
	top.add_child(hand_label)
	root.add_child(HSeparator.new())
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	root.add_child(body)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(316, 178)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(sc)
	grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	sc.add_child(grid)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 4)
	right.custom_minimum_size = Vector2(178, 0)
	body.add_child(right)
	var svc := SubViewportContainer.new()
	svc.stretch = true
	svc.custom_minimum_size = Vector2(178, 84)
	svc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right.add_child(svc)
	preview_vp = SubViewport.new()
	preview_vp.size = Vector2i(178, 84)
	preview_vp.transparent_bg = true
	preview_vp.own_world_3d = true
	preview_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	svc.add_child(preview_vp)
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.66, 0.78)
	env.ambient_light_energy = 0.8
	var we := WorldEnvironment.new()
	we.environment = env
	preview_vp.add_child(we)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 0.05, 1.15)
	cam.fov = 38.0
	cam.current = true
	preview_vp.add_child(cam)
	var dl := DirectionalLight3D.new()
	dl.rotation_degrees = Vector3(-35, 30, 0)
	dl.light_energy = 1.3
	dl.light_color = Color(0.95, 0.95, 1.0)
	preview_vp.add_child(dl)
	preview_pivot = Node3D.new()
	preview_pivot.rotation.x = 0.35
	preview_vp.add_child(preview_pivot)
	name_label = _lbl("", 13, Color(0.9, 0.9, 0.84))
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(name_label)
	desc_label = _lbl("", 10, Color(0.62, 0.66, 0.7))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size = Vector2(176, 44)
	right.add_child(desc_label)
	var acts := HBoxContainer.new()
	acts.add_theme_constant_override("separation", 4)
	right.add_child(acts)
	use_btn = _btn("ПРИМЕНИТЬ", 86)
	use_btn.pressed.connect(func(): use_pressed.emit(selected))
	acts.add_child(use_btn)
	equip_btn = _btn("В РУКИ", 86)
	equip_btn.pressed.connect(func(): equip_pressed.emit(selected))
	acts.add_child(equip_btn)
	var acts2 := HBoxContainer.new()
	acts2.add_theme_constant_override("separation", 4)
	right.add_child(acts2)
	drop_btn = _btn("БРОСИТЬ", 86)
	drop_btn.pressed.connect(func(): drop_pressed.emit(selected))
	acts2.add_child(drop_btn)
	var close_btn := _btn("ЗАКРЫТЬ", 86)
	close_btn.pressed.connect(close)
	acts2.add_child(close_btn)

func open(item_ids: Array) -> void:
	ids = item_ids
	if ids.is_empty():
		return
	if selected == "" or not (selected in ids):
		selected = game.held_item if (game.held_item in ids) else str(ids[0])
	_rebuild()
	_select(selected)
	visible = true
	preview_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	if slot_btns.has(selected):
		(slot_btns[selected] as Button).grab_focus()

func close() -> void:
	if not visible:
		return
	visible = false
	preview_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	closed.emit()

## Обновить список после изменения (взяли в руки, выбросили, съели).
func refresh(item_ids: Array) -> void:
	ids = item_ids
	if ids.is_empty():
		close()
		return
	if not (selected in ids):
		selected = str(ids[0])
	_rebuild()
	_select(selected)

func _rebuild() -> void:
	for c in grid.get_children():
		grid.remove_child(c)
		c.queue_free()
	slot_btns.clear()
	for id in ids:
		var cid: String = str(id)
		var b := Button.new()
		b.custom_minimum_size = Vector2(100, 32)
		b.clip_text = true
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.focus_mode = Control.FOCUS_ALL
		b.add_theme_font_size_override("font_size", 11)
		b.add_theme_color_override("font_color", Color(0.78, 0.8, 0.8))
		b.add_theme_color_override("font_hover_color", Color(1.0, 0.98, 0.8))
		b.add_theme_color_override("font_focus_color", Color(1.0, 0.98, 0.8))
		b.text = _slot_text(cid)
		b.pressed.connect(func(): _select(cid))
		b.focus_entered.connect(func(): _select(cid))
		grid.add_child(b)
		slot_btns[cid] = b
	_restyle()

func _slot_text(id: String) -> String:
	var t: String = str(game._item_title(id))
	if game.held_item == id:
		t = "• " + t
	return t

func _restyle() -> void:
	for id in slot_btns:
		var b: Button = slot_btns[id]
		var held: bool = game.held_item == id
		var sel: bool = selected == id
		var normal := MCStyle.slot_box("selected" if sel else ("held" if held else "normal"))
		b.add_theme_stylebox_override("normal", normal)
		b.add_theme_stylebox_override("pressed", MCStyle.slot_box("selected"))
		b.add_theme_stylebox_override("hover", MCStyle.slot_box("selected" if sel else "hover"))
		b.add_theme_stylebox_override("focus", MCStyle.slot_box("selected"))

func _select(id: String) -> void:
	selected = id
	_restyle()
	name_label.text = str(game._item_title(id))
	desc_label.text = str(game.ITEM_DESC.get(id, ""))
	var held: bool = game.held_item == id
	equip_btn.text = "УБРАТЬ" if held else "В РУКИ"
	hand_label.text = ("В РУКАХ: " + str(game.ITEM_NAMES.get(game.held_item, "")).to_upper()) if game.held_item != "" else "РУКИ ПУСТЫ"
	if slot_btns.has(id):
		(slot_btns[id] as Button).text = _slot_text(id)
	_set_preview(id)

func _set_preview(id: String) -> void:
	if id == _preview_id:
		return
	_preview_id = id
	for c in preview_pivot.get_children():
		c.queue_free()
	var item: Node3D = ItemModels.make(id, game.mats)
	var box := AABB()
	var first := true
	for c in item.get_children():
		if c is MeshInstance3D:
			var mi := c as MeshInstance3D
			var bb: AABB = mi.transform * mi.get_aabb()
			if first:
				box = bb
				first = false
			else:
				box = box.merge(bb)
	var ext: float = maxf(box.size.x, maxf(box.size.y, box.size.z))
	var holder := Node3D.new()
	holder.scale = Vector3.ONE * (0.46 / maxf(ext, 0.05))
	item.position = -box.get_center()
	holder.add_child(item)
	preview_pivot.add_child(holder)

func _process(delta: float) -> void:
	if visible and preview_pivot != null:
		preview_pivot.rotation.y += delta * 0.9
