class_name TowerState
extends StageState
## A queued command is atomic for Undo. Routing handles transport, never chooses a new hook.
var region: int = 0
var shutter_open: bool = false
var gallery_open: bool = false
var placement_mode: bool = false
var preview_anchor: int = -1
var jobs: Array[Dictionary] = []
var history: Array[Dictionary] = []
var transitioning: bool = false
var transition_from: Vector2 = Vector2.ZERO
var transition_to: Vector2 = Vector2.ZERO
var transition_progress: float = 0.0
var transition_region: int = 0
var transition_duration: float = 0.0
var transition_ladder: bool = false
var reposition_source: int = -1
var tower: TowerLayout
var help_visible: bool = false
var hints_enabled: bool = true
var unreachable_points: Array[Vector2] = []
var unreachable_gap: Array[Vector2] = []
var unreachable_window: int = -1
var unreachable_age: float = -1.0
var nudge_age: float = -1.0
var idle_time: float = 0.0
var idle_nudged: bool = false

func _init() -> void:
	configure(TowerLayout.new(), [])

func configure(wall: WallLayout, _tools: Array[String]) -> void:
	layout = wall
	tower = wall as TowerLayout
	gifts.clear()
	reset()

func reset() -> void:
	if tower == null:
		return
	super.reset()
	# Curved glass has no invisible dirt in the two corners above its arch.
	for index: int in masks.size():
		var area: Rect2 = window_rect(index)
		var radius: float = area.size.x / 2
		for y: int in DirtMask.HEIGHT:
			for x: int in DirtMask.WIDTH:
				var point: Vector2 = Vector2((x + 0.5) / DirtMask.WIDTH * area.size.x, (y + 0.5) / DirtMask.HEIGHT * area.size.y)
				if point.y < radius and point.distance_to(Vector2(radius, radius)) > radius:
					masks[index].cells[y * DirtMask.WIDTH + x] = 0
					masks[index].remaining -= 1
		masks[index].total_cells = masks[index].remaining
	hero = Vector2(248, tower.floor_y(0))
	walk_target = hero.x
	region = 0
	shutter_open = false
	gallery_open = false
	placement_mode = false
	preview_anchor = -1
	help_visible = false
	unreachable_points.clear()
	unreachable_gap.clear()
	unreachable_window = -1
	unreachable_age = -1.0
	nudge_age = -1.0
	idle_time = 0.0
	idle_nudged = false
	jobs.clear()
	history.clear()
	transitioning = false
	reposition_source = -1
	changed.emit()

func busy() -> bool:
	return transitioning or not jobs.is_empty()

func can_act() -> bool:
	return phase == "playing" and not paused and not busy()

func inside() -> bool:
	return region == 6

func floor_has_gap(value: int) -> bool:
	return tower.gap_on_floor(value) and not (value == 1 and gallery_open)

func window_unlocked(index: int) -> bool:
	return index != TowerLayout.SHUTTER or shutter_open

func can_reach_floor(index: int) -> bool:
	return tower.window_region(index) == region or (gallery_open and region in [1, 2] and tower.window_region(index) in [1, 2])

func accessible(index: int) -> bool:
	if index < 0 or index >= masks.size() or not can_act() or inside() or not window_unlocked(index):
		return false
	var window_region: int = tower.window_region(index)
	var same_landing: bool = window_region == region or (gallery_open and region in [1, 2] and window_region in [1, 2])
	return same_landing and absf(hero.x - window_rect(index).get_center().x) < 110.0

func same_balcony(x: float) -> bool:
	return not floor_has_gap(floor_index) or (hero.x <= WallLayout.GAP_LEFT and x <= WallLayout.GAP_LEFT) or (hero.x >= WallLayout.GAP_RIGHT and x >= WallLayout.GAP_RIGHT)

func anchor_enabled(index: int) -> bool:
	return index >= 0 and index < tower.anchor_count() and not (index == 4 and gallery_open and ladder_anchor != 4)

