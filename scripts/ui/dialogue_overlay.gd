class_name DialogueOverlay
extends Control
## Persistent, mouse/keyboard friendly story conversation overlay.

@onready var _speaker: Label = $Panel/Margin/Content/Speaker
@onready var _body: Label = $Panel/Margin/Content/Body
@onready var _progress: Label = $Panel/Margin/Content/Footer/Progress
@onready var _continue: Button = $Panel/Margin/Content/Footer/Continue
@onready var _choices: VBoxContainer = $Panel/Margin/Content/Choices
@onready var _panel: PanelContainer = $Panel

var _story_id: StringName = &""
var _lines: Array[String] = []
var _choice_labels: Array[String] = []
var _line_index := 0
var _choices_visible := false
var _accept_after_msec := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_continue.pressed.connect(_advance)
	EventBus.dialogue_requested.connect(_show_dialogue)


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
	_show_line()
	AudioManager.play(&"dialogue_open")


func _show_line() -> void:
	if _lines.is_empty():
		_finish(-1)
		return
	_body.text = _lines[_line_index]
	_progress.text = "%d / %d   [Enter or E]" % [_line_index + 1, _lines.size()]
	_continue.text = "Continue" if _line_index < _lines.size() - 1 else (
		"Choose" if not _choice_labels.is_empty() else "Close"
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
		button.custom_minimum_size = Vector2(0, 42)
		button.text = "%d.  %s" % [i + 1, _choice_labels[i]]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_choose.bind(i))
		_choices.add_child(button)
	if _choices.get_child_count() > 0:
		(_choices.get_child(0) as Button).grab_focus()
	_progress.text = "Choose with mouse or number key"


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
