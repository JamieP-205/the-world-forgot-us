class_name NarrativeRouteState
extends RefCounted
## JSON-safe campaign decisions and deterministic ending resolution.

const RouteRegistry = preload("res://scripts/narrative/narrative_route_registry.gd")
const NPCRegistry = preload("res://scripts/narrative/narrative_npc_registry.gd")

const SCHEMA_VERSION := 1
const NPC_STATES: Array[StringName] = [
	&"unmet", &"active", &"rescued", &"injured", &"left", &"dead", &"estranged",
]
const MISSION_STATES: Array[StringName] = [&"available", &"active", &"complete"]
const HOLLOW_OUTCOMES: Array[StringName] = [&"stabilise", &"kill", &"weaponise"]

var route_anchor: StringName = &""
var network_strategy: StringName = &""
var _evidence: Dictionary = {}
var _npc_states: Dictionary = {}
var _fed_traces: Dictionary = {}
var _hollow_outcomes := {&"stabilise": 0, &"kill": 0, &"weaponise": 0}
var _mission_states: Dictionary = {}


func reset() -> void:
	route_anchor = &""
	network_strategy = &""
	_evidence.clear()
	_npc_states.clear()
	_fed_traces.clear()
	_hollow_outcomes = {&"stabilise": 0, &"kill": 0, &"weaponise": 0}
	_mission_states.clear()


func commit_anchor(anchor: StringName) -> bool:
	anchor = _normalise_anchor(anchor)
	if anchor not in RouteRegistry.ANCHORS:
		return false
	if route_anchor != &"" and route_anchor != anchor:
		return false
	route_anchor = anchor
	return true


func commit_strategy(strategy: StringName) -> bool:
	strategy = _normalise_strategy(strategy)
	if strategy not in RouteRegistry.STRATEGIES:
		return false
	if network_strategy != &"" and network_strategy != strategy:
		return false
	network_strategy = strategy
	return true


func get_route_id() -> StringName:
	return RouteRegistry.route_id_for(route_anchor, network_strategy)


func get_route() -> Dictionary:
	return RouteRegistry.get_route(get_route_id())


func add_evidence(revelation_id: StringName) -> bool:
	if revelation_id not in RouteRegistry.REVELATION_IDS or _evidence.has(revelation_id):
		return false
	_evidence[revelation_id] = true
	return true


func has_evidence(revelation_id: StringName) -> bool:
	return bool(_evidence.get(revelation_id, false))


func get_evidence_ids() -> Array[StringName]:
	return _sorted_string_names(_evidence.keys())


func get_evidence_confidence() -> int:
	return _evidence.size()


func set_npc_state(npc_id: StringName, state: StringName) -> bool:
	if npc_id not in NPCRegistry.NPC_IDS or state not in NPC_STATES:
		return false
	if state == &"rescued" and npc_id not in NPCRegistry.RESCUEABLE_NPC_IDS:
		return false
	if StringName(_npc_states.get(npc_id, &"unmet")) == state:
		return false
	_npc_states[npc_id] = state
	return true


func rescue_npc(npc_id: StringName) -> bool:
	if npc_id not in NPCRegistry.RESCUEABLE_NPC_IDS:
		return false
	return set_npc_state(npc_id, &"rescued")


func get_npc_state(npc_id: StringName) -> StringName:
	return StringName(_npc_states.get(npc_id, &"unmet"))


func get_rescued_npcs() -> Array[StringName]:
	var rescued: Array[StringName] = []
	for npc_id in _npc_states:
		if StringName(_npc_states[npc_id]) == &"rescued":
			rescued.append(StringName(npc_id))
	rescued.sort()
	return rescued


func record_trace_fed(trace_id: StringName, fed: bool = true) -> bool:
	if trace_id == &"":
		return false
	if fed:
		if _fed_traces.has(trace_id):
			return false
		_fed_traces[trace_id] = true
		return true
	if not _fed_traces.has(trace_id):
		return false
	_fed_traces.erase(trace_id)
	return true


func is_trace_fed(trace_id: StringName) -> bool:
	return bool(_fed_traces.get(trace_id, false))


