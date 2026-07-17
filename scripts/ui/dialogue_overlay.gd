class_name DialogueOverlay
extends Control
## Persistent story conversation overlay with keyboard, mouse and touch input.
## Touch layouts scale the complete card from the real browser window so the
## story text and choices stay readable through the expanded game viewport.

const PHONE_PORTRAIT_CARD := Vector2(460.0, 620.0)
const PHONE_LANDSCAPE_CARD := Vector2(820.0, 350.0)
const INPUT_DEBOUNCE_MSEC := 280

@onready var _panel: PanelContainer = $Panel
@onready var _margin: MarginContainer = $Panel/Margin
@onready var _content: VBoxContainer = $Panel/Margin/Content
@onready var _speaker: Label = $Panel/Margin/Content/Speaker
@onready var _signal_tag: Label = $Panel/Margin/Content/SignalTag
@onready var _body: RichTextLabel = $Panel/Margin/Content/Body
@onready var _progress: Label = $Panel/Margin/Content/Footer/Progress
@onready var _continue: Button = $Panel/Margin/Content/Footer/Continue
@onready var _choices: GridContainer = $Panel/Margin/Content/Choices

var _story_id: StringName = &""
var _lines: Array[String] = []
var _choice_labels: Array[String] = []
var _line_index := 0
var _choices_visible := false
var _accept_after_msec := 0
var _touch_ui := false
var _layout_touch := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_touch_ui = _is_touch_device()
	visible = false
	_continue.pressed.connect(_on_continue_pressed)
	EventBus.dialogue_requested.connect(_show_dialogue)
	get_viewport().size_changed.connect(_apply_responsive_layout)
	call_deferred("_apply_responsive_layout")


func _is_touch_device() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("web_android") \
		or OS.has_feature("web_ios") or DisplayServer.is_touchscreen_available()


func _physical_scale(logical_view: Vector2, physical_override: Vector2 = Vector2.ZERO) -> float:
	var window_size := physical_override
	if window_size == Vector2.ZERO:
		window_size = Vector2(DisplayServer.window_get_size())
	if window_size.x <= 1.0 or window_size.y <= 1.0 \
			or logical_view.x <= 1.0 or logical_view.y <= 1.0:
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
	_layout_touch = _touch_ui if touch_override < 0 else touch_override == 1
	if _layout_touch:
		_apply_phone_layout(view, view.y > view.x, physical_view)
	else:
		_apply_desktop_layout(view)
	_restyle_choice_buttons()


func _apply_phone_layout(view: Vector2, portrait: bool, physical_view: Vector2) -> void:
	var physical := _physical_scale(view, physical_view)
	var requested_scale := clampf(0.92 / physical, 1.0, 3.2)
	var base_size := PHONE_PORTRAIT_CARD if portrait else PHONE_LANDSCAPE_CARD
	var edge := 14.0 * requested_scale
	var fit_scale := minf(
		(view.x - edge * 2.0) / base_size.x,
		(view.y - edge * 2.0) / base_size.y
	)
	var card_scale := maxf(0.5, minf(requested_scale, fit_scale))
	_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_panel.grow_horizontal = Control.GROW_DIRECTION_END
	_panel.grow_vertical = Control.GROW_DIRECTION_END
	_panel.pivot_offset = Vector2.ZERO
	_panel.scale = Vector2.ONE * card_scale
	_panel.size = base_size
	_panel.position = Vector2(
		(view.x - base_size.x * card_scale) * 0.5,
		view.y - edge - base_size.y * card_scale
	)
	_margin.add_theme_constant_override("margin_left", 26)
	_margin.add_theme_constant_override("margin_top", 16)
	_margin.add_theme_constant_override("margin_right", 30)
	_margin.add_theme_constant_override("margin_bottom", 18)
	_content.add_theme_constant_override("separation", 7)
	_choices.columns = 1 if portrait else 2
	_choices.add_theme_constant_override("h_separation", 8)
	_choices.add_theme_constant_override("v_separation", 7)
	_signal_tag.add_theme_font_size_override("font_size", 11)
	_speaker.add_theme_font_size_override("font_size", 21 if portrait else 19)
	_body.add_theme_font_size_override("normal_font_size", 18 if portrait else 17)
	_progress.add_theme_font_size_override("font_size", 12)
	_continue.custom_minimum_size = Vector2(188.0, 58.0)
	_continue.add_theme_font_size_override("font_size", 18)
	_panel.size = base_size


