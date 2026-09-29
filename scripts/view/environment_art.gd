class_name EnvironmentArt
extends RefCounted
## Kenney CC0 scaffold; region coordinates refer to the unmodified source atlas.
const ATLAS: Texture2D = preload("res://assets/third_party/kenney_medieval/medieval_tilesheet.png")
const FRAME: Texture2D = preload("res://assets/third_party/kenney_ui_adventure/panel_border_grey.png")
var frame: StyleBoxTexture = StyleBoxTexture.new()

func _init() -> void:
	frame.texture = FRAME
	frame.draw_center = false
	frame.set_texture_margin_all(12.0)

func wall(canvas: CanvasItem, area: Rect2) -> void:
	for row: int in ceili(area.size.y / 70.0):
		for col: int in ceili(area.size.x / 70.0):
			var point: Vector2 = area.position + Vector2(col * 70, row * 70)
			var size: Vector2 = Vector2(minf(70, area.end.x - point.x), minf(70, area.end.y - point.y))
			canvas.draw_texture_rect_region(ATLAS, Rect2(point, size), Rect2(Vector2(770, 420), size), Color("8295a8"))

func window_frame(canvas: CanvasItem, area: Rect2) -> void:
	frame.draw(canvas.get_canvas_item(), area.grow(12))

func balcony(canvas: CanvasItem, area: Rect2) -> void:
	canvas.draw_texture_rect_region(ATLAS, area, Rect2(770, 560, 70, 18), Color("b6b8a1"))

func bracket(canvas: CanvasItem, point: Vector2, tint: Color) -> void:
	canvas.draw_texture_rect_region(ATLAS, Rect2(point - Vector2(14, 17), Vector2(28, 28)), Rect2(1125, 583, 56, 47), tint)

func distant_window(canvas: CanvasItem, area: Rect2) -> void:
	canvas.draw_texture_rect_region(ATLAS, area, Rect2(0, 420, 70, 70), Color("6b8799"))
