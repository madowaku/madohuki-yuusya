class_name StageData
extends RefCounted

const FLOORS: Array[float] = [1070.0, 805.0, 540.0, 275.0]
const ANCHOR_INPUT_RADIUS: float = 44.0
const WINDOWS: Array[Dictionary] = [
	{"id": "A", "rect": Rect2(182, 876, 132, 158), "floor": 0, "kind": "mechanism"},
	{"id": "D", "rect": Rect2(412, 876, 132, 158), "floor": 0, "kind": "normal"},
	{"id": "B", "rect": Rect2(182, 611, 132, 158), "floor": 1, "kind": "normal"},
	{"id": "C", "rect": Rect2(412, 611, 132, 158), "floor": 1, "kind": "resident"},
	{"id": "E", "rect": Rect2(294, 346, 132, 158), "floor": 2, "kind": "normal"},
	{"id": "F", "rect": Rect2(294, 81, 132, 158), "floor": 3, "kind": "resident"},
]
const ANCHORS: Array[Dictionary] = [
	{"x": 114.0, "floor": 0, "unlock": 0},
	{"x": 606.0, "floor": 0, "unlock": 0},
	{"x": 224.0, "floor": 1, "unlock": 3},
	{"x": 496.0, "floor": 1, "unlock": 3},
	{"x": 228.0, "floor": 1, "unlock": 2, "horizontal": true},
	{"x": 228.0, "floor": 2, "unlock": 2, "horizontal": true},
	{"x": 112.0, "floor": 2, "unlock": 1},
	{"x": 608.0, "floor": 2, "unlock": 1},
]

static func is_horizontal_anchor(index: int) -> bool:
	return index >= 0 and index < ANCHORS.size() and bool(ANCHORS[index].get("horizontal", false))

static func window_rect(index: int) -> Rect2:
	return WINDOWS[index]["rect"]

static func anchor_base(index: int) -> Vector2:
	var anchor: Dictionary = ANCHORS[index]
	return Vector2(float(anchor["x"]), FLOORS[int(anchor["floor"])])

static func anchor_top(index: int) -> Vector2:
	if is_horizontal_anchor(index):
		return anchor_base(index) + Vector2(265, 0)
	return anchor_base(index) + Vector2(0, -265)
