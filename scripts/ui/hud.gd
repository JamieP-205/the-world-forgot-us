extends CanvasLayer
## In-game HUD: meters, inventory, objectives, interaction prompt, notices.

@onready var _inv_header: Label = $Interface/InventoryPanel/Margin/Content/Header
@onready var _inv_list: VBoxContainer = $Interface/InventoryPanel/Margin/Content/List
@onready var _prompt_panel: PanelContainer = $Interface/PromptPanel
@onready var _prompt_label: Label = $Interface/PromptPanel/Margin/PromptLabel
@onready var _pause_overlay: Control = $PauseOverlay
@onready var _pause_panel: PanelContainer = $PauseOverlay/PausePanel
@onready var _pause_box: VBoxContainer = $PauseOverlay/PausePanel/Margin/PauseBox
@onready var _pause_controls: Control = $PauseOverlay/PauseControls
@onready var _notice_label: Label = $Interface/NoticeLabel
@onready var _notice_timer: Timer = $NoticeTimer
@onready var _health_bar: ProgressBar = $Interface/StatusPanel/Margin/Content/HealthBar
@onready var _health_label: Label = $Interface/StatusPanel/Margin/Content/StatusHeader/HealthLabel
@onready var _scanner_bar: ProgressBar = $Interface/StatusPanel/Margin/Content/ScannerBar
@onready var _scanner_value: Label = $Interface/StatusPanel/Margin/Content/ScannerLine/ScannerValue
@onready var _archive_label: Label = $Interface/ArchiveLabel
@onready var _objective_chapter: Label = $Interface/ObjectivePanel/Margin/Content/Chapter
@onready var _objective_label: Label = $Interface/ObjectivePanel/Margin/Content/ObjectiveLabel
@onready var _objective_location: Label = $Interface/ObjectivePanel/Margin/Content/PrimaryLocation
@onready var _objective_progress: Label = $Interface/ObjectivePanel/Margin/Content/PrimaryProgress
@onready var _optional_rule: HSeparator = $Interface/ObjectivePanel/Margin/Content/OptionalRule
@onready var _optional_header: Label = $Interface/ObjectivePanel/Margin/Content/OptionalHeader
@onready var _optional_task: Label = $Interface/ObjectivePanel/Margin/Content/OptionalTask
@onready var _optional_location: Label = $Interface/ObjectivePanel/Margin/Content/OptionalLocation
@onready var _optional_progress: Label = $Interface/ObjectivePanel/Margin/Content/OptionalProgress
@onready var _compass = $Interface/Compass
@onready var _ability_label: Label = $Interface/AbilityPanel/Margin/AbilityLabel

func _ready() -> void:
	InventorySystem.inventory_changed.connect(_refresh_inventory)
	EventBus.interaction_prompt_changed.connect(_on_prompt_changed)
	EventBus.paused_changed.connect(_on_paused_changed)
	EventBus.notice_posted.connect(_on_notice_posted)
	EventBus.player_health_changed.connect(_on_player_health_changed)
	EventBus.scanner_energy_changed.connect(_on_scanner_energy_changed)
	EventBus.level_loaded.connect(_refresh_objectives)
	EventBus.game_saved.connect(_refresh_objectives)
	EventBus.campaign_progress_changed.connect(_refresh_objectives)
	ArchiveSystem.echo_recorded.connect(_on_echo_recorded)
	BaseUpgradeSystem.upgrade_built.connect(_on_upgrade_built)
	_notice_timer.timeout.connect(_on_notice_timeout)
	_wire_pause_menu()
	_refresh_inventory()
	_prompt_label.text = ""
	_prompt_panel.visible = false
	_notice_label.text = ""
	_refresh_archive()
	_refresh_objectives()
	call_deferred("_show_opening_hint")


func _process(_delta: float) -> void:
	_update_compass()
	_update_ability_label()


func _update_compass() -> void:
	if _compass == null:
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var target := _current_objective_target()
	if player == null or target == null:
		_compass.set_aim(false, Vector2.ZERO)
	else:
		_compass.set_aim(true, target.global_position - player.global_position)


func _current_objective_target() -> Node2D:
	var main := get_tree().get_first_node_in_group("main")
	if main == null or not main.has_method("get_current_level"):
		return null
	var level: Node = main.get_current_level()
	if level == null:
		return null

	# CampaignSystem is the one source of truth for both the text and arrow.
	var objective := CampaignSystem.get_objective()
	var target_key := String(objective.get("target", ""))
	if target_key.is_empty():
		return null
	var named := level.find_child(target_key, true, false) as Node2D
	if named != null:
		return named
	for candidate in get_tree().get_nodes_in_group("objective_targets"):
		if not candidate is Node2D or not level.is_ancestor_of(candidate):
			continue
		var candidate_story := String(candidate.get("story_id"))
		if candidate_story.is_empty() and candidate.has_meta("story_id"):
			candidate_story = String(candidate.get_meta("story_id"))
		if candidate_story == target_key or candidate.name == target_key:
			return candidate as Node2D
	return null


func _refresh_inventory() -> void:
	var item_count := InventorySystem.get_total_count()
	_inv_header.text = "FIELD KIT  /  %d %s" % [item_count, "ITEM" if item_count == 1 else "ITEMS"]

	while _inv_list.get_child_count() > 0:
		var old := _inv_list.get_child(0)
		_inv_list.remove_child(old)
		old.queue_free()

	var items := InventorySystem.get_items()
	for item_id in items:
		var data: ItemData = ItemDatabase.get_item(item_id)
		var label_text := data.display_name if data != null else String(item_id)
		_inv_list.add_child(_make_item_row(
			data.icon if data != null else null,
			"%s x%d" % [label_text, items[item_id]]))

	_refresh_objectives()


