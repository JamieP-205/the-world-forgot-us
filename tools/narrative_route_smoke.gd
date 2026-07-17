extends Node
## Deterministic route/state smoke.
## Run with an isolated APPDATA directory:
## godot --headless --path <project> --scene res://tools/narrative_route_smoke.tscn

const RouteRegistry = preload("res://scripts/narrative/narrative_route_registry.gd")
const RouteState = preload("res://scripts/narrative/narrative_route_state.gd")
const NPCRegistry = preload("res://scripts/narrative/narrative_npc_registry.gd")

var _failures: Array[String] = []


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_registries()
	_check_all_twelve_routes()
	_check_consequence_axes()
	_check_legacy_state_migration()
	_check_legacy_world_migration()
	_check_legacy_repeater_conflicts()
	_check_campaign_hooks()
	if _failures.is_empty():
		print("NARRATIVE_ROUTE_SMOKE: PASS")
		get_tree().quit(0)
		return
	for failure in _failures:
		push_error("NARRATIVE_ROUTE_SMOKE: " + failure)
	print("NARRATIVE_ROUTE_SMOKE: FAIL (%d)" % _failures.size())
	get_tree().quit(1)


func _check_registries() -> void:
	for error in RouteRegistry.validate():
		_fail("route registry: " + error)
	for error in NPCRegistry.validate():
		_fail("NPC registry: " + error)
	_check(RouteRegistry.all_route_ids().size() == 12, "route registry exposes twelve ids")
	_check(NPCRegistry.all_ids().size() == 12, "NPC registry exposes the twelve-person cast")

	var service_ids: Dictionary = {}
	var voice_openers: Dictionary = {}
	for npc_id in NPCRegistry.all_ids():
		var definition := NPCRegistry.get_definition(npc_id)
		var service: Dictionary = definition.get("service", {})
		var service_id := StringName(service.get("id", &""))
		_check(service_id != &"", "%s has a meaningful service" % npc_id)
		_check(not service_ids.has(service_id), "%s service is distinct" % npc_id)
		service_ids[service_id] = true
		var voice: Dictionary = definition.get("voice", {})
		var samples: Array = voice.get("samples", [])
		if not samples.is_empty():
			var opener := String(samples[0])
			_check(not voice_openers.has(opener), "%s voice sample is distinct" % npc_id)
			voice_openers[opener] = true


func _check_all_twelve_routes() -> void:
	var material_outcomes: Dictionary = {}
	var ending_texts: Dictionary = {}
	var route_count := 0
	var policies: Array[StringName] = [&"stabilise", &"kill", &"weaponise", &"mixed"]
	var anchor_allies := {
		&"clinic": &"imogen",
		&"radio": &"rafi",
		&"witness": &"leena",
		&"copy": &"nia",
	}
	for anchor in RouteRegistry.ANCHORS:
		for strategy in RouteRegistry.STRATEGIES:
			var state = RouteState.new()
			_check(state.commit_anchor(anchor), "%s/%s anchor is reachable" % [anchor, strategy])
			_check(state.commit_strategy(strategy), "%s/%s strategy is reachable" % [anchor, strategy])
			var route_id: StringName = state.get_route_id()
			_check(route_id == RouteRegistry.route_id_for(anchor, strategy), "%s resolves deterministically" % route_id)

			# Exercise every consequence axis while retaining different route values.
			var evidence_count := 4 + route_count % 8
			for evidence_index in evidence_count:
				state.add_evidence(RouteRegistry.REVELATION_IDS[evidence_index])
			state.set_hollow_policy(policies[route_count % policies.size()])
			state.rescue_npc(anchor_allies[anchor])
			if route_count % 2 == 0:
				state.rescue_npc(&"doyle")
			for trace_index in route_count % 4:
				state.record_trace_fed(StringName("route_trace_%d" % trace_index))

			var missions := RouteRegistry.get_missions(route_id)
			_check(missions.size() == 2, "%s has two exclusive missions" % route_id)
			for mission in missions:
				var mission_id := StringName(mission.get("id", &""))
				_check(state.start_mission(mission_id), "%s mission starts" % mission_id)
				_check(state.complete_mission(mission_id), "%s mission completes" % mission_id)
			_check(state.route_missions_complete(), "%s route jobs complete" % route_id)

			# JSON round-trip is the save contract, not an in-memory duplicate.
			var saved := state.to_dict()
			var parsed: Variant = JSON.parse_string(JSON.stringify(saved))
			_check(typeof(parsed) == TYPE_DICTIONARY, "%s state serialises to JSON" % route_id)
			var restored = RouteState.new()
			restored.restore(parsed, 3)
			_check(restored.to_dict() == saved, "%s state survives a lossless save round-trip" % route_id)
			_check(restored.get_route_id() == route_id, "%s route survives save round-trip" % route_id)
			_check(restored.route_missions_complete(), "%s mission state survives save round-trip" % route_id)

			var outcome := restored.resolve_outcome(true)
			_check(not outcome.is_empty(), "%s resolves an ending" % route_id)
			_check(StringName(outcome.get("route_id", &"")) == route_id, "%s ending keeps its route id" % route_id)
			_check(Array(outcome.get("gameplay_modifiers", [])).size() >= 7, "%s ending exposes material gameplay modifiers" % route_id)
			var route := RouteRegistry.get_route(route_id)
			var route_material_key := JSON.stringify([
				route.get("title", ""), route.get("operation", ""), route.get("access", ""),
				route.get("finale", ""), route.get("gameplay_modifiers", []), route.get("world_states", []),
			])
			_check(not material_outcomes.has(route_material_key), "%s operation and world state are distinct" % route_id)
			material_outcomes[route_material_key] = route_id
			var ending_text := "%s|%s" % [outcome.get("title", ""), outcome.get("body", "")]
			_check(not ending_texts.has(ending_text), "%s ending text is distinct" % route_id)
			ending_texts[ending_text] = route_id
			route_count += 1
	_check(route_count == 12, "all twelve route combinations were exercised")
	_check(material_outcomes.size() == 12, "all twelve routes change operation, gameplay and map state")
	_check(ending_texts.size() == 12, "all twelve routes resolve distinct outcome text")