func _apply_desktop_layout(view: Vector2) -> void:
	_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_panel.grow_horizontal = Control.GROW_DIRECTION_END
	_panel.grow_vertical = Control.GROW_DIRECTION_END
	_panel.pivot_offset = Vector2.ZERO
	_panel.scale = Vector2.ONE
	_panel.size = Vector2(maxf(756.0, view.x - 116.0), 342.0)
	_panel.position = Vector2(58.0, view.y - 380.0)
	_margin.add_theme_constant_override("margin_left", 30)
	_margin.add_theme_constant_override("margin_top", 16)
	_margin.add_theme_constant_override("margin_right", 38)
	_margin.add_theme_constant_override("margin_bottom", 17)
	_content.add_theme_constant_override("separation", 8)
	_choices.columns = 2
	_choices.add_theme_constant_override("h_separation", 8)
	_choices.add_theme_constant_override("v_separation", 6)
	_signal_tag.add_theme_font_size_override("font_size", 10)
	_speaker.add_theme_font_size_override("font_size", 19)
	_body.add_theme_font_size_override("normal_font_size", 16)
	_progress.add_theme_font_size_override("font_size", 11)
	_continue.custom_minimum_size = Vector2(176.0, 44.0)
	_continue.add_theme_font_size_override("font_size", 14)
	_panel.size = Vector2(maxf(756.0, view.x - 116.0), 342.0)


func _restyle_choice_buttons() -> void:
	for child in _choices.get_children():
		if child is not Button:
			continue
		var button := child as Button
		button.custom_minimum_size = Vector2(340.0, 62.0 if _layout_touch else 48.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 17 if _layout_touch else 14)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if _choices_visible and event is InputEventKey and event.pressed and not event.echo:
		var index := -1
		if event.keycode == KEY_1:
			index = 0
		elif event.keycode == KEY_2:
			index = 1
		elif event.keycode == KEY_3:
			index = 2
		elif event.keycode == KEY_4:
			index = 3
		if index >= 0 and index < _choice_labels.size():
			_on_choice_pressed(index)
			get_viewport().set_input_as_handled()
	elif not _choices_visible and (event.is_action_pressed("ui_accept") \
			or event.is_action_pressed("interact")):
		_on_continue_pressed()
		get_viewport().set_input_as_handled()


## Screen touches arrive before GUI controls. Claiming page taps here prevents
## the browser's follow-on synthetic click from also pressing Continue. Once
## replies are visible, the real choice buttons own touch normally.
func _input(event: InputEvent) -> void:
	if visible and _touch_ui and not _choices_visible \
			and event is InputEventScreenTouch and event.pressed:
		AudioManager.unlock_audio()
		_on_continue_pressed()
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
	_speaker.text = String(payload.get("title", "Unknown line"))
	_signal_tag.text = String(payload.get("provenance", _provenance_for(_speaker.text)))
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
	_body.scroll_to_line(0)
	_progress.text = (
		"Page %d of %d · tap to continue" if _layout_touch
		else "Page %d of %d · Enter or E"
	) % [_line_index + 1, _lines.size()]
	_continue.text = "Continue" if _line_index < _lines.size() - 1 else (
		"Choose a reply" if not _choice_labels.is_empty() else "Close"
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
		button.custom_minimum_size = Vector2(340, 62 if _layout_touch else 48)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.text = "%d.  %s" % [i + 1, _choice_labels[i]]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.add_theme_font_size_override("font_size", 17 if _layout_touch else 14)
		button.pressed.connect(_on_choice_pressed.bind(i))
		_choices.add_child(button)
	if _choices.get_child_count() > 0:
		(_choices.get_child(0) as Button).grab_focus()
	_progress.text = "Tap a reply" if _layout_touch else "Choose with mouse or number key"


func _on_continue_pressed() -> void:
	if not _claim_ui_input():
		return
	_advance()


func _on_choice_pressed(index: int) -> void:
	if not _claim_ui_input():
		return
	_choose(index)


## Touchscreen browsers may send the same gesture as both a screen touch and
## a synthetic mouse click. Holding a brief shared gate keeps one tap to one
## page or one reply, including the hand-off from the last page to choices.
func _claim_ui_input() -> bool:
	var now := Time.get_ticks_msec()
	if now < _accept_after_msec:
		return false
	_accept_after_msec = now + INPUT_DEBOUNCE_MSEC
	return true


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


func _provenance_for(title: String) -> String:
	var lower := title.to_lower()
	if "radio" in lower or "signal" in lower or "maggie" in lower or "continuity" in lower:
		return "Receiver line · identity not yet verified"
	if "evidence" in lower or "record" in lower or "ledger" in lower:
		return "Field evidence · copied into Ellie's notebook"
	return "Field conversation · noted by Ellie"
