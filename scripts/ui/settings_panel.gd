extends Control

signal closed

@onready var _card: PanelContainer = $Card
@onready var _margin: MarginContainer = $Card/Margin
@onready var _layout: VBoxContainer = $Card/Margin/Layout
@onready var _columns: HBoxContainer = $Card/Margin/Layout/Columns
@onready var _audio_column: VBoxContainer = $Card/Margin/Layout/Columns/Audio
@onready var _options_column: VBoxContainer = $Card/Margin/Layout/Columns/Options
@onready var _audio_note: Label = $Card/Margin/Layout/Columns/Audio/Note
@onready var _persistence: Label = $Card/Margin/Layout/Columns/Options/Persistence
@onready var _title: Label = $Card/Margin/Layout/Title
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
@onready var _shake: HSlider = $Card/Margin/Layout/Columns/Options/Shake/Slider
@onready var _shake_value: Label = $Card/Margin/Layout/Columns/Options/Shake/Value
@onready var _back: Button = $Card/Margin/Layout/Actions/Back
@onready var _reset: Button = $Card/Margin/Layout/Actions/Reset

var _syncing := false
var _touch_ui := false
var _mobile_stack: VBoxContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_touch_ui = _is_touch_device()
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
	_back.pressed.connect(close_panel)
	_reset.pressed.connect(_on_reset)
	get_viewport().size_changed.connect(_apply_responsive_layout)
	visible = false


func _is_touch_device() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("web_android") \
		or OS.has_feature("web_ios") or DisplayServer.is_touchscreen_available()


func _physical_scale() -> float:
	var window_size := Vector2(DisplayServer.window_get_size())
	if window_size.x <= 1.0 or window_size.y <= 1.0 or size.x <= 1.0 or size.y <= 1.0:
		return 1.0
	return maxf(0.05, minf(window_size.x / size.x, window_size.y / size.y))


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


func _apply_responsive_layout() -> void:
	if not is_node_ready() or not _touch_ui or size.x <= 1.0 or size.y <= 1.0:
		return
	var window_size := Vector2(DisplayServer.window_get_size())
	var portrait := window_size.y > window_size.x
	var requested_scale := clampf(0.92 / _physical_scale(), 1.0, 2.85)
	var base_size := Vector2(620.0, 820.0) if portrait else Vector2(900.0, 480.0)
	var edge := 16.0 * requested_scale
	var card_scale := minf(
		requested_scale,
		(size.x - edge * 2.0) / base_size.x,
		(size.y - edge * 2.0) / base_size.y
	)
	card_scale = maxf(0.72, card_scale)

	_set_columns_stacked(portrait)
	_card.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_card.pivot_offset = Vector2.ZERO
	_card.scale = Vector2.ONE * card_scale
	_card.size = base_size
	_card.position = Vector2(
		(size.x - base_size.x * card_scale) * 0.5,
		(size.y - base_size.y * card_scale) * 0.5
	)
	_margin.add_theme_constant_override("margin_left", 20)
	_margin.add_theme_constant_override("margin_top", 18)
	_margin.add_theme_constant_override("margin_right", 20)
	_margin.add_theme_constant_override("margin_bottom", 18)
	_layout.add_theme_constant_override("separation", 8)
	_audio_column.add_theme_constant_override("separation", 8)
	_options_column.add_theme_constant_override("separation", 6)
	_audio_column.custom_minimum_size.x = 0.0
	_options_column.custom_minimum_size.x = 0.0
	_audio_note.visible = false
	_persistence.visible = false
	_title.add_theme_font_size_override("font_size", 36)
	for slider in [_master, _music, _sfx, _shake]:
		(slider as HSlider).custom_minimum_size.y = 34.0
	for option in [_fullscreen, _vsync, _reduced, _contrast, _day_night]:
		(option as CheckButton).custom_minimum_size.y = 38.0
	_back.custom_minimum_size = Vector2(210.0, 52.0)
	_reset.custom_minimum_size = Vector2(210.0, 52.0)
	_back.add_theme_font_size_override("font_size", 17)
	_reset.add_theme_font_size_override("font_size", 17)


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
			_mobile_stack.queue_free()
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
