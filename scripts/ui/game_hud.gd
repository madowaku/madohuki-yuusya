class_name GameHUD
extends Control

signal command(action: String)
signal direction_changed(direction: float)

var journey: CastleRun
var chapter_label: Label
var loadout: Label
var state: StageState
var language: String = "ja"
var muted: bool = false
var reduced_motion: bool = false
var title_top: MarginContainer
var title_bottom: MarginContainer
var header: MarginContainer
var bottom: MarginContainer
var overlay: CenterContainer
var counter: Label
var timer_label: Label
var hint: Label
var climb_button: Button
var retrieve_button: Button
var message_until: float = 0.0
var message_text: String = ""
var real_clock: float = 0.0
var best_moves: int = 0
var credits_open: bool = false
var planning_open: bool = false
var debug_label: Label
var result_delay: float = 0.0

func bind(model: StageState, run_model: CastleRun) -> void:
	journey = run_model
	state = model
	state.changed.connect(refresh)
	rebuild()

func tr_pair(japanese: String, english: String) -> String:
	return japanese if language == "ja" else english

func _process(delta: float) -> void:
	real_clock += delta
	if state == null:
		return
	if result_delay > 0.0:
		result_delay = maxf(0.0, result_delay - delta)
		if result_delay == 0.0:
			refresh()
	if state.phase == "playing" and not state.paused:
		var seconds: int = int(state.elapsed)
		timer_label.text = "%02d:%02d" % [int(seconds / 60.0), seconds % 60]
		if real_clock >= message_until:
			hint.text = _next_hint()
	if debug_label != null and debug_label.visible:
		debug_label.text = JSON.stringify(state.snapshot())

func _label(text_value: String, font_size: int = 24, color: Color = Color("f6edce")) -> Label:
	var label: Label = Label.new()
	label.text = text_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _button(text_value: String, action: String, width: float = 0) -> Button:
	var button: Button = Button.new()
	button.text = text_value
	button.name = action.to_pascal_case()
	button.custom_minimum_size = Vector2(maxf(width, 88), 88)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(func() -> void: command.emit(action))
	return button

func _margin(top: float, bottom_value: float, from_bottom: bool = false) -> MarginContainer:
	var margin: MarginContainer = MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE if from_bottom else Control.PRESET_TOP_WIDE)
	margin.offset_top = top
	margin.offset_bottom = bottom_value
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	add_child(margin)
	return margin

func _column(parent: Node) -> VBoxContainer:
	var column: VBoxContainer = VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(column)
	return column

func _row(parent: Node) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(row)
	return row

func rebuild() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	title_top = _margin(20, 178)
	title_top.name = "TitleTop"
	var title_column: VBoxContainer = _column(title_top)
	title_column.add_theme_constant_override("separation", 2)
	title_column.add_child(_label("A LITTLE CASTLE. A LITTLE KINDNESS.", 17, Color("c0d4bf")))
	title_column.add_child(_label(tr_pair("窓ふき勇者", "WINDOW HERO"), 60, Color("fff0c6")))
	title_column.add_child(_label(tr_pair("剣をおいて、ハシゴを持とう。", "Leave your sword. Bring a ladder."), 23, Color("e0d7ba")))
	title_bottom = _margin(-204, -16, true)
	title_bottom.name = "TitleBottom"
	var title_actions: VBoxContainer = _column(title_bottom)
	var start_button: Button = _button(tr_pair("3つの城壁を、ぴかぴかに。 →", "Three walls. One little adventure. →"), "start")
	start_button.add_theme_font_size_override("font_size", 27)
	start_button.add_theme_stylebox_override("normal", _warm_style())
	start_button.add_theme_color_override("font_color", Color("293d42"))
	title_actions.add_child(start_button)
	var options: HBoxContainer = _row(title_actions)
	options.add_child(_button("日本語 / EN", "language", 204))
	options.add_child(_button(tr_pair("クレジット", "Credits"), "credits", 204))
	options.add_child(_button("♪ " + tr_pair("音", "Sound"), "sound", 140))
	header = _margin(16, 180)
	header.name = "Header"
	var header_column: VBoxContainer = _column(header)
	var header_row: HBoxContainer = _row(header_column)
	chapter_label = _label("", 22)
	chapter_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chapter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	header_row.add_child(chapter_label)
	timer_label = _label("00:00", 24, Color("c8d8c0"))
	timer_label.custom_minimum_size.x = 80
	header_row.add_child(timer_label)
	var plan_button: Button = _button(tr_pair("仕掛け", "Map"), "plan", 88)
	plan_button.add_theme_font_size_override("font_size", 20)
	header_row.add_child(plan_button)
	var pause_button: Button = _button("Ⅱ", "pause", 68)
	header_row.add_child(pause_button)
	counter = _label("", 24, Color("e2d9b8"))
	header_column.add_child(counter)
	loadout = _label("", 18, Color("b9e9be"))
	header_column.add_child(loadout)
	bottom = _margin(-176, -16, true)
	bottom.name = "Bottom"
	var bottom_column: VBoxContainer = _column(bottom)
	hint = _label("", 23, Color("e9e5c9"))
	hint.custom_minimum_size.y = 50
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bottom_column.add_child(hint)
	var controls: HBoxContainer = _row(bottom_column)
	for direction: int in [-1, 1]:
		var arrow: Button = _button("‹" if direction == -1 else "›", "left" if direction == -1 else "right", 76)
		arrow.add_theme_font_size_override("font_size", 36)
		arrow.button_down.connect(func() -> void: direction_changed.emit(float(direction)))
		arrow.button_up.connect(func() -> void: direction_changed.emit(0.0))
		controls.add_child(arrow)
	climb_button = _button("", "action", 242)
	climb_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls.add_child(climb_button)
	retrieve_button = _button(tr_pair("回収", "Pick up"), "retrieve", 146)
	controls.add_child(retrieve_button)
	overlay = CenterContainer.new()
	overlay.name = "Overlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	debug_label = _label("", 16)
	debug_label.name = "Debug"
	debug_label.position = Vector2(20, 184)
	debug_label.size = Vector2(680, 130)
	debug_label.visible = false
	add_child(debug_label)
	refresh()

