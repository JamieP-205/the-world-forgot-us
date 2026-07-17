extends Node
## Repositions and scales the existing HUD for touch devices without changing
## the desktop scene. Phone layouts prioritise condition, current objective and
## interaction prompts; secondary field data remains available in landscape.

var _hud: CanvasLayer
var _interface: Control
var _status: Control
var _inventory: Control
var _objective: Control
var _objective_task: Label
var _objective_location: Label
var _objective_progress: Label
var _notice: Control
var _prompt_panel: Control
var _prompt: Label
var _compass: Control
var _archive_count: Label
var _field_hint: Label
var _pause_menu: Control
var _pause_hint: Label
var _pause_items: VBoxContainer


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
	_inventory = _hud.get_node("Interface/InventoryPanel") as Control
	_objective = _hud.get_node("Interface/ObjectivePanel") as Control
	_objective_task = _hud.get_node("Interface/ObjectivePanel/Margin/Note/Task") as Label
	_objective_location = _hud.get_node("Interface/ObjectivePanel/Margin/Note/Location") as Label
	_objective_progress = _hud.get_node("Interface/ObjectivePanel/Margin/Note/Progress") as Label
	_notice = _hud.get_node("Interface/Notice") as Control
	_prompt_panel = _hud.get_node("Interface/Prompt") as Control
	_prompt = _hud.get_node("Interface/Prompt/Margin/Label") as Label
	_compass = _hud.get_node("Interface/Compass") as Control
	_archive_count = _hud.get_node("Interface/ArchiveCount") as Label
	_field_hint = _hud.get_node("Interface/FieldHint") as Label
	_pause_menu = _hud.get_node("PauseOverlay/Menu") as Control
	_pause_items = _hud.get_node("PauseOverlay/Menu/Margin/Items") as VBoxContainer
	_pause_hint = _hud.get_node("PauseOverlay/Menu/Margin/Items/Hint") as Label

	EventBus.interaction_prompt_changed.connect(_on_prompt_changed)
	ArchiveSystem.echo_recorded.connect(func(_data: MemoryEchoData) -> void: _refresh_archive())
	_field_hint.text = "kit · tools     pause · menu"
	_pause_hint.text = "Tap return to road  ·  pocket guide explains the controls"
	(_hud.get_node("PauseOverlay/Menu/Margin/Items/Guide") as Button).text = "POCKET GUIDE"
	_apply_layout()
	_refresh_archive()


func _physical_scale(view: Vector2) -> float:
	var window_size := Vector2(DisplayServer.window_get_size())
	if window_size.x <= 1.0 or window_size.y <= 1.0 or view.x <= 1.0 or view.y <= 1.0:
		return 1.0
	return maxf(0.05, minf(window_size.x / view.x, window_size.y / view.y))


