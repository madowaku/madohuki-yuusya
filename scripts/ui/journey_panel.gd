class_name JourneyPanel
extends RefCounted
## Gift choices and run results share the existing HUD's container/theme.

static func build(column: VBoxContainer, journey: CastleRun, language: String, command: Callable) -> void:
	var japanese: bool = language == "ja"
	if journey.awaiting_gift():
		column.add_child(_label("%d / 3  ·  WALL CLEAR" % (journey.wall_index + 1), 20, Color("b9e9be")))
		var wall: Dictionary = journey.results.back()
		column.add_child(_label(("設置 %d 回 / 目標 %d 回  ·  横掛け %d 回" if japanese else "%d MOVES / TARGET %d · %d BRIDGES") % [wall["moves"], wall["goal"], wall["bridges"]], 21))
		if int(wall["moves"]) <= int(wall["goal"]):
			column.add_child(_label("ひらめきの順路！" if japanese else "A CLEVER ROUTE!", 24, Color("ffe4a9")))
		column.add_child(_label("窓の向こうから、お礼です。" if japanese else "A thank-you from the other side.", 32))
		column.add_child(_label("道具をひとつ選んで、次の城壁へ。\n選んだ効果は、この旅の最後まで。" if japanese else "Choose one gift for the next wall.\nIt stays with you for the rest of this journey.", 22))
		for gift: String in journey.available_gifts():
			var button: Button = Button.new()
			button.name = "Gift" + gift.to_pascal_case()
			button.custom_minimum_size = Vector2(0, 150)
			button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			button.tooltip_text = CastleRun.gift_name(gift, language)
			button.pressed.connect(command.bind("gift:" + gift))
			var margin: MarginContainer = MarginContainer.new()
			margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			margin.add_theme_constant_override("margin_left", 16)
			margin.add_theme_constant_override("margin_right", 16)
			margin.add_theme_constant_override("margin_top", 12)
			margin.add_theme_constant_override("margin_bottom", 12)
			margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
			button.add_child(margin)
			var words: VBoxContainer = VBoxContainer.new()
			words.alignment = BoxContainer.ALIGNMENT_CENTER
			words.mouse_filter = Control.MOUSE_FILTER_IGNORE
			margin.add_child(words)
			words.add_child(_label(CastleRun.gift_name(gift, language), 26, Color("ffe4a9")))
			words.add_child(_label(CastleRun.gift_description(gift, language), 24))
			column.add_child(button)
		var preview: String = ("次の城壁：途切れたベランダ。1本をどう使う？" if japanese else "Next: a gap between balconies. One ladder. Your plan?") if journey.wall_index == 0 else ("次の城壁：雨戸の鍵を、上から逆算。" if japanese else "Next: trace the shutter keys back from the top.")
		column.add_child(_label(preview + "\n#%06d" % journey.castle_seed, 19, Color("b7c9bc")))
		return
	column.add_child(_label("EVERY WINDOW, A LITTLE WORLD", 17, Color("b9e9be")))
	column.add_child(_label("お城に、朝がきた。" if japanese else "Morning finds the castle.", 36, Color("ffe4a9")))
	column.add_child(_label("3つの城壁、16の窓。\nきれいにした先で、つながった旅。" if japanese else "Three walls. Sixteen little worlds.\nA journey made brighter by kindness.", 23))
	column.add_child(_label(("ハシゴ設置  %d 回\n歩いた距離  %.1f m" if japanese else "LADDER PLACEMENTS  %d\nWALKING DISTANCE  %.1f m") % [int(journey.total("moves")), journey.total("walking")], 27, Color("ffe4a9")))
	column.add_child(_label(("所要時間 %d 秒  ·  登降 %d m" if japanese else "TIME %d sec  ·  CLIMB %d m") % [int(journey.total("time")), int(journey.total("climb"))], 20))
	column.add_child(_label(("ひらめきの順路  %d / 3" if japanese else "CLEVER ROUTES  %d / 3") % journey.goals_met(), 23, Color("b9e9be")))
	var tools: PackedStringArray = []
	for gift: String in journey.gifts:
		tools.append(CastleRun.gift_name(gift, language))
	column.add_child(_label(" + ".join(tools), 21, Color("b9e9be")))
	var record_text: String = "この城と道具の順で、初めての記録！" if japanese else "First record for this castle and gift order!"
	if not journey.previous_record.is_empty():
		record_text = ("この城のルート記録を更新！" if japanese else "A new route record for this castle!") if journey.new_record else ("次は違う道具と順路を試してみよう。" if japanese else "Try another gift and another route next time.")
		column.add_child(_label(("同じ城・道具順の記録：設置 %d 回 / 徒歩 %.1f m" if japanese else "SAME CASTLE + GIFTS: %d placements / %.1f m walked") % [int(journey.previous_record["moves"]), float(journey.previous_record["walking"])], 19, Color("c4ccbb")))
	column.add_child(_label(record_text, 22))
	column.add_child(_label("#%06d  ·  %s" % [journey.castle_seed, "同じ城なら配置も同じ" if japanese else "Same castle, same layout"], 19, Color("b7c9bc")))
	column.add_child(_button("同じ城で、別の作戦。" if japanese else "Same castle, a new plan", "restart", command))
	column.add_child(_button("別の城に出かける →" if japanese else "Visit a different castle →", "new_castle", command))
	column.add_child(_button("タイトルへ" if japanese else "Back to title", "title", command))

static func _label(text: String, size: int, color: Color = Color("f3e3b5")) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label

static func _button(text: String, action: String, command: Callable) -> Button:
	var button: Button = Button.new()
	button.name = action.to_pascal_case()
	button.text = text
	button.custom_minimum_size.y = 88
	button.pressed.connect(command.bind(action))
	return button
