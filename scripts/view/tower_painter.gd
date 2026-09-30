class_name TowerPainter
extends RefCounted
## Presentation only. The exterior and cutaway use exactly the same world coordinates.
const PROPS: Texture2D = preload("res://assets/generated/ladder_brackets_v02.png")
const LADDER_REGION: Rect2 = Rect2(130, 54, 318, 1426)
const BRACKET_REGION: Rect2 = Rect2(612, 612, 316, 230)
var rattle_at: float = -10
var shutter_at: float = -10
var route_at: float = -10
var selection_at: float = -10
var selection_was_visible: bool = false

func event(view: CastleView, event_name: String) -> void:
	match event_name:
		"shutter_rattled": rattle_at = view.clock
		"shutter_opened": shutter_at = view.clock
		"mechanism_activated": route_at = view.clock
		"state_undone":
			rattle_at = -10
			shutter_at = -10
			route_at = -10

func draw(view: CastleView) -> void:
	var model: TowerState = view.state as TowerState
	var wall: TowerLayout = model.tower
	var teaching: bool = model is TutorialState
	_sky(view, model)
	_wall(view, Rect2(76, 450 if teaching else 116, 568, 830 if teaching else 1164))
	for x: int in range(80, 650, 62):
		view._box(Rect2(x, 434 if teaching else 100, 38, 32), Color("646a80"), Color("192636"), 3)
	view._ivy(Vector2(91, 190), 30)
	view._ivy(Vector2(626, 554), 32)
	view._ivy(Vector2(110, 960), 18)
	if not teaching:
		view._banner(Vector2(108, 420), Color("88556b"))
	var visible_floors: Array = [0, 1, 2, 3]
	if teaching:
		visible_floors = (wall as TutorialLayout).tutorial_step_data()["visible_floors"]
	for floor_value: int in visible_floors:
		var y: float = wall.floor_y(floor_value)
		if model.floor_has_gap(floor_value):
			_ledge(view, 92, y, 228)
			_ledge(view, 400, y, 228)
		else:
			_ledge(view, 92, y, 536)
	_mechanisms(view, model)
	for index: int in wall.window_count():
		_window(view, model, index)
	if model.ladder_anchor >= 0:
		_ladder(view, model.anchor_base(model.ladder_anchor), model.anchor_top(model.ladder_anchor), 1)
	if model.inside():
		_cutaway(view, model)
	var show_candidates: bool = model.placement_mode or model.help_visible
	if show_candidates and not selection_was_visible:
		selection_at = view.clock
	selection_was_visible = show_candidates
	if show_candidates:
		view.draw_rect(Rect2(76, 116, 568, 1164), Color(0.03, 0.05, 0.12, 0.10))
		var fade: float = 1.0 if view.reduced_motion else clampf((view.clock - selection_at) / 0.15, 0, 1)
		for index: int in model.candidate_anchors():
			_ghost(view, model, index, fade, index == model.preview_anchor)
	if model.preview_anchor >= 0:
		if model.ladder_anchor >= 0:
			_ladder(view, model.anchor_base(model.ladder_anchor), model.anchor_top(model.ladder_anchor), 0.28, Color("c3817b"))
		if model.busy():
			_ghost(view, model, model.preview_anchor, 1, true)
	_hero(view, model)
	if model.ladder_anchor < 0 and not model.inside() and model.phase == "playing":
		var carry: Vector2 = model.carried_ladder_hit_rect().get_center()
		_ladder(view, carry + Vector2(0, 30), carry - Vector2(0, 30), 1)
	if model.help_visible:
		_available(view, model)
	_feedback(view, model)
	_juice(view, model)
	if view.wiping:
		view._box(Rect2(view.pointer - Vector2(17, 4), Vector2(34, 8)), Color("fae4a8"), CastleView.INK, 2)
		view.draw_line(view.pointer + Vector2(0, 4), view.pointer + Vector2(5, 19), Color("8dd4c1"), 5)

