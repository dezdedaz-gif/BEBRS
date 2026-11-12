extends RefCounted
## Стиль «как в Майнкрафте»: каменная плитка, объёмные кнопки, жёлтые надписи с тенью.

static func stone_texture() -> ImageTexture:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for y in 16:
		for x in 16:
			var g := rng.randf_range(0.34, 0.56)
			if rng.randf() < 0.08:
				g -= 0.14
			img.set_pixel(x, y, Color(g, g, g, 1.0))
	return ImageTexture.create_from_image(img)

## Кнопка 24x24, растягивается по 9-patch: чёрная рамка, светлый верх/лево, тёмный низ/право.
static func button_box(base: Color) -> StyleBoxTexture:
	var s := 24
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	var light := base.lightened(0.35)
	var dark := base.darkened(0.45)
	for y in s:
		for x in s:
			var c := base
			if x < 2 or y < 2 or x >= s - 2 or y >= s - 2:
				c = Color(0, 0, 0, 1)
			elif x < 4 or y < 4:
				c = light
			elif x >= s - 4 or y >= s - 4:
				c = dark
			img.set_pixel(x, y, c)
	var sb := StyleBoxTexture.new()
	sb.texture = ImageTexture.create_from_image(img)
	sb.texture_margin_left = 4
	sb.texture_margin_right = 4
	sb.texture_margin_top = 4
	sb.texture_margin_bottom = 4
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 5
	sb.content_margin_bottom = 7
	return sb

static func style_button(b: Button, danger: bool = false) -> void:
	var base := Color(0.36, 0.37, 0.4)
	var hover := Color(0.32, 0.4, 0.48)
	if danger:
		base = Color(0.34, 0.2, 0.18)
		hover = Color(0.48, 0.27, 0.22)
	b.add_theme_stylebox_override("normal", button_box(base))
	b.add_theme_stylebox_override("hover", button_box(hover))
	b.add_theme_stylebox_override("pressed", button_box(hover.darkened(0.25)))
	b.add_theme_stylebox_override("focus", button_box(hover))
	b.add_theme_stylebox_override("disabled", button_box(Color(0.2, 0.2, 0.22)))
	b.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	b.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 0.62))
	b.add_theme_color_override("font_pressed_color", Color(1.0, 1.0, 0.62))
	b.add_theme_color_override("font_focus_color", Color(1.0, 1.0, 0.62))
	b.add_theme_color_override("font_disabled_color", Color(0.45, 0.45, 0.47))
	b.add_theme_color_override("font_outline_color", Color(0.12, 0.12, 0.12))
	b.add_theme_constant_override("outline_size", 0)
	b.add_theme_color_override("font_shadow_color", Color(0.15, 0.15, 0.15, 1.0))
	b.add_theme_constant_override("shadow_offset_x", 1)
	b.add_theme_constant_override("shadow_offset_y", 1)

static func style_label(l: Label, col: Color) -> void:
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_shadow_color", col.darkened(0.7))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 2)

## Полупрозрачная тёмная плашка с рамкой — для текста в левом углу.
static func hud_box() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.02, 0.025, 0.03, 0.74)
	s.set_border_width_all(2)
	s.border_color = Color(0.22, 0.26, 0.3, 0.95)
	s.border_width_left = 4
	s.set_corner_radius_all(2)
	s.shadow_color = Color(0, 0, 0, 0.5)
	s.shadow_size = 5
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 7
	s.content_margin_bottom = 8
	return s

## Тёмная зернистая панель с потёртыми краями. Холодный сине-серый, никакого красного свечения.
static func grunge_panel() -> StyleBoxTexture:
	var sz := 24
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	for y in sz:
		for x in sz:
			var g := rng.randf_range(0.032, 0.07)
			if rng.randf() < 0.06:
				g += 0.03
			if rng.randf() < 0.03:
				g -= 0.02
			var c := Color(g * 0.95, g * 1.05, g * 1.25, 0.96)
			if x < 2 or y < 2 or x >= sz - 2 or y >= sz - 2:
				c = Color(0.012, 0.014, 0.018, 1.0)
			elif x < 3 or y < 3:
				c = Color(0.19, 0.21, 0.24, 1.0)
			elif x >= sz - 3 or y >= sz - 3:
				c = Color(0.05, 0.055, 0.065, 1.0)
			img.set_pixel(x, y, c)
	var sb := StyleBoxTexture.new()
	sb.texture = ImageTexture.create_from_image(img)
	sb.texture_margin_left = 4
	sb.texture_margin_right = 4
	sb.texture_margin_top = 4
	sb.texture_margin_bottom = 4
	sb.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	sb.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 11
	sb.content_margin_bottom = 12
	return sb

## Рамка окна с камерой девушки.
static func portrait_frame() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.015, 0.02, 0.025, 1.0)
	s.set_border_width_all(2)
	s.border_color = Color(0.3, 0.34, 0.38, 1.0)
	s.shadow_color = Color(0, 0, 0, 0.5)
	s.shadow_size = 4
	s.content_margin_left = 3
	s.content_margin_right = 3
	s.content_margin_top = 3
	s.content_margin_bottom = 3
	return s

## Ячейка рюкзака: normal / hover / selected / held.
static func slot_box(kind: String) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.06, 0.07, 0.09, 0.95)
	s.set_border_width_all(2)
	s.border_color = Color(0.17, 0.19, 0.22)
	match kind:
		"hover":
			s.bg_color = Color(0.09, 0.11, 0.14, 0.95)
			s.border_color = Color(0.38, 0.46, 0.5)
		"selected":
			s.bg_color = Color(0.11, 0.14, 0.17, 0.98)
			s.border_color = Color(0.62, 0.72, 0.7)
		"held":
			s.bg_color = Color(0.07, 0.1, 0.09, 0.95)
			s.border_color = Color(0.4, 0.6, 0.48)
	s.content_margin_left = 6
	s.content_margin_right = 6
	s.content_margin_top = 3
	s.content_margin_bottom = 3
	return s
