class_name StageState
extends RefCounted

signal changed
signal event_occurred(event_name: String, detail: int)

var layout: WallLayout = WallLayout.new()
var gifts: Array[String] = []
var reach_window: int = -1
var reach_spent: bool = false
var descents: int = 0
var bridge_crossings: int = 0
var bridge_moves: int = 0
var masks: Array[DirtMask] = []
var hero: Vector2 = Vector2(248, 1070)
var floor_index: int = 0
var ladder_anchor: int = -1
var moves: int = 0
var climb_distance: float = 0.0
var walking_distance: float = 0.0
var elapsed: float = 0.0
var phase: String = "title"
var climbing: bool = false
var climb_progress: float = 0.0
var climb_from: Vector2 = Vector2.ZERO
var climb_to: Vector2 = Vector2.ZERO
var climb_target_floor: int = 0
var walk_target: float = 248.0
var pending_anchor: int = -1
var pending_action: String = ""
var paused: bool = false
var held_direction: float = 0.0

func _init() -> void:
	reset()

func configure(wall: WallLayout, tools: Array[String]) -> void:
	layout = wall
	gifts = tools.duplicate()
	reset()

func window_rect(index: int) -> Rect2:
	return layout.window_rect(index)

func anchor_base(index: int) -> Vector2:
	return layout.anchor_base(index)

func anchor_top(index: int) -> Vector2:
	return layout.anchor_top(index)

func window_floor(index: int) -> int:
	return layout.window_floor(index)

func floor_has_gap(floor_index_value: int) -> bool:
	var gallery_open: bool = layout.chapter == 2 and floor_index_value == 1 and masks.size() > 4 and is_clean(4)
	return layout.gap_on_floor(floor_index_value) and not gallery_open

func can_reach_floor(index: int) -> bool:
	if window_floor(index) == floor_index:
		return true
	return gifts.has("reach") and window_floor(index) == floor_index + 1 and not reach_spent and (reach_window < 0 or reach_window == index)

func reset() -> void:
	reach_window = -1
	reach_spent = false
	descents = 0
	bridge_crossings = 0
	bridge_moves = 0
	masks.clear()
	for index: int in layout.window_count():
		masks.append(DirtMask.new())
	hero = Vector2(248, StageData.FLOORS[0])
	floor_index = 0
	ladder_anchor = -1
	moves = 0
	climb_distance = 0.0
	walking_distance = 0.0
	elapsed = 0.0
	climbing = false
	climb_progress = 0.0
	walk_target = hero.x
	pending_anchor = -1
	pending_action = ""
	held_direction = 0.0
	paused = false
	phase = "playing"
	changed.emit()

func is_clean(index: int) -> bool:
	return masks[index].remaining == 0

func cleaned_count() -> int:
	var result: int = 0
	for mask: DirtMask in masks:
		if mask.remaining == 0:
			result += 1
	return result

func can_act() -> bool:
	return phase == "playing" and not paused and not climbing

func accessible(index: int) -> bool:
	var x: float = window_rect(index).get_center().x
	var connected: bool = window_floor(index) != floor_index or same_balcony(x)
	var reach: float = 96.0 if window_floor(index) != floor_index else 185.0
	return can_act() and window_unlocked(index) and can_reach_floor(index) and connected and absf(hero.x - x) < reach

func same_balcony(x: float) -> bool:
	return not floor_has_gap(floor_index) or (hero.x <= WallLayout.GAP_LEFT and x <= WallLayout.GAP_LEFT) or (hero.x >= WallLayout.GAP_RIGHT and x >= WallLayout.GAP_RIGHT)

func bridge_on_floor() -> bool:
	return ladder_anchor >= 0 and layout.is_horizontal_anchor(ladder_anchor) and int(StageData.ANCHORS[ladder_anchor]["floor"]) == floor_index

func anchor_enabled(index: int) -> bool:
	if index < 0 or index >= layout.anchor_count():
		return false
	if not layout.is_horizontal_anchor(index) or ladder_anchor == index:
		return true
	return floor_has_gap(int(StageData.ANCHORS[index]["floor"]))

func anchor_endpoint(index: int) -> Vector2:
	if layout.is_horizontal_anchor(index):
		return anchor_base(index) if hero.x < 360 else anchor_top(index)
	return anchor_base(index) if floor_index == int(StageData.ANCHORS[index]["floor"]) else anchor_top(index)

func anchor_marker(index: int) -> Vector2:
	return anchor_base(index).lerp(anchor_top(index), 0.5) if layout.is_horizontal_anchor(index) else anchor_endpoint(index)