func anchor_unlocked(index: int) -> bool:
	return anchor_enabled(index) and is_clean(tower.hook_keys[index])

func anchor_on_floor(index: int) -> bool:
	return anchor_enabled(index) and tower.anchor_ends(index).has(region)

func anchor_endpoint(index: int) -> Vector2:
	var ends: Array[int] = tower.anchor_ends(index)
	if ends.has(region):
		return tower.anchor_base(index) if region == ends[0] else tower.anchor_top(index)
	return tower.anchor_base(index) if floor_index == tower.region_floor(ends[0]) else tower.anchor_top(index)

func anchor_marker(index: int) -> Vector2:
	if tower.is_horizontal_anchor(index):
		return tower.anchor_base(index).lerp(tower.anchor_top(index), 0.5)
	return anchor_endpoint(index)

func hook_hit_rect(index: int) -> Rect2:
	# At a shared landing, incoming and outgoing hooks have separate targets.
	var point: Vector2 = anchor_marker(index) + Vector2(0, 16)
	if not tower.is_horizontal_anchor(index) and floor_index == tower.region_floor(int(tower.anchor_ends(index)[1])) and floor_index in [1, 2]:
		point.x += 100.0 if point.x < 360 else -100.0
	return Rect2(point - TowerLayout.HIT_SIZE * 0.5, TowerLayout.HIT_SIZE)

func _body_hit_rect(first: Vector2, last: Vector2) -> Rect2:
	var minimum: Vector2 = Vector2(minf(first.x, last.x), minf(first.y, last.y))
	var maximum: Vector2 = Vector2(maxf(first.x, last.x), maxf(first.y, last.y))
	var center: Vector2 = (minimum + maximum) * 0.5
	var size: Vector2 = (maximum - minimum) + Vector2(48.0, 48.0)
	size.x = maxf(size.x, 88.0)
	size.y = maxf(size.y, 88.0)
	return Rect2(center - size * 0.5, size)

func ladder_hit_rect() -> Rect2:
	if ladder_anchor < 0:
		return Rect2()
	return _body_hit_rect(tower.anchor_base(ladder_anchor), tower.anchor_top(ladder_anchor))

func carried_ladder_hit_rect() -> Rect2:
	# Match the separate carried-ladder prop drawn beside the hero.
	return Rect2(hero + Vector2(-109.0, -74.0), Vector2(88.0, 88.0))

func ghost_hit_rect(index: int) -> Rect2:
	if index < 0 or index >= tower.anchor_count():
		return Rect2()
	return _body_hit_rect(tower.anchor_base(index), tower.anchor_top(index))

func _distance_to_segment(point: Vector2, first: Vector2, last: Vector2) -> float:
	var segment: Vector2 = last - first
	var amount: float = 0.0
	if segment.length_squared() > 0.001:
		amount = clampf((point - first).dot(segment) / segment.length_squared(), 0.0, 1.0)
	return point.distance_to(first + segment * amount)

func placement_candidate_at(point: Vector2) -> int:
	var best_index: int = -1
	var best_segment_distance: float = INF
	var best_center_distance: float = INF
	for index: int in candidate_anchors():
		if not ghost_hit_rect(index).has_point(point):
			continue
		var first: Vector2 = tower.anchor_base(index)
		var last: Vector2 = tower.anchor_top(index)
		var segment_distance: float = _distance_to_segment(point, first, last)
		var center_distance: float = point.distance_squared_to((first + last) * 0.5)
		if segment_distance < best_segment_distance - 0.01 or (is_equal_approx(segment_distance, best_segment_distance) and center_distance < best_center_distance):
			best_index = index
			best_segment_distance = segment_distance
			best_center_distance = center_distance
	return best_index

func _mark_input_activity() -> void:
	idle_time = 0.0
	idle_nudged = false
	nudge_age = -1.0

