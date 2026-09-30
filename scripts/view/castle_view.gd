class_name CastleView
extends Node2D

const FONT: Font = preload("res://assets/fonts/MPLUSRounded1c-Regular.ttf")
const SPARKLE: Texture2D = preload("res://assets/art/sparkle.png")
const MOON_MOTH: Texture2D = preload("res://assets/generated/raw/npc/npc_moon_moth_astronomer_happy_v01.png")
const INK: Color = Color("172735")
const CREAM: Color = Color("fff0c8")
const MINT: Color = Color("b9e9be")
var characters: CharacterArt = CharacterArt.new()
var dirt_art: DirtArt = DirtArt.new()
var environment: EnvironmentArt = EnvironmentArt.new()
var place_time: float = -10.0
var facing: float = 1.0
var state: StageState
var clock: float = 0.0
var pointer: Vector2 = Vector2.ZERO
var wiping: bool = false
var reduced_motion: bool = false
var textures: Array[ImageTexture] = []
var revisions: Array[int] = []
var reveal_times: Array[float] = []
var particles: Array[Dictionary] = []
var glint: float = 0.0
var bubble_times: Array[float] = []
var tower_painter: TowerPainter = TowerPainter.new()

func bind(model: StageState) -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if state != null and state.event_occurred.is_connected(_on_event):
		state.event_occurred.disconnect(_on_event)
	state = model
	state.event_occurred.connect(_on_event)
	_ensure_window_storage()

func invalidate() -> void:
	_ensure_window_storage()
	revisions.fill(-1)
	reveal_times.fill(-10.0)
	bubble_times.fill(-10.0)
	particles.clear()
	wiping = false
	place_time = -10.0
	facing = 1.0

func _process(delta: float) -> void:
	if state == null:
		return
	_ensure_window_storage()
	if not state.paused:
		clock += delta
		glint = maxf(0.0, glint - delta)
		for index: int in range(particles.size() - 1, -1, -1):
			particles[index]["life"] = float(particles[index]["life"]) - delta
			particles[index]["p"] = Vector2(particles[index]["p"]) + Vector2(particles[index]["v"]) * delta
			particles[index]["v"] = Vector2(particles[index]["v"]) + Vector2(0, 55) * delta
			if float(particles[index]["life"]) <= 0:
				particles.remove_at(index)
	for index: int in state.masks.size():
		if revisions[index] != state.masks[index].revision:
			_update_dirt(index)
	queue_redraw()

func _ensure_window_storage() -> void:
	while textures.size() < state.masks.size():
		textures.append(ImageTexture.new())
		revisions.append(-1)
		reveal_times.append(-10.0)
		bubble_times.append(-10.0)
	while textures.size() > state.masks.size():
		textures.pop_back()
		revisions.pop_back()
		reveal_times.pop_back()
		bubble_times.pop_back()

func _update_dirt(index: int) -> void:
	var mask: DirtMask = state.masks[index]
	textures[index].set_image(dirt_art.compose((index + state.layout.dirt_offset) % 5, mask))
	revisions[index] = mask.revision

func _on_event(event_name: String, detail: int) -> void:
	if state is TowerState:
		tower_painter.event(self, event_name)
	if event_name == "window_cleaned":
		reveal_times[detail] = clock
		glint = 0.24
		var center: Vector2 = state.window_rect(detail).get_center()
		for index: int in 24:
			var angle: float = TAU * index / 24.0
			particles.append({"p": center, "v": Vector2(cos(angle), sin(angle)) * (60 + (index % 4) * 24), "life": 0.8 + (index % 3) * 0.18, "size": 10 + (index % 3) * 5})
	elif event_name == "bubble_link":
		bubble_times[detail] = clock
	elif event_name == "ladder_placed":
		place_time = clock
		for index: int in 8:
			particles.append({"p": state.anchor_base(detail), "v": Vector2((index - 4) * 20, -35 - index * 5), "life": 0.4, "size": 10})

