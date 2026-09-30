extends SceneTree

var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func finish_jobs(model: TowerState) -> void:
	for step: int in 1600:
		model.tick(0.05)
		if not model.busy() and absf(model.hero.x - model.walk_target) < 1.0:
			return
	check(false, "UX command finishes within bounded time")

func settle() -> void:
	for frame: int in 5:
		await process_frame

func save_user_settings() -> Dictionary:
	var path: String = "user://settings.cfg"
	var result: Dictionary = {"exists": FileAccess.file_exists(path), "bytes": PackedByteArray()}
	if bool(result["exists"]):
		result["bytes"] = FileAccess.get_file_as_bytes(path)
	return result

func restore_user_settings(saved: Dictionary) -> void:
	var path: String = "user://settings.cfg"
	var absolute_path: String = ProjectSettings.globalize_path(path)
	if bool(saved["exists"]):
		var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
		if file != null:
			file.store_buffer(saved["bytes"] as PackedByteArray)
			file.close()
	else:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(absolute_path)

func run() -> void:
	var original_settings: Dictionary = save_user_settings()
	var game: Node = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	# The test manually advances the game's tutorial timer. Keep the engine from
	# also advancing it between assertions on a slower or differently loaded host.
	game.set_process(false)
	game.set_process_input(false)
	game.set_process_unhandled_input(false)
	root.add_child(game)
	current_scene = game
	await settle()
	(game.get_node("Sound") as SoundBank).set_muted(true)
	game.set("score_attack_enabled", false)
	game.call("_command", "start")
	var model: TutorialState = game.get("state") as TutorialState
	check(model != null and model.tutorial_step == 1, "Start begins silent tutorial T1")
	check(model.ladder_anchor == 0, "first ladder is visible and installed before any operation")
	game.call("_begin_tutorial", 3)
	model = game.get("state") as TutorialState
	model.placement_mode = false

	var target: Vector2 = model.tower.window_hit_rect(0).get_center()
	game.call("_pointer_down", target)
	game.call("_pointer_up")
	check(model.unreachable_window == 0 and model.unreachable_age == 0.0, "unreachable window tap creates timed feedback")
	check(model.unreachable_points.size() >= 2 and model.unreachable_gap.size() == 2, "unreachable feedback traces to the first missing ladder edge")
	check(model.unreachable_points.back() == model.unreachable_gap[0], "missing edge starts at the reachable trace endpoint")

	game.call("_pointer_down", model.hero)
	game.call("_pointer_up")
	check(not model.placement_mode, "hero body is not the ladder control")
	var carried: Rect2 = model.carried_ladder_hit_rect()
	check(carried.size.x >= 88.0 and carried.size.y >= 88.0, "carried ladder has an 88px-equivalent target")
	game.call("_pointer_down", carried.get_center())
	game.call("_pointer_up")
	check(model.placement_mode, "tapping the visible carried ladder opens placement")
	var ghost: Rect2 = model.ghost_hit_rect(0)
	check(ghost.size.x >= 88.0 and ghost.size.y >= 88.0 and ghost.has_point(model.tower.anchor_base(0)), "ghost hit target covers the full ladder shaft")
	game.call("_pointer_down", ghost.get_center())
	game.call("_pointer_up")
	finish_jobs(model)
	check(model.ladder_anchor == 0 and not model.placement_mode, "tapping the ghost installs the selected ladder")

	game.call("_pointer_down", model.tower.window_hit_rect(0).get_center())
	game.call("_pointer_up")
	finish_jobs(model)
	check(model.region == 1 and model.floor_index == 1, "destination window tap auto-climbs and approaches")
	check(model.reachable_regions().has(1) and model.reachable_windows().has(0), "reachability helpers expose destinations without puzzle advice")

	game.call("_begin_tutorial", 3)
	model = game.get("state") as TutorialState
	model.placement_mode = false
	game.call("_command", "help")
	check(model.help_visible and not model.placement_mode, "Help reveals route options without entering placement mode")
	check(model.snapshot()["reachable_regions"].has(0) and model.snapshot()["candidates"] == [0], "Help snapshot exposes reachable areas and legal ladder ghosts")
	game.call("_pointer_down", model.ghost_hit_rect(0).get_center())
	game.call("_pointer_up")
	check(not model.help_visible and model.busy(), "a ghost shown by Help remains directly selectable")
	var initial_hints: bool = bool(game.get("hints_enabled_preference"))
	game.call("_command", "hints")
	check(model.hints_enabled == not initial_hints, "Hints command toggles idle cues off or on")
	game.call("_command", "hints")
	check(model.hints_enabled == initial_hints, "Hints command restores the startup preference")
	game.call("_begin_tutorial", 1)
	model = game.get("state") as TutorialState
	model.masks[0].remaining = 0
	model._check_clear()
	check(float(game.get("tutorial_advance_timer")) > 0.0, "tutorial clear schedules a short advance")
	game.call("_command", "undo")
	check(float(game.get("tutorial_advance_timer")) == 0.0, "Undo cancels a pending tutorial advance")
	game.call("_begin_tutorial", 2)
	game.call("_command", "restart")
	check((game.get("state") as TutorialState).tutorial_step == 2, "retry keeps the current tutorial floor")
	game.call("_begin_tutorial", 1)
	for step: int in 3:
		var current_tutorial: TutorialState = game.get("state") as TutorialState
		check(current_tutorial.tutorial_step == step + 1, "tutorial sequence reaches T%d" % (step + 1))
		for window: int in current_tutorial.masks.size():
			current_tutorial.masks[window].remaining = 0
		current_tutorial._check_clear()
		game.call("_process", 0.81)
	var full_tower: TowerState = game.get("state") as TowerState
	check(not full_tower is TutorialState and full_tower.masks.size() == 12, "clearing T3 enters the original twelve-window tower")

	var overlap: TutorialState = TutorialState.new()
	overlap.configure_tutorial(3)
	overlap.region = 1
	overlap.floor_index = 1
	overlap.hero = Vector2(260.0, 760.0)
	overlap.walk_target = overlap.hero.x
	overlap.masks[0].remaining = 0
	var candidates: Array[int] = overlap.candidate_anchors()
	check(candidates == [0, 1], "T3 shared landing presents both available ghost ladders")
	check(overlap.ghost_hit_rect(0).intersects(overlap.ghost_hit_rect(1)), "test setup has overlapping expanded ghost targets")
	check(overlap.placement_candidate_at(Vector2(270.0, 760.0)) == 1, "overlapping ghosts resolve to the nearer ladder segment")
	var long_route: TowerState = TowerState.new()
	long_route.region = 0
	long_route.floor_index = 0
	long_route.hero = Vector2(313.0, long_route.tower.floor_y(0))
	long_route.walk_target = long_route.hero.x
	long_route.ladder_anchor = 0
	long_route.masks[3].remaining = 0
	check(not long_route.relocation_plan(4).is_empty(), "cleaning the bridge key makes the upper-floor bridge reachable through the installed ladder")
	check(long_route.candidate_anchors().has(4), "placement candidates include every legal route destination, even on another floor")
	check(not long_route.accessible(4) and long_route.reachable_windows().has(4), "a destination reachable through a ladder cannot be cleaned before arrival")
	long_route.region = 6
	check(long_route.reachable_windows().is_empty(), "the interior offers no exterior windows to clean")

	# Reproduce a real Web failure: the upper ghost crossed a polished window.
	var collision: TowerState = TowerState.new()
	collision.configure(AuthoredLayout.new("gallery_return"), [])
	collision.tower.windows[4] = Rect2(508, 428, 94, 112)
	for index: int in 5:
		collision.masks[index].cells.fill(0)
		collision.masks[index].remaining = 0
	collision.region = 4
	collision.floor_index = 2
	collision.hero = Vector2(555, 610)
	collision.walk_target = collision.hero.x
	collision.ladder_anchor = 3
	collision.moves = 4
	collision.gallery_open = true
	collision.placement_mode = true
	game.call("_switch_state", collision)
	var shared_point: Vector2 = (collision.anchor_base(4) + collision.anchor_top(4)) * 0.5
	check(collision.tower.window_hit_rect(4).has_point(shared_point), "regression fixture overlaps a ghost shaft and window")
	game.call("_pointer_down", shared_point)
	game.call("_pointer_up")
	finish_jobs(collision)
	check(collision.ladder_anchor == 4 and collision.moves == 5, "explicit placement mode gives the full ghost priority over nearby glass")

	var idle: TutorialState = TutorialState.new()
	idle.configure_tutorial(1)
	for step: int in 101:
		idle.tick(0.05)
	check(idle.nudge_age >= 0.0, "one quiet idle interval triggers a brief ladder nudge")
	for step: int in 26:
		idle.tick(0.05)
	check(idle.nudge_age < 0.0, "idle nudge expires after one pulse")
	for step: int in 101:
		idle.tick(0.05)
	check(idle.nudge_age < 0.0, "the same idle interval does not retrigger the nudge")
	idle.walk_to(idle.hero.x + 40.0)
	for step: int in 101:
		idle.tick(0.05)
	check(idle.nudge_age >= 0.0, "meaningful input starts a fresh idle interval")
	idle.set_hints_enabled(false)
	for step: int in 130:
		idle.tick(0.05)
	check(idle.nudge_age < 0.0, "disabling Hints suppresses idle nudges")

	game.set("hints_enabled_preference", initial_hints)
	var final_state: TowerState = game.get("state") as TowerState
	if final_state != null:
		final_state.set_hints_enabled(initial_hints)
	game.queue_free()
	await settle()
	restore_user_settings(original_settings)
	print("[UX CONTROLS TEST] %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
