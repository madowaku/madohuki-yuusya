extends SceneTree
## Independent discrete search: window keys, regions, one ladder and one reach charge.
## Walking inside a balcony is free; only placing the ladder costs one move.
var failures: int = 0
var state_count: int = 0

func _initialize() -> void:
	for chapter: int in 3:
		for has_reach: bool in [false, true]:
			audit(WallLayout.new(1729, chapter), has_reach)
	print("[SOLVER] %d reachable abstract states; %d failures" % [state_count, failures])
	quit(1 if failures else 0)

func audit(wall: WallLayout, has_reach: bool) -> void:
	var right: int = 2 if wall.has_gap else 1
	var top_right: int = 4 if wall.chapter == 2 else 3
	var connections: Array = [[0, 1], [0, right], [1, 3], [right, top_right], [1, 2], [3, 4], [3, 5], [4, 5]]
	var rooms: Array[int] = [0, 0, 1, right, top_right, 5]
	var active_anchors: Array[int] = []
	for anchor: int in wall.anchor_count():
		var anchor_floor: int = int(StageData.ANCHORS[anchor]["floor"])
		if not StageData.is_horizontal_anchor(anchor) or wall.gap_on_floor(anchor_floor):
			active_anchors.append(anchor)
	# Store the four state fields directly, so a new window or anchor cannot
	# silently collide with the old packed-integer encoding's fixed radix.
	var start: Vector4i = Vector4i(0, 0, -1, 0)
	var all_clean: int = (1 << wall.window_count()) - 1
	var distances: Dictionary = {start: 0}
	var parents: Dictionary = {}
	var reverse: Dictionary = {}
	var queue: Array[Vector4i] = [start]
	var solutions: Dictionary = {}
	var minimum: int = 999
	var best: Vector4i = start
	while not queue.is_empty():
		var code: Vector4i = queue.pop_front()
		var bits: int = code.x
		var region: int = code.y
		var ladder: int = code.z
		var spent: int = code.w
		if bits == all_clean:
			if int(distances[code]) < minimum:
				best = code
			minimum = mini(minimum, int(distances[code]))
			solutions[code] = true
			# The real model stops accepting actions at CLEAR. Audit the same
			# terminal behavior instead of inventing post-clear escape routes.
			continue
		var gallery_open: bool = wall.chapter == 2 and (bits & (1 << 4)) != 0
		var next: Dictionary = {}
		for index: int in wall.window_count():
			var required: int = wall.required_window[index]
			if (bits & (1 << index)) != 0 or (required >= 0 and (bits & (1 << required)) == 0):
				continue
			if rooms[index] == region:
				next[Vector4i(bits | (1 << index), region, ladder, spent)] = 0
			elif has_reach and spent == 0 and floor_of(rooms[index]) == floor_of(region) + 1 and not (wall.chapter == 2 and region == 1 and index == 4):
				next[Vector4i(bits | (1 << index), region, ladder, 1)] = 0
		if gallery_open and region in [1, 2]:
			next[Vector4i(bits, 3 - region, ladder, spent)] = 0
		for anchor: int in active_anchors:
			var ends: Array = connections[anchor]
			if not ends.has(region):
				continue
			var covered_bridge: bool = gallery_open and anchor == 4
			if ladder == -1 and not covered_bridge and (bits & (1 << wall.hook_keys[anchor])) != 0:
				next[Vector4i(bits, region, anchor, spent)] = 1
			elif ladder == anchor:
				# A ladder already lying under the newly opened gallery remains
				# traversable and retrievable from either side.
				next[Vector4i(bits, region, -1, spent)] = 0
				next[Vector4i(bits, int(ends[1]) if region == int(ends[0]) else int(ends[0]), ladder, spent)] = 0
		for target: Vector4i in next:
			if not reverse.has(target):
				reverse[target] = []
			if not reverse[target].has(code):
				reverse[target].append(code)
			var distance: int = int(distances[code]) + int(next[target])
			if not distances.has(target) or distance < int(distances[target]):
				distances[target] = distance
				parents[target] = code
				queue.append(target)
	var tools: Array[String] = []
	if has_reach:
		tools.append("reach")
	var expected_goals: Array = [[2, 1], [4, 2], [7, 5]]
	var expected: int = int(expected_goals[wall.chapter][1 if has_reach else 0])
	if minimum != expected or minimum != wall.placement_goal(tools):
		failures += 1
		push_error("wall %d reach=%s: minimum %d, expected %d, displayed %d" % [wall.chapter, has_reach, minimum, expected, wall.placement_goal(tools)])
		var path: Array[Vector4i] = [best]
		while parents.has(best):
			best = parents[best]
			path.push_front(best)
		print("[SOLVER] shortest path (clean bits, region, ladder, reach spent): ", path)
	var recoverable: Dictionary = {}
	queue.clear()
	for solution: Vector4i in solutions:
		recoverable[solution] = true
		queue.append(solution)
	while not queue.is_empty():
		var current: Vector4i = queue.pop_front()
		for previous: Vector4i in reverse.get(current, []):
			if not recoverable.has(previous):
				recoverable[previous] = true
				queue.append(previous)
	state_count += distances.size()
	if recoverable.size() != distances.size():
		failures += 1
		push_error("wall %d has unrecoverable states" % wall.chapter)
	print("[SOLVER] wall %d, reach=%s: minimum %d, %d/%d terminal-mode states can finish" % [wall.chapter + 1, has_reach, minimum, recoverable.size(), distances.size()])

func floor_of(region: int) -> int:
	if region == 5:
		return 3
	return 0 if region == 0 else (2 if region >= 3 else 1)
