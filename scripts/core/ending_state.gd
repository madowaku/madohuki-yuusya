class_name EndingState
extends StageState
## Non-interactive ending beat. The view owns its presentation; this state owns timing and summary data.

const FINAL_READY_SECONDS: float = 7.0

var animation_time: float = 0.0
var final_ready: bool = false
var campaign_stats: Dictionary = {}

func configure_ending(stats: Dictionary) -> void:
	campaign_stats = stats.duplicate(true)
	animation_time = 0.0
	final_ready = false
	phase = "ending"
	paused = false
	masks.clear()
	changed.emit()

func can_act() -> bool:
	return false

func tick(delta: float) -> void:
	if phase != "ending" or paused or final_ready or delta <= 0.0:
		return
	animation_time += delta
	if animation_time >= FINAL_READY_SECONDS:
		animation_time = FINAL_READY_SECONDS
		final_ready = true
		changed.emit()

func set_paused(value: bool) -> void:
	if paused == value:
		return
	paused = value
	changed.emit()

func snapshot() -> Dictionary:
	var result: Dictionary = super.snapshot()
	result.merge({
		"ending": true,
		"phase": "ending",
		"animation_time": animation_time,
		"final_ready": final_ready,
		"ending_stats": campaign_stats.duplicate(true),
	}, true)
	return result