func _draw() -> void:
	if state == null:
		return
	if state is TowerState:
		tower_painter.draw(self)
		return
	_draw_sky()
	_draw_castle()
	for index: int in state.masks.size():
		_draw_window(index)
	if state.ladder_anchor >= 0:
		_draw_ladder(state.anchor_base(state.ladder_anchor), state.anchor_top(state.ladder_anchor), 1.0)
	_draw_anchors()
	_draw_hero(state.hero, state.ladder_anchor == -1)
	for particle: Dictionary in particles:
		var particle_size: float = float(particle["size"])
		var alpha: float = clampf(float(particle["life"]) * 2, 0, 1)
		draw_texture_rect(SPARKLE, Rect2(Vector2(particle["p"]) - Vector2.ONE * particle_size / 2, Vector2.ONE * particle_size), false, Color(1, 0.92, 0.59, alpha))
	_draw_bubble_links()
	if state.phase == "playing" and not state.paused:
		_draw_guide()
	if wiping and not state.paused:
		if state.gifts.has("reach") and pointer.y < state.hero.y - 270:
			draw_line(state.hero + Vector2(16 * facing, -55), pointer + Vector2(0, 8), INK, 8)
			draw_line(state.hero + Vector2(16 * facing, -55), pointer + Vector2(0, 8), Color("e8bd70"), 4)
		draw_arc(pointer, 32, 0, TAU, 28, Color(1, 0.96, 0.73, 0.65), 2)
		_box(Rect2(pointer + Vector2(-20, -5), Vector2(40, 10)), Color("f4d78c"), INK, 3)
		draw_line(pointer + Vector2(0, 5), pointer + Vector2(7, 22), Color("8cd4c1"), 8)
	if glint > 0 and not reduced_motion:
		draw_rect(Rect2(0, 0, 720, 1280), Color(1, 0.93, 0.69, glint * 0.12))

func _draw_sky() -> void:
	var dawn: float = float(state.cleaned_count()) / state.masks.size()
	for stripe: int in 80:
		var t: float = float(stripe) / 80.0
		var night: Color = [Color("243d51"), Color("304b54"), Color("3d3c59")][state.layout.chapter]
		var top: Color = night.lerp(Color("89b2ad"), dawn * 0.7)
		var bottom: Color = Color("ab9b88").lerp(Color("f5d99c"), dawn * 0.85)
		draw_rect(Rect2(0, stripe * 16, 720, 17), top.lerp(bottom, t))
	draw_circle(Vector2(594, 244), 53, Color("ead9ae"))
	if state.cleaned_count() < state.masks.size():
		draw_circle(Vector2(575, 231), 51, Color("3c5664").lerp(Color("7e9e9b"), dawn * 0.7))
	for index: int in 35:
		var point: Vector2 = Vector2(24 + (index * 137) % 680, 135 + (index * 83) % 390)
		var alpha: float = 0.3 + 0.2 * sin(clock * 0.8 + index)
		draw_rect(Rect2(point, Vector2(3, 3)), Color(1, 0.92, 0.75, alpha))
	_cloud(Vector2(20 + sin(clock * 0.02) * 10, 326), 1.0)
	_cloud(Vector2(532, 417), 0.8)
	for index: int in 12:
		var bx: float = index * 73.0 - 50
		var by: float = 820 - (index * 41) % 130
		draw_rect(Rect2(bx, by, 62, 300), Color("536976"))
		draw_colored_polygon(PackedVector2Array([Vector2(bx - 4, by), Vector2(bx + 31, by - 55), Vector2(bx + 66, by)]), Color("536976"))
	draw_colored_polygon(PackedVector2Array([Vector2(0, 1020), Vector2(140, 932), Vector2(286, 1040), Vector2(500, 900), Vector2(720, 966), Vector2(720, 1280), Vector2(0, 1280)]), Color("506d6e"))

func _cloud(origin: Vector2, factor: float) -> void:
	var tint: Color = Color(0.8, 0.81, 0.72, 0.12)
	for index: int in 5:
		draw_rect(Rect2(origin + Vector2(index * 28, -absf(sin(index * 1.5)) * 14) * factor, Vector2(50, 18) * factor), tint)

