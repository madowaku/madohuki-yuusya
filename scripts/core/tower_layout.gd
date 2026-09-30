class_name TowerLayout
extends WallLayout
## Authored geometry shared with the independent route solver.
const DATA: Dictionary = preload("res://resources/tower_v01.json").data
const HIT_SIZE: Vector2 = Vector2(88, 88)
const ENTRY: int = 7
const SHUTTER: int = 8
const GALLERY_KEY: int = 8

func _init(_castle_seed: int = 1, _wall_index: int = 0) -> void:
	windows.clear()
	anchor_x.clear()
	hook_keys.clear()
	required_window.clear()
	chapter = 2
	has_gap = true
	for item: Dictionary in DATA["windows"]:
		var rect: Array = item["rect"]
		windows.append(Rect2(float(rect[0]), float(rect[1]), float(rect[2]), float(rect[3])))
		required_window.append(-1)
	for item: Dictionary in DATA["anchors"]:
		anchor_x.append(float(item["base"][0]))
		hook_keys.append(int(item["key"]))

func window_floor(index: int) -> int:
	return int(DATA["windows"][index]["floor"])

func window_region(index: int) -> int:
	return int(DATA["windows"][index]["region"])

func window_kind(index: int) -> String:
	return str(DATA["windows"][index]["kind"])

func window_hit_rect(index: int) -> Rect2:
	var area: Rect2 = window_rect(index)
	var target_size: Vector2 = area.size.max(HIT_SIZE)
	return Rect2(area.get_center() - target_size * 0.5, target_size)

func floor_y(index: int) -> float:
	return float(DATA["floors"][index])

func region_floor(region: int) -> int:
	return [0, 1, 1, 2, 2, 3, 2][region]

func anchor_ends(index: int) -> Array[int]:
	var ends: Array = DATA["anchors"][index]["ends"]
	return [int(ends[0]), int(ends[1])]

func anchor_base(index: int) -> Vector2:
	var point: Array = DATA["anchors"][index]["base"]
	return Vector2(float(point[0]), float(point[1]))

func anchor_top(index: int) -> Vector2:
	var point: Array = DATA["anchors"][index]["top"]
	return Vector2(float(point[0]), float(point[1]))

func is_horizontal_anchor(index: int) -> bool:
	return index >= 0 and bool(DATA["anchors"][index].get("horizontal", false))

func anchor_count() -> int:
	return DATA["anchors"].size()

func title(language: String) -> String:
	return "灯りをつなぐ塔" if language == "ja" else "THE LANTERN TOWER"

func placement_goal(_tools: Array[String]) -> int:
	return int(DATA["placement_goal"])

func gap_on_floor(index: int) -> bool:
	return index in [1, 2]
