extends Node2D
## Editor-only contact review. Open this scene and F6; click to change page.
const FONT: Font = preload("res://assets/fonts/MPLUSRounded1c-Regular.ttf")
var page: int = 0
var art: CharacterArt = CharacterArt.new()
var environment: EnvironmentArt = EnvironmentArt.new()
var dirt: DirtArt = DirtArt.new()
var concepts: Dictionary[String, Texture2D] = {}
var dirt_previews: Array[ImageTexture] = []

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	for key: String in ["item_legendary_ladder", "window_heart_concept", "window_heart_clean_hint"]:
		var category: String = "items" if key.begins_with("item") else "windows"
		concepts[key] = load("res://assets/generated/raw/%s/%s_v01.png" % [category, key])
	for key: String in ["style_reference", "color_palette_reference"]:
		concepts[key] = load("res://assets/reference/%s_v01.png" % key)
	for index: int in 5:
		dirt_previews.append(ImageTexture.create_from_image(dirt.compose(index, DirtMask.new())))
	if "--capture-art" in OS.get_cmdline_user_args():
		_capture.call_deferred()

func _unhandled_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
		page = (page + 1) % 3
		queue_redraw()

func _capture() -> void:
	DirAccess.make_dir_recursive_absolute("res://output/art-review")
	for index: int in 3:
		page = index
		queue_redraw()
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var captured: Image = get_viewport().get_texture().get_image()
		var code: Error = captured.save_png("res://output/art-review/godot-page-%d.png" % (page + 1))
		assert(code == OK)
	print("[ART REVIEW] Captured 3 Godot pages")
	get_tree().quit()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 720, 1280), Color("243844"))
	_label(Vector2(30, 55), "窓ふき勇者  /  ASSET REVIEW v0.1", 28)
	_label(Vector2(30, 95), "クリック / タップで次のページ   %d / 3" % (page + 1), 20)
	match page:
		0:
			var poses: Array[String] = ["idle", "walk", "carry_ladder", "place_ladder", "climb", "wipe"]
			for index: int in 6:
				var p: Vector2 = Vector2(126 + index % 3 * 232, 320 + floori(index / 3.0) * 260)
				environment.wall(self, Rect2(p - Vector2(102, 166), Vector2(204, 180)))
				art.draw_hero(self, poses[index], p, 1.0)
				_label(p + Vector2(-90, 50), poses[index], 19)
			_label(Vector2(30, 696), "HERO 100px / mobile 50px · 足元を揃えて表示", 21)
			var emotions: Array[String] = ["neutral", "surprised", "happy"]
			for index: int in 3:
				var p: Vector2 = Vector2(126 + index * 232, 946)
				var area: Rect2 = Rect2(p - Vector2(66, 142), Vector2(132, 158))
				draw_rect(area, Color("c99060"))
				environment.window_frame(self, area)
				art.draw_resident(self, emotions[index], p)
				_label(p + Vector2(-90, 63), emotions[index], 19)
			_label(Vector2(30, 1120), "GOBLIN 112px / mobile 56px · CLEANで笑顔へ", 21)
			_label(Vector2(30, 1170), "背景・枠：Kenney CC0 / キャラ：生成原画", 20)
		1:
			_label(Vector2(30, 150), "5つの汚れ / 消去マスク共通", 24)
			for index: int in 5:
				var area: Rect2 = Rect2(28 + index * 139, 190, 112, 150)
				draw_rect(area, Color("e8bd70"))
				art.draw_resident(self, "happy", Vector2(area.get_center().x, area.end.y - 3))
				draw_texture_rect(dirt_previews[index], area, false)
				environment.window_frame(self, area)
				_label(Vector2(area.position.x, 385), DirtArt.KINDS[index], 19)
			_label(Vector2(30, 460), "終盤用コンセプト / 5窓スライスの進行には未追加", 21)
			_fit(concepts["window_heart_concept"], Rect2(25, 520, 222, 430))
			_fit(concepts["window_heart_clean_hint"], Rect2(254, 520, 222, 430))
			_fit(concepts["item_legendary_ladder"], Rect2(496, 490, 194, 520))
			_label(Vector2(30, 1030), "HEART / before → after", 22)
			_label(Vector2(487, 1070), "伝説のハシゴ", 22)
			_label(Vector2(30, 1150), "汚れPNG＋薄膜 → 見えない清掃判定を防ぐ", 21)
		2:
			_fit(concepts["style_reference"], Rect2(45, 135, 630, 525))
			_fit(concepts["color_palette_reference"], Rect2(50, 700, 620, 470))
			_label(Vector2(30, 1240), "正確な色値：assets/reference/palette.json", 20)

func _fit(texture: Texture2D, area: Rect2) -> void:
	var factor: float = minf(area.size.x / texture.get_width(), area.size.y / texture.get_height())
	var size: Vector2 = texture.get_size() * factor
	draw_texture_rect(texture, Rect2(area.get_center() - size / 2, size), false)

func _label(point: Vector2, text: String, font_size: int) -> void:
	draw_string(FONT, point, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("f3e3b5"))
