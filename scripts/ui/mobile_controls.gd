class_name MobileControls
extends Control
## Touch overlay for phone and tablet builds.
##
## A floating left-thumb stick feeds the existing move actions. Four road
## actions stay available on the right; less frequent actions live in a small
## field-kit tray so the game remains visible on a phone screen.

@export var force_visible := false

const MOVE_DEADZONE := 0.18
const PANEL := Color(0.018, 0.027, 0.027, 0.64)
const PANEL_STRONG := Color(0.018, 0.027, 0.027, 0.9)
const PANEL_PRESSED := Color(0.09, 0.13, 0.12, 0.92)
const LINE := Color(0.45, 0.78, 0.75, 0.68)
const AMBER := Color(0.93, 0.67, 0.33, 0.92)
const CYAN := Color(0.42, 0.84, 0.82, 0.92)
const INK := Color(0.94, 0.91, 0.82, 0.94)
const MUTED := Color(0.73, 0.76, 0.71, 0.82)
const TUTORIAL_SETTING := "mobile_tutorial_seen"
const NORMAL_LAYER := 90
const TUTORIAL_LAYER := 110

var _device_enabled := false
var _layout_scale := 1.0
var _portrait := false
var _move_touch := -1
var _move_center := Vector2.ZERO
var _move_origin := Vector2.ZERO
var _move_knob := Vector2.ZERO
var _move_radius := 76.0
var _touch_roles: Dictionary = {}
var _pressed_visuals: Dictionary = {}
var _buttons: Dictionary = {}
var _kit_open := false
var _kit_toggle_center := Vector2.ZERO
var _kit_toggle_radius := 30.0
var _action_backdrop := Rect2()
var _kit_backdrop := Rect2()
var _tutorial_rect := Rect2()
var _tutorial_visible := false
var _tutorial_seen := false
var _tutorial_owns_lock := false
var _tutorial_ready_after_msec := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	set_process_input(true)
	_device_enabled = _should_enable()
	_tutorial_seen = SettingsManager.get_bool("gameplay", TUTORIAL_SETTING, false)
	_tutorial_ready_after_msec = Time.get_ticks_msec() + 900
	resized.connect(_rebuild_layout)
	get_viewport().size_changed.connect(_rebuild_layout)
	_rebuild_layout()
	_sync_visibility()


func _exit_tree() -> void:
	_release_all()
	if _tutorial_owns_lock:
		_tutorial_owns_lock = false
		GameManager.set_dialogue_active(false)


func _process(_delta: float) -> void:
	_sync_visibility()


func _should_enable() -> bool:
	if force_visible:
		return true
	if OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios"):
		return true
	return DisplayServer.is_touchscreen_available()


func _sync_visibility() -> void:
	var should_show := _device_enabled and (_tutorial_visible or not GameManager.is_input_locked())
	if visible != should_show:
		visible = should_show
		if not visible:
			_release_all()
		queue_redraw()
	if should_show and not _tutorial_seen and not _tutorial_visible \
			and Time.get_ticks_msec() >= _tutorial_ready_after_msec:
		_show_tutorial()


func _physical_scale() -> float:
	var window_size := Vector2(DisplayServer.window_get_size())
	if window_size.x <= 1.0 or window_size.y <= 1.0 or size.x <= 1.0 or size.y <= 1.0:
		return 1.0
	return maxf(0.05, minf(window_size.x / size.x, window_size.y / size.y))


