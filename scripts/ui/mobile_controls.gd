class_name MobileControls
extends Control
## Touch overlay for phone and tablet builds.
##
## A floating left-thumb stick feeds the existing move actions. The right-side
## buttons emit the same actions as the keyboard, so gameplay code remains the
## single source of truth for combat, scanning, interaction and menus.

@export var force_visible := false

const MOVE_DEADZONE := 0.18
const PANEL := Color(0.018, 0.027, 0.027, 0.64)
const PANEL_PRESSED := Color(0.09, 0.13, 0.12, 0.9)
const LINE := Color(0.45, 0.78, 0.75, 0.68)
const AMBER := Color(0.93, 0.67, 0.33, 0.92)
const CYAN := Color(0.42, 0.84, 0.82, 0.92)
const INK := Color(0.94, 0.91, 0.82, 0.94)
const MUTED := Color(0.73, 0.76, 0.71, 0.82)

var _device_enabled := false
var _layout_scale := 1.0
var _move_touch := -1
var _move_center := Vector2.ZERO
var _move_origin := Vector2.ZERO
var _move_knob := Vector2.ZERO
var _move_radius := 76.0
var _touch_roles: Dictionary = {}
var _pressed_visuals: Dictionary = {}
var _buttons: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	set_process_input(true)
	_device_enabled = _should_enable()
	resized.connect(_rebuild_layout)
	get_viewport().size_changed.connect(_rebuild_layout)
	_rebuild_layout()
	_sync_visibility()


func _process(_delta: float) -> void:
	_sync_visibility()


func _should_enable() -> bool:
	if force_visible:
		return true
	if OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios"):
		return true
	return DisplayServer.is_touchscreen_available()


func _sync_visibility() -> void:
	var should_show := _device_enabled and not GameManager.is_input_locked()
	if visible == should_show:
		return
	visible = should_show
	if not visible:
		_release_all()
	queue_redraw()


func _rebuild_layout() -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		return
	_layout_scale = clampf(minf(size.y / 720.0, size.x / 1280.0 * 1.35), 0.62, 1.15)
	_move_radius = 76.0 * _layout_scale
	var edge := 28.0 * _layout_scale
	_move_center = Vector2(edge + _move_radius, size.y - edge - _move_radius)
	if _move_touch < 0:
		_move_origin = _move_center
		_move_knob = _move_origin

	var large := 43.0 * _layout_scale
	var small := 31.0 * _layout_scale
	var right := size.x - edge - large
	var bottom := size.y - edge - large
	var utility_y := edge + small
	var utility_gap := small * 2.25
	var utility_mid := size.x * 0.5

	_buttons = {
		&"interact": {
			"center": Vector2(right, bottom),
			"radius": large,
			"label": "USE",
			"tone": AMBER,
		},
		&"attack": {
			"center": Vector2(right - large * 2.18, bottom + large * 0.08),
			"radius": large,
			"label": "HIT",
			"tone": INK,
		},
		&"scan": {
			"center": Vector2(right, bottom - large * 2.18),
			"radius": large,
			"label": "SCAN",
			"tone": CYAN,
		},
		&"dodge": {
			"center": Vector2(right - large * 2.18, bottom - large * 2.02),
			"radius": large,
			"label": "DODGE",
			"tone": AMBER,
		},
		&"consume": {
			"center": Vector2(right - large * 4.25, bottom + small * 0.15),
			"radius": small,
			"label": "HEAL",
			"tone": INK,
		},
		&"memory_burst": {
			"center": Vector2(right - large * 4.25, bottom - small * 2.25),
			"radius": small,
			"label": "BURST",
			"tone": CYAN,
		},
		&"pause": {
			"center": Vector2(utility_mid - utility_gap, utility_y),
			"radius": small,
			"label": "MENU",
			"tone": AMBER,
		},
		&"map": {
			"center": Vector2(utility_mid, utility_y),
			"radius": small,
			"label": "MAP",
			"tone": INK,
		},
		&"archive": {
			"center": Vector2(utility_mid + utility_gap, utility_y),
			"radius": small,
			"label": "LOG",
			"tone": CYAN,
		},
	}
	queue_redraw()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		var handled := _begin_touch(touch.index, touch.position) if touch.pressed else _end_touch(touch.index)
		if handled:
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if _drag_touch(drag.index, drag.position):
			get_viewport().set_input_as_handled()


func _begin_touch(identifier: int, position: Vector2) -> bool:
	if _move_touch < 0 and position.x <= size.x * 0.47 and position.y >= size.y * 0.38:
		_move_touch = identifier
		_touch_roles[identifier] = &"move"
		_move_origin = _clamp_move_origin(position)
		_update_move(position)
		return true

	var action := _button_at(position)
	if action == &"":
		return false
	_touch_roles[identifier] = action
	_pressed_visuals[action] = true
	_emit_action(action, true)
	_emit_action.call_deferred(action, false)
	queue_redraw()
	return true


