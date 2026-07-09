class_name MemoryEcho
extends Interactable
## A memory echo: scan to reveal, then interact to recover it into the Archive.

## The echo this represents (assign a .tres per instance).
@export var echo_data: MemoryEchoData

## Alpha before the echo is revealed (barely perceptible).
@export var hidden_alpha: float = 0.06

var _revealed: bool = false
var _recovered: bool = false

@onready var _visual: Node2D = $Visual
@onready var _halo: Polygon2D = $Halo
@onready var _scannable: Scannable = $Scannable

## Base display scale of the echo-core sprite. Its art is ~430px tall, so a
## small base keeps the revealed echo a readable ~55px on screen (it used to
## balloon to ~950px). The reveal/recover tweens scale RELATIVE to this.
const BASE_SCALE := Vector2(0.13, 0.13)
## Reveal pops slightly bigger, then settles just above base; recovery rests
## right at base. All expressed as multiples of BASE_SCALE so nothing is huge.
const POP_SCALE := Vector2(0.2, 0.2)
const REVEALED_SCALE := Vector2(0.15, 0.15)
const RECOVERED_SCALE := Vector2(0.14, 0.14)

var _idle_tween: Tween = null


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

	AudioManager.play(&"echo_recover")
	var text := echo_data.memory_text if echo_data != null else "You remember."
	EventBus.notice_posted.emit(
		"Echo recovered - %s.\n%s\nThe mast glows warm behind you. Carry this home, west, to the Railhome."
		% [_echo_title(), text])
	EventBus.camera_shake_requested.emit(2.5, 0.14)

	# Settle from the cyan of an unread echo to a warm, remembered glow.
	if _idle_tween != null and _idle_tween.is_valid():
		_idle_tween.kill()
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_visual, "modulate", Color(1.0, 0.92, 0.6, 0.9), 0.5)
	tween.tween_property(_halo, "modulate", Color(1.0, 0.78, 0.36, 0.4), 0.5)
	tween.tween_property(_visual, "scale", RECOVERED_SCALE, 0.5)


func _on_revealed() -> void:
	if _revealed:
		return
	_revealed = true
	EventBus.echo_revealed.emit(echo_data)
	EventBus.camera_shake_requested.emit(2.5, 0.12)
	EventBus.notice_posted.emit(
		"A cyan echo tears free above the fallen mast - a voice from the night everyone left.\nStep into the light and press E to recover it.")
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_visual, "modulate", Color(0.55, 0.95, 0.95, 0.95), 0.25)
	tween.tween_property(_halo, "modulate", Color(0.32, 0.92, 1.0, 0.5), 0.25)
	tween.tween_property(_visual, "scale", POP_SCALE, 0.25)
	tween.chain().tween_property(_visual, "scale", REVEALED_SCALE, 0.35)
	# Gentle idle breathing so the revealed echo reads as alive, not static.
	_idle_tween = create_tween().set_loops()
	_idle_tween.tween_property(_halo, "modulate:a", 0.28, 1.1)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_idle_tween.tween_property(_halo, "modulate:a", 0.5, 1.1)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _echo_title() -> String:
	return echo_data.title if echo_data != null else "Unknown echo"
