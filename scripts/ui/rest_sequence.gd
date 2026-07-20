class_name RestSequence
extends CanvasLayer
## A short in-world rest and tape-decoding transition.

signal finished

@onready var _backdrop: ColorRect = $Backdrop
@onready var _card: PanelContainer = $Card
@onready var _clock: Label = $Card/Margin/Copy/Clock
@onready var _status: Label = $Card/Margin/Copy/Status
@onready var _fragment: Label = $Card/Margin/Copy/Fragment
@onready var _progress: ProgressBar = $Card/Margin/Copy/Progress
@onready var _trace: Line2D = $Card/Margin/Copy/Trace
@onready var _recorder: Control = $Card/Margin/Copy/Recorder

var _decoding := false
var _elapsed := 0.0


func begin(decoding: bool) -> void:
	_decoding = decoding
	process_mode = Node.PROCESS_MODE_ALWAYS
	_backdrop.modulate.a = 0.0
	_card.modulate.a = 0.0
	_progress.visible = decoding
	_recorder.set("decoding", decoding)
	_recorder.set("progress", 0.0)
	_fragment.text = ""
	_clock.text = "04:17  /  RAIN ON THE ROOF"
	_status.text = "Boots off. Door barred. Receiver listening."
	AudioManager.play(&"rest", -2.0, 0.82)
	var viewport_size := get_viewport().get_visible_rect().size
	var fit := minf(1.0, minf(
		(viewport_size.x - 24.0) / 660.0,
		(viewport_size.y - 24.0) / 330.0))
	_card.scale = Vector2.ONE * maxf(fit, 0.46)
	var fade_in := create_tween().set_parallel(true)
	fade_in.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade_in.tween_property(_backdrop, "modulate:a", 0.96, 0.48)
	fade_in.tween_property(_card, "modulate:a", 1.0, 0.48)
	await fade_in.finished

	if decoding:
		await _run_decode()
	else:
		await get_tree().create_timer(0.9, true, false, true).timeout

	_clock.text = "06:41  /  FIRST LIGHT"
	_status.text = "The carriage is quiet. The door is still barred."
	await get_tree().create_timer(0.62, true, false, true).timeout
	var fade_out := create_tween().set_parallel(true)
	fade_out.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade_out.tween_property(_backdrop, "modulate:a", 0.0, 0.42)
	fade_out.tween_property(_card, "modulate:a", 0.0, 0.34)
	await fade_out.finished
	finished.emit()
	queue_free()


func _run_decode() -> void:
	_status.text = "TAPE DECODE  /  separating voice from carrier"
	_progress.value = 0.0
	AudioManager.play(&"radio_static", -8.0, 0.74)
	var decode := create_tween()
	decode.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	decode.tween_property(_progress, "value", 36.0, 0.62)
	decode.tween_callback(func() -> void: _fragment.text = "FOURTEEN B")
	decode.tween_property(_progress, "value", 68.0, 0.66)
	decode.tween_callback(func() -> void: _fragment.text = "YELLOW LEAD")
	decode.tween_property(_progress, "value", 100.0, 0.72)
	decode.tween_callback(func() -> void:
		_fragment.text = "COME NORTH  /  VOICE LAYER DOES NOT MATCH BREATH"
		AudioManager.play(&"objective", -4.0, 0.84)
	)
	await decode.finished
	await get_tree().create_timer(0.72, true, false, true).timeout


func _process(delta: float) -> void:
	_elapsed += delta
	if _recorder != null:
		_recorder.set("progress", _progress.value)
	if _trace == null:
		return
	var points := PackedVector2Array()
	for index in 49:
		var x := float(index) * 12.0
		var envelope := 4.0 + 8.0 * sin(float(index) * 0.41 + _elapsed * 2.1)
		var y := sin(float(index) * 1.73 + _elapsed * 5.4) * envelope
		points.append(Vector2(x, y))
	_trace.points = points
