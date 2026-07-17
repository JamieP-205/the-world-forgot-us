extends Control

signal closed

const PHONE_PORTRAIT_CARD := Vector2(390.0, 820.0)
const PHONE_LANDSCAPE_CARD := Vector2(820.0, 350.0)

@onready var _card: PanelContainer = $Card
@onready var _margin: MarginContainer = $Card/Margin
@onready var _layout: VBoxContainer = $Card/Margin/Layout
@onready var _columns: HBoxContainer = $Card/Margin/Layout/Columns
@onready var _audio_column: VBoxContainer = $Card/Margin/Layout/Columns/Audio
@onready var _options_column: VBoxContainer = $Card/Margin/Layout/Columns/Options
@onready var _audio_header: Label = $Card/Margin/Layout/Columns/Audio/Header
@onready var _options_header: Label = $Card/Margin/Layout/Columns/Options/Header
@onready var _audio_note: Label = $Card/Margin/Layout/Columns/Audio/Note
@onready var _persistence: Label = $Card/Margin/Layout/Columns/Options/Persistence
@onready var _title: Label = $Card/Margin/Layout/Title
@onready var _master_row: HBoxContainer = $Card/Margin/Layout/Columns/Audio/Master
@onready var _music_row: HBoxContainer = $Card/Margin/Layout/Columns/Audio/Music
@onready var _sfx_row: HBoxContainer = $Card/Margin/Layout/Columns/Audio/SFX
@onready var _shake_row: HBoxContainer = $Card/Margin/Layout/Columns/Options/Shake
@onready var _master_name: Label = $Card/Margin/Layout/Columns/Audio/Master/Name
@onready var _music_name: Label = $Card/Margin/Layout/Columns/Audio/Music/Name
@onready var _sfx_name: Label = $Card/Margin/Layout/Columns/Audio/SFX/Name
@onready var _shake_label: Label = $Card/Margin/Layout/Columns/Options/ShakeLabel
@onready var _master: HSlider = $Card/Margin/Layout/Columns/Audio/Master/Slider
@onready var _music: HSlider = $Card/Margin/Layout/Columns/Audio/Music/Slider
@onready var _sfx: HSlider = $Card/Margin/Layout/Columns/Audio/SFX/Slider
@onready var _master_value: Label = $Card/Margin/Layout/Columns/Audio/Master/Value
@onready var _music_value: Label = $Card/Margin/Layout/Columns/Audio/Music/Value
@onready var _sfx_value: Label = $Card/Margin/Layout/Columns/Audio/SFX/Value
@onready var _fullscreen: CheckButton = $Card/Margin/Layout/Columns/Options/Fullscreen
@onready var _vsync: CheckButton = $Card/Margin/Layout/Columns/Options/VSync
@onready var _reduced: CheckButton = $Card/Margin/Layout/Columns/Options/ReducedEffects
@onready var _contrast: CheckButton = $Card/Margin/Layout/Columns/Options/HighContrast
@onready var _day_night: CheckButton = $Card/Margin/Layout/Columns/Options/DayNight
@onready var _precise_bearings: CheckButton = $Card/Margin/Layout/Columns/Options/PreciseBearings
@onready var _shake: HSlider = $Card/Margin/Layout/Columns/Options/Shake/Slider
@onready var _shake_value: Label = $Card/Margin/Layout/Columns/Options/Shake/Value
@onready var _actions: GridContainer = $Card/Margin/Layout/Actions
@onready var _back: Button = $Card/Margin/Layout/Actions/Back
@onready var _reset: Button = $Card/Margin/Layout/Actions/Reset

