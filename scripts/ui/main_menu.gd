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
@onready var _box: VBoxContainer = $Box
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


func _ready() -> void:
	get_tree().paused = false
	_touch_ui = _is_touch_device()
	$QuotePanel/Margin/Content/Quote.text = "\"Take the tuning plate off.\nIf it doesn't say 14B,\nswitch the set off and walk.\""
	$QuotePanel/Margin/Content/Attribution.text = "- MAGGIE WARD  /  FAULT TAPE 06"
	_footer.text = "JAMIE PARR  /  GODOT 4.7  /  HEADPHONES RECOMMENDED"

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


func _physical_scale() -> float:
	var window_size := Vector2(DisplayServer.window_get_size())
	if window_size.x <= 1.0 or window_size.y <= 1.0 or size.x <= 1.0 or size.y <= 1.0:
		return 1.0
	return maxf(0.05, minf(window_size.x / size.x, window_size.y / size.y))


func _create_mobile_tag() -> void:
	_mobile_tag = Label.new()
	_mobile_tag.name = "MobileTag"
	_mobile_tag.text = "TOUCH CONTROLS READY  /  LANDSCAPE RECOMMENDED"
	_mobile_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mobile_tag.add_theme_color_override("font_color", Color(0.42, 0.84, 0.82, 0.92))
	_mobile_tag.visible = _touch_ui
	_mobile_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_mobile_tag)
	move_child(_mobile_tag, _box.get_index() + 1)


func _apply_responsive_layout() -> void:
	if not is_node_ready():
		return
	if not _touch_ui:
		_apply_desktop_layout()
		return

	var view := size
	var window_size := Vector2(DisplayServer.window_get_size())
	var portrait := window_size.y > window_size.x
	var ui_scale := clampf(0.92 / _physical_scale(), 1.0, 2.85)
	var edge := 20.0 * ui_scale
	var menu_width := minf(view.x - edge * 2.0, 390.0 * ui_scale)
	var button_base := 46.0 if portrait else 40.0
	var separation_base := 8.0 if portrait else 6.0
	var button_height := button_base * ui_scale
	var button_font := roundi(clampf(17.0 * ui_scale, 18.0, 46.0))

	_signal_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if portrait else HORIZONTAL_ALIGNMENT_LEFT
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if portrait else HORIZONTAL_ALIGNMENT_LEFT
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if portrait else HORIZONTAL_ALIGNMENT_LEFT
	_signal_tag.add_theme_font_size_override("font_size", roundi(clampf(13.0 * ui_scale, 14.0, 34.0)))
	_title.add_theme_font_size_override("font_size", roundi(clampf(49.0 * ui_scale, 52.0, 104.0)))
	_subtitle.add_theme_font_size_override("font_size", roundi(clampf(15.0 * ui_scale, 16.0, 38.0)))
	_mobile_tag.add_theme_font_size_override("font_size", roundi(clampf(12.0 * ui_scale, 13.0, 30.0)))
	$Box/Controls.text = "TOUCH GUIDE"
	_box.add_theme_constant_override("separation", roundi(separation_base * ui_scale))
	_footer.text = "JAMIE PARR  /  GODOT 4.7  /  TOUCH CONTROLS READY"
	_build_label.text = "PHONE BUILD  /  LANDSCAPE RECOMMENDED"
	_mobile_tag.visible = true
	_quote_panel.visible = false
	_footer_rule.visible = false
	_footer.visible = false
	_build_label.visible = false

	for child in _box.get_children():
		if child is Button:
			var button := child as Button
			button.custom_minimum_size = Vector2(menu_width, button_height)
			button.add_theme_font_size_override("font_size", button_font)

	if portrait:
		_signal_tag.position = Vector2(edge, 20.0 * ui_scale)
		_signal_tag.size = Vector2(view.x - edge * 2.0, 24.0 * ui_scale)
		_title.position = Vector2(edge, 48.0 * ui_scale)
		_title.size = Vector2(view.x - edge * 2.0, 104.0 * ui_scale)
		_subtitle.position = Vector2(edge, 158.0 * ui_scale)
		_subtitle.size = Vector2(view.x - edge * 2.0, 26.0 * ui_scale)
		_title_rule.position = Vector2((view.x - menu_width) * 0.5, 188.0 * ui_scale)
		_title_rule.size = Vector2(menu_width, maxf(2.0, 1.4 * ui_scale))
		_mobile_tag.position = Vector2(edge, 199.0 * ui_scale)
		_mobile_tag.size = Vector2(view.x - edge * 2.0, 24.0 * ui_scale)
		_mobile_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_box.position = Vector2((view.x - menu_width) * 0.5, 232.0 * ui_scale)
	else:
		var left := 28.0 * ui_scale
		_signal_tag.position = Vector2(left, 16.0 * ui_scale)
		_signal_tag.size = Vector2(menu_width, 24.0 * ui_scale)
		_title.position = Vector2(left, 36.0 * ui_scale)
		_title.size = Vector2(menu_width, 92.0 * ui_scale)
		_subtitle.position = Vector2(left, 124.0 * ui_scale)
		_subtitle.size = Vector2(menu_width, 24.0 * ui_scale)
		_title_rule.position = Vector2(left, 149.0 * ui_scale)
		_title_rule.size = Vector2(menu_width, maxf(2.0, 1.4 * ui_scale))
		_mobile_tag.position = Vector2(left, 158.0 * ui_scale)
		_mobile_tag.size = Vector2(menu_width, 22.0 * ui_scale)
		_mobile_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_box.position = Vector2(left, 181.0 * ui_scale)

	_box.size = Vector2(
		menu_width,
		button_height * 6.0 + separation_base * ui_scale * 5.0
	)


