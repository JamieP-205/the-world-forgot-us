extends CanvasLayer
## In-game HUD: meters, inventory, objectives, interaction prompt, notices.

@onready var _inv_header: Label = $InventoryPanel/Header
@onready var _inv_list: VBoxContainer = $InventoryPanel/List
@onready var _prompt_label: Label = $PromptLabel
@onready var _pause_overlay: ColorRect = $PauseOverlay
@onready var _pause_box: VBoxContainer = $PauseOverlay/PauseBox
@onready var _pause_controls: Control = $PauseOverlay/PauseControls
@onready var _notice_label: Label = $NoticeLabel
@onready var _notice_timer: Timer = $NoticeTimer
@onready var _health_bar: ProgressBar = $HealthBar
@onready var _health_label: Label = $HealthBar/HealthLabel
@onready var _scanner_bar: ProgressBar = $ScannerBar
@onready var _archive_label: Label = $ArchiveLabel
@onready var _objective_label: Label = $ObjectiveLabel
@onready var _compass = $Compass
@onready var _ability_label: Label = $AbilityLabel

var _scanned_echo := false


func _ready() -> void:
	InventorySystem.inventory_changed.connect(_refresh_inventory)
	EventBus.interaction_prompt_changed.connect(_on_prompt_changed)
	EventBus.paused_changed.connect(_on_paused_changed)
	EventBus.notice_posted.connect(_on_notice_posted)
	EventBus.player_health_changed.connect(_on_player_health_changed)
	EventBus.scanner_energy_changed.connect(_on_scanner_energy_changed)
	EventBus.level_loaded.connect(_refresh_objectives)
	EventBus.echo_revealed.connect(_on_echo_revealed)
	EventBus.game_saved.connect(_refresh_objectives)
	EventBus.campaign_progress_changed.connect(_refresh_objectives)
	ArchiveSystem.echo_recorded.connect(_on_echo_recorded)
	BaseUpgradeSystem.upgrade_built.connect(_on_upgrade_built)
	_notice_timer.timeout.connect(_on_notice_timeout)
	_wire_pause_menu()
	_scanned_echo = ArchiveSystem.has_echo(&"echo_last_signal")
	_refresh_inventory()
	_prompt_label.text = ""
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

	var at_base := _current_level_path() == GameManager.BASE_SCENE_PATH
	var has_broadcast := ArchiveSystem.has_echo(&"echo_last_signal")
	var has_coil := BaseUpgradeSystem.is_built(&"scanner_coil")
	var radio_built := BaseUpgradeSystem.is_built(&"radio_desk")
	var rested := SaveManager.has_save()
	var target_name := ""

	if at_base:
		if not has_broadcast:
			target_name = "Outside" if has_coil else "ScannerCoilBench"
		elif not radio_built:
			target_name = "RadioDeskStation"
		elif not rested:
			target_name = "Bedroll"
		else:
			target_name = "Outside"
	else:
		if not has_broadcast:
			if has_coil:
				target_name = "MemoryEcho"
			elif _has_coil_materials():
				target_name = "BaseDoor"
			elif InventorySystem.get_total_count() == 0:
				target_name = "RoadsideCrate"
			else:
				target_name = "ShedLocker"
		elif not radio_built or not rested:
			target_name = "BaseDoor"
		else:
			target_name = "NorthSignal"

	return level.find_child(target_name, true, false) as Node2D


func _has_coil_materials() -> bool:
	return InventorySystem.get_count(&"battery") >= 1 and InventorySystem.get_count(&"scrap") >= 2


func _has_radio_materials() -> bool:
	return InventorySystem.get_count(&"battery") >= 1 and InventorySystem.get_count(&"scrap") >= 3


func _refresh_inventory() -> void:
	_inv_header.text = "Items: %d" % InventorySystem.get_total_count()

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
	tex.custom_minimum_size = Vector2(26, 26)
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.texture = icon
	row.add_child(tex)

	var label := Label.new()
	label.text = text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	row.add_child(label)
	return row


func _on_prompt_changed(text: String) -> void:
	_prompt_label.text = text


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
	_pause_box.visible = false
	_pause_controls.visible = true


func _on_pause_controls_closed() -> void:
	_pause_controls.visible = false
	_pause_box.visible = true


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
		_pause_box.visible = true


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


func _on_echo_revealed(_data: MemoryEchoData) -> void:
	_scanned_echo = true
	_refresh_objectives()


func _on_echo_recorded(_data: MemoryEchoData) -> void:
	_refresh_archive()
	_refresh_objectives()


func _on_upgrade_built(_data: BaseUpgradeData) -> void:
	_refresh_objectives()


func _refresh_archive() -> void:
	_archive_label.text = "Echoes recovered: %d" % ArchiveSystem.get_count()