func toggle_help() -> void:
	if not can_act():
		return
	_mark_input_activity()
	help_visible = not help_visible
	changed.emit()

func set_hints_enabled(value: bool) -> void:
	if hints_enabled == value:
		return
	hints_enabled = value
	_mark_input_activity()
	if not value:
		idle_nudged = true
	changed.emit()

func _region_total() -> int:
	return 7

func reachable_regions() -> Array[int]:
	var result: Array[int] = []
	var queue: Array[int] = [region]
	var visited: Dictionary = {region: true}
	while not queue.is_empty():
		var current: int = queue.pop_front()
		result.append(current)
		for next: int in _links(current, ladder_anchor):
			if not visited.has(next):
				visited[next] = true
				queue.append(next)
	return result

func reachable_windows() -> Array[int]:
	var result: Array[int] = []
	if inside():
		return result
	var reached: Array[int] = reachable_regions()
	for index: int in masks.size():
		if not is_clean(index) and window_unlocked(index) and tower.window_region(index) in reached:
			result.append(index)
	return result

func toggle_hints() -> void:
	set_hints_enabled(not hints_enabled)

func _all_links(at: int) -> Array[int]:
	var result: Array[int] = _links(at, ladder_anchor)
	for index: int in tower.anchor_count():
		var ends: Array[int] = tower.anchor_ends(index)
		if ends.has(at):
			var next: int = int(ends[1]) if at == int(ends[0]) else int(ends[0])
			if not result.has(next):
				result.append(next)
	return result

func _diagnostic_path(start: int, finish: int) -> Array[int]:
	var queue: Array[int] = [start]
	var parents: Dictionary = {start: -1}
	while not queue.is_empty():
		var at: int = queue.pop_front()
		if at == finish:
			var path: Array[int] = [finish]
			while int(parents[at]) >= 0:
				at = int(parents[at])
				path.push_front(at)
			return path
		for next: int in _all_links(at):
			if not parents.has(next):
				parents[next] = at
				queue.append(next)
	return []

func _anchor_for_edge(first_region: int, last_region: int) -> int:
	for index: int in tower.anchor_count():
		var ends: Array[int] = tower.anchor_ends(index)
		if ends.has(first_region) and ends.has(last_region):
			return index
	return -1

func _region_point(value: int) -> Vector2:
	if value == 6:
		return Vector2(360.0, tower.floor_y(2) - 24.0)
	var floor_number: int = tower.region_floor(value)
	var x: float = 360.0
	if value in [1, 3]:
		x = 210.0
	elif value in [2, 4]:
		x = 510.0
	return Vector2(x, tower.floor_y(floor_number))

func report_unreachable_window(index: int) -> void:
	if index < 0 or index >= masks.size():
		return
	_mark_input_activity()
	unreachable_window = index
	unreachable_age = 0.0
	unreachable_points.clear()
	unreachable_gap.clear()
	var target_region: int = tower.window_region(index)
	var path: Array[int] = _diagnostic_path(region, target_region)
	var trace: Array[Vector2] = [hero]
	var found_gap: bool = false
	for step: int in range(1, path.size()):
		var previous_region: int = path[step - 1]
		var next_region: int = path[step]
		if not _links(previous_region, ladder_anchor).has(next_region):
			var anchor: int = _anchor_for_edge(previous_region, next_region)
			if anchor >= 0:
				var ends: Array[int] = tower.anchor_ends(anchor)
				var stop: Vector2 = tower.anchor_base(anchor) if previous_region == ends[0] else tower.anchor_top(anchor)
				var far: Vector2 = tower.anchor_top(anchor) if previous_region == ends[0] else tower.anchor_base(anchor)
				trace.append(stop)
				unreachable_gap.append(stop)
				unreachable_gap.append(far)
				found_gap = true
			break
		trace.append(_region_point(next_region))
	if not found_gap and path.is_empty():
		trace.append(tower.window_rect(index).get_center())
	unreachable_points = trace
	if found_gap:
		nudge_age = 0.0
		idle_nudged = true
	event_occurred.emit("unreachable_window", index)
	changed.emit()

