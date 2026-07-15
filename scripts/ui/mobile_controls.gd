extends CanvasLayer
## Touch overlay for browser and mobile builds.
##
## Movement is polled through the existing Input Map, while action buttons feed
## InputEventAction events back through Godot's normal input pipeline. The player,
## dialogue, map and pause code therefore keep one source of truth for controls.

@export var force_visible: bool = false

const MOVE_ACTIONS: Array[StringName] = [
	&"move_left", &"move_right", &"move_up", &"move_down"
]
const BUTTON_ACTIONS: Array[StringName] = [
	&"interact", &"attack", &"scan", &"dodge", &"consume",
	&"memory_burst", &"map", &"archive", &"pause"
]

var _enabled: bool = false
var _root: Control
var _stick_zone: Panel
var _stick_knob: Panel
var _stick_touch: int = -1
var _mouse_stick: bool = false
var _action_cluster: Control
var _tools_panel: PanelContainer
var _tools_open: bool = false
var _held_actions: Dictionary = {}
var _last_paused: bool = false


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	_enabled = force_visible or DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")
	if not _enabled:
		visible = false
		return

	_build_interface()
	get_viewport().size_changed.connect(_layout_interface)
	call_deferred("_layout_interface")


func _process(_delta: float) -> void:
	if not _enabled or _root == null:
		return
	var paused := get_tree().paused
	if paused != _last_paused:
		_last_paused = paused
		_root.visible = not paused
		if paused:
			_release_all_inputs()


func _exit_tree() -> void:
	_release_all_inputs()


func _build_interface() -> void:
	_root = Control.new()
	_root.name = "TouchRoot"
	_root.anchor_right = 1.0
	_root.anchor_bottom = 1.0
	_root.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_root.grow_vertical = Control.GROW_DIRECTION_BOTH
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_build_stick()
	_build_action_cluster()
	_build_tools_panel()


func _build_stick() -> void:
	_stick_zone = Panel.new()
	_stick_zone.name = "MoveStick"
	_stick_zone.mouse_filter = Control.MOUSE_FILTER_STOP
	_stick_zone.add_theme_stylebox_override(
		"panel", _style(Color(0.025, 0.04, 0.04, 0.58), Color(0.33, 0.76, 0.75, 0.72), 72, 2)
	)
	_stick_zone.gui_input.connect(_on_stick_gui_input)
	_root.add_child(_stick_zone)

	_stick_knob = Panel.new()
	_stick_knob.name = "Knob"
	_stick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stick_knob.add_theme_stylebox_override(
		"panel", _style(Color(0.11, 0.16, 0.15, 0.88), Color(0.91, 0.62, 0.26, 0.95), 36, 2)
	)
	_stick_zone.add_child(_stick_knob)

	var label := Label.new()
	label.name = "MoveLabel"
	label.text = "MOVE"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", Color(0.72, 0.78, 0.72, 0.84))
	label.add_theme_font_size_override("font_size", 11)
	label.anchor_left = 0.0
	label.anchor_top = 1.0
	label.anchor_right = 1.0
	label.anchor_bottom = 1.0
	label.offset_top = 4.0
	label.offset_bottom = 24.0
	_stick_zone.add_child(label)


