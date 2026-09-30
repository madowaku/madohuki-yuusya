class_name CampaignRun
extends RefCounted
## Small authored sequence controller; each board remains a separate gameplay state.

const DEFAULT_STAGE_IDS: Array[String] = ["tutorial_1", "tutorial_2", "tutorial_3", "tower"]
const DEFAULT_STAGE_LABELS: Array[String] = ["T1", "T2", "T3", "Tower"]
const FULL_STAGE_IDS: Array[String] = ["tutorial_1", "tutorial_2", "tutorial_3", "switchback", "gallery_return", "tower", "heart_window"]
const FULL_STAGE_LABELS: Array[String] = ["T1", "T2", "T3", "1F", "2F", "Tower", "Heart"]
const CLEAN_PAUSE_DURATION: float = 0.6
const ASCENT_DURATION: float = 1.4

var active: bool = false
var index: int = -1
var stage_ids: Array[String] = []
var labels: Array[String] = []
var completed_records: Array[Dictionary] = []
var flow_phase: String = "idle"
var phase_elapsed: float = 0.0
var pending_record: Dictionary = {}

func begin(sequence: Array[String] = [], stage_labels: Array[String] = []) -> String:
	active = true
	index = 0
	stage_ids = sequence.duplicate() if not sequence.is_empty() else DEFAULT_STAGE_IDS.duplicate()
	labels = stage_labels.duplicate()
	if labels.size() != stage_ids.size():
		labels.clear()
		for stage_id: String in stage_ids:
			labels.append(_label_for(stage_id))
	completed_records.clear()
	pending_record.clear()
	phase_elapsed = 0.0
	flow_phase = "stage" if not stage_ids.is_empty() else "ending"
	return current_stage_id()

func _label_for(stage_id: String) -> String:
	match stage_id:
		"tutorial_1": return "T1"
		"tutorial_2": return "T2"
		"tutorial_3": return "T3"
		"switchback": return "1F"
		"gallery_return": return "2F"
		"tower": return "Tower"
		"heart_window": return "Heart"
		_: return stage_id

func current_stage_id() -> String:
	if index < 0 or index >= stage_ids.size():
		return "ending" if flow_phase == "ending" else ""
	return stage_ids[index]

func current_label() -> String:
	if index < 0 or index >= labels.size():
		return "Ending" if flow_phase == "ending" else ""
	return labels[index]

func make_record(state: StageState) -> Dictionary:
	return {
		"stage_id": current_stage_id(),
		"label": current_label(),
		"cleaned": state.cleaned_count(),
		"windows": state.masks.size(),
		"placements": state.moves,
		"minimum_placements": state.layout.placement_goal(state.gifts),
		"bridge_moves": state.bridge_moves,
	}

func start_clear(record: Dictionary) -> bool:
	if not active or flow_phase != "stage" or current_stage_id().is_empty():
		return false
	pending_record = record.duplicate(true)
	phase_elapsed = 0.0
	flow_phase = "clean_pause"
	return true

func tick(delta: float, frozen: bool = false) -> String:
	if not active or frozen or delta <= 0.0:
		return ""
	if flow_phase == "clean_pause":
		phase_elapsed += delta
		if phase_elapsed >= CLEAN_PAUSE_DURATION:
			phase_elapsed = 0.0
			flow_phase = "ascent"
			return "ascent_started"
	elif flow_phase == "ascent":
		phase_elapsed += delta
		if phase_elapsed >= ASCENT_DURATION:
			return advance()
	return ""

func advance() -> String:
	if not active:
		return ""
	if not pending_record.is_empty():
		completed_records.append(pending_record.duplicate(true))
	pending_record.clear()
	index += 1
	phase_elapsed = 0.0
	if index >= stage_ids.size():
		flow_phase = "ending"
		return "ending"
	flow_phase = "stage"
	return current_stage_id()

func cancel_transition() -> bool:
	if flow_phase not in ["clean_pause", "ascent"]:
		return false
	phase_elapsed = 0.0
	flow_phase = "stage"
	pending_record.clear()
	return true

func restart_current() -> String:
	if not active or index < 0 or index >= stage_ids.size():
		return ""
	phase_elapsed = 0.0
	flow_phase = "stage"
	pending_record.clear()
	return current_stage_id()

func stop() -> void:
	active = false
	flow_phase = "idle"
	phase_elapsed = 0.0
	pending_record.clear()

func ending_stats() -> Dictionary:
	var total_windows: int = 0
	var total_placements: int = 0
	var total_minimum: int = 0
	var tower_windows: int = 0
	var tower_placements: int = 0
	var tower_minimum: int = 0
	for record: Dictionary in completed_records:
		total_windows += int(record.get("windows", 0))
		total_placements += int(record.get("placements", 0))
		total_minimum += int(record.get("minimum_placements", 0))
		if str(record.get("stage_id", "")) == "tower":
			tower_windows = int(record.get("windows", 0))
			tower_placements = int(record.get("placements", 0))
			tower_minimum = int(record.get("minimum_placements", 0))
	return {
		"completed_stages": completed_records.size(),
		"total_windows": total_windows,
		"total_placements": total_placements,
		"total_minimum": total_minimum,
		"tower_windows": tower_windows,
		"tower_placements": tower_placements,
		"tower_minimum": tower_minimum,
		"records": completed_records.duplicate(true),
	}

func snapshot() -> Dictionary:
	var progress: float = 0.0
	if flow_phase == "ascent":
		progress = clampf(phase_elapsed / ASCENT_DURATION, 0.0, 1.0)
	return {
		"campaign_active": active,
		"stage_index": index,
		"stage_count": stage_ids.size(),
		"stage_id": current_stage_id(),
		"stage_label": current_label(),
		"stage_ids": stage_ids.duplicate(),
		"completed_records": completed_records.duplicate(true),
		"flow_phase": flow_phase,
		"flow_elapsed": phase_elapsed,
		"clean_pause_duration": CLEAN_PAUSE_DURATION,
		"ascent_elapsed": phase_elapsed if flow_phase == "ascent" else 0.0,
		"ascent_duration": ASCENT_DURATION,
		"ascent_progress": progress,
		"ending_stats": ending_stats(),
	}