func _warm_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("edd4a1")
	style.border_color = Color("ae8b63")
	style.border_width_bottom = 5
	style.set_corner_radius_all(12)
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	return style

func refresh() -> void:
	if state == null or header == null:
		return
	var show_overlay: bool = state.paused or (state.phase == "clear" and result_delay <= 0.0) or credits_open
	title_top.visible = state.phase == "title" and not show_overlay
	title_bottom.visible = title_top.visible
	header.visible = state.phase == "playing" and not show_overlay
	bottom.visible = header.visible
	overlay.visible = show_overlay
	var compact_tower: bool = state.layout.chapter == 2
	if compact_tower:
		var short_gifts: PackedStringArray = []
		for gift: String in journey.gifts:
			var short_name: String = "長柄" if gift == "reach" else ("回収" if gift == "recall" else "泡")
			if language == "en":
				short_name = "REACH" if gift == "reach" else ("HOOK" if gift == "recall" else "SOAP")
			short_gifts.append(short_name)
		var tools_label: String = " + ".join(short_gifts)
		var tower_status: String = "塔 %d/3 · 窓 %d/%d · 設置 %d/%d" % [journey.wall_index + 1, state.cleaned_count(), state.masks.size(), state.moves, state.layout.placement_goal(state.gifts)] if language == "ja" else "%d/3 TOWER · W%d/%d · M%d/%d" % [journey.wall_index + 1, state.cleaned_count(), state.masks.size(), state.moves, state.layout.placement_goal(state.gifts)]
		chapter_label.text = tower_status + (" · " + tools_label if not tools_label.is_empty() else "")
		chapter_label.add_theme_font_size_override("font_size", 17)
	else:
		chapter_label.text = "%d / 3  %s" % [journey.wall_index + 1, state.layout.title(language)]
		chapter_label.add_theme_font_size_override("font_size", 22)
	var tools: PackedStringArray = []
	for gift: String in journey.gifts:
		var title: String = CastleRun.gift_name(gift, language)
		if gift == "reach":
			title += " 0/1" if state.reach_spent else " 1/1"
		tools.append(title)
	loadout.text = " + ".join(tools) if not tools.is_empty() else tr_pair("住人のお礼で、次の順路が変わる。", "A resident’s gift can change your next route.")
	counter.visible = not compact_tower
	loadout.visible = not compact_tower
	counter.text = tr_pair("窓 %d / %d  ·  設置 %d 回  /  目標 %d 回", "WINDOWS %d / %d · MOVES %d / TARGET %d") % [state.cleaned_count(), state.masks.size(), state.moves, state.layout.placement_goal(state.gifts)]
	if real_clock >= message_until:
		hint.text = _next_hint()
	climb_button.disabled = state.climbing
	retrieve_button.disabled = state.climbing or state.ladder_anchor < 0
	if state.climbing:
		climb_button.text = tr_pair("そろり、そろり…", "Steady now…") if state.layout.is_horizontal_anchor(state.ladder_anchor) else tr_pair("よいしょ…", "Up we go…")
	elif state.ladder_anchor == -1:
		climb_button.text = tr_pair("ハシゴを掛ける", "Place ladder")
	elif state.layout.is_horizontal_anchor(state.ladder_anchor):
		climb_button.text = tr_pair("↔ わたる", "↔ Cross")
	elif int(StageData.ANCHORS[state.ladder_anchor]["floor"]) == state.floor_index:
		climb_button.text = tr_pair("↑ のぼる", "↑ Climb")
	else:
		climb_button.text = tr_pair("↓ おりる", "↓ Descend")
	if show_overlay:
		_build_overlay()

