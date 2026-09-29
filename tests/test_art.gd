extends SceneTree

var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	var records: Array = JSON.parse_string(FileAccess.get_file_as_string("res://assets/generated/production_prompts.json"))
	verify(records.size() == 21, "all 21 generated PNG deliverables recorded")
	for record: Dictionary in records:
		var path: String = "res://" + str(record["file"])
		var source: Image = Image.new()
		verify(source.load_png_from_buffer(FileAccess.get_file_as_bytes(path)) == OK, "PNG decodes: " + path)
		verify(source.detect_alpha() != Image.ALPHA_NONE, "alpha present: " + path)
		var transparent: bool = false
		var visible: bool = false
		for y: int in range(0, source.get_height(), 16):
			for x: int in range(0, source.get_width(), 16):
				var alpha: float = source.get_pixel(x, y).a
				transparent = transparent or alpha < 0.01
				visible = visible or alpha > 0.9
		verify(transparent and visible, "visible artwork with transparent background: " + path)
	var renderer: DirtArt = DirtArt.new()
	for index: int in 5:
		var mask: DirtMask = DirtMask.new()
		var dirty: Image = renderer.compose(index, mask)
		verify(not dirty.has_mipmaps(), "dynamic mask cannot sample stale mip levels")
		verify(dirty.get_size() == Vector2i(66, 80), "bounded runtime dirt texture")
		var hidden_work: bool = false
		for y: int in dirty.get_height():
			for x: int in dirty.get_width():
				hidden_work = hidden_work or dirty.get_pixel(x, y).a < 0.35
		verify(not hidden_work, "every dirty logical cell has a visible film")
		mask.cells[0] = 0
		var wiped: Image = renderer.compose(index, mask)
		verify(wiped.get_pixel(0, 0).a == 0 and wiped.get_pixel(1, 1).a == 0, "erased cell removes its full visible block")
		verify(wiped.get_pixel(2, 0).a >= 0.35, "adjacent dirty cell remains visible")
		mask.cells.fill(0)
		verify(renderer.compose(index, mask).is_invisible(), "no artwork remains after full clean")
	var characters: CharacterArt = CharacterArt.new()
	var model: StageState = StageState.new()
	verify(characters.hero_pose(model, false, false) == "carry_ladder", "carrying pose")
	verify(characters.hero_pose(model, true, false) == "wipe", "wipe overrides carry")
	model.ladder_anchor = 0
	verify(characters.hero_pose(model, false, true) == "place_ladder", "placement event pose")
	verify(characters.hero_pose(model, false, false) == "idle", "idle pose")
	model.walk_target += 100
	verify(characters.hero_pose(model, false, false) == "walk", "walking pose")
	model.climbing = true
	verify(characters.hero_pose(model, true, true) == "climb", "climb takes priority")
	print("[ART TEST] %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)

func verify(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)