func _drag_touch(identifier: int, position: Vector2) -> bool:
	if not _touch_roles.has(identifier):
		return false
	if _touch_roles[identifier] == &"move":
		_update_move(position)
	return true


func _end_touch(identifier: int) -> bool:
	if not _touch_roles.has(identifier):
		return false
	var role: StringName = _touch_roles[identifier]
	_touch_roles.erase(identifier)
	if role == &"move":
		_move_touch = -1
		_move_origin = _move_center
		_move_knob = _move_origin
		_release_movement()
	else:
		_pressed_visuals.erase(role)
	queue_redraw()
	return true


func _clamp_move_origin(position: Vector2) -> Vector2:
	var edge := 20.0 * _layout_scale + _move_radius
	var max_x := maxf(edge, size.x * 0.47 - _move_radius)
	var min_y := minf(size.y - edge, size.y * 0.42 + _move_radius)
	return Vector2(
		clampf(position.x, edge, max_x),
		clampf(position.y, min_y, size.y - edge)
	)


func _update_move(position: Vector2) -> void:
	var offset := position - _move_origin
	if offset.length() > _move_radius:
		offset = offset.normalized() * _move_radius
	_move_knob = _move_origin + offset
	var move := offset / maxf(_move_radius, 1.0)
	if move.length() < MOVE_DEADZONE:
		move = Vector2.ZERO
	else:
		var scaled_length := (move.length() - MOVE_DEADZONE) / (1.0 - MOVE_DEADZONE)
		move = move.normalized() * clampf(scaled_length, 0.0, 1.0)
	_set_movement(move)
	queue_redraw()


func _set_movement(move: Vector2) -> void:
	_set_action_strength(&"move_left", maxf(-move.x, 0.0))
	_set_action_strength(&"move_right", maxf(move.x, 0.0))
	_set_action_strength(&"move_up", maxf(-move.y, 0.0))
	_set_action_strength(&"move_down", maxf(move.y, 0.0))


func _set_action_strength(action: StringName, strength: float) -> void:
	if strength > 0.001:
		Input.action_press(action, strength)
	else:
		Input.action_release(action)


func _release_movement() -> void:
	for action in [&"move_left", &"move_right", &"move_up", &"move_down"]:
		Input.action_release(action)


func _release_all() -> void:
	_release_movement()
	_move_touch = -1
	_move_origin = _move_center
	_move_knob = _move_origin
	_touch_roles.clear()
	_pressed_visuals.clear()


func _emit_action(action: StringName, pressed: bool) -> void:
	var action_event := InputEventAction.new()
	action_event.action = action
	action_event.pressed = pressed
	action_event.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(action_event)


func _button_at(position: Vector2) -> StringName:
	for action in _buttons:
		var data: Dictionary = _buttons[action]
		var center: Vector2 = data["center"]
		var radius: float = data["radius"]
		if position.distance_to(center) <= radius * 1.12:
			return action
	return &""


func _draw() -> void:
	if not _device_enabled or not visible:
		return
	var font := get_theme_default_font()
	var label_size := maxi(11, roundi(13.0 * _layout_scale))
	var primary_size := maxi(12, roundi(14.0 * _layout_scale))

	draw_circle(_move_origin, _move_radius, PANEL)
	draw_arc(_move_origin, _move_radius, 0.0, TAU, 64, LINE, 2.0 * _layout_scale, true)
	draw_circle(_move_knob, _move_radius * 0.42, PANEL_PRESSED)
	draw_arc(_move_knob, _move_radius * 0.42, 0.0, TAU, 48, CYAN, 2.0 * _layout_scale, true)
	draw_string(
		font,
		_move_origin + Vector2(-_move_radius, _move_radius + 18.0 * _layout_scale),
		"MOVE",
		HORIZONTAL_ALIGNMENT_CENTER,
		_move_radius * 2.0,
		label_size,
		MUTED
	)

	for action in _buttons:
		var data: Dictionary = _buttons[action]
		var center: Vector2 = data["center"]
		var radius: float = data["radius"]
		var label: String = data["label"]
		var tone: Color = data["tone"]
		var pressed := _pressed_visuals.has(action)
		draw_circle(center, radius, PANEL_PRESSED if pressed else PANEL)
		draw_arc(center, radius, 0.0, TAU, 48, tone, 2.0 * _layout_scale, true)
		var font_size := primary_size if radius > 36.0 * _layout_scale else label_size
		draw_string(
			font,
			center + Vector2(-radius, font_size * 0.35),
			label,
			HORIZONTAL_ALIGNMENT_CENTER,
			radius * 2.0,
			font_size,
			INK
		)

	if size.y > size.x:
		draw_string(
			font,
			Vector2(size.x * 0.15, size.y * 0.18),
			"TURN THE PHONE SIDEWAYS FOR THE FULL VIEW",
			HORIZONTAL_ALIGNMENT_CENTER,
			size.x * 0.7,
			primary_size,
			AMBER
		)
