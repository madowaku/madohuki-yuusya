extends SceneTree

var checks: int = 0
var failures: int = 0
var model: TutorialState

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func finish_jobs() -> void:
	for step: int in 1600:
		model.tick(0.05)
		if not model.busy() and absf(model.hero.x - model.walk_target) < 1.0:
			return
	check(false, "tutorial command finishes within bounded time")

func clean(index: int) -> void:
	var area: Rect2 = model.window_rect(index)
	var last: Vector2 = area.position + Vector2(3, 5)
	for row: int in 4:
		var point: Vector2 = Vector2(area.end.x - 3 if row % 2 == 0 else area.position.x + 3, area.position.y + 5 + row * (area.size.y - 10) / 3)
		model.wipe(index, last, point)
		last = point
	check(model.is_clean(index), "ordinary zigzag completely cleans tutorial window %d" % index)

func place(index: int, expected_moves: int) -> void:
	check(model.request_place(index), "smart tutorial placement %d is legal" % index)
	finish_jobs()
	check(model.ladder_anchor == index, "tutorial ladder reaches selected destination %d" % index)
	check(model.moves == expected_moves, "tutorial placement count is %d" % expected_moves)

func run() -> void:
	test_t1_vertical()
	test_t2_bridge()
	test_t3_reposition()
	print("[TUTORIAL TEST] %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)

func test_t1_vertical() -> void:
	model = TutorialState.new()
	model.configure_tutorial(1)
	check(model.tutorial_step == 1 and model.masks.size() == 1, "T1 loads one dirty upper window")
	check(model.ladder_anchor == 0 and model.moves == 0 and model.candidate_anchors().is_empty(), "T1 starts with its sole ladder installed at no placement cost")
	check(model.tower.floor_y(0) == 1040 and model.hero == Vector2(360, 1040), "T1 is centered and starts on its lower floor")
	check(model.tower.placement_goal([]) == 0, "T1 teaches destination movement before ladder selection")
	check(model.interact_window(0), "T1 destination tap automatically climbs the installed vertical ladder")
	finish_jobs()
	check(model.region == 1 and model.floor_index == 1, "T1 arrival reaches the upper window floor")
	clean(0)
	check(model.phase == "clear", "T1 clears as soon as its only window is polished")

func test_t2_bridge() -> void:
	model = TutorialState.new()
	model.configure_tutorial(2)
	check(model.masks.size() == 1 and model.tower.is_horizontal_anchor(0), "T2 contains one window and one horizontal ladder destination")
	check(model.candidate_anchors() == [0], "T2 starts with exactly one legal bridge ghost")
	check(model.floor_index == 0 and model.tower.region_floor(0) == model.tower.region_floor(1), "T2 keeps the bridge on one floor")
	check(model.tower.gap_on_floor(0), "T2 marks its ground floor as a gap")
	model.walk_to(540)
	finish_jobs()
	check(model.hero.x <= WallLayout.GAP_LEFT and model.region == 0, "T2 movement stops at the gap until the ladder is placed")
	check(not model.interact_window(0), "T2 target is separated by an unbridged gap")
	place(0, 1)
	check(model.interact_window(0), "T2 destination tap automatically crosses the installed bridge")
	finish_jobs()
	check(model.region == 1 and model.floor_index == 0, "T2 reaches the target beyond the gap without changing floors")
	clean(0)
	check(model.phase == "clear", "T2 clears after the target window is polished")

func test_t3_reposition() -> void:
	model = TutorialState.new()
	model.configure_tutorial(3)
	check(model.masks.size() == 2 and model.candidate_anchors() == [0], "T3 starts with only its vertical destination unlocked")
	place(0, 1)
	check(model.interact_window(0), "T3 first window tap automatically climbs")
	finish_jobs()
	check(model.region == 1 and model.floor_index == 1, "T3 reaches its first upper window")
	clean(0)
	check(model.candidate_anchors() == [1], "polishing window 0 unlocks only the horizontal destination")
	check(model.request_place(1), "T3 selects a new destination to reposition its installed ladder")
	finish_jobs()
	check(model.ladder_anchor == 1 and model.moves == 2 and model.region == 1, "T3 moves the same ladder directly from vertical to horizontal")
	check(model.is_clean(0), "repositioning preserves completed cleaning work")
	check(model.undo(), "T3 can undo the reposition as one meaningful decision")
	check(model.ladder_anchor == 0 and model.moves == 1 and model.region == 1 and model.is_clean(0), "Undo restores the vertical route and keeps window 0 clean")
	place(1, 2)
	check(model.interact_window(1), "T3 second destination tap automatically crosses the new bridge")
	finish_jobs()
	check(model.region == 2 and model.floor_index == 1, "T3 reaches the second window across the same floor")
	clean(1)
	check(model.phase == "clear", "T3 clears after both windows are polished")
