class_name TowerLayout
extends WallLayout
## Authored geometry shared with independent route solvers.
const DATA: Dictionary = preload("res://resources/tower_v01.json").data
const HIT_SIZE: Vector2 = Vector2(88, 88)
const ENTRY: int = 7
const SHUTTER: int = 8
const GALLERY_KEY: int = 8

var data: Dictionary = {}
var _region_floors: Array[int] = []
var _gap_floors: Array[int] = []

func _init(_castle_seed: int = 1, _wall_index: int = 0) -> void:
	super(_castle_seed, _wall_index)
	configure_data(DATA)

## Replace this layout's complete authored board while keeping TowerState's
## historic TowerLayout interface. TutorialLayout uses the same entry point.
func configure_data(board: Dictionary) -> void:
	data = board.duplicate(true)
	windows.clear()
	anchor_x.clear()
	hook_keys.clear()
	required_window.clear()
	_region_floors.clear()
	_gap_floors.clear()
	chapter = 2
	for item: Dictionary in data.get("windows", []):
		var rect: Array = item["rect"]
		windows.append(Rect2(float(rect[0]), float(rect[1]), float(rect[2]), float(rect[3])))
		required_window.append(int(item.get("requires_window", -1)))
	for item: Dictionary in data.get("anchors", []):
		var base: Array = item["base"]
		anchor_x.append(float(base[0]))
		hook_keys.append(int(item.get("requires_window", item.get("key", -1))))
	for value: Variant in data.get("region_floors", []):
		_region_floors.append(int(value))
	if _region_floors.is_empty():
		_region_floors = [0, 1, 1, 2, 2, 3, 2]
	for value: Variant in data.get("gaps", []):
		_gap_floors.append(int(value))
	if not data.has("gaps"):
		_gap_floors = [1, 2]
	has_gap = not _gap_floors.is_empty()
	required_window.resize(windows.size())

func window_floor(index: int) -> int:
	return int(data["windows"][index]["floor"])

func window_region(index: int) -> int:
	return int(data["windows"][index]["region"])

func window_kind(index: int) -> String:
	return str(data["windows"][index].get("kind", "normal"))

func window_requirement(index: int) -> int:
	return int(data["windows"][index].get("requires_window", -1))

func window_requires_all_other(index: int) -> bool:
	return bool(data["windows"][index].get("requires_all_other", false))

func window_hit_rect(index: int) -> Rect2:
	var area: Rect2 = window_rect(index)
	var target_size: Vector2 = area.size.max(HIT_SIZE)
	return Rect2(area.get_center() - target_size * 0.5, target_size)

func floor_y(index: int) -> float:
	return float(data["floors"][index])

func floor_count() -> int:
	return data.get("floors", []).size()

func region_floor(region: int) -> int:
	return int(_region_floors[region]) if region >= 0 and region < _region_floors.size() else 0

func region_count() -> int:
	return _region_floors.size()

func anchor_ends(index: int) -> Array[int]:
	var ends: Array = data["anchors"][index]["ends"]
	return [int(ends[0]), int(ends[1])]

func anchor_base(index: int) -> Vector2:
	var point: Array = data["anchors"][index]["base"]
	return Vector2(float(point[0]), float(point[1]))

func anchor_top(index: int) -> Vector2:
	var point: Array = data["anchors"][index]["top"]
	return Vector2(float(point[0]), float(point[1]))

func is_horizontal_anchor(index: int) -> bool:
	return index >= 0 and index < anchor_count() and bool(data["anchors"][index].get("horizontal", false))

func anchor_requirement(index: int) -> int:
	var item: Dictionary = data["anchors"][index]
	return int(item.get("requires_window", item.get("key", -1)))

func anchor_count() -> int:
	return data.get("anchors", []).size()

func stage_id() -> String:
	return str(data.get("stage_id", "tower_v01"))

func title(language: String) -> String:
	var names: Dictionary = data.get("title", {})
	return str(names.get("ja", "灯りをつなぐ塔")) if language == "ja" else str(names.get("en", "THE LANTERN TOWER"))

func initial_hero() -> Vector2:
	var point: Array = data.get("initial_hero", [248, floor_y(0)])
	return Vector2(float(point[0]), float(point[1]))

func initial_region() -> int:
	return int(data.get("initial_region", 0))

func visible_floors() -> Array[int]:
	var result: Array[int] = []
	var values: Array = data.get("visible_floors", [])
	if values.is_empty():
		for index: int in floor_count():
			result.append(index)
		return result
	for value: Variant in values:
		result.append(int(value))
	return result

func entry_window() -> int:
	return int(data.get("entry", 7))

func shutter_window() -> int:
	return int(data.get("shutter", 8))

func gallery_window() -> int:
	return int(data.get("gallery_key", 8))

func gallery_regions() -> Array[int]:
	var result: Array[int] = []
	var values: Array = data.get("gallery_regions", [1, 2])
	for value: Variant in values:
		result.append(int(value))
	return result

func interior_region() -> int:
	return int(data.get("interior_region", 6))

func interior_floor() -> int:
	return int(data.get("interior_floor", 2))

func completion_region() -> int:
	return int(data.get("completion_region", 5))

func retired_bridge() -> int:
	return int(data.get("retired_bridge", 4))

func room_rect() -> Rect2:
	var values: Array = data.get("room_rect", [265, 435, 295, 181])
	return Rect2(float(values[0]), float(values[1]), float(values[2]), float(values[3]))

func placement_goal(_tools: Array[String]) -> int:
	return int(data.get("placement_goal", 0))

func gap_on_floor(index: int) -> bool:
	return index in _gap_floors
