extends Control
## Small HUD compass: a stable objective arrow. It is intentionally not a
## minimap; it only answers "which way is the next useful thing?".

var _has_target := false
var _dir := Vector2.ZERO


func _ready() -> void:
	custom_minimum_size = Vector2(76, 76)
	queue_redraw()


## Called by the HUD each frame. `dir` is (target_world - player_world).
func set_aim(has_target: bool, dir: Vector2) -> void:
	_has_target = has_target
	_dir = dir
	queue_redraw()


func _draw() -> void:
	var side: float = minf(size.x, size.y)
	if side <= 4.0:
		return
	var r: float = maxf(side * 0.5 - 3.0, 12.0)
	var c := size * 0.5

	draw_circle(c, r, Color(0.045, 0.055, 0.055, 0.78))
	draw_arc(c, r - 2.0, 0.0, TAU, 56, Color(0.36, 0.55, 0.56, 0.85), 2.0, true)
	draw_arc(c, r - 7.0, -PI * 0.5 - 0.22, -PI * 0.5 + 0.22, 8, Color(1.0, 0.72, 0.32, 0.85), 2.0, true)

	var font := ThemeDB.fallback_font
	var fs := 11
	_label(font, fs, c + Vector2(0, -r + 12), "N", Color(1.0, 0.72, 0.32))
	_label(font, fs, c + Vector2(0, r - 3), "S", Color(0.62, 0.78, 0.78))
	_label(font, fs, c + Vector2(r - 8, 4), "E", Color(0.62, 0.78, 0.78))
	_label(font, fs, c + Vector2(-r + 8, 4), "W", Color(0.62, 0.78, 0.78))

	if _has_target and _dir.length() > 0.001:
		var d := _dir.normalized()
		var tip := c + d * (r - 10.0)
		var tail := c - d * 8.0
		var perp := Vector2(-d.y, d.x)
		draw_line(c - d * 2.0, tip - d * 6.0, Color(1.0, 0.78, 0.34, 0.78), 2.0, true)
		draw_colored_polygon(
			PackedVector2Array([tip, tail + perp * 6.0, tail - perp * 6.0]),
			Color(1.0, 0.82, 0.36, 0.98))
	else:
		draw_arc(c, r * 0.45, 0.0, TAU, 32, Color(0.62, 0.78, 0.78, 0.28), 2.0, true)

	draw_circle(c, 2.5, Color(0.82, 0.92, 0.88, 0.95))


func _label(font: Font, fs: int, pos: Vector2, txt: String, col: Color) -> void:
	var w := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(font, pos - Vector2(w * 0.5, 0.0), txt,
		HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