func destination_region_at(point: Vector2) -> int:
	var best_floor: int = -1
	var best_distance: float = INF
	var floor_count: int = tower.DATA["floors"].size()
	if tower is TutorialLayout:
		var tutorial_layout: TutorialLayout = tower as TutorialLayout
		floor_count = tutorial_layout.tutorial_step_data()["floors"].size()
	for floor_number: int in floor_count:
		var distance: float = absf(point.y - tower.floor_y(floor_number))
		if distance < best_distance:
			best_distance = distance
			best_floor = floor_number
	if best_distance > 64.0:
		return -1
	if tower is TutorialLayout:
		var tutorial: TutorialLayout = tower as TutorialLayout
		match tutorial.tutorial_step:
			1:
				return 0 if best_floor == 0 else 1
			2:
				return 0 if point.x < 360.0 else 1
			3:
				if best_floor == 0:
					return 0
				return 1 if point.x < 360.0 else 2
	match best_floor:
		0:
			return 0
		1:
			return 1 if point.x < 360.0 else 2
		2:
			return 3 if point.x < 360.0 else 4
		3:
			return 5
	return -1

func move_to_region(destination: int, destination_x: float = -1.0) -> bool:
	if not can_act() or inside() and destination != 6:
		return false
	var path: Array[int] = _path(region, destination, ladder_anchor)
	if path.is_empty():
		return false
	_mark_input_activity()
	var target_x: float = destination_x if destination_x >= 0.0 else hero.x
	if path.size() == 1:
		walk_to(target_x)
		return true
	jobs.clear()
	_append_path(path, jobs)
	if absf(hero.x - target_x) > 1.0:
		jobs.append({"type": "walk", "x": target_x})
	placement_mode = false
	preview_anchor = -1
	help_visible = false
	changed.emit()
	return true

func tap_destination(point: Vector2) -> bool:
	if not can_act():
		return false
	if inside():
		_mark_input_activity()
		walk_to(point.x)
		return true
	var destination: int = destination_region_at(point)
	if destination < 0:
		return false
	return move_to_region(destination, point.x)

func select_ladder() -> void:
	if can_act() and not inside():
		_mark_input_activity()
		placement_mode = not placement_mode
		preview_anchor = -1
		changed.emit()

func _links(at: int, with_ladder: int) -> Array[int]:
	var result: Array[int] = []
	if gallery_open and at in [1, 2]:
		result.append(3 - at)
	if is_clean(TowerLayout.ENTRY):
		if at == 3:
			result.append(6)
		elif at == 6:
			result.append(3)
	if shutter_open:
		if at == 4:
			result.append(6)
		elif at == 6:
			result.append(4)
	if with_ladder >= 0:
		var ends: Array = tower.anchor_ends(with_ladder)
		if ends.has(at):
			result.append(int(ends[1]) if at == int(ends[0]) else int(ends[0]))
	return result

func _path(start: int, finish: int, with_ladder: int) -> Array[int]:
	var queue: Array[int] = [start]
	var parents: Dictionary = {start: -1}
	while not queue.is_empty():
		var at: int = queue.pop_front()
		if at == finish:
			var path: Array[int] = [finish]
			while int(parents[at]) >= 0:
				at = int(parents[at])
				path.push_front(at)
			return path
		for next: int in _links(at, with_ladder):
			if not parents.has(next):
				parents[next] = at
				queue.append(next)
	return []

func _append_path(path: Array[int], target_jobs: Array[Dictionary]) -> void:
	for index: int in range(1, path.size()):
		target_jobs.append({"type": "region", "region": path[index]})

