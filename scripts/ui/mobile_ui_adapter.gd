extends Node
## Repositions the existing HUD for touch devices without changing desktop UI.
## The desktop scene remains the source layout; this adapter only runs when a
## touchscreen or mobile web feature is detected.

var _hud: CanvasLayer
var _interface: Control
var _status: Control
var _objective: Control
var _notice: Control
var _prompt_panel: Control
var _prompt: Label
var _compass: Control
var _archive_count: Label
var _field_hint: Label
var _pause_menu: Control
var _pause_hint: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not _is_touch_device():
		queue_free()
		return
	get_viewport().size_changed.connect(_apply_layout)
	call_deferred("_bind_hud")


func _is_touch_device() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("web_android") \
		or OS.has_feature("web_ios") or DisplayServer.is_touchscreen_available()


func _bind_hud() -> void:
	_hud = get_parent().get_node_or_null("HUD") as CanvasLayer
	if _hud == null:
		return
	_interface = _hud.get_node("Interface") as Control
	_status = _hud.get_node("Interface/StatusPanel") as Control
	_objective = _hud.get_node("Interface/ObjectivePanel") as Control
	_notice = _hud.get_node("Interface/Notice") as Control
	_prompt_panel = _hud.get_node("Interface/Prompt") as Control
	_prompt = _hud.get_node("Interface/Prompt/Margin/Label") as Label
	_compass = _hud.get_node("Interface/Compass") as Control
	_archive_count = _hud.get_node("Interface/ArchiveCount") as Label
	_field_hint = _hud.get_node("Interface/FieldHint") as Label
	_pause_menu = _hud.get_node("PauseOverlay/Menu") as Control
	_pause_hint = _hud.get_node("PauseOverlay/Menu/Margin/Items/Hint") as Label

	EventBus.interaction_prompt_changed.connect(_on_prompt_changed)
	ArchiveSystem.echo_recorded.connect(func(_data: MemoryEchoData) -> void: _refresh_archive())
	_field_hint.text = "HELP  /  TOUCH GUIDE     MENU  /  PAUSE"
	_pause_hint.text = "TAP RETURN TO ROAD  /  MAP AND GUIDE ARE ON SCREEN"
	(_hud.get_node("PauseOverlay/Menu/Margin/Items/Guide") as Button).text = "TOUCH GUIDE"
	for child in (_hud.get_node("PauseOverlay/Menu/Margin/Items") as VBoxContainer).get_children():
		if child is Button:
			(child as Button).custom_minimum_size.y = 52.0
	_apply_layout()
	_refresh_archive()


func _apply_layout() -> void:
	if _interface == null or not is_instance_valid(_interface):
		return
	var view := _interface.size
	if view.x <= 1.0 or view.y <= 1.0:
		return
	var window_size := Vector2(DisplayServer.window_get_size())
	var portrait := window_size.y > window_size.x

	_set_rect(_status, Vector2(14.0, 14.0), Vector2(235.0, 76.0))
	if portrait:
		_set_rect(_objective, Vector2(14.0, 104.0), Vector2(minf(370.0, view.x - 28.0), 136.0))
		_set_rect(_notice, Vector2(20.0, 250.0), Vector2(maxf(220.0, view.x - 40.0), 70.0))
		_set_rect(_compass, Vector2(maxf(268.0, view.x - 92.0), 16.0), Vector2(74.0, 74.0))
		_set_rect(_archive_count, Vector2(maxf(270.0, view.x - 230.0), 92.0), Vector2(212.0, 22.0))
		_set_rect(_field_hint, Vector2(14.0, 246.0), Vector2(minf(430.0, view.x - 28.0), 22.0))
		_set_rect(_prompt_panel, Vector2(maxf(14.0, (view.x - 440.0) * 0.5), view.y - 330.0), Vector2(minf(440.0, view.x - 28.0), 46.0))
	else:
		_set_rect(_objective, Vector2(maxf(14.0, view.x - 370.0), 14.0), Vector2(352.0, 136.0))
		_set_rect(_notice, Vector2(maxf(270.0, (view.x - 560.0) * 0.5), 20.0), Vector2(minf(560.0, view.x - 540.0), 62.0))
		_set_rect(_compass, Vector2(maxf(14.0, view.x - 92.0), 164.0), Vector2(74.0, 74.0))
		_set_rect(_archive_count, Vector2(maxf(14.0, view.x - 226.0), 164.0), Vector2(124.0, 22.0))
		_set_rect(_field_hint, Vector2(270.0, 96.0), Vector2(minf(430.0, view.x - 540.0), 22.0))
		_set_rect(_prompt_panel, Vector2(maxf(260.0, (view.x - 480.0) * 0.5), view.y - 250.0), Vector2(minf(480.0, view.x - 520.0), 46.0))

	var menu_width := minf(430.0, view.x - 30.0)
	var menu_height := minf(620.0, view.y - 30.0)
	_set_rect(_pause_menu, Vector2((view.x - menu_width) * 0.5, (view.y - menu_height) * 0.5), Vector2(menu_width, menu_height))


func _set_rect(control: Control, position: Vector2, control_size: Vector2) -> void:
	if control == null:
		return
	control.set_anchors_preset(Control.PRESET_TOP_LEFT)
	control.position = position
	control.size = Vector2(maxf(1.0, control_size.x), maxf(1.0, control_size.y))


func _on_prompt_changed(text: String) -> void:
	if _prompt == null:
		return
	_prompt.text = "USE  /  " + text if not text.is_empty() else ""


func _refresh_archive() -> void:
	if _archive_count != null:
		_archive_count.text = "LOG  /  %d TRACES" % ArchiveSystem.get_count()