func _check_consequence_axes() -> void:
	var baseline = _completed_state(&"clinic", &"restore")
	var baseline_outcome: Dictionary = baseline.resolve_outcome(true)
	var changed = _completed_state(&"clinic", &"restore")
	for revelation_id in RouteRegistry.REVELATION_IDS.slice(0, 10):
		changed.add_evidence(revelation_id)
	changed.set_hollow_policy(&"stabilise")
	changed.rescue_npc(&"imogen")
	changed.rescue_npc(&"rafi")
	changed.rescue_npc(&"leena")
	changed.record_trace_fed(&"private_lunch_tin")
	changed.record_trace_fed(&"private_house_number")
	changed.record_trace_fed(&"private_last_tape")
	var changed_outcome: Dictionary = changed.resolve_outcome(true)
	_check(changed_outcome.get("body", "") != baseline_outcome.get("body", ""), "consequence axes change ending text within one route")
	var baseline_modifiers: Array = baseline_outcome.get("gameplay_modifiers", [])
	var changed_modifiers: Array = changed_outcome.get("gameplay_modifiers", [])
	_check("evidence_unsteady" in baseline_modifiers and "evidence_corroborated" in changed_modifiers, "evidence confidence changes gameplay modifiers")
	_check("hollows_undecided" in baseline_modifiers and "hollows_stabilise" in changed_modifiers, "Hollow policy changes gameplay modifiers")
	_check("copy_unfed" in baseline_modifiers and "copy_intimate" in changed_modifiers, "fed traces change copy gameplay modifiers")
	_check("ally_imogen_available" in changed_modifiers and "ally_rafi_available" in changed_modifiers, "rescues change ally gameplay modifiers")


func _check_legacy_state_migration() -> void:
	var state = RouteState.new()
	state.restore({
		"anchor": "imogen",
		"strategy": "choir",
		"evidence": ["R01", "R03", "R05"],
		"hollow_policy": "cure",
		"rescued_npcs": ["rafi"],
		"fed_traces": ["old_private_trace"],
		"completed_missions": ["mission_clinic_mesh_patients", "mission_clinic_mesh_cold_chain"],
	}, 2)
	_check(state.get_route_id() == &"clinic_mesh", "legacy anchor and ending aliases migrate")
	_check(state.get_hollow_policy() == &"stabilise", "legacy cure policy migrates")
	_check(state.get_npc_state(&"rafi") == &"rescued", "legacy rescued list migrates")
	_check(state.get_fed_trace_count() == 1, "legacy fed traces migrate")
	_check(state.route_missions_complete(), "legacy completed missions migrate")
	_check(not state.resolve_outcome(true).is_empty(), "migrated state resolves safely")


