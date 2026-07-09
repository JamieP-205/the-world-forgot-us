class_name MemoryEcho
extends Interactable
## A memory echo: scan to reveal, then interact to recover it into the Archive.

## The echo this represents (assign a .tres per instance).
@export var echo_data: MemoryEchoData

## Optional upgrade gate. Used in Pass 14 so the main echo gives scavenged
## battery/scrap an immediate purpose without adding another crafting system.
@export var required_upgrade_id: StringName = &""
@export_multiline var required_upgrade_notice: String = "The signal is too weak. Improve the Mnemoscope, then scan again."

## Alpha before the echo is revealed (barely perceptible).
@export var hidden_alpha: float = 0.05

var _revealed: bool = false
var _recovered: bool = false
var _blocked_pulse := false

@onready var _visual: Node2D = $Visual
@onready var _halo: Polygon2D = $Halo
@onready var _scannable: Scannable = $Scannable

const BASE_SCALE := Vector2(0.12, 0.12)
const POP_SCALE := Vector2(0.19, 0.19)
const REVEALED_SCALE := Vector2(0.145, 0.145)
const RECOVERED_SCALE := Vector2(0.135, 0.135)

var _idle_tween: Tween = null


func _ready() -> void:
	_scannable.scanned.connect(_on_revealed)
	_visual.scale = BASE_SCALE
	_visual.modulate = Color(0.4, 0.85, 0.9, hidden_alpha)
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
		"Echo recovered - %s.\n%s\nCarry it west to the Railhome and make the Radio Desk speak."
		% [_echo_title(), text])
	EventBus.camera_shake_requested.emit(3.0, 0.18)

	if _idle_tween != null and _idle_tween.is_valid():
		_idle_tween.kill()
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_visual, "modulate", Color(1.0, 0.86, 0.46, 0.95), 0.55)
	tween.tween_property(_halo, "modulate", Color(1.0, 0.72, 0.32, 0.48), 0.55)
	tween.tween_property(_visual, "scale", RECOVERED_SCALE, 0.55)


func _on_revealed() -> void:
	if _revealed or _recovered:
		return
	if _requires_upgrade():
		_show_blocked_signal()
		return
	_revealed = true
	EventBus.echo_revealed.emit(echo_data)
	EventBus.camera_shake_requested.emit(3.0, 0.16)
	EventBus.notice_posted.emit(
		"The strengthened Mnemoscope catches the broadcast. A cyan memory opens above the mast.\nStep into the light and press E to recover it.")
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_visual, "modulate", Color(0.46, 0.94, 0.96, 0.98), 0.22)
	tween.tween_property(_halo, "modulate", Color(0.26, 0.90, 1.0, 0.58), 0.22)
	tween.tween_property(_visual, "scale", POP_SCALE, 0.22)
	tween.chain().tween_property(_visual, "scale", REVEALED_SCALE, 0.34)
	_idle_tween = create_tween().set_loops()
	_idle_tween.tween_property(_halo, "modulate:a", 0.30, 1.0)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_idle_tween.tween_property(_halo, "modulate:a", 0.58, 1.0)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _requires_upgrade() -> bool:
	return required_upgrade_id != &"" and not BaseUpgradeSystem.is_built(required_upgrade_id)


func _show_blocked_signal() -> void:
	AudioManager.play(&"weak_signal")
	EventBus.notice_posted.emit(required_upgrade_notice)
	EventBus.camera_shake_requested.emit(1.5, 0.08)
	if _blocked_pulse:
		return
	_blocked_pulse = true
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_visual, "modulate", Color(0.34, 0.84, 0.88, 0.24), 0.14)
	tween.tween_property(_halo, "modulate", Color(0.24, 0.82, 0.92, 0.22), 0.14)
	tween.tween_property(_visual, "scale", BASE_SCALE * 1.25, 0.14)
	tween.chain().tween_property(_visual, "modulate:a", hidden_alpha, 0.35)
	tween.parallel().tween_property(_halo, "modulate:a", hidden_alpha, 0.35)
	tween.parallel().tween_property(_visual, "scale", BASE_SCALE, 0.35)
	tween.chain().tween_callback(func() -> void: _blocked_pulse = false)


func _echo_title() -> String:
	return echo_data.title if echo_data != null else "Unknown echo"