func _refresh_objectives() -> void:
	var objective := CampaignSystem.get_objective()
	var chapter := String(objective.get("chapter", "THE WORLD FORGOT US"))
	var next := String(objective.get("text", "Find a way forward."))
	var optional: Array[String] = []
	if not WorldState.is_opened(&"keepsake_shelf_used"):
		optional.append("[ ] Preserve a keepsake at the Railhome")
	if not ArchiveSystem.has_echo(&"echo_names_wall"):
		optional.append("[ ] Find the optional wall of names")
	if optional.is_empty():
		optional.append("[x] Optional memories preserved")
	_objective_label.text = "%s\n\nNEXT\n%s\n\nOPTIONAL\n%s" % [
		chapter,
		next,
		"\n".join(optional),
	]
	return
	var has_supplies := InventorySystem.get_total_count() > 0
	var has_last_broadcast := ArchiveSystem.has_echo(&"echo_last_signal")
	var has_coil := BaseUpgradeSystem.is_built(&"scanner_coil")
	var at_base := _current_level_path() == GameManager.BASE_SCENE_PATH
	var radio_built := BaseUpgradeSystem.is_built(&"radio_desk")
	var rested := SaveManager.has_save()
	var shelf_used := WorldState.is_opened(&"keepsake_shelf_used")
	var relay_clear := WorldState.is_defeated(&"RelayHollow") or WorldState.is_opened(&"RelayCache")
	var lantern_lit := BaseUpgradeSystem.is_built(&"base_lantern")

	var lines: Array[String] = [
		"Core Signal",
		"Next: %s" % _next_objective_text(
			has_supplies, has_coil, has_last_broadcast, at_base, radio_built, rested),
		"",
	]
	lines.append(_objective_line(has_supplies, "Search first supplies"))
	lines.append(_objective_line(has_coil, "Build Scanner Coil"))
	lines.append(_objective_line(_scanned_echo or has_last_broadcast, "Reveal the mast echo"))
	lines.append(_objective_line(has_last_broadcast, "Recover The Last Broadcast"))
	lines.append(_objective_line(at_base or radio_built or rested, "Return to the Railhome"))
	lines.append(_objective_line(radio_built, "Build the Radio Desk"))
	lines.append(_objective_line(rested, "Rest and save"))
	lines.append("")
	lines.append("Useful extras")
	lines.append(_objective_line(shelf_used, "Tend keepsakes at Memory Shelf"))
	lines.append(_objective_line(relay_clear, "Clear guarded relay cache"))
	lines.append(_objective_line(lantern_lit, "Wire the Signal Lantern"))
	_objective_label.text = "\n".join(lines)


func _objective_line(done: bool, text: String) -> String:
	return "%s %s" % ["[x]" if done else "[ ]", text]


func _next_objective_text(
		has_supplies: bool,
		has_coil: bool,
		has_last_broadcast: bool,
		at_base: bool,
		radio_built: bool,
		rested: bool) -> String:
	if not has_supplies:
		return "Follow the amber road east. Search the first glowing crate."
	if not has_coil:
		if at_base:
			return "Build the Scanner Coil so the Mnemoscope can hold the mast signal."
		if _has_coil_materials():
			return "You have coil parts. Return west to the Railhome and build it."
		return "Find battery and scrap in the car, kiosk, and shed. Food heals with F."
	if not has_last_broadcast:
		if at_base:
			return "Scanner Coil built. Step outside and return to the fallen mast."
		if not _scanned_echo:
			return "Go to the fallen mast and press Q to scan the signal."
		return "Interact with the revealed echo beside the fallen mast."
	if not at_base and not radio_built and not rested:
		return "Carry the memory west to the Railhome."
	if not radio_built:
		if _has_radio_materials():
			return "Build the Radio Desk from the recovered memory and supplies."
		return "Find enough battery and scrap for the Radio Desk. The relay cache can help."
	if not rested:
		return "Radio Desk online. Rest at the bedroll to save and finish the slice."
	return "Demo endpoint reached. The north signal is an ending hook, not a playable next zone."


func _show_opening_hint() -> void:
	if InventorySystem.get_total_count() == 0 and _current_level_path() != GameManager.BASE_SCENE_PATH:
		_on_notice_posted("You wake on the dead road with the Railhome behind you.\nFollow the amber road, search supplies with E, and keep food for healing with F.")


func _update_ability_label() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		_ability_label.text = "[SPACE] Dodge   [I] Archive"
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
	_ability_label.text = "[SPACE] Dodge %s    [R] Burst %s    [I] Archive" % [dodge_text, burst_text]


func _current_level_path() -> String:
	var main := get_tree().get_first_node_in_group("main")
	if main != null and main.has_method("get_current_level_path"):
		return main.get_current_level_path()
	return ""