func _draw_castle() -> void:
	# The final wall grows by one full floor; every window and landing stays in view.
	var tall: bool = state.layout.chapter == 2
	var wall_top: float = 22.0 if tall else 294.0
	var roof_base: float = 43.0 if tall else 300.0
	var crenel_y: float = 12.0 if tall else 284.0
	_wall(Rect2(48, 511, 110, 588), 0)
	_wall(Rect2(562, 511, 110, 588), 1)
	_roof(Vector2(37, 515), 132, 112, Color("476b70"))
	_roof(Vector2(551, 515), 132, 112, Color("476b70"))
	_wall(Rect2(156, wall_top, 408, 1092.0 - wall_top), 2)
	_roof(Vector2(145, roof_base), 430, 124, Color("3a6268"))
	for index: int in 8:
		var bx: float = 160 + index * 54.0
		_box(Rect2(bx, crenel_y, 34, 26), Color("9ba399"), INK, 4)
	if tall:
		# A small observatory crown makes the extra height legible at a glance.
		draw_line(Vector2(360, 28), Vector2(360, -30), Color("d2bd87"), 4)
		draw_circle(Vector2(360, 26), 10, Color("edda9f"))
		draw_arc(Vector2(360, 26), 15, PI * 0.15, PI * 0.85, 18, Color("f1dcab"), 3)
	draw_line(Vector2(103, 403), Vector2(103, 359), CREAM, 4)
	draw_colored_polygon(PackedVector2Array([Vector2(106, 360), Vector2(148, 367), Vector2(106, 382)]), Color("db9778"))
	for side: int in 2:
		var x: float = 70 + side * 534.0
		environment.distant_window(self, Rect2(x - 7, 580, 38, 62))
		environment.distant_window(self, Rect2(x - 7, 838, 38, 58))
		_banner(Vector2(73 + side * 536, 697), Color("c88770"))
	# Each projecting ledge aligns with the ladder's floor index.
	_platform(72, 1070, 576, true)
	if state.floor_has_gap(1):
		_platform(92, 805, WallLayout.GAP_LEFT - 92, true)
		_platform(WallLayout.GAP_RIGHT, 805, 628 - WallLayout.GAP_RIGHT, true)
		draw_rect(Rect2(WallLayout.GAP_LEFT, 803, WallLayout.GAP_RIGHT - WallLayout.GAP_LEFT, 26), Color("263a45"))
	else:
		_platform(92, 805, 536, true)
		if state.layout.chapter == 2 and state.is_clean(4):
			draw_line(Vector2(320, 806), Vector2(400, 806), Color("e6d18a"), 5)
			for tile: int in 4:
				draw_circle(Vector2(329 + tile * 21, 810), 3, Color("90aa80"))
	if state.floor_has_gap(2):
		# Keep upper-hook hit targets apart from the middle hooks vertically above them.
		_platform(92, 540, WallLayout.GAP_LEFT - 92, state.anchor_unlocked(2))
		_platform(WallLayout.GAP_RIGHT, 540, 628 - WallLayout.GAP_RIGHT, true)
		draw_rect(Rect2(WallLayout.GAP_LEFT, 538, WallLayout.GAP_RIGHT - WallLayout.GAP_LEFT, 26), Color("263a45"))
	else:
		_platform(204, 540, 312, state.anchor_unlocked(2) or state.anchor_unlocked(3))
	if tall:
		_platform(92, 275, 536, true)
		for x: int in [169, 333, 553]:
			draw_colored_polygon(PackedVector2Array([Vector2(x, 292), Vector2(x + 22, 292), Vector2(x, 317)]), Color("596c6c"))
	for y: int in [822, 1086]:
		for x: int in [169, 333, 553]:
			draw_colored_polygon(PackedVector2Array([Vector2(x, y), Vector2(x + 22, y), Vector2(x, y + 25)]), Color("596c6c"))
	# The mechanism's actual window position connects to both lower hooks.
	var pipe: Color = Color("d8b873") if state.is_clean(0) else Color("69766e")
	var mechanism: Rect2 = state.window_rect(0)
	var joint: Vector2 = Vector2(mechanism.get_center().x, 846)
	draw_line(Vector2(mechanism.get_center().x, mechanism.end.y + 10), joint, pipe, 4)
	for hook: int in [0, 1]:
		if state.layout.hook_keys[hook] != 0:
			continue
		var endpoint: Vector2 = state.anchor_top(hook) + Vector2(0, 12)
		draw_polyline(PackedVector2Array([joint, Vector2(endpoint.x, joint.y), endpoint]), pipe, 4)
	_ivy(Vector2(165, 343), 16)
	_ivy(Vector2(550, 864), 11)
	_ivy(Vector2(58, 911), 8)
	draw_rect(Rect2(0, 1100, 720, 180), Color("233c42"))
	draw_rect(Rect2(0, 1100, 720, 9), Color("53766b"))
	for index: int in 34:
		var x: float = float((index * 67) % 720)
		var y: float = float(1117 + (index * 23) % 125)
		draw_line(Vector2(x, y), Vector2(x + 25, y), Color("2c484c"), 3)
	for side: int in 2:
		var x: float = 26 + side * 660.0
		for leaf: int in 9:
			draw_line(Vector2(x, 1100), Vector2(x + (leaf - 4) * 6, 1080 - (leaf % 3) * 8), Color("88a781"), 4)
		for petal: int in 3:
			draw_rect(Rect2(x + petal * 7 - 8, 1072 - (petal % 2) * 8, 6, 6), Color("edc78c"))
	if state.is_clean(0):
		_lantern(Vector2(147, 980))
		_lantern(Vector2(577, 980))