func _build_action_cluster() -> void:
	_action_cluster = Control.new()
	_action_cluster.name = "ActionCluster"
	_action_cluster.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_action_cluster)

	var interact := _make_action_button("Interact", "USE", &"interact", false, Color(0.91, 0.62, 0.26, 0.92))
	var attack := _make_action_button("Attack", "HIT", &"attack", true, Color(0.91, 0.62, 0.26, 1.0))
	var scan := _make_action_button("Scan", "SCAN", &"scan", false, Color(0.30, 0.82, 0.82, 0.95))
	var dodge := _make_action_button("Dodge", "DODGE", &"dodge", false, Color(0.72, 0.73, 0.65, 0.9))

	interact.position = Vector2(75, 11)
	interact.size = Vector2(60, 60)
	attack.position = Vector2(137, 76)
	attack.size = Vector2(70, 70)
	scan.position = Vector2(10, 77)
	scan.size = Vector2(60, 60)
	dodge.position = Vector2(75, 143)
	dodge.size = Vector2(60, 60)

	var tools := Button.new()
	tools.name = "ToolsToggle"
	tools.text = "TOOLS"
	tools.focus_mode = Control.FOCUS_NONE
	tools.mouse_filter = Control.MOUSE_FILTER_STOP
	tools.position = Vector2(147, 12)
	tools.size = Vector2(59, 40)
	tools.add_theme_font_size_override("font_size", 10)
	tools.add_theme_color_override("font_color", Color(0.80, 0.81, 0.74, 1.0))
	tools.add_theme_color_override("font_pressed_color", Color(0.96, 0.78, 0.43, 1.0))
	tools.add_theme_stylebox_override("normal", _style(Color(0.025, 0.035, 0.034, 0.72), Color(0.45, 0.55, 0.50, 0.72), 4, 1))
	tools.add_theme_stylebox_override("hover", _style(Color(0.06, 0.075, 0.07, 0.90), Color(0.91, 0.62, 0.26, 0.90), 4, 2))
	tools.add_theme_stylebox_override("pressed", _style(Color(0.10, 0.09, 0.06, 0.96), Color(0.96, 0.68, 0.30, 1.0), 4, 2))
	tools.pressed.connect(_toggle_tools)
	_action_cluster.add_child(tools)