func get_fed_trace_ids() -> Array[StringName]:
	return _sorted_string_names(_fed_traces.keys())


func get_fed_trace_count() -> int:
	return _fed_traces.size()


func record_hollow_outcome(outcome: StringName, amount: int = 1) -> bool:
	outcome = _normalise_hollow_policy(outcome)
	if outcome not in HOLLOW_OUTCOMES or amount <= 0:
		return false
	_hollow_outcomes[outcome] = int(_hollow_outcomes.get(outcome, 0)) + amount
	return true


func set_hollow_policy(policy: StringName) -> bool:
	policy = _normalise_hollow_policy(policy)
	if policy == &"mixed":
		_hollow_outcomes = {&"stabilise": 1, &"kill": 1, &"weaponise": 0}
		return true
	if policy not in HOLLOW_OUTCOMES:
		return false
	_hollow_outcomes = {&"stabilise": 0, &"kill": 0, &"weaponise": 0}
	_hollow_outcomes[policy] = 1
	return true


func get_hollow_policy() -> StringName:
	var used: Array[StringName] = []
	for outcome in HOLLOW_OUTCOMES:
		if int(_hollow_outcomes.get(outcome, 0)) > 0:
			used.append(outcome)
	if used.is_empty():
		return &"undecided"
	return used[0] if used.size() == 1 else &"mixed"


func get_hollow_outcomes() -> Dictionary:
	return {
		"stabilise": int(_hollow_outcomes.get(&"stabilise", 0)),
		"kill": int(_hollow_outcomes.get(&"kill", 0)),
		"weaponise": int(_hollow_outcomes.get(&"weaponise", 0)),
	}


func start_mission(mission_id: StringName) -> bool:
	if RouteRegistry.find_mission(get_route_id(), mission_id).is_empty():
		return false
	var current := get_mission_state(mission_id)
	if current != &"available":
		return false
	_mission_states[mission_id] = &"active"
	return true


func complete_mission(mission_id: StringName) -> bool:
	if RouteRegistry.find_mission(get_route_id(), mission_id).is_empty():
		return false
	if get_mission_state(mission_id) != &"active":
		return false
	_mission_states[mission_id] = &"complete"
	return true


func get_mission_state(mission_id: StringName) -> StringName:
	return StringName(_mission_states.get(mission_id, &"available"))


func route_missions_complete() -> bool:
	var missions := RouteRegistry.get_missions(get_route_id())
	if missions.size() != 2:
		return false
	for mission in missions:
		if get_mission_state(StringName(mission.get("id", &""))) != &"complete":
			return false
	return true


func get_gameplay_modifiers() -> Array[StringName]:
	var modifiers: Dictionary = {}
	var route := get_route()
	for modifier in route.get("gameplay_modifiers", []):
		modifiers[StringName(modifier)] = true

	var confidence := get_evidence_confidence()
	var evidence_modifier := &"evidence_unsteady"
	if confidence >= 10:
		evidence_modifier = &"evidence_corroborated"
	elif confidence >= 5:
		evidence_modifier = &"evidence_supported"
	modifiers[evidence_modifier] = true

	modifiers[StringName("hollows_%s" % String(get_hollow_policy()))] = true
	for npc_id in get_rescued_npcs():
		modifiers[StringName("ally_%s_available" % String(npc_id))] = true

	var fed_count := get_fed_trace_count()
	var copy_modifier := &"copy_unfed"
	if fed_count >= 3:
		copy_modifier = &"copy_intimate"
	elif fed_count > 0:
		copy_modifier = &"copy_learning"
	modifiers[copy_modifier] = true

	for mission in RouteRegistry.get_missions(get_route_id()):
		var mission_id := StringName(mission.get("id", &""))
		if get_mission_state(mission_id) == &"complete":
			modifiers[StringName("service_%s" % String(mission.get("service_unlock", &"")))] = true
	return _sorted_string_names(modifiers.keys())


