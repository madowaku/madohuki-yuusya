class_name TowerHUD
extends GameHUD
## The board owns interaction. Progress, Undo, visibility and Menu remain on screen.
var undo_button: Button
var help_button: Button
var ending_bottom: MarginContainer
var campaign_flow: Dictionary = {}
var placement_counter: Label
var best_score_label: Label
var instructions_open: bool = false
var records_open: bool = false
var attack_score: Label

func set_campaign_flow(value: Dictionary) -> void:
	var should_refresh: bool = false
	for key: String in ["campaign_active", "stage_index", "stage_id", "stage_label", "flow_phase", "ending_stats"]:
		if campaign_flow.get(key) != value.get(key):
			should_refresh = true
	campaign_flow = value.duplicate(true)
	if should_refresh:
		refresh()

func rebuild() -> void:
	if state is EndingState:
		_rebuild_ending()
		return
	if not state is TowerState:
		super.rebuild()
		return
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	var illustrated_title: bool = ResourceLoader.exists(CastleView.TITLE_PATH)
	title_top = _margin(700, 778) if illustrated_title else _margin(16, 176)
	title_top.name = "TitleTop"
	var title_column: VBoxContainer = _column(title_top)
	title_column.add_theme_constant_override("separation", 2)
	title_column.add_child(_label("CLIMB · CLEAN · SCORE", 18, Color("aab6c5")))
	if not illustrated_title:
		title_column.add_child(_label(tr_pair("窓ふき勇者", "WINDOW HERO"), 56))
	best_score_label = _label("", 24, Color("dcc7a1"))
	title_column.add_child(best_score_label)
	title_bottom = _margin(-488, -12, true)
	title_bottom.add_theme_constant_override("margin_left", 116)
	title_bottom.add_theme_constant_override("margin_right", 116)
	title_bottom.name = "TitleBottom"
	var title_actions: VBoxContainer = _column(title_bottom)
	title_actions.add_theme_constant_override("separation", 8)
	var start_button: Button = _button(tr_pair("スタート", "START"), "start")
	start_button.add_theme_font_size_override("font_size", 40)
	start_button.add_theme_stylebox_override("normal", _warm_style())
	start_button.add_theme_color_override("font_color", Color("293d42"))
	title_actions.add_child(start_button)
	title_actions.add_child(_button(tr_pair("あそびかた", "HOW TO PLAY"), "instructions"))
	title_actions.add_child(_button(tr_pair("自己ベスト", "PERSONAL BEST"), "records"))
	title_actions.add_child(_button(tr_pair("クレジット", "Credits"), "credits"))
	var options: HBoxContainer = _row(title_actions)
	options.add_child(_button("日本語 / EN", "language", 248))
	options.add_child(_button("♪", "sound", 140))
	header = _margin(8, 100)
	header.name = "Header"
	var row: HBoxContainer = _row(header)
	chapter_label = _label("", 28, Color("d1d4df"))
	chapter_label.custom_minimum_size.x = 116
	chapter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	row.add_child(chapter_label)
	counter = _label("", 28, Color("eedbb9"))
	var progress_column: VBoxContainer = VBoxContainer.new()
	progress_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_column.alignment = BoxContainer.ALIGNMENT_CENTER
	progress_column.add_theme_constant_override("separation", 0)
	row.add_child(progress_column)
	progress_column.add_child(counter)
	placement_counter = _label("", 24, Color("aebecb"))
	progress_column.add_child(placement_counter)
	attack_score = _label("", 26, Color("eedbb9"))
	attack_score.custom_minimum_size.x = 142
	row.add_child(attack_score)
	undo_button = _icon("undo")
	undo_button.tooltip_text = tr_pair("一手もどる", "Undo one move")
	row.add_child(undo_button)
	help_button = _icon("help")
	help_button.tooltip_text = tr_pair("できる操作を見る", "Show available actions")
	help_button.toggle_mode = true
	row.add_child(help_button)
	var menu: Button = _icon("pause")
	menu.tooltip_text = tr_pair("メニュー", "Menu")
	row.add_child(menu)
	# Reuse the existing accessible settings/credits panel helpers.
	overlay = CenterContainer.new()
	overlay.name = "Overlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	debug_label = _label("", 16)
	debug_label.name = "Debug"
	debug_label.position = Vector2(20, 100)
	debug_label.size = Vector2(680, 120)
	debug_label.visible = false
	add_child(debug_label)
	refresh()