func _build_overlay() -> void:
	for child: Node in overlay.get_children():
		overlay.remove_child(child)
		child.queue_free()
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size.x = 612
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("1c343e")
	style.border_color = Color("94ac94")
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	style.content_margin_left = 32
	style.content_margin_right = 32
	style.content_margin_top = 32
	style.content_margin_bottom = 32
	style.shadow_color = Color(0.05, 0.12, 0.16, 0.65)
	style.shadow_size = 35
	panel.add_theme_stylebox_override("panel", style)
	overlay.add_child(panel)
	var column: VBoxContainer = _column(panel)
	column.add_theme_constant_override("separation", 18)
	if credits_open:
		column.add_child(_label(tr_pair("つくったひと・素材", "CREDITS"), 34))
		column.add_child(_label(tr_pair("企画・制作：madowaku\nAI制作支援：OpenAI Codex\nエンジン：Godot 4.7", "Game by madowaku\nAI assistance: OpenAI Codex\nEngine: Godot 4.7"), 24))
		column.add_child(_label("Art · OpenAI image generation\nKenney · Medieval / UI Adventure\nUI Audio / Particle Pack (CC0)\nM PLUS Rounded 1c · M+ FONTS\nSIL Open Font License 1.1", 21, Color("c6d4bd")))
		column.add_child(_label(tr_pair("キャラクター生成・音楽・清掃音は\nこのゲームのために制作。", "Generated characters, music and cleaning sounds\ncreated for this game."), 21))
		column.add_child(_button(tr_pair("もどる", "Back"), "back"))
	elif planning_open:
		RoutePanel.build(column, state, language, func(action: String) -> void: command.emit(action))
	elif state.phase == "clear":
		JourneyPanel.build(column, journey, language, func(action: String) -> void: command.emit(action))
	else:
		column.add_child(_label(tr_pair("ひとやすみ", "A LITTLE BREAK"), 38))
		column.add_child(_label(tr_pair("窓をドラッグで拭く。\n光る丸をタップしてハシゴを掛ける。\n「のぼる」→ 上で「回収」→ 掛け直す。", "Drag over a window to clean it.\nTap a glowing circle to place your ladder.\nClimb, pick it up, then place it again."), 23))
		column.add_child(_label(tr_pair("キーボード：← → 移動 / ↑↓ 登降\nE 回収 / Space 設置 / Esc 一時停止", "Keys: ← → move / ↑ ↓ climb\nE pick up / Space place / Esc pause"), 19, Color("bbceb8")))
		column.add_child(_button(tr_pair("つづける", "Continue"), "resume"))
		column.add_child(_button(tr_pair("この城壁をやり直す", "Retry this wall"), "retry_wall"))
		var settings_row: HBoxContainer = _row(column)
		settings_row.add_child(_button("♪ " + ("OFF" if muted else "ON"), "sound", 166))
		settings_row.add_child(_button("日本語 / EN", "language", 200))
		column.add_child(_button(tr_pair("動きを控えめに：", "Reduced motion: ") + ("ON" if reduced_motion else "OFF"), "motion"))
		column.add_child(_button(tr_pair("はじめから", "Start over"), "restart"))

func say(japanese: String, english: String, duration: float = 4.0) -> void:
	message_text = tr_pair(japanese, english)
	message_until = real_clock + duration
	hint.text = message_text

