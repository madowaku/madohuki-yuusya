class_name TutorialLayout
extends TowerLayout
## Three sparse authored boards that teach the ladder through play.
const TUTORIAL_DATA: Dictionary = preload("res://resources/tutorial_v02.json").data

var tutorial_step: int = 1
var board: Dictionary = {}

func _init(step: int = 1) -> void:
	super(1, 0)
	tutorial_step = clampi(step, 1, 3)
	board = TUTORIAL_DATA["boards"][tutorial_step - 1]
	configure_data(board)

func tutorial_step_data() -> Dictionary:
	return board

func initial_hero() -> Vector2:
	var point: Array = board["hero"]
	return Vector2(float(point[0]), float(point[1]))

func stage_id() -> String:
	return "tutorial_%d" % tutorial_step

func initial_region() -> int:
	return 0

func visible_floors() -> Array[int]:
	var result: Array[int] = []
	for value: Variant in board["visible_floors"]:
		result.append(int(value))
	return result

func window_floor(index: int) -> int:
	return int(board["windows"][index]["floor"])

func window_region(index: int) -> int:
	return int(board["windows"][index]["region"])

func window_kind(index: int) -> String:
	return str(board["windows"][index]["kind"])

func window_hit_rect(index: int) -> Rect2:
	var area: Rect2 = window_rect(index)
	var target_size: Vector2 = area.size.max(TowerLayout.HIT_SIZE)
	return Rect2(area.get_center() - target_size * 0.5, target_size)

func floor_y(index: int) -> float:
	return float(board["floors"][index])

func region_floor(region: int) -> int:
	var floors: Array = board["region_floors"]
	return int(floors[region]) if region >= 0 and region < floors.size() else 0

func anchor_ends(index: int) -> Array[int]:
	var ends: Array = board["anchors"][index]["ends"]
	return [int(ends[0]), int(ends[1])]

func anchor_base(index: int) -> Vector2:
	var point: Array = board["anchors"][index]["base"]
	return Vector2(float(point[0]), float(point[1]))

func anchor_top(index: int) -> Vector2:
	var point: Array = board["anchors"][index]["top"]
	return Vector2(float(point[0]), float(point[1]))

func anchor_requirement(index: int) -> int:
	return int(board["anchors"][index].get("requires_window", -1))

func is_horizontal_anchor(index: int) -> bool:
	return index >= 0 and index < anchor_count() and bool(board["anchors"][index].get("horizontal", false))

func anchor_count() -> int:
	return board["anchors"].size()

func title(_language: String) -> String:
	return "WINDOW HERO"

func placement_goal(_tools: Array[String]) -> int:
	return int(board["placement_goal"])

func gap_on_floor(index: int) -> bool:
	for value: Variant in board["gaps"]:
		if int(value) == index:
			return true
	return false

func entry_window() -> int:
	return -1

func shutter_window() -> int:
	return -1

func gallery_window() -> int:
	return -1

func gallery_regions() -> Array[int]:
	return []

func interior_region() -> int:
	return -1

func interior_floor() -> int:
	return -1

func completion_region() -> int:
	return [1, 1, 2][tutorial_step - 1]

func retired_bridge() -> int:
	return -1

func room_rect() -> Rect2:
	return Rect2()
