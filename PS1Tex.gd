extends RefCounted
## Крошечные процедурные текстуры 32x32 в стиле PS1 (серые, окрашиваются через albedo материала).

static func make(kind: String, seed_value: int = 1, size: int = 32) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in size:
		for x in size:
			var shade := 1.0
			match kind:
				"brick":
					var row := floori(y / 8.0)
					var off := 8 if row % 2 == 1 else 0
					if y % 8 == 0 or (x + off) % 16 == 0:
						shade = 0.55
				"planks":
					if x % 8 == 0:
						shade = 0.55
					elif (y + floori(x / 8.0) * 7) % 16 == 0:
						shade = 0.8
					elif (y + floori(x / 8.0) * 3) % 5 == 0:
						shade = 0.9
				"tiles":
					if x % 16 == 0 or y % 16 == 0:
						shade = 0.6
				"metal":
					if y % 8 == 0:
						shade = 0.8
					elif x % 16 == 3 and y % 8 == 3:
						shade = 1.2
				_:
					pass
			var n := rng.randf_range(-0.06, 0.06)
			var v := clampf(0.78 * shade + n, 0.0, 1.0)
			img.set_pixel(x, y, Color(v, v, v, 1.0))
	return ImageTexture.create_from_image(img)