func _sky(view: CastleView, model: TowerState) -> void:
	var dawn: float = float(model.cleaned_count()) / model.layout.window_count()
	for stripe: int in 64:
		var top: Color = Color("111e42").lerp(Color("314666"), dawn * 0.7)
		var bottom: Color = Color("283b59").lerp(Color("7b6671"), dawn)
		view.draw_rect(Rect2(0, stripe * 20, 720, 21), top.lerp(bottom, stripe / 64.0))
	view.draw_circle(Vector2(42, 198), 23, Color("eee3c4"))
	view.draw_circle(Vector2(50, 191), 22, Color("182746"))
	for index: int in 60:
		var point: Vector2 = Vector2((index * 193) % 720, 124 + (index * 79) % 1080)
		view.draw_circle(point, 1.2, Color(0.76, 0.86, 1, 0.5))
	for side: int in 2:
		for index: int in 4:
			var x: float = -30 + index * 28 if side == 0 else 641 + index * 28
			var y: float = 880 + index % 3 * 73
			view.draw_rect(Rect2(x, y, 30, 400), Color("23344c"))
			view.draw_colored_polygon(PackedVector2Array([Vector2(x - 4, y), Vector2(x + 15, y - 37), Vector2(x + 34, y)]), Color("23344c"))
			for row: int in 6:
				view.draw_rect(Rect2(x + 12, y + 25 + row * 48, 4, 9), Color("cbab75"))

func _wall(view: CastleView, area: Rect2) -> void:
	view.draw_rect(area, Color("424b64"))
	for row: int in ceili(area.size.y / 28):
		for col: int in 13:
			var x: float = area.position.x + col * 48 - (24 if row % 2 else 0)
			var y: float = area.position.y + row * 28
			var width: float = minf(45, area.end.x - x)
			if x < area.position.x or width <= 0:
				continue
			var noise: int = absi((row * 73856093) ^ (col * 19349663))
			var tint: Color = [Color("3b455d"), Color("454d65"), Color("41495f"), Color("4b5268")][noise % 4]
			view.draw_rect(Rect2(x, y, width, 25), tint)
			view.draw_line(Vector2(x + 2, y + 2), Vector2(x + width - 3, y + 2), Color(0.55, 0.57, 0.66, 0.12), 1)
			if noise % 7 == 0:
				view.draw_line(Vector2(x + 6, y + 15), Vector2(x + 12, y + 18), Color("303b51"), 2)
			if noise % 11 == 0:
				view.draw_rect(Rect2(x + 3, y + 19, 17, 3), Color(0.23, 0.35, 0.35, 0.4))
	view.draw_rect(Rect2(area.position, Vector2(9, area.size.y)), Color("667089"))
	view.draw_rect(Rect2(area.end.x - 12, area.position.y, 12, area.size.y), Color("29384f"))

func _ledge(view: CastleView, x: float, y: float, width: float) -> void:
	view._box(Rect2(x, y, width, 13), Color("887d7a"), Color("263244"), 3)
	view.draw_line(Vector2(x, y), Vector2(x + width, y), Color("c2b49a"), 3)
	for index: int in int(width / 78):
		var point: Vector2 = Vector2(x + 22 + index * 78, y + 13)
		view.draw_colored_polygon(PackedVector2Array([point, point + Vector2(18, 0), point + Vector2(0, 21)]), Color("626477"))

