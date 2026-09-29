class_name DirtMask
extends RefCounted

const WIDTH: int = 33
const HEIGHT: int = 40
const FINISH_FRACTION: float = 0.055
var cells: PackedByteArray = PackedByteArray()
var remaining: int = WIDTH * HEIGHT
var revision: int = 0

func _init() -> void:
	cells.resize(WIDTH * HEIGHT)
	cells.fill(1)

func fraction() -> float:
	return float(remaining) / float(WIDTH * HEIGHT)

func erase_segment(from: Vector2, to: Vector2, area: Rect2, radius: float = 32.0) -> int:
	var erased: int = 0
	var low: Vector2 = (from.min(to) - area.position - Vector2.ONE * radius) / area.size
	var high: Vector2 = (from.max(to) - area.position + Vector2.ONE * radius) / area.size
	var x0: int = clampi(int(floor(low.x * WIDTH)), 0, WIDTH - 1)
	var x1: int = clampi(int(ceil(high.x * WIDTH)), 0, WIDTH - 1)
	var y0: int = clampi(int(floor(low.y * HEIGHT)), 0, HEIGHT - 1)
	var y1: int = clampi(int(ceil(high.y * HEIGHT)), 0, HEIGHT - 1)
	for y: int in range(y0, y1 + 1):
		for x: int in range(x0, x1 + 1):
			var cell_index: int = y * WIDTH + x
			if cells[cell_index] == 0:
				continue
			var point: Vector2 = area.position + Vector2((x + 0.5) / WIDTH, (y + 0.5) / HEIGHT) * area.size
			if point.distance_squared_to(Geometry2D.get_closest_point_to_segment(point, from, to)) <= radius * radius:
				cells[cell_index] = 0
				erased += 1
	remaining -= erased
	if remaining > 0 and fraction() <= FINISH_FRACTION:
		erased += remaining
		remaining = 0
		cells.fill(0)
	if erased > 0:
		revision += 1
	return erased