func _make_item_row(icon: Texture2D, text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)

	var tex := TextureRect.new()
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.custom_minimum_size = Vector2(20, 20)
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.texture = icon
	row.add_child(tex)

	var label := Label.new()
	label.text = text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(0.73, 0.75, 0.68, 1.0))
	label.add_theme_font_size_override("font_size", 13)
	row.add_child(label)
	return row


func _on_prompt_changed(text: String) -> void:
	_prompt_label.text = text
	_prompt_panel.visible = not text.strip_edges().is_empty()


func _wire_pause_menu() -> void:
	_pause_box.get_node("Resume").pressed.connect(func() -> void: GameManager.set_paused(false))
	_pause_box.get_node("Controls").pressed.connect(_on_pause_controls)
	_pause_box.get_node("MainMenu").pressed.connect(_on_pause_main_menu)
	var quit_button := _pause_box.get_node("Quit") as Button
	quit_button.pressed.connect(_on_pause_quit)
	if OS.has_feature("web"):
		quit_button.text = "Fullscreen"
	_pause_controls.closed.connect(_on_pause_controls_closed)
	_pause_controls.visible = false


func _on_pause_controls() -> void:
	_pause_panel.visible = false
	_pause_controls.visible = true


func _on_pause_controls_closed() -> void:
	_pause_controls.visible = false
	_pause_panel.visible = true


func _on_pause_main_menu() -> void:
	GameManager.set_paused(false)
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func _on_pause_quit() -> void:
	if OS.has_feature("web"):
		var mode := DisplayServer.window_get_mode()
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_WINDOWED
			if mode == DisplayServer.WINDOW_MODE_FULLSCREEN
			else DisplayServer.WINDOW_MODE_FULLSCREEN
		)
	else:
		get_tree().quit()


func _on_paused_changed(is_paused: bool) -> void:
	_pause_overlay.visible = is_paused
	if not is_paused:
		_pause_controls.visible = false
		_pause_panel.visible = true
	elif not _pause_controls.visible:
		_pause_box.get_node("Resume").grab_focus()


func _on_notice_posted(text: String) -> void:
	_notice_label.text = text
	_notice_timer.start(_notice_duration_for(text))


func _notice_duration_for(text: String) -> float:
	return clampf(3.0 + text.length() * 0.045, 4.0, 11.0)


func _on_notice_timeout() -> void:
	_notice_label.text = ""


func _on_player_health_changed(current: float, maximum: float) -> void:
	_health_bar.max_value = maximum
	_health_bar.value = current
	_health_label.text = "%d / %d" % [roundi(current), roundi(maximum)]


func _on_scanner_energy_changed(current: float, maximum: float) -> void:
	_scanner_bar.max_value = maximum
	_scanner_bar.value = current
	_scanner_value.text = "%d%%" % roundi(100.0 * current / maxf(maximum, 0.001))


func _on_echo_recorded(_data: MemoryEchoData) -> void:
	_refresh_archive()
	_refresh_objectives()


func _on_upgrade_built(_data: BaseUpgradeData) -> void:
	_refresh_objectives()


func _refresh_archive() -> void:
	_archive_label.text = "ARCHIVE  /  %d TRACES" % ArchiveSystem.get_count()


func _refresh_objectives() -> void:
	var objective := CampaignSystem.get_objective()
	var chapter := String(objective.get("chapter", "THE WORLD FORGOT US"))
	var next := String(objective.get("text", "Find a way forward."))
	_objective_chapter.text = chapter.to_upper()
	_objective_label.text = next
	_objective_location.text = String(objective.get("location", "NO VERIFIED LOCATION"))
	_objective_progress.text = String(objective.get("progress", ""))

	var optional := CampaignSystem.get_optional_focus()
	var has_optional := not optional.is_empty()
	for control in [_optional_rule, _optional_header, _optional_task, _optional_location, _optional_progress]:
		control.visible = has_optional
	if has_optional:
		_optional_task.text = String(optional.get("task", optional.get("label", "Field lead")))
		_optional_location.text = String(optional.get("location", "LOCATION UNKNOWN"))
		_optional_progress.text = String(optional.get("progress", optional.get("status", "OPEN")))


func _show_opening_hint() -> void:
	if InventorySystem.get_total_count() == 0 and _current_level_path() != GameManager.BASE_SCENE_PATH:
		_on_notice_posted("Cullbrook Services. Carriage 317 is west of the yard.\nFollow the amber lamps east and search the lit service crates.")


func _update_ability_label() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		_ability_label.text = "Q SWEEP  /  F SUPPLIES  /  SPACE DODGE  /  I ARCHIVE"
		return
	var dodge_text := "READY"
	var burst_text := "LOCKED"
	if player.has_method("get_dodge_cooldown_ratio"):
		var dodge_ratio := float(player.get_dodge_cooldown_ratio())
		dodge_text = "READY" if dodge_ratio <= 0.0 else "%d%%" % roundi((1.0 - dodge_ratio) * 100.0)
	if WorldState.has_flag(&"memory_burst_unlocked"):
		burst_text = "READY"
		if player.has_method("get_burst_cooldown_ratio"):
			var burst_ratio := float(player.get_burst_cooldown_ratio())
			burst_text = "READY" if burst_ratio <= 0.0 else "%d%%" % roundi((1.0 - burst_ratio) * 100.0)
	_ability_label.text = "Q SWEEP  /  F SUPPLIES  /  SPACE %s  /  R DISCHARGE %s  /  I ARCHIVE" % [dodge_text, burst_text]


func _current_level_path() -> String:
	var main := get_tree().get_first_node_in_group("main")
	if main != null and main.has_method("get_current_level_path"):
		return main.get_current_level_path()
	return ""
