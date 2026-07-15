extends Node
## Persistent player-facing options. Audio buses are created at runtime so the
## project stays self contained and browser exports need no generated bus file.

signal settings_changed(section: String, key: String, value: Variant)

const SAVE_PATH := "user://settings.cfg"
const LOW_EFFECTS_SETTING := "rendering/environment/ashland_low_effects"

const DEFAULTS := {
	"audio": {
		"master": 0.86,
		"music": 0.64,
		"sfx": 0.88,
	},
	"display": {
		"fullscreen": false,
		"vsync": true,
	},
	"gameplay": {
		"day_night_cycle": true,
	},
	"accessibility": {
		"reduced_effects": false,
		"screen_shake": 0.8,
		"high_contrast": false,
	},
}

var _values: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_values = _platform_defaults()
	_load()
	# Browsers cannot restore fullscreen before a user gesture. Keep the stored
	# UI state honest instead of showing a checked box while the canvas is still
	# embedded/windowed.
	if OS.has_feature("web"):
		(_values["display"] as Dictionary)["fullscreen"] = false
	_ensure_audio_buses()
	apply_all()


func get_value(section: String, key: String, fallback: Variant = null) -> Variant:
	var group: Dictionary = _values.get(section, {})
	return group.get(key, fallback)


func get_float(section: String, key: String, fallback: float = 0.0) -> float:
	return float(get_value(section, key, fallback))


func get_bool(section: String, key: String, fallback: bool = false) -> bool:
	return bool(get_value(section, key, fallback))


func set_value(section: String, key: String, value: Variant, persist := true) -> void:
	if not _values.has(section):
		_values[section] = {}
	(_values[section] as Dictionary)[key] = value
	_apply_one(section, key, value)
	settings_changed.emit(section, key, value)
	if persist:
		save()


func reset_defaults() -> void:
	_values = _platform_defaults()
	apply_all()
	save()
	for section in _values:
		for key in (_values[section] as Dictionary):
			settings_changed.emit(section, key, _values[section][key])


func save() -> void:
	var config := ConfigFile.new()
	for section in _values:
		for key in (_values[section] as Dictionary):
			config.set_value(section, key, _values[section][key])
	var error := config.save(SAVE_PATH)
	if error != OK:
		push_warning("SettingsManager: could not save settings (%s)." % error_string(error))


func apply_all() -> void:
	_ensure_audio_buses()
	for section in _values:
		for key in (_values[section] as Dictionary):
			_apply_one(section, key, _values[section][key])


func sync_display_state() -> void:
	if DisplayServer.get_name() == "headless":
		return
	(_values["display"] as Dictionary)["fullscreen"] = (
		DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	)


func _platform_defaults() -> Dictionary:
	var defaults := DEFAULTS.duplicate(true)
	# LightingDirector historically defaults Web to its one-sample grade. Keep
	# that performance-safe default while desktop retains the richer wash.
	(defaults["accessibility"] as Dictionary)["reduced_effects"] = OS.has_feature("web")
	return defaults


func _load() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	for section in DEFAULTS:
		for key in (DEFAULTS[section] as Dictionary):
			_values[section][key] = config.get_value(section, key, _values[section][key])


func _apply_one(section: String, key: String, value: Variant) -> void:
	if section == "audio":
		var bus_name: String = String({"master": "Master", "music": "Music", "sfx": "SFX"}.get(key, key))
		_set_bus_volume(bus_name, float(value))
	elif section == "display":
		if key == "fullscreen" and DisplayServer.get_name() != "headless":
			DisplayServer.window_set_mode(
				DisplayServer.WINDOW_MODE_FULLSCREEN if bool(value)
				else DisplayServer.WINDOW_MODE_WINDOWED
			)
		elif key == "vsync" and DisplayServer.get_name() != "headless":
			DisplayServer.window_set_vsync_mode(
				DisplayServer.VSYNC_ENABLED if bool(value) else DisplayServer.VSYNC_DISABLED
			)
	elif section == "accessibility" and key == "reduced_effects":
		ProjectSettings.set_setting(LOW_EFFECTS_SETTING, bool(value))
		var main_for_effects := get_tree().get_first_node_in_group("main")
		if main_for_effects != null:
			var director: Node = main_for_effects.get_node_or_null("LightingDirector")
			if director != null and director.has_method("_configure_effect_quality"):
				director.call("_configure_effect_quality")
	elif section == "gameplay" and key == "day_night_cycle":
		var main := get_tree().get_first_node_in_group("main")
		if main != null:
			var cycle: Node = main.get_node_or_null("DayNightCycle")
			if cycle != null:
				cycle.set("cycle_enabled", bool(value))


func _ensure_audio_buses() -> void:
	for bus_name in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus_name) < 0:
			AudioServer.add_bus()
			var index := AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus_name)
			AudioServer.set_bus_send(index, "Master")


func _set_bus_volume(bus_name: String, linear: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		return
	var safe := clampf(linear, 0.0, 1.0)
	AudioServer.set_bus_mute(index, safe <= 0.001)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(safe, 0.001)))
