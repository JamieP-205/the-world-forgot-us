class_name MemoryEcho
extends Interactable
## A memory echo: scan to reveal, then interact to recover it into the Archive.

## The echo this represents (assign a .tres per instance).
@export var echo_data: MemoryEchoData

## Alpha before the echo is revealed (barely perceptible).
@export var hidden_alpha: float = 0.06

var _revealed: bool = false
var _recovered: bool = false

@onready var _visual: Sprite2D = $Visual
@onready var _halo: Polygon2D = $Halo
@onready var _scannable: Scannable = $Scannable

## Base display scale of the echo-core sprite (its art is ~430px tall, so
## it renders at roughly the old polygon footprint). The reveal/recover
## tweens below scale relative to this.
const BASE_SCALE := Vector2(0.1, 0.1)


func _ready() -> void:
	_scannable.scanned.connect(_on_revealed)
	_visual.scale = BASE_SCALE
	_visual.modulate.a = hidden_alpha
	_halo.modulate.a = hidden_alpha


## Only interactable once scanned, and only until recovered.
func is_available() -> bool:
	return _revealed and not _recovered


func get_prompt() -> String:
	return "Recover memory: %s" % _echo_title()


func interact(_player: Node2D) -> void:
	if not is_available():
		return
	_recovered = true

	ArchiveSystem.record_echo(echo_data)
	if echo_data != null and echo_data.keepsake_item != &"":
		InventorySystem.add_item(echo_data.keepsake_item, 1)
	_scannable.remove_from_group("scannables")

	var text := echo_data.memory_text if echo_data != null else "You remember."
	EventBus.notice_posted.emit(
		"Echo recovered: %s\n%s\nFor a moment, the mast remembers warmth."
		% [_echo_title(), text])
	EventBus.camera_shake_requested.emit(2.5, 0.14)

	# Settle from the cyan of an unread echo to a warm, remembered glow.
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_visual, "modulate", Color(1.0, 0.92, 0.6, 0.85), 0.5)
	tween.tween_property(_halo, "modulate", Color(1.0, 0.78, 0.36, 0.42), 0.5)
	tween.tween_property(_visual, "scale", BASE_SCALE * 1.25, 0.5)


func _on_revealed() -> void:
	if _revealed:
		return
	_revealed = true
	EventBus.echo_revealed.emit(echo_data)
	EventBus.camera_shake_requested.emit(2.5, 0.12)
	var hint := echo_data.hint if echo_data != null else "A memory stirs here."
	EventBus.notice_posted.emit("Echo signal found by the fallen mast.\n%s" % hint)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_visual, "modulate", Color(0.55, 0.95, 0.95, 0.95), 0.25)
	tween.tween_property(_halo, "modulate", Color(0.32, 0.92, 1.0, 0.5), 0.25)
	tween.tween_property(_visual, "scale", BASE_SCALE * 2.25, 0.25)
	tween.chain().tween_property(_visual, "scale", BASE_SCALE * 1.45, 0.35)


func _echo_title() -> String:
	return echo_data.title if echo_data != null else "Unknown echo"
