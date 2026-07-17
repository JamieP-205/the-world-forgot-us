extends Node2D
## Restrained texture-driven sweep feedback. The actual detection is still
## dispatched instantly through EventBus.scanner_pulsed.

## Seconds for the ring to expand and fade.
@export var duration: float = 0.62

var _max_radius: float = 220.0
var _elapsed: float = 0.0
var _active: bool = false

@onready var _ring: Sprite2D = $Ring
@onready var _dust: Sprite2D = $Dust


## Called by the scanner right after the pulse is added to the scene.
func start(max_radius: float) -> void:
	_max_radius = max_radius
	_active = true
	_ring.scale = Vector2.ONE * 0.035
	_ring.modulate.a = 0.32
	_dust.scale = Vector2.ONE * 0.055
	_dust.modulate.a = 0.09


func _process(delta: float) -> void:
	if not _active:
		return
	_elapsed += delta
	var t := clampf(_elapsed / maxf(duration, 0.001), 0.0, 1.0)
	var eased := ease(t, 0.72)
	var texture_size := _ring.texture.get_size().x if _ring.texture != null else 431.0
	var target_scale := (_max_radius * 2.0) / maxf(texture_size, 1.0)
	_ring.scale = Vector2.ONE * lerpf(0.035, target_scale, eased)
	_ring.modulate.a = (1.0 - t) * 0.32
	_ring.rotation = t * 0.045
	_dust.scale = Vector2.ONE * lerpf(0.055, target_scale * 0.76, eased)
	_dust.modulate.a = (1.0 - t) * 0.09
	if _elapsed >= duration:
		queue_free()
