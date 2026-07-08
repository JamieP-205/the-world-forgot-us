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
var ending_hook_shown := false


# --- Loot containers ---
func mark_opened(id: StringName) -> void:
	if id != &"":
		_opened[id] = true


func is_opened(id: StringName) -> bool:
	return _opened.get(id, false)


# --- Either/or choices ---
func mark_choice(group: StringName, option: StringName) -> void:
	if group != &"":
		_choices[group] = String(option)


func choice_taken(group: StringName) -> bool:
	return _choices.has(group)


func chosen_option(group: StringName) -> String:
	return _choices.get(group, "")


# --- Defeated hand-placed enemies ---
func mark_defeated(id: StringName) -> void:
	if id != &"":
		_defeated[id] = true


func is_defeated(id: StringName) -> bool:
	return _defeated.get(id, false)


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
	return {
		"opened": opened_ids,
		"choices": choices,
		"defeated": defeated_ids,
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
	ending_hook_shown = bool(data.get("ending_hook_shown", false))


func clear() -> void:
	_opened.clear()
	_choices.clear()
	_defeated.clear()
	ending_hook_shown = false