func get_world_states() -> Array[StringName]:
	var states: Dictionary = {}
	for state_id in get_route().get("world_states", []):
		states[StringName(state_id)] = true
	for mission in RouteRegistry.get_missions(get_route_id()):
		var mission_id := StringName(mission.get("id", &""))
		if get_mission_state(mission_id) == &"complete":
			states[StringName(mission.get("world_state", &""))] = true
	return _sorted_string_names(states.keys())


func resolve_outcome(require_completed_missions: bool = true) -> Dictionary:
	var route_id := get_route_id()
	var route := get_route()
	if route_id == &"" or route.is_empty():
		return {}
	if require_completed_missions and not route_missions_complete():
		return {}

	var axis_lines := [
		_evidence_outcome_line(),
		_hollow_outcome_line(),
		_rescue_outcome_line(),
		_trace_outcome_line(),
	]
	var body := String(route.get("ending_body", ""))
	for line in axis_lines:
		if not String(line).is_empty():
			body += " " + String(line)

	var modifiers := get_gameplay_modifiers()
	var world_states := get_world_states()
	var fingerprint := "%s|%s|%s|%s|%s" % [
		route_id,
		",".join(_string_names_to_strings(modifiers)),
		",".join(_string_names_to_strings(world_states)),
		String(get_hollow_policy()),
		get_fed_trace_count(),
	]
	return {
		"ending_id": route_id,
		"route_id": route_id,
		"title": String(route.get("title", "")),
		"subtitle": String(route.get("subtitle", "")),
		"body": body,
		"operation": String(route.get("operation", "")),
		"access": String(route.get("access", "")),
		"finale": String(route.get("finale", "")),
		"gameplay_modifiers": _string_names_to_strings(modifiers),
		"world_states": _string_names_to_strings(world_states),
		"axis_summary": {
			"evidence_confidence": get_evidence_confidence(),
			"hollow_policy": String(get_hollow_policy()),
			"rescued_npcs": _string_names_to_strings(get_rescued_npcs()),
			"fed_traces": get_fed_trace_count(),
		},
		"fingerprint": fingerprint,
	}


func to_dict() -> Dictionary:
	var npc_states: Dictionary = {}
	for npc_id in _sorted_string_names(_npc_states.keys()):
		npc_states[String(npc_id)] = String(_npc_states[npc_id])
	var mission_states: Dictionary = {}
	for mission_id in _sorted_string_names(_mission_states.keys()):
		mission_states[String(mission_id)] = String(_mission_states[mission_id])
	return {
		"schema_version": SCHEMA_VERSION,
		"route_anchor": String(route_anchor),
		"network_strategy": String(network_strategy),
		"evidence_ids": _string_names_to_strings(get_evidence_ids()),
		"npc_states": npc_states,
		"rescued_npcs": _string_names_to_strings(get_rescued_npcs()),
		"fed_trace_ids": _string_names_to_strings(get_fed_trace_ids()),
		"hollow_outcomes": get_hollow_outcomes(),
		"hollow_policy": String(get_hollow_policy()),
		"mission_states": mission_states,
	}


func restore(data: Dictionary, _source_save_version: int = 0) -> void:
	reset()
	var anchor := StringName(data.get("route_anchor", data.get("anchor", "")))
	var strategy := StringName(data.get("network_strategy", data.get("strategy", "")))
	if anchor != &"":
		commit_anchor(anchor)
	if strategy != &"":
		commit_strategy(strategy)

	var evidence_source: Variant = data.get("evidence_ids", data.get("evidence", []))
	if evidence_source is Array:
		for revelation_id in evidence_source:
			add_evidence(StringName(revelation_id))

	var npc_source: Dictionary = data.get("npc_states", {})
	for npc_id in npc_source:
		set_npc_state(StringName(npc_id), StringName(npc_source[npc_id]))
	for npc_id in data.get("rescued_npcs", []):
		rescue_npc(StringName(npc_id))

	for trace_id in data.get("fed_trace_ids", data.get("fed_traces", [])):
		record_trace_fed(StringName(trace_id))

	var hollow_source: Dictionary = data.get("hollow_outcomes", {})
	var restored_hollows := false
	for outcome in HOLLOW_OUTCOMES:
		var amount := int(hollow_source.get(String(outcome), hollow_source.get(outcome, 0)))
		if amount > 0:
			record_hollow_outcome(outcome, amount)
			restored_hollows = true
	if not restored_hollows:
		var policy := StringName(data.get("hollow_policy", ""))
		if policy != &"" and policy != &"undecided":
			set_hollow_policy(policy)

	var mission_source: Dictionary = data.get("mission_states", {})
	for mission_id in mission_source:
		_restore_mission_state(StringName(mission_id), StringName(mission_source[mission_id]))
	for mission_id in data.get("completed_missions", []):
		_restore_mission_state(StringName(mission_id), &"complete")