func _apply_layout() -> void:
	if _interface == null or not is_instance_valid(_interface):
		return
	var view := _interface.size
	if view.x <= 1.0 or view.y <= 1.0:
		return
	var window_size := Vector2(DisplayServer.window_get_size())
	var portrait := window_size.y > window_size.x
	var physical := _physical_scale(view)
	var ui_scale := clampf(0.92 / physical, 0.95, 2.85)
	var edge := 14.0 * ui_scale

	_objective_location.visible = not portrait
	_objective_progress.visible = not portrait
	_archive_count.visible = not portrait
	_field_hint.visible = not portrait
	_objective_task.add_theme_font_size_override("font_size", 16 if portrait else 14)
	_prompt.add_theme_font_size_override("font_size", 16 if portrait else 14)

	if portrait:
		_set_scaled_rect(_status, Vector2(edge, edge), Vector2(220.0, 72.0), ui_scale)
		_set_scaled_rect(
			_compass,
			Vector2(view.x - edge - 64.0 * ui_scale, edge),
			Vector2(64.0, 64.0),
			ui_scale
		)
		var objective_y := edge + 82.0 * ui_scale
		var objective_width := minf(330.0, maxf(245.0, (view.x - edge * 2.0) / ui_scale))
		_set_scaled_rect(_objective, Vector2(edge, objective_y), Vector2(objective_width, 94.0), ui_scale)
		_set_scaled_rect(
			_inventory,
			Vector2(edge, objective_y + 106.0 * ui_scale),
			Vector2(220.0, 112.0),
			ui_scale
		)
	else:
		_set_scaled_rect(_status, Vector2(edge, edge), Vector2(235.0, 76.0), ui_scale)
		_set_scaled_rect(
			_compass,
			Vector2(view.x - edge - 74.0 * ui_scale, edge),
			Vector2(74.0, 74.0),
			ui_scale
		)
		_set_scaled_rect(
			_objective,
			Vector2(view.x - edge - 352.0 * ui_scale, edge),
			Vector2(352.0, 136.0),
			ui_scale
		)
		_set_scaled_rect(
			_archive_count,
			Vector2(view.x - edge - 124.0 * ui_scale, edge + 148.0 * ui_scale),
			Vector2(124.0, 22.0),
			ui_scale
		)
		_set_scaled_rect(
			_inventory,
			Vector2(edge, edge + 88.0 * ui_scale),
			Vector2(235.0, 128.0),
			ui_scale
		)
		_set_scaled_rect(
			_field_hint,
			Vector2(edge + 248.0 * ui_scale, edge + 82.0 * ui_scale),
			Vector2(300.0, 22.0),
			ui_scale * 0.9
		)

	var notice_scale := ui_scale * 0.9
	var notice_width := minf(540.0, maxf(250.0, (view.x - edge * 2.0) / notice_scale))
	var notice_y := edge + (188.0 if portrait else 148.0) * ui_scale
	_set_scaled_rect(
		_notice,
		Vector2((view.x - notice_width * notice_scale) * 0.5, notice_y),
		Vector2(notice_width, 62.0),
		notice_scale
	)

	var prompt_scale := ui_scale
	var prompt_width := minf(460.0, maxf(260.0, (view.x - edge * 2.0) / prompt_scale))
	var prompt_bottom_clearance := (252.0 if portrait else 205.0) * ui_scale
	_set_scaled_rect(
		_prompt_panel,
		Vector2((view.x - prompt_width * prompt_scale) * 0.5, view.y - prompt_bottom_clearance),
		Vector2(prompt_width, 48.0),
		prompt_scale
	)

	var menu_fit := minf(
		(view.x - edge * 2.0) / 420.0,
		(view.y - edge * 2.0) / 600.0
	)
	var menu_scale := maxf(0.72, minf(ui_scale, menu_fit))
	_set_scaled_rect(
		_pause_menu,
		Vector2((view.x - 420.0 * menu_scale) * 0.5, (view.y - 600.0 * menu_scale) * 0.5),
		Vector2(420.0, 600.0),
		menu_scale
	)
	var button_height := clampf(44.0 / maxf(physical * menu_scale, 0.01), 52.0, 78.0)
	var button_font := roundi(clampf(14.0 / maxf(physical * menu_scale, 0.01), 15.0, 26.0))
	for child in _pause_items.get_children():
		if child is Button:
			var button := child as Button
			button.custom_minimum_size.y = button_height
			button.add_theme_font_size_override("font_size", button_font)


func _set_scaled_rect(control: Control, position: Vector2, control_size: Vector2, scale_value: float) -> void:
	if control == null:
		return
	control.set_anchors_preset(Control.PRESET_TOP_LEFT)
	control.pivot_offset = Vector2.ZERO
	control.scale = Vector2.ONE * scale_value
	control.position = position
	control.size = Vector2(maxf(1.0, control_size.x), maxf(1.0, control_size.y))


func _on_prompt_changed(text: String) -> void:
	if _prompt == null:
		return
	_prompt.text = "use  ·  " + text if not text.is_empty() else ""


func _refresh_archive() -> void:
	if _archive_count != null:
		_archive_count.text = "traces  ·  %d" % ArchiveSystem.get_count()
