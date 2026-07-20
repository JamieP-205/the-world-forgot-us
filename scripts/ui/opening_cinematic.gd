extends Control

signal finished

const TOUCH_DEBOUNCE_MSEC := 320
const PHONE_PORTRAIT_CARD := Vector2(390.0, 320.0)
const PHONE_LANDSCAPE_CARD := Vector2(820.0, 184.0)

const BEATS := [
	{"stamp": "Cullbrook / 02:03", "title": "The receiver has been unplugged for three years.", "body": "It switches itself on. A woman says, \"Ellie. Fourteen B. Yellow lead. Do not let it finish the sentence.\"", "duration": 5.2},
	{"stamp": "Carriage 317", "title": "The voice belongs to Maggie. Maggie vanished eighteen years ago.", "body": "Nobody else knew the yellow-lead joke. But the recording contains the same breath twice, perfectly identical.", "duration": 5.4},
	{"stamp": "Cullbrook service road", "title": "A dead payphone rings once.", "body": "In its glass, Ellie's reflection lifts the receiver before she does. Her own set burns out its Search Coil. The signal moves to the fallen radio mast.", "duration": 5.4},
	{"stamp": "First light", "title": "Listen before you believe.", "body": "Follow Idris's amber paint: search the crate beside him and the car boot east. Take one battery and two scrap to the receiver bench, build the coil, then scan the mast.", "duration": 6.0},
]

@onready var _canvas = $Illustration
@onready var _plate: PanelContainer = $TextPlate
@onready var _margin: MarginContainer = $TextPlate/Margin
@onready var _copy: VBoxContainer = $TextPlate/Margin/Copy
@onready var _stamp: Label = $TextPlate/Margin/Copy/Stamp
@onready var _title: Label = $TextPlate/Margin/Copy/Title
@onready var _body: Label = $TextPlate/Margin/Copy/Body
@onready var _footer: HBoxContainer = $TextPlate/Margin/Copy/Footer
@onready var _progress: ProgressBar = $TextPlate/Margin/Copy/Footer/Progress
@onready var _skip: Button = $TextPlate/Margin/Copy/Footer/Skip
@onready var _next: Button = $TextPlate/Margin/Copy/Footer/Next

var _index := 0
var _elapsed := 0.0
var _running := false
var _touch_ui := false
var _last_touch_msec := -TOUCH_DEBOUNCE_MSEC


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_touch_ui = _is_touch_device()
	_next.pressed.connect(_on_next_pressed)
	_skip.pressed.connect(_on_skip_pressed)
	get_viewport().size_changed.connect(_apply_responsive_layout)
	visible = false
	call_deferred("_apply_responsive_layout")


func _is_touch_device() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("web_android") \
		or OS.has_feature("web_ios") or DisplayServer.is_touchscreen_available()


func _physical_scale(logical_view: Vector2, physical_override: Vector2 = Vector2.ZERO) -> float:
	var window_size := physical_override
	if window_size == Vector2.ZERO:
		window_size = Vector2(DisplayServer.window_get_size())
	if window_size.x <= 1.0 or window_size.y <= 1.0 or logical_view.x <= 1.0 or logical_view.y <= 1.0:
		return 1.0
	return maxf(0.05, minf(window_size.x / logical_view.x, window_size.y / logical_view.y))


func apply_responsive_layout(
		viewport_size: Vector2,
		touch_override: int = -1,
		physical_view: Vector2 = Vector2.ZERO,
	) -> void:
	_apply_responsive_layout(viewport_size, touch_override, physical_view)


