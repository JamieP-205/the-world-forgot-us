class_name Scannable
extends Node2D
## Base for anything a scanner pulse can reveal or affect: memory echoes
## now, and later hidden enemies, weak points, locked signal panels, and
## corrupted machines.
##
## It listens for EventBus.scanner_pulsed and, when a pulse reaches it,
## fires scanned and calls the overridable _on_scanned(). Distance-based,
## so no collision shape is needed.

signal scanned

## True once this has been hit by at least one pulse.
var revealed: bool = false


func _ready() -> void:
	add_to_group("scannables")
	EventBus.scanner_pulsed.connect(_on_scanner_pulsed)


func _on_scanner_pulsed(origin: Vector2, radius: float) -> void:
	if global_position.distance_to(origin) > radius:
		return
	revealed = true
	EventBus.scannable_pinged.emit(global_position)
	scanned.emit()
	_on_scanned()


## Override in subclasses to react to being scanned.
func _on_scanned() -> void:
	pass
