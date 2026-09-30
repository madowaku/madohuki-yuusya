extends SceneTree

var checks: int = 0
var failures: int = 0
var model: ScoreAttackState

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
		if not model.busy() and absf(model.hero.x - model.walk_target) < 1:
			return
	check(false, "fixed route command finishes")

func move_to(destination: int) -> void:
	var target_x: float = model.window_rect(destination).get_center().x if destination < model.masks.size() else 540.0
	check(model.move_to_region(destination, target_x), "neighbor %d can be selected" % destination)
	finish_jobs()
	check(model.region == destination, "hero reaches chosen neighbor %d" % destination)

func clean(index: int) -> void:
	check(model.interact_window(index), "window %d can be approached" % index)
	finish_jobs()
	var area: Rect2 = model.window_rect(index)
	var last: Vector2 = area.position + Vector2(3, 5)
	for row: int in 6:
		var point: Vector2 = Vector2(area.end.x - 3 if row % 2 == 0 else area.position.x + 3, area.position.y + 5 + row * (area.size.y - 10) / 5)
		model.wipe(index, last, point)
		last = point
	check(model.is_clean(index), "window %d cleans without tiny residue" % index)
	for _step: int in 30:
		model.tick(0.05)

func run() -> void:
	model = ScoreAttackState.new()
	check(model.masks.size() == 16 and model.tower.floor_count() == 10, "one continuous tower has sixteen distinct ledges/windows")
	check(model.tower.anchor_count() == 18 and model.candidate_anchors().is_empty(), "all eighteen ladders are already fixed")
	model.select_ladder()
	check(not model.placement_mode and not model.request_place(0) and not model.retrieve(), "no placement or retrieval operation remains")
	check(not model.interact_window(15) and not model.move_to_region(16), "far-away destinations do not auto-solve the maze")
	var reached: Array[int] = [0]
	for _pass: int in model.tower.region_count():
		for at: int in reached.duplicate():
			for neighbor: int in model._links(at, -1):
				if not reached.has(neighbor):
					reached.append(neighbor)
	check(reached.size() == model.tower.region_count(), "every scoring branch and boss is connected")
	model.tick(61)
	check(model.phase == "playing" and model.elapsed > 60, "count-up attack never expires")
	model.set_paused(true)
	var elapsed: float = model.elapsed
	model.tick(10)
	check(model.elapsed == elapsed, "pause freezes elapsed time")
	model.set_paused(false)
	model = ScoreAttackState.new()
	for destination: int in [1, 3, 4, 6, 8, 7, 9, 11, 12, 14, 15]:
		move_to(destination)
	check(model.score == 0, "climbing alone awards no window points")
	move_to(16)
	check(model.phase == "clear" and model.finish_reason == "summit" and model.cleaned_count() == 0, "arrival at the boss summit ends the run with optional panes dirty")
	check(model.score == 0 and model.final_score() < 10000, "rush score reflects elapsed time and contacts")
	var rush_score: int = model.final_score()
	model = ScoreAttackState.new()
	clean(0)
	for destination: int in [2, 0, 1, 3, 5, 6, 4, 6, 8, 10, 9, 7, 9, 11, 13, 11, 12, 14, 15]:
		move_to(destination)
		if not model.is_clean(destination):
			clean(destination)
	check(model.cleaned_count() == 16 and model.score == 6400, "each unique window scores four hundred points once")
	move_to(16)
	check(model.moves == 0 and model.history.is_empty(), "a complete run makes zero placements or retrieval transactions")
	check(model.final_score() > rush_score, "productive detours beat a boss-only rush despite taking longer")
	check(model.camera_y < -1900, "the camera follows a continuous tall tower to its summit")
	var stats: Dictionary = model.run_stats()
	check(stats["score"] == maxi(0, roundi(10000 + model.score + 1500 - model.elapsed * 50 - model.damage * 150)), "score uses window points, time, contact penalty and all-clean bonus")
	var final_elapsed: float = model.elapsed
	model.tick(60)
	check(model.elapsed == final_elapsed, "score and time freeze at the finish")
	model = ScoreAttackState.new()
	var first_patrol: Dictionary = model.patrols()[0]
	model.hero = (first_patrol["point"] as Vector2) + Vector2(0, 38)
	model.walk_target = model.hero.x
	model.tick(0.01)
	check(model.damage == 1 and model.invulnerable > 0, "contact applies one three-second-equivalent penalty")
	model.tick(0.01)
	check(model.damage == 1, "invulnerability prevents repeated contacts each frame")
	var patrol_before: Array[Dictionary] = model.patrols()
	model.set_paused(true)
	model.tick(10)
	check(model.patrols() == patrol_before, "pause freezes deterministic monster routes")
	# Real controller gesture dispatch, including a downward flick.
	var game: Node = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	game.set_process(false)
	root.add_child(game)
	await process_frame
	(game.get_node("Sound") as SoundBank).set_muted(true)
	game.call("_command", "start")
	model = game.get("state") as ScoreAttackState
	check(model != null, "normal Start enters the fixed-ladder mode")
	game.call("_pointer_down", Vector2(355, 1130))
	game.call("_pointer_move", Vector2(480, 1130))
	game.call("_pointer_up")
	var start_x: float = model.hero.x
	for _frame: int in 12:
		model.tick(0.016)
	check(model.hero.x > start_x + 40, "horizontal flick moves the hero smoothly")
	finish_jobs()
	game.call("_pointer_down", Vector2(355, 1120))
	game.call("_pointer_move", Vector2(355, 1000))
	game.call("_pointer_up")
	finish_jobs()
	check(model.floor_index == 1 and model.moves == 0, "upward flick climbs a nearby fixed ladder")
	game.call("_pointer_down", Vector2(355, 1120))
	game.call("_pointer_move", Vector2(355, 1240))
	game.call("_pointer_up")
	finish_jobs()
	check(model.floor_index == 0, "downward flick descends without a ladder selection mode")
	game.queue_free()
	await process_frame
	print("[SCORE ATTACK TEST] %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