func relocation_plan(index: int) -> Array[Dictionary]:
	var best: Array[Dictionary] = []
	if inside() or not anchor_unlocked(index) or index == ladder_anchor:
		return best
	var cost: float = INF
	var recovery_ends: Array = [region] if ladder_anchor < 0 else tower.anchor_ends(ladder_anchor)
	for recovery: int in recovery_ends:
		var before: Array[int] = _path(region, recovery, ladder_anchor)
		if before.is_empty():
			continue
		for destination: int in tower.anchor_ends(index):
			var after: Array[int] = _path(recovery, destination, -1)
			if after.is_empty():
				continue
			var retrieval_point: Vector2 = hero if ladder_anchor < 0 else (anchor_base(ladder_anchor) if recovery == int(tower.anchor_ends(ladder_anchor)[0]) else anchor_top(ladder_anchor))
			var destination_point: Vector2 = anchor_base(index) if destination == int(tower.anchor_ends(index)[0]) else anchor_top(index)
			var next_cost: float = (before.size() + after.size()) * 1000.0 + absf(hero.x - retrieval_point.x) + absf(retrieval_point.x - destination_point.x)
			if next_cost >= cost:
				continue
			cost = next_cost
			best.clear()
			_append_path(before, best)
			if ladder_anchor >= 0:
				best.append({"type": "walk", "x": retrieval_point.x})
				best.append({"type": "retrieve"})
			_append_path(after, best)
			best.append({"type": "walk", "x": destination_point.x})
			best.append({"type": "place", "anchor": index})
	return best

func candidate_anchors() -> Array[int]:
	var result: Array[int] = []
	if not can_act() or inside():
		return result
	for index: int in tower.anchor_count():
		if not relocation_plan(index).is_empty():
			result.append(index)
	return result

func request_place(index: int) -> bool:
	if not can_act() or not anchor_enabled(index):
		return false
	_mark_input_activity()
	var plan: Array[Dictionary] = relocation_plan(index)
	if plan.is_empty():
		event_occurred.emit("invalid_placement", index)
		return false
	_remember()
	reposition_source = ladder_anchor
	jobs = plan
	preview_anchor = index
	placement_mode = false
	help_visible = false
	changed.emit()
	return true

func walk_to(x: float) -> void:
	if not can_act():
		return
	_mark_input_activity()
	var target: float = clampf(x, 92, 628)
	if not inside() and floor_has_gap(floor_index) and not bridge_on_floor():
		target = minf(target, WallLayout.GAP_LEFT) if hero.x < 360 else maxf(target, WallLayout.GAP_RIGHT)
	if not inside() and floor_has_gap(floor_index) and bridge_on_floor() and (x < 360) != (hero.x < 360):
		climb()
		return
	walk_target = target
	placement_mode = false
	preview_anchor = -1

func bridge_on_floor() -> bool:
	return ladder_anchor >= 0 and tower.is_horizontal_anchor(ladder_anchor) and anchor_on_floor(ladder_anchor)

func climb() -> bool:
	if not can_act() or ladder_anchor < 0 or not anchor_on_floor(ladder_anchor):
		return false
	_mark_input_activity()
	_remember()
	var ends: Array = tower.anchor_ends(ladder_anchor)
	jobs.append({"type": "region", "region": int(ends[1]) if region == int(ends[0]) else int(ends[0])})
	placement_mode = false
	changed.emit()
	return true

func retrieve() -> bool:
	# Optional keyboard/debug affordance. Normal play selects the next hook.
	if not can_act() or ladder_anchor < 0 or not anchor_on_floor(ladder_anchor):
		return false
	_mark_input_activity()
	_remember()
	jobs.append({"type": "walk", "x": anchor_endpoint(ladder_anchor).x})
	jobs.append({"type": "retrieve"})
	return true

