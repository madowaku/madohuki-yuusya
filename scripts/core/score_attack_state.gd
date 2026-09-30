class_name ScoreAttackState
extends TowerState
## Fixed routes. Each input chooses one neighboring ledge, never a whole solution.
const ATTACK_DATA: Dictionary = preload("res://resources/score_attack_v1.json").data

var score: int = 0
var camera_y: float = 0.0
var finish_reason: String = ""
var last_score_window: int = -1
var score_age: float = -1.0
var display_second: int = 60
var horizontal_velocity: float = 0.0
var next_climb_duration: float = 0.58
var scored_windows: Array[int] = []
var damage: int = 0
var invulnerable: float = 0.0
var cleaning_window: int = -1
var cleaning_remaining: float = 0.0
var clean_waiting: Array[int] = []

func _init() -> void:
	var board: TowerLayout = TowerLayout.new()
	board.configure_data(ATTACK_DATA)
	configure(board, [])

func reset() -> void:
	super.reset()
	score = 0
	camera_y = 0.0
	finish_reason = ""
	last_score_window = -1
	score_age = -1.0
	display_second = 60
	horizontal_velocity = 0.0
	scored_windows.clear()
	damage = 0
	invulnerable = 0.0
	cleaning_window = -1
	cleaning_remaining = 0.0
	clean_waiting.clear()
	placement_mode = false
	hints_enabled = false

func window_points(index: int) -> int:
	return 400 if index >= 0 and index < masks.size() else 0

func final_score() -> int:
	var all_bonus: int = 1500 if cleaned_count() == masks.size() else 0
	return maxi(0, roundi(10000 + score + all_bonus - elapsed * 50 - damage * 150))

func move_to_region(destination: int, destination_x: float = -1.0) -> bool:
	if cleaning_remaining > 0:
		return false
	return super.move_to_region(destination, destination_x)

func walk_to(target: float) -> void:
	if cleaning_remaining <= 0:
		super.walk_to(target)

func wipe(index: int, from: Vector2, to: Vector2) -> int:
	if index < 0 or index >= masks.size() or not accessible(index) or is_clean(index) or from.distance_to(to) < 1:
		return 0
	if cleaning_window != index:
		cleaning_window = index
		cleaning_remaining = 1.2
		walk_target = hero.x
		horizontal_velocity = 0.0
	var erased: int = masks[index].erase_segment(from, to, window_rect(index), 32.0)
	if erased > 0:
		event_occurred.emit("window_clean_progress", index)
		if is_clean(index) and not clean_waiting.has(index):
			clean_waiting.append(index)
		changed.emit()
	return erased

func patrols() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for enemy: Dictionary in tower.data.get("enemies", []):
		var first: Array = enemy["from"]
		var last: Array = enemy["to"]
		var cycle: float = fposmod(elapsed / float(enemy["period"]) + float(enemy.get("offset", 0)), 1.0)
		var amount: float = 1.0 - absf(cycle * 2 - 1)
		var a: Vector2 = Vector2(float(first[0]), float(first[1]))
		var b: Vector2 = Vector2(float(last[0]), float(last[1]))
		result.append({"kind": str(enemy["kind"]), "point": a.lerp(b, amount), "from": a, "to": b, "direction": 1 if cycle < 0.5 else -1})
	return result

func set_hints_enabled(_enabled: bool) -> void:
	hints_enabled = false

func candidate_anchors() -> Array[int]:
	return []

func select_ladder() -> void:
	pass

func request_place(_index: int) -> bool:
	return false

func retrieve() -> bool:
	return false

func undo() -> bool:
	return false

func _remember() -> void:
	pass

func _links(at: int, _with_ladder: int) -> Array[int]:
	var result: Array[int] = []
	for index: int in tower.anchor_count():
		var ends: Array[int] = tower.anchor_ends(index)
		if ends.has(at):
			result.append(ends[1] if ends[0] == at else ends[0])
	return result

func _path(start: int, finish: int, _with_ladder: int) -> Array[int]:
	var result: Array[int] = []
	if start == finish:
		result.append(start)
	elif _links(start, -1).has(finish):
		result.append(start)
		result.append(finish)
	return result

func _begin_transition(destination: int) -> void:
	for index: int in tower.anchor_count():
		var ends: Array[int] = tower.anchor_ends(index)
		if ends.has(region) and ends.has(destination):
			ladder_anchor = index
			break
	super._begin_transition(destination)
	if transitioning:
		transition_duration = 0.4 if tower.is_horizontal_anchor(ladder_anchor) else next_climb_duration

func request_cross(index: int) -> bool:
	if not can_act() or index < 0 or index >= tower.anchor_count():
		return false
	var ends: Array[int] = tower.anchor_ends(index)
	if not ends.has(region):
		return false
	var other: int = ends[1] if ends[0] == region else ends[0]
	var endpoint: Vector2 = tower.anchor_top(index) if ends[0] == region else tower.anchor_base(index)
	return move_to_region(other, endpoint.x)