func _window(view: CastleView, model: TowerState, index: int) -> void:
	var area: Rect2 = model.window_rect(index)
	var clean: bool = model.is_clean(index)
	var kind: String = model.tower.window_kind(index)
	var rim: Color = Color("9c9085")
	if clean:
		rim = Color("bea47c")
		for ring: int in 5:
			view.draw_circle(area.get_center(), area.size.x * (0.65 + ring * 0.12), Color(1, 0.72, 0.32, 0.018))
	_arch(view, area.grow(9), Color("202a3e"))
	_arch(view, area.grow(6), rim)
	var arch_center: Vector2 = Vector2(area.get_center().x, area.position.y + area.size.x / 2)
	for segment: int in 9:
		var a: float = PI + segment * PI / 9
		var b: float = a + PI / 9 - 0.025
		var r: float = area.size.x / 2
		var points: PackedVector2Array = PackedVector2Array([arch_center + Vector2(cos(a), sin(a)) * (r + 2), arch_center + Vector2(cos(a), sin(a)) * (r + 11), arch_center + Vector2(cos(b), sin(b)) * (r + 11), arch_center + Vector2(cos(b), sin(b)) * (r + 2)])
		view.draw_colored_polygon(points, rim.lightened(0.04 if segment % 2 else 0.14))
	for stripe: int in ceili(area.size.y / 2):
		var row: float = stripe * 2.0
		var inset: float = _inset(area, row)
		var tint: Color = Color("634539").lerp(Color("f2c47b"), row / area.size.y)
		view.draw_rect(Rect2(area.position.x + inset, area.position.y + row, area.size.x - inset * 2, 2), tint)
	if kind == "entry" or (kind == "shutter" and model.shutter_open):
		_arch(view, area.grow(-9), Color("493849"))
		view.draw_rect(Rect2(area.position + Vector2(3, 3), Vector2(9, area.size.y - 6)), Color("cb8060"))
		view.draw_rect(Rect2(area.end.x - 12, area.position.y + 3, 9, area.size.y - 6), Color("cb8060"))
		view.draw_line(area.position + Vector2(8, 7), area.position + Vector2(8, area.size.y - 7), Color("e8b985"), 3)
		if clean:
			view.draw_polyline(PackedVector2Array([area.get_center() + Vector2(-8, 0), area.get_center() + Vector2(4, 0), area.get_center() + Vector2(0, -5), area.get_center() + Vector2(4, 0), area.get_center() + Vector2(0, 5)]), Color("f3d59a"), 2)
	else:
		view.draw_line(Vector2(area.get_center().x, area.position.y + 2), Vector2(area.get_center().x, area.end.y), Color("775b45"), 3)
		view.draw_line(Vector2(area.position.x + 2, area.position.y + area.size.x / 2), Vector2(area.end.x - 2, area.position.y + area.size.x / 2), Color("775b45"), 3)
	if kind == "discovery":
		view.draw_texture_rect(CastleView.MOON_MOTH, area.grow(-3), false)
	elif index in [1, 4, 9]:
		view.draw_set_transform(area.get_center() + Vector2(0, 18), 0, Vector2(0.5, 0.5))
		view._cat(Vector2.ZERO, Color("e9c895"))
		view.draw_set_transform(Vector2.ZERO)
	elif kind == "mechanism":
		var center: Vector2 = area.get_center()
		for tooth: int in 8:
			var angle: float = tooth * PI / 4 + (view.clock * 0.25 if clean and not view.reduced_motion else 0.0)
			view.draw_line(center, center + Vector2(cos(angle), sin(angle)) * 18, Color("d1a468"), 5)
		view.draw_circle(center, 9, Color("634d42"))
	if not clean and view.textures[index].get_width() > 0:
		var texture: ImageTexture = view.textures[index]
		for stripe: int in ceili(area.size.y / 2):
			var row: float = stripe * 2.0
			var inset: float = _inset(area, row)
			var target: Rect2 = Rect2(area.position.x + inset, area.position.y + row, area.size.x - inset * 2, minf(2, area.size.y - row))
			var source: Rect2 = Rect2(Vector2(inset / area.size.x, row / area.size.y) * texture.get_size(), target.size / area.size * texture.get_size())
			view.draw_texture_rect_region(texture, target, source)
	if kind == "shutter" and not model.shutter_open:
		var shake: float = 0.0 if view.reduced_motion else sin((view.clock - rattle_at) * 70) * maxf(0, 1 - (view.clock - rattle_at) / 0.35) * 3
		var shutter: Rect2 = Rect2(area.position + Vector2(shake, 0), area.size)
		view._box(shutter, Color("4d454b"), Color("252735"), 3)
		for plank: int in 5:
			view.draw_line(shutter.position + Vector2(plank * area.size.x / 5, 0), shutter.position + Vector2(plank * area.size.x / 5, area.size.y), Color("68605e"), 2)
		for y: float in [0.25, 0.72]:
			view.draw_rect(Rect2(shutter.position + Vector2(0, area.size.y * y), Vector2(area.size.x, 8)), Color("303745"))
			for x: float in [0.13, 0.87]:
				view.draw_circle(shutter.position + Vector2(area.size.x * x, area.size.y * y + 4), 2, Color("a5987a"))
	elif kind == "shutter":
		var open_progress: float = 1.0 if view.reduced_motion else clampf((view.clock - shutter_at) / 0.35, 0, 1)
		var flap_width: float = lerpf(area.size.x * 0.5, 13, open_progress)
		var offset: float = open_progress * 18
		for side: int in 2:
			var x: float = area.position.x - offset if side == 0 else area.end.x + offset - flap_width
			view._box(Rect2(x, area.position.y + 8, flap_width, area.size.y - 8), Color("514647"), Color("282b39"), 2)
			for row: float in [0.3, 0.7]:
				view.draw_line(Vector2(x, area.position.y + area.size.y * row), Vector2(x + flap_width, area.position.y + area.size.y * row), Color("9a8971"), 2)
	view.draw_rect(Rect2(area.position.x - 13, area.end.y + 3, area.size.x + 26, 9), Color("b2a083"))
	if clean:
		_arch(view, area, Color(1, 0.9, 0.61, maxf(0, 0.35 - (view.clock - view.reveal_times[index]))))
	elif model.can_reach_floor(index) and model.window_unlocked(index) and not model.inside():
		view.draw_line(area.position + Vector2(0, area.size.y + 14), area.end + Vector2(0, 14), Color("b0c5bc"), 2)