func _build_tools_panel() -> void:
	_tools_panel = PanelContainer.new()
	_tools_panel.name = "ToolsPanel"
	_tools_panel.visible = false
	_tools_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_tools_panel.add_theme_stylebox_override(
		"panel", _style(Color(0.018, 0.028, 0.027, 0.93), Color(0.37, 0.57, 0.54, 0.76), 5, 1)
	)
	_root.add_child(_tools_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	_tools_panel.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	margin.add_child(row)

	_make_tool_button(row, "HEAL", &"consume")
	_make_tool_button(row, "BURST", &"memory_burst")
	_make_tool_button(row, "MAP", &"map")
	_make_tool_button(row, "LOG", &"archive")
	_make_tool_button(row, "PAUSE", &"pause")


func _make_action_button(
	button_name: String,
	label: String,
	action: StringName,
	large: bool,
	accent: Color
) -> Button:
	var button := Button.new()
	button.name = button_name
	button.text = label
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.add_theme_font_size_override("font_size", 13 if large else 11)
	button.add_theme_color_override("font_color", Color(0.90, 0.89, 0.79, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(1.0, 0.93, 0.73, 1.0))
	button.add_theme_stylebox_override("normal", _style(Color(0.025, 0.04, 0.04, 0.68), accent, 44, 2))
	button.add_theme_stylebox_override("hover", _style(Color(0.06, 0.085, 0.08, 0.90), accent.lightened(0.08), 44, 2))
	button.add_theme_stylebox_override("pressed", _style(Color(0.12, 0.10, 0.065, 0.96), accent.lightened(0.15), 44, 3))
	button.button_down.connect(_press_button_action.bind(action))
	button.button_up.connect(_release_button_action.bind(action))
	_action_cluster.add_child(button)
	return button


func _make_tool_button(parent: HBoxContainer, label: String, action: StringName) -> void:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(53, 36)
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.add_theme_font_size_override("font_size", 9)
	button.add_theme_color_override("font_color", Color(0.78, 0.80, 0.73, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(0.96, 0.78, 0.43, 1.0))
	button.add_theme_stylebox_override("normal", _style(Color(0.035, 0.05, 0.048, 0.86), Color(0.30, 0.47, 0.45, 0.8), 3, 1))
	button.add_theme_stylebox_override("hover", _style(Color(0.07, 0.085, 0.07, 0.96), Color(0.86, 0.60, 0.27, 0.95), 3, 1))
	button.add_theme_stylebox_override("pressed", _style(Color(0.12, 0.10, 0.065, 1.0), Color(0.96, 0.68, 0.30, 1.0), 3, 2))
	button.button_down.connect(_press_button_action.bind(action))
	button.button_up.connect(_release_button_action.bind(action))
	parent.add_child(button)


func _style(background: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.border_width_left = width
	style.border_width_top = width
	style.border_width_right = width
	style.border_width_bottom = width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_right = radius
	style.corner_radius_bottom_left = radius
	return style


func _layout_interface() -> void:
	if _root == null or _stick_zone == null or _action_cluster == null:
		return
	var view_size := get_viewport().get_visible_rect().size
	if view_size.x <= 1.0 or view_size.y <= 1.0:
		return

	var control_scale := 0.84 if view_size.x < 390.0 else 1.0
	_stick_zone.scale = Vector2.ONE * control_scale
	_action_cluster.scale = Vector2.ONE * control_scale
	_tools_panel.scale = Vector2.ONE * control_scale

	_stick_zone.position = Vector2(14.0, view_size.y - 150.0 * control_scale - 16.0)
	_stick_zone.size = Vector2(140, 140)
	_stick_knob.size = Vector2(54, 54)
	if _stick_touch < 0 and not _mouse_stick:
		_center_stick()

	_action_cluster.position = Vector2(
		view_size.x - 216.0 * control_scale - 10.0,
		view_size.y - 212.0 * control_scale - 10.0
	)
	_action_cluster.size = Vector2(216, 212)

	_tools_panel.size = Vector2(326, 50)
	_tools_panel.position = Vector2(
		maxf(8.0, view_size.x - 336.0 * control_scale),
		view_size.y - 270.0 * control_scale
	)


func _on_stick_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			AudioManager.unlock_audio()
		if event.pressed and _stick_touch < 0:
			_stick_touch = event.index
			_update_stick(event.position)
			_stick_zone.accept_event()
		elif not event.pressed and event.index == _stick_touch:
			_stick_touch = -1
			_release_movement()
			_center_stick()
			_stick_zone.accept_event()
	elif event is InputEventScreenDrag and event.index == _stick_touch:
		_update_stick(event.position)
		_stick_zone.accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_mouse_stick = event.pressed
		if _mouse_stick:
			_update_stick(event.position)
		else:
			_release_movement()
			_center_stick()
		_stick_zone.accept_event()
	elif event is InputEventMouseMotion and _mouse_stick:
		_update_stick(event.position)
		_stick_zone.accept_event()


func _update_stick(local_position: Vector2) -> void:
	var center := _stick_zone.size * 0.5
	var radius := maxf(1.0, (minf(_stick_zone.size.x, _stick_zone.size.y) - _stick_knob.size.x) * 0.5)
	var offset := (local_position - center).limit_length(radius)
	var vector := offset / radius
	if vector.length() < 0.16:
		vector = Vector2.ZERO

	_stick_knob.position = center + offset - _stick_knob.size * 0.5
	_set_move_action(&"move_left", maxf(-vector.x, 0.0))
	_set_move_action(&"move_right", maxf(vector.x, 0.0))
	_set_move_action(&"move_up", maxf(-vector.y, 0.0))
	_set_move_action(&"move_down", maxf(vector.y, 0.0))


func _center_stick() -> void:
	if _stick_zone == null or _stick_knob == null:
		return
	_stick_knob.position = (_stick_zone.size - _stick_knob.size) * 0.5


func _set_move_action(action: StringName, strength: float) -> void:
	if strength > 0.0:
		Input.action_press(action, strength)
	else:
		Input.action_release(action)


func _press_button_action(action: StringName) -> void:
	AudioManager.unlock_audio()
	if _held_actions.has(action):
		return
	_held_actions[action] = true
	_emit_action(action, true)


func _release_button_action(action: StringName) -> void:
	if not _held_actions.has(action):
		return
	_held_actions.erase(action)
	_emit_action(action, false)


func _emit_action(action: StringName, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	event.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(event)


func _toggle_tools() -> void:
	_tools_open = not _tools_open
	_tools_panel.visible = _tools_open


func _release_movement() -> void:
	for action in MOVE_ACTIONS:
		Input.action_release(action)


func _release_all_inputs() -> void:
	_release_movement()
	for action in BUTTON_ACTIONS:
		if _held_actions.has(action):
			_emit_action(action, false)
	_held_actions.clear()
	_stick_touch = -1
	_mouse_stick = false
	if _stick_knob != null:
		_center_stick()