func _rebuild_layout() -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		return

	_portrait = size.y > size.x
	var base_scale := minf(size.y / 720.0, size.x / 1280.0 * 1.35)
	var physical_boost := clampf(0.9 / _physical_scale(), 0.78, 2.25)
	_layout_scale = clampf(base_scale * physical_boost * (0.84 if _portrait else 1.0), 0.72, 2.0)
	_move_radius = 70.0 * _layout_scale
	var edge := 20.0 * _layout_scale
	_move_center = Vector2(edge + _move_radius, size.y - edge - _move_radius)
	if _move_touch < 0:
		_move_origin = _move_center
		_move_knob = _move_origin

	var large := 41.0 * _layout_scale
	var small := 27.0 * _layout_scale
	var right := size.x - edge - large
	var bottom := size.y - edge - large
	if _portrait:
		bottom = size.y - edge - large * 1.05

	_buttons = {
		&"interact": {
			"center": Vector2(right, bottom),
			"radius": large,
			"label": "USE",
			"tone": AMBER,
			"group": "road",
		},
		&"attack": {
			"center": Vector2(right - large * 2.18, bottom + large * 0.08),
			"radius": large,
			"label": "HIT",
			"tone": INK,
			"group": "road",
		},
		&"scan": {
			"center": Vector2(right, bottom - large * 2.18),
			"radius": large,
			"label": "SCAN",
			"tone": CYAN,
			"group": "road",
		},
		&"dodge": {
			"center": Vector2(right - large * 2.18, bottom - large * 2.02),
			"radius": large,
			"label": "DODGE",
			"tone": AMBER,
			"group": "road",
		},
	}

	_kit_toggle_radius = small * 1.08
	_kit_toggle_center = Vector2(right - large * 4.02, bottom - large * 0.96)

	var tray_gap := small * 2.28
	var tray_left := maxf(edge + small, right - large * 7.15)
	var tray_top := bottom - small * 2.72
	if _portrait:
		tray_left = maxf(edge + small, right - large * 6.45)
		tray_top = bottom - small * 3.05

	_buttons.merge({
		&"consume": {
			"center": Vector2(tray_left, tray_top),
			"radius": small,
			"label": "HEAL",
			"tone": INK,
			"group": "kit",
		},
		&"memory_burst": {
			"center": Vector2(tray_left + tray_gap, tray_top),
			"radius": small,
			"label": "BURST",
			"tone": CYAN,
			"group": "kit",
		},
		&"mobile_help": {
			"center": Vector2(tray_left + tray_gap * 2.0, tray_top),
			"radius": small,
			"label": "HELP",
			"tone": CYAN,
			"group": "kit",
		},
		&"pause": {
			"center": Vector2(tray_left, tray_top + tray_gap),
			"radius": small,
			"label": "MENU",
			"tone": AMBER,
			"group": "kit",
		},
		&"map": {
			"center": Vector2(tray_left + tray_gap, tray_top + tray_gap),
			"radius": small,
			"label": "MAP",
			"tone": INK,
			"group": "kit",
		},
		&"archive": {
			"center": Vector2(tray_left + tray_gap * 2.0, tray_top + tray_gap),
			"radius": small,
			"label": "LOG",
			"tone": CYAN,
			"group": "kit",
		},
	})

	_action_backdrop = Rect2(
		Vector2(right - large * 3.25, bottom - large * 3.12),
		Vector2(large * 4.35, large * 4.25)
	)
	_kit_backdrop = Rect2(
		Vector2(tray_left - small * 1.25, tray_top - small * 1.28),
		Vector2(tray_gap * 2.0 + small * 2.5, tray_gap + small * 2.56)
	)

	var tutorial_width := minf(size.x - edge * 2.0, 650.0 * _layout_scale)
	var tutorial_height := (390.0 if _portrait else 320.0) * _layout_scale
	_tutorial_rect = Rect2(
		Vector2((size.x - tutorial_width) * 0.5, (size.y - tutorial_height) * 0.5),
		Vector2(tutorial_width, tutorial_height)
	)
	queue_redraw()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if _tutorial_visible:
		if event is InputEventScreenTouch and event.pressed:
			_dismiss_tutorial()
			get_viewport().set_input_as_handled()
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_dismiss_tutorial()
			get_viewport().set_input_as_handled()
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
	AudioManager.unlock_audio()
	if _move_touch < 0 and position.x <= size.x * 0.47 and position.y >= size.y * 0.34:
		_move_touch = identifier
		_touch_roles[identifier] = &"move"
		_move_origin = _clamp_move_origin(position)
		_update_move(position)
		return true

	if position.distance_to(_kit_toggle_center) <= _kit_toggle_radius * 1.2:
		_kit_open = not _kit_open
		_pressed_visuals.clear()
		_pulse(12)
		queue_redraw()
		return true

	var action := _button_at(position)
	if action == &"":
		if _kit_open:
			_kit_open = false
			queue_redraw()
		return false
	if action == &"mobile_help":
		_kit_open = false
		_pulse(12)
		_show_tutorial()
		return true

	_touch_roles[identifier] = action
	_pressed_visuals[action] = true
	_emit_action(action, true)
	_emit_action.call_deferred(action, false)
	_pulse(18)
	if _is_kit_action(action):
		_kit_open = false
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
	var edge := 16.0 * _layout_scale + _move_radius
	var max_x := maxf(edge, size.x * 0.47 - _move_radius)
	var min_y := minf(size.y - edge, size.y * 0.36 + _move_radius)
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
	_kit_open = false