func _wall(area: Rect2, _seed_value: int) -> void:
	_box(area, Color("627c86"), INK, 6)
	environment.wall(self, area)
	draw_rect(Rect2(area.position, Vector2(8, area.size.y)), Color("91a5a5"))
	draw_rect(Rect2(area.end.x - 10, area.position.y, 10, area.size.y), Color("354f60"))

func _roof(origin: Vector2, width: float, height: float, tint: Color) -> void:
	var points: PackedVector2Array = PackedVector2Array([origin, origin + Vector2(width / 2, -height), origin + Vector2(width, 0)])
	draw_colored_polygon(points, tint)
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[0]]), INK, 5)
	for row: int in range(1, int(height / 17)):
		var py: float = row * 17.0
		var half_width: float = width / 2 * py / height
		draw_line(origin + Vector2(width / 2 - half_width, -height + py), origin + Vector2(width / 2 + half_width, -height + py), Color("69908a"), 3)

func _platform(x: float, y: float, width: float, enabled: bool) -> void:
	if not enabled:
		for index: int in int(width / 18):
			draw_line(Vector2(x + index * 18, y), Vector2(x + index * 18 + 8, y), Color(0.76, 0.82, 0.7, 0.3), 3)
		return
	_box(Rect2(x, y, width, 16), Color("b7b298"), INK, 4)
	environment.balcony(self, Rect2(x, y, width, 16))
	draw_line(Vector2(x + 2, y + 1), Vector2(x + width - 2, y + 1), CREAM, 3)

func _banner(origin: Vector2, tint: Color) -> void:
	draw_line(origin + Vector2(-5, -6), origin + Vector2(41, -6), Color("d0ba8b"), 6)
	draw_colored_polygon(PackedVector2Array([origin, origin + Vector2(36, 0), origin + Vector2(36, 90), origin + Vector2(18, 79), origin + Vector2(0, 90)]), tint)
	draw_line(origin + Vector2(7, 4), origin + Vector2(7, 75), Color("eab38c"), 3)
	draw_colored_polygon(PackedVector2Array([origin + Vector2(18, 25), origin + Vector2(27, 40), origin + Vector2(18, 54), origin + Vector2(9, 40)]), Color("edcb96"))

func _ivy(origin: Vector2, count: int) -> void:
	for index: int in count:
		var center: Vector2 = origin + Vector2(sin(index * 0.7) * 15, index * 12)
		draw_rect(Rect2(center, Vector2(4, 15)), Color("426955"))
		draw_colored_polygon(PackedVector2Array([center, center + Vector2(-12, 0), center + Vector2(-16, 10), center + Vector2(-4, 13)]), Color("72916b"))
		draw_colored_polygon(PackedVector2Array([center + Vector2(2, 6), center + Vector2(14, 2), center + Vector2(17, 10), center + Vector2(5, 16)]), Color("567c63"))

func _lantern(point: Vector2) -> void:
	draw_circle(point, 27, Color(1, 0.77, 0.34, 0.07))
	draw_circle(point, 18, Color(1, 0.77, 0.34, 0.10))
	_box(Rect2(point - Vector2(7, 12), Vector2(14, 24)), Color("f7d58b"), INK, 3)