func _inset(area: Rect2, row: float) -> float:
	var radius: float = area.size.x / 2
	if row >= radius:
		return 0
	return radius - sqrt(maxf(0, radius * radius - (radius - row) * (radius - row)))

func _arch(view: CastleView, area: Rect2, color: Color) -> void:
	var radius: float = area.size.x / 2
	var center: Vector2 = area.position + Vector2(radius, radius)
	var points: PackedVector2Array = PackedVector2Array([Vector2(area.position.x, area.end.y)])
	for point: int in 17:
		var angle: float = PI + point * PI / 16
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	points.append(area.end)
	view.draw_colored_polygon(points, color)

func _cutaway(view: CastleView, model: TowerState) -> void:
	view.draw_rect(Rect2(76, 116, 568, 1164), Color(0.02, 0.03, 0.10, 0.34))
	var chamber: Rect2 = Rect2(265, 435, 295, 181)
	view._box(chamber, Color(0.36, 0.24, 0.20, 0.87), Color("a58a68"), 2)
	for x: int in range(290, 550, 45):
		view.draw_line(Vector2(x, 460), Vector2(x, 595), Color(0.83, 0.65, 0.42, 0.1), 2)
	var entry: Vector2 = model.window_rect(TowerLayout.ENTRY).get_center()
	var exit_point: Vector2 = model.window_rect(TowerLayout.SHUTTER).get_center()
	var path: PackedVector2Array = PackedVector2Array([entry, Vector2(entry.x, 586), Vector2(exit_point.x, 586), exit_point])
	view.draw_polyline(path, Color("f2ca89"), 4)
	view.draw_line(Vector2(285, 590), Vector2(553, 590), Color("d8b68b"), 10)
	view._lantern(Vector2(413, 495))
	# The exterior ladder remains visible through the wall, in its original position.
	if model.ladder_anchor >= 0:
		_ladder(view, model.anchor_base(model.ladder_anchor), model.anchor_top(model.ladder_anchor), 0.35)
	for index: int in [TowerLayout.ENTRY, TowerLayout.SHUTTER]:
		var area: Rect2 = model.window_rect(index)
		view.draw_rect(area, Color(0.96, 0.77, 0.48, 0.17))
		view.draw_rect(area.grow(5), Color("ebc790"), false, 3)
	if not model.shutter_open:
		var latch: Vector2 = exit_point + Vector2(0, 12)
		view.draw_line(latch - Vector2(20, 0), latch + Vector2(20, 0), Color("eac183"), 6)
		view.draw_circle(latch + Vector2(12, 7), 5, Color("ffd998"))

func _ladder(view: CastleView, base: Vector2, top: Vector2, alpha: float, color: Color = Color("e6ba76")) -> void:
	var age: float = view.clock - view.place_time
	if alpha >= 0.99 and age >= 0 and age < 0.18 and not view.reduced_motion:
		var shake: Vector2 = Vector2(sin(age * 70) * (1 - age / 0.18) * 2, 0)
		base += shake
		top += shake
	if alpha >= 0.99:
		var angle: float = (top - base).angle() + PI / 2
		var length: float = base.distance_to(top)
		view.draw_set_transform(base, angle)
		view.draw_texture_rect_region(PROPS, Rect2(-21, -length, 42, length), LADDER_REGION)
		view.draw_set_transform(Vector2.ZERO)
		return
	var direction: Vector2 = (top - base).normalized()
	var perpendicular: Vector2 = Vector2(-direction.y, direction.x)
	color.a = alpha
	for side: int in [-1, 1]:
		var offset: Vector2 = perpendicular * side * 14
		view.draw_line(base + offset, top + offset, Color(0.16, 0.18, 0.22, alpha), 9)
		view.draw_line(base + offset, top + offset, color, 5)
	for rung: int in range(1, int(base.distance_to(top) / 22)):
		var point: Vector2 = base + direction * rung * 22
		view.draw_line(point - perpendicular * 14, point + perpendicular * 14, color, 4)

