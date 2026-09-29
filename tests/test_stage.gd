extends SceneTree

var failures: int = 0
var assertions: int = 0

func _initialize() -> void:
	var model: StageState = StageState.new()
	check(model.cleaned_count() == 0 and model.ladder_anchor == -1, "fresh run carries the single ladder; all five windows dirty")
	check(not model.request_place(0), "upper hooks cannot be used before cleaning mechanism A")
	check(not model.request_place(-1) and not model.request_place(6), "invalid anchors rejected without changing state")
	check(model.wipe(2, Vector2(190, 620), Vector2(300, 760)) == 0, "upper windows cannot be cleaned remotely")
	check(model.wipe(0, Vector2(200, 900), Vector2(200, 900)) == 0, "stationary hold does not erase grime")
	model.set_paused(true)
	model.tick(5)
	check(model.elapsed == 0.0 and not model.request_place(0), "pause freezes time and interactions")
	model.set_paused(false)
	clean_window(model, 0)
	check(model.is_clean(0) and model.anchor_unlocked(0) and model.anchor_unlocked(1), "cleaning A opens both lower hooks")
	check(not model.anchor_unlocked(2), "upper landing remains locked until resident C")
	clean_window(model, 1)
	check(model.request_place(1), "ground placement accepted")
	advance(model, 2.0)
	check(model.ladder_anchor == 1 and model.moves == 1, "walking to preview places exactly one ladder")
	check(model.climb(), "climb starts at the foot of a placed ladder")
	model.tick(1.5)
	check(model.climbing and model.floor_index == 0, "climb remains in progress at halfway")
	check(not model.retrieve() and not model.request_place(0), "cannot mutate ladder while climbing")
	model.tick(1.5)
	check(model.floor_index == 1 and not model.climbing, "climbing one ladder takes three seconds")
	check(model.retrieve(), "ladder can be retrieved from its top endpoint")
	clean_window(model, 3)
	check(model.anchor_unlocked(2), "resident C opens the final ledge")
	clean_window(model, 2)
	check(model.request_place(2), "upper placement accepted after helping the resident")
	advance(model, 2.0)
	check(model.climb(), "final climb accepted")
	advance(model, 3.1)
	clean_window(model, 4)
	check(model.phase == "clear" and model.cleaned_count() == 5, "five windows produce a completed stage")
	check(model.moves == 2 and model.elapsed < 180, "ideal route finishes within three minutes using two placements")
	var finish_time: float = model.elapsed
	model.tick(8)
	check(model.elapsed == finish_time, "result clock does not continue counting")
	model.reset()
	check(model.phase == "playing" and model.cleaned_count() == 0 and model.moves == 0 and model.elapsed == 0, "restart fully resets progression and metrics")
	# Backtracking is essential: even a player who skips the greenhouse must be able to return.
	clean_window(model, 0)
	model.request_place(0)
	advance(model, 2)
	model.climb()
	advance(model, 3.1)
	model.retrieve()
	clean_window(model, 3)
	model.request_place(3)
	advance(model, 2)
	model.climb()
	advance(model, 3.1)
	clean_window(model, 4)
	check(model.phase == "playing", "cleaning the top window early does not incorrectly finish the level")
	model.walk_to(StageData.anchor_base(3).x)
	advance(model, 2)
	model.climb()
	advance(model, 3.1)
	model.retrieve()
	clean_window(model, 2)
	model.request_place(0)
	advance(model, 2)
	check(model.climb(), "can place a ladder from the upper end and descend to missed windows")
	advance(model, 3.1)
	clean_window(model, 1)
	check(model.phase == "clear", "backtracked route can still finish")
	print("[TEST] %d assertions; %d failures" % [assertions, failures])
	quit(1 if failures > 0 else 0)

func check(condition: bool, description: String) -> void:
	assertions += 1
	if not condition:
		failures += 1
		push_error("[TEST] " + description)
	else:
		print("[PASS] " + description)

func advance(model: StageState, seconds: float) -> void:
	for frame: int in int(ceil(seconds * 60)):
		model.tick(1.0 / 60.0)

func clean_window(model: StageState, index: int) -> void:
	var area: Rect2 = StageData.window_rect(index)
	model.walk_to(area.get_center().x)
	advance(model, 2)
	var previous: Vector2 = area.position + Vector2(4, 8)
	for row: int in 5:
		var y: float = area.position.y + 8 + row * 36
		var target: Vector2 = Vector2(area.end.x - 4 if row % 2 == 0 else area.position.x + 4, y)
		model.wipe(index, previous, target)
		model.tick(0.5)
		previous = target
	check(model.is_clean(index), "window %s completes with broad swipes and no pixel hunt" % StageData.WINDOWS[index]["id"])
