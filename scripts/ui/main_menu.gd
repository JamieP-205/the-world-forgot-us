extends Control
## First-launch main menu. Desktop keeps the authored 1280 x 720 composition;
## touch devices receive a physically sized title and menu that survives the
## canvas-items stretch used by the Web build.

const GAME_SCENE := "res://scenes/main.tscn"

var _wash_time := 0.0
var _redraw_accum := 0.0
var _touch_ui := false
var _mobile_tag: Label

@onready var _continue_btn: Button = $Box/Continue
@onready var _box: GridContainer = $Box
@onready var _controls_panel: Control = $ControlsPanel
@onready var _settings_panel: Control = $SettingsPanel
@onready var _confirm: ConfirmationDialog = $NewGameConfirm
@onready var _signal_tag: Label = $SignalTag
@onready var _title: Label = $Title
@onready var _subtitle: Label = $Subtitle
@onready var _title_rule: ColorRect = $TitleRule
@onready var _quote_panel: PanelContainer = $QuotePanel
@onready var _footer_rule: ColorRect = $FooterRule
@onready var _footer: Label = $Footer
@onready var _build_label: Label = $BuildLabel
@onready var _menu_sheet: FieldDocumentSurface = $MenuSheet


func _ready() -> void:
	get_tree().paused = false
	_touch_ui = _is_touch_device()
	$QuotePanel/Margin/Content/Quote.text = "\"Take the tuning plate off.\nIf it doesn't say 14B,\nswitch the set off and walk.\""
	$QuotePanel/Margin/Content/Attribution.text = "- Maggie Ward  /  fault tape 06"
	_footer.text = "Jamie Parr  /  Godot 4.7  /  headphones recommended"

	_continue_btn.disabled = not SaveManager.has_save()
	_continue_btn.pressed.connect(_on_continue)
	$Box/NewGame.pressed.connect(_on_new_game)
	$Box/Controls.pressed.connect(_on_controls)
	$Box/Settings.pressed.connect(_on_settings)
	$Box/Credits.pressed.connect(func() -> void: $CreditsDialog.popup_centered())
	$Box/Quit.pressed.connect(_on_quit_or_fullscreen)
	if OS.has_feature("web"):
		$Box/Quit.text = "Fullscreen"

	_controls_panel.visible = false
	_controls_panel.closed.connect(_on_controls_closed)
	_settings_panel.visible = false
	_settings_panel.closed.connect(_on_settings_closed)
	_confirm.confirmed.connect(_do_new_game)

	_create_mobile_tag()
	get_viewport().size_changed.connect(_apply_responsive_layout)
	_apply_responsive_layout()

	if not _continue_btn.disabled:
		_continue_btn.grab_focus()
	else:
		$Box/NewGame.grab_focus()
	queue_redraw()


func _is_touch_device() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("web_android") \
		or OS.has_feature("web_ios") or DisplayServer.is_touchscreen_available()


func _physical_scale(view: Vector2, window_size: Vector2) -> float:
	if window_size.x <= 1.0 or window_size.y <= 1.0 or view.x <= 1.0 or view.y <= 1.0:
		return 1.0
	return maxf(0.05, minf(window_size.x / view.x, window_size.y / view.y))


func _create_mobile_tag() -> void:
	_mobile_tag = Label.new()
	_mobile_tag.name = "MobileTag"
	_mobile_tag.text = "Touch controls ready  /  landscape recommended"
	_mobile_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mobile_tag.add_theme_color_override("font_color", Color(0.42, 0.84, 0.82, 0.92))
	_mobile_tag.visible = _touch_ui
	_mobile_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_mobile_tag)
	move_child(_mobile_tag, _box.get_index() + 1)


func apply_responsive_layout(
		viewport_size: Vector2,
		touch_override: int = -1,
		window_override: Vector2 = Vector2.ZERO,
	) -> void:
	_apply_responsive_layout(viewport_size, touch_override, window_override)


