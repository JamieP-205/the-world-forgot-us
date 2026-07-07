extends Node2D
## Cosmetic expanding ring for scanner feedback. Grows from the origin to
## the pulse radius while fading out, then frees itself. Purely visual --
## the actual detection is done instantly via EventBus.scanner_pulsed.

## Seconds for the ring to expand and fade.
@export var duration: float = 0.62

var _max_radius: float = 220.0
var _elapsed: float = 0.0
var _active: bool = false


## Called by the scanner right after the pulse is added to the scene.
func start(max_radius: float) -> void:
	_max_radius = max_radius
	_active = true


func _process(delta: float) -> void:
	if not _active:
		return
	_elapsed += delta
	queue_redraw()
	if _elapsed >= duration:
		queue_free()


func _draw() -> void:
	var t: float = clampf(_elapsed / duration, 0.0, 1.0)
	var radius: float = maxf(_max_radius * t, 1.0)
	var alpha := (1.0 - t)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 72, Color(0.55, 0.96, 1.0, alpha * 0.95), 4.0, true)
	draw_arc(Vector2.ZERO, radius * 0.72, 0.0, TAU, 72, Color(0.32, 0.72, 0.88, alpha * 0.45), 2.0, true)
	draw_circle(Vector2.ZERO, maxf(18.0 * (1.0 - t), 1.0), Color(0.7, 1.0, 1.0, alpha * 0.22))