func _marker(view: CastleView, point: Vector2, symbol: String, tint: Color) -> void:
	view.draw_circle(point, 25, Color(0.10, 0.16, 0.25, 0.9))
	view.draw_arc(point, 25, 0, TAU, 28, tint, 2)
	var direction: Vector2 = Vector2.RIGHT if symbol == "↔" else Vector2.UP
	var perpendicular: Vector2 = Vector2(-direction.y, direction.x)
	view.draw_line(point - direction * 14, point + direction * 14, tint, 3)
	for side: int in [-1, 1]:
		var end: Vector2 = point + direction * side * 14
		view.draw_polyline(PackedVector2Array([end - direction * side * 6 - perpendicular * 6, end, end - direction * side * 6 + perpendicular * 6]), tint, 3)

func _ghost(view: CastleView, model: TowerState, index: int, fade: float, selected: bool) -> void:
	var base: Vector2 = model.anchor_base(index)
	var top: Vector2 = model.anchor_top(index)
	var tint: Color = Color("ffe4a3") if selected else Color("e9cb8e")
	var halo: Color = tint
	halo.a = (0.17 if selected else 0.09) * fade
	view.draw_line(base, top, halo, 74)
	_ladder(view, base, top, (0.95 if selected else 0.67) * fade, tint)
	view.draw_circle(base, 6, Color(tint, 0.7 * fade))
	view.draw_circle(top, 6, Color(tint, 0.7 * fade))

func _bracket(view: CastleView, point: Vector2, horizontal: bool, tint: Color) -> void:
	view.draw_set_transform(point, PI / 2 if horizontal else 0.0)
	view.draw_texture_rect_region(PROPS, Rect2(-26, -18, 52, 36), BRACKET_REGION, Color.WHITE if tint == Color("a99c82") else Color("a2afc7"))
	view.draw_set_transform(Vector2.ZERO)

func _available(view: CastleView, model: TowerState) -> void:
	for at: int in model.reachable_regions():
		if at == 6:
			continue
		var floor_value: int = model.tower.region_floor(at)
		var right_side: bool = at in [2, 4]
		if model is TutorialState:
			for anchor: int in model.tower.anchor_count():
				var ends: Array[int] = model.tower.anchor_ends(anchor)
				if at in ends:
					var endpoint: Vector2 = model.anchor_base(anchor) if at == ends[0] else model.anchor_top(anchor)
					right_side = endpoint.x >= 400
		var left: float = 400 if right_side else 92
		var width: float = 228 if model.floor_has_gap(floor_value) else 536
		view.draw_rect(Rect2(left, model.tower.floor_y(floor_value) - 12, width, 12), Color(0.52, 0.79, 0.73, 0.32))
	for index: int in model.reachable_windows():
		if not model.is_clean(index):
			_arch_outline(view, model.window_rect(index).grow(7), Color("e4dcaf"))

func _arch_outline(view: CastleView, area: Rect2, tint: Color) -> void:
	var radius: float = area.size.x / 2
	var center: Vector2 = area.position + Vector2(radius, radius)
	view.draw_arc(center, radius, PI, TAU, 24, tint, 2)
	view.draw_polyline(PackedVector2Array([center - Vector2(radius, 0), Vector2(area.position.x, area.end.y), area.end, center + Vector2(radius, 0)]), tint, 2)

