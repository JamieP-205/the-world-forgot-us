extends Node2D
## Content pass scene glue for the current hand-built demo map.

@onready var _mast_glow: Polygon2D = $RadioMast/RecoveredGlow
@onready var _spark_a: Polygon2D = $RadioMast/StaticSparkA
@onready var _spark_b: Polygon2D = $RadioMast/StaticSparkB
@onready var _spark_c: Polygon2D = $RadioMast/StaticSparkC
@onready var _north_signal: Node2D = $NorthSignal

var _time := 0.0
var _recovered := false


func _ready() -> void:
	ArchiveSystem.echo_recorded.connect(_on_echo_recorded)
	if ArchiveSystem.has_echo(&"echo_last_signal"):
		_apply_mast_recovered()
	# Once the Radio Desk is online, a new signal shows itself in the north.
	_north_signal.visible = BaseUpgradeSystem.is_built(&"radio_desk")
	if _north_signal.visible:
		_maybe_show_ending_hook()


func _process(delta: float) -> void:
	_time += delta
	var cold_alpha := 0.34 + sin(_time * 4.1) * 0.12
	if _recovered:
		var warm_alpha := 0.24 + sin(_time * 2.3) * 0.08
		_mast_glow.color = Color(1.0, 0.86, 0.42, warm_alpha)
	else:
		_spark_a.color.a = cold_alpha
		_spark_b.color.a = cold_alpha * 0.8
		_spark_c.color.a = cold_alpha * 0.65
	if _north_signal.visible:
		_north_signal.modulate.a = 0.6 + sin(_time * 3.0) * 0.32


## The demo's ending hook: after the player has built the Radio Desk AND
## rested/saved, returning to the world reveals a louder, wrong signal from
## the north -- the promise of the next zone. Shown once per session.
func _maybe_show_ending_hook() -> void:
	if WorldState.ending_hook_shown:
		return
	if not SaveManager.has_save():
		return  # only after the safe pause at the bedroll
	WorldState.ending_hook_shown = true
	var msg := "A NEW SIGNAL claws in from the north - louder than the last, and wrong somewhere underneath.\n\"...come north... it isn't finished forgetting...\"\nThe next road is out there, and it is already changing."
	if BaseUpgradeSystem.is_built(&"route_beacon"):
		msg += "\nBehind you the beacon burns steady. The way home, at least, will keep."
	AudioManager.play(&"ending")
	EventBus.notice_posted.emit(msg)
	EventBus.camera_shake_requested.emit(2.0, 0.16)


func _on_echo_recorded(data: MemoryEchoData) -> void:
	if data != null and data.id == &"echo_last_signal":
		_apply_mast_recovered()


func _apply_mast_recovered() -> void:
	_recovered = true
	_mast_glow.visible = true
	_spark_a.color = Color(1.0, 0.86, 0.42, 0.75)
	_spark_b.color = Color(1.0, 0.86, 0.42, 0.65)
	_spark_c.color = Color(1.0, 0.86, 0.42, 0.55)