func _draw_window(index: int) -> void:
	var area: Rect2 = state.window_rect(index)
	var clean: bool = state.is_clean(index)
	var age: float = clock - reveal_times[index]
	var is_reachable: bool = state.accessible(index)
	var rim: Color = Color("d2c7a5") if clean else Color("abb3a1")
	if is_reachable and not clean:
		rim = Color("c3e5bb")
		if not reduced_motion:
			draw_rect(area.grow(15), Color(0.76, 0.92, 0.71, 0.05 + sin(clock * 3) * 0.025))
	_box(area.grow(12), rim, INK, 5)
	_box(area.grow(5), Color("b2a98d"), Color("516666"), 3)
	environment.window_frame(self, area)
	_draw_room(index, area)
	if textures[index].get_width() > 0 and not clean:
		draw_texture_rect(textures[index], area, false)
	if clean:
		draw_colored_polygon(PackedVector2Array([area.position + Vector2(12, 0), area.position + Vector2(41, 0), area.position + Vector2(0, 65), area.position + Vector2(0, 37)]), Color(1, 0.97, 0.82, 0.16))
		draw_line(area.position + Vector2(98, 6), area.position + Vector2(78, 43), Color(1, 0.95, 0.77, 0.17), 5)
		draw_texture_rect(SPARKLE, Rect2(area.end - Vector2(14, 14), Vector2(28, 28)), false, Color("fff1ac"))
		draw_rect(Rect2(area.position, area.size), Color(1, 0.95, 0.76, clampf(0.35 - age, 0, 0.35)))
	else:
		# A faint cross and visible grime communicate glass without revealing the reward.
		draw_line(Vector2(area.get_center().x, area.position.y), Vector2(area.get_center().x, area.end.y), Color(0.15, 0.22, 0.21, 0.15), 4)
		var fraction: float = 1.0 - state.masks[index].fraction()
		if fraction > 0.0:
			draw_rect(Rect2(area.position.x, area.end.y + 17, area.size.x, 5), Color("334951"))
			draw_rect(Rect2(area.position.x, area.end.y + 17, area.size.x * fraction, 5), MINT)
	_box(Rect2(area.position.x - 18, area.end.y + 2, area.size.x + 36, 10), Color("c7bd9e"), INK, 3)
	if age < 1.25 and not reduced_motion:
		var rise: float = minf(age, 0.65) * 22
		draw_string(FONT, area.position + Vector2(-35, -24 - rise), "SHINE!", HORIZONTAL_ALIGNMENT_CENTER, area.size.x + 70, 25, Color(1, 0.94, 0.67, minf(1, (1.25 - age) * 3)))
	if not state.window_unlocked(index):
		_box(area, Color("465367"), INK, 3)
		for slat: int in 7:
			draw_line(area.position + Vector2(0, slat * 24), area.position + Vector2(area.size.x, slat * 24), Color("637080"), 3)
		_box(Rect2(area.get_center() - Vector2(53, 20), Vector2(106, 40)), Color("263d4b"), Color("d7b783"), 2)
		var source: String = str(StageData.WINDOWS[state.layout.required_window[index]]["id"])
		draw_string(FONT, area.get_center() + Vector2(-53, 10), source + " → " + str(StageData.WINDOWS[index]["id"]), HORIZONTAL_ALIGNMENT_CENTER, 106, 26, CREAM)
	_box(Rect2(area.position + Vector2(-7, -24), Vector2(32, 30)), INK, Color("e0cba2"), 2)
	draw_string(FONT, area.position + Vector2(-7, 0), str(StageData.WINDOWS[index]["id"]), HORIZONTAL_ALIGNMENT_CENTER, 32, 24, CREAM)
	if not clean and state.window_unlocked(index) and state.can_reach_floor(index) and state.window_floor(index) > state.floor_index:
		draw_rect(Rect2(area.position + Vector2(0, -40), Vector2(area.size.x, 24)), Color("354f60"))
		draw_string(FONT, area.position + Vector2(0, -21), "↑ 1", HORIZONTAL_ALIGNMENT_CENTER, area.size.x, 23, Color("f4d78c"))
	if not clean and state.window_unlocked(index) and not state.can_reach_floor(index):
		draw_circle(area.get_center(), 14, Color(0.18, 0.26, 0.26, 0.28))
		draw_string(FONT, area.get_center() + Vector2(-10, 7), "?", HORIZONTAL_ALIGNMENT_CENTER, 20, 20, Color("c1bea3"))