func _safe_walk_target(x: float) -> float:
	var target: float = clampf(x, 92.0, 628.0)
	if floor_has_gap(floor_index) and not bridge_on_floor():
		return minf(target, WallLayout.GAP_LEFT) if hero.x < 360 else maxf(target, WallLayout.GAP_RIGHT)
	return target

func window_unlocked(index: int) -> bool:
	var source: int = layout.required_window[index]
	return source < 0 or is_clean(source)

func anchor_unlocked(index: int) -> bool:
	return anchor_enabled(index) and is_clean(layout.hook_keys[index])

func anchor_on_floor(index: int) -> bool:
	if not anchor_enabled(index):
		return false
	if layout.is_horizontal_anchor(index):
		return floor_index == int(StageData.ANCHORS[index]["floor"])
	var lower: int = int(StageData.ANCHORS[index]["floor"])
	return (floor_index == lower or floor_index == lower + 1) and (same_balcony(anchor_base(index).x) or bridge_on_floor())

func walk_to(x: float) -> void:
	if not can_act():
		return
	walk_target = _safe_walk_target(x)
	pending_anchor = -1
	pending_action = ""

func request_place(index: int) -> bool:
	if not can_act() or index < 0 or index >= layout.anchor_count():
		return false
	if ladder_anchor != -1 or not anchor_unlocked(index) or not anchor_on_floor(index):
		event_occurred.emit("invalid_placement", index)
		return false
	walk_target = anchor_endpoint(index).x
	pending_anchor = index
	pending_action = ""
	return true

func retrieve() -> bool:
	if not can_act() or ladder_anchor < 0 or not anchor_on_floor(ladder_anchor):
		return false
	# Retrieval is allowed from either end, so the single ladder can never strand the hero.
	# A bridge cannot disappear while the hero is standing above the gap.
	if layout.is_horizontal_anchor(ladder_anchor) and hero.x > WallLayout.GAP_LEFT and hero.x < WallLayout.GAP_RIGHT:
		walk_to(anchor_endpoint(ladder_anchor).x)
		pending_action = "retrieve"
		return true
	if not gifts.has("recall") and absf(hero.x - anchor_endpoint(ladder_anchor).x) > 84.0:
		walk_to(anchor_endpoint(ladder_anchor).x)
		pending_action = "retrieve"
		return true
	var previous: int = ladder_anchor
	ladder_anchor = -1
	pending_anchor = -1
	pending_action = ""
	walk_target = hero.x
	event_occurred.emit("ladder_retrieved", previous)
	changed.emit()
	return true

func climb() -> bool:
	if not can_act() or ladder_anchor < 0 or not anchor_on_floor(ladder_anchor):
		return false
	if absf(hero.x - anchor_endpoint(ladder_anchor).x) > 1.0:
		walk_to(anchor_endpoint(ladder_anchor).x)
		pending_action = "climb"
		return true
	var lower: int = int(StageData.ANCHORS[ladder_anchor]["floor"])
	if layout.is_horizontal_anchor(ladder_anchor):
		climb_target_floor = floor_index
		climb_from = anchor_endpoint(ladder_anchor)
		climb_to = anchor_top(ladder_anchor) if hero.x < 360 else anchor_base(ladder_anchor)
	else:
		climb_target_floor = lower + 1 if floor_index == lower else lower
		climb_from = Vector2(anchor_base(ladder_anchor).x, StageData.FLOORS[floor_index])
		climb_to = Vector2(climb_from.x, StageData.FLOORS[climb_target_floor])
	hero = climb_from
	climb_progress = 0.0
	climbing = true
	pending_anchor = -1
	event_occurred.emit("hero_started_climb", ladder_anchor)
	changed.emit()
	return true

func wipe(index: int, from: Vector2, to: Vector2) -> int:
	if index < 0 or index >= masks.size() or not accessible(index) or is_clean(index):
		return 0
	if from.distance_to(to) < 1.0:
		return 0
	var erased: int = masks[index].erase_segment(from, to, window_rect(index))
	if erased > 0:
		if window_floor(index) > floor_index:
			reach_window = index
		event_occurred.emit("window_clean_progress", index)
		if is_clean(index):
			_complete_window(index)
		changed.emit()
	return erased

