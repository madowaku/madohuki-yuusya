class_name RoutePanel
extends RefCounted
## Reveals the rules, never a solved sequence. Reading stops the run clock.
static func build(column: VBoxContainer, model: StageState, language: String, command: Callable) -> void:
	var japanese: bool = language == "ja"
	column.add_child(JourneyPanel._label("仕掛けのつながり" if japanese else "FOLLOW THE CONNECTIONS", 30))
	column.add_child(JourneyPanel._label("窓を磨くと、同じ文字の仕掛けが開く。\n考えている間、時間は進まない。" if japanese else "A clean window opens mechanisms with its letter.\nThe clock waits while you think.", 21))
	for index: int in model.layout.window_count():
		var letter: String = str(StageData.WINDOWS[index]["id"])
		var destinations: PackedStringArray = []
		for target: int in model.layout.window_count():
			if model.layout.required_window[target] == index:
				destinations.append(("雨戸 " if japanese else "shutter ") + str(StageData.WINDOWS[target]["id"]))
		for anchor: int in model.layout.anchor_count():
			if model.anchor_enabled(anchor) and model.layout.hook_keys[anchor] == index:
				var labels: Array = ["左下フック", "右下フック", "中段左フック", "中段右フック", "中段の橋", "上段の橋", "最上段左フック", "最上段右フック"] if japanese else ["lower left hook", "lower right hook", "middle left hook", "middle right hook", "middle bridge", "upper bridge", "top left hook", "top right hook"]
				destinations.append(str(labels[anchor]))
		if destinations.is_empty():
			continue
		var prefix: String = "✓ " if model.is_clean(index) else "○ "
		var row: Label = JourneyPanel._label(prefix + letter + " → " + ", ".join(destinations), 23, Color("b9e9be") if model.is_clean(index) else Color("f3e3b5"))
		row.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		column.add_child(row)
	if model.layout.has_gap:
		column.add_child(JourneyPanel._label("ハシゴは1本。縦にも横にも、両端から回収。\n光る ↔ が横掛けの場所。" if japanese else "One ladder: upright or sideways. Retrieve at either end.\nThe glowing ↔ marks the bridge position.", 22, Color("ffe4a9")))
	if model.layout.chapter == 2:
		column.add_child(JourneyPanel._label("Eを磨くと中段の切れ目が開通。鍵の印をたどってみよう。" if japanese else "Cleaning E opens a permanent middle gallery. Follow the lettered locks.", 21, Color("ffe4a9")))
	column.add_child(JourneyPanel._label(("設置 %d 回以内で、%d枚すべてを磨こう。\n超えてもクリア可能。何度でも工夫できる。" if japanese else "Can you clean all %d windows in %d placements?\nExtra moves are allowed. Keep experimenting.") % [model.layout.window_count(), model.layout.placement_goal(model.gifts)], 22))
	column.add_child(JourneyPanel._button("盤面にもどる" if japanese else "Back to the wall", "resume", command))
	column.add_child(JourneyPanel._button("この城壁をやり直す" if japanese else "Retry this wall", "retry_wall", command))