func _rebuild_ending() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	title_top = _margin(16, 176)
	title_bottom = _margin(-204, -16, true)
	header = _margin(8, 100)
	bottom = _margin(-176, -16, true)
	ending_bottom = _margin(-240, -8, true)
	ending_bottom.name = "EndingControls"
	var column: VBoxContainer = _column(ending_bottom)
	column.add_theme_constant_override("separation", 4)
	var summary: Label = _label(ending_summary(), 25, Color("253c49"))
	summary.name = "EndingSummary"
	var summary_style: StyleBoxFlat = StyleBoxFlat.new()
	summary_style.bg_color = Color(0.98, 0.91, 0.77, 0.92)
	summary_style.set_corner_radius_all(8)
	summary_style.content_margin_top = 4
	summary_style.content_margin_bottom = 4
	summary.add_theme_stylebox_override("normal", summary_style)
	column.add_child(summary)
	var row: HBoxContainer = _row(column)
	row.add_child(_button(tr_pair("リトライ", "RETRY") if bool((state as EndingState).campaign_stats.get("score_attack", false)) else tr_pair("もう一度", "Replay"), "replay", 196))
	row.add_child(_button(tr_pair("タイトル", "Title"), "title", 176))
	row.add_child(_button(tr_pair("クレジット", "Credits"), "credits", 196))
	overlay = CenterContainer.new()
	overlay.name = "Overlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	debug_label = _label("", 16)
	debug_label.name = "Debug"
	debug_label.position = Vector2(20, 100)
	debug_label.size = Vector2(680, 120)
	debug_label.visible = false
	add_child(debug_label)
	refresh()

func set_language(value: String) -> void:
	language = value
	if state is EndingState:
		rebuild()
	else:
		refresh()

func _icon(action: String) -> BoardIconButton:
	var button: BoardIconButton = BoardIconButton.new()
	button.glyph_key = "menu" if action == "pause" else action
	button.name = action.to_pascal_case()
	button.custom_minimum_size = Vector2(88, 88)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(func() -> void: command.emit(action))
	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = Color(0.08, 0.13, 0.23, 0.50)
	normal.set_corner_radius_all(8)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("disabled", normal)
	return button

func _process(delta: float) -> void:
	if state is EndingState:
		real_clock += delta
		if debug_label != null and debug_label.visible:
			debug_label.text = JSON.stringify(_flow_snapshot())
		return
	if not state is TowerState:
		super._process(delta)
		return
	real_clock += delta
	if state is ScoreAttackState:
		_refresh_attack_clock()
	if result_delay > 0:
		result_delay = maxf(0, result_delay - delta)
		if result_delay == 0:
			refresh()
	if debug_label != null and debug_label.visible:
		debug_label.text = JSON.stringify(state.snapshot())

func refresh() -> void:
	if state is EndingState:
		_refresh_ending()
		return
	if not state is TowerState:
		super.refresh()
		return
	if header == null:
		return
	var model: TowerState = state as TowerState
	var teaching: bool = model is TutorialState
	var attack: ScoreAttackState = model as ScoreAttackState
	best_score_label.text = tr_pair("自己ベスト %d pt", "PERSONAL BEST %d pt") % int(campaign_flow.get("best_score", 0))
	var in_campaign: bool = bool(campaign_flow.get("campaign_active", false))
	var show_overlay: bool = model.paused or (model.phase == "clear" and attack == null and not teaching and not in_campaign and result_delay <= 0) or credits_open or instructions_open or records_open
	title_top.visible = model.phase == "title" and not show_overlay
	title_bottom.visible = title_top.visible
	header.visible = model.phase != "title" and not show_overlay
	overlay.visible = show_overlay
	chapter_label.text = "T%d" % (model as TutorialState).tutorial_step if teaching else (str(campaign_flow.get("stage_label", "1F")) if in_campaign else "%dF" % (model.floor_index + 1))
	counter.text = "%d / %d" % [model.cleaned_count(), model.layout.window_count()]
	placement_counter.visible = not teaching
	placement_counter.text = tr_pair("%d回 · 最少%d", "Moves %d · min %d") % [model.moves, model.tower.placement_goal([])]
	placement_counter.add_theme_color_override("font_color", Color("e4bb89") if model.moves > model.tower.placement_goal([]) else Color("aebecb"))
	undo_button.disabled = model.history.is_empty() or model.paused
	undo_button.visible = attack == null
	attack_score.visible = attack != null
	help_button.visible = attack == null
	if attack != null:
		chapter_label.custom_minimum_size.x = 70
		chapter_label.add_theme_font_size_override("font_size", 36)
		counter.add_theme_font_size_override("font_size", 34)
		_refresh_attack_clock()
		placement_counter.visible = true
	help_button.set_pressed_no_signal(model.help_visible)
	help_button.disabled = model.paused or model.busy() or model.phase != "playing"
	if show_overlay:
		_build_overlay()

