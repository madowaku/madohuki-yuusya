extends Node

@onready var castle: CastleView = $Castle
@onready var hud: GameHUD = $UI/HUD
@onready var sound: SoundBank = $Sound
var state: StageState = TowerState.new()
var journey: CastleRun = CastleRun.new()
var run_records: Dictionary = {}
var active_window: int = -1
var active_touch: int = -1
var last_pointer: Vector2 = Vector2.ZERO
var dragging: bool = false
var browser_callback: JavaScriptObject
var debug_visible: bool = false
var step_clock: float = 0.0
var web_clock: float = 0.0
var tutorial_advance_timer: float = 0.0
var hints_enabled_preference: bool = true

func _ready() -> void:
	state.phase = "title"
	_load_settings()
	(state as TowerState).set_hints_enabled(hints_enabled_preference)
	castle.bind(state)
	hud.bind(state, journey)
	hud.command.connect(_command)
	hud.direction_changed.connect(func(value: float) -> void: state.held_direction = value)
	state.event_occurred.connect(_event)
	sound.muted = hud.muted
	if OS.has_feature("web"):
		# Read-only instrumentation stays available in the shipped build.
		JavaScriptBridge.eval("window.windowHero = {state: {}, ready: true};")
		if OS.is_debug_build():
			browser_callback = JavaScriptBridge.create_callback(_debug_browser_command)
			var browser: JavaScriptObject = JavaScriptBridge.get_interface("window")
			browser.windowHeroCommand = browser_callback
	print("[WindowHero] ready Godot 4.7; portrait 720x1280; mouse + touch")

func _process(delta: float) -> void:
	var keyboard_direction: float = 0.0
	if Input.is_physical_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_A):
		keyboard_direction -= 1
	if Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_physical_key_pressed(KEY_D):
		keyboard_direction += 1
	if keyboard_direction != 0:
		state.walk_to(state.hero.x + keyboard_direction * 110)
	state.tick(minf(delta, 0.05))
	step_clock += delta
	if state.climbing and not state.paused and step_clock > 0.36:
		sound.play("step")
		step_clock = 0
	if tutorial_advance_timer > 0.0 and state is TutorialState:
		var tutorial: TutorialState = state as TutorialState
		if tutorial.phase != "clear":
			tutorial_advance_timer = 0.0
		elif not tutorial.paused:
			tutorial_advance_timer = maxf(0.0, tutorial_advance_timer - delta)
			if tutorial_advance_timer == 0.0:
				if tutorial.tutorial_step >= 3:
					_begin_tower()
				else:
					_begin_tutorial(tutorial.tutorial_step + 1)
	if OS.has_feature("web"):
		web_clock += delta
		if web_clock > 0.2:
			JavaScriptBridge.eval("window.windowHero.state = " + JSON.stringify(debug_snapshot()) + ";")
			web_clock = 0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo:
			match key_event.physical_keycode:
				KEY_ESCAPE:
					_command("resume" if state.paused else "pause")
				KEY_ENTER:
					if state.phase == "title":
						_command("start")
				KEY_SPACE:
					_command("action")
				KEY_UP, KEY_DOWN, KEY_W, KEY_S:
					state.climb()
				KEY_E:
					if not state is TowerState:
						state.retrieve()
				KEY_Z:
					_command("undo")
				KEY_F3:
					debug_visible = not debug_visible
					hud.debug_label.visible = debug_visible
	if not state.can_act() or hud.credits_open:
		return
	if event is InputEventMouseButton:
		var mouse: InputEventMouseButton = event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_LEFT:
			if mouse.pressed:
				_pointer_down(mouse.position)
			else:
				_pointer_up()
	elif event is InputEventMouseMotion:
		var motion: InputEventMouseMotion = event as InputEventMouseMotion
		_update_tower_preview(motion.position)
		if dragging and active_touch < 0:
			_pointer_move(motion.position)
	elif event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		if touch.pressed and active_touch < 0:
			active_touch = touch.index
			_pointer_down(touch.position)
		elif not touch.pressed and touch.index == active_touch:
			_pointer_up()
	elif event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event as InputEventScreenDrag
		if drag.index == active_touch:
			_pointer_move(drag.position)

func _input(event: InputEvent) -> void:
	# A release on top of a HUD button must still end the ongoing cleaning gesture.
	if event is InputEventMouseButton:
		var mouse: InputEventMouseButton = event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_LEFT and not mouse.pressed:
			_pointer_up()
	elif event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		if not touch.pressed and touch.index == active_touch:
			_pointer_up()

