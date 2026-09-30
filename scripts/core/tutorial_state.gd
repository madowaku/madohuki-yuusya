class_name TutorialState
extends TowerState
## Tutorial-only routing: no gallery, shutter, or interior links.
var tutorial_step: int = 1
var tutorial_layout: TutorialLayout

func _init() -> void:
	configure_tutorial(1)

func configure_tutorial(step: int) -> void:
	tutorial_step = clampi(step, 1, 3)
	tutorial_layout = TutorialLayout.new(tutorial_step)
	configure(tutorial_layout, [])

func reset() -> void:
	if tutorial_layout == null:
		return
	super.reset()
	hero = tutorial_layout.initial_hero()
	walk_target = hero.x
	region = 0
	floor_index = tutorial_layout.region_floor(region)
	changed.emit()

func anchor_unlocked(index: int) -> bool:
	if not anchor_enabled(index):
		return false
	var required: int = tutorial_layout.anchor_requirement(index)
	return required < 0 or (required < masks.size() and is_clean(required))

func window_unlocked(index: int) -> bool:
	if index < 0 or index >= masks.size():
		return false
	var required: int = int(tutorial_layout.board["windows"][index].get("requires_window", -1))
	return required < 0 or (required < masks.size() and is_clean(required))

func can_reach_floor(index: int) -> bool:
	if index < 0 or index >= masks.size():
		return false
	return not _path(region, tutorial_layout.window_region(index), ladder_anchor).is_empty()

func hook_hit_rect(index: int) -> Rect2:
	var point: Vector2 = anchor_marker(index) + Vector2(0, 16)
	return Rect2(point - TowerLayout.HIT_SIZE * 0.5, TowerLayout.HIT_SIZE)

func _links(at: int, with_ladder: int) -> Array[int]:
	var result: Array[int] = []
	if with_ladder >= 0 and with_ladder < tower.anchor_count():
		var ends: Array[int] = tower.anchor_ends(with_ladder)
		if ends.has(at):
			result.append(ends[1] if at == ends[0] else ends[0])
	return result

func _check_clear() -> void:
	if cleaned_count() == masks.size() and phase != "clear":
		phase = "clear"
		placement_mode = false
		event_occurred.emit("stage_cleared", masks.size())

func snapshot() -> Dictionary:
	var result: Dictionary = super.snapshot()
	result["tutorial"] = true
	result["tutorial_step"] = tutorial_step
	result["visible_floors"] = tutorial_layout.visible_floors()
	return result
