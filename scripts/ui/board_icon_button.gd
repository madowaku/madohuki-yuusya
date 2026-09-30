class_name BoardIconButton
extends Button
## Draw familiar icons without depending on the font's symbol coverage.
var glyph_key: String = "undo"

func _draw() -> void:
	var center: Vector2 = size * 0.5
	var tint: Color = Color("e2d9c5")
	if disabled:
		tint.a = 0.27
	if glyph_key == "undo":
		var origin: Vector2 = center + Vector2(2, 7)
		draw_arc(origin, 19, PI, TAU + 0.5, 32, tint, 4, true)
		draw_polyline(PackedVector2Array([origin + Vector2(-10, -10), origin + Vector2(-21, 0), origin + Vector2(-10, 9)]), tint, 4, true)
	elif glyph_key == "help":
		var eye: PackedVector2Array = PackedVector2Array()
		for index: int in 33:
			var angle: float = index * TAU / 32
			eye.append(center + Vector2(cos(angle) * 23, sin(angle) * 13))
		draw_polyline(eye, tint, 3, true)
		draw_circle(center, 6, tint)
	else:
		for row: int in [-1, 0, 1]:
			draw_line(center + Vector2(-15, row * 10), center + Vector2(15, row * 10), tint, 3, true)
