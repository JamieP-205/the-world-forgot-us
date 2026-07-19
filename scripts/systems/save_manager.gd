extends Node
## Autoload: SaveManager
##
## Serialises the demo state to a single JSON file and restores it on launch:
## current level, player position/health, inventory, recovered echoes, and
## built base upgrades.

const SAVE_PATH := "user://savegame.json"
## Version three separated narrative decisions; version four adds per-trace
## filing decisions while preserving the legacy archive id array.
const SAVE_VERSION := 4

## Player state waiting to be applied once the loaded level is ready.
var _pending_player: Dictionary = {}


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game(notice: String = "Progress saved.") -> bool:
	var main := get_tree().get_first_node_in_group("main")
	var player := get_tree().get_first_node_in_group("player")

	var data := {
		"version": SAVE_VERSION,
		"level": main.get_current_level_path() if main != null else "",
		"player": {
			"x": player.global_position.x if player != null else 0.0,
			"y": player.global_position.y if player != null else 0.0,
			"health": player.get_health() if player != null and player.has_method("get_health") else 100.0,
		},
		"inventory": _keys_to_strings(InventorySystem.get_items()),
		"archive": _ids_to_strings(ArchiveSystem.get_recovered_ids()),
		"archive_dispositions": ArchiveSystem.get_dispositions(),
		"upgrades": _ids_to_strings(BaseUpgradeSystem.get_built_ids()),
		"world": WorldState.get_state(),
		"narrative": CampaignSystem.get_narrative_state(),
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: could not open save file for writing.")
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	EventBus.game_saved.emit()
	if not notice.is_empty():
		EventBus.notice_posted.emit(notice)
	return true


func load_game() -> bool:
	_cancel_pending_player_restore()
	if not has_save():
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("SaveManager: could not open save file for reading.")
		return false
	var text := file.get_as_text()
	file.close()

	# Parse through a JSON instance rather than JSON.parse_string() so an
	# unparseable local save is reported as a recoverable condition instead of
	# spamming the engine error log.
	var json := JSON.new()
	if json.parse(text) != OK or typeof(json.data) != TYPE_DICTIONARY:
		push_warning("SaveManager: save file is corrupt; keeping the current session.")
		return false
	var data: Dictionary = json.data

	# Validate the destination and payload shape before changing any live run
	# state. A stale or hand-edited level path -- or a locally edited field with
	# the wrong type -- must not half-restore inventory, story flags, or a player
	# transform into the current session.
	var level_path := String(data.get("level", ""))
	if not _is_loadable_level(level_path):
		return false
	if not _has_restorable_shape(data):
		push_warning("SaveManager: save file has malformed fields; keeping the current session.")
		return false

	var source_version := int(data.get("version", 0))
	CraftedItemEffects.clear_runtime_state()
	InventorySystem.set_items(data.get("inventory", {}))
	ArchiveSystem.restore(
		data.get("archive", []),
		data.get("archive_dispositions", {}),
	)
	BaseUpgradeSystem.restore(data.get("upgrades", []))
	# Older saves have no "world" key; restore() handles the empty default.
	WorldState.restore(data.get("world", {}))
	# Version 3 stores route decisions separately from legacy world flags.
	# CampaignSystem reconstructs safe evidence/rescue defaults for older saves.
	CampaignSystem.restore_narrative_state(data.get("narrative", {}), source_version)

	var player_data: Variant = data.get("player", {})
	_pending_player = Dictionary(player_data).duplicate(true) \
		if typeof(player_data) == TYPE_DICTIONARY else {}
	if not EventBus.level_loaded.is_connected(_on_level_loaded):
		EventBus.level_loaded.connect(_on_level_loaded, CONNECT_ONE_SHOT)

	GameManager.travel_to(level_path, &"")
	return true


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


## Wipes the save file and all in-memory run state, for a clean New Game.
## Leaves no stale WorldState/inventory/echo/upgrade flags behind.
func clear_run_state() -> void:
	_cancel_pending_player_restore()
	delete_save()
	CraftedItemEffects.clear_runtime_state()
	InventorySystem.set_items({})
	ArchiveSystem.restore([])
	BaseUpgradeSystem.restore([])
	WorldState.clear()
	CampaignSystem.clear_narrative_state(false)


func _is_loadable_level(level_path: String) -> bool:
	if not GameManager.is_travel_destination(level_path):
		push_warning("SaveManager: save refers to an unknown level; keeping the current session.")
		return false
	if not ResourceLoader.exists(level_path, "PackedScene"):
		return false
	return load(level_path) is PackedScene


# Rejects a locally edited save whose top-level fields carry the wrong container
# type, so a malformed payload can never crash a strictly-typed restore or be
# half-applied to the live session. Missing fields are fine -- older saves omit
# them and each restore falls back to its empty default. The nested contents of
# "world"/"narrative" are validated defensively by their own restore functions.
func _has_restorable_shape(data: Dictionary) -> bool:
	for key in ["inventory", "archive_dispositions", "world", "narrative", "player"]:
		if data.has(key) and not (data[key] is Dictionary):
			return false
	for key in ["archive", "upgrades"]:
		if data.has(key) and not (data[key] is Array):
			return false
	if data.has("version") and not (data["version"] is float or data["version"] is int):
		return false
	if data.has("player"):
		var player := data.player as Dictionary
		for axis in ["x", "y"]:
			if player.has(axis) and not _is_bounded_number(player[axis], 10000.0):
				return false
		if player.has("health") and not _is_bounded_number(player.health, 1000.0):
			return false
	return true


func _is_bounded_number(value: Variant, absolute_limit: float) -> bool:
	if not (value is int or value is float):
		return false
	var number := float(value)
	return not is_nan(number) and not is_inf(number) \
		and absf(number) <= absolute_limit


func _cancel_pending_player_restore() -> void:
	_pending_player = {}
	if EventBus.level_loaded.is_connected(_on_level_loaded):
		EventBus.level_loaded.disconnect(_on_level_loaded)


func _on_level_loaded() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player != null and not _pending_player.is_empty():
		player.global_position = Vector2(
			float(_pending_player.get("x", 0.0)),
			float(_pending_player.get("y", 0.0))
		)
		if player.has_method("set_health"):
			player.set_health(float(_pending_player.get("health", 100.0)))
	_pending_player = {}


# JSON keys/values must be plain strings, so flatten StringNames.
func _keys_to_strings(source: Dictionary) -> Dictionary:
	var out := {}
	for key in source:
		out[String(key)] = int(source[key])
	return out


func _ids_to_strings(ids: Array) -> Array:
	var out := []
	for id in ids:
		out.append(String(id))
	return out