func _check_legacy_world_migration() -> void:
	var world_before := WorldState.get_state()
	var archive_before := ArchiveSystem.get_recovered_ids()
	var narrative_before := CampaignSystem.get_narrative_state()
	WorldState.clear()
	ArchiveSystem.restore([])
	CampaignSystem.clear_narrative_state(false)
	WorldState.set_flag(CampaignSystem.IMOGEN_RESCUED_FLAG)
	WorldState.set_flag(CampaignSystem.RAFI_CONNECTED_FLAG)
	WorldState.set_flag(&"road_trace_west")
	WorldState.set_flag(&"road_trace_east")
	WorldState.set_flag(&"ending_complete")
	WorldState.set_flag(&"ending_id", "choir")
	ArchiveSystem.restore(["echo_last_signal", "echo_first_tone"])
	CampaignSystem.restore_narrative_state({}, 2)
	var migrated := CampaignSystem.get_narrative_state()
	_check(CampaignSystem.get_active_route_id() == &"witness_mesh", "version-two ending migrates to its matching route")
	_check(Array(migrated.get("rescued_npcs", [])).has("imogen"), "legacy Imogen rescue migrates")
	_check(Array(migrated.get("rescued_npcs", [])).has("rafi"), "legacy Rafi connection migrates")
	_check(Array(migrated.get("evidence_ids", [])).has("R01"), "legacy traces migrate to evidence")
	_check(Array(migrated.get("evidence_ids", [])).has("R04"), "legacy road verification migrates to evidence")
	_check(CampaignSystem.are_route_missions_complete(), "completed legacy ending migrates completed route jobs")
	WorldState.restore(world_before)
	ArchiveSystem.restore(archive_before)
	CampaignSystem.restore_narrative_state(narrative_before, SaveManager.SAVE_VERSION)


func _check_campaign_hooks() -> void:
	var before := CampaignSystem.get_narrative_state()
	var world_before := WorldState.get_state()
	CampaignSystem.clear_narrative_state(false)
	var gated_payload: Dictionary = CampaignSystem.call("_narrative_dialogue_for", CampaignSystem.NARRATIVE_ANCHOR_STORY_ID)
	_check(Array(gated_payload.get("choices", [])).is_empty(), "anchor commitment waits for Maggie's workshop tape")
	WorldState.set_flag(&"mara_contacted")
	var anchor_payload: Dictionary = CampaignSystem.call("_narrative_dialogue_for", CampaignSystem.NARRATIVE_ANCHOR_STORY_ID)
	var more_payload: Dictionary = CampaignSystem.call("_narrative_dialogue_for", CampaignSystem.NARRATIVE_ANCHOR_MORE_STORY_ID)
	var strategy_payload: Dictionary = CampaignSystem.call("_narrative_dialogue_for", CampaignSystem.NARRATIVE_STRATEGY_STORY_ID)
	_check(Array(anchor_payload.get("choices", [])).size() == 3, "anchor dialogue fits the existing three-key choice input")
	_check(Array(more_payload.get("choices", [])).size() == 3, "second anchor page keeps witness and copy keyboard reachable")
	_check(Array(strategy_payload.get("choices", [])).is_empty(), "strategy dialogue waits for an anchor")
	_check(CampaignSystem.commit_route_anchor(&"witness", false), "CampaignSystem accepts anchor hook")
	strategy_payload = CampaignSystem.call("_narrative_dialogue_for", CampaignSystem.NARRATIVE_STRATEGY_STORY_ID)
	_check(Array(strategy_payload.get("choices", [])).size() == 3, "strategy dialogue exposes all three routes")
	_check(CampaignSystem.commit_network_strategy(&"sever", false), "CampaignSystem accepts strategy hook")
	_check(CampaignSystem.get_active_route_id() == &"witness_sever", "CampaignSystem exposes active route")
	CampaignSystem.record_narrative_evidence(&"R14", false)
	CampaignSystem.set_hollow_policy(&"stabilise", false)
	CampaignSystem.rescue_narrative_npc(&"leena", false)
	CampaignSystem.record_trace_fed(&"campaign_hook_trace", true, false)
	for mission in CampaignSystem.get_route_mission_definitions():
		var mission_id := StringName(mission.get("id", &""))
		CampaignSystem.start_route_mission(mission_id, false)
		CampaignSystem.complete_route_mission(mission_id, false)
	var outcome := CampaignSystem.resolve_narrative_ending(true)
	_check(StringName(outcome.get("route_id", &"")) == &"witness_sever", "CampaignSystem resolves the data route")
	_check(CampaignSystem.has_gameplay_modifier(&"identity_core_stealth"), "CampaignSystem exposes modifiers to gameplay systems")
	var leena_payload := CampaignSystem.get_npc_dialogue_payload(&"leena", "service")
	_check("LEENA" in String(Array(leena_payload.get("lines", [""]))[0]), "NPC voice data reaches the dialogue payload")
	_check(SaveManager.SAVE_VERSION == 4, "save schema covers narrative and trace decisions")
	_check(SaveManager.save_game(""), "SaveManager writes narrative state")
	var save_file := FileAccess.open(SaveManager.SAVE_PATH, FileAccess.READ)
	_check(save_file != null, "narrative save file can be read")
	if save_file != null:
		var saved_data: Variant = JSON.parse_string(save_file.get_as_text())
		save_file.close()
		_check(typeof(saved_data) == TYPE_DICTIONARY, "narrative save is valid JSON")
		if typeof(saved_data) == TYPE_DICTIONARY:
			var narrative: Dictionary = saved_data.get("narrative", {})
			_check(narrative.get("route_anchor", "") == "witness", "save stores the route anchor")
			_check(narrative.get("network_strategy", "") == "sever", "save stores the network strategy")
			_check(Array(narrative.get("evidence_ids", [])).has("R14"), "save stores evidence confidence inputs")
	SaveManager.delete_save()
	WorldState.restore(world_before)
	CampaignSystem.restore_narrative_state(before, SaveManager.SAVE_VERSION)


