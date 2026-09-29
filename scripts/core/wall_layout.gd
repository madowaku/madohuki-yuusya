class_name WallLayout
extends RefCounted
## Hand-built, solvable geometry with seeded room/anchor variations.
var windows: Array[Rect2] = []
var anchor_x: Array[float] = [114.0, 606.0, 224.0, 496.0, 228.0, 228.0, 112.0, 608.0]
var chapter: int = 0
var dirt_offset: int = 0
var required_window: Array[int] = [-1, -1, -1, -1, -1, -1]
var hook_keys: Array[int] = [0, 0, 3, 3, 2, 2, 1, 1]
var has_gap: bool = false
const GAP_LEFT: float = 320.0
const GAP_RIGHT: float = 400.0

func _init(castle_seed: int = 1, wall_index: int = 0) -> void:
	chapter = wall_index
	for index: int in (6 if wall_index == 2 else 5):
		windows.append(StageData.window_rect(index))
	if wall_index < 2:
		required_window.resize(5)
	if wall_index == 0:
		return
	has_gap = true
	hook_keys[1] = 3
	# Moonlight opens the ground shutter. On the final wall, the library
	# opens the upper hooks and moonlight wakes the merchant before the garden.
	required_window[1] = 4 if wall_index == 1 else 3
	if wall_index == 2:
		required_window[3] = 4
		hook_keys[2] = 2
		required_window[5] = 1
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = castle_seed * 101 + wall_index * 9973
	var left: float = float([172, 182, 196][rng.randi_range(0, 2)])
	var right: float = float([396, 412, 424][rng.randi_range(0, 2)])
	windows[0].position.x = right if rng.randf() < 0.5 else left
	windows[1].position.x = left if windows[0].position.x == right else right
	windows[2].position.x = left
	windows[3].position.x = right
	windows[4].position.x = float([244, 294, 344][rng.randi_range(0, 2)])
	if chapter == 2:
		windows[4].position.x = right
	anchor_x = [float(rng.randi_range(102, 134)), float(rng.randi_range(586, 620)), float(rng.randi_range(214, 264)), float(rng.randi_range(456, 504)), 228.0, 228.0, 112.0, 608.0]
	dirt_offset = rng.randi_range(1, 4)

func window_rect(index: int) -> Rect2:
	return windows[index]

func anchor_base(index: int) -> Vector2:
	return Vector2(anchor_x[index], StageData.FLOORS[int(StageData.ANCHORS[index]["floor"])])

func anchor_top(index: int) -> Vector2:
	if StageData.is_horizontal_anchor(index):
		return anchor_base(index) + Vector2(265, 0)
	return anchor_base(index) + Vector2(0, -265)

func is_horizontal_anchor(index: int) -> bool:
	return StageData.is_horizontal_anchor(index)

func window_floor(index: int) -> int:
	return int(StageData.WINDOWS[index]["floor"])

func window_count() -> int:
	return windows.size()

func anchor_count() -> int:
	return 4 if chapter == 0 else (6 if chapter == 1 else 8)

func title(language: String) -> String:
	var names: Array = ["はじまりの城壁", "ふたつのベランダ", "四階建て・星あかり塔"] if language == "ja" else ["THE FIRST WALL", "TWO BALCONIES", "FOUR-FLOOR STAR TOWER"]
	return names[clampi(chapter, 0, 2)]

func placement_goal(tools: Array[String]) -> int:
	if tools.has("reach"):
		return [1, 2, 5][chapter]
	return [2, 4, 7][chapter]

func gap_on_floor(floor_index: int) -> bool:
	return has_gap and (floor_index == 1 or (chapter == 2 and floor_index == 2))
