class_name TowerHUD
extends GameHUD
## The board owns interaction. Only progress, Undo and Menu remain on screen.
var undo_button: Button

func rebuild() -> void:
	if not state is TowerState:
		super.rebuild()
		return
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	title_top = _margin(16, 176)
	title_top.name = "TitleTop"
	var title_column: VBoxContainer = _column(title_top)
	title_column.add_theme_constant_override("separation", 2)
	title_column.add_child(_label("CLIMB · CLEAN · DISCOVER", 18, Color("aab6c5")))
	title_column.add_child(_label(tr_pair("窓ふき勇者", "WINDOW HERO"), 56))
	title_bottom = _margin(-204, -16, true)
	title_bottom.name = "TitleBottom"
	var title_actions: VBoxContainer = _column(title_bottom)
	var start_button: Button = _button(tr_pair("灯りをつなぐ塔へ →", "Enter the lantern tower →"), "start")
	start_button.add_theme_stylebox_override("normal", _warm_style())
	start_button.add_theme_color_override("font_color", Color("293d42"))
	title_actions.add_child(start_button)
	var options: HBoxContainer = _row(title_actions)
	options.add_child(_button("日本語 / EN", "language", 204))
	options.add_child(_button(tr_pair("クレジット", "Credits"), "credits", 204))
	options.add_child(_button("♪", "sound", 140))
	header = _margin(8, 100)
	header.name = "Header"
	var row: HBoxContainer = _row(header)
	chapter_label = _label("", 28, Color("d1d4df"))
	chapter_label.custom_minimum_size.x = 116
	chapter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	row.add_child(chapter_label)
	counter = _label("", 28, Color("eedbb9"))
	counter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(counter)
	undo_button = _icon("undo")
	undo_button.tooltip_text = tr_pair("一手もどる", "Undo one move")
	row.add_child(undo_button)
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

func _icon(action: String) -> BoardIconButton:
	var button: BoardIconButton = BoardIconButton.new()
	button.glyph_key = "undo" if action == "undo" else "menu"
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
	if not state is TowerState:
		super._process(delta)
		return
	real_clock += delta
	if result_delay > 0:
		result_delay = maxf(0, result_delay - delta)
		if result_delay == 0:
			refresh()
	if debug_label != null and debug_label.visible:
		debug_label.text = JSON.stringify(state.snapshot())

func refresh() -> void:
	if not state is TowerState:
		super.refresh()
		return
	if header == null:
		return
	var model: TowerState = state as TowerState
	var show_overlay: bool = model.paused or (model.phase == "clear" and result_delay <= 0) or credits_open
	title_top.visible = model.phase == "title" and not show_overlay
	title_bottom.visible = title_top.visible
	header.visible = model.phase != "title" and not show_overlay
	overlay.visible = show_overlay
	chapter_label.text = "%dF" % (model.floor_index + 1)
	counter.text = "%d / 12" % model.cleaned_count()
	undo_button.disabled = model.history.is_empty() or model.paused
	if show_overlay:
		_build_overlay()

func _build_overlay() -> void:
	if not state is TowerState or credits_open:
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
	if state.phase == "clear":
		column.add_child(_label(tr_pair("塔に、灯りがともった。", "THE TOWER IS ALIGHT."), 34))
		column.add_child(_label(tr_pair("12の窓 · ハシゴ設置 %d回\n最少設置 %d回", "12 windows · %d ladder placements\nMinimum: %d placements") % [state.moves, state.layout.placement_goal([])], 26))
		column.add_child(_button(tr_pair("塔をもう一度", "Try the tower again"), "restart"))
		column.add_child(_button(tr_pair("一手もどって考える", "Undo and explore"), "undo"))
	else:
		column.add_child(_label(tr_pair("ひとやすみ", "A LITTLE BREAK"), 36))
		column.add_child(_label(tr_pair("窓をなぞると、光が差す。\n勇者をタップ → ハシゴの行き先を選ぶ。\n開いた窓をタップ → 中へ。", "Drag a window to let the light in.\nTap the hero → choose the next ladder hook.\nTap an open window → step inside."), 23))
		column.add_child(_button(tr_pair("つづける", "Continue"), "resume"))
		column.add_child(_button(tr_pair("この塔をやり直す", "Retry this tower"), "restart"))
		var settings: HBoxContainer = _row(column)
		settings.add_child(_button("♪ " + ("OFF" if muted else "ON"), "sound", 166))
		settings.add_child(_button("日本語 / EN", "language", 200))
		column.add_child(_button(tr_pair("動きを控えめに：", "Reduced motion: ") + ("ON" if reduced_motion else "OFF"), "motion"))
	column.add_child(_button(tr_pair("以前の3城壁で遊ぶ", "Play the original three walls"), "start_classic"))
	column.add_child(_button(tr_pair("タイトルへ", "Title"), "title"))

func say(japanese: String, english: String, duration: float = 4) -> void:
	if not state is TowerState:
		super.say(japanese, english, duration)