func _pointer_down(point: Vector2) -> void:
	dragging = true
	last_pointer = point
	castle.pointer = point
	active_window = -1
	if state is TowerState:
		_tower_pointer_down(point)
		return
	for index: int in state.masks.size():
		if state.window_rect(index).grow(8).has_point(point):
			if not state.window_unlocked(index):
				var key: String = str(StageData.WINDOWS[state.layout.required_window[index]]["id"])
				hud.say("雨戸の鍵は %s の窓。つながりをたどってみよう。" % key, "Window %s opens this shutter. Follow the connection." % key, 3.0)
			elif state.accessible(index):
				active_window = index
				castle.wiping = not state.is_clean(index)
			elif state.window_floor(index) == state.floor_index and not state.same_balcony(state.window_rect(index).get_center().x) and not state.bridge_on_floor():
				hud.say("ベランダが途切れている。1本のハシゴで道を作れそう。", "A gap between balconies. One ladder could make a path.", 3.0)
			elif state.can_reach_floor(index):
				state.walk_to(state.window_rect(index).get_center().x)
				active_window = index
				castle.wiping = not state.is_clean(index)
			else:
				hud.say("ハシゴで、窓のある階へ。", "Use your ladder to reach this floor.", 2.0)
			return
	for index: int in state.layout.anchor_count():
		if not state.anchor_on_floor(index):
			continue
		var point_on_floor: Vector2 = state.anchor_marker(index)
		if point.distance_to(point_on_floor + Vector2(0, -16)) < StageData.ANCHOR_INPUT_RADIUS:
			if state.ladder_anchor == index:
				state.climb()
			else:
				state.request_place(index)
			return
	if point.y > StageData.FLOORS[state.floor_index] - 100 and point.y < StageData.FLOORS[state.floor_index] + 22:
		state.walk_to(point.x)

func _tower_pointer_down(point: Vector2) -> void:
	var model: TowerState = state as TowerState
	for index: int in model.masks.size():
		if model.tower.window_hit_rect(index).has_point(point):
			if model.interact_window(index) and not model.is_clean(index) and model.window_unlocked(index) and not model.inside():
				active_window = index
				castle.wiping = true
			return
	if model.placement_mode:
		var candidate: int = model.placement_candidate_at(point)
		if candidate >= 0:
			model.request_place(candidate)
		elif model.ladder_anchor >= 0 and model.ladder_hit_rect().has_point(point):
			model.select_ladder()
		elif model.ladder_anchor < 0 and model.carried_ladder_hit_rect().has_point(point):
			model.select_ladder()
		return
	if model.help_visible:
		var help_candidate: int = model.placement_candidate_at(point)
		if help_candidate >= 0:
			model.request_place(help_candidate)
			return
	if model.ladder_anchor >= 0 and model.ladder_hit_rect().has_point(point):
		model.select_ladder()
		return
	if model.ladder_anchor < 0 and model.carried_ladder_hit_rect().has_point(point):
		model.select_ladder()
		return
	model.tap_destination(point)

func _pointer_move(point: Vector2) -> void:
	if not dragging or not state.can_act():
		return
	castle.pointer = point
	_update_tower_preview(point)
	if active_window >= 0:
		var erased: int = state.wipe(active_window, last_pointer, point)
		if erased > 0:
			sound.play("wipe")
		if state.is_clean(active_window):
			castle.wiping = false
	last_pointer = point

func _update_tower_preview(point: Vector2) -> void:
	if not state is TowerState:
		return
	var model: TowerState = state as TowerState
	if not model.placement_mode:
		return
	model.preview_anchor = model.placement_candidate_at(point)

func _pointer_up() -> void:
	dragging = false
	active_touch = -1
	active_window = -1
	castle.wiping = false

func _begin_wall() -> void:
	_pointer_up()
	hud.result_delay = 0.0
	hud.message_until = 0.0
	hud.credits_open = false
	hud.planning_open = false
	state.configure(journey.layout(), journey.gifts)
	castle.invalidate()
	hud.refresh()
	sound.begin()
	sound.play("retrieve")

func _switch_state(model: StageState) -> void:
	_pointer_up()
	if state.event_occurred.is_connected(_event):
		state.event_occurred.disconnect(_event)
	state = model
	if state is TowerState:
		(state as TowerState).set_hints_enabled(hints_enabled_preference)
	castle.bind(state)
	hud.bind(state, journey)
	state.event_occurred.connect(_event)
	castle.invalidate()
	hud.refresh()

func _begin_tower() -> void:
	tutorial_advance_timer = 0.0
	hud.result_delay = 0
	hud.credits_open = false
	hud.planning_open = false
	_switch_state(TowerState.new())
	sound.begin()