func fixed_ladder_at(point: Vector2) -> int:
	var best: int = -1
	var distance: float = INF
	for index: int in tower.anchor_count():
		if not tower.anchor_ends(index).has(region):
			continue
		var base: Vector2 = tower.anchor_base(index)
		var top: Vector2 = tower.anchor_top(index)
		var candidate: float = _distance_to_segment(point, base, top)
		if _body_hit_rect(base, top).has_point(point) and candidate < distance:
			distance = candidate
			best = index
	return best

func climb() -> bool:
	return flick_vertical(1, 0)

func flick_vertical(direction: int, velocity: float) -> bool:
	var nearest: int = -1
	var distance: float = INF
	for index: int in tower.anchor_count():
		var ends: Array[int] = tower.anchor_ends(index)
		if not ends.has(region) or tower.is_horizontal_anchor(index):
			continue
		var other: int = ends[1] if ends[0] == region else ends[0]
		var endpoint: Vector2 = tower.anchor_top(index) if ends[0] == region else tower.anchor_base(index)
		if (tower.region_floor(other) - floor_index) * direction <= 0:
			continue
		var candidate: float = absf(hero.x - endpoint.x)
		if candidate < distance:
			distance = candidate
			nearest = index
	next_climb_duration = clampf(0.7 - absf(velocity) / 6000.0, 0.42, 0.7)
	return request_cross(nearest) if nearest >= 0 else false

func drag_walk(target: float) -> void:
	if not can_act():
		return
	if floor_has_gap(floor_index) and ((hero.x <= 320 and target > 340) or (hero.x >= 400 and target < 380)):
		for index: int in tower.anchor_count():
			if tower.is_horizontal_anchor(index) and tower.anchor_ends(index).has(region):
				request_cross(index)
				return
	walk_to(target)

func coast(velocity: float) -> void:
	if not can_act():
		return
	horizontal_velocity = clampf(velocity, -920, 920)
	drag_walk(walk_target + horizontal_velocity * 0.12)

func walking_speed(delta: float) -> float:
	var difference: float = walk_target - hero.x
	var desired: float = signf(difference) * minf(920, absf(difference) * 13)
	horizontal_velocity = move_toward(horizontal_velocity, desired, 4200 * delta)
	return maxf(35, absf(horizontal_velocity)) if absf(difference) > 0.5 else 0.0

func _check_clear() -> void:
	for index: int in masks.size():
		if is_clean(index) and not scored_windows.has(index) and not clean_waiting.has(index):
			scored_windows.append(index)
			score += window_points(index)
			last_score_window = index
			score_age = 0.0
	if region == tower.completion_region() and phase == "playing":
		_finish("summit")

func _finish(reason: String) -> void:
	finish_reason = reason
	phase = "clear"
	jobs.clear()
	transitioning = false
	climbing = false
	walk_target = hero.x
	event_occurred.emit("stage_cleared", cleaned_count())
	changed.emit()

func tick(delta: float) -> void:
	if paused or phase != "playing":
		return
	super.tick(delta)
	cleaning_remaining = maxf(0, cleaning_remaining - delta)
	if cleaning_remaining == 0:
		for index: int in clean_waiting.duplicate():
			clean_waiting.erase(index)
			event_occurred.emit("window_cleaned", index)
			event_occurred.emit("window_revealed", index)
			_check_clear()
			changed.emit()
	invulnerable = maxf(0, invulnerable - delta)
	if phase == "playing" and invulnerable == 0:
		for enemy: Dictionary in patrols():
			var enemy_point: Vector2 = enemy["point"]
			if enemy_point.distance_to(hero + Vector2(0, -38)) < 30:
				damage += 1
				invulnerable = 1.5
				event_occurred.emit("monster_contact", damage)
				changed.emit()
				break
	var target: float = minf(0, hero.y - 916)
	camera_y = lerpf(camera_y, target, minf(1, delta * 12))
	if score_age >= 0:
		score_age += delta
	var second: int = int(elapsed)
	if second != display_second:
		display_second = second
		changed.emit()

func run_stats() -> Dictionary:
	return {"score_attack": true, "score": final_score(), "window_points": score, "damage": damage, "all_clean_bonus": 1500 if cleaned_count() == masks.size() else 0, "cleaned": cleaned_count(),
		"total_windows": masks.size(), "seconds": snappedf(elapsed, 0.01),
		"won": finish_reason == "summit"}

func snapshot() -> Dictionary:
	var result: Dictionary = super.snapshot()
	var fixed: Array[Dictionary] = []
	for index: int in tower.anchor_count():
		var base: Vector2 = tower.anchor_base(index)
		var top: Vector2 = tower.anchor_top(index)
		fixed.append({"index": index, "ends": tower.anchor_ends(index),
			"base": [base.x, base.y], "top": [top.x, top.y],
			"horizontal": tower.is_horizontal_anchor(index)})
	result.merge(run_stats(), true)
	result.merge({"fixed_ladders": fixed, "camera_y": camera_y, "finish_reason": finish_reason,
		"neighbor_regions": _links(region, -1), "cleaning_remaining": cleaning_remaining, "invulnerable": invulnerable}, true)
	return result
