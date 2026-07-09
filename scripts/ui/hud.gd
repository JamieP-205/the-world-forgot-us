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


## Rebuilds the inventory readout: a header total plus one icon+label row
## per item type. Icons come from ItemData.icon (sliced item sprites).
func _refresh_inventory() -> void:
	_inv_header.text = "Items: %d" % InventorySystem.get_total_count()

	# Clear the previous rows (rebuilds only on inventory changes, not per frame).
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


## One inventory row: a 26px icon (if any) beside the name x count.
func _make_item_row(icon: Texture2D, text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)

	var tex := TextureRect.new()
	# Ignore the source texture's (large) size so the row stays 26px tall.
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
	_pause_box.get_node("Quit").pressed.connect(func() -> void: get_tree().quit())
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


func _on_paused_changed(is_paused: bool) -> void:
	_pause_overlay.visible = is_paused
	# Always reopen the pause menu on its main options, not the sub-panel.
	if not is_paused:
		_pause_controls.visible = false
		_pause_box.visible = true


## Shows a transient notice, restarting the timer each time so the latest
## message stays readable.
func _on_notice_posted(text: String) -> void:
	_notice_label.text = text
	_notice_timer.start(_notice_duration_for(text))


## Longer, multi-line story beats (opening, echo recovery, ending hook) linger
## long enough to read; short toasts clear quickly. Clamped to a sane range.
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
	var has_supplies := InventorySystem.get_total_count() > 0
	var has_last_broadcast := ArchiveSystem.has_echo(&"echo_last_signal")
	var at_base := _current_level_path() == GameManager.BASE_SCENE_PATH
	var radio_built := BaseUpgradeSystem.is_built(&"radio_desk")
	var rested := SaveManager.has_save()

	var has_lunchbox := InventorySystem.get_count(&"child_lunchbox") > 0
	var has_choice_keepsake := InventorySystem.get_count(&"tin_locket") > 0
	var beacon_lit := BaseUpgradeSystem.is_built(&"route_beacon")

	var lines: Array[String] = [
		"Demo Goal",
		"Next: %s" % _next_objective_text(
			has_supplies, has_last_broadcast, at_base, radio_built, rested),
		"",
	]
	lines.append(_objective_line(has_supplies, "Search supplies"))
	lines.append(_objective_line(_scanned_echo or has_last_broadcast, "Scan for an echo"))
	lines.append(_objective_line(has_last_broadcast, "Recover The Last Broadcast"))
	lines.append(_objective_line(at_base or radio_built or rested, "Return to the Railhome"))
	lines.append(_objective_line(radio_built, "Build the Radio Desk"))
	lines.append(_objective_line(rested, "Rest at the bedroll"))
	lines.append("")
	lines.append("Optional")
	lines.append(_objective_line(has_lunchbox, "Find who left the lunchbox"))
	lines.append(_objective_line(has_choice_keepsake, "Choose the tin locket over salvage"))
	lines.append(_objective_line(beacon_lit, "Power the roadside beacon"))
	_objective_label.text = "\n".join(lines)


func _objective_line(done: bool, text: String) -> String:
	return "%s %s" % ["[x]" if done else "[ ]", text]


func _next_objective_text(
		has_supplies: bool,
		has_last_broadcast: bool,
		at_base: bool,
		radio_built: bool,
		rested: bool) -> String:
	if not has_supplies:
		return "Follow the cracked road east. Search the glinting roadside crate."
	if not (_scanned_echo or has_last_broadcast):
		return "Keep following the cracked road to the fallen mast. Press Q near the cyan static."
	if not has_last_broadcast:
		return "Interact with the revealed echo beside the fallen mast"
	if not at_base and not radio_built and not rested:
		return "Return west to the bright Railhome doorway"
	if not radio_built:
		return "At the Railhome, build the Radio Desk"
	if not rested:
		return "Radio Desk built - rest at the bedroll to save."
	return "Demo complete. Next signal detected north."


func _show_opening_hint() -> void:
	if InventorySystem.get_total_count() == 0 and _current_level_path() != GameManager.BASE_SCENE_PATH:
		_on_notice_posted("You wake alone on the dead road. The Railhome is at your back; everything the world forgot lies east.\nFollow the amber arrows and search the glinting crates (E).")


func _current_level_path() -> String:
	var main := get_tree().get_first_node_in_group("main")
	if main != null and main.has_method("get_current_level_path"):
		return main.get_current_level_path()
	return ""