func _next_hint() -> String:
	if not state.is_clean(0):
		return tr_pair("窓をなぞって、ゴシゴシ。", "Drag over the window. Make a little sunshine.")
	if state.climbing:
		return tr_pair("もうすぐ、次の窓。", "A new little world is waiting up there.")
	if state.layout.chapter == 2:
		if not state.is_clean(2):
			return tr_pair("Aが左下のフックを開いた。Bの窓へ登ろう。", "A opened the lower-left hook. Climb toward B.")
		if not state.is_clean(4):
			if state.gifts.has("reach") and state.floor_index == 1 and not state.reach_spent:
				return tr_pair("長柄が届くのは一階上のEまで。橋を温存する手もある。", "Your sky squeegee reaches E one floor up. Save a bridge if you like.")
			return tr_pair("Bが上段の横橋を開く。Eを磨くと、中段の切れ目もつながる。", "B unlocks the upper bridge. Cleaning E joins the lower gallery.")
		if not state.is_clean(3):
			return tr_pair("Eが開いた道からCへ。窓の印とフックの鍵を読もう。", "E opens the gallery to C. Read each window and hook mark.")
		if not state.is_clean(1):
			return tr_pair("Cの印は地上のDへ。帰りのハシゴを残せる？", "C points to D below. Can you keep a ladder for the return trip?")
		if not state.is_clean(5):
			return tr_pair("DがFの雨戸と最上階のフックを開く。", "D opens F's shutter and the top-floor hooks.")
		if state.floor_index == 3:
			return tr_pair("星を見る住人の窓を、最後のひと拭き。", "One last wipe for the stargazer's window.")
	if state.layout.has_gap:
		if state.layout.is_horizontal_anchor(state.ladder_anchor):
			return tr_pair("渡った先からも、同じ1本を回収できる。", "Cross over. Pick up the same ladder at the far end.")
		if state.floor_index == 0 and not state.window_unlocked(1):
			return tr_pair("閉じた雨戸の印が、鍵になる窓を教えてくれる。", "The shutter’s letter tells you which window opens it.")
		if state.floor_index == 1 and state.is_clean(4):
			return tr_pair("開いた窓と、帰り道。1本をどう使おう？", "Open shutters, and a way home. Where does your ladder go?")
		if state.floor_index == 1:
			return tr_pair("縦に登る？ 横に渡る？ 仕掛けの印を見てみよう。", "Climb up or bridge across? Read the marks on the wall.")
	if state.gifts.has("reach") and not state.reach_spent and state.floor_index == 1 and not state.is_clean(4):
		return tr_pair("長柄なら、最後の高窓をここから拭ける！", "Your sky squeegee can reach the top window from here!")
	if state.floor_index == 0:
		if not state.is_clean(1):
			return tr_pair("もう一枚の窓も、気になるね。", "What could be behind the other window?")
		return tr_pair("光る丸にハシゴを掛けて、上の階へ。", "Tap a glowing circle. Place your ladder and climb.")
	if state.floor_index == 1:
		if state.ladder_anchor >= 0 and not state.layout.is_horizontal_anchor(state.ladder_anchor) and int(StageData.ANCHORS[state.ladder_anchor]["floor"]) == 0:
			return tr_pair("上でもハシゴを回収できるよ。", "You can pick up your ladder from the top, too.")
		if not state.is_clean(3):
			return tr_pair("窓の向こうに、誰かいる？", "Is someone waiting behind that window?")
		if not state.is_clean(2):
			return tr_pair("もう一枚、何があるかな。", "One more secret behind the other window.")
		return tr_pair("新しい足場へ、ハシゴを掛け直そう。", "A new ledge! Place your ladder to reach it.")
	if state.cleaned_count() < state.masks.size() - 1 and not state.is_clean(state.masks.size() - 1):
		return tr_pair("下の窓も、あとで忘れずに。", "Don't forget the other windows downstairs.")
	if state.is_clean(state.masks.size() - 1):
		return tr_pair("下に残った窓も、ぴかぴかにしよう。", "Let's go back for the windows we missed.")
	return tr_pair("最後のひと拭きで、朝がくる。", "One last window. Let the morning in.")

func button_snapshot() -> Dictionary:
	var result: Dictionary = {}
	var nodes: Array[Node] = [self]
	while not nodes.is_empty():
		var current: Node = nodes.pop_back()
		for child: Node in current.get_children():
			nodes.append(child)
		if current is Button and current.is_visible_in_tree():
			var bounds: Rect2 = current.get_global_rect()
			result[str(current.name)] = [bounds.position.x, bounds.position.y, bounds.size.x, bounds.size.y]
	return result