func _flow_snapshot() -> Dictionary:
	var result: Dictionary = campaign_flow.duplicate(true)
	if state != null:
		result["state"] = state.snapshot()
	result["language"] = language
	return result

func _refresh_ending() -> void:
	if header == null or ending_bottom == null:
		return
	var ending: EndingState = state as EndingState
	title_top.visible = false
	title_bottom.visible = false
	header.visible = false
	bottom.visible = false
	ending_bottom.visible = (ending.final_ready or bool(ending.campaign_stats.get("score_attack", false))) and not ending.paused and not credits_open
	overlay.visible = ending.paused or credits_open
	if overlay.visible:
		_build_overlay()

func _build_overlay() -> void:
	if instructions_open or records_open:
		_build_title_info()
		return
	if credits_open:
		super._build_overlay()
		return
	if state is EndingState:
		_build_ending_overlay()
		return
	if not state is TowerState:
		super._build_overlay()
		return
	for child: Node in overlay.get_children():
		overlay.remove_child(child)
		child.queue_free()
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size.x = 612
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("1e2b43")
	style.border_color = Color("8c8994")
	style.set_border_width_all(2)
	style.set_content_margin_all(28)
	panel.add_theme_stylebox_override("panel", style)
	overlay.add_child(panel)
	var column: VBoxContainer = _column(panel)
	column.add_theme_constant_override("separation", 16)
	var in_campaign: bool = bool(campaign_flow.get("campaign_active", false))
	if state.phase == "clear" and not in_campaign:
		column.add_child(_label(tr_pair("塔に、灯りがともった。", "THE TOWER IS ALIGHT."), 34))
		column.add_child(_label(tr_pair("12の窓 · ハシゴ設置 %d回\n最少設置 %d回", "12 windows · %d ladder placements\nMinimum: %d placements") % [state.moves, state.layout.placement_goal([])], 26))
		column.add_child(_button(tr_pair("塔をもう一度", "Try the tower again"), "restart"))
		column.add_child(_button(tr_pair("一手もどって考える", "Undo and explore"), "undo"))
	else:
		column.add_child(_label(tr_pair("ひとやすみ", "A LITTLE BREAK"), 36))
		column.add_child(_button(tr_pair("つづける", "Continue"), "resume"))
		column.add_child(_button(tr_pair("このステージをやり直す", "Retry this stage") if in_campaign else tr_pair("この塔をやり直す", "Retry this tower"), "restart"))
		var settings: HBoxContainer = _row(column)
		settings.add_child(_button("♪ " + ("OFF" if muted else "ON"), "sound", 166))
		settings.add_child(_button("日本語 / EN", "language", 200))
		column.add_child(_button(tr_pair("動きを控えめに：", "Reduced motion: ") + ("ON" if reduced_motion else "OFF"), "motion"))
		if not state is ScoreAttackState:
			column.add_child(_button(tr_pair("操作の合図：", "Idle cues: ") + ("ON" if (state as TowerState).hints_enabled else "OFF"), "hints"))
	if not in_campaign:
		if not state is ScoreAttackState:
			column.add_child(_button(tr_pair("以前の3城壁で遊ぶ", "Play the original three walls"), "start_classic"))
	column.add_child(_button(tr_pair("タイトルへ", "Title"), "title"))

