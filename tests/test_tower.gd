extends SceneTree

var checks: int = 0
var failures: int = 0
var game: Node
var model: TowerState

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func finish_jobs() -> void:
	for step: int in 1000:
		model.tick(0.05)
		if not model.busy() and absf(model.hero.x - model.walk_target) < 1:
			return
	check(false, "command finishes within bounded time")

func clean(index: int) -> void:
	check(model.interact_window(index), "window %d can be approached" % index)
	finish_jobs()
	var area: Rect2 = model.window_rect(index)
	var last: Vector2 = area.position + Vector2(3, 5)
	for row: int in 4:
		var point: Vector2 = Vector2(area.end.x - 3 if row % 2 == 0 else area.position.x + 3, area.position.y + 5 + row * (area.size.y - 10) / 3)
		model.wipe(index, last, point)
		last = point
	check(model.is_clean(index), "ordinary zigzag completely cleans %d" % index)

func place(index: int) -> void:
	check(model.request_place(index), "legal smart placement %d" % index)
	finish_jobs()
	check(model.ladder_anchor == index, "one ladder arrives at selected hook %d" % index)

func cross() -> void:
	check(model.climb(), "ladder crosses")
	finish_jobs()

func run() -> void:
	var saved: ConfigFile = ConfigFile.new()
	var had_settings: bool = saved.load("user://settings.cfg") == OK
	game = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(game)
	current_scene = game
	for frame: int in 5:
		await process_frame
	game.set_process(false)
	var sound: SoundBank = game.get_node("Sound") as SoundBank
	sound.set_muted(true)
	game.call("_command", "start")
	model = game.get("state") as TowerState
	check(model != null and model.masks.size() == 12, "tower is the default twelve-window board")
	check(not model.request_place(0) and model.history.is_empty(), "invalid placement creates no undo entry")
	check(not model.interact_window(8) and not model.shutter_open, "outside cannot open inner shutter")
	check_hits()
	clean(0)
	clean(1)
	clean(2)
	place(0)
	cross()
	clean(3)
	clean(4)
	# A full smart transaction is reversible even halfway through retrieval.
	check(model.request_place(4), "horizontal reposition starts without manual retrieval")
	model.tick(0.05)
	model.set_paused(true)
	var paused_snapshot: Dictionary = model.snapshot()
	model.tick(2)
	check(model.snapshot() == paused_snapshot, "pause freezes transport transaction")
	model.set_paused(false)
	check(model.undo(), "undo cancels transport transaction")
	check(model.ladder_anchor == 0 and model.moves == 1 and model.region == 1, "undo restores original ladder and region atomically")
	check(model.is_clean(3) and model.is_clean(4), "undo retains cleaning work")
	place(4)
	cross()
	clean(5)
	check(model.candidate_anchors().has(2), "candidate UI includes destination across the current bridge")
	# Move back across the existing bridge, collect it, and climb on the left.
	place(2)
	check(model.region == 1 and model.moves == 3, "smart transport crosses old bridge before removing it")
	cross()
	clean(6)
	clean(7)
	check(model.interact_window(7), "polished entry admits hero")
	finish_jobs()
	check(model.inside() and model.ladder_anchor == 2, "entering leaves ladder outside")
	check(model.interact_window(8), "inner latch can be selected")
	finish_jobs()
	check(model.shutter_open and model.inside(), "latch opens from inside, stays inside")
	check(model.undo(), "undo inner shutter")
	check(not model.shutter_open and model.inside(), "undo closes latch at a safe interior position")
	model.interact_window(8)
	finish_jobs()
	model.interact_window(8)
	finish_jobs()
	check(model.region == 4 and model.ladder_anchor == 2, "exit matches exterior window, ladder remains on left")
	clean(8)
	check(model.gallery_open, "shutter light opens permanent lower gallery")
	check(model.undo(), "undo permanent route")
	check(not model.gallery_open and model.is_clean(8), "route undo preserves polished glass")
	model.interact_window(8)
	check(model.gallery_open, "one tap reactivates polished mechanism without re-cleaning")
	place(7)
	check(model.region == 4 and model.moves == 4, "transport uses inside route after collecting left ladder")
	cross()
	clean(9)
	clean(10)
	clean(11)
	check(model.phase == "clear" and model.moves == 4, "four-placement route clears all twelve windows")
	check(model.undo() and model.phase == "playing" and model.cleaned_count() == 12, "clear can be undone without losing polished windows")
	cross()
	check(model.phase == "clear", "returning to the crown clears again after Undo")
	game.get("hud").result_delay = 0
	game.get("hud").refresh()
	for dimensions: Vector2i in [Vector2i(720, 1280), Vector2i(360, 800)]:
		root.size = dimensions
		for language: String in ["ja", "en"]:
			var hud: TowerHUD = game.get("hud") as TowerHUD
			hud.language = language
			hud.rebuild()
			await settle()
			check_ui(hud, "result")
			game.call("_command", "title")
			await settle()
			check_ui(hud, "title")
			game.call("_command", "start")
			await settle()
			check_ui(hud, "play")
			check(hud.button_snapshot().size() == 2, "only Undo and Menu stay visible")
			game.call("_command", "pause")
			await settle()
			check_ui(hud, "menu")
			game.call("_command", "resume")
	# Real screen hit routing covers expanded targets, modal candidates and Undo.
	model = game.get("state") as TowerState
	clean(0)
	game.call("_pointer_down", model.hero + Vector2(0, 20))
	game.call("_pointer_up")
	check(model.placement_mode, "hero tap exposes legal hooks")
	var target: Vector2 = model.hook_hit_rect(0).position + Vector2(2, 2)
	game.call("_pointer_down", target)
	game.call("_pointer_up")
	finish_jobs()
	check(model.ladder_anchor == 0, "transparent 44px target selects hook")
	game.call("_command", "undo")
	check(model.ladder_anchor == -1 and model.is_clean(0), "HUD Undo returns carrying state without scrubbing again")
	game.call("_command", "start_classic")
	check(not game.get("state") is TowerState, "original validated puzzles remain playable")
	sound.set_muted(true)
	await create_timer(0.2).timeout
	game.queue_free()
	await settle()
	if had_settings:
		saved.save("user://settings.cfg")
	else:
		DirAccess.remove_absolute("user://settings.cfg")
	print("[TOWER TEST] %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)

func settle() -> void:
	for frame: int in 5:
		await process_frame

func check_ui(hud: GameHUD, label: String) -> void:
	var pending: Array[Node] = [hud]
	var leaves: Array[Control] = []
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		pending.append_array(node.get_children())
		var control: Control = node as Control
		if control == null or not control.is_visible_in_tree():
			continue
		var bounds: Rect2 = control.get_global_rect()
		check(bounds.has_area(), label + " nonzero control")
		check(Rect2(-1, -1, 722, 1282).encloses(bounds), label + " onscreen control")
		if control is Button:
			check(bounds.size.x >= 88 and bounds.size.y >= 88, label + " 44px mobile target")
		if control is Label or control is Button:
			for other: Control in leaves:
				check(not bounds.intersects(other.get_global_rect()), label + " no overlapping leaves")
			leaves.append(control)

func check_hits() -> void:
	var wall: TowerLayout = model.tower
	for index: int in 12:
		var hit: Rect2 = wall.window_hit_rect(index)
		check(hit.size.x >= 88 and hit.size.y >= 88, "window minimum touch target")
		check(Rect2(0, 104, 720, 1176).encloses(hit), "window target remains in board")
		for other: int in range(index + 1, 12):
			check(not hit.intersects(wall.window_hit_rect(other)), "window targets do not overlap")
	for at: int in 6:
		model.region = at
		model.floor_index = wall.region_floor(at)
		var hits: Array[Rect2] = []
		for index: int in wall.anchor_count():
			if not model.anchor_on_floor(index):
				continue
			var hit: Rect2 = model.hook_hit_rect(index)
			check(Rect2(0, 104, 720, 1176).encloses(hit), "hook target in board")
			for other: Rect2 in hits:
				check(not hit.intersects(other), "same-floor hook targets do not overlap")
			for other: int in 12:
				check(not hit.intersects(wall.window_hit_rect(other)), "hook never overlaps window target")
			hits.append(hit)
	model.region = 0
	model.floor_index = 0