var _syncing := false
var _touch_ui := false
var _mobile_stack: VBoxContainer
var _content_scroll: ScrollContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_touch_ui = _is_touch_device()
	_install_scroll_container()
	_master.value_changed.connect(func(value: float) -> void: _set_audio("master", value, _master_value))
	_music.value_changed.connect(func(value: float) -> void: _set_audio("music", value, _music_value))
	_sfx.value_changed.connect(func(value: float) -> void: _set_audio("sfx", value, _sfx_value))
	_shake.value_changed.connect(_on_shake_changed)
	for slider in [_master, _music, _sfx, _shake]:
		(slider as HSlider).drag_ended.connect(func(_changed: bool) -> void: SettingsManager.save())
	_fullscreen.toggled.connect(func(value: bool) -> void: _set_option("display", "fullscreen", value))
	_vsync.toggled.connect(func(value: bool) -> void: _set_option("display", "vsync", value))
	_reduced.toggled.connect(func(value: bool) -> void: _set_option("accessibility", "reduced_effects", value))
	_contrast.toggled.connect(func(value: bool) -> void: _set_option("accessibility", "high_contrast", value))
	_day_night.toggled.connect(func(value: bool) -> void: _set_option("gameplay", "day_night_cycle", value))
	_precise_bearings.toggled.connect(func(value: bool) -> void: _set_option("gameplay", "precise_bearings", value))
	for control in [
		_master, _music, _sfx, _fullscreen, _vsync, _reduced,
		_contrast, _day_night, _precise_bearings, _shake,
	]:
		(control as Control).focus_entered.connect(_ensure_setting_visible.bind(control))
	_back.pressed.connect(close_panel)
	_reset.pressed.connect(_on_reset)
	get_viewport().size_changed.connect(_apply_responsive_layout)
	visible = false
	call_deferred("_apply_responsive_layout")


func _is_touch_device() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("web_android") \
		or OS.has_feature("web_ios") or DisplayServer.is_touchscreen_available()


func _physical_scale(logical_view: Vector2, physical_override: Vector2 = Vector2.ZERO) -> float:
	var window_size := physical_override
	if window_size == Vector2.ZERO:
		window_size = Vector2(DisplayServer.window_get_size())
	if window_size.x <= 1.0 or window_size.y <= 1.0 or logical_view.x <= 1.0 or logical_view.y <= 1.0:
		return 1.0
	return maxf(0.05, minf(window_size.x / logical_view.x, window_size.y / logical_view.y))


func _install_scroll_container() -> void:
	if _content_scroll != null:
		return
	_content_scroll = ScrollContainer.new()
	_content_scroll.name = "SettingsScroll"
	_content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_content_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_content_scroll.scroll_deadzone = 8
	var old_index := _columns.get_index()
	_layout.add_child(_content_scroll)
	_layout.move_child(_content_scroll, old_index)
	_columns.reparent(_content_scroll)


func _ensure_setting_visible(control: Control) -> void:
	_content_scroll.ensure_control_visible(control)


func open_panel() -> void:
	SettingsManager.sync_display_state()
	_sync()
	visible = true
	_apply_responsive_layout()
	_master.grab_focus()


func close_panel() -> void:
	if not visible:
		return
	visible = false
	SettingsManager.save()
	AudioManager.play(&"ui_back", -4.0)
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		close_panel()


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
	var portrait := view.y > view.x
	var touch_layout := _touch_ui if touch_override < 0 else touch_override == 1
	var compact := touch_layout or view.x < 980.0 or view.y < 600.0
	if compact:
		_apply_phone_layout(view, portrait, touch_layout, physical_view)
	else:
		_apply_desktop_layout(view)