func _restore_mission_state(mission_id: StringName, state: StringName) -> void:
	if state not in MISSION_STATES:
		return
	if RouteRegistry.find_mission(get_route_id(), mission_id).is_empty():
		return
	if state != &"available":
		_mission_states[mission_id] = state


func _normalise_anchor(anchor: StringName) -> StringName:
	match anchor:
		&"imogen": return &"clinic"
		&"rafi": return &"radio"
		&"leena": return &"witness"
		&"maggie", &"continuity": return &"copy"
	return anchor


func _normalise_strategy(strategy: StringName) -> StringName:
	match strategy:
		&"archive": return &"restore"
		&"choir", &"local": return &"mesh"
		&"silence", &"destroy": return &"sever"
	return strategy


func _normalise_hollow_policy(policy: StringName) -> StringName:
	match policy:
		&"cure", &"release": return &"stabilise"
		&"use", &"lure": return &"weaponise"
	return policy


func _evidence_outcome_line() -> String:
	var confidence := get_evidence_confidence()
	if confidence >= 10:
		return "The incident chain is corroborated well enough that nobody can dismiss it as one survivor's account."
	if confidence >= 5:
		return "The central claim holds, though several names remain supported rather than corroborated."
	return "Ellie can defend only part of the account; the rest remains honestly marked uncertain."


func _hollow_outcome_line() -> String:
	match get_hollow_policy():
		&"stabilise": return "Imogen's counter-signal brings recoverable Hollows back as patients, not trophies."
		&"kill": return "The roads are safer, and several people who might have returned do not."
		&"weaponise": return "Nia's carrier lures protect the settlements and leave a weapon somebody else may inherit."
		&"mixed": return "Some Hollows return, some are killed and some are used; nobody can call the policy clean."
	return "No shared Hollow policy survives the road, so each settlement makes its own frightened rule."


func _rescue_outcome_line() -> String:
	var rescued := get_rescued_npcs()
	if rescued.is_empty():
		return "Carriage 317 stays a quiet shelter with too few hands for the work left behind."
	var names: Array[String] = []
	for npc_id in rescued:
		var definition := NPCRegistry.get_definition(npc_id)
		names.append(String(definition.get("display_name", npc_id)))
	return "%s reach Carriage 317 and keep their own work alive." % _join_human(names)


func _trace_outcome_line() -> String:
	var count := get_fed_trace_count()
	if count == 0:
		return "The copy never receives Ellie's private traces and never sounds fully like Maggie."
	if count < 3:
		return "The copy learns %d private trace%s, enough to become familiar without becoming complete." % [count, "" if count == 1 else "s"]
	return "With %d private traces, the copy knows family details no public record should hold." % count


func _join_human(values: Array[String]) -> String:
	if values.is_empty():
		return "Nobody"
	if values.size() == 1:
		return values[0]
	if values.size() == 2:
		return "%s and %s" % [values[0], values[1]]
	return "%s and %s" % [", ".join(values.slice(0, values.size() - 1)), values[-1]]


func _sorted_string_names(values: Array) -> Array[StringName]:
	var strings: Array[String] = []
	for value in values:
		strings.append(String(value))
	strings.sort()
	var names: Array[StringName] = []
	for value in strings:
		names.append(StringName(value))
	return names


func _string_names_to_strings(values: Array[StringName]) -> Array[String]:
	var strings: Array[String] = []
	for value in values:
		strings.append(String(value))
	return strings