func _apply_responsive_layout(
		size_override: Vector2 = Vector2.ZERO,
		touch_override: int = -1,
		window_override: Vector2 = Vector2.ZERO,
	) -> void:
	if not is_node_ready():
		return
	var view := size_override if size_override != Vector2.ZERO else size
	var touch_layout := _touch_ui if touch_override < 0 else touch_override == 1
	if not touch_layout:
		_apply_desktop_layout(view)
		return

	var window_size := window_override if window_override != Vector2.ZERO else (
		Vector2(DisplayServer.window_get_size()) if size_override == Vector2.ZERO else view)
	var portrait := window_size.y > window_size.x
	var physical := _physical_scale(view, window_size)
	var ui_scale := clampf(0.92 / physical, 1.0, 2.85)
	var edge := 20.0 * ui_scale
	var button_width := minf(view.x - edge * 2.0, 390.0 * ui_scale)
	var button_base := 48.0
	var separation_base := 8.0 if portrait else 6.0
	var button_height := maxf(button_base * ui_scale, 44.0 / physical)
	var columns := 1 if portrait else 2
	if not portrait:
		button_width = minf((view.x - 56.0 * ui_scale - separation_base * ui_scale) * 0.5, 248.0 * ui_scale)
	var box_width := button_width if portrait else button_width * 2.0 + separation_base * ui_scale
	var rows := 6 if portrait else 3
	var menu_height := button_height * rows + separation_base * ui_scale * (rows - 1)
	var button_font := roundi(clampf(17.0 * ui_scale, 18.0, 46.0))

	_signal_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if portrait else HORIZONTAL_ALIGNMENT_LEFT
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if portrait else HORIZONTAL_ALIGNMENT_LEFT
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if portrait else HORIZONTAL_ALIGNMENT_LEFT
	_signal_tag.add_theme_font_size_override("font_size", roundi(clampf(13.0 * ui_scale, 14.0, 34.0)))
	_title.add_theme_font_size_override("font_size", roundi(clampf(49.0 * ui_scale, 52.0, 104.0)))
	_subtitle.add_theme_font_size_override("font_size", roundi(clampf(15.0 * ui_scale, 16.0, 38.0)))
	_mobile_tag.add_theme_font_size_override("font_size", roundi(clampf(12.0 * ui_scale, 13.0, 30.0)))
	$Box/Controls.text = "Touch guide"
	_box.columns = columns
	_box.add_theme_constant_override("h_separation", roundi(separation_base * ui_scale))
	_box.add_theme_constant_override("v_separation", roundi(separation_base * ui_scale))
	_footer.text = "Jamie Parr  /  Godot 4.7  /  touch controls ready"
	_build_label.text = "Phone layout  /  landscape recommended"
	_mobile_tag.visible = true
	_quote_panel.visible = false
	_footer_rule.visible = false
	_footer.visible = false
	_build_label.visible = false

	for child in _box.get_children():
		if child is Button:
			var button := child as Button
			button.custom_minimum_size = Vector2(button_width, button_height)
			button.add_theme_font_size_override("font_size", button_font)

	if portrait:
		_signal_tag.position = Vector2(edge, 20.0 * ui_scale)
		_signal_tag.size = Vector2(view.x - edge * 2.0, 24.0 * ui_scale)
		_title.position = Vector2(edge, 48.0 * ui_scale)
		_title.size = Vector2(view.x - edge * 2.0, 104.0 * ui_scale)
		_subtitle.position = Vector2(edge, 158.0 * ui_scale)
		_subtitle.size = Vector2(view.x - edge * 2.0, 26.0 * ui_scale)
		_title_rule.position = Vector2((view.x - box_width) * 0.5, 188.0 * ui_scale)
		_title_rule.size = Vector2(box_width, maxf(2.0, 1.4 * ui_scale))
		_mobile_tag.position = Vector2(edge, 199.0 * ui_scale)
		_mobile_tag.size = Vector2(view.x - edge * 2.0, 24.0 * ui_scale)
		_mobile_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_box.position = Vector2((view.x - box_width) * 0.5, 232.0 * ui_scale)
		_menu_sheet.position = Vector2(maxf(6.0, edge * 0.22), maxf(6.0, 8.0 * ui_scale))
		_menu_sheet.size = Vector2(
			view.x - _menu_sheet.position.x * 2.0,
			minf(view.y - _menu_sheet.position.y * 2.0,
				_box.position.y + menu_height + 20.0 * ui_scale - _menu_sheet.position.y),
		)
	else:
		var left := 28.0 * ui_scale
		_signal_tag.position = Vector2(left, 16.0 * ui_scale)
		_signal_tag.size = Vector2(box_width, 24.0 * ui_scale)
		_title.position = Vector2(left, 36.0 * ui_scale)
		_title.size = Vector2(box_width, 92.0 * ui_scale)
		_subtitle.position = Vector2(left, 167.0 * ui_scale)
		_subtitle.size = Vector2(box_width, 24.0 * ui_scale)
		_title_rule.position = Vector2(left, 191.0 * ui_scale)
		_title_rule.size = Vector2(box_width, maxf(2.0, 1.4 * ui_scale))
		_mobile_tag.position = Vector2(left, 200.0 * ui_scale)
		_mobile_tag.size = Vector2(box_width, 22.0 * ui_scale)
		_mobile_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_box.position = Vector2(left, 220.0 * ui_scale)
		_menu_sheet.position = Vector2(maxf(6.0, left - 18.0 * ui_scale), maxf(6.0, 7.0 * ui_scale))
		_menu_sheet.size = Vector2(
			box_width + 36.0 * ui_scale,
			minf(view.y - _menu_sheet.position.y * 2.0,
				_box.position.y + menu_height + 18.0 * ui_scale - _menu_sheet.position.y),
		)

	_box.size = Vector2(
		box_width,
		menu_height
	)


