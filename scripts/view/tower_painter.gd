class_name TowerPainter
extends RefCounted
## Presentation only. The exterior and cutaway use exactly the same world coordinates.
var rattle_at: float = -10
var shutter_at: float = -10
var route_at: float = -10

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
	_sky(view, model)
	_wall(view, Rect2(76, 116, 568, 1164))
	for x: int in range(80, 650, 62):
		view._box(Rect2(x, 100, 38, 32), Color("646a80"), Color("192636"), 3)
	view._ivy(Vector2(91, 190), 30)
	view._ivy(Vector2(626, 554), 32)
	view._ivy(Vector2(110, 960), 18)
	view._banner(Vector2(108, 420), Color("88556b"))
	for floor_value: int in 4:
		var y: float = wall.floor_y(floor_value)
		if model.floor_has_gap(floor_value):
			_ledge(view, 92, y, 228)
			_ledge(view, 400, y, 228)
		else:
			_ledge(view, 92, y, 536)
	_mechanisms(view, model)
	for index: int in 12:
		_window(view, model, index)
	if model.ladder_anchor >= 0:
		_ladder(view, model.anchor_base(model.ladder_anchor), model.anchor_top(model.ladder_anchor), 1)
	if model.inside():
		_cutaway(view, model)
	if model.placement_mode:
		for index: int in model.candidate_anchors():
			_ladder(view, model.anchor_base(index), model.anchor_top(index), 0.16)
			_marker(view, model.hook_hit_rect(index).get_center(), "↔" if wall.is_horizontal_anchor(index) else "↕", Color("b8dfe0"))
	if model.preview_anchor >= 0:
		if model.ladder_anchor >= 0:
			_ladder(view, model.anchor_base(model.ladder_anchor), model.anchor_top(model.ladder_anchor), 0.28, Color("c3817b"))
		_ladder(view, model.anchor_base(model.preview_anchor), model.anchor_top(model.preview_anchor), 0.5)
	if model.ladder_anchor >= 0 and model.anchor_on_floor(model.ladder_anchor) and not model.inside() and not model.placement_mode:
		_marker(view, model.hook_hit_rect(model.ladder_anchor).get_center(), "↔" if wall.is_horizontal_anchor(model.ladder_anchor) else "↕", Color("ecd2a0"))
	_hero(view, model)
	if model.phase == "playing" and not model.paused and not model.busy() and not model.inside():
		# The hero is the placement handle; this stays quiet until touched.
		var handle: Vector2 = model.hero + Vector2(0, 20)
		view.draw_arc(handle, 19, 0, TAU, 24, Color(0.91, 0.80, 0.58, 0.6), 2)
		for side: int in [-1, 1]:
			view.draw_line(handle + Vector2(side * 6, -10), handle + Vector2(side * 6, 10), Color("e5c991"), 2)
		for rung: int in 3:
			view.draw_line(handle + Vector2(-6, -7 + rung * 7), handle + Vector2(6, -7 + rung * 7), Color("e5c991"), 2)
	_juice(view, model)
	if view.wiping:
		view._box(Rect2(view.pointer - Vector2(17, 4), Vector2(34, 8)), Color("fae4a8"), CastleView.INK, 2)
		view.draw_line(view.pointer + Vector2(0, 4), view.pointer + Vector2(5, 19), Color("8dd4c1"), 5)
	if not model.is_clean(0) and model.phase == "playing":
		var center: Vector2 = model.window_rect(0).get_center()
		var offset: float = 0.0 if view.reduced_motion else sin(view.clock * 2.5) * 22
		view.draw_line(center + Vector2(-22 + offset, 0), center + Vector2(14 + offset, 0), Color(1, 0.92, 0.72, 0.75), 7)

func _sky(view: CastleView, model: TowerState) -> void:
	var dawn: float = float(model.cleaned_count()) / 12.0
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

func _hero(view: CastleView, model: TowerState) -> void:
	var moving: bool = absf(model.hero.x - model.walk_target) > 2
	if moving:
		view.facing = signf(model.walk_target - model.hero.x)
	if view.wiping:
		view.facing = signf(view.pointer.x - model.hero.x) if absf(view.pointer.x - model.hero.x) > 1 else 1.0
	var pose: String = view.characters.hero_pose(model, view.wiping, view.clock - view.place_time < 0.25)
	if model.inside():
		pose = "carry_ladder" if model.ladder_anchor < 0 else ("walk" if moving else "idle")
	view.characters._draw_aligned(view, view.characters.heroes[pose], view.characters.bounds[pose], model.hero, 66, view.facing)

func _juice(view: CastleView, model: TowerState) -> void:
	for index: int in 12:
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
		if model.tower.is_horizontal_anchor(index):
			continue
		var key: int = model.tower.hook_keys[index]
		var top: Vector2 = model.anchor_top(index) + Vector2(0, -8)
		var tint: Color = Color("a99c82") if model.is_clean(key) else Color("677187")
		view.draw_arc(top, 7, PI, TAU * 0.85, 14, tint, 3)
		var age: float = view.clock - view.reveal_times[key]
		if age >= 0 and age < 0.7:
			var source: Vector2 = model.window_rect(key).get_center()
			var path: PackedVector2Array = PackedVector2Array([source, Vector2(top.x, source.y), top])
			view.draw_polyline(path, Color(1, 0.84, 0.51, (1 - age / 0.7) * 0.7), 3)
			view.draw_arc(top, 15, 0, TAU, 24, Color(1, 0.83, 0.49, 1 - age / 0.7), 3)
