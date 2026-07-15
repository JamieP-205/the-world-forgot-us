extends CanvasLayer
## A restrained field-kit HUD. Vital information stays at the edges; inventory
## and control hints appear only when useful. Full route detail lives on the
## hand-marked map rather than in a permanent dashboard.

@onready var _interface: Control = $Interface
@onready var _status_panel: PanelContainer = $Interface/StatusPanel
@onready var _health_bar: ProgressBar = $Interface/StatusPanel/Margin/Readout/HealthBar
@onready var _health_label: Label = $Interface/StatusPanel/Margin/Readout/Top/Health
@onready var _scanner_bar: ProgressBar = $Interface/StatusPanel/Margin/Readout/Scanner/Bar
@onready var _scanner_value: Label = $Interface/StatusPanel/Margin/Readout/Scanner/Value
@onready var _inventory_panel: PanelContainer = $Interface/InventoryPanel
@onready var _inventory_header: Label = $Interface/InventoryPanel/Margin/List/Header
@onready var _inventory_rows: VBoxContainer = $Interface/InventoryPanel/Margin/List/Rows
@onready var _inventory_timer: Timer = $InventoryTimer
@onready var _objective_panel: PanelContainer = $Interface/ObjectivePanel
@onready var _region_line: Label = $Interface/ObjectivePanel/Margin/Note/Region
@onready var _objective: Label = $Interface/ObjectivePanel/Margin/Note/Task
@onready var _objective_location: Label = $Interface/ObjectivePanel/Margin/Note/Location
@onready var _objective_progress: Label = $Interface/ObjectivePanel/Margin/Note/Progress
@onready var _notice: Label = $Interface/Notice
@onready var _notice_timer: Timer = $NoticeTimer
@onready var _prompt_panel: PanelContainer = $Interface/Prompt
@onready var _prompt: Label = $Interface/Prompt/Margin/Label
@onready var _compass = $Interface/Compass
@onready var _archive_count: Label = $Interface/ArchiveCount
@onready var _hint: Label = $Interface/FieldHint
@onready var _hint_timer: Timer = $HintTimer

@onready var _pause_overlay: Control = $PauseOverlay
@onready var _pause_panel: PanelContainer = $PauseOverlay/Menu
@onready var _pause_box: VBoxContainer = $PauseOverlay/Menu/Margin/Items
@onready var _controls: Control = $PauseOverlay/ControlsPanel
@onready var _map: Control = $MapScreen
@onready var _settings: Control = $SettingsPanel
@onready var _cinematic: Control = $OpeningCinematic

var _return_to_pause := false
var _clock := 0.0


func _ready() -> void:
	InventorySystem.inventory_changed.connect(_on_inventory_changed)
	EventBus.interaction_prompt_changed.connect(_on_prompt_changed)
	EventBus.paused_changed.connect(_on_paused_changed)
	EventBus.notice_posted.connect(_on_notice)
	EventBus.player_health_changed.connect(_on_health_changed)
	EventBus.scanner_energy_changed.connect(_on_scanner_changed)
	EventBus.level_loaded.connect(_refresh_objective)
	EventBus.game_saved.connect(_refresh_objective)
	EventBus.campaign_progress_changed.connect(_refresh_objective)
	ArchiveSystem.echo_recorded.connect(func(_data: MemoryEchoData) -> void: _refresh_archive())
	BaseUpgradeSystem.upgrade_built.connect(func(_data: BaseUpgradeData) -> void: _refresh_objective())
	SettingsManager.settings_changed.connect(_on_setting_changed)
	_notice_timer.timeout.connect(func() -> void: _notice.text = "")
	_inventory_timer.timeout.connect(func() -> void: _inventory_panel.visible = false)
	_hint_timer.timeout.connect(func() -> void: _hint.visible = false)
	_wire_pause()
	_map.closed.connect(_on_map_closed)
	_settings.closed.connect(_on_settings_closed)
	_cinematic.finished.connect(_on_cinematic_finished)
	_controls.closed.connect(_on_controls_closed)
	_wire_day_night_cycle()
	_controls.visible = false
	_pause_overlay.visible = false
	_map.visible = false
	_settings.visible = false
	_prompt_panel.visible = false
	_notice.text = ""
	_refresh_inventory(false)
	_refresh_archive()
	_refresh_objective()
	_apply_accessibility()
	_hint_timer.start()
	call_deferred("_maybe_begin_cinematic")


func _process(delta: float) -> void:
	_update_compass()
	_clock += delta
	if _clock >= 0.5:
		_clock = 0.0
		_refresh_region_line()