func _begin_tutorial(step: int) -> void:
	tutorial_advance_timer = 0.0
	hud.result_delay = 0.0
	hud.credits_open = false
	hud.planning_open = false
	var tutorial: TutorialState = TutorialState.new()
	tutorial.configure_tutorial(step)
	_switch_state(tutorial)
	sound.begin()

func _command(action: String) -> void:
	if action == "start_classic":
		journey.start(journey.castle_seed)
		_switch_state(StageState.new())
		_begin_wall()
		return
	if action == "undo" and state is TowerState:
		_pointer_up()
		hud.result_delay = 0
		if state is TutorialState:
			tutorial_advance_timer = 0.0
		(state as TowerState).undo()
		return
	if action == "action" and state is TowerState:
		(state as TowerState).select_ladder()
		return
	if action == "help" and state is TowerState:
		(state as TowerState).toggle_help()
		return
	if action == "hints" and state is TowerState:
		hints_enabled_preference = not hints_enabled_preference
		(state as TowerState).set_hints_enabled(hints_enabled_preference)
		_save_settings()
		hud.refresh()
		return
	if action == "title":
		_begin_tower()
		state.phase = "title"
		hud.refresh()
		return
	if state is TutorialState and action in ["start", "restart", "retry_wall", "new_castle"]:
		_begin_tutorial((state as TutorialState).tutorial_step)
		return
	if state is TowerState and action in ["start", "restart", "retry_wall", "new_castle"]:
		if action == "start" and state.phase == "title":
			_begin_tutorial(1)
		else:
			_begin_tower()
		return
	if action.begins_with("gift:"):
		if journey.choose_gift(action.trim_prefix("gift:")):
			_begin_wall()
		return
	match action:
		"start", "restart", "new_castle":
			var seed_value: int = journey.castle_seed
			if action != "restart":
				seed_value = randi_range(1, 999999)
				if seed_value == journey.castle_seed:
					seed_value = seed_value % 999999 + 1
			journey.start(seed_value)
			_begin_wall()
		"pause":
			if state.phase == "playing":
				_pointer_up()
				state.set_paused(true)
		"plan":
			if state.phase == "playing":
				_pointer_up()
				hud.planning_open = true
				state.set_paused(true)
		"retry_wall":
			if state.phase == "playing":
				_begin_wall()
		"resume":
			hud.planning_open = false
			state.set_paused(false)
		"language":
			hud.language = "en" if hud.language == "ja" else "ja"
			hud.message_until = 0
			hud.rebuild()
			_save_settings()
		"sound":
			hud.muted = not hud.muted
			sound.set_muted(hud.muted)
			hud.refresh()
			_save_settings()
		"motion":
			hud.reduced_motion = not hud.reduced_motion
			castle.reduced_motion = hud.reduced_motion
			hud.refresh()
			_save_settings()
		"credits":
			hud.credits_open = true
			hud.refresh()
		"back":
			hud.credits_open = false
			hud.refresh()
		"retrieve":
			if not state.retrieve() and state.ladder_anchor >= 0:
				hud.say("ハシゴのそばでもう一度「回収」。", "Get close, then tap Pick up again.", 2.5)
		"action":
			if state.ladder_anchor >= 0:
				if not state.climb() and not state.climbing:
					hud.say("ハシゴのそばでもう一度「のぼる」。", "Get close, then tap Climb again.", 2.5)
			else:
				var nearest: int = -1
				var distance: float = INF
				for index: int in state.layout.anchor_count():
					if state.anchor_on_floor(index) and state.anchor_unlocked(index):
						var next_distance: float = absf(state.hero.x - state.anchor_base(index).x)
						if next_distance < distance:
							nearest = index
							distance = next_distance
				if nearest >= 0:
					state.request_place(nearest)
				else:
					hud.say("まずは窓を、ひと拭き。", "First, let's clean a window.", 2.5)

