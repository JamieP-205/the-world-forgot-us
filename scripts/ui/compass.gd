extends Control
## Small HUD compass: a fixed N/E/S/W ring plus an amber arrow that points
## toward the current objective. The world is top-down and unrotated, so screen
## up == North; the arrow direction is just (target - player) in world space.

var _has_target := false
var _dir := Vector2.ZERO


func _ready() -> void:
	# Redraw on demand; the HUD feeds us a fresh aim each frame.
	pass


## Called by the HUD each frame. `dir` is (target_world - player_world).
func set_aim(has_target: bool, dir: Vector2) -> void:
	_has_target = has_target
	_dir = dir
	queue_redraw()


func _draw() -> void:
	var r := size.x * 0.5
	var c := Vector2(r, r)

	# Backdrop + ring.
	draw_circle(c, r, Color(0.07, 0.09, 0.10, 0.62))
	draw_arc(c, r - 2.0, 0.0, TAU, 48, Color(0.40, 0.60, 0.62, 0.75), 2.0, true)

	var font := ThemeDB.fallback_font
	var fs := 12
	_label(font, fs, c + Vector2(0, -r + 11), "N", Color(0.95, 0.66, 0.36))
	_label(font, fs, c + Vector2(0, r - 2), "S", Color(0.68, 0.80, 0.80))
	_label(font, fs, c + Vector2(r - 7, 5), "E", Color(0.68, 0.80, 0.80))
	_label(font, fs, c + Vector2(-r + 7, 5), "W", Color(0.68, 0.80, 0.80))

	# Objective arrow.
	if _has_target and _dir.length() > 0.001:
		var d := _dir.normalized()
		var tip := c + d * (r - 9.0)
		var back := c - d * 3.0
		var perp := Vector2(-d.y, d.x) * 5.0
		draw_colored_polygon(
			PackedVector2Array([tip, back + perp, back - perp]),
			Color(1.0, 0.86, 0.42, 0.96))

	draw_circle(c, 2.5, Color(0.82, 0.92, 0.92, 0.95))


func _label(font: Font, fs: int, pos: Vector2, txt: String, col: Color) -> void:
	var w := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(font, pos - Vector2(w * 0.5, 0.0), txt,
		HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