func _wire_day_night_cycle() -> void:
	var cycle: Node = get_parent().get_node_or_null("DayNightCycle") if get_parent() != null else null
	if cycle != null and cycle.has_signal("phase_changed"):
		cycle.connect("phase_changed", _on_day_phase_changed)


func _on_day_phase_changed(_phase_name: StringName, _phase: float) -> void:
	_refresh_region_line()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("map") or GameManager.dialogue_active or GameManager.ending_active:
		return
	if _map.visible:
		return
	get_viewport().set_input_as_handled()
	_open_map(GameManager.is_paused)


func _wire_pause() -> void:
	_pause_box.get_node("Resume").pressed.connect(func() -> void: GameManager.set_paused(false))
	_pause_box.get_node("Map").pressed.connect(func() -> void: _open_map(true))
	_pause_box.get_node("Settings").pressed.connect(func() -> void: _open_settings(true))
	_pause_box.get_node("Guide").pressed.connect(_open_controls)
	_pause_box.get_node("MainMenu").pressed.connect(_to_main_menu)
	var quit := _pause_box.get_node("Quit") as Button
	quit.pressed.connect(_quit_or_fullscreen)
	if OS.has_feature("web"):
		quit.text = "FULLSCREEN"


func _open_map(from_pause: bool) -> void:
	_return_to_pause = from_pause
	if not GameManager.is_paused:
		GameManager.set_paused(true)
	_pause_panel.visible = false
	_controls.visible = false
	_settings.visible = false
	_map.open_map()


func _on_map_closed() -> void:
	if _return_to_pause:
		_pause_panel.visible = true
		_pause_box.get_node("Resume").grab_focus()
	else:
		GameManager.set_paused(false)


func _open_settings(from_pause: bool) -> void:
	_return_to_pause = from_pause
	if not GameManager.is_paused:
		GameManager.set_paused(true)
	_pause_panel.visible = false
	_controls.visible = false
	_map.visible = false
	_settings.open_panel()


func _on_settings_closed() -> void:
	if _return_to_pause:
		_pause_panel.visible = true
		_pause_box.get_node("Resume").grab_focus()
	else:
		GameManager.set_paused(false)


func _open_controls() -> void:
	_pause_panel.visible = false
	_controls.visible = true


func _on_controls_closed() -> void:
	_controls.visible = false
	_pause_panel.visible = true
	_pause_box.get_node("Resume").grab_focus()


func _to_main_menu() -> void:
	GameManager.set_paused(false)
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func _quit_or_fullscreen() -> void:
	if OS.has_feature("web"):
		var mode := DisplayServer.window_get_mode()
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if mode == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		get_tree().quit()


func _on_paused_changed(paused: bool) -> void:
	_pause_overlay.visible = paused
	if not paused:
		_pause_panel.visible = true
		_controls.visible = false
		_map.visible = false
		_settings.visible = false
	elif not _map.visible and not _settings.visible and not _controls.visible:
		_pause_panel.visible = true
		_pause_box.get_node("Resume").grab_focus()


func _on_inventory_changed() -> void:
	_refresh_inventory(true)


func _refresh_inventory(reveal: bool) -> void:
	var items := InventorySystem.get_items()
	var total := InventorySystem.get_total_count()
	_inventory_header.text = "FIELD KIT / %d" % total
	while _inventory_rows.get_child_count() > 0:
		var child := _inventory_rows.get_child(0)
		_inventory_rows.remove_child(child)
		child.queue_free()
	for id in items:
		var data: ItemData = ItemDatabase.get_item(id)
		var label := Label.new()
		label.text = "%s  x%d" % [data.display_name if data != null else String(id), int(items[id])]
		label.add_theme_color_override("font_color", Color(0.73, 0.74, 0.66, 1))
		label.add_theme_font_size_override("font_size", 12)
		_inventory_rows.add_child(label)
	_inventory_panel.visible = reveal and total > 0
	if _inventory_panel.visible:
		_inventory_timer.start()


func _refresh_objective() -> void:
	var data := CampaignSystem.get_objective()
	_objective.text = String(data.get("text", "Find a road that still agrees with its signs."))
	_objective_location.text = String(data.get("location", "LOCATION UNCONFIRMED"))
	_objective_progress.text = String(data.get("progress", ""))
	_refresh_region_line()


