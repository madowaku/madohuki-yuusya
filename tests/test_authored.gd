extends SceneTree

var checks: int = 0
var failures: int = 0
var model: TowerState
var clear_events: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func finish_jobs() -> void:
	for _step: int in 2000:
		model.tick(0.05)
		if not model.busy() and absf(model.hero.x - model.walk_target) < 1.0:
			return
	check(false, "authored command finishes within bounded time")

func clean(index: int) -> void:
	check(model.interact_window(index), "authored window %d can be approached" % index)
	finish_jobs()
	var area: Rect2 = model.window_rect(index)
	var last: Vector2 = area.position + Vector2(3, 5)
	var rows: int = maxi(4, ceili(area.size.y / 40.0))
	for row: int in rows:
		var point: Vector2 = Vector2(area.end.x - 3 if row % 2 == 0 else area.position.x + 3, area.position.y + 5 + row * (area.size.y - 10) / (rows - 1))
		model.wipe(index, last, point)
		last = point
	check(model.is_clean(index), "authored window %d cleans completely" % index)

func place(index: int, expected_moves: int) -> void:
	check(model.request_place(index), "authored smart placement %d is legal" % index)
	finish_jobs()
	check(model.ladder_anchor == index, "authored ladder reaches anchor %d" % index)
	check(model.moves == expected_moves, "authored placement count reaches %d" % expected_moves)

func cross() -> void:
	check(model.climb(), "authored ladder crosses")
	finish_jobs()

func make_model(stage_id: String) -> TowerState:
	var result: TowerState = TowerState.new()
	result.configure(AuthoredLayout.new(stage_id), [])
	return result

func on_event(event_name: String, _value: int) -> void:
	if event_name == "stage_cleared":
		clear_events += 1

func run() -> void:
	test_switchback()
	test_gallery_return()
	test_heart_window()
	print("[AUTHORED TEST] %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)

func test_switchback() -> void:
	model = make_model("switchback")
	clear_events = 0
	model.event_occurred.connect(on_event)
	var board: AuthoredLayout = model.tower as AuthoredLayout
	check(board.stage_id() == "switchback" and board.title("en") == "UP, ACROSS, UP", "switchback title and stable ID load from authored data")
	check(model.masks.size() == 4 and board.anchor_count() == 4, "switchback is a compact four-window board with an optional route")
	check(board.entry_window() == -1 and board.shutter_window() == -1 and board.gallery_window() == -1, "switchback has no room or gallery roles")
	check(model.candidate_anchors().is_empty(), "switchback keeps both ladder routes locked behind its first window")
	clean(0)
	check(model.candidate_anchors().has(0) and model.candidate_anchors().has(3), "first window reveals left and right vertical starts")
	place(0, 1)
	clean(1)
	check(model.candidate_anchors().has(1) and model.candidate_anchors().has(3), "left window reveals the bridge while preserving the optional right climb")
	place(1, 2)
	clean(2)
	check(model.candidate_anchors().has(2) and model.candidate_anchors().has(3), "far-side window reveals the upper vertical route")
	place(2, 3)
	cross()
	clean(3)
	check(model.phase == "clear" and model.region == board.completion_region(), "switchback clears on the upper landing")
	check(clear_events == 1, "switchback emits one stage clear event")

func test_gallery_return() -> void:
	model = make_model("gallery_return")
	clear_events = 0
	model.event_occurred.connect(on_event)
	var board: AuthoredLayout = model.tower as AuthoredLayout
	check(model.masks.size() == 6 and board.gallery_window() == 2, "gallery board loads six windows and its permanent route key")
	check(board.gallery_regions() == [1, 2] and board.retired_bridge() == 1, "gallery metadata connects and retires the lower bridge")
	clean(0)
	place(0, 1)
	clean(1)
	place(1, 2)
	clean(2)
	check(model.gallery_open, "polishing the key opens the return route")
	check(model.reachable_regions().has(1), "gallery makes the opposite balcony reachable")
	place(2, 3)
	clean(3)
	check(model.candidate_anchors().has(3), "the next balcony window unlocks the opposite vertical route")
	place(3, 4)
	clean(4)
	place(4, 5)
	cross()
	clean(5)
	check(model.phase == "clear" and model.region == board.completion_region(), "gallery route board clears on its crown")
	check(clear_events == 1, "gallery route emits one stage clear event")

func test_heart_window() -> void:
	model = make_model("heart_window")
	clear_events = 0
	model.event_occurred.connect(on_event)
	var board: AuthoredLayout = model.tower as AuthoredLayout
	check(model.masks.size() == 6 and board.title("ja") == "最後の窓", "heart board loads localized title and six windows")
	check(board.entry_window() == 3 and board.shutter_window() == 4 and board.interior_region() == 6, "heart board exposes its entry and inner shutter")
	check(board.room_rect().has_point(board.window_rect(3).get_center()) and board.room_rect().has_point(board.window_rect(4).get_center()), "heart cutaway encloses both exterior portals in their original coordinates")
	check(board.window_requires_all_other(5) and board.window_kind(5) == "heart", "oversized heart is gated behind every other window")
	clean(0)
	place(0, 1)
	clean(1)
	place(1, 2)
	clean(2)
	place(2, 3)
	clean(3)
	check(model.ladder_anchor == 2, "ladder stays installed while the hero enters")
	check(model.interact_window(3), "clean entry can be entered")
	finish_jobs()
	check(model.inside() and model.ladder_anchor == 2, "inside route retains the ladder on the exterior")
	check(model.interact_window(4), "inner latch opens from inside")
	finish_jobs()
	check(model.shutter_open and model.inside(), "shutter opens without leaving the room")
	check(model.interact_window(4), "opened shutter is an exit route")
	finish_jobs()
	check(model.region == 4 and model.ladder_anchor == 2, "shutter exit leaves the old ladder in place")
	clean(4)
	check(not model.is_clean(5), "heart remains dark while any other window is unfinished")
	check(model.request_place(3), "open interior route lets the same ladder move to the heart")
	finish_jobs()
	check(model.ladder_anchor == 3 and model.region == 4 and model.moves == 4, "smart reposition retrieves through the open room route")
	check(model.undo(), "heart ladder reposition can be undone")
	check(model.ladder_anchor == 2 and model.region == 4 and model.is_clean(4), "Undo restores the old route but keeps polished glass")
	place(3, 4)
	cross()
	check(model.window_unlocked(5), "heart unlocks after all five other windows are clean")
	clean(5)
	check(model.phase == "clear" and model.region == board.completion_region(), "heart board clears at the crown")
	check(model.shutter_open and clear_events == 1, "heart clear retains its opened shutter and emits once")