func interact_window(index: int) -> bool:
	if not can_act() or index < 0 or index >= masks.size():
		return false
	_mark_input_activity()
	if inside():
		if index not in [TowerLayout.ENTRY, TowerLayout.SHUTTER]:
			return false
		if index == TowerLayout.SHUTTER and not shutter_open:
			_remember()
			jobs.append({"type": "walk", "x": window_rect(index).get_center().x})
			jobs.append({"type": "shutter"})
		else:
			var exit_region: int = tower.window_region(index)
			var exit_path: Array[int] = _path(region, exit_region, ladder_anchor)
			if exit_path.is_empty():
				report_unreachable_window(index)
				return false
			jobs.clear()
			jobs.append({"type": "walk", "x": window_rect(index).get_center().x})
			_append_path(exit_path, jobs)
		placement_mode = false
		help_visible = false
		changed.emit()
		return true
	if index == TowerLayout.SHUTTER and not shutter_open:
		event_occurred.emit("shutter_rattled", index)
		return false
	if index == TowerLayout.GALLERY_KEY and is_clean(index) and not gallery_open and can_reach_floor(index):
		_activate_gallery()
		return true
	var target_region: int = tower.window_region(index)
	if index in [TowerLayout.ENTRY, TowerLayout.SHUTTER] and is_clean(index):
		if not _path(region, target_region, ladder_anchor).is_empty():
			_remember()
			if not move_to_region(target_region, window_rect(index).get_center().x):
				return false
			jobs.append({"type": "region", "region": 6})
			return true
	if not _path(region, target_region, ladder_anchor).is_empty():
		return move_to_region(target_region, window_rect(index).get_center().x)
	report_unreachable_window(index)
	return false

func wipe(index: int, from: Vector2, to: Vector2) -> int:
	if index < 0 or index >= masks.size() or not accessible(index) or is_clean(index) or from.distance_to(to) < 1.0:
		return 0
	var erased: int = masks[index].erase_segment(from, to, window_rect(index), 32.0)
	if erased > 0:
		event_occurred.emit("window_clean_progress", index)
		if is_clean(index):
			event_occurred.emit("window_cleaned", index)
			event_occurred.emit("window_revealed", index)
			if index == TowerLayout.GALLERY_KEY:
				_activate_gallery()
			_check_clear()
		changed.emit()
	return erased

func _activate_gallery() -> void:
	_remember()
	gallery_open = true
	event_occurred.emit("mechanism_activated", TowerLayout.GALLERY_KEY)
	_check_clear()
	changed.emit()

func _check_clear() -> void:
	if cleaned_count() == masks.size() and gallery_open and shutter_open and region == 5 and phase != "clear":
		phase = "clear"
		placement_mode = false
		event_occurred.emit("stage_cleared", masks.size())

func _remember() -> void:
	history.append({"hero": hero, "region": region, "ladder": ladder_anchor, "moves": moves, "shutter": shutter_open, "gallery": gallery_open, "walking": walking_distance, "distance": climb_distance, "descents": descents, "crossings": bridge_crossings, "bridges": bridge_moves})
	if history.size() > 128:
		history.pop_front()

func undo() -> bool:
	if history.is_empty() or paused or phase == "title":
		return false
	var previous: Dictionary = history.pop_back()
	hero = previous["hero"]
	region = int(previous["region"])
	floor_index = tower.region_floor(region)
	ladder_anchor = int(previous["ladder"])
	moves = int(previous["moves"])
	shutter_open = bool(previous["shutter"])
	gallery_open = bool(previous["gallery"])
	walking_distance = float(previous["walking"])
	climb_distance = float(previous["distance"])
	descents = int(previous["descents"])
	bridge_crossings = int(previous["crossings"])
	bridge_moves = int(previous["bridges"])
	jobs.clear()
	transitioning = false
	climbing = false
	walk_target = hero.x
	held_direction = 0
	placement_mode = false
	preview_anchor = -1
	reposition_source = -1
	phase = "playing"
	# Polished glass is retained. Undo restores the route, not the player's scrubbing effort.
	event_occurred.emit("state_undone", history.size())
	changed.emit()
	return true