func _apply_desktop_layout(view: Vector2 = Vector2.ZERO) -> void:
	if view == Vector2.ZERO:
		view = size
	_menu_sheet.position = Vector2(42.0, 22.0)
	_menu_sheet.size = Vector2(396.0, 590.0)
	_signal_tag.position = Vector2(74.0, 42.0)
	_signal_tag.size = Vector2(356.0, 22.0)
	_signal_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_signal_tag.add_theme_font_size_override("font_size", 13)
	_title.position = Vector2(70.0, 72.0)
	_title.size = Vector2(580.0, 114.0)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_title.add_theme_font_size_override("font_size", 49)
	_subtitle.position = Vector2(74.0, 198.0)
	_subtitle.size = Vector2(486.0, 26.0)
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_subtitle.add_theme_font_size_override("font_size", 15)
	_title_rule.position = Vector2(74.0, 240.0)
	_title_rule.size = Vector2(332.0, 2.0)
	_box.position = Vector2(74.0, 274.0)
	_box.size = Vector2(332.0, 321.0)
	_box.columns = 1
	_box.add_theme_constant_override("h_separation", 9)
	_box.add_theme_constant_override("v_separation", 9)
	for child in _box.get_children():
		if child is Button:
			var button := child as Button
			button.custom_minimum_size = Vector2(332.0, 46.0)
			button.add_theme_font_size_override("font_size", 17)
	$Box/Controls.text = "Field guide"
	_quote_panel.visible = true
	_footer_rule.visible = true
	_footer.visible = true
	_footer_rule.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_footer.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_build_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_footer_rule.position = Vector2(74.0, view.y - 54.0)
	_footer_rule.size = Vector2(maxf(0.0, view.x - 148.0), 1.0)
	_footer.position = Vector2(74.0, view.y - 42.0)
	_footer.size = Vector2(576.0, 25.0)
	_build_label.position = Vector2(maxf(0.0, view.x - 340.0), view.y - 42.0)
	_build_label.size = Vector2(266.0, 25.0)
	_build_label.visible = true
	_mobile_tag.visible = false