func _emit_action(action: StringName, pressed: bool) -> void:
	var action_event := InputEventAction.new()
	action_event.action = action
	action_event.pressed = pressed
	action_event.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(action_event)


func _pulse(duration_msec: int) -> void:
	Input.vibrate_handheld(duration_msec)


func _is_kit_action(action: StringName) -> bool:
	var data: Dictionary = _buttons.get(action, {})
	return String(data.get("group", "")) == "kit"


func _button_at(position: Vector2) -> StringName:
	for action in _buttons:
		var data: Dictionary = _buttons[action]
		if String(data.get("group", "road")) == "kit" and not _kit_open:
			continue
		var center: Vector2 = data["center"]
		var radius: float = data["radius"]
		if position.distance_to(center) <= radius * 1.12:
			return action
	return &""


func _show_tutorial() -> void:
	if _tutorial_visible:
		return
	_tutorial_visible = true
	_kit_open = false
	_release_all()
	if not GameManager.is_input_locked():
		_tutorial_owns_lock = true
		GameManager.set_dialogue_active(true)
	var canvas := get_parent() as CanvasLayer
	if canvas != null:
		canvas.layer = TUTORIAL_LAYER
	queue_redraw()


func _dismiss_tutorial() -> void:
	_tutorial_visible = false
	var canvas := get_parent() as CanvasLayer
	if canvas != null:
		canvas.layer = NORMAL_LAYER
	if _tutorial_owns_lock:
		_tutorial_owns_lock = false
		GameManager.set_dialogue_active(false)
	if not _tutorial_seen:
		_tutorial_seen = true
		SettingsManager.set_value("gameplay", TUTORIAL_SETTING, true)
	queue_redraw()


func _draw_control_backdrops() -> void:
	draw_rect(_action_backdrop, Color(PANEL.r, PANEL.g, PANEL.b, 0.3), true)
	draw_rect(_action_backdrop, Color(LINE.r, LINE.g, LINE.b, 0.25), false, maxf(1.0, _layout_scale))
	if _kit_open:
		draw_rect(_kit_backdrop, Color(PANEL.r, PANEL.g, PANEL.b, 0.72), true)
		draw_rect(_kit_backdrop, Color(AMBER.r, AMBER.g, AMBER.b, 0.46), false, maxf(1.0, _layout_scale))


