extends Control

signal closed

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


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
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
	visible = false


func open_panel() -> void:
	SettingsManager.sync_display_state()
	_sync()
	visible = true
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
