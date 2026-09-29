class_name DirtArt
extends RefCounted
## One visible film per logical cell prevents transparent art from hiding work.
const KINDS: Array[String] = ["soot", "mud", "streak", "bird", "magic"]
const SCALE: int = 2
var bases: Array[Image] = []

func _init() -> void:
	for kind: String in KINDS:
		var texture: Texture2D = load("res://assets/generated/raw/windows/dirt_%s_v01.png" % kind)
		var source: Image = texture.get_image()
		# This small dynamic texture must not retain stale pre-wipe mip levels.
		source.clear_mipmaps()
		source.convert(Image.FORMAT_RGBA8)
		source.resize(DirtMask.WIDTH * SCALE, DirtMask.HEIGHT * SCALE, Image.INTERPOLATE_LANCZOS)
		for y: int in source.get_height():
			for x: int in source.get_width():
				var pigment: Color = source.get_pixel(x, y)
				var film: Color = Color("53666b").lerp(Color(pigment.r, pigment.g, pigment.b), pigment.a)
				film.a = 0.38 + pigment.a * 0.58
				source.set_pixel(x, y, film)
		bases.append(source)

func compose(index: int, mask: DirtMask) -> Image:
	var result: Image = bases[index].duplicate()
	for y: int in DirtMask.HEIGHT:
		for x: int in DirtMask.WIDTH:
			if mask.cells[y * DirtMask.WIDTH + x] == 0:
				result.fill_rect(Rect2i(x * SCALE, y * SCALE, SCALE, SCALE), Color.TRANSPARENT)
	return result
