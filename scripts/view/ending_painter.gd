class_name EndingPainter
extends RefCounted
## A brief payoff using the same hero and ladder; no additional game rules.

const LEGEND: Texture2D = preload("res://assets/generated/legendary_ladder_v1.png")
const HEART: Texture2D = preload("res://assets/generated/heart_window_v1.png")
const KING: Texture2D = preload("res://assets/generated/demon_king_v1.png")
var legend_bounds: Rect2 = Rect2(LEGEND.get_image().get_used_rect())
var heart_bounds: Rect2 = Rect2(HEART.get_image().get_used_rect())
var king_bounds: Rect2 = Rect2(KING.get_image().get_used_rect())

func draw(view: CastleView, model: EndingState) -> void:
	var time: float = model.animation_time
	var dawn: float = smoothstep(0.0, 2.0, time)
	for stripe: int in 64:
		var top: Color = Color("1c304f").lerp(Color("91bfca"), dawn)
		var bottom: Color = Color("665b70").lerp(Color("f7c58c"), dawn)
		view.draw_rect(Rect2(0, stripe * 20, 720, 21), top.lerp(bottom, stripe / 64.0))
	var sun: Vector2 = Vector2(100, lerpf(520, 340, dawn))
	for ring: int in range(7, 0, -1):
		view.draw_circle(sun, 42 + ring * 12, Color(1, 0.85, 0.59, 0.015 * dawn))
	view.draw_circle(sun, 42, Color("ffe9b5"))
	_cloud(view, Vector2(590, 370), 1.4, Color("c5d6cf"))
	_cloud(view, Vector2(130, 550), 1.1, Color("ddd7bf"))
	view.tower_painter._wall(view, Rect2(82, 745, 556, 535))
	view.tower_painter._ledge(view, 74, 1078, 572)
	view._ivy(Vector2(101, 790), 18)
	var opening: float = 1.0 - smoothstep(3.0, 4.0, time)
	if opening > 0:
		var heart_size: Vector2 = heart_bounds.size * 255.0 / heart_bounds.size.y
		view.draw_texture_rect_region(HEART, Rect2(Vector2(360 - heart_size.x / 2, 755), heart_size), heart_bounds, Color(1, 1, 1, opening))
		view.characters._draw_aligned(view, KING, king_bounds, Vector2(374, 979), 113, 1.0)
	var growth: float = smoothstep(2.6, 6.6, time)
	var length: float = lerpf(250, 740, growth)
	var ladder_rect: Rect2 = Rect2(426, 1078 - length, 172, length)
	view.draw_texture_rect_region(LEGEND, ladder_rect, legend_bounds)
	var feet: Vector2 = Vector2(lerpf(254, 368, smoothstep(2.6, 4.2, time)), 1078)
	var pose: String = "walk" if time > 2.6 and time < 4.2 and not view.reduced_motion else "idle"
	view.characters._draw_aligned(view, view.characters.heroes[pose], view.characters.bounds[pose], feet, 112, 1.0)
	var drift: float = 0.0 if view.reduced_motion else sin(time * 0.5) * 8
	_cloud(view, Vector2(550 + drift, 445), 1.1, Color(0.98, 0.94, 0.81, growth * 0.9))
	_cloud(view, Vector2(345 - drift, 374), 0.85, Color(0.98, 0.94, 0.81, growth * 0.88))
	_cloud(view, Vector2(90, 1100), 1.8, Color(0.96, 0.86, 0.73, 0.9))
	_cloud(view, Vector2(625, 1200), 2.0, Color(0.96, 0.86, 0.73, 0.9))
	if time >= 0.7 and time < 4.0:
		var language: String = str(view.campaign_flow.get("language", "ja"))
		var line: String = "…外って、こんなに明るかったか。" if language == "ja" else "…Was the world always this bright?"
		var alpha: float = minf(1, (time - 0.7) * 3) * (1 - smoothstep(3.0, 4.0, time))
		view.draw_style_box(_caption_style(alpha), Rect2(72, 620, 576, 98))
		view.draw_string(CastleView.FONT, Vector2(88, 680), line, HORIZONTAL_ALIGNMENT_CENTER, 544, 25, Color(1, 0.94, 0.80, alpha))
	if time > 5.2:
		var alpha: float = smoothstep(5.2, 6.6, time)
		view.draw_string(CastleView.FONT, Vector2(70, 152), "NEXT JOB", HORIZONTAL_ALIGNMENT_CENTER, 580, 24, Color(0.20, 0.29, 0.35, alpha))
		view.draw_string(CastleView.FONT, Vector2(50, 208), "THE WINDOWS", HORIZONTAL_ALIGNMENT_CENTER, 620, 41, Color(0.14, 0.23, 0.29, alpha))
		view.draw_string(CastleView.FONT, Vector2(50, 263), "OF HEAVEN", HORIZONTAL_ALIGNMENT_CENTER, 620, 41, Color(0.14, 0.23, 0.29, alpha))

func _cloud(view: CastleView, center: Vector2, scale_value: float, tint: Color) -> void:
	for index: int in 5:
		var offset: Vector2 = Vector2((index - 2) * 34, -sin(index * PI / 4) * 24) * scale_value
		view.draw_circle(center + offset, (33 + index % 2 * 9) * scale_value, tint)
	view.draw_rect(Rect2(center + Vector2(-90, -8) * scale_value, Vector2(180, 28) * scale_value), tint)

func _caption_style(alpha: float) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.19, 0.27, alpha * 0.86)
	style.set_corner_radius_all(18)
	return style
