class_name CastleRun
extends RefCounted
## A short run: three walls, two permanent-for-this-run gift choices.
const WALL_COUNT: int = 3
const GIFTS: Array[String] = ["reach", "recall", "soap"]
var castle_seed: int = 1729
var wall_index: int = 0
var gifts: Array[String] = []
var results: Array[Dictionary] = []
var previous_record: Dictionary = {}
var new_record: bool = false

func start(seed_value: int) -> void:
	castle_seed = clampi(seed_value, 1, 999999)
	wall_index = 0
	gifts.clear()
	results.clear()
	previous_record.clear()
	new_record = false

func layout() -> WallLayout:
	return WallLayout.new(castle_seed, wall_index)

func finish_wall(model: StageState) -> bool:
	if model.phase != "clear" or results.size() != wall_index:
		return false
	results.append({"moves": model.moves, "walking": snappedf(model.walking_distance / 26.5, 0.1), "climb": model.climb_distance / 26.5, "time": model.elapsed, "descents": model.descents, "bridges": model.bridge_moves, "goal": model.layout.placement_goal(gifts)})
	return true

func awaiting_gift() -> bool:
	return results.size() == wall_index + 1 and results.size() < WALL_COUNT

func available_gifts() -> Array[String]:
	var result: Array[String] = []
	for gift: String in GIFTS:
		if not gifts.has(gift):
			result.append(gift)
	return result

func choose_gift(gift: String) -> bool:
	if not awaiting_gift() or not available_gifts().has(gift):
		return false
	gifts.append(gift)
	wall_index += 1
	return true

func complete() -> bool:
	return results.size() == WALL_COUNT

func total(metric: String) -> float:
	var value: float = 0.0
	for result: Dictionary in results:
		value += float(result.get(metric, 0.0))
	return value

func beats(previous: Dictionary) -> bool:
	if previous.is_empty():
		return true
	if int(total("moves")) != int(previous.get("moves", 999)):
		return int(total("moves")) < int(previous.get("moves", 999))
	return total("walking") < float(previous.get("walking", INF)) - 0.05

func record() -> Dictionary:
	return {"moves": int(total("moves")), "walking": total("walking"), "time": total("time"), "gifts": gifts.duplicate()}

func record_key() -> String:
	# Different gift orders have different logical minima; compare like with like.
	return "%06d:%s" % [castle_seed, ">".join(gifts)]

func goals_met() -> int:
	var count: int = 0
	for result: Dictionary in results:
		if int(result["moves"]) <= int(result["goal"]):
			count += 1
	return count

func snapshot() -> Dictionary:
	return {"seed": castle_seed, "wall": wall_index + 1, "gifts": gifts.duplicate(), "offers": available_gifts() if awaiting_gift() else [], "complete": complete(), "results": results.duplicate(true)}

static func gift_name(gift: String, language: String) -> String:
	var names: Dictionary = {"reach": ["のびるスクイージー", "SKY SQUEEGEE"], "recall": ["おかえりフック", "HOMECOMING HOOK"], "soap": ["おすそわけの泡", "NEIGHBORLY BUBBLES"]}
	return str(names[gift][0 if language == "ja" else 1])

static func gift_description(gift: String, language: String) -> String:
	var descriptions: Dictionary = {
		"reach": ["城壁ごとに1枚だけ、一階上の窓を拭ける。", "Clean ONE upstairs window from below, each wall."],
		"recall": ["離れたハシゴを、その場で回収できる。", "Call your ladder back without walking to it."],
		"soap": ["拭き終わると、同じ階の隣の窓もひと拭き。", "Each clean sends a free swipe to its neighbor."]}
	return str(descriptions[gift][0 if language == "ja" else 1])
