extends SceneTree
var checks: int = 0
var failures: int = 0
var events: Array[String] = []

func _initialize() -> void:
	for seed_value: int in [1, 1729, 999999]:
		for first: String in CastleRun.GIFTS:
			for second: String in CastleRun.GIFTS:
				if first == second:
					continue
				var run: CastleRun = CastleRun.new()
				run.start(seed_value)
				check(not run.choose_gift(first), "no gift before clear")
				for wall: int in 3:
					var model: StageState = StageState.new()
					model.configure(run.layout(), run.gifts)
					var duplicate: WallLayout = WallLayout.new(seed_value, wall)
					check(model.layout.windows == duplicate.windows and model.layout.anchor_x == duplicate.anchor_x, "same seed reproduces geometry")
					solve(model)
					check(model.phase == "clear", "all gifts/seeds complete wall %d" % wall)
					check(model.moves == model.layout.placement_goal(model.gifts), "constructive solution matches placement goal")
					check(run.finish_wall(model) and not run.finish_wall(model), "exactly one result per wall")
					if wall < 2:
						check(run.choose_gift(first if wall == 0 else second), "offered gift advances")
						check(not run.choose_gift("soap"), "cannot choose twice")
				check(run.complete() and run.results.size() == 3, "three-wall run ends")
				check(run.goals_met() == 3, "each shortest route earns its own puzzle mark")
				var other_order: CastleRun = CastleRun.new()
				other_order.start(seed_value)
				other_order.gifts = [second, first]
				check(run.record_key() != other_order.record_key(), "records compare identical castle and gift order")
				check(not run.choose_gift("reach"), "completed run cannot advance")
				check(not run.beats(run.record()), "equal record is not new")
				check(run.beats({"moves": run.total("moves") + 1, "walking": 0}), "placements take precedence over walking")
				check(run.beats({"moves": run.total("moves"), "walking": run.total("walking") + 1}), "walking breaks ties")
				run.start(seed_value)
				check(run.gifts.is_empty() and run.results.is_empty() and run.wall_index == 0, "restart resets choices and progression")
	check(WallLayout.new(1, 1).anchor_x != WallLayout.new(999, 1).anchor_x, "different seeds vary anchors")
	check_final_hook_clearance()
	check_gift_edges()
	check_bridge_edges()
	print("[RUN TEST] %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func advance(model: StageState, seconds: float = 6.0) -> void:
	for frame: int in int(seconds * 60):
		model.tick(1.0 / 60)

func clean(model: StageState, index: int) -> void:
	if model.is_clean(index):
		return
	var area: Rect2 = model.window_rect(index)
	model.walk_to(area.get_center().x)
	advance(model, 2)
	var previous: Vector2 = area.position + Vector2(4, 8)
	for row: int in 5:
		var target: Vector2 = Vector2(area.end.x - 4 if row % 2 == 0 else area.position.x + 4, area.position.y + 8 + row * 36)
		model.wipe(index, previous, target)
		previous = target
	check(model.is_clean(index), "legal broad swipes clean %d on wall %d" % [index, model.layout.chapter])

func place(model: StageState, anchor: int) -> void:
	if model.ladder_anchor >= 0:
		check(model.retrieve(), "retrieve from this balcony")
		advance(model)
	check(model.request_place(anchor), "place anchor %d from floor %d" % [anchor, model.floor_index])
	advance(model)
	check(model.ladder_anchor == anchor, "placement completes")

func cross(model: StageState) -> void:
	check(model.climb(), "traverse placed ladder")
	advance(model)

func solve(model: StageState) -> void:
	clean(model, 0)
	if not model.layout.has_gap:
		clean(model, 1)
		place(model, 1)
		cross(model)
		clean(model, 3)
		clean(model, 2)
		place(model, 2)
		cross(model)
		clean(model, 4)
		return
	place(model, 0)
	cross(model)
	clean(model, 2)
	if model.layout.chapter == 2:
		solve_final_tower(model)
		check(model.bridge_crossings == (1 if model.gifts.has("reach") else 2), "final tower route crosses its single needed bridge")
		return
	if model.layout.chapter == 1 and model.gifts.has("reach"):
		# Keep the vertical ladder for the return trip BEFORE repurposing it as a bridge.
		clean(model, 4)
		cross(model)
		clean(model, 1)
		cross(model)
		place(model, 4)
		cross(model)
		clean(model, 3)
		return
	if model.layout.chapter == 1:
		place(model, 4)
		cross(model)
		clean(model, 3)
	if model.gifts.has("reach"):
		if model.layout.chapter == 2:
			place(model, 4)
			cross(model)
		clean(model, 4)
	else:
		place(model, 3 if model.layout.chapter == 1 else 2)
		cross(model)
		if model.layout.chapter == 2:
			place(model, 5)
			cross(model)
		clean(model, 4)
		cross(model)
		if model.layout.chapter == 2:
			place(model, 2)
			cross(model)
	if model.layout.chapter == 2:
		if not model.gifts.has("reach"):
			place(model, 4)
			cross(model)
		clean(model, 3)
	if model.ladder_anchor >= 0:
		model.retrieve()
		advance(model)
	place(model, 0 if model.hero.x < 360 else 1)
	cross(model)
	clean(model, 1)
	check(model.bridge_crossings == (3 if model.layout.chapter == 2 and not model.gifts.has("reach") else 1), "bridge crossings match intended route")

func solve_final_tower(model: StageState) -> void:
	if model.gifts.has("reach"):
		# Keep the middle bridge in place until E lights the permanent gallery.
		place(model, 4)
		cross(model)
		clean(model, 4)
		check(not model.floor_has_gap(1), "E permanently opens the middle gallery")
		check(model.ladder_anchor == 4, "an already placed bridge survives the gallery opening")
		model.retrieve()
		advance(model)
		clean(model, 3)
		place(model, 1)
		cross(model)
		clean(model, 1)
		cross(model)
		model.retrieve()
		advance(model)
		place(model, 3)
		cross(model)
		place(model, 7)
		cross(model)
		clean(model, 5)
		return
	# Return across the same upper bridge before changing it back to vertical.
	place(model, 2)
	cross(model)
	place(model, 5)
	cross(model)
	clean(model, 4)
	cross(model)
	model.retrieve()
	advance(model)
	place(model, 2)
	cross(model)
	check(not model.floor_has_gap(1), "E permanently opens the middle gallery")
	check(model.same_balcony(model.window_rect(3).get_center().x), "the open gallery connects the two middle balconies")
	clean(model, 3)
	place(model, 1)
	cross(model)
	clean(model, 1)
	cross(model)
	model.retrieve()
	advance(model)
	place(model, 3)
	cross(model)
	place(model, 7)
	cross(model)
	clean(model, 5)

func check_gift_edges() -> void:
	var model: StageState = StageState.new()
	model.configure(WallLayout.new(20, 2), ["reach", "soap"])
	check(not model.accessible(3), "locked upper window rejects the long tool")
	check(not model.can_reach_floor(4), "long tool cannot skip two floors")
	var area: Rect2 = model.window_rect(2)
	model.walk_to(area.get_center().x)
	advance(model)
	model.wipe(2, area.position + Vector2(8, 8), area.position + Vector2(80, 8))
	check(model.reach_window == 2 and not model.can_reach_floor(3), "first actual stroke reserves charge for one window")
	model.set_paused(true)
	var before: int = model.masks[2].remaining
	model.wipe(2, area.position, area.end)
	check(model.masks[2].remaining == before, "pause rejects gifted wiping")
	model.set_paused(false)
	clean(model, 2)
	check(model.reach_spent, "completion consumes charge")
	check(model.masks[3].fraction() == 1.0, "soap cannot penetrate a closed shutter")
	model.configure(WallLayout.new(20, 1), ["reach", "soap"])
	check(not model.reach_spent and model.reach_window == -1, "new wall refreshes reach")
	clean(model, 0)
	check(model.masks[1].fraction() == 1.0, "ground shutter blocks bubbles")
	model.configure(WallLayout.new(), ["soap"])
	clean(model, 0)
	check(model.masks[1].fraction() < 0.6 and model.masks[2].fraction() == 1, "bubbles only swipe the same-floor neighbor")
	# Prepare an almost-clean neighbor: the propagated swipe completes both once.
	model.configure(WallLayout.new(), ["soap"])
	for index: int in [2, 3, 4]:
		model.masks[index].cells.fill(0)
		model.masks[index].remaining = 0
	model.masks[1].cells.fill(0)
	model.masks[1].cells[20 * DirtMask.WIDTH] = 1
	model.masks[1].remaining = 1
	model.event_occurred.connect(func(event_name: String, _detail: int) -> void: events.append(event_name))
	clean(model, 0)
	check(events.count("stage_cleared") == 1 and events.count("window_cleaned") == 2, "bubble completion emits one stage clear")

func check_bridge_edges() -> void:
	var model: StageState = StageState.new()
	model.configure(WallLayout.new(1, 2), ["recall"])
	clean(model, 0)
	place(model, 0)
	cross(model)
	model.walk_to(600)
	advance(model)
	check(model.hero.x == WallLayout.GAP_LEFT, "walking cannot step over a gap")
	model.held_direction = 1
	advance(model)
	model.held_direction = 0
	check(model.hero.x == WallLayout.GAP_LEFT, "held controls cannot step over gap")
	check(not model.request_place(3), "cannot place vertical ladder across gap")
	clean(model, 2)
	place(model, 4)
	model.walk_to(360)
	advance(model)
	check(model.retrieve() and model.ladder_anchor == 4, "recall waits for solid footing")
	advance(model)
	check(model.ladder_anchor == -1 and (model.hero.x <= 320 or model.hero.x >= 400), "bridge retrieval leaves hero safe")
	check(model.hero.x == model.walk_target, "retrieval cancels walk across removed bridge")
	place(model, 4)
	cross(model)
	check(model.floor_index == 1 and model.bridge_crossings == 1, "crossing keeps floor and changes bank")
	check(model.retrieve() and model.ladder_anchor == -1, "recall retrieves from far bank")
	place(model, 4)
	cross(model)
	check(not model.anchor_unlocked(3), "wrong early bridge choice has upper hook still locked")
	cross(model)
	place(model, 2)
	cross(model)
	place(model, 5)
	cross(model)
	clean(model, 4)
	check(model.window_unlocked(3), "backtracking recovers a wrong bridge-first choice")

func check_final_hook_clearance() -> void:
	var minimum_distance: float = INF
	for seed_value: int in range(1, 257):
		var layout: WallLayout = WallLayout.new(seed_value, 2)
		minimum_distance = minf(minimum_distance, absf(layout.anchor_x[2] - layout.anchor_x[6]))
		minimum_distance = minf(minimum_distance, absf(layout.anchor_x[3] - layout.anchor_x[7]))
	check(minimum_distance >= StageData.ANCHOR_INPUT_RADIUS * 2.0,
		"final-floor hook targets stay outside one another's input radius across seeds")