func _process(delta: float) -> void:
	_wash_time += delta
	_redraw_accum += delta
	if _redraw_accum >= 0.05:
		_redraw_accum = 0.0
		queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w <= 1.0 or h <= 1.0:
		return

	# The title is laid out on a field sheet inside Carriage 317. The rest of
	# the screen is the rain-blackened carriage wall and its depot window.
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.025, 0.03, 0.027, 1.0))
	for seam in 8:
		var seam_y := h * (0.08 + seam * 0.105)
		draw_line(Vector2.ZERO + Vector2(0, seam_y), Vector2(w, seam_y + 2), Color(0.19, 0.2, 0.17, 0.12), 2.0)
		draw_line(Vector2(0, seam_y + 3), Vector2(w, seam_y + 4), Color(0, 0, 0, 0.27), 1.0)

	var window := Rect2(w * 0.44, h * 0.065, w * 0.515, h * 0.64)
	draw_rect(window.grow(13.0), Color(0.055, 0.06, 0.054, 1.0))
	draw_rect(window.grow(7.0), Color(0.24, 0.23, 0.18, 0.68), false, 3.0)
	draw_rect(window, Color(0.115, 0.15, 0.145, 1.0))
	draw_rect(window, Color(0.39, 0.47, 0.43, 0.14))

	# Cullbrook's closed service buildings remain barely legible through wet
	# glass: a familiar British road stop, not an abstract sci-fi backdrop.
	var ground_y := window.position.y + window.size.y * 0.68
	draw_colored_polygon(PackedVector2Array([
		Vector2(window.position.x, ground_y - 14),
		Vector2(window.position.x + window.size.x * 0.16, ground_y - 27),
		Vector2(window.position.x + window.size.x * 0.31, ground_y - 12),
		Vector2(window.position.x + window.size.x * 0.49, ground_y - 31),
		Vector2(window.position.x + window.size.x * 0.7, ground_y - 16),
		Vector2(window.end.x, ground_y - 25), Vector2(window.end.x, window.end.y),
		Vector2(window.position.x, window.end.y),
	]), Color(0.045, 0.061, 0.056, 0.98))
	var services := Rect2(window.position.x + window.size.x * 0.31, ground_y - 80, window.size.x * 0.27, 68)
	draw_rect(services, Color(0.055, 0.068, 0.061, 1.0))
	draw_colored_polygon(PackedVector2Array([
		services.position + Vector2(-9, 4), services.position + Vector2(services.size.x * 0.48, -14),
		services.position + Vector2(services.size.x + 8, 4), services.position + Vector2(services.size.x, 11),
		services.position + Vector2(0, 11),
	]), Color(0.07, 0.075, 0.064, 1.0))
	for pane in 3:
		draw_rect(Rect2(services.position + Vector2(15 + pane * 34, 28), Vector2(20, 24)), Color(0.54, 0.36, 0.16, 0.18))
	draw_colored_polygon(PackedVector2Array([
		Vector2(window.position.x, ground_y + 30), Vector2(window.end.x, ground_y - 2),
		Vector2(window.end.x, window.end.y), Vector2(window.position.x, window.end.y),
	]), Color(0.055, 0.062, 0.056, 0.92))

	# Depot lamp and telegraph pole establish scale and place without turning
	# into objective markers.
	var lamp_x := window.position.x + window.size.x * 0.73
	draw_line(Vector2(lamp_x, ground_y + 12), Vector2(lamp_x, ground_y - 95), Color(0.035, 0.04, 0.036), 3.0)
	draw_line(Vector2(lamp_x - 13, ground_y - 89), Vector2(lamp_x + 13, ground_y - 89), Color(0.035, 0.04, 0.036), 2.0)
	draw_rect(Rect2(lamp_x - 5, ground_y - 96, 10, 7), Color(0.7, 0.45, 0.19, 0.32))

	# Rain travels at slightly different rates across the glass; the fixed
	# seeds keep the image calm and reproducible.
	for drop in 34:
		var drop_x := window.position.x + fmod(float(drop * 83), maxf(1.0, window.size.x - 8.0)) + 4.0
		var travel := fmod(_wash_time * (18.0 + drop % 5 * 5.0) + drop * 37.0, window.size.y + 54.0) - 27.0
		var drop_y := window.position.y + travel
		var end_y := minf(drop_y + 12.0 + drop % 4 * 5.0, window.end.y)
		if drop_y >= window.position.y and drop_y <= window.end.y:
			draw_line(Vector2(drop_x, drop_y), Vector2(drop_x - 2.0, end_y), Color(0.66, 0.76, 0.71, 0.12 + (drop % 3) * 0.025), 1.0)
	for wipe in 4:
		var wipe_y := window.position.y + window.size.y * (0.22 + wipe * 0.18)
		draw_line(Vector2(window.position.x + 10, wipe_y), Vector2(window.end.x - 12, wipe_y + sin(wipe) * 3), Color(0.75, 0.8, 0.69, 0.035), 3.0)

	# The lower third is the carriage workbench, including the receiver cable
	# that visually connects the fault-tape card to the world.
	var bench_y := h * 0.72
	draw_rect(Rect2(0, bench_y, w, h - bench_y), Color(0.058, 0.058, 0.048, 1.0))
	draw_rect(Rect2(0, bench_y, w, 5), Color(0.25, 0.22, 0.15, 0.55))
	for scratch in 11:
		var sy := bench_y + 18.0 + scratch * 13.0
		draw_line(Vector2(w * 0.35, sy), Vector2(w * (0.48 + fmod(scratch * 0.07, 0.42)), sy + sin(scratch) * 4), Color(0.38, 0.35, 0.25, 0.09), 1.0)
	var cable := PackedVector2Array()
	for step in 15:
		var t := float(step) / 14.0
		cable.append(Vector2(w * (0.52 + t * 0.42), bench_y + 36.0 + sin(t * PI * 2.2) * 24.0 + t * 72.0))
	draw_polyline(cable, Color(0.015, 0.018, 0.016, 0.95), 5.0, true)
	draw_polyline(cable, Color(0.19, 0.2, 0.17, 0.42), 1.2, true)


func _input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventScreenTouch:
		if event.pressed:
			AudioManager.unlock_audio()


func _on_continue() -> void:
	if SaveManager.has_save():
		_start_game()


func _on_new_game() -> void:
	if SaveManager.has_save():
		_confirm.popup_centered()
	else:
		_do_new_game()


func _do_new_game() -> void:
	SaveManager.clear_run_state()
	WorldState.set_flag(&"intro_pending")
	_start_game()


func _start_game() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_controls() -> void:
	_box.visible = false
	_controls_panel.visible = true


func _on_controls_closed() -> void:
	_controls_panel.visible = false
	_box.visible = true


func _on_settings() -> void:
	_box.visible = false
	_settings_panel.open_panel()


func _on_settings_closed() -> void:
	_settings_panel.visible = false
	_box.visible = true


func _on_quit_or_fullscreen() -> void:
	AudioManager.unlock_audio()
	if OS.has_feature("web"):
		var mode := DisplayServer.window_get_mode()
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_WINDOWED
			if mode == DisplayServer.WINDOW_MODE_FULLSCREEN
			else DisplayServer.WINDOW_MODE_FULLSCREEN
		)
	else:
		get_tree().quit()
