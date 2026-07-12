extends Node
## Autoload: SaveManager
##
## Serialises the demo state to a single JSON file and restores it on launch:
## current level, player position/health, inventory, recovered echoes, and
## built base upgrades.

const SAVE_PATH := "user://savegame.json"
## Bumped when the save schema changes. Missing/older values are read with
## safe defaults, so pre-version saves still load (just without world flags).
const SAVE_VERSION := 2

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
		"upgrades": _ids_to_strings(BaseUpgradeSystem.get_built_ids()),
		"world": WorldState.get_state(),
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
	if not has_save():
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("SaveManager: could not open save file for reading.")
		return false
	var text := file.get_as_text()
	file.close()

	var data: Variant = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		push_error("SaveManager: save file is corrupt.")
		return false

	InventorySystem.set_items(data.get("inventory", {}))
	ArchiveSystem.restore(data.get("archive", []))
	BaseUpgradeSystem.restore(data.get("upgrades", []))
	# Older saves have no "world" key; restore() handles the empty default.
	WorldState.restore(data.get("world", {}))

	_pending_player = data.get("player", {})
	if not EventBus.level_loaded.is_connected(_on_level_loaded):
		EventBus.level_loaded.connect(_on_level_loaded, CONNECT_ONE_SHOT)

	var level_path := String(data.get("level", ""))
	if level_path.is_empty():
		return false
	GameManager.travel_to(level_path, &"")
	return true


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


## Wipes the save file and all in-memory run state, for a clean New Game.
## Leaves no stale WorldState/inventory/echo/upgrade flags behind.
func clear_run_state() -> void:
	delete_save()
	InventorySystem.set_items({})
	ArchiveSystem.restore([])
	BaseUpgradeSystem.restore([])
	WorldState.clear()


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