func _feedback(view: CastleView, model: TowerState) -> void:
	if model.unreachable_window >= 0 and model.unreachable_age < 1.2:
		var fade: float = 1 - model.unreachable_age / 1.2
		var tint: Color = Color(0.97, 0.76, 0.57, fade)
		_arch_outline(view, model.window_rect(model.unreachable_window).grow(9), tint)
		if model.unreachable_points.size() > 1:
			view.draw_polyline(PackedVector2Array(model.unreachable_points), Color(0.86, 0.79, 0.68, fade * 0.65), 3)
		if model.unreachable_gap.size() == 2:
			var stop: Vector2 = model.unreachable_gap[0]
			var radius: float = 18.0 if view.reduced_motion else 16 + sin(model.unreachable_age * PI / 1.2) * 12
			view.draw_arc(stop, radius, 0, TAU, 32, tint, 3)
			view.draw_line(stop - Vector2(7, 7), stop + Vector2(7, 7), tint, 3)
			view.draw_line(stop - Vector2(7, -7), stop + Vector2(7, -7), tint, 3)
	if model.nudge_age >= 0 and model.nudge_age < 1.0 and not model.paused:
		var alpha: float = sin(model.nudge_age * PI) * 0.75
		var rect: Rect2 = model.carried_ladder_hit_rect() if model.ladder_anchor < 0 else model.ladder_hit_rect()
		view.draw_rect(rect.grow(-9), Color(1, 0.82, 0.47, alpha), false, 3)
		for index: int in model.reachable_windows():
			if not model.is_clean(index):
				_arch_outline(view, model.window_rect(index).grow(7), Color(1, 0.86, 0.64, alpha))

func _hero(view: CastleView, model: TowerState) -> void:
	var moving: bool = absf(model.hero.x - model.walk_target) > 2
	if moving:
		view.facing = signf(model.walk_target - model.hero.x)
	if view.wiping:
		view.facing = signf(view.pointer.x - model.hero.x) if absf(view.pointer.x - model.hero.x) > 1 else 1.0
	var pose: String = view.characters.hero_pose(model, view.wiping, view.clock - view.place_time < 0.25)
	if model.ladder_anchor < 0 and not model.climbing and not view.wiping:
		# The carried prop beside the hero is the sole visible ladder/control surface.
		pose = "walk" if moving else "idle"
	if model.inside():
		pose = "carry_ladder" if model.ladder_anchor < 0 else ("walk" if moving else "idle")
	view.characters._draw_aligned(view, view.characters.heroes[pose], view.characters.bounds[pose], model.hero, 66, view.facing)

func _juice(view: CastleView, model: TowerState) -> void:
	for index: int in model.layout.window_count():
		var age: float = view.clock - view.reveal_times[index]
		if age >= 0 and age < 0.65:
			var area: Rect2 = model.window_rect(index)
			if not view.reduced_motion:
				view.draw_texture_rect(CastleView.SPARKLE, Rect2(area.end + Vector2(-8, -14), Vector2(20, 20)), false, Color(1, 0.9, 0.6, 1 - age / 0.65))
			view.draw_string(CastleView.FONT, area.position + Vector2(-10, -19), "CLEAN", HORIZONTAL_ALIGNMENT_CENTER, area.size.x + 20, 19, Color(1, 0.92, 0.72, 1 - age / 0.65))
	var route_age: float = view.clock - route_at
	if model.gallery_open and route_age >= 0 and route_age < 0.7:
		var y: float = model.tower.floor_y(1)
		view.draw_line(Vector2(320, y), Vector2(400, y), Color(1, 0.81, 0.35, 1 - route_age / 0.7), 8)
		if not view.reduced_motion:
			view.draw_circle(Vector2(lerpf(320, 400, route_age / 0.7), y), 7, Color("ffe5a2"))
	var shutter_age: float = view.clock - shutter_at
	if model.shutter_open and shutter_age >= 0 and shutter_age < 0.55:
		view.draw_rect(model.window_rect(TowerLayout.SHUTTER).grow(12), Color(1, 0.82, 0.46, 0.25 * (1 - shutter_age / 0.55)))

func _mechanisms(view: CastleView, model: TowerState) -> void:
	for index: int in model.tower.anchor_count():
		var key: int = model.tower.hook_keys[index]
		var horizontal: bool = model.tower.is_horizontal_anchor(index)
		var top: Vector2 = model.anchor_top(index)
		var tint: Color = Color("a99c82") if key < 0 or model.is_clean(key) else Color("677187")
		_bracket(view, model.anchor_base(index), horizontal, tint)
		_bracket(view, top, horizontal, tint)
		if key < 0 or key >= view.reveal_times.size():
			continue
		var age: float = view.clock - view.reveal_times[key]
		if age >= 0 and age < 0.7:
			var source: Vector2 = model.window_rect(key).get_center()
			var path: PackedVector2Array = PackedVector2Array([source, Vector2(top.x, source.y), top])
			view.draw_polyline(path, Color(1, 0.84, 0.51, (1 - age / 0.7) * 0.7), 3)
			view.draw_arc(top, 15, 0, TAU, 24, Color(1, 0.83, 0.49, 1 - age / 0.7), 3)
