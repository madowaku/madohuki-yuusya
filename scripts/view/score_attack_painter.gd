class_name ScoreAttackPainter
extends RefCounted
const WALL: Texture2D = preload("res://assets/generated/castle_wall_v1.png")

const ENEMIES: Dictionary = {
	"skeleton": preload("res://assets/monsters/skeleton.png"),
	"bat": preload("res://assets/monsters/bat.png"),
	"ghost": preload("res://assets/monsters/ghost.png")
}
var enemy_bounds: Dictionary = {}

func _init() -> void:
	for kind: String in ENEMIES:
		enemy_bounds[kind] = Rect2((ENEMIES[kind] as Texture2D).get_image().get_used_rect())

func draw(view: CastleView, model: ScoreAttackState) -> void:
	var art: TowerPainter = view.tower_painter
	var camera_offset: Vector2 = Vector2(0, -model.camera_y)
	art._sky(view, model)
	view.draw_set_transform(Vector2(0, -model.camera_y))
	var top: float = model.tower.floor_y(model.tower.floor_count() - 1) - 270
	var wall_height: float = model.tower.floor_y(0) - top + 180
	var tile_height: float = 568 * WALL.get_height() / float(WALL.get_width())
	for tile: int in ceili(wall_height / tile_height):
		var height: float = minf(tile_height, wall_height - tile * tile_height)
		view.draw_texture_rect_region(WALL, Rect2(76, top + tile * tile_height, 568, height), Rect2(0, 0, WALL.get_width(), WALL.get_height() * height / tile_height))
	for floor_value: int in model.tower.floor_count():
		var y: float = model.tower.floor_y(floor_value)
		if y < model.camera_y - 100 or y > model.camera_y + 1380:
			continue
		if model.floor_has_gap(floor_value):
			_platform(view, 92, y, 228)
			_platform(view, 400, y, 228)
		else:
			_platform(view, 92, y, 536)
		view._lantern(Vector2(355, y - 140))
		view._ivy(Vector2(90 if floor_value % 2 == 0 else 628, y - 150), 12)
	view.draw_set_transform(Vector2.ZERO)
	for index: int in model.masks.size():
		var area: Rect2 = model.window_rect(index)
		if area.end.y < model.camera_y + 90 or area.position.y > model.camera_y + 1280:
			continue
		art._window(view, model, index, camera_offset)
		area.position += camera_offset
		var points: int = model.window_points(index)
		var tint: Color = Color("fff0b5") if points >= 40 else Color("cad6d1")
		view.draw_string(CastleView.FONT, Vector2(area.position.x - 12, area.end.y + 28), "%d pt" % points, HORIZONTAL_ALIGNMENT_CENTER, area.size.x + 24, 24, tint)
	for index: int in model.tower.anchor_count():
		var base: Vector2 = model.anchor_base(index)
		var end: Vector2 = model.anchor_top(index)
		if maxf(base.y, end.y) < model.camera_y + 100 or minf(base.y, end.y) > model.camera_y + 1280:
			continue
		art._ladder(view, base + camera_offset, end + camera_offset, 1)
		base += camera_offset
		end += camera_offset
		if model.tower.anchor_ends(index).has(model.region):
			var center: Vector2 = (base + end) / 2
			view.draw_circle(center, 22, Color(0.1, 0.2, 0.27, 0.9))
			var other: int = model.tower.anchor_ends(index)[1] if model.tower.anchor_ends(index)[0] == model.region else model.tower.anchor_ends(index)[0]
			var target: Vector2 = end if other == model.tower.anchor_ends(index)[1] else base
			var direction: Vector2 = (target - center).normalized()
			var side: Vector2 = Vector2(-direction.y, direction.x)
			view.draw_polyline(PackedVector2Array([center - direction * 5 - side * 9, center + direction * 7, center - direction * 5 + side * 9]), Color("ffe6a4"), 4)
	var goal_y: float = model.tower.floor_y(model.tower.floor_count() - 1) + camera_offset.y
	view.characters._draw_aligned(view, TowerPainter.KING, art.king_bounds, Vector2(490, goal_y), 110, 1.0)
	view.draw_string(CastleView.FONT, Vector2(280, goal_y - 145), "GOAL", HORIZONTAL_ALIGNMENT_CENTER, 330, 36, Color("fff0aa"))
	for enemy: Dictionary in model.patrols():
		var at: Vector2 = enemy["point"]
		if at.y > model.camera_y + 1350 or at.y < model.camera_y - 80:
			continue
		view.draw_line((enemy["from"] as Vector2) + camera_offset, (enemy["to"] as Vector2) + camera_offset, Color(0.93, 0.44, 0.47, 0.15), 3)
		_enemy(view, str(enemy["kind"]), at + camera_offset, float(enemy["direction"]))
	art._hero(view, model, camera_offset)
	view.draw_set_transform(camera_offset)
	if model.invulnerable > 0:
		view.draw_arc(model.hero + Vector2(0, -42), 42, 0, TAU, 32, Color(1, 0.45, 0.35, 0.75), 4)
		view.draw_string(CastleView.FONT, model.hero + Vector2(-90, -105), "+3 s", HORIZONTAL_ALIGNMENT_CENTER, 180, 30, Color("ffa588"))
	if model.cleaning_remaining > 0:
		view.draw_arc(model.hero + Vector2(0, -44), 53, -PI / 2, -PI / 2 + TAU * (1 - model.cleaning_remaining / 1.2), 28, Color("ffe4a3"), 4)
	art._juice(view, model)
	art._feedback(view, model)
	if model.score_age >= 0 and model.score_age < 1.2 and model.last_score_window >= 0:
		var at: Vector2 = model.window_rect(model.last_score_window).get_center() + Vector2(-60, -model.score_age * 36)
		view.draw_string(CastleView.FONT, at, "+%d" % model.window_points(model.last_score_window), HORIZONTAL_ALIGNMENT_CENTER, 120, 34, Color(1, 0.88, 0.52, 1 - model.score_age / 1.2))
	if view.wiping:
		view._box(Rect2(view.pointer - Vector2(17, 4), Vector2(34, 8)), Color("fae4a8"), CastleView.INK, 2)
	view.draw_set_transform(Vector2.ZERO)
	view.draw_rect(Rect2(0, 0, 720, 104), Color(0.06, 0.12, 0.21, 0.94))
	if model.elapsed < 7.0:
		var language: String = str(view.campaign_flow.get("language", "ja"))
		var line: String = "横フリック：歩く｜上下：ハシゴ" if language == "ja" else "Flick sideways to walk; up/down to climb"
		var second: String = "窓はなぞって拭く。寄り道で高得点！" if language == "ja" else "Swipe glass to clean. Detour for points!"
		view.draw_style_box(view.ending_painter._caption_style(1), Rect2(82, 1188, 556, 84))
		view.draw_string(CastleView.FONT, Vector2(96, 1221), line, HORIZONTAL_ALIGNMENT_CENTER, 528, 23, Color("fff0c8"))
		view.draw_string(CastleView.FONT, Vector2(96, 1255), second, HORIZONTAL_ALIGNMENT_CENTER, 528, 23, Color("fff0c8"))