func _apply_responsive_layout(
		size_override: Vector2 = Vector2.ZERO,
		touch_override: int = -1,
		physical_view: Vector2 = Vector2.ZERO,
	) -> void:
	if not is_node_ready():
		return
	var view := size_override if size_override != Vector2.ZERO else size
	if view.x <= 1.0 or view.y <= 1.0:
		return
	var portrait := view.y > view.x
	var touch_layout := _touch_ui if touch_override < 0 else touch_override == 1
	var compact := touch_layout or view.x < 980.0 or view.y < 560.0

	if compact:
		var physical := _physical_scale(view, physical_view)
		var requested_scale := clampf(0.94 / physical, 1.0, 3.2) if touch_layout else 1.0
		var base_size := PHONE_PORTRAIT_CARD if portrait else PHONE_LANDSCAPE_CARD
		var edge := 12.0 * requested_scale
		var fit_scale := minf(
			(view.x - edge * 2.0) / base_size.x,
			(view.y - edge * 2.0) / base_size.y
		)
		var card_scale := maxf(0.5, minf(requested_scale, fit_scale))
		_plate.set_anchors_preset(Control.PRESET_TOP_LEFT)
		_plate.grow_horizontal = Control.GROW_DIRECTION_END
		_plate.grow_vertical = Control.GROW_DIRECTION_END
		_plate.pivot_offset = Vector2.ZERO
		_plate.scale = Vector2.ONE * card_scale
		_plate.size = base_size
		_plate.position = Vector2(
			(view.x - base_size.x * card_scale) * 0.5,
			view.y - base_size.y * card_scale - edge * 0.45
		)
		_canvas.set_anchors_preset(Control.PRESET_TOP_LEFT)
		_canvas.position = Vector2.ZERO
		_canvas.size = Vector2(view.x, maxf(1.0, _plate.position.y + 8.0 * card_scale))
		_margin.add_theme_constant_override("margin_left", 18 if portrait else 24)
		_margin.add_theme_constant_override("margin_top", 15 if portrait else 11)
		_margin.add_theme_constant_override("margin_right", 18 if portrait else 24)
		_margin.add_theme_constant_override("margin_bottom", 14 if portrait else 10)
		_copy.add_theme_constant_override("separation", 7 if portrait else 5)
		_footer.add_theme_constant_override("separation", 9)
		var copy_width := base_size.x - (36.0 if portrait else 48.0)
		_title.custom_minimum_size.x = copy_width
		_body.custom_minimum_size.x = copy_width
		_stamp.add_theme_font_size_override("font_size", 14)
		_title.add_theme_font_size_override("font_size", 27 if portrait else 23)
		_body.add_theme_font_size_override("font_size", 17 if portrait else 15)
		_skip.custom_minimum_size = Vector2(82.0, 52.0)
		_next.custom_minimum_size = Vector2(142.0, 52.0)
		_skip.add_theme_font_size_override("font_size", 15)
		_next.add_theme_font_size_override("font_size", 16)
		_skip.text = "Skip"
		# Font changes invalidate wrapped-label minimums. Reassert the authored
		# card after those minimums have been calculated at the real copy width.
		_plate.size = base_size
	else:
		_plate.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		_plate.scale = Vector2.ONE
		_plate.offset_left = 0.0
		_plate.offset_top = -178.0
		_plate.offset_right = 0.0
		_plate.offset_bottom = 0.0
		_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
		_canvas.offset_left = 0.0
		_canvas.offset_top = 0.0
		_canvas.offset_right = 0.0
		_canvas.offset_bottom = -150.0
		_margin.add_theme_constant_override("margin_left", 42)
		_margin.add_theme_constant_override("margin_top", 16)
		_margin.add_theme_constant_override("margin_right", 42)
		_margin.add_theme_constant_override("margin_bottom", 14)
		_copy.add_theme_constant_override("separation", 8)
		_footer.add_theme_constant_override("separation", 18)
		_title.custom_minimum_size.x = 520.0
		_body.custom_minimum_size.x = 520.0
		_stamp.add_theme_font_size_override("font_size", 12)
		_title.add_theme_font_size_override("font_size", 21)
		_body.add_theme_font_size_override("font_size", 14)
		_skip.custom_minimum_size = Vector2(92.0, 44.0)
		_next.custom_minimum_size = Vector2(154.0, 44.0)
		_skip.add_theme_font_size_override("font_size", 12)
		_next.add_theme_font_size_override("font_size", 14)
		_skip.text = "Esc: skip"


func begin() -> void:
	if _running or WorldState.has_flag(&"intro_seen") or DisplayServer.get_name() == "headless":
		return
	_running = true
	_index = 0
	_elapsed = 0.0
	_last_touch_msec = -TOUCH_DEBOUNCE_MSEC
	visible = true
	_apply_responsive_layout()
	GameManager.set_dialogue_active(true)
	_show_beat()
	_next.grab_focus()
	AudioManager.play(&"radio_static", -2.0)


func _process(delta: float) -> void:
	if not _running:
		return
	_elapsed += delta
	var duration := float(BEATS[_index].duration)
	_progress.value = clampf(_elapsed / duration * 100.0, 0.0, 100.0)
	if _elapsed >= duration:
		_advance()


func _unhandled_input(event: InputEvent) -> void:
	if not _running:
		return
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_finish()
	elif event.is_action_pressed("interact") or event is InputEventKey and event.pressed and event.physical_keycode == KEY_SPACE:
		get_viewport().set_input_as_handled()
		_advance()


func _input(event: InputEvent) -> void:
	if not _running or not event is InputEventScreenTouch or not event.pressed:
		return
	var now := Time.get_ticks_msec()
	get_viewport().set_input_as_handled()
	if now - _last_touch_msec < TOUCH_DEBOUNCE_MSEC:
		return
	_last_touch_msec = now
	if _skip.get_global_rect().has_point(event.position):
		_finish()
	else:
		_advance()


func _on_next_pressed() -> void:
	if Time.get_ticks_msec() - _last_touch_msec < TOUCH_DEBOUNCE_MSEC:
		return
	_advance()


func _on_skip_pressed() -> void:
	if Time.get_ticks_msec() - _last_touch_msec < TOUCH_DEBOUNCE_MSEC:
		return
	_finish()


func _advance() -> void:
	if not _running:
		return
	_index += 1
	_elapsed = 0.0
	if _index >= BEATS.size():
		_finish()
		return
	_show_beat()
	AudioManager.play(&"radio_static", -8.0, 0.82 + _index * 0.035)


func _show_beat() -> void:
	var beat: Dictionary = BEATS[_index]
	_canvas.set_beat(_index)
	_stamp.text = String(beat.stamp)
	_title.text = String(beat.title)
	_body.text = String(beat.body)
	_progress.value = 0.0
	_next.text = "Next" if _index < BEATS.size() - 1 else "Step outside"


func _finish() -> void:
	_running = false
	visible = false
	WorldState.set_flag(&"intro_seen")
	WorldState.set_flag(&"intro_pending", false)
	GameManager.set_dialogue_active(false)
	SaveManager.save_game("")
	AudioManager.play(&"objective")
	finished.emit()
