class_name AuthoredLayout
extends TowerLayout
## Selects a data-authored optional or final challenge by stable stage ID.
const CHALLENGES: Dictionary = preload("res://resources/challenges_v1.json").data

func _init(requested_stage_id: String) -> void:
	super(1, 0)
	var selected: Dictionary = {}
	for board: Dictionary in CHALLENGES.get("boards", []):
		if str(board.get("stage_id", "")) == requested_stage_id:
			selected = board
			break
	if selected.is_empty():
		push_error("Unknown authored challenge: %s" % requested_stage_id)
		selected = CHALLENGES["boards"][0]
	configure_data(selected)