func _event(event_name: String, detail: int) -> void:
	if event_name != "window_clean_progress":
		print("[WindowHero] %s %d %s" % [event_name, detail, JSON.stringify(state.snapshot())])
	if state is TutorialState:
		match event_name:
			"ladder_placed": sound.play("place")
			"window_cleaned": sound.play("shine")
			"state_undone": sound.play("retrieve")
			"stage_cleared":
				tutorial_advance_timer = 0.8
				sound.play("clear")
		return
	if state is TowerState:
		match event_name:
			"ladder_placed", "shutter_opened": sound.play("place")
			"ladder_retrieved", "state_undone", "shutter_rattled": sound.play("retrieve")
			"window_cleaned", "mechanism_activated": sound.play("shine")
			"stage_cleared":
				hud.result_delay = 1.2
				sound.play("clear")
		return
	match event_name:
		"ladder_placed":
			sound.play("place")
			if state.layout.is_horizontal_anchor(detail):
				hud.say("ハシゴが、橋になった！", "Your ladder is a bridge!", 3.0)
			else:
				hud.say("ガシャン！ ハシゴの準備、できた。", "Clunk! Your ladder is ready.", 2.0)
		"ladder_retrieved":
			sound.play("retrieve")
			if state.gifts.has("recall"):
				hud.say("おかえり！ フックでその場に回収。", "Welcome back! Your hook brings the ladder to you.", 2.5)
			else:
				hud.say("ハシゴを持って、次の場所へ。", "Ladder in hand. On to the next little secret.", 2.5)
		"invalid_placement":
			var key: String = str(StageData.WINDOWS[state.layout.hook_keys[detail]]["id"])
			hud.say("先にハシゴを回収。灰色の印は %s の窓で開くよ。" % key, "Pick up your ladder first. Window %s opens this gray hook." % key, 3.0)
		"window_cleaned":
			sound.play("shine")
			match detail:
				0:
					hud.say("歯車が動いた！ 上のフックが開いたよ。", "The gears turn! The upper hooks are unlocked.", 5.0)
				1:
					hud.say("陽だまりの温室。猫も、うれしそう。", "A tiny greenhouse. A very happy cat.", 4.0)
				2:
					hud.say("小さな書庫。「やさしい魔法の使い方」。", "A little library. “The Art of Gentle Magic.”", 4.0)
				3:
					hud.say("「ありがとう！ フックを開けておくね。」", "“Thank you! I've opened the hooks for you.”", 5.0)
				4:
					if state.layout.chapter == 2:
						hud.say("Eの光で、中段のギャラリーが開いた！", "E's light opened the middle gallery!", 4.0)
					else:
						hud.say("いちばん高い窓には、朝を待つ猫。", "At the highest window, a cat waiting for sunrise.", 4.0)
				5:
					hud.say("天文塔の蛾が、朝の星を見つけた！", "A tiny astronomer found the morning star!", 4.0)
		"mechanism_activated":
			if state.layout.chapter > 0:
				hud.say("%s の光が、つながる仕掛けを開いた！" % StageData.WINDOWS[detail]["id"], "Window %s opened its linked mechanisms!" % StageData.WINDOWS[detail]["id"], 3.0)
		"bubble_link":
			hud.say("おすそわけの泡が、隣の窓へ！", "A little kindness bubbles over to the next window!", 2.0)
		"stage_cleared":
			journey.finish_wall(state)
			hud.result_delay = 1.7
			sound.play("clear")
			if journey.complete():
				var record_key: String = journey.record_key()
				journey.previous_record = run_records.get(record_key, {}).duplicate(true)
				journey.new_record = journey.beats(journey.previous_record)
				if journey.new_record:
					run_records[record_key] = journey.record()
				while run_records.size() > 32:
					run_records.erase(run_records.keys()[0])
				_save_settings()

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_WINDOW_FOCUS_OUT] and is_node_ready():
		_pointer_up()
		if state.phase == "playing":
			state.set_paused(true)

func _load_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		hud.language = str(config.get_value("settings", "language", "ja"))
		hud.muted = bool(config.get_value("settings", "muted", false))
		hud.reduced_motion = bool(config.get_value("settings", "reduced_motion", false))
		hints_enabled_preference = bool(config.get_value("settings", "hints_enabled", true))
		hud.best_moves = int(config.get_value("record", "moves", 0))
		var saved_records: Variant = config.get_value("record", "castles", {})
		if saved_records is Dictionary:
			run_records = saved_records
	castle.reduced_motion = hud.reduced_motion

func _save_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("settings", "language", hud.language)
	config.set_value("settings", "muted", hud.muted)
	config.set_value("settings", "reduced_motion", hud.reduced_motion)
	config.set_value("settings", "hints_enabled", hints_enabled_preference)
	config.set_value("record", "moves", hud.best_moves)
	config.set_value("record", "castles", run_records)
	config.save("user://settings.cfg")

func _debug_browser_command(arguments: Array) -> void:
	if arguments.is_empty():
		return
	var action: String = str(arguments[0])
	if action in ["start", "restart", "pause", "resume", "title", "language", "help", "hints"]:
		_command(action)

func debug_snapshot() -> Dictionary:
	var result: Dictionary = state.snapshot()
	result["journey"] = journey.snapshot()
	result["language"] = hud.language
	result["buttons"] = hud.button_snapshot()
	return result