func _draw_room(index: int, area: Rect2) -> void:
	var top_colors: Array[Color] = [Color("785841"), Color("586b62"), Color("765653"), Color("626b64"), Color("587379"), Color("635a78")]
	for row: int in 16:
		draw_rect(Rect2(area.position + Vector2(0, row * 10), Vector2(area.size.x, 10)), top_colors[index].lerp(Color("d7af79"), float(row) / 24.0))
	draw_rect(Rect2(area.position.x, area.end.y - 23, area.size.x, 23), Color("594c40"))
	draw_line(area.position + Vector2(0, 30), area.position + Vector2(132, 30), Color(1, 0.91, 0.7, 0.13), 2)
	var center: Vector2 = area.get_center()
	match index:
		0:
			for gear: int in 2:
				var p: Vector2 = center + Vector2(-20 + gear * 43, -9 + gear * 22)
				var rotation_value: float = clock * 0.5 * (1 if gear == 0 else -1) if state.is_clean(0) else 0.0
				for tooth: int in 8:
					var angle: float = tooth * PI / 4 + rotation_value
					draw_line(p, p + Vector2(cos(angle), sin(angle)) * 28, Color("eac787"), 10)
				draw_circle(p, 18, Color("eac787"))
				draw_circle(p, 9, Color("886b4b"))
				draw_circle(p, 3, Color("ffecaf"))
			draw_line(center + Vector2(-33, 35), center + Vector2(-33, 53), Color("cc9d64"), 5)
		1:
			# A tiny greenhouse, including a very content sleepy cat.
			for plant: int in 3:
				var p: Vector2 = area.position + Vector2(23 + plant * 42, 123)
				draw_rect(Rect2(p - Vector2(10, 0), Vector2(20, 14)), Color("d38c67"))
				draw_line(p, p + Vector2(0, -32), Color("c4d895"), 4)
				draw_circle(p + Vector2(-7, -21), 8, Color("91ad76"))
				draw_circle(p + Vector2(7, -32), 9, Color("b8c687"))
			_cat(center + Vector2(0, 38), Color("efcd92"))
		2:
			for shelf: int in 2:
				var y: float = area.position.y + 46 + shelf * 55
				for book: int in 7:
					var tint: Color = [Color("b2bf9b"), Color("d7ac7e"), Color("ba8070")][book % 3]
					draw_rect(Rect2(area.position.x + 12 + book * 16, y - 23 - book % 3 * 5, 11, 24 + book % 3 * 5), tint)
					draw_rect(Rect2(area.position.x + 14 + book * 16, y - 10, 7, 2), CREAM)
					draw_rect(Rect2(area.position.x + 8, y, 116, 7), Color("5b493e"))
		3:
			# The merchant reacts during reveal, then waves thanks after CLEAN.
			draw_rect(Rect2(center + Vector2(-35, -60), Vector2(70, 5)), Color("b8aa84"))
			var emotion: String = "neutral"
			if state.is_clean(3):
				emotion = "surprised" if clock - reveal_times[3] < 0.65 else "happy"
			elif state.masks[3].fraction() < 0.7:
				emotion = "surprised"
			characters.draw_resident(self, emotion, Vector2(center.x, area.end.y - 11))
			draw_rect(Rect2(area.position.x + 8, area.end.y - 29, 116, 9), Color("c79763"))
			if state.is_clean(3):
				draw_string(FONT, area.position + Vector2(0, 33), "♥", HORIZONTAL_ALIGNMENT_CENTER, 132, 26, Color("f7c798"))
		4:
			draw_circle(center + Vector2(0, -16), 37, Color("dec287"))
			draw_line(center + Vector2(-47, 45), center + Vector2(47, 45), Color("e1c292"), 7)
			_cat(center + Vector2(0, 36), Color("d3d8ca"))
			for star: int in 3:
				draw_texture_rect(SPARKLE, Rect2(area.position + Vector2(14 + star * 43, 12 + star % 2 * 16), Vector2(16, 16)), false, CREAM)
		5:
			# The astronomer only becomes readable as the last veil of grime clears.
			draw_circle(center + Vector2(0, 26), 42, Color(0.95, 0.82, 0.60, 0.18))
			draw_texture_rect(MOON_MOTH, Rect2(area.position + Vector2(2, 3), area.size - Vector2(4, 5)), false)
			for star: int in 3:
				var sparkle_position: Vector2 = area.position + Vector2(13 + star * 48, 13 + (star % 2) * 15)
				draw_texture_rect(SPARKLE, Rect2(sparkle_position, Vector2(13, 13)), false, Color("f5e9bc"))