func _build_title_info() -> void:
	for child: Node in overlay.get_children():
		overlay.remove_child(child)
		child.queue_free()
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size.x = 580
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("172735")
	style.border_color = Color("c49b62")
	style.set_border_width_all(3)
	style.set_corner_radius_all(16)
	style.set_content_margin_all(28)
	panel.add_theme_stylebox_override("panel", style)
	overlay.add_child(panel)
	var column: VBoxContainer = _column(panel)
	column.add_theme_constant_override("separation", 22)
	if instructions_open:
		column.add_child(_label(tr_pair("あそびかた", "HOW TO PLAY"), 34))
		column.add_child(_label(tr_pair("← → 横フリックで走る\n↑ ↓ 上下フリックでハシゴ\n窓をなぞって CLEAN！", "← → Flick sideways to run\n↑ ↓ Flick to climb / descend\nSwipe a window to CLEAN!"), 27))
		column.add_child(_label(tr_pair("行き先やハシゴのタップでも移動。\n最上階に着いたらクリア。", "Tap destinations or ladders to move.\nReach the top to finish."), 23))
		column.add_child(_label(tr_pair("窓 +400点 / 1秒 -50点\n敵との接触 -150点\n全16窓 CLEAN +1,500点", "Window +400 / second -50\nMonster contact -150\nAll 16 windows +1,500"), 24, Color("efd7a0")))
	else:
		column.add_child(_label(tr_pair("自己ベスト", "PERSONAL BEST"), 34))
		column.add_child(_label("%d pt" % int(campaign_flow.get("best_score", 0)), 48, Color("efd7a0")))
		column.add_child(_label(tr_pair("この端末に保存した最高得点。\n速さ × 窓ふき × 安全な経路。", "Best score saved on this device.\nSpeed, clean glass, a safer route."), 25))
	column.add_child(_button(tr_pair("もどる", "Back"), "back"))

func _build_ending_overlay() -> void:
	for child: Node in overlay.get_children():
		overlay.remove_child(child)
		child.queue_free()
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size.x = 560
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("1c343e")
	style.border_color = Color("94ac94")
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 28
	style.content_margin_bottom = 28
	panel.add_theme_stylebox_override("panel", style)
	overlay.add_child(panel)
	var column: VBoxContainer = _column(panel)
	column.add_theme_constant_override("separation", 16)
	if credits_open:
		column.add_child(_label(tr_pair("クレジット", "CREDITS"), 32))
		column.add_child(_label(tr_pair("企画・制作：madowaku\nAI制作支援：OpenAI Codex\nエンジン：Godot 4.7", "Game by madowaku\nAI assistance: OpenAI Codex\nEngine: Godot 4.7"), 22))
		column.add_child(_label("Art · OpenAI image generation\nKenney · Medieval / UI Adventure\nUI Audio / Particle Pack (CC0)\nM PLUS Rounded 1c · M+ FONTS\nSIL Open Font License 1.1", 19, Color("c6d4bd")))
		column.add_child(_button(tr_pair("もどる", "Back"), "back"))
	else:
		column.add_child(_label(tr_pair("ひとやすみ", "PAUSED"), 34))
		column.add_child(_button(tr_pair("つづける", "Continue"), "resume"))
		column.add_child(_button(tr_pair("もう一度", "Replay"), "replay"))
		column.add_child(_button(tr_pair("クレジット", "Credits"), "credits"))
		column.add_child(_button(tr_pair("タイトルへ", "Title"), "title"))

func ending_summary() -> String:
	var stats: Dictionary = (state as EndingState).campaign_stats if state is EndingState else {}
	if bool(stats.get("score_attack", false)):
		return "TIME  %.2f s    WINDOWS  %d / %d\nDAMAGE  %d    SCORE  %d\nBEST  %d" % [float(stats.get("seconds", 0)), int(stats.get("cleaned", 0)), int(stats.get("total_windows", 0)), int(stats.get("damage", 0)), int(stats.get("score", 0)), int(stats.get("best_score", 0))]
	var tower_windows: int = int(stats.get("tower_windows", 0))
	var tower_moves: int = int(stats.get("tower_placements", 0))
	var tower_minimum: int = int(stats.get("tower_minimum", 0))
	return tr_pair("塔 %d窓 · 設置 %d回 / 最少 %d回" % [tower_windows, tower_moves, tower_minimum], "Tower: %d windows · %d placements / min %d" % [tower_windows, tower_moves, tower_minimum])

func say(japanese: String, english: String, duration: float = 4) -> void:
	if not state is TowerState:
		super.say(japanese, english, duration)

func _refresh_attack_clock() -> void:
	if state is ScoreAttackState and state.phase == "playing" and not state.paused:
		var model: ScoreAttackState = state as ScoreAttackState
		chapter_label.text = "%dF" % (model.floor_index + 1)
		counter.text = "%02d:%05.2f" % [int(model.elapsed / 60), fmod(model.elapsed, 60)]
		placement_counter.text = "%d / %d CLEAN" % [model.cleaned_count(), model.masks.size()]
		attack_score.text = "SCORE\n%d" % model.final_score()