func _platform(view: CastleView, x: float, y: float, width: float) -> void:
	view._box(Rect2(x, y, width, 15), Color("73594e"), Color("27303d"), 3)
	view.draw_line(Vector2(x, y), Vector2(x + width, y), Color("d1b17d"), 4)
	for plank: int in int(width / 46):
		view.draw_line(Vector2(x + plank * 46, y + 3), Vector2(x + plank * 46, y + 12), Color("473c3d"), 2)
	for index: int in int(width / 116):
		var point: Vector2 = Vector2(x + 28 + index * 116, y + 15)
		view.draw_colored_polygon(PackedVector2Array([point, point + Vector2(28, 0), point + Vector2(0, 34)]), Color("4b4245"))
		view.draw_line(point + Vector2(1, 28), point + Vector2(23, 4), Color("9b805e"), 4)
	view.draw_line(Vector2(x + 5, y - 28), Vector2(x + 5, y), Color("b49a72"), 6)
	view.draw_line(Vector2(x + width - 5, y - 28), Vector2(x + width - 5, y), Color("b49a72"), 6)

func _enemy(view: CastleView, kind: String, at: Vector2, direction: float = 1) -> void:
	if ENEMIES.has(kind):
		var height: float = 80 if kind == "skeleton" else 72
		var feet: Vector2 = at + Vector2(0, 38 if kind == "skeleton" else 36)
		if not view.reduced_motion:
			feet.y += sin(view.clock * (9 if kind == "skeleton" else 5)) * 2
		view.characters._draw_aligned(view, ENEMIES[kind], enemy_bounds[kind], feet, height, direction)
		return
	var ink: Color = Color("222a3f")
	if kind == "skeleton":
		view.draw_circle(at + Vector2(0, -19), 15, ink)
		view.draw_circle(at + Vector2(0, -21), 13, Color("ded8bb"))
		for side: int in [-1, 1]:
			view.draw_circle(at + Vector2(side * 6, -23), 4, ink)
			view.draw_line(at + Vector2(0, -3), at + Vector2(side * 16, 9), Color("ded8bb"), 5)
			view.draw_line(at + Vector2(side * 6, 15), at + Vector2(side * 12, 34), Color("ded8bb"), 5)
		view.draw_line(at - Vector2(0, 7), at + Vector2(0, 16), Color("ded8bb"), 5)
		for rib: int in 3:
			view.draw_line(at + Vector2(-9, rib * 6 - 2), at + Vector2(9, rib * 6 - 2), Color("ded8bb"), 3)
	elif kind == "bat":
		var flap: float = 7 * sin(view.clock * 14)
		for side: int in [-1, 1]:
			view.draw_colored_polygon(PackedVector2Array([at, at + Vector2(side * 37, -18 - flap), at + Vector2(side * 29, 6), at + Vector2(side * 17, 1), at + Vector2(side * 13, 14)]), Color("9b739b"))
		view.draw_circle(at, 12, ink)
		for side: int in [-1, 1]:
			view.draw_circle(at + Vector2(side * 5, -2), 3, Color("ffcc7d"))
	else:
		view.draw_circle(at - Vector2(0, 12), 22, Color(0.66, 0.79, 0.88, 0.82))
		view.draw_colored_polygon(PackedVector2Array([at + Vector2(-22, -12), at + Vector2(22, -12), at + Vector2(22, 21), at + Vector2(11, 13), at + Vector2(0, 23), at + Vector2(-11, 13), at + Vector2(-22, 21)]), Color(0.66, 0.79, 0.88, 0.82))
		for side: int in [-1, 1]:
			view.draw_circle(at + Vector2(side * 8, -12), 5, ink)
		view.draw_circle(at + Vector2(0, 2), 4, ink)