func _check_legacy_repeater_conflicts() -> void:
	var narrative_before := CampaignSystem.get_narrative_state()
	var world_before := WorldState.get_state()

	CampaignSystem.clear_narrative_state(false)
	WorldState.clear()
	WorldState.set_flag(CampaignSystem.REPEATER_DECLINED_FLAG)
	_check(CampaignSystem.commit_route_anchor(&"radio", false),
		"legacy stripped-repeater fixture commits the radio anchor")
	_check(CampaignSystem.commit_network_strategy(&"restore", false),
		"legacy stripped-repeater fixture commits restore")
	var rebuild: Dictionary = CampaignSystem.call("_public_repeater_dialogue")
	_check(Array(rebuild.get("choices", [])).front() == "REBUILD THE PUBLIC CHANNEL",
		"a pre-route stripped repeater can be reconsidered for restore")
	CampaignSystem.call("_complete_story", &"long_acre_repeater", 0)
	_check(WorldState.has_flag(CampaignSystem.REPEATER_ONLINE_FLAG) \
		and not WorldState.has_flag(CampaignSystem.REPEATER_DECLINED_FLAG),
		"rebuilding clears the conflicting legacy decline")

	CampaignSystem.clear_narrative_state(false)
	WorldState.clear()
	WorldState.set_flag(CampaignSystem.REPEATER_ONLINE_FLAG)
	_check(CampaignSystem.commit_route_anchor(&"radio", false),
		"legacy live-repeater fixture commits the radio anchor")
	_check(CampaignSystem.commit_network_strategy(&"sever", false),
		"legacy live-repeater fixture commits sever")
	var isolate: Dictionary = CampaignSystem.call("_public_repeater_dialogue")
	_check(Array(isolate.get("choices", [])).front() == "REMOVE THE LAST FUSE",
		"a pre-route live repeater can be isolated for sever")
	CampaignSystem.call("_complete_story", &"long_acre_repeater", 0)
	_check(WorldState.has_flag(CampaignSystem.REPEATER_DECLINED_FLAG) \
		and not WorldState.has_flag(CampaignSystem.REPEATER_ONLINE_FLAG),
		"isolating clears the conflicting legacy live state")

	SaveManager.delete_save()
	WorldState.restore(world_before)
	CampaignSystem.restore_narrative_state(narrative_before, SaveManager.SAVE_VERSION)


func _completed_state(anchor: StringName, strategy: StringName):
	var state = RouteState.new()
	state.commit_anchor(anchor)
	state.commit_strategy(strategy)
	for mission in RouteRegistry.get_missions(state.get_route_id()):
		var mission_id := StringName(mission.get("id", &""))
		state.start_mission(mission_id)
		state.complete_mission(mission_id)
	return state


func _check(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _fail(message: String) -> void:
	_failures.append(message)