func _cat(point: Vector2, tint: Color) -> void:
	_box(Rect2(point + Vector2(-20, -17), Vector2(40, 25)), tint, Color("614f42"), 3)
	draw_colored_polygon(PackedVector2Array([point + Vector2(-19, -15), point + Vector2(-20, -33), point + Vector2(-4, -19)]), tint)
	draw_colored_polygon(PackedVector2Array([point + Vector2(5, -19), point + Vector2(19, -33), point + Vector2(20, -15)]), tint)
	draw_line(point + Vector2(-12, -5), point + Vector2(-5, -3), Color("5e564a"), 3)
	draw_line(point + Vector2(5, -3), point + Vector2(12, -5), Color("5e564a"), 3)
	draw_rect(Rect2(point + Vector2(-2, 2), Vector2(4, 3)), Color("a87862"))


func _draw_anchors() -> void:
	if state.phase == "title":
		return
	for index: int in state.layout.anchor_count():
		if not state.anchor_enabled(index):
			continue
		var unlocked: bool = state.anchor_unlocked(index)
		var base: Vector2 = state.anchor_base(index)
		var top: Vector2 = state.anchor_top(index)
		var available: bool = unlocked and state.anchor_on_floor(index) and state.ladder_anchor == -1
		var tint: Color = MINT if available else Color("a3aa8f")
		if available:
			_draw_ladder(base, top, 0.15 + (0.0 if reduced_motion else sin(clock * 3) * 0.04))
		var point: Vector2 = state.anchor_marker(index)
		if state.anchor_on_floor(index):
			draw_circle(point + Vector2(0, -16), 24, Color(0.1, 0.23, 0.25, 0.93))
			draw_arc(point + Vector2(0, -16), 24, 0, TAU, 24, tint, 3)
			if state.layout.is_horizontal_anchor(index) or not unlocked:
				var symbol: String = "↔" if unlocked else str(StageData.WINDOWS[state.layout.hook_keys[index]]["id"])
				draw_string(FONT, point + Vector2(-24, -7), symbol, HORIZONTAL_ALIGNMENT_CENTER, 48, 27, tint)
			else:
				draw_line(point + Vector2(-7, -28), point + Vector2(-7, -4), tint, 3)
				draw_line(point + Vector2(7, -28), point + Vector2(7, -4), tint, 3)
				for rung: int in 3:
					draw_line(point + Vector2(-7, -24 + rung * 8), point + Vector2(7, -24 + rung * 8), tint, 3)
		if not unlocked:
			draw_string(FONT, top + Vector2(-16, -28), str(StageData.WINDOWS[state.layout.hook_keys[index]]["id"]), HORIZONTAL_ALIGNMENT_CENTER, 32, 23, Color("c1c4b4"))
		environment.bracket(self, top + Vector2(0, -7), tint)
		# A hooked top is visible even before a ladder is placed.
		draw_arc(top + Vector2(0, -15), 10, PI, TAU * 0.85, 12, tint, 5)

func _draw_ladder(base: Vector2, top: Vector2, alpha: float) -> void:
	var tint: Color = Color("d4b783")
	tint.a = alpha
	var edge: Color = Color(0.19, 0.25, 0.25, alpha)
	var direction: Vector2 = (top - base).normalized()
	var perpendicular: Vector2 = Vector2(-direction.y, direction.x)
	for side: int in [-1, 1]:
		var offset: Vector2 = perpendicular * side * 18
		draw_line(base + offset, top + offset + direction * 18, edge, 12)
		draw_line(base + offset, top + offset + direction * 18, tint, 7)
	for index: int in 12:
		var rung: Vector2 = base + direction * (index * 24 + 6)
		draw_line(rung - perpendicular * 18, rung + perpendicular * 18, edge, 8)
		draw_line(rung - perpendicular * 18, rung + perpendicular * 18, tint, 5)