func _refresh_region_line() -> void:
	var main := get_tree().get_first_node_in_group("main")
	var phase := ""
	if main != null and main.has_method("get_day_phase_name"):
		phase = String(main.get_day_phase_name()).to_upper()
	var path := _current_level_path()
	var region := "CULLBROOK"
	if path.ends_with("railhome_base.tscn"): region = "CARRIAGE 317"
	elif path.ends_with("ashmere_verge.tscn"): region = "ASHMERE"
	elif path.ends_with("broadcast_fields.tscn"): region = "WRENFIELD"
	elif path.ends_with("choir_core.tscn"): region = "TOLLARD"
	_region_line.text = "%s / %s" % [region, phase if not phase.is_empty() else "FIELD NOTE"]


func _on_prompt_changed(text: String) -> void:
	_prompt.text = "E  /  " + text if not text.is_empty() else ""
	_prompt_panel.visible = not text.strip_edges().is_empty()


func _on_notice(text: String) -> void:
	_notice.text = text
	_notice_timer.start(clampf(3.0 + text.length() * 0.04, 4.0, 10.0))


func _on_health_changed(current: float, maximum: float) -> void:
	_health_bar.max_value = maximum
	_health_bar.value = current
	_health_label.text = "%d" % roundi(current)


func _on_scanner_changed(current: float, maximum: float) -> void:
	_scanner_bar.max_value = maximum
	_scanner_bar.value = current
	_scanner_value.text = "%d%%" % roundi(current / maxf(maximum, 0.001) * 100.0)


func _refresh_archive() -> void:
	_archive_count.text = "I  /  %d TRACES" % ArchiveSystem.get_count()


func _update_compass() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var target := _objective_target()
	_compass.set_aim(player != null and target != null, target.global_position - player.global_position if player != null and target != null else Vector2.ZERO)


func _objective_target() -> Node2D:
	var main := get_tree().get_first_node_in_group("main")
	if main == null or not main.has_method("get_current_level"):
		return null
	var level: Node = main.get_current_level()
	if level == null:
		return null
	var target_key := String(CampaignSystem.get_objective().get("target", ""))
	if target_key.is_empty():
		return null
	var named := level.find_child(target_key, true, false) as Node2D
	if named != null:
		return named
	for candidate in get_tree().get_nodes_in_group("objective_targets"):
		if not candidate is Node2D or not level.is_ancestor_of(candidate):
			continue
		var story := str(candidate.get("story_id"))
		if story == target_key or candidate.name == target_key:
			return candidate as Node2D
	return null


func _maybe_begin_cinematic() -> void:
	if DisplayServer.get_name() == "headless" or WorldState.has_flag(&"intro_seen"):
		return
	# Existing progressed saves should not be interrupted by a newly added intro.
	if _has_meaningful_progress():
		WorldState.set_flag(&"intro_seen")
		return
	_interface.visible = false
	_cinematic.begin()


func _has_meaningful_progress() -> bool:
	# New Game deletes the old save and sets only intro_pending. Any surviving
	# save therefore represents a Continue/legacy run, even if it predates
	# echoes, upgrades, or the WorldState schema.
	if SaveManager.has_save() and not WorldState.has_flag(&"intro_pending"):
		return true
	if InventorySystem.get_total_count() > 0:
		return true
	if ArchiveSystem.get_count() > 0 or BaseUpgradeSystem.get_built_ids().size() > 0:
		return true
	var state := WorldState.get_state()
	if not state.get("opened", []).is_empty() or not state.get("choices", []).is_empty() or not state.get("defeated", []).is_empty():
		return true
	var flags: Dictionary = state.get("flags", {})
	for raw_id in flags:
		var id := String(raw_id)
		if id in ["intro_pending", "intro_seen"]:
			continue
		var value: Variant = flags[raw_id]
		if value != false and value != null and value != "":
			return true
	return false


func _on_cinematic_finished() -> void:
	_interface.visible = true
	_hint.visible = true
	_hint_timer.start()
	_on_notice("The voice used Maggie's house number. Find the north-road tape and compare it.")


func _on_setting_changed(section: String, key: String, _value: Variant) -> void:
	if section == "accessibility" and key == "high_contrast":
		_apply_accessibility()


func _apply_accessibility() -> void:
	var contrast := SettingsManager.get_bool("accessibility", "high_contrast")
	_objective.add_theme_color_override("font_color", Color(1.0, 0.94, 0.78) if contrast else Color(0.89, 0.85, 0.72))
	_objective_location.add_theme_color_override("font_color", Color(0.58, 0.95, 0.9) if contrast else Color(0.43, 0.7, 0.67))
	_prompt.add_theme_color_override("font_color", Color(1.0, 0.87, 0.5) if contrast else Color(0.94, 0.79, 0.44))


func _current_level_path() -> String:
	var main := get_tree().get_first_node_in_group("main")
	if main != null and main.has_method("get_current_level_path"):
		return String(main.get_current_level_path())
	return ""