func _apply_desktop_layout() -> void:
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
	_box.size = Vector2(332.0, 284.0)
	_box.add_theme_constant_override("separation", 9)
	for child in _box.get_children():
		if child is Button:
			var button := child as Button
			button.custom_minimum_size = Vector2(332.0, 46.0)
			button.add_theme_font_size_override("font_size", 17)
	$Box/Controls.text = "FIELD GUIDE"
	_quote_panel.visible = true
	_footer_rule.visible = true
	_footer.visible = true
	_footer_rule.position = Vector2(74.0, size.y - 54.0)
	_footer_rule.size = Vector2(maxf(0.0, size.x - 148.0), 1.0)
	_footer.position = Vector2(74.0, size.y - 42.0)
	_footer.size = Vector2(576.0, 25.0)
	_build_label.position = Vector2(maxf(0.0, size.x - 340.0), size.y - 42.0)
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

	draw_rect(Rect2(Vector2.ZERO, size), Color(0.025, 0.031, 0.03, 1.0))
	for band in 7:
		var y := h * (0.08 + float(band) * 0.085)
		var alpha := 0.035 + float(band % 3) * 0.012
		draw_colored_polygon(PackedVector2Array([
			Vector2(0.0, y - 32.0),
			Vector2(w, y + 18.0 + sin(_wash_time * 0.08 + band) * 4.0),
			Vector2(w, y + 76.0),
			Vector2(0.0, y + 44.0),
		]), Color(0.32, 0.35, 0.31, alpha))

	var sun := Vector2(w * 0.77, h * 0.24)
	for ring in range(6, 0, -1):
		draw_circle(sun, 30.0 + ring * 24.0,
			Color(0.68, 0.39, 0.14, 0.012 + (6 - ring) * 0.006))
	draw_circle(sun, 29.0, Color(0.81, 0.52, 0.22, 0.34))
	draw_circle(sun + Vector2(-4.0, 3.0), 24.0, Color(0.13, 0.15, 0.13, 0.42))

	draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, h * 0.57), Vector2(w * 0.09, h * 0.49),
		Vector2(w * 0.18, h * 0.55), Vector2(w * 0.29, h * 0.45),
		Vector2(w * 0.41, h * 0.54), Vector2(w * 0.53, h * 0.47),
		Vector2(w * 0.65, h * 0.56), Vector2(w * 0.78, h * 0.44),
		Vector2(w * 0.9, h * 0.53), Vector2(w, h * 0.47),
		Vector2(w, h), Vector2(0.0, h),
	]), Color(0.055, 0.065, 0.059, 0.97))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, h * 0.7), Vector2(w * 0.12, h * 0.61),
		Vector2(w * 0.25, h * 0.66), Vector2(w * 0.37, h * 0.58),
		Vector2(w * 0.54, h * 0.67), Vector2(w * 0.71, h * 0.58),
		Vector2(w * 0.83, h * 0.64), Vector2(w, h * 0.57),
		Vector2(w, h), Vector2(0.0, h),
	]), Color(0.035, 0.043, 0.039, 1.0))

	for pole_x in [0.52, 0.67, 0.82, 0.95]:
		var pole_ratio: float = float(pole_x)
		var px: float = w * pole_ratio
		var ground: float = h * (0.64 - (pole_ratio - 0.52) * 0.07)
		var pole_h: float = h * (0.15 - (pole_ratio - 0.52) * 0.07)
		draw_line(Vector2(px, ground), Vector2(px, ground - pole_h),
			Color(0.12, 0.13, 0.115, 0.92), 3.0, true)
		draw_line(Vector2(px - 13.0, ground - pole_h + 8.0),
			Vector2(px + 13.0, ground - pole_h + 8.0),
			Color(0.12, 0.13, 0.115, 0.92), 2.0, true)

	var echo := Vector2(w * 0.83, h * 0.59)
	for arc_index in 4:
		var pulse := sin(_wash_time * 0.55 + arc_index * 0.9) * 2.0
		draw_arc(echo, 18.0 + arc_index * 15.0 + pulse, -2.55, 0.52, 38,
			Color(0.27, 0.82, 0.83, 0.24 - arc_index * 0.035), 1.4, true)

	for mote in 18:
		var mx := fmod(float(mote * 97) + _wash_time * (2.0 + mote % 4), w + 80.0) - 40.0
		var my := fmod(float(mote * 53) + sin(_wash_time * 0.19 + mote) * 18.0, h * 0.72)
		var mote_alpha := 0.1 + float(mote % 3) * 0.035
		draw_circle(Vector2(mx, my), 1.0 + float(mote % 2),
			Color(0.65, 0.62, 0.52, mote_alpha))


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