func _begin_transition(destination: int) -> void:
	var uses_ladder: bool = destination != 6 and region != 6 and not (gallery_open and region in [1, 2] and destination in [1, 2])
	var start_point: Vector2 = hero
	var end_point: Vector2 = hero
	if uses_ladder:
		start_point = anchor_endpoint(ladder_anchor)
		end_point = anchor_top(ladder_anchor) if region == int(tower.anchor_ends(ladder_anchor)[0]) else anchor_base(ladder_anchor)
	elif destination == 6:
		var portal: int = TowerLayout.ENTRY if region == 3 else TowerLayout.SHUTTER
		start_point = Vector2(window_rect(portal).get_center().x, tower.floor_y(2))
		end_point = start_point + Vector2(0, -24)
	elif region == 6:
		var portal: int = TowerLayout.ENTRY if destination == 3 else TowerLayout.SHUTTER
		start_point = Vector2(window_rect(portal).get_center().x, tower.floor_y(2) - 24)
		end_point = start_point + Vector2(0, 24)
	else:
		end_point.x = 440.0 if destination == 2 else 280.0
	walk_target = start_point.x
	if absf(hero.x - walk_target) > 1:
		return
	transitioning = true
	transition_ladder = uses_ladder
	transition_from = hero
	transition_to = end_point
	transition_region = destination
	transition_progress = 0
	transition_duration = 0.85 if uses_ladder else 0.35
	climbing = uses_ladder
	climb_from = hero
	climb_to = end_point
	if uses_ladder:
		event_occurred.emit("hero_started_climb", ladder_anchor)

func tick(delta: float) -> void:
	if phase != "playing" or paused:
		return
	elapsed += delta
	if unreachable_age >= 0.0:
		unreachable_age += delta
		if unreachable_age > 1.2:
			unreachable_age = -1.0
			unreachable_window = -1
			unreachable_points.clear()
			unreachable_gap.clear()
			changed.emit()
	if nudge_age >= 0.0:
		nudge_age += delta
		if nudge_age > 1.2:
			nudge_age = -1.0
			changed.emit()
	if hints_enabled and not help_visible and not placement_mode and not inside() and not busy():
		idle_time += delta
		if idle_time >= 5.0 and not idle_nudged:
			nudge_age = 0.0
			idle_nudged = true
			changed.emit()
	else:
		idle_time = 0.0
	if transitioning:
		transition_progress = minf(1, transition_progress + delta / transition_duration)
		hero = transition_from.lerp(transition_to, smoothstep(0, 1, transition_progress))
		if transition_progress >= 1:
			var was_inside: bool = inside()
			region = transition_region
			floor_index = tower.region_floor(region)
			if transition_ladder:
				climb_distance += absf(transition_to.y - transition_from.y)
				if transition_to.y > transition_from.y:
					descents += 1
				if tower.is_horizontal_anchor(ladder_anchor):
					bridge_crossings += 1
					event_occurred.emit("bridge_crossed", bridge_crossings)
				event_occurred.emit("hero_finished_climb", floor_index)
			elif inside() != was_inside:
				event_occurred.emit("hero_entered_window" if inside() else "hero_exited_window", TowerLayout.ENTRY if hero.x < 360 else TowerLayout.SHUTTER)
			transitioning = false
			climbing = false
			jobs.pop_front()
			walk_target = hero.x
			_check_clear()
			changed.emit()
		return
	if not jobs.is_empty():
		var job: Dictionary = jobs[0]
		match str(job["type"]):
			"region":
				_begin_transition(int(job["region"]))
			"walk":
				walk_target = float(job["x"])
				if absf(hero.x - walk_target) < 1:
					jobs.pop_front()
			"retrieve":
				var previous: int = ladder_anchor
				ladder_anchor = -1
				jobs.pop_front()
				event_occurred.emit("ladder_retrieved", previous)
				changed.emit()
			"place":
				ladder_anchor = int(job["anchor"])
				moves += 1
				if tower.is_horizontal_anchor(ladder_anchor):
					bridge_moves += 1
				jobs.pop_front()
				preview_anchor = -1
				event_occurred.emit("ladder_placed", ladder_anchor)
				if reposition_source >= 0:
					event_occurred.emit("ladder_repositioned", ladder_anchor)
				_check_clear()
				changed.emit()
			"shutter":
				shutter_open = true
				jobs.pop_front()
				event_occurred.emit("shutter_opened", TowerLayout.SHUTTER)
				changed.emit()
	elif held_direction != 0:
		walk_to(hero.x + held_direction * 80)
	var previous_x: float = hero.x
	hero.x = move_toward(hero.x, walk_target, 460.0 * delta)
	walking_distance += absf(hero.x - previous_x)
	if jobs.is_empty() and not inside() and gallery_open and floor_index == 1:
		region = 1 if hero.x <= 360 else 2