func _apply_phone_layout(
		view: Vector2,
		portrait: bool,
		touch_layout: bool,
		physical_view: Vector2,
	) -> void:
	var physical := _physical_scale(view, physical_view)
	var requested_scale := clampf(0.94 / physical, 1.0, 3.2) if touch_layout else 1.0
	var base_size := PHONE_PORTRAIT_CARD if portrait else PHONE_LANDSCAPE_CARD
	var edge := 12.0 * requested_scale
	var fit_scale := minf(
		(view.x - edge * 2.0) / base_size.x,
		(view.y - edge * 2.0) / base_size.y
	)
	var card_scale := maxf(0.5, minf(requested_scale, fit_scale))
	_apply_phone_copy()
	_set_columns_stacked(portrait)
	_card.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_card.grow_horizontal = Control.GROW_DIRECTION_END
	_card.grow_vertical = Control.GROW_DIRECTION_END
	_card.pivot_offset = Vector2.ZERO
	_card.scale = Vector2.ONE * card_scale
	_card.size = base_size
	_card.position = Vector2(
		(view.x - base_size.x * card_scale) * 0.5,
		(view.y - base_size.y * card_scale) * 0.5
	)
	_margin.add_theme_constant_override("margin_left", 44)
	_margin.add_theme_constant_override("margin_top", 14 if portrait else 10)
	_margin.add_theme_constant_override("margin_right", 18)
	_margin.add_theme_constant_override("margin_bottom", 14 if portrait else 10)
	_layout.add_theme_constant_override("separation", 7 if portrait else 5)
	_columns.add_theme_constant_override("separation", 18)
	_audio_column.add_theme_constant_override("separation", 8)
	_options_column.add_theme_constant_override("separation", 4)
	var usable_width := base_size.x - 62.0
	_columns.custom_minimum_size.x = usable_width
	if portrait:
		_audio_column.custom_minimum_size.x = usable_width
		_options_column.custom_minimum_size.x = usable_width
	else:
		var column_width := (usable_width - 18.0) * 0.5
		_audio_column.custom_minimum_size.x = column_width
		_options_column.custom_minimum_size.x = column_width
	_audio_note.visible = false
	_persistence.visible = false
	_title.add_theme_font_size_override("font_size", 30 if portrait else 27)
	$Card/Margin/Layout/Eyebrow.add_theme_font_size_override("font_size", 13)
	_audio_header.add_theme_font_size_override("font_size", 14)
	_options_header.add_theme_font_size_override("font_size", 14)
	for slider in [_master, _music, _sfx, _shake]:
		(slider as HSlider).custom_minimum_size.y = 52.0
	for row in [_master_row, _music_row, _sfx_row, _shake_row]:
		(row as HBoxContainer).custom_minimum_size.y = 52.0
	for option in [_fullscreen, _vsync, _reduced, _contrast, _day_night, _precise_bearings]:
		(option as CheckButton).custom_minimum_size.y = 52.0
		(option as CheckButton).add_theme_font_size_override("font_size", 17)
	for label in [
		_master_name, _music_name, _sfx_name,
		_master_value, _music_value, _sfx_value,
		_shake_label, _shake_value,
	]:
		(label as Label).add_theme_font_size_override("font_size", 16)
	_actions.columns = 1 if portrait else 2
	_back.custom_minimum_size = Vector2(0.0, 54.0)
	_reset.custom_minimum_size = Vector2(0.0, 54.0)
	_back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_reset.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_back.add_theme_font_size_override("font_size", 17)
	_reset.add_theme_font_size_override("font_size", 17)
	# Container minimums are recalculated after the mobile copy and fonts.
	# Reasserting the fixed viewport keeps the scroll area, not the card, as
	# the place where long settings content grows.
	_card.size = base_size


func _apply_desktop_layout(view: Vector2) -> void:
	_apply_desktop_copy()
	_set_columns_stacked(false)
	_card.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_card.grow_horizontal = Control.GROW_DIRECTION_END
	_card.grow_vertical = Control.GROW_DIRECTION_END
	_card.pivot_offset = Vector2.ZERO
	_card.scale = Vector2.ONE
	_card.size = Vector2(940.0, 600.0)
	_card.position = Vector2((view.x - 940.0) * 0.5, (view.y - 600.0) * 0.5)
	_margin.add_theme_constant_override("margin_left", 50)
	_margin.add_theme_constant_override("margin_top", 32)
	_margin.add_theme_constant_override("margin_right", 42)
	_margin.add_theme_constant_override("margin_bottom", 30)
	_layout.add_theme_constant_override("separation", 14)
	_columns.add_theme_constant_override("separation", 48)
	_audio_column.add_theme_constant_override("separation", 13)
	_options_column.add_theme_constant_override("separation", 10)
	_columns.custom_minimum_size.x = 0.0
	_audio_column.custom_minimum_size.x = 385.0
	_options_column.custom_minimum_size.x = 390.0
	_audio_note.visible = true
	_persistence.visible = true
	_title.add_theme_font_size_override("font_size", 31)
	$Card/Margin/Layout/Eyebrow.add_theme_font_size_override("font_size", 11)
	_audio_header.add_theme_font_size_override("font_size", 12)
	_options_header.add_theme_font_size_override("font_size", 12)
	for slider in [_master, _music, _sfx, _shake]:
		(slider as HSlider).custom_minimum_size.y = 0.0
	for row in [_master_row, _music_row, _sfx_row, _shake_row]:
		(row as HBoxContainer).custom_minimum_size.y = 0.0
	for option in [_fullscreen, _vsync, _reduced, _contrast, _day_night, _precise_bearings]:
		(option as CheckButton).custom_minimum_size.y = 0.0
		(option as CheckButton).remove_theme_font_size_override("font_size")
	for label in [
		_master_name, _music_name, _sfx_name,
		_master_value, _music_value, _sfx_value,
		_shake_label, _shake_value,
	]:
		(label as Label).remove_theme_font_size_override("font_size")
	_actions.columns = 2
	_back.custom_minimum_size = Vector2(210.0, 40.0)
	_reset.custom_minimum_size = Vector2(210.0, 40.0)
	_back.add_theme_font_size_override("font_size", 15)
	_reset.add_theme_font_size_override("font_size", 15)
	_card.size = Vector2(940.0, 600.0)


