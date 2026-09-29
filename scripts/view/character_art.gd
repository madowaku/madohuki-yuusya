class_name CharacterArt
extends RefCounted
## Presentation only: raw PNGs remain intact; Godot aligns their visible bounds.

var heroes: Dictionary[String, Texture2D] = {}
var residents: Dictionary[String, Texture2D] = {}
var bounds: Dictionary[String, Rect2] = {}

func _init() -> void:
	for pose: String in ["idle", "walk", "carry_ladder", "place_ladder", "climb", "wipe"]:
		var texture: Texture2D = load("res://assets/generated/raw/hero/hero_%s_v01.png" % pose)
		heroes[pose] = texture
		bounds[pose] = Rect2(texture.get_image().get_used_rect())
	for emotion: String in ["neutral", "surprised", "happy"]:
		var texture: Texture2D = load("res://assets/generated/raw/npc/npc_goblin_merchant_%s_v01.png" % emotion)
		residents[emotion] = texture
		bounds[emotion] = Rect2(texture.get_image().get_used_rect())

func hero_pose(model: StageState, wiping: bool, placing: bool) -> String:
	if model.climbing:
		return "walk" if model.layout.is_horizontal_anchor(model.ladder_anchor) else "climb"
	if wiping:
		return "wipe"
	if placing:
		return "place_ladder"
	if model.ladder_anchor == -1:
		return "carry_ladder"
	if absf(model.walk_target - model.hero.x) > 2.0:
		return "walk"
	return "idle"

func draw_hero(canvas: CanvasItem, pose: String, feet: Vector2, facing: float) -> void:
	_draw_aligned(canvas, heroes[pose], bounds[pose], feet, 100.0, facing)

func draw_resident(canvas: CanvasItem, emotion: String, feet: Vector2) -> void:
	_draw_aligned(canvas, residents[emotion], bounds[emotion], feet, 112.0, 1.0)

func _draw_aligned(canvas: CanvasItem, texture: Texture2D, source: Rect2, feet: Vector2, height: float, facing: float) -> void:
	var size: Vector2 = source.size * height / source.size.y
	# Horizontal mirroring around the feet preserves the ground contact point.
	canvas.draw_set_transform(feet, 0.0, Vector2(facing, 1.0))
	canvas.draw_texture_rect_region(texture, Rect2(Vector2(-size.x * 0.5, -height), size), source)
	canvas.draw_set_transform(Vector2.ZERO)