func set_paused(value: bool) -> void:
	# Freeze the transaction in place; resume continues it without losing the ladder.
	paused = value
	held_direction = 0
	if jobs.is_empty() and not transitioning:
		walk_target = hero.x
	changed.emit()

func snapshot() -> Dictionary:
	var result: Dictionary = super.snapshot()
	var hits: Array = []
	var hooks: Array = []
	var ghosts: Array = []
	var trace: Array = []
	var missing_edge: Array = []
	var kinds: Array[String] = []
	var visible_hooks: Array[int] = []
	if placement_mode:
		visible_hooks = candidate_anchors()
	elif help_visible:
		visible_hooks = candidate_anchors()
	for index: int in masks.size():
		var hit: Rect2 = tower.window_hit_rect(index)
		hits.append([hit.position.x, hit.position.y, hit.size.x, hit.size.y])
		kinds.append(tower.window_kind(index))
	for index: int in visible_hooks:
		var ghost: Rect2 = ghost_hit_rect(index)
		var first: Vector2 = tower.anchor_base(index)
		var last: Vector2 = tower.anchor_top(index)
		ghosts.append({"index": index, "rect": [ghost.position.x, ghost.position.y, ghost.size.x, ghost.size.y], "base": [first.x, first.y], "top": [last.x, last.y]})
	for point: Vector2 in unreachable_points:
		trace.append([point.x, point.y])
	for point: Vector2 in unreachable_gap:
		missing_edge.append([point.x, point.y])
	for index: int in tower.anchor_count():
		var hit: Rect2 = hook_hit_rect(index)
		hooks.append([hit.position.x, hit.position.y, hit.size.x, hit.size.y])
		result["anchor_points"][index] = [hit.get_center().x, hit.get_center().y]
	var ladder_hit: Rect2 = ladder_hit_rect()
	var carried_hit: Rect2 = carried_ladder_hit_rect()
	result.merge({"mode": "visual_ux", "region": region, "inside": inside(), "busy": busy(), "window_hits": hits, "hook_hits": hooks, "ghost_hits": ghosts, "ladder_hit": [ladder_hit.position.x, ladder_hit.position.y, ladder_hit.size.x, ladder_hit.size.y], "carried_ladder_hit": [carried_hit.position.x, carried_hit.position.y, carried_hit.size.x, carried_hit.size.y], "window_kinds": kinds, "shutter_open": shutter_open, "gallery_open": gallery_open, "placement_mode": placement_mode, "candidates": visible_hooks, "preview": preview_anchor, "undo_depth": history.size(), "reachable_regions": reachable_regions(), "reachable_windows": reachable_windows(), "help_visible": help_visible, "hints_enabled": hints_enabled, "unreachable_points": trace, "unreachable_gap": missing_edge, "unreachable_window": unreachable_window, "unreachable_age": unreachable_age, "nudge_age": nudge_age}, true)
	return result
