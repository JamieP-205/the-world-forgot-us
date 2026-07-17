extends Node
## Headless geometry and input contract for the touch field kit.

const MOBILE_SCENE := preload("res://scenes/ui/mobile_controls.tscn")
const PLAYER_SCENE := preload("res://scenes/player/player.tscn")

var _failures: Array[String] = []
var _checks := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	SettingsManager.set_value("gameplay", "mobile_tutorial_seen", true, false)
	var layer := MOBILE_SCENE.instantiate() as CanvasLayer
	var surface := layer.get_node("Surface") as MobileControls
	surface.force_visible = true
	add_child(layer)
	await get_tree().process_frame

	_check(surface.visible, "forced mobile controls are visible")
	_check_layout(surface, Vector2(1280, 720), false)
	_check_layout(surface, Vector2(390, 844), true)
	_check_input(surface)
	await _check_emulated_click_filter()

	layer.queue_free()
	Input.action_release(&"move_left")
	Input.action_release(&"move_right")
	Input.action_release(&"move_up")
	Input.action_release(&"move_down")
	if _failures.is_empty():
		print("MOBILE CONTROLS CONTRACT PASS (%d checks)" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures:
		push_error("MOBILE CONTROLS: " + failure)
	print("MOBILE CONTROLS CONTRACT FAIL (%d failures / %d checks)" % [
		_failures.size(), _checks])
	get_tree().quit(1)


func _check_layout(surface: MobileControls, viewport_size: Vector2, portrait: bool) -> void:
	surface.size = viewport_size
	surface.call("_rebuild_layout")
	_check(bool(surface.get("_portrait")) == portrait,
		"%s orientation is detected" % ("portrait" if portrait else "landscape"))
	var buttons: Dictionary = surface.get("_buttons")
	_check(buttons.size() == 11, "all four road and seven kit actions are present")
	var scale: float = surface.get("_layout_scale")
	var minimum_edge := 10.0 * scale
	for action in buttons:
		var data: Dictionary = buttons[action]
		var center: Vector2 = data["center"]
		var radius: float = data["radius"]
		_check(radius * 2.0 >= 44.0, "%s keeps a 44-pixel touch diameter" % action)
		_check(center.x - radius >= minimum_edge and center.x + radius <= viewport_size.x - minimum_edge,
			"%s stays inside horizontal safe edges" % action)
		_check(center.y - radius >= minimum_edge and center.y + radius <= viewport_size.y - minimum_edge,
			"%s stays inside vertical safe edges" % action)

	var road := [&"interact", &"attack", &"scan", &"dodge"]
	for first_index in range(road.size()):
		for second_index in range(first_index + 1, road.size()):
			var first: Dictionary = buttons[road[first_index]]
			var second: Dictionary = buttons[road[second_index]]
			_check((first.center as Vector2).distance_to(second.center) >= \
				(float(first.radius) + float(second.radius)) * 0.94,
				"road actions %s and %s do not overlap" % [road[first_index], road[second_index]])

	var move_center: Vector2 = surface.get("_move_center")
	var move_radius: float = surface.get("_move_radius")
	for action in road:
		var data: Dictionary = buttons[action]
		_check(move_center.distance_to(data.center) > move_radius + float(data.radius) + 24.0 * scale,
			"movement and %s remain separate thumb zones" % action)
	if portrait:
		for action in buttons:
			var data: Dictionary = buttons[action]
			if String(data.get("group", "")) != "kit":
				continue
			_check(move_center.distance_to(data.center) > move_radius + float(data.radius),
				"open kit action %s stays clear of the portrait joystick" % action)
			for road_action in road:
				var road_data: Dictionary = buttons[road_action]
				_check((data.center as Vector2).distance_to(road_data.center) \
						> float(data.radius) + float(road_data.radius),
					"open kit action %s stays clear of %s" % [action, road_action])


func _check_input(surface: MobileControls) -> void:
	surface.size = Vector2(1280, 720)
	surface.call("_rebuild_layout")
	var origin: Vector2 = surface.get("_move_center")
	var radius: float = surface.get("_move_radius")
	_check(bool(surface.call("_begin_touch", 41, origin)),
		"left-thumb drag is accepted")
	surface.call("_drag_touch", 41, origin + Vector2(radius, 0.0))
	_check(Input.get_action_strength(&"move_right") > 0.9,
		"rightward drag reaches full analogue strength")
	_check(bool(surface.call("_end_touch", 41)), "movement touch releases cleanly")
	_check(Input.get_action_strength(&"move_right") <= 0.001,
		"movement action is released with the touch")

	var kit_center: Vector2 = surface.get("_kit_toggle_center")
	_check(bool(surface.call("_begin_touch", 42, kit_center)), "field-kit tab accepts touch")
	_check(bool(surface.get("_kit_open")), "field-kit tray opens")
	var buttons: Dictionary = surface.get("_buttons")
	var craft: Dictionary = buttons[&"craft"]
	_check(surface.call("_button_at", craft.center) == &"craft",
		"crafting remains reachable from the open tray")

	# Portrait puts several kit buttons inside the broad movement half. Every
	# visible action must win input routing and leave the joystick untouched.
	surface.size = Vector2(390, 844)
	surface.call("_rebuild_layout")
	buttons = surface.get("_buttons")
	var touch_id := 70
	for action in buttons:
		var data: Dictionary = buttons[action]
		if String(data.get("group", "")) != "kit":
			continue
		surface.set("_kit_open", true)
		var accepted := bool(surface.call("_begin_touch", touch_id, data.center))
		_check(accepted, "portrait kit action %s accepts touch" % action)
		_check(int(surface.get("_move_touch")) < 0,
			"portrait kit action %s is never mistaken for movement" % action)
		if action == &"mobile_help":
			surface.call("_dismiss_tutorial")
		else:
			var roles: Dictionary = surface.get("_touch_roles")
			_check(roles.get(touch_id, &"") == action,
				"portrait kit action %s keeps its input role" % action)
			surface.call("_end_touch", touch_id)
			touch_id += 1


func _check_emulated_click_filter() -> void:
	GameManager.set_dialogue_active(false)
	var player := PLAYER_SCENE.instantiate() as Player
	add_child(player)
	await get_tree().process_frame
	player.set("_attack_cd", 0.0)

	var mirrored_touch := InputEventMouseButton.new()
	mirrored_touch.device = InputEvent.DEVICE_ID_EMULATION
	mirrored_touch.button_index = MOUSE_BUTTON_LEFT
	mirrored_touch.pressed = true
	player.call("_unhandled_input", mirrored_touch)
	_check(is_zero_approx(float(player.get("_attack_cd"))),
		"browser touch emulation cannot trigger a stray melee swing")

	var deliberate_attack := InputEventAction.new()
	deliberate_attack.action = &"attack"
	deliberate_attack.pressed = true
	player.call("_unhandled_input", deliberate_attack)
	_check(float(player.get("_attack_cd")) > 0.0,
		"the touch surface's deliberate attack action still reaches combat")
	player.free()


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
