extends SceneTree

var checks: int = 0
var failures: int = 0
var game: Node

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func settle() -> void:
	for _frame: int in 5:
		await process_frame

func drive(seconds: float) -> void:
	for _step: int in ceili(seconds / 0.05):
		game.call("_process", 0.05)

func force_clear() -> void:
	var model: TowerState = game.get("state") as TowerState
	for mask: DirtMask in model.masks:
		mask.cells.fill(0)
		mask.remaining = 0
	model.region = model.tower.completion_region()
	model.floor_index = model.tower.region_floor(model.region)
	model.hero.y = model.tower.floor_y(model.floor_index)
	model.walk_target = model.hero.x
	model.shutter_open = model.tower.shutter_window() >= 0
	model.gallery_open = model.tower.gallery_window() >= 0
	model._check_clear()

func check_ui(hud: GameHUD, context: String) -> void:
	var pending: Array[Node] = [hud]
	var leaves: Array[Control] = []
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		pending.append_array(node.get_children())
		var control: Control = node as Control
		if control == null or not control.is_visible_in_tree():
			continue
		var bounds: Rect2 = control.get_global_rect()
		check(bounds.has_area(), context + " nonzero control")
		check(Rect2(-1, -1, 722, 1282).encloses(bounds), context + " onscreen control")
		if control is Button:
			check(bounds.size.x >= 88 and bounds.size.y >= 88, context + " 44px mobile target")
		if control is Label or control is Button:
			for other: Control in leaves:
				check(not bounds.intersects(other.get_global_rect()), context + " no overlapping leaves")
			leaves.append(control)

func run() -> void:
	var settings_path: String = "user://settings.cfg"
	var had_settings: bool = FileAccess.file_exists(settings_path)
	var settings_bytes: PackedByteArray = FileAccess.get_file_as_bytes(settings_path) if had_settings else PackedByteArray()
	game = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	game.set_process(false)
	game.set_process_input(false)
	game.set_process_unhandled_input(false)
	root.add_child(game)
	current_scene = game
	await settle()
	(game.get_node("Sound") as SoundBank).set_muted(true)
	game.set("full_campaign_enabled", false)
	game.set("score_attack_enabled", false)
	game.call("_command", "start")
	var campaign: CampaignRun = game.get("campaign_run") as CampaignRun
	check(campaign.active and campaign.current_stage_id() == "tutorial_1", "Start begins authored campaign at T1")
	var model: TutorialState = game.get("state") as TutorialState
	check(model.ladder_anchor == 0 and model.interact_window(0), "T1 starts with a ladder and a reversible destination move")
	for _step: int in 100:
		model.tick(0.05)
	force_clear()
	check(campaign.flow_phase == "clean_pause", "clear starts a brief CLEAN pause")
	drive(0.7)
	check(campaign.flow_phase == "ascent", "CLEAN pause becomes upward ascent")
	game.call("_command", "pause")
	var frozen: Dictionary = campaign.snapshot()
	drive(1.0)
	check(campaign.snapshot() == frozen, "pause freezes the campaign ascent")
	game.call("_command", "resume")
	game.call("_command", "undo")
	check(campaign.flow_phase == "stage" and model.phase == "playing", "Undo cancels pending ascent and resumes exploration")
	check(model.ladder_anchor == 0 and model.region == 0 and model.is_clean(0), "Undo restores the initial route while retaining clean glass")
	force_clear()
	drive(2.2)
	check(campaign.current_stage_id() == "tutorial_2" and campaign.completed_records.size() == 1, "ascent advances once and records the cleared board")
	game.call("_command", "restart")
	check(campaign.current_stage_id() == "tutorial_2" and (game.get("state") as TutorialState).tutorial_step == 2, "Restart keeps the current campaign board")
	for id: String in ["tutorial_2", "tutorial_3", "tower"]:
		check(campaign.current_stage_id() == id, "MUST campaign reaches " + id)
		force_clear()
		drive(2.2)
	check(game.get("state") is EndingState and campaign.flow_phase == "ending", "MUST route ends after the twelve-window tower")
	var ending: EndingState = game.get("state") as EndingState
	check(ending.campaign_stats["completed_stages"] == 4 and ending.campaign_stats["total_windows"] == 16, "Ending receives all four MUST board records")
	check(not ending.final_ready and not ending.can_act(), "Ending has no puzzle actions during its short animation")
	drive(7.1)
	check(ending.final_ready and ending.animation_time == 7.0, "legendary ladder payoff exposes final controls after seven seconds")
	var hud: TowerHUD = game.get("hud") as TowerHUD
	for dimensions: Vector2i in [Vector2i(720, 1280), Vector2i(360, 800)]:
		root.size = dimensions
		for language: String in ["ja", "en"]:
			hud.language = language
			hud.rebuild()
			await settle()
			check_ui(hud, "ending " + language)
			check(hud.button_snapshot().has("Replay") and hud.button_snapshot().has("Title") and hud.button_snapshot().has("Credits"), "Ending shows replay, title and credits")
			game.call("_command", "credits")
			await settle()
			check_ui(hud, "credits " + language)
			game.call("_command", "back")
	game.call("_command", "replay")
	check(campaign.current_stage_id() == "tutorial_1" and campaign.completed_records.is_empty(), "Replay starts a fresh campaign")
	game.call("_command", "title")
	check(not campaign.active and (game.get("state") as StageState).phase == "title", "Title stops campaign progression")
	game.set("full_campaign_enabled", true)
	game.call("_command", "start")
	for id: String in CampaignRun.FULL_STAGE_IDS:
		check(campaign.current_stage_id() == id, "full campaign reaches " + id)
		force_clear()
		drive(2.2)
	check(game.get("state") is EndingState and campaign.completed_records.size() == 7, "preserved seven-board campaign reaches Ending")
	check((game.get("state") as EndingState).campaign_stats["total_windows"] == 32, "preserved campaign records every authored window")
	game.queue_free()
	await settle()
	if had_settings:
		var file: FileAccess = FileAccess.open(settings_path, FileAccess.WRITE)
		file.store_buffer(settings_bytes)
		file.close()
	elif FileAccess.file_exists(settings_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(settings_path))
	print("[CAMPAIGN TEST] %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
