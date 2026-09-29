extends SceneTree

var failures: int = 0
var checks: int = 0
var game: Node
var original_settings: ConfigFile = ConfigFile.new()
var had_settings: bool = false

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	had_settings = original_settings.load("user://settings.cfg") == OK
	var scene: PackedScene = load("res://scenes/main/main.tscn")
	game = scene.instantiate()
	root.size = Vector2i(720, 1280)
	root.add_child(game)
	current_scene = game
	await settle()
	var hud: GameHUD = game.get_node("UI/HUD") as GameHUD
	var sound: SoundBank = game.get_node("Sound") as SoundBank
	for dimensions: Vector2i in [Vector2i(720, 1280), Vector2i(360, 800)]:
		root.size = dimensions
		for language: String in ["ja", "en"]:
			hud.language = language
			hud.rebuild()
			game.call("_command", "title")
			game.call("_command", "credits")
			await settle()
			check_layout(hud, "%s credits %s" % [str(dimensions), language])
			game.call("_command", "back")
			await settle()
			check_layout(hud, "%s title %s" % [str(dimensions), language])
			game.call("_command", "start")
			await settle()
			check_layout(hud, "%s playing %s" % [str(dimensions), language])
			game.call("_command", "pause")
			await settle()
			check_layout(hud, "%s pause %s" % [str(dimensions), language])
			var paused_time: float = float(game.get("state").elapsed)
			await create_timer(0.1).timeout
			verify(float(game.get("state").elapsed) == paused_time, "pause stops gameplay time")
			game.call("_command", "sound")
			verify(sound.muted == hud.muted, "sound control updates audio playback")
			game.call("_command", "resume")
			verify(not bool(game.get("state").paused), "resume clears pause")
			game.call("_command", "plan")
			await settle()
			check_layout(hud, "%s logic map %s" % [str(dimensions), language])
			verify(bool(game.get("state").paused), "reading rules stops timer")
			game.call("_command", "resume")
			for wall: int in 3:
				var model: StageState = game.get("state") as StageState
				var journey: CastleRun = game.get("journey") as CastleRun
				model.phase = "clear"
				journey.finish_wall(model)
				hud.result_delay = 0
				hud.refresh()
				await settle()
				check_layout(hud, "%s result %d %s" % [str(dimensions), wall, language])
				if wall < 2:
					var gift_name: String = "GiftReach" if wall == 0 else "GiftRecall"
					var gift: Button = hud.find_child(gift_name, true, false) as Button
					verify(gift != null, "offered gift exists")
					gift.pressed.emit()
					await settle()
					verify(model.phase == "playing" and journey.wall_index == wall + 1, "gift callback advances exactly one wall")
					game.call("_command", "plan")
					await settle()
					check_layout(hud, "%s map wall %d %s" % [str(dimensions), wall + 1, language])
					game.call("_command", "retry_wall")
					verify(journey.wall_index == wall + 1 and journey.gifts.size() == wall + 1, "retry wall keeps run gifts and completed walls")
				else:
					journey.previous_record = journey.record()
					hud.refresh()
					await settle()
					check_layout(hud, "%s returning result %s" % [str(dimensions), language])
			sound.set_muted(true)
			hud.muted = true
			game.call("_command", "title")
	check_final_hook_input()
	# Allow the audio mixer to drain stopped voices before ending the headless process.
	sound.set_muted(true)
	await create_timer(0.2).timeout
	game.queue_free()
	await settle()
	if had_settings:
		original_settings.save("user://settings.cfg")
	else:
		DirAccess.remove_absolute("user://settings.cfg")
	print("[UI TEST] %d checks; %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

func settle() -> void:
	for frame: int in 5:
		await process_frame

func verify(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func check_final_hook_input() -> void:
	var model: StageState = game.get("state") as StageState
	for anchor: int in [6, 7]:
		model.configure(WallLayout.new(257, 2), [])
		model.masks[1].cells.fill(0)
		model.masks[1].remaining = 0
		model.floor_index = 2
		model.hero = Vector2(model.anchor_base(anchor).x, StageData.FLOORS[2])
		model.walk_target = model.hero.x
		var target: Vector2 = model.anchor_marker(anchor) + Vector2(0, -16)
		game.call("_pointer_down", target)
		verify(model.pending_anchor == anchor, "screen input selects isolated final hook %d" % anchor)
		model.tick(0.05)
		verify(model.ladder_anchor == anchor and model.moves == 1,
			"screen input places one ladder on final hook %d" % anchor)
		game.call("_pointer_up")

func check_layout(hud: GameHUD, label: String) -> void:
	var nodes: Array[Node] = [hud]
	var leaves: Array[Control] = []
	var inspected: int = 0
	while not nodes.is_empty():
		var current: Node = nodes.pop_back()
		for child: Node in current.get_children():
			nodes.append(child)
		var control: Control = current as Control
		if control == null or not control.is_visible_in_tree():
			continue
		inspected += 1
		var bounds: Rect2 = control.get_global_rect()
		verify(bounds.size.x > 0 and bounds.size.y > 0, label + " nonzero " + str(control.get_path()))
		verify(Rect2(-1, -1, 722, 1282).encloses(bounds), label + " onscreen " + str(control.get_path()))
		if control is Button:
			verify(bounds.size.x >= 88 and bounds.size.y >= 88, label + " 44px minimum mobile touch target")
		if control is Button or control is Label:
			for other: Control in leaves:
				if control.is_ancestor_of(other) or other.is_ancestor_of(control):
					continue
				verify(not bounds.intersects(other.get_global_rect()), label + " no overlapping text/buttons")
			leaves.append(control)
		if control is Label:
			var parent: Node = control.get_parent()
			while parent != null and not parent is Button:
				parent = parent.get_parent()
			if parent is Button:
				verify(parent.get_global_rect().encloses(bounds), label + " gift text fits its button")
	print("[UI TEST] %s: %d visible controls" % [label, inspected])
