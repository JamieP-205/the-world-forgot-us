class_name DialogueOverlay
extends Control
## Persistent story conversation overlay with keyboard, mouse and touch input.
## Touch layouts scale the complete card from the real browser window so the
## story text and choices stay readable through the expanded game viewport.

@onready var _panel: PanelContainer = $Panel
@onready var _speaker: Label = $Panel/Margin/Content/Speaker
@onready var _body: Label = $Panel/Margin/Content/Body
@onready var _progress: Label = $Panel/Margin/Content/Footer/Progress
@onready var _continue: Button = $Panel/Margin/Content/Footer/Continue
@onready var _choices: VBoxContainer = $Panel/Margin/Content/Choices

var _story_id: StringName = &""
var _lines: Array[String] = []
var _choice_labels: Array[String] = []
var _line_index := 0
var _choices_visible := false
var _accept_after_msec := 0
var _touch_ui := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_touch_ui = _is_touch_device()
	visible = false
	_continue.pressed.connect(_advance)
	EventBus.dialogue_requested.connect(_show_dialogue)
	get_viewport().size_changed.connect(_apply_responsive_layout)
	call_deferred("_apply_responsive_layout")


func _is_touch_device() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("web_android") \
		or OS.has_feature("web_ios") or DisplayServer.is_touchscreen_available()


func _physical_scale() -> float:
	var window_size := Vector2(DisplayServer.window_get_size())
	if window_size.x <= 1.0 or window_size.y <= 1.0 or size.x <= 1.0 or size.y <= 1.0:
		return 1.0
	return maxf(0.05, minf(window_size.x / size.x, window_size.y / size.y))


func _apply_responsive_layout() -> void:
	if not is_node_ready() or size.x <= 1.0 or size.y <= 1.0:
		return
	if _touch_ui:
		var window_size := Vector2(DisplayServer.window_get_size())
		var portrait := window_size.y > window_size.x
		var requested_scale := clampf(0.92 / _physical_scale(), 1.0, 2.85)
		var base_size := Vector2(460.0, 440.0) if portrait else Vector2(760.0, 300.0)
		var edge := 16.0 * requested_scale
		var fit_scale := minf(
			(size.x - edge * 2.0) / base_size.x,
			(size.y - edge * 2.0) / base_size.y
		)
		var card_scale := maxf(0.72, minf(requested_scale, fit_scale))
		_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
		_panel.pivot_offset = Vector2.ZERO
		_panel.scale = Vector2.ONE * card_scale
		_panel.size = base_size
		_panel.position = Vector2(
			(size.x - base_size.x * card_scale) * 0.5,
			size.y - edge - base_size.y * card_scale
		)
		_continue.custom_minimum_size = Vector2(188.0, 54.0)
		_continue.add_theme_font_size_override("font_size", 18)
	else:
		_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		_panel.scale = Vector2.ONE
		_panel.offset_left = 58.0
		_panel.offset_right = -280.0
		_panel.offset_top = -300.0
		_panel.offset_bottom = -38.0
		_continue.custom_minimum_size = Vector2(176.0, 36.0)
		_continue.add_theme_font_size_override("font_size", 14)


func _unhandled_input(event: InputEvent) -> void:
	if not visible or Time.get_ticks_msec() < _accept_after_msec:
		return
	if _choices_visible and event is InputEventKey and event.pressed and not event.echo:
		var index := -1
		if event.keycode == KEY_1:
			index = 0
		elif event.keycode == KEY_2:
			index = 1
		elif event.keycode == KEY_3:
			index = 2
		if index >= 0 and index < _choice_labels.size():
			_choose(index)
			get_viewport().set_input_as_handled()
	elif not _choices_visible and (event.is_action_pressed("ui_accept") \
			or event.is_action_pressed("interact")):
		_advance()
		get_viewport().set_input_as_handled()
	elif _touch_ui and not _choices_visible and event is InputEventScreenTouch and event.pressed:
		AudioManager.unlock_audio()
		_advance()
		get_viewport().set_input_as_handled()


func _show_dialogue(payload: Dictionary) -> void:
	_story_id = StringName(payload.get("id", &""))
	_lines.clear()
	for raw_line in payload.get("lines", []):
		_lines.append(String(raw_line))
	_choice_labels.clear()
	for raw_choice in payload.get("choices", []):
		_choice_labels.append(String(raw_choice))
	_line_index = 0
	_choices_visible = false
	_accept_after_msec = Time.get_ticks_msec() + 180
	_speaker.text = String(payload.get("title", "UNKNOWN SIGNAL"))
	var accent: Color = payload.get("accent", Color(0.38, 0.90, 0.94, 1.0))
	_speaker.add_theme_color_override("font_color", accent)
	_panel.modulate = Color(1, 1, 1, 1)
	_clear_choices()
	visible = true
	_apply_responsive_layout()
	_show_line()
	AudioManager.play(&"dialogue_open")


func _show_line() -> void:
	if _lines.is_empty():
		_finish(-1)
		return
	_body.text = _lines[_line_index]
	_progress.text = (
		"RECORD %02d / %02d     TAP CONTINUE" if _touch_ui
		else "RECORD %02d / %02d     ENTER  /  E"
	) % [_line_index + 1, _lines.size()]
	_continue.text = "CONTINUE" if _line_index < _lines.size() - 1 else (
		"CHOOSE" if not _choice_labels.is_empty() else "CLOSE"
	)
	_continue.visible = true
	_choices.visible = false
	_choices_visible = false
	_continue.grab_focus()


func _advance() -> void:
	if not visible or _choices_visible:
		return
	AudioManager.play(&"dialogue_tick", -4.0, 1.0 + _line_index * 0.025)
	if _line_index < _lines.size() - 1:
		_line_index += 1
		_show_line()
	elif not _choice_labels.is_empty():
		_show_choices()
	else:
		_finish(-1)


func _show_choices() -> void:
	_choices_visible = true
	_continue.visible = false
	_choices.visible = true
	_clear_choices()
	for i in _choice_labels.size():
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 58 if _touch_ui else 38)
		button.text = "%02d  /  %s" % [i + 1, _choice_labels[i]]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", 18 if _touch_ui else 14)
		button.pressed.connect(_choose.bind(i))
		_choices.add_child(button)
	if _choices.get_child_count() > 0:
		(_choices.get_child(0) as Button).grab_focus()
	_progress.text = "TAP A RESPONSE" if _touch_ui else "SELECT WITH MOUSE  /  NUMBER KEY"


func _choose(index: int) -> void:
	if not _choices_visible:
		return
	AudioManager.play(&"choice")
	_finish(index)


func _finish(choice_index: int) -> void:
	var finished_id := _story_id
	visible = false
	_story_id = &""
	_lines.clear()
	_choice_labels.clear()
	_clear_choices()
	EventBus.dialogue_finished.emit(finished_id, choice_index)


func _clear_choices() -> void:
	for child in _choices.get_children():
		_choices.remove_child(child)
		child.queue_free()