func _draw_hero(feet: Vector2, _carrying: bool) -> void:
	var moving: bool = absf(state.walk_target - feet.x) > 2.0 and not state.climbing
	if moving:
		facing = signf(state.walk_target - feet.x)
	if wiping:
		facing = -1.0 if pointer.x < feet.x else 1.0
	if state.climbing:
		facing = signf(state.climb_to.x - state.climb_from.x) if state.layout.is_horizontal_anchor(state.ladder_anchor) else 1.0
	var bob: float = 0.0 if reduced_motion or state.paused else sin(clock * 9) * (1.5 if moving else 0.5)
	draw_ellipse_shadow(feet)
	var pose: String = characters.hero_pose(state, wiping, clock - place_time < 0.45)
	characters.draw_hero(self, pose, feet + Vector2(0, bob), facing)

func draw_ellipse_shadow(feet: Vector2) -> void:
	draw_set_transform(feet, 0, Vector2(1, 0.25))
	draw_circle(Vector2.ZERO, 32, Color(0.09, 0.19, 0.19, 0.3))
	draw_set_transform(Vector2.ZERO)

func _draw_guide() -> void:
	if not state.is_clean(0):
		var center: Vector2 = state.window_rect(0).get_center()
		var hand: Vector2 = center + Vector2(sin(clock * 2.5) * 33, 8 + cos(clock * 2.5) * 20)
		if reduced_motion:
			hand = center
		draw_arc(center, 41, 0.1, PI + 0.1, 22, Color(1, 0.97, 0.82, 0.7), 3)
		_box(Rect2(hand - Vector2(17, 6), Vector2(34, 12)), Color("f6d797"), INK, 3)
		draw_line(hand + Vector2(0, 6), hand + Vector2(6, 22), CREAM, 6)
	elif state.ladder_anchor < 0 and not state.climbing:
		for index: int in state.layout.anchor_count():
			if state.anchor_unlocked(index) and state.anchor_on_floor(index):
				var target: Vector2 = state.anchor_marker(index)
				var offset: float = 0.0 if reduced_motion else sin(clock * 4) * 5
				draw_polyline(PackedVector2Array([target + Vector2(-9, -63 + offset), target + Vector2(0, -52 + offset), target + Vector2(9, -63 + offset)]), MINT, 4)

func _box(area: Rect2, fill: Color, border: Color, width: float) -> void:
	draw_rect(area, fill)
	draw_rect(area, border, false, width)

func _draw_bubble_links() -> void:
	for target: int in state.masks.size():
		var age: float = clock - bubble_times[target]
		if age < 0.0 or age > 0.85:
			continue
		var finish: Vector2 = state.window_rect(target).get_center()
		var source: int = -1
		var nearest_distance: float = INF
		for candidate: int in state.masks.size():
			if candidate == target or state.window_floor(candidate) != state.window_floor(target):
				continue
			var candidate_distance: float = finish.distance_squared_to(state.window_rect(candidate).get_center())
			if candidate_distance < nearest_distance:
				nearest_distance = candidate_distance
				source = candidate
		if source < 0:
			continue
		if reduced_motion:
			draw_arc(finish, 38, 0, TAU, 24, Color(0.72, 0.94, 0.93, 0.7), 3)
			continue
		var start: Vector2 = state.window_rect(source).get_center()
		for bubble: int in 6:
			var t: float = clampf(age / 0.6 - bubble * 0.045, 0.0, 1.0)
			var point: Vector2 = start.lerp(finish, t) + Vector2(0, -sin(t * PI) * (30 + bubble * 6))
			var opacity: float = clampf((0.85 - age) * 5, 0.0, 0.8)
			draw_circle(point, 7 + bubble % 3 * 3, Color(0.78, 0.97, 0.96, opacity * 0.3))
			draw_arc(point, 7 + bubble % 3 * 3, 0, TAU, 16, Color(0.87, 1.0, 0.95, opacity), 2)