func _apply_phone_copy() -> void:
	_reduced.text = "Reduced effects (faster)"
	_contrast.text = "High-contrast HUD and map"
	_day_night.text = "Living day / night cycle"
	_precise_bearings.text = "Precise job bearing"


func _apply_desktop_copy() -> void:
	_reduced.text = "Reduced post-processing (faster)"
	_contrast.text = "High-contrast HUD and map ink"
	_day_night.text = "Living day and night cycle"
	_precise_bearings.text = "Pinpoint job bearing (accessibility)"


func _set_columns_stacked(stacked: bool) -> void:
	if stacked:
		if _mobile_stack == null:
			_mobile_stack = VBoxContainer.new()
			_mobile_stack.name = "MobileColumns"
			_mobile_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_mobile_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
			_mobile_stack.add_theme_constant_override("separation", 14)
			_columns.add_child(_mobile_stack)
			_audio_column.reparent(_mobile_stack)
			_options_column.reparent(_mobile_stack)
	else:
		if _mobile_stack != null:
			_audio_column.reparent(_columns)
			_options_column.reparent(_columns)
			_mobile_stack.free()
			_mobile_stack = null


func _sync() -> void:
	_syncing = true
	_master.value = SettingsManager.get_float("audio", "master", 0.86)
	_music.value = SettingsManager.get_float("audio", "music", 0.64)
	_sfx.value = SettingsManager.get_float("audio", "sfx", 0.88)
	_shake.value = SettingsManager.get_float("accessibility", "screen_shake", 0.8)
	_fullscreen.button_pressed = SettingsManager.get_bool("display", "fullscreen")
	_vsync.button_pressed = SettingsManager.get_bool("display", "vsync", true)
	_reduced.button_pressed = SettingsManager.get_bool("accessibility", "reduced_effects")
	_contrast.button_pressed = SettingsManager.get_bool("accessibility", "high_contrast")
	_day_night.button_pressed = SettingsManager.get_bool("gameplay", "day_night_cycle", true)
	_precise_bearings.button_pressed = SettingsManager.get_bool("gameplay", "precise_bearings")
	_update_percent(_master_value, _master.value)
	_update_percent(_music_value, _music.value)
	_update_percent(_sfx_value, _sfx.value)
	_update_percent(_shake_value, _shake.value)
	_syncing = false


func _set_audio(key: String, value: float, label: Label) -> void:
	_update_percent(label, value)
	if not _syncing:
		SettingsManager.set_value("audio", key, value, false)


func _on_shake_changed(value: float) -> void:
	_update_percent(_shake_value, value)
	if not _syncing:
		SettingsManager.set_value("accessibility", "screen_shake", value, false)


func _set_option(section: String, key: String, value: bool) -> void:
	if not _syncing:
		SettingsManager.set_value(section, key, value)
		AudioManager.play(&"settings_apply", -6.0)


func _on_reset() -> void:
	SettingsManager.reset_defaults()
	_sync()
	AudioManager.play(&"settings_apply")


func _update_percent(label: Label, value: float) -> void:
	label.text = "%d%%" % roundi(value * 100.0)
