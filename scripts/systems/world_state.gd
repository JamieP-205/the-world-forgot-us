extends Node
## Autoload: WorldState
##
## A small persistent set of "consumed" world flags that must survive scene
## travel (levels are re-instanced on every trip) AND save/load: searched
## loot containers, resolved either/or choices, defeated hand-placed
## enemies, and the one-time ending hook. It mirrors how BaseUpgradeSystem
## tracks built ids -- a plain flag store, not a new gameplay system.
##
## Ids are StringNames. Placed nodes default their id to their node name, so
## no per-instance setup is needed as long as node names stay unique within
## the demo (they are). SaveManager serialises get_state()/restore().

var _opened: Dictionary = {}     # container id -> true
var _choices: Dictionary = {}    # choice group id -> chosen option id
var _defeated: Dictionary = {}   # enemy id -> true
var _flags: Dictionary = {}      # campaign / quest id -> JSON-safe value
var ending_hook_shown := false

const NON_CACHE_OPENED_IDS: Array[StringName] = [&"keepsake_shelf_used"]


# --- Loot containers ---
func mark_opened(id: StringName) -> void:
	if id != &"":
		_opened[id] = true
		EventBus.campaign_progress_changed.emit()


func is_opened(id: StringName) -> bool:
	return _opened.get(id, false)


## Route-parts drawers use this as a coarse proof that the player has actually
## searched the road before asking for emergency stock. At present the only
## non-loot entry in the opened set is the Railhome keepsake shelf.
func get_searched_cache_count() -> int:
	var count := 0
	for raw_id in _opened:
		if StringName(raw_id) not in NON_CACHE_OPENED_IDS:
			count += 1
	return count


# --- Either/or choices ---
func mark_choice(group: StringName, option: StringName) -> void:
	if group != &"":
		_choices[group] = String(option)
		EventBus.campaign_progress_changed.emit()


func choice_taken(group: StringName) -> bool:
	return _choices.has(group)


func chosen_option(group: StringName) -> String:
	return _choices.get(group, "")


# --- Defeated hand-placed enemies ---
func mark_defeated(id: StringName) -> void:
	if id != &"":
		_defeated[id] = true
		EventBus.campaign_progress_changed.emit()


func is_defeated(id: StringName) -> bool:
	return _defeated.get(id, false)


# --- Campaign flags ---
## Compact persistent state store used by campaign routes and world changes.
## Values must stay JSON-safe because SaveManager persists this dictionary.
func set_flag(id: StringName, value: Variant = true) -> void:
	if id == &"":
		return
	_flags[id] = value
	EventBus.campaign_progress_changed.emit()


func get_flag(id: StringName, default: Variant = false) -> Variant:
	return _flags.get(id, default)


func has_flag(id: StringName) -> bool:
	return bool(_flags.get(id, false))


func get_flags() -> Dictionary:
	return _flags.duplicate(true)


# --- Save/load snapshot (plain strings, JSON-safe) ---
func get_state() -> Dictionary:
	var opened_ids: Array = []
	for k in _opened:
		opened_ids.append(String(k))
	var choices: Dictionary = {}
	for g in _choices:
		choices[String(g)] = String(_choices[g])
	var defeated_ids: Array = []
	for k in _defeated:
		defeated_ids.append(String(k))
	var flags: Dictionary = {}
	for k in _flags:
		flags[String(k)] = _flags[k]
	return {
		"opened": opened_ids,
		"choices": choices,
		"defeated": defeated_ids,
		"flags": flags,
		"ending_hook_shown": ending_hook_shown,
	}


func restore(data: Dictionary) -> void:
	clear()
	for id in data.get("opened", []):
		_opened[StringName(id)] = true
	var ch: Dictionary = data.get("choices", {})
	for g in ch:
		_choices[StringName(g)] = String(ch[g])
	for id in data.get("defeated", []):
		_defeated[StringName(id)] = true
	var saved_flags: Dictionary = data.get("flags", {})
	for id in saved_flags:
		_flags[StringName(id)] = saved_flags[id]
	ending_hook_shown = bool(data.get("ending_hook_shown", false))


func clear() -> void:
	_opened.clear()
	_choices.clear()
	_defeated.clear()
	_flags.clear()
	ending_hook_shown = false