func _draw_tutorial(font: Font, label_size: int, _primary_size: int) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.003, 0.006, 0.006, 0.82), true)
	draw_rect(_tutorial_rect, PANEL_STRONG, true)
	draw_rect(_tutorial_rect, CYAN, false, maxf(2.0, _layout_scale * 1.5))

	var left := _tutorial_rect.position.x + 30.0 * _layout_scale
	var top := _tutorial_rect.position.y + 36.0 * _layout_scale
	var width := _tutorial_rect.size.x - 60.0 * _layout_scale
	var heading_size := maxi(18, roundi(24.0 * _layout_scale))
	var body_size := maxi(12, roundi(14.0 * _layout_scale))
	var step_gap := 66.0 * _layout_scale

	draw_string(font, Vector2(left, top), "PHONE FIELD GUIDE", HORIZONTAL_ALIGNMENT_LEFT, width, heading_size, INK)
	draw_string(font, Vector2(left, top + 28.0 * _layout_scale), "THE ROAD USES TWO THUMBS", HORIZONTAL_ALIGNMENT_LEFT, width, label_size, CYAN)

	var first_y := top + 78.0 * _layout_scale
	_draw_tutorial_step(font, Vector2(left, first_y), "01", "MOVE", "Drag lower-left. The stick follows your thumb.", width, body_size)
	_draw_tutorial_step(font, Vector2(left, first_y + step_gap), "02", "ACT", "Right side: USE, HIT, SCAN and DODGE.", width, body_size)
	_draw_tutorial_step(font, Vector2(left, first_y + step_gap * 2.0), "03", "KIT", "Tap KIT for HEAL, BURST, HELP, MENU, MAP and LOG.", width, body_size)

	var footer_y := _tutorial_rect.end.y - 34.0 * _layout_scale
	var footer := "HELP REOPENS THIS GUIDE  /  TAP ANYWHERE TO START"
	if _portrait:
		footer = "LANDSCAPE RECOMMENDED  /  TAP ANYWHERE TO START"
	draw_string(font, Vector2(left, footer_y), footer, HORIZONTAL_ALIGNMENT_CENTER, width, label_size, AMBER)


func _draw_tutorial_step(
	font: Font,
	position: Vector2,
	number: String,
	heading: String,
	body: String,
	width: float,
	font_size: int
) -> void:
	var number_width := 44.0 * _layout_scale
	draw_string(font, position, number, HORIZONTAL_ALIGNMENT_LEFT, number_width, font_size, AMBER)
	draw_string(font, position + Vector2(number_width, 0.0), heading, HORIZONTAL_ALIGNMENT_LEFT, 82.0 * _layout_scale, font_size, INK)
	draw_string(font, position + Vector2(number_width + 82.0 * _layout_scale, 0.0), body, HORIZONTAL_ALIGNMENT_LEFT, width - number_width - 82.0 * _layout_scale, font_size, MUTED)


func _draw_button(font: Font, action: StringName, label_size: int, primary_size: int) -> void:
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


func _draw() -> void:
	if not _device_enabled or not visible:
		return
	var font := get_theme_default_font()
	var label_size := maxi(11, roundi(12.0 * _layout_scale))
	var primary_size := maxi(12, roundi(14.0 * _layout_scale))

	_draw_control_backdrops()
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
		if String(data.get("group", "road")) == "kit" and not _kit_open:
			continue
		_draw_button(font, action, label_size, primary_size)

	draw_circle(_kit_toggle_center, _kit_toggle_radius, PANEL_PRESSED if _kit_open else PANEL)
	draw_arc(_kit_toggle_center, _kit_toggle_radius, 0.0, TAU, 48, AMBER, 2.0 * _layout_scale, true)
	draw_string(
		font,
		_kit_toggle_center + Vector2(-_kit_toggle_radius, label_size * 0.35),
		"CLOSE" if _kit_open else "KIT",
		HORIZONTAL_ALIGNMENT_CENTER,
		_kit_toggle_radius * 2.0,
		label_size,
		INK
	)

	if _portrait and not _tutorial_visible:
		draw_string(
			font,
			Vector2(size.x * 0.15, size.y * 0.18),
			"TURN THE PHONE SIDEWAYS FOR THE FULL VIEW",
			HORIZONTAL_ALIGNMENT_CENTER,
			size.x * 0.7,
			primary_size,
			AMBER
		)

	if _tutorial_visible:
		_draw_tutorial(font, label_size, primary_size)