func _complete_window(index: int) -> void:
	if reach_window == index:
		reach_spent = true
	event_occurred.emit("window_cleaned", index)
	if layout.hook_keys.has(index) or layout.required_window.has(index):
		event_occurred.emit("mechanism_activated", index)
	if gifts.has("soap"):
		for neighbor: int in masks.size():
			if neighbor == index or is_clean(neighbor) or not window_unlocked(neighbor) or window_floor(neighbor) != window_floor(index):
				continue
			var area: Rect2 = window_rect(neighbor)
			var start: Vector2 = Vector2(area.position.x, area.get_center().y)
			var finish: Vector2 = Vector2(area.end.x, area.get_center().y)
			var removed: int = masks[neighbor].erase_segment(start, finish, area, 42.0)
			if removed > 0:
				event_occurred.emit("bubble_link", neighbor)
				event_occurred.emit("window_clean_progress", neighbor)
				if is_clean(neighbor):
					_complete_window(neighbor)
	if cleaned_count() == masks.size() and phase != "clear":
		phase = "clear"
		event_occurred.emit("stage_cleared", masks.size())

func tick(delta: float) -> void:
	if phase != "playing" or paused:
		return
	elapsed += delta
	if climbing:
		climb_progress = minf(1.0, climb_progress + delta / (1.2 if layout.is_horizontal_anchor(ladder_anchor) else 3.0))
		hero = climb_from.lerp(climb_to, smoothstep(0.0, 1.0, climb_progress))
		if climb_progress >= 1.0:
			if climb_to.y > climb_from.y:
				descents += 1
			if layout.is_horizontal_anchor(ladder_anchor):
				bridge_crossings += 1
				walking_distance += climb_from.distance_to(climb_to)
				event_occurred.emit("bridge_crossed", bridge_crossings)
			climbing = false
			floor_index = climb_target_floor
			walk_target = hero.x
			climb_distance += absf(climb_to.y - climb_from.y)
			event_occurred.emit("hero_finished_climb", floor_index)
			changed.emit()
		return
	if held_direction != 0.0:
		walk_target = _safe_walk_target(hero.x + held_direction * 80.0)
		pending_anchor = -1
		pending_action = ""
	var previous_x: float = hero.x
	hero.x = move_toward(hero.x, walk_target, 320.0 * delta)
	walking_distance += absf(previous_x - hero.x)
	if pending_anchor >= 0 and absf(hero.x - walk_target) < 1.0:
		ladder_anchor = pending_anchor
		pending_anchor = -1
		moves += 1
		if layout.is_horizontal_anchor(ladder_anchor):
			bridge_moves += 1
		event_occurred.emit("ladder_placed", ladder_anchor)
		changed.emit()
	if not pending_action.is_empty() and absf(hero.x - walk_target) < 1.0:
		var action: String = pending_action
		pending_action = ""
		if action == "climb":
			climb()
		else:
			retrieve()

func set_paused(value: bool) -> void:
	paused = value
	held_direction = 0.0
	pending_anchor = -1
	pending_action = ""
	walk_target = hero.x
	changed.emit()

func snapshot() -> Dictionary:
	var progress: Array[float] = []
	for mask: DirtMask in masks:
		progress.append(snappedf(1.0 - mask.fraction(), 0.001))
	var rectangles: Array = []
	var window_floors: Array[int] = []
	for index: int in masks.size():
		var area: Rect2 = window_rect(index)
		rectangles.append([area.position.x, area.position.y, area.size.x, area.size.y])
		window_floors.append(window_floor(index))
	var anchor_points: Array = []
	var horizontal_anchors: Array[bool] = []
	for index: int in layout.anchor_count():
		var marker: Vector2 = anchor_marker(index)
		anchor_points.append([marker.x, marker.y - 16])
	for index: int in layout.anchor_count():
		horizontal_anchors.append(layout.is_horizontal_anchor(index))
	var gallery_open: bool = layout.chapter == 2 and masks.size() > 4 and is_clean(4)
	return {"has_gap": layout.has_gap, "gallery_open": gallery_open, "anchor_points": anchor_points, "horizontal_anchors": horizontal_anchors, "bridge_moves": bridge_moves, "bridge_crossings": bridge_crossings, "windows": rectangles, "window_floors": window_floors, "window_count": masks.size(), "anchor_count": layout.anchor_count(), "anchors": layout.anchor_x, "required_window": layout.required_window, "hook_keys": layout.hook_keys, "placement_goal": layout.placement_goal(gifts), "gifts": gifts, "reach_window": reach_window, "reach_spent": reach_spent, "walking": walking_distance, "phase": phase, "paused": paused, "floor": floor_index, "hero": [hero.x, hero.y], "ladder": ladder_anchor, "carrying": ladder_anchor == -1, "climbing": climbing, "moves": moves, "cleaned": cleaned_count(), "progress": progress, "elapsed": snappedf(elapsed, 0.01)}
