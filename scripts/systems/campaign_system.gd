extends Node
## Grounded campaign director.
##
## Several scene paths, story ids, and save flags still use names from the
## first public build. They are deliberately stable so existing browser saves
## continue to load; none of those legacy names are shown to the player.

const NarrativeRouteRegistryScript = preload("res://scripts/narrative/narrative_route_registry.gd")
const NarrativeRouteStateScript = preload("res://scripts/narrative/narrative_route_state.gd")
const NarrativeNPCRegistryScript = preload("res://scripts/narrative/narrative_npc_registry.gd")
const NarrativeGameplayRulesScript = preload("res://scripts/narrative/narrative_gameplay_rules.gd")
const NPCServiceRulesScript = preload("res://scripts/narrative/npc_service_rules.gd")
const ROUTE_MISSION_CONTRACTS_PATH := "res://scripts/narrative/route_mission_contracts.gd"

const RUSTWAY_SCENE := "res://scenes/maps/test_map.tscn"
const ASHMERE_SCENE := "res://scenes/maps/ashmere_verge.tscn"
const BROADCAST_SCENE := "res://scenes/maps/broadcast_fields.tscn"
const CHOIR_SCENE := "res://scenes/maps/choir_core.tscn"
const CYAN := Color(0.38, 0.90, 0.94, 1.0)
const AMBER := Color(1.0, 0.72, 0.34, 1.0)
const RED := Color(0.92, 0.36, 0.30, 1.0)
const RAFI_CONNECTED_FLAG := &"helped_rafi"
const RAFI_DECLINED_FLAG := &"rafi_declined"
const RAFI_ROUTE_REJOINED_FLAG := &"rafi_route_rejoined"
const REPEATER_ONLINE_FLAG := &"public_repeater"
const REPEATER_DECLINED_FLAG := &"public_repeater_declined"
const IMOGEN_MET_FLAG := &"imogen_met"
const IMOGEN_ESCORT_FLAG := &"imogen_escort_started"
const IMOGEN_RESCUED_FLAG := &"imogen_rescued"
const CLINIC_POWER_FLAG := &"clinic_lift_powered"
const SCHOOL_POWER_FLAG := &"school_backfeed_powered"
const EAST_DEFENSE_STARTED_FLAG := &"east_relay_defense_started"
const EAST_DEFENSE_COMPLETE_FLAG := &"east_relay_defense_complete"
const NARRATIVE_ANCHOR_STORY_ID := &"narrative_anchor_commitment"
const NARRATIVE_ANCHOR_MORE_STORY_ID := &"narrative_anchor_more"
const NARRATIVE_STRATEGY_STORY_ID := &"narrative_strategy_commitment"
const MAGGIE_CUTTING_STORY_ID := &"maggie_cutting_recorder"
const RECOVERABLE_HOLLOW_STORY_ID := &"wrenfield_recoverable_hollow"
const ROAD_TRACE_IDS := [&"road_trace_west", &"road_trace_east", &"road_trace_south"]
const ALL_TRACE_IDS := [
	&"echo_last_signal", &"echo_sun_lid", &"echo_mara_repair",
	&"echo_clinic_triage", &"echo_bus_ledger", &"echo_names_wall",
	&"echo_relay_warning", &"echo_driver_call", &"echo_first_tone", &"echo_maggie_final",
]

var _active_story_id: StringName = &""
var _circuit_requirements: Dictionary = {}
var _narrative_state = NarrativeRouteStateScript.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.dialogue_finished.connect(_on_dialogue_finished)
	EventBus.level_loaded.connect(_emit_progress)
	ArchiveSystem.echo_recorded.connect(_on_echo_recorded)
	BaseUpgradeSystem.upgrade_built.connect(_on_upgrade_built)


# --- Narrative rewrite state -------------------------------------------------

func get_narrative_state() -> Dictionary:
	return _narrative_state.to_dict()


func restore_narrative_state(data: Dictionary, source_save_version: int = 0) -> void:
	_narrative_state.restore(data, source_save_version)
	if data.is_empty() and source_save_version < 3:
		_migrate_legacy_narrative()
	_emit_narrative_state(false, &"")


func clear_narrative_state(notify: bool = true) -> void:
	var previous_route: StringName = _narrative_state.get_route_id()
	_narrative_state.reset()
	if notify:
		_emit_narrative_state(false, previous_route)


func commit_route_anchor(anchor: StringName, persist: bool = true) -> bool:
	var previous_route: StringName = _narrative_state.get_route_id()
	if not _narrative_state.commit_anchor(anchor):
		return false
	_rejoin_rafi_for_radio_if_needed()
	_share_copy_workshop_trace_if_ready()
	_emit_narrative_state(persist, previous_route)
	return true


func _rejoin_rafi_for_radio_if_needed() -> bool:
	# The damaged school aerial stays a permanent choice. Choosing Rafi's work
	# lets Ellie ask him back over Maggie's short local pair without pretending
	# that the original switch was repaired, whichever decision happened first.
	if _narrative_state.route_anchor != &"radio" \
			or not WorldState.has_flag(RAFI_DECLINED_FLAG) \
			or WorldState.has_flag(RAFI_CONNECTED_FLAG):
		return false
	WorldState.set_flag(RAFI_CONNECTED_FLAG)
	WorldState.set_flag(RAFI_ROUTE_REJOINED_FLAG)
	if _narrative_state.set_npc_state(&"rafi", &"rescued"):
		EventBus.narrative_npc_state_changed.emit(&"rafi", &"rescued")
	EventBus.notice_posted.emit(
		"RAFI REJOINS ON MAGGIE'S LOCAL RELAY - the school aerial stays grounded, but the warning route has a human lead.")
	return true


func _share_copy_workshop_trace_if_ready() -> bool:
	if _narrative_state.route_anchor != &"copy" \
			or not ArchiveSystem.has_echo(&"echo_mara_repair"):
		return false
	var changed := false
	if not WorldState.has_flag(&"copy_workshop_trace_shared"):
		WorldState.set_flag(&"copy_workshop_trace_shared")
		changed = true
	if _narrative_state.record_trace_fed(&"echo_mara_repair", true):
		changed = true
	if changed and get_tree().get_first_node_in_group("main") != null:
		EventBus.notice_posted.emit(
			"WORKSHOP TRACE SHARED - the verified paper record stays filed while Continuity receives a copy.")
	return changed


func commit_network_strategy(strategy: StringName, persist: bool = true) -> bool:
	var previous_route: StringName = _narrative_state.get_route_id()
	if not _narrative_state.commit_strategy(strategy):
		return false
	_emit_narrative_state(persist, previous_route)
	return true


func get_active_route_id() -> StringName:
	return _narrative_state.get_route_id()


func get_active_route() -> Dictionary:
	return _narrative_state.get_route()


func get_route_anchors() -> Array[StringName]:
	return NarrativeRouteRegistryScript.ANCHORS.duplicate()


func get_network_strategies() -> Array[StringName]:
	return NarrativeRouteRegistryScript.STRATEGIES.duplicate()


func record_narrative_evidence(revelation_id: StringName, persist: bool = true) -> bool:
	if not _narrative_state.add_evidence(revelation_id):
		return false
	_emit_narrative_state(persist, get_active_route_id())
	return true


func get_evidence_confidence() -> int:
	return NPCServiceRulesScript.effective_evidence_confidence(
		_narrative_state.get_evidence_confidence())


func record_trace_fed(trace_id: StringName, fed: bool = true, persist: bool = true) -> bool:
	if not _narrative_state.record_trace_fed(trace_id, fed):
		return false
	_emit_narrative_state(persist, get_active_route_id())
	return true


func get_fed_trace_count() -> int:
	return _narrative_state.get_fed_trace_count()


func record_hollow_outcome(outcome: StringName, amount: int = 1, persist: bool = true) -> bool:
	if not _narrative_state.record_hollow_outcome(outcome, amount):
		return false
	_emit_narrative_state(persist, get_active_route_id())
	return true


func set_hollow_policy(policy: StringName, persist: bool = true) -> bool:
	if not _narrative_state.set_hollow_policy(policy):
		return false
	_emit_narrative_state(persist, get_active_route_id())
	return true


func get_hollow_policy() -> StringName:
	return _narrative_state.get_hollow_policy()


func set_narrative_npc_state(npc_id: StringName, state: StringName, persist: bool = true) -> bool:
	if not _narrative_state.set_npc_state(npc_id, state):
		return false
	EventBus.narrative_npc_state_changed.emit(npc_id, state)
	_emit_narrative_state(persist, get_active_route_id())
	return true


func rescue_narrative_npc(npc_id: StringName, persist: bool = true) -> bool:
	return set_narrative_npc_state(npc_id, &"rescued", persist)


func get_narrative_npc_state(npc_id: StringName) -> StringName:
	return _narrative_state.get_npc_state(npc_id)


func get_npc_definition(npc_id: StringName) -> Dictionary:
	return NarrativeNPCRegistryScript.get_definition(npc_id)


func get_all_npc_ids() -> Array[StringName]:
	return NarrativeNPCRegistryScript.all_ids()


func get_npc_dialogue_payload(npc_id: StringName, beat: String = "") -> Dictionary:
	var definition := NarrativeNPCRegistryScript.get_definition(npc_id)
	if definition.is_empty():
		return {}
	if beat.is_empty():
		beat = _narrative_npc_beat(npc_id)
	var lines := NarrativeNPCRegistryScript.get_dialogue(npc_id, beat)
	return _payload(
		NarrativeNPCRegistryScript.get_story_id(npc_id),
		String(definition.get("display_name", "UNKNOWN")),
		lines,
		[],
		_narrative_accent_for_npc(npc_id),
	)


func get_route_mission_definitions() -> Array[Dictionary]:
	return NarrativeRouteRegistryScript.get_missions(get_active_route_id())


func get_route_mission_progress() -> Array[Dictionary]:
	var progress: Array[Dictionary] = []
	for mission in get_route_mission_definitions():
		var entry := mission.duplicate(true)
		var mission_id := StringName(mission.get("id", &""))
		entry["state"] = String(_narrative_state.get_mission_state(mission_id))
		progress.append(entry)
	return progress


func get_route_mission_state(mission_id: StringName) -> StringName:
	return _narrative_state.get_mission_state(mission_id)


func get_route_mission_contract(mission_id: StringName) -> Dictionary:
	return _route_mission_contracts().get_contract(mission_id)


func get_route_mission_unmet(mission_id: StringName) -> Array[Dictionary]:
	return _route_mission_contracts().unmet_steps(mission_id)


func _route_mission_contracts() -> Variant:
	# This table calls back through the campaign's public state API. Loading it
	# on demand keeps that relationship one-way at script initialization while
	# ResourceLoader still serves the cached script after the first request.
	return load(ROUTE_MISSION_CONTRACTS_PATH)


func start_route_mission(mission_id: StringName, persist: bool = true) -> bool:
	if not _narrative_state.start_mission(mission_id):
		return false
	_emit_narrative_state(persist, get_active_route_id())
	return true


func complete_route_mission(mission_id: StringName, persist: bool = true) -> bool:
	var mission := NarrativeRouteRegistryScript.find_mission(get_active_route_id(), mission_id)
	if mission.is_empty():
		return false
	if not _narrative_state.complete_mission(mission_id):
		return false
	var world_state := StringName(mission.get("world_state", &""))
	var service_unlock := StringName(mission.get("service_unlock", &""))
	if world_state != &"":
		WorldState.set_flag(world_state)
	if service_unlock != &"":
		WorldState.set_flag(StringName("service_%s" % String(service_unlock)))
	_emit_narrative_state(persist, get_active_route_id())
	return true


func are_route_missions_complete() -> bool:
	return _narrative_state.route_missions_complete()


func get_active_gameplay_modifiers() -> Array[StringName]:
	return _narrative_state.get_gameplay_modifiers()


func get_active_world_states() -> Array[StringName]:
	return _narrative_state.get_world_states()


func has_gameplay_modifier(modifier_id: StringName) -> bool:
	return modifier_id in get_active_gameplay_modifiers()


func get_gameplay_value(rule_id: StringName, fallback: float = 1.0) -> float:
	var route_value := NarrativeGameplayRulesScript.value(
		get_active_gameplay_modifiers(), rule_id, fallback)
	return NPCServiceRulesScript.gameplay_value(rule_id, route_value)


func get_npc_service_ending_lines() -> Array[String]:
	return NPCServiceRulesScript.ending_lines(
		_narrative_state.get_evidence_confidence())


func resolve_narrative_ending(require_completed_missions: bool = true) -> Dictionary:
	return _narrative_state.resolve_outcome(require_completed_missions)


func finish_narrative_ending() -> bool:
	var payload := resolve_narrative_ending(true)
	if payload.is_empty():
		return false
	var service_lines := get_npc_service_ending_lines()
	if not service_lines.is_empty():
		payload["body"] = "%s %s" % [
			String(payload.get("body", "")).strip_edges(),
			" ".join(service_lines),
		]
		payload["service_consequences"] = service_lines
		var axis: Dictionary = payload.get("axis_summary", {})
		axis["effective_evidence_confidence"] = get_evidence_confidence()
		payload["axis_summary"] = axis
	var route_id := StringName(payload.get("route_id", &""))
	WorldState.set_flag(&"ending_complete")
	WorldState.set_flag(&"ending_id", String(route_id))
	_apply_route_world_states(payload)
	payload["accent"] = _narrative_ending_accent(_narrative_state.network_strategy)
	payload["stats"] = _narrative_ending_stats(payload)
	payload["aftermath"] = "The roads stay open after the incident. Return to Railhome, then revisit the settlements to see what this route changed."
	SaveManager.save_game("")
	GameManager.set_ending_active(true)
	AudioManager.play(&"finale", 2.0, 0.72 if _narrative_state.network_strategy == &"sever" else 1.0)
	EventBus.ending_requested.emit(payload)
	return true


func can_interact(story_id: StringName) -> bool:
	return story_id != &"" and not GameManager.dialogue_active and not GameManager.ending_active


func get_prompt(story_id: StringName, fallback: String) -> String:
	match story_id:
		&"north_signal": return "Play the north-road tape"
		&"ashmere_mara_radio": return "Check Maggie's workshop radio"
		&"imogen_clinic":
			if not WorldState.has_flag(IMOGEN_MET_FLAG): return "Answer the voice in the clinic"
			if not _clinic_junction_resolved(): return "Check on Imogen"
			if not WorldState.has_flag(IMOGEN_ESCORT_FLAG): return "Ask Imogen to move"
			return "Check on Imogen"
		&"clinic_power_junction":
			return "Inspect the committed clinic junction" if _clinic_junction_resolved() else "Repair and reroute the clinic junction"
		&"imogen_workshop_safe":
			if WorldState.has_flag(IMOGEN_RESCUED_FLAG): return "Read Imogen's clinic notes"
			if WorldState.has_flag(IMOGEN_ESCORT_FLAG): return "Bring Imogen into the workshop"
			return "Inspect Maggie's cellar"
		&"bellwether_school_radio":
			if WorldState.has_flag(RAFI_CONNECTED_FLAG): return "Check in with Rafi"
			if WorldState.has_flag(RAFI_DECLINED_FLAG): return "Inspect the local aerial" if WorldState.has_flag(SCHOOL_POWER_FLAG) else "Inspect the grounded aerial"
			return "Call Rafi at the water works"
		&"ashmere_gate": return "Unlock the Wrenfield road"
		&"broadcast_relay_west", &"broadcast_relay_east", &"broadcast_relay_south": return "Reset the line relay"
		&"road_trace_west", &"road_trace_east", &"road_trace_south": return "Review the verified road record" if WorldState.has_flag(story_id) else "Verify the road record"
		&"broadcast_defense_anchor":
			if WorldState.has_flag(EAST_DEFENSE_COMPLETE_FLAG): return "Check the stable clinic carrier"
			if WorldState.has_flag(EAST_DEFENSE_STARTED_FLAG): return "Hold the east clinic carrier"
			return "Begin the east-line hold"
		&"rafi_field_contact": return "Speak with Rafi"
		&"long_acre_repeater":
			if WorldState.has_flag(REPEATER_ONLINE_FLAG): return "Check the public warning line"
			if WorldState.has_flag(REPEATER_DECLINED_FLAG): return "Inspect the isolated repeater"
			return "Decide the public warning line"
		&"broadcast_core_gate": return "Open Tollard Exchange"
		&"choir_final_console": return "Open the incident controls"
		MAGGIE_CUTTING_STORY_ID:
			return "Replay Maggie's recorder" if WorldState.has_flag(&"maggie_final_proof_recovered") else "Check the body and recorder"
		RECOVERABLE_HOLLOW_STORY_ID:
			return "Review the grounded survivor" if get_hollow_policy() != &"undecided" else "Listen beneath the Hollow's carrier"
	var narrative_prompt := _narrative_prompt(story_id)
	if not narrative_prompt.is_empty():
		return narrative_prompt
	return fallback


func request_interaction(story_id: StringName) -> void:
	if not can_interact(story_id):
		return
	var payload: Dictionary = _dialogue_for(story_id)
	if payload.is_empty():
		EventBus.notice_posted.emit("The receiver finds static and nothing else.")
		return
	_active_story_id = story_id
	GameManager.set_dialogue_active(true)
	EventBus.dialogue_requested.emit(payload)


func _dialogue_for(story_id: StringName) -> Dictionary:
	match story_id:
		&"north_signal": return _north_signal_dialogue()
		&"ashmere_mara_radio": return _maggie_dialogue()
		&"imogen_clinic": return _imogen_dialogue()
		&"clinic_power_junction": return _clinic_power_dialogue()
		&"imogen_workshop_safe": return _imogen_safehouse_dialogue()
		&"bellwether_school_radio": return _school_radio_dialogue()
		&"ashmere_gate": return _ashmere_gate_dialogue()
		&"broadcast_relay_west", &"broadcast_relay_east", &"broadcast_relay_south": return _relay_dialogue(story_id)
		&"road_trace_west", &"road_trace_east", &"road_trace_south": return _road_trace_dialogue(story_id)
		&"broadcast_defense_anchor": return _defense_dialogue()
		&"rafi_field_contact": return _rafi_field_dialogue()
		&"long_acre_repeater": return _public_repeater_dialogue()
		&"broadcast_core_gate": return _broadcast_gate_dialogue()
		&"choir_final_console": return _final_console_dialogue()
		MAGGIE_CUTTING_STORY_ID: return _maggie_cutting_dialogue()
		RECOVERABLE_HOLLOW_STORY_ID: return _recoverable_hollow_dialogue()
	return _narrative_dialogue_for(story_id)


func _north_signal_dialogue() -> Dictionary:
	if not BaseUpgradeSystem.is_built(&"radio_desk"):
		return _payload(&"north_signal", "NORTH-ROAD TAPE", ["The carriage receiver cannot hold the frequency.", "Recover the mast recording and finish the radio desk."], [], CYAN)
	if not WorldState.has_flag(&"rested_after_radio"):
		return _payload(&"north_signal", "NORTH-ROAD TAPE", ["The desk is still cleaning eighteen years of hiss from the tape.", "Leave it running. Get some sleep."], [], CYAN)
	return _payload(&"north_signal", "MAGGIE'S TAPE", [
		"MAGGIE WARD, 14 OCTOBER — Ellie, do not answer a voice just because it sounds like mine.",
		"Take the tuning plate off. I scratched our old house number underneath: 14B.",
		"If it is there, come to my workshop on Ashmere Estate. If not, switch this off and walk away.",
	], ["FOLLOW THE A38 NORTH", "STAY AT CULLBROOK"], AMBER)


func _maggie_dialogue() -> Dictionary:
	if WorldState.has_flag(&"mara_contacted"):
		return _payload(&"ashmere_mara_radio", "WORKSHOP TAPE 6", ["SUN MARK. SERVICE LEDGER. WRENFIELD KEY.", "Rafi still monitors 88.4 after dusk."], [], AMBER)
	return _payload(&"ashmere_mara_radio", "WORKSHOP TAPE 6", [
		"MAGGIE — If 14B was under the plate, this is really my set and probably really you.",
		"The network learned our voices on Blank Night. It can use them again.",
		"Find your lunch tin and my service ledger. Together they open the Wrenfield road.",
		"The yellow lead is yours. Do not touch the red unless you fancy losing your eyebrows.",
	], [], AMBER)


func _imogen_dialogue() -> Dictionary:
	if WorldState.has_flag(IMOGEN_RESCUED_FLAG):
		return _payload(&"imogen_clinic", "IMOGEN BELL - WORKSHOP", [
			"IMOGEN - The oxygen bank is stable. I have copied every patient name twice.",
			"Maggie left for Tollard three nights ago. She said the exchange had started answering calls that nobody made.",
		], [], CYAN)
	if not WorldState.has_flag(IMOGEN_MET_FLAG):
		return _payload(&"imogen_clinic", "ASHMERE CLINIC - TREATMENT ROOM", [
			"IMOGEN - If you are real, say what is written over the door.",
			"ELLIE - No promises. No miracles. Record everything.",
			"IMOGEN - Good. Maggie wrote it. The fire doors trapped me when the backup junction failed.",
			"The same junction feeds the clinic lift and Bellwether's warning aerial. It needs one battery and two pieces of scrap before either route will hold.",
		], [], AMBER)
	if not _clinic_junction_resolved():
		return _payload(&"imogen_clinic", "IMOGEN BELL - BEHIND THE FIRE DOOR", [
			"The oxygen bank has minutes, not hours. The junction is outside by the ambulance bay.",
			"One battery. Two pieces of usable metal. Then choose where the current goes.",
		], [], RED)
	if WorldState.has_flag(IMOGEN_ESCORT_FLAG):
		return _payload(&"imogen_clinic", "IMOGEN BELL - MOVING", [
			"Keep me in sight. If the copied voices call from behind us, do not turn around.",
		], [], CYAN)
	var consequence := (
		"The lift is open and the oxygen trolley can move."
		if WorldState.has_flag(CLINIC_POWER_FLAG)
		else "The school aerial has current. I will carry what medicine I can."
	)
	return _payload(&"imogen_clinic", "IMOGEN BELL - FIRE DOOR OPEN", [
		consequence,
		"Maggie's workshop has a hand lock and a dry cellar. Get me there and I can tell you why she went back to Tollard.",
	], ["COME WITH ME", "WAIT HERE"], CYAN)


func _clinic_power_dialogue() -> Dictionary:
	if _clinic_junction_resolved():
		var route := "CLINIC LIFT" if WorldState.has_flag(CLINIC_POWER_FLAG) else "SCHOOL AERIAL"
		return _payload(&"clinic_power_junction", "AMBULANCE-BAY JUNCTION", [
			"The patched bus bars hold. Current is committed to the %s." % route,
			"The junction cannot be moved again without cutting both lines.",
		], [], CYAN)
	if not WorldState.has_flag(IMOGEN_MET_FLAG):
		return _payload(&"clinic_power_junction", "AMBULANCE-BAY JUNCTION", [
			"Two hand-labelled outputs disappear through the clinic wall: LIFT and SCHOOL AERIAL.",
			"Someone is tapping a steady three-beat pattern from inside.",
		], [], AMBER)
	if not _has_parts(1, 2):
		return _payload(&"clinic_power_junction", "AMBULANCE-BAY JUNCTION", [
			"The battery cradle is empty and both bus bars are split.",
			"Required: 1 battery and 2 scrap. Search the marked ambulance bay and maintenance shed.",
		], [], RED)
	if WorldState.has_flag(RAFI_DECLINED_FLAG):
		return _payload(&"clinic_power_junction", "ONE SOURCE / ONE INTACT ROUTE", [
			"The school aerial's ceramic switch is broken and grounded. That feed cannot safely take current.",
			"The repaired bus bars can still power the clinic lift and move Imogen's oxygen trolley.",
		], ["POWER CLINIC LIFT"], AMBER)
	return _payload(&"clinic_power_junction", "ONE SOURCE / TWO LIVE ROUTES", [
		"The repair will hold, but the old changeover can feed only one route.",
		"LIFT moves Imogen and the oxygen trolley. SCHOOL AERIAL gives Rafi a clean regional carrier after dusk.",
		"This is a physical cutover. It cannot be undone from Tollard.",
	], ["POWER CLINIC LIFT", "POWER SCHOOL AERIAL"], AMBER)


func _imogen_safehouse_dialogue() -> Dictionary:
	if WorldState.has_flag(IMOGEN_RESCUED_FLAG):
		return _payload(&"imogen_workshop_safe", "MAGGIE'S WORKSHOP - CELLAR", [
			"Imogen's paper clinic list is drying beside the stove. Her handwriting does not change when the radio speaks.",
		], [], CYAN)
	if not WorldState.has_flag(IMOGEN_ESCORT_FLAG):
		return _payload(&"imogen_workshop_safe", "MAGGIE'S WORKSHOP - HAND LOCK", [
			"The cellar is dry and defensible. Someone from the clinic could shelter here.",
		], [], AMBER)
	return _payload(&"imogen_workshop_safe", "MAGGIE'S WORKSHOP - CELLAR", [
		"IMOGEN - Maggie found proof that the Open Call began before the storm, not during it.",
		"She went to Tollard for the original dispatch roll. If the exchange still has it, somebody changed the official time.",
		"I can hold this place and verify the clinic names. You keep moving.",
	], ["TAKE TWO SEALED FIELD KITS", "LEAVE THE KITS FOR ASHMERE"], CYAN)


func _road_trace_dialogue(story_id: StringName) -> Dictionary:
	if WorldState.has_flag(story_id):
		return _payload(story_id, "VERIFIED ROAD RECORD", ["This record is marked, photographed, and cross-checked."], [], CYAN)
	var title := "WRENFIELD ROAD RECORD"
	var lines: Array[String] = []
	match story_id:
		&"road_trace_west":
			title = "WEST CABLE HOUSE - PAPER DRUM"
			lines = ["The paper route drum says NORTH at 02:11.", "The electronic log changed it to EAST four minutes later, signed by an operator who died in 2006."]
		&"road_trace_east":
			title = "EAST LAY-BY - BUS TACHOGRAPH"
			lines = ["The evacuation bus stopped here facing south.", "Its radio transcript claims it crossed the north bridge nine minutes later. The bridge had already fallen."]
		&"road_trace_south":
			title = "SOUTH GENERATOR - ENGINEER'S CHALK"
			lines = ["Three manual arrows survive under the paint: WEST / CLINIC / SAFE.", "Tollard painted over them after Blank Night, then broadcast a route through the flooded cutting."]
	return _payload(story_id, title, lines + ["Mark this as a verified contradiction before restoring road control."], ["CATALOGUE CONTRADICTION", "LEAVE IT UNMARKED"], AMBER)


func _defense_dialogue() -> Dictionary:
	if WorldState.has_flag(EAST_DEFENSE_COMPLETE_FLAG):
		return _payload(&"broadcast_defense_anchor", "EAST CLINIC CARRIER", ["The manual carrier is stable. Imogen's paper list has a clean route out."], [], CYAN)
	if WorldState.has_flag(EAST_DEFENSE_STARTED_FLAG):
		return _payload(&"broadcast_defense_anchor", "EAST CLINIC CARRIER - LIVE", ["The manual hold is in progress. Break the incoming targeting carriers before the line drops."], [], RED)
	if not WorldState.has_flag(&"relay_west_restored"):
		return _payload(&"broadcast_defense_anchor", "EAST CLINIC CARRIER", ["Road control must be verified first. Otherwise the clinic carrier inherits the false route table."], [], RED)
	var support := (
		"Rafi will cover the west approach."
		if WorldState.has_flag(&"rafi_field_defense")
		else "You will have to hold all three approaches alone."
	)
	return _payload(&"broadcast_defense_anchor", "EAST CLINIC CARRIER - MANUAL HOLD", [
		"The automatic defence is part of Tollard's copied-voice network. Bypassing it wakes every carrier nearby.",
		support,
	], ["BEGIN THE MANUAL HOLD", "CHECK THE APPROACHES"], RED)


func _rafi_field_dialogue() -> Dictionary:
	if not WorldState.has_flag(RAFI_CONNECTED_FLAG):
		return _payload(&"rafi_field_contact", "EMPTY REPEATER SHELTER", ["A still-warm mug sits beside 88.4. Nobody answers."], [], Color(0.68, 0.76, 0.76, 1.0))
	if WorldState.has_flag(&"rafi_field_defense"):
		return _payload(&"rafi_field_contact", "RAFI SAYEED - WEST APPROACH", ["I will keep their eyes off the clinic carrier. Two surges, if we are lucky. Move when I whistle."], [], CYAN)
	if WorldState.has_flag(&"rafi_field_repeater"):
		return _payload(&"rafi_field_contact", "RAFI SAYEED - REPEATER SHELTER", ["The public line stays human while I am here. No borrowed names, no clever voices."], [], CYAN)
	return _payload(&"rafi_field_contact", "RAFI SAYEED - IN PERSON", [
		"RAFI - Good. You look like the woman who argued with me, not the voice that apologised afterwards.",
		"I found Maggie's boot prints heading for Tollard. Only one set came back, and those stopped at the flooded cutting.",
		"I can help you hold the east clinic carrier, or stay here and keep the public repeater clean. Not both.",
	], ["COVER THE EAST LINE", "GUARD THE PUBLIC REPEATER"], CYAN)


func _school_radio_dialogue() -> Dictionary:
	if WorldState.has_flag(RAFI_ROUTE_REJOINED_FLAG):
		return _payload(&"bellwether_school_radio", "MAGGIE'S LOCAL RELAY - RAFI SAYEED", [
			"The school aerial remains grounded. Maggie's short local pair reaches Rafi without putting 88.4 back on the damaged switch.",
			"RAFI - I heard your work-card call. I will lead the warning route, but the broken aerial stays broken.",
		], [], CYAN)
	if WorldState.has_flag(RAFI_CONNECTED_FLAG):
		return _payload(&"bellwether_school_radio", "88.4 — RAFI SAYEED", ["Still here. The pump is behaving and nobody has poisoned the tea.", "Get Wrenfield talking and I can send a proper storm warning."], [], CYAN)
	if WorldState.has_flag(RAFI_DECLINED_FLAG):
		if WorldState.has_flag(SCHOOL_POWER_FLAG):
			return _payload(&"bellwether_school_radio", "SCHOOL AERIAL - LOCAL BACKFEED", [
				"You kept the repaired aerial off 88.4. Its local carrier remains available for Imogen's verified clinic read-back.",
				"Rafi and the quarry camp cannot answer through this set.",
			], [], Color(0.68, 0.76, 0.76, 1.0))
		return _payload(&"bellwether_school_radio", "SCHOOL AERIAL — GROUNDED", [
			"The ceramic switch broke when you grounded the aerial.",
			"88.4 is still faintly audible, but this set cannot answer it.",
		], [], Color(0.68, 0.76, 0.76, 1.0))
	var final_line := (
		"The repaired backfeed is live. You can connect 88.4 or keep it as a local verified channel."
		if WorldState.has_flag(SCHOOL_POWER_FLAG)
		else "The cracked ceramic switch will survive one change, not two."
	)
	var choices: Array[String] = (
		["CONNECT RAFI TO THE BACKFEED", "KEEP THE AERIAL LOCAL"]
		if WorldState.has_flag(SCHOOL_POWER_FLAG)
		else ["ROUTE 88.4 TO RAFI", "GROUND THE AERIAL"]
	)
	return _payload(&"bellwether_school_radio", "88.4 — WATER WORKS", [
		"RAFI — I have nineteen people, one good pump, and no weather report.",
		"Maggie Ward repaired this set six months ago. She said an Ellie might come after her.",
		"Patch me through the school aerial and I can warn the quarry camp before the ash turns.",
		final_line,
	], choices, CYAN)


func _ashmere_gate_dialogue() -> Dictionary:
	var missing: Array[String] = []
	if not WorldState.has_flag(&"mara_contacted"): missing.append("play Maggie's workshop tape")
	if not WorldState.has_flag(IMOGEN_RESCUED_FLAG): missing.append("get Imogen from the clinic to the workshop")
	if not ArchiveSystem.has_echo(&"echo_sun_lid"): missing.append("find the lunch tin")
	if not ArchiveSystem.has_echo(&"echo_mara_repair"): missing.append("recover Maggie's service ledger")
	if _narrative_state.route_anchor == &"": missing.append("choose whose work leads")
	if _narrative_state.network_strategy == &"": missing.append("decide what the relays become")
	if not _route_mission_complete(0): missing.append("finish the Ashmere route job")
	if not missing.is_empty():
		return _payload(&"ashmere_gate", "WRENFIELD MAINTENANCE ROAD", ["The padlock has two improvised tumblers.", "Maggie's note says to %s." % ", then ".join(missing)], [], CYAN)
	return _payload(&"ashmere_gate", "WRENFIELD MAINTENANCE ROAD", ["The sun gives four digits. Maggie's job number supplies the rest.", "Three line relays beyond the gate still feed Tollard Exchange."], ["OPEN THE ROAD", "GO BACK"], AMBER)


func _maggie_cutting_dialogue() -> Dictionary:
	if not ArchiveSystem.has_echo(&"echo_maggie_final"):
		return _payload(MAGGIE_CUTTING_STORY_ID, "FLOODED CUTTING / CHAINAGE 14", [
			"A county coat lies half under the washed ballast. The name strip reads M. WARD.",
			"Her recorder is caught beneath one hand. Its capstan moves, but the tape will not play until the Trace Anchor beside it is filed.",
		], [], Color(0.70, 0.78, 0.77, 1.0))
	if WorldState.has_flag(&"maggie_final_proof_recovered"):
		var handling := "kept off the carrier" if WorldState.has_flag(&"maggie_tape_private") else "copied to Railhome's paper record"
		return _payload(MAGGIE_CUTTING_STORY_ID, "MAGGIE WARD / FINAL RECORDER", [
			"The body is Maggie's. The dates on the recorder, the watch and the exchange key agree.",
			"Her last tape is %s. Continuity cannot turn that choice into consent." % handling,
		], [], CYAN)
	return _payload(MAGGIE_CUTTING_STORY_ID, "MAGGIE WARD / FINAL RECORDER", [
		"MAGGIE - Ellie, it is making people out of gaps. It learned my voice because I kept answering.",
		"MAGGIE - The shutdown phrase is real. The voice asking me not to use it is not me. Do not let grief cast a vote.",
		"The body, service watch and uncut tape establish the order: Maggie reached Tollard, recorded the manual phrase, and died here on the return road.",
	], ["KEEP THE TAPE OFF THE NETWORK", "COPY IT TO RAILHOME'S WITNESS FILE"], AMBER)


func _recoverable_hollow_dialogue() -> Dictionary:
	var policy := get_hollow_policy()
	if policy != &"undecided":
		var result: String = String({
			&"stabilise": "The carrier is quiet. A frightened living person is breathing beneath the coat.",
			&"kill": "The carrier is quiet because the person beneath it is dead.",
			&"weaponise": "The lure is working. Every nearby carrier can now hear this person's pain.",
		}.get(policy, "The first decision has already been made."))
		return _payload(RECOVERABLE_HOLLOW_STORY_ID, "HOLLOW / PERSON / POLICY", [result], [], RED)
	return _payload(RECOVERABLE_HOLLOW_STORY_ID, "A VOICE UNDER THE CARRIER", [
		"A Linesman tag says CALDER, N. The figure repeats a Tollard route number, then whispers 'please' between pulses.",
		"Imogen's notes say the command loop can be grounded. Nia's field marks say a clean strike is safer. The receiver can also bend the loop into a lure.",
		"This is the rule Ellie will use on later Hollows, not a private exception.",
	], ["STABILISE - USE AN ANALOGUE ISOLATOR", "KILL - END THE LOOP AND THE LIFE", "WEAPONISE - USE A SIGNAL DECOY"], RED)


func _relay_dialogue(story_id: StringName) -> Dictionary:
	var flag: StringName = _relay_flag(story_id)
	var copy: Dictionary = _relay_copy(story_id)
	var title := String(copy.get("title", "LINE RELAY"))
	if WorldState.has_flag(flag):
		return _payload(story_id, title, [String(copy.get("restored", "The breaker holds."))], [], CYAN)
	if story_id == &"broadcast_relay_west" and get_road_trace_count() < 2:
		return _payload(story_id, title, [
			"The route table contains three mutually exclusive evacuation roads.",
			"Verify at least two physical records before returning power (%d / 2)." % mini(get_road_trace_count(), 2),
		], [], RED)
	if story_id == &"broadcast_relay_east":
		return _payload(story_id, title, [
			"The automatic reset wakes Tollard's targeting carrier.",
			"Use the manual hold beside the east bunker and defend the clinic line instead.",
		], [], RED)
	if story_id == &"broadcast_relay_south":
		return _payload(story_id, title, [
			"Three field switches disagree: FEED, GROUND, and CARRIER.",
			"Follow the south cable and align all three by hand (%d / 3)." % get_circuit_alignment(&"south_line"),
		], [], AMBER)
	return _payload(story_id, title, [String(copy.get("detail", "The cabinet is live.")), "Resetting it will wake another part of Tollard's network."], ["RESET THE RELAY", "LEAVE IT OFF"], CYAN)


func _relay_copy(story_id: StringName) -> Dictionary:
	match story_id:
		&"broadcast_relay_west": return {
			"title": "WEST LINE — ROAD CONTROL",
			"detail": "Fault card: CONTRADICTORY ROUTES, 02:11. Circled three times in red pen.",
			"restored": "Road-control packets are moving again, slowly and in order.",
		}
		&"broadcast_relay_east": return {
			"title": "EAST LINE — CLINIC LINK",
			"detail": "A paper patient list is folded behind the main fuse. The database is blank.",
			"restored": _clinic_line_result(),
		}
		&"broadcast_relay_south": return {
			"title": "SOUTH LINE — PUBLIC WARNING",
			"detail": "The speaker repeats half a postcode in Maggie's voice, then restarts.",
			"restored": "Weather data passes without a borrowed voice.",
		}
	return {}


func _public_repeater_dialogue() -> Dictionary:
	var strategy: StringName = _narrative_state.network_strategy
	if WorldState.has_flag(REPEATER_ONLINE_FLAG) and strategy == &"sever":
		return _payload(&"long_acre_repeater", "PUBLIC REPEATER 3 — LIVE CONFLICT", [
			"The public carrier was wired before the network method was chosen.",
			"A severed route cannot leave this cabinet speaking behind you.",
		], ["REMOVE THE LAST FUSE", "LEAVE IT FOR NOW"], RED)
	if WorldState.has_flag(REPEATER_DECLINED_FLAG) and strategy == &"restore":
		return _payload(&"long_acre_repeater", "PUBLIC REPEATER 3 — STRIPPED", [
			"You removed the carrier before the network method was chosen.",
			"The restore route now needs that decision made again, with the route card beside it.",
		], ["REBUILD THE PUBLIC CHANNEL", "LEAVE IT FOR NOW"], AMBER)
	if WorldState.has_flag(REPEATER_ONLINE_FLAG):
		var source := (
			"Rafi's storm report follows a plain carrier."
			if WorldState.has_flag(RAFI_CONNECTED_FLAG)
			else "A plain regional weather bulletin follows the carrier. Nobody answers on 88.4."
		)
		return _payload(&"long_acre_repeater", "PUBLIC REPEATER 3", [source, "No names. No copied voices. Just wind, direction, and time."], [], CYAN)
	if WorldState.has_flag(REPEATER_DECLINED_FLAG):
		return _payload(&"long_acre_repeater", "PUBLIC REPEATER 3 — ISOLATED", [
			"You removed the cracked fuse carrier rather than feed the line.",
			"The old public channel cannot be restored from this cabinet.",
		], [], Color(0.68, 0.76, 0.76, 1.0))
	var choices: Array[String] = ["WIRE THE PUBLIC CHANNEL", "REMOVE THE LAST FUSE"]
	if strategy == &"restore":
		choices = ["WIRE THE PUBLIC CHANNEL", "LEAVE IT FOR NOW"]
	elif strategy == &"sever":
		choices = ["REMOVE THE LAST FUSE", "LEAVE IT FOR NOW"]
	return _payload(&"long_acre_repeater", "PUBLIC REPEATER 3", [
		"The analogue repeater bypasses Tollard's identity system.",
		"Maggie left the old wiring in place. It needs joining by hand.",
		"The cracked fuse carrier will survive one final connection.",
	], choices, AMBER)


func _broadcast_gate_dialogue() -> Dictionary:
	if get_active_route_id() == &"":
		return _payload(&"broadcast_core_gate", "TOLLARD SERVICE GATE", [
			"The route card is blank. Maggie's Ashmere workbench still has four named plans waiting for a commitment.",
		], [], RED)
	var restored := get_restored_relay_count()
	if restored < 3:
		return _payload(&"broadcast_core_gate", "TOLLARD SERVICE GATE", ["%d of 3 line relays are available." % restored, "All three circuits must agree before the bolts move."], [], RED)
	if not WorldState.is_defeated(&"RelayHusk"):
		return _payload(&"broadcast_core_gate", "THE LINESMAN", ["An insulated maintenance suit is still walking the gate circuit.", "Scan to interrupt its shield. Move when the blue field drops."], [], RED)
	if not ArchiveSystem.has_echo(&"echo_maggie_final") or not WorldState.has_flag(&"maggie_final_proof_recovered"):
		return _payload(&"broadcast_core_gate", "TOLLARD SERVICE GATE", [
			"Rafi's boot marks end at the flooded cutting. Maggie's last recorder must be checked before Tollard can turn another copied voice into evidence.",
		], [], RED)
	if get_hollow_policy() == &"undecided":
		return _payload(&"broadcast_core_gate", "TOLLARD SERVICE GATE", [
			"A living voice is still caught in the grounded Hollow by the cutting. Decide what rule follows you into Tollard.",
		], [], RED)
	if not _route_mission_complete(1):
		return _payload(&"broadcast_core_gate", "TOLLARD SERVICE GATE", [
			"The Wrenfield route job is still unsigned. The operation inside depends on work done outside, where it can be checked.",
		], [], RED)
	return _payload(&"broadcast_core_gate", "TOLLARD SERVICE GATE", ["The Linesman's key turns. The bolts answer one at a time.", "Inside is the exchange that issued the Open Call on Blank Night."], ["ENTER TOLLARD EXCHANGE", "CHECK YOUR KIT"], AMBER)


func _final_console_dialogue() -> Dictionary:
	if not WorldState.is_defeated(&"ChoirWarden"):
		return _payload(&"choir_final_console", "INCIDENT CONTROL", ["The Custodian has locked out manual control.", "Break its field with the trace set, then reach the switches."], [], RED)
	var route_id := get_active_route_id()
	if route_id != &"":
		var route := get_active_route()
		var title := "%s - %s" % [String(route.get("title", "TOLLARD")), String(route.get("operation", "FINAL OPERATION"))]
		var lines: Array[String] = [
			"Access: %s." % String(route.get("access", "incident controls")),
			String(route.get("finale", "The route is ready.")),
		]
		if not are_route_missions_complete():
			lines.append("The two route jobs are not complete. Tollard can wait; the missing work cannot be invented here.")
			return _payload(&"choir_final_console", title, lines, [], RED)
		if not WorldState.has_flag(&"route_finale_started"):
			lines.append("The three cabinets below Incident Control must be thrown by hand. Their pattern is fixed by the route you chose outside.")
			return _payload(
				&"choir_final_console",
				title,
				lines,
				[String(route.get("operation", "BEGIN THE OPERATION")), "STEP BACK"],
				AMBER,
			)
		if not is_circuit_complete(&"route_finale"):
			lines.append("Manual cabinets aligned: %d / 3. Leave this desk and finish the physical operation." % get_circuit_alignment(&"route_finale"))
			return _payload(&"choir_final_console", title, lines, [], RED)
		lines.append("All three contacts agree. The last change cannot be delegated to the copied voice.")
		return _payload(&"choir_final_console", title, lines, ["COMMIT THIS ROUTE", "READ IT AGAIN"], AMBER)
	return _payload(&"choir_final_console", "INCIDENT 44 - CONTINUITY MODE", [
		"The dispatch roll proves Continuity Mode spoke in Maggie's voice at 02:03 - fourteen minutes before county control claimed it was activated.",
		"The system had been quietly completing missing identities for months. On Blank Night, damaged records turned that trial into 34,112 invented people and personalised routes.",
		"Maggie reached this room three nights ago. Her manual shutdown is genuine. The reply begging her to stop is not.",
		"No operation can be invented at the last switch. Return to Maggie's four work cards in Ashmere and commit a route that can be tested outside this room.",
	], [], RED)


func _on_dialogue_finished(story_id: StringName, choice_index: int) -> void:
	if story_id != _active_story_id: return
	_active_story_id = &""
	GameManager.set_dialogue_active(false)
	_complete_story(story_id, choice_index)


func _complete_story(story_id: StringName, choice_index: int) -> void:
	if _complete_narrative_story(story_id, choice_index):
		_emit_progress()
		return
	match story_id:
		&"north_signal":
			if choice_index == 0 and BaseUpgradeSystem.is_built(&"radio_desk") and WorldState.has_flag(&"rested_after_radio"):
				WorldState.set_flag(&"ashmere_opened")
				SaveManager.save_game("")
				GameManager.travel_to(ASHMERE_SCENE, &"from_rustway")
		&"ashmere_mara_radio":
			if not WorldState.has_flag(&"mara_contacted"):
				WorldState.set_flag(&"mara_contacted")
				WorldState.set_flag(&"memory_burst_unlocked")
				AudioManager.play(&"memory_burst")
				EventBus.notice_posted.emit(
					"Maggie's red-lead modification is ready. Receiver discharge: [R].")
				SaveManager.save_game("")
		&"imogen_clinic":
			if not WorldState.has_flag(IMOGEN_MET_FLAG):
				WorldState.set_flag(IMOGEN_MET_FLAG)
				EventBus.notice_posted.emit("FIELD TASK ADDED - repair the ambulance-bay junction.")
				SaveManager.save_game("")
			elif _clinic_junction_resolved() and choice_index == 0 and not WorldState.has_flag(IMOGEN_ESCORT_FLAG):
				WorldState.set_flag(IMOGEN_ESCORT_FLAG)
				EventBus.notice_posted.emit("ESCORT STARTED - keep Imogen close on the clinic-to-workshop route.")
				SaveManager.save_game("")
		&"clinic_power_junction":
			var school_route_available := choice_index == 0 or not WorldState.has_flag(RAFI_DECLINED_FLAG)
			if (
				choice_index in [0, 1]
				and school_route_available
				and WorldState.has_flag(IMOGEN_MET_FLAG)
				and not _clinic_junction_resolved()
				and _has_parts(1, 2)
			):
				InventorySystem.remove_item(&"battery", 1)
				InventorySystem.remove_item(&"scrap", 2)
				if choice_index == 0:
					WorldState.set_flag(CLINIC_POWER_FLAG)
					EventBus.notice_posted.emit("Clinic lift powered. Imogen can move the oxygen trolley.")
				else:
					WorldState.set_flag(SCHOOL_POWER_FLAG)
					EventBus.notice_posted.emit("School aerial powered. 88.4 gains a clean carrier after dusk.")
				AudioManager.play(&"relay_restore")
				SaveManager.save_game("")
		&"imogen_workshop_safe":
			if choice_index in [0, 1] and WorldState.has_flag(IMOGEN_ESCORT_FLAG) and not WorldState.has_flag(IMOGEN_RESCUED_FLAG):
				var kit_granted: bool = true
				if choice_index == 0:
					var kits: Dictionary = {&"medical_kit": 2}
					kit_granted = InventorySystem.can_apply_transaction({}, kits) \
						and InventorySystem.add_items_atomic(kits)
				if not kit_granted:
					EventBus.notice_posted.emit(
						"MAKE ROOM - the field kit needs two free medical-kit spaces before Imogen can hand over the sealed stock.")
				else:
					WorldState.set_flag(IMOGEN_RESCUED_FLAG)
					rescue_narrative_npc(&"imogen", false)
					if choice_index == 0:
						WorldState.set_flag(&"imogen_kit_taken")
						EventBus.notice_posted.emit("Imogen rescued. You take two sealed field kits.")
					else:
						WorldState.set_flag(&"imogen_kit_left")
						EventBus.notice_posted.emit("Imogen rescued. Ashmere keeps the sealed field kits.")
					SaveManager.save_game("")
		&"bellwether_school_radio":
			var rafi_resolved := (
				WorldState.has_flag(RAFI_CONNECTED_FLAG)
				or WorldState.has_flag(RAFI_DECLINED_FLAG)
			)
			if choice_index == 0 and not rafi_resolved:
				WorldState.set_flag(RAFI_CONNECTED_FLAG)
				rescue_narrative_npc(&"rafi", false)
				EventBus.notice_posted.emit("Rafi reaches the quarry camp. Storm warning relayed.")
				SaveManager.save_game("")
			elif choice_index == 1 and not rafi_resolved:
				WorldState.set_flag(RAFI_DECLINED_FLAG)
				_rejoin_rafi_for_radio_if_needed()
				if WorldState.has_flag(SCHOOL_POWER_FLAG):
					EventBus.notice_posted.emit("The repaired aerial stays local. Imogen keeps a verified clinic channel; 88.4 remains unconnected.")
				else:
					EventBus.notice_posted.emit("You ground the school aerial. The cracked switch breaks in your hand.")
				SaveManager.save_game("")
		&"ashmere_gate":
			if choice_index == 0 and _ashmere_ready():
				WorldState.set_flag(&"broadcast_opened")
				SaveManager.save_game("")
				GameManager.travel_to(BROADCAST_SCENE, &"from_ashmere")
		&"road_trace_west", &"road_trace_east", &"road_trace_south":
			if choice_index == 0 and not WorldState.has_flag(story_id):
				WorldState.set_flag(story_id)
				EventBus.notice_posted.emit("Verified road contradictions: %d / 3." % get_road_trace_count())
				if get_road_trace_count() >= 2 and not WorldState.has_flag(&"wrenfield_route_verified"):
					WorldState.set_flag(&"wrenfield_route_verified")
					record_narrative_evidence(&"R04", false)
					var accepted := InventorySystem.add_item(&"scrap", 2)
					EventBus.notice_posted.emit(
						"ROUTE VERIFIED - west road control can now be restored. %s"
						% _reward_result(&"scrap", 2, accepted))
				SaveManager.save_game("")
		&"broadcast_relay_west":
			if choice_index == 0 and get_road_trace_count() >= 2 and not WorldState.has_flag(&"relay_west_restored"):
				_restore_relay(&"relay_west_restored", "West road-control relay verified and restored.")
		&"broadcast_relay_east":
			if choice_index == 0 and not WorldState.has_flag(EAST_DEFENSE_STARTED_FLAG):
				EventBus.notice_posted.emit("Use the manual carrier beside the east bunker to hold this line.")
		&"broadcast_relay_south":
			if choice_index == 0 and not is_circuit_complete(&"south_line"):
				EventBus.notice_posted.emit("Trace the south cable and align FEED / GROUND / CARRIER by hand.")
		&"broadcast_defense_anchor":
			if choice_index == 0 and WorldState.has_flag(&"relay_west_restored") and not WorldState.has_flag(EAST_DEFENSE_STARTED_FLAG):
				WorldState.set_flag(EAST_DEFENSE_STARTED_FLAG)
				SaveManager.save_game("")
		&"rafi_field_contact":
			if choice_index in [0, 1] and WorldState.has_flag(RAFI_CONNECTED_FLAG) and not _rafi_field_decided():
				var field_reward: Dictionary = {&"battery": 1, &"scrap": 1}
				if not InventorySystem.add_items_atomic(field_reward):
					EventBus.notice_posted.emit(
						"MAKE ROOM - Rafi's field pack needs space for one battery and one scrap before you choose his post.")
				else:
					if choice_index == 0:
						WorldState.set_flag(&"rafi_field_defense")
						EventBus.notice_posted.emit(
							"Rafi takes the west approach. The east-line hold will be shorter. +1 battery, +1 scrap")
					else:
						WorldState.set_flag(&"rafi_field_repeater")
						EventBus.notice_posted.emit(
							"Rafi stays with the public repeater and keeps its carrier human. +1 battery, +1 scrap")
					SaveManager.save_game("")
		&"long_acre_repeater":
			var strategy: StringName = _narrative_state.network_strategy
			var repeater_online := WorldState.has_flag(REPEATER_ONLINE_FLAG)
			var repeater_declined := WorldState.has_flag(REPEATER_DECLINED_FLAG)
			if repeater_online and strategy == &"sever" and choice_index == 0:
				WorldState.set_flag(REPEATER_ONLINE_FLAG, false)
				WorldState.set_flag(REPEATER_DECLINED_FLAG)
				EventBus.notice_posted.emit(
					"You remove the old carrier. The public line now matches the severed route.")
				SaveManager.save_game("")
			elif repeater_declined and strategy == &"restore" and choice_index == 0:
				WorldState.set_flag(REPEATER_DECLINED_FLAG, false)
				WorldState.set_flag(REPEATER_ONLINE_FLAG)
				EventBus.notice_posted.emit(
					"Public repeater rebuilt. The warning route has its analogue channel back.")
				SaveManager.save_game("")
			var repeater_resolved := (
				WorldState.has_flag(REPEATER_ONLINE_FLAG)
					or WorldState.has_flag(REPEATER_DECLINED_FLAG)
			)
			if not repeater_resolved:
				var wire_line: bool = choice_index == 0 and strategy != &"sever"
				var remove_fuse: bool = (
					(choice_index == 0 and strategy == &"sever")
					or (choice_index == 1 and strategy not in [&"restore", &"sever"])
				)
				if wire_line:
					WorldState.set_flag(REPEATER_ONLINE_FLAG)
					EventBus.notice_posted.emit("Public repeater online. Analogue weather channel only.")
					SaveManager.save_game("")
				elif remove_fuse:
					WorldState.set_flag(REPEATER_DECLINED_FLAG)
					EventBus.notice_posted.emit(
						"You remove the last intact fuse carrier. The public line stays isolated.")
					SaveManager.save_game("")
		&"broadcast_core_gate":
			if choice_index == 0 and _broadcast_ready():
				WorldState.set_flag(&"choir_opened")
				SaveManager.save_game("")
				GameManager.travel_to(CHOIR_SCENE, &"from_fields")
		MAGGIE_CUTTING_STORY_ID:
			if choice_index in [0, 1] and ArchiveSystem.has_echo(&"echo_maggie_final") \
					and not WorldState.has_flag(&"maggie_final_proof_recovered"):
				WorldState.set_flag(&"maggie_final_proof_recovered")
				WorldState.set_flag(&"maggie_tape_private" if choice_index == 0 else &"maggie_tape_shared")
				record_narrative_evidence(&"R10", false)
				if choice_index == 1:
					record_trace_fed(&"echo_maggie_final", true, false)
				EventBus.notice_posted.emit(
					"MAGGIE WARD IDENTIFIED - recorder, watch and body logged without treating the copied voice as a witness.")
				SaveManager.save_game("")
		RECOVERABLE_HOLLOW_STORY_ID:
			_resolve_recoverable_hollow(choice_index)
		&"choir_final_console":
			if not WorldState.is_defeated(&"ChoirWarden"): return
			if get_active_route_id() != &"":
				if choice_index == 0:
					if not WorldState.has_flag(&"route_finale_started"):
						WorldState.set_flag(&"route_finale_started")
						AudioManager.play(&"relay_restore", -1.0, 0.82)
						EventBus.notice_posted.emit("FINAL OPERATION STARTED - throw all three marked cabinets by hand.")
						SaveManager.save_game("")
					elif is_circuit_complete(&"route_finale"):
						finish_narrative_ending()
				return
			if choice_index == 0: _finish_ending(&"archive")
			elif choice_index == 1: _finish_ending(&"silence")
			elif choice_index == 2 and _secret_ending_unlocked(): _finish_ending(&"choir")
	_emit_progress()


func report_field_task(task_id: StringName) -> void:
	match task_id:
		&"east_relay_defense":
			if WorldState.has_flag(EAST_DEFENSE_COMPLETE_FLAG):
				return
			WorldState.set_flag(EAST_DEFENSE_COMPLETE_FLAG)
			var accepted := InventorySystem.add_item(&"battery", 1)
			_restore_relay(&"relay_east_restored",
				"East clinic carrier held. %s" % _reward_result(&"battery", 1, accepted))
		&"south_line":
			if WorldState.has_flag(&"circuit_south_line_complete"):
				return
			WorldState.set_flag(&"circuit_south_line_complete")
			var accepted := InventorySystem.add_item(&"scrap", 2)
			_restore_relay(&"relay_south_restored",
				"South warning line rerouted without the copied voice. %s"
				% _reward_result(&"scrap", 2, accepted))
		&"route_finale":
			if WorldState.has_flag(&"route_finale_ready"):
				return
			WorldState.set_flag(&"circuit_route_finale_complete")
			WorldState.set_flag(&"route_finale_ready")
			AudioManager.play(&"finale", -4.0, 0.74)
			EventBus.notice_posted.emit("FINAL OPERATION READY - return to Incident Control and make the last commitment.")
	SaveManager.save_game("")
	_emit_progress()


func _reward_result(item_id: StringName, requested: int, accepted: int) -> String:
	var data := ItemDatabase.get_item(item_id)
	var label := data.display_name.to_lower() if data != null else String(item_id).replace("_", " ")
	if accepted >= requested:
		return "+%d %s" % [accepted, label]
	if accepted > 0:
		return "+%d/%d %s; the field kit reached its limit" % [accepted, requested, label]
	return "No %s recovered; the field kit is already full" % label


func register_circuit_switch(circuit_id: StringName, switch_id: StringName, required_on: bool) -> void:
	if not _circuit_requirements.has(circuit_id):
		_circuit_requirements[circuit_id] = {}
	var requirements: Dictionary = _circuit_requirements[circuit_id]
	requirements[switch_id] = required_on
	_circuit_requirements[circuit_id] = requirements


func get_circuit_switch_state(circuit_id: StringName, switch_id: StringName, fallback: bool) -> bool:
	var key := _circuit_value_key(circuit_id, switch_id)
	if not WorldState.get_flags().has(key):
		return fallback
	return bool(WorldState.get_flag(key, fallback))


func set_circuit_switch(circuit_id: StringName, switch_id: StringName, value: bool) -> void:
	WorldState.set_flag(_circuit_value_key(circuit_id, switch_id), value)
	WorldState.set_flag(_circuit_touch_key(circuit_id, switch_id))
	_evaluate_circuit(circuit_id)
	SaveManager.save_game("")


func get_circuit_alignment(circuit_id: StringName) -> int:
	var requirements: Dictionary = _circuit_requirements.get(circuit_id, {})
	var aligned := 0
	for switch_id in requirements:
		if (
			WorldState.has_flag(_circuit_touch_key(circuit_id, switch_id))
			and get_circuit_switch_state(circuit_id, switch_id, false) == bool(requirements[switch_id])
		):
			aligned += 1
	return aligned


func is_circuit_complete(circuit_id: StringName) -> bool:
	return WorldState.has_flag(StringName("circuit_%s_complete" % circuit_id))


func _evaluate_circuit(circuit_id: StringName) -> void:
	var requirements: Dictionary = _circuit_requirements.get(circuit_id, {})
	if requirements.size() >= 3 and get_circuit_alignment(circuit_id) == requirements.size():
		report_field_task(circuit_id)


func _circuit_value_key(circuit_id: StringName, switch_id: StringName) -> StringName:
	return StringName("circuit_%s_%s_value" % [circuit_id, switch_id])


func _circuit_touch_key(circuit_id: StringName, switch_id: StringName) -> StringName:
	return StringName("circuit_%s_%s_touched" % [circuit_id, switch_id])


func _restore_relay(flag: StringName, notice: String) -> void:
	if WorldState.has_flag(flag):
		return
	WorldState.set_flag(flag)
	AudioManager.play(&"relay_restore")
	EventBus.notice_posted.emit("%s\nLine relays available: %d / 3." % [notice, get_restored_relay_count()])
	SaveManager.save_game("")


func _finish_ending(ending_id: StringName) -> void:
	WorldState.set_flag(&"ending_complete")
	WorldState.set_flag(&"ending_id", String(ending_id))
	var payload: Dictionary
	match ending_id:
		&"archive": payload = {
			"title": "VERIFIED RECORDS SENT",
			"subtitle": "The evidence travels with the danger attached.",
			"body": _archive_ending_body(),
			"accent": AMBER,
		}
		&"silence": payload = {
			"title": "EXCHANGE POWER CUT",
			"subtitle": "The region is quieter. Much of its evidence is gone.",
			"body": _silence_ending_body(),
			"accent": Color(0.72, 0.82, 0.86, 1.0),
		}
		&"choir": payload = {
			"title": "THE LONG REPAIR",
			"subtitle": "No central voice. Work that can be checked.",
			"body": "Using the public repeater, Rafi's line, Imogen's paper list, and every analogue trace, Ellie removes Tollard's voice generator and breaks the archive into local packets. Imogen and Rafi establish a chain of human witnesses; Ellie walks the disputed packets between them by hand. None of the records pretend to be people. Maggie's rule goes on the carriage wall: if you cannot verify it, say so.",
			"accent": CYAN,
		}
	payload["ending_id"] = ending_id
	payload["stats"] = _ending_stats()
	SaveManager.save_game("")
	GameManager.set_ending_active(true)
	AudioManager.play(&"finale", 2.0, 1.0 if ending_id != &"silence" else 0.72)
	EventBus.ending_requested.emit(payload)


func _archive_ending_body() -> String:
	var delivery := _archive_delivery_result()
	var ash_result := _imogen_ending_result()
	return (
		"Tollard sends its verified names and incident logs. %s "
		+ "%s "
		+ "Weeks later, families reach Cullbrook with copied pages in biscuit tins. "
		+ "Ellie keeps Carriage 317 lit and marks every uncertain record as uncertain."
	) % [delivery, ash_result]


func _archive_delivery_result() -> String:
	var rafi_connected := WorldState.has_flag(RAFI_CONNECTED_FLAG)
	var repeater_online := WorldState.has_flag(REPEATER_ONLINE_FLAG)
	if rafi_connected and repeater_online:
		return "Rafi copies the clinic list, then sends a plain storm warning over the public repeater before shutting Tollard's carrier out."
	if rafi_connected:
		return "Rafi copies the clinic list over 88.4, but the quarry camp has no public warning line."
	if repeater_online:
		return "The public line carries a regional storm warning, but nobody at the water works confirms the clinic list."
	return "The clinic list enters the county feed, but neither 88.4 nor the public warning line confirms receiving it."


func _imogen_ending_result() -> String:
	if not WorldState.has_flag(IMOGEN_RESCUED_FLAG):
		return "The Ashmere clinic never answers again, leaving its paper list unverified."
	var power_result := (
		"The powered lift lets Imogen move the oxygen bank into Maggie's cellar."
		if WorldState.has_flag(CLINIC_POWER_FLAG)
		else "The school backfeed carries Imogen's read-back of every clinic name after dusk."
	)
	var kit_result := (
		"She keeps the sealed field kits for the next people who reach Ashmere."
		if WorldState.has_flag(&"imogen_kit_left")
		else "The sealed kits travel with Ellie, leaving Imogen to rebuild the clinic stock from scraps."
	)
	return "%s %s" % [power_result, kit_result]


func _silence_ending_body() -> String:
	var local_result: String
	var rafi_connected := WorldState.has_flag(RAFI_CONNECTED_FLAG)
	var repeater_online := WorldState.has_flag(REPEATER_ONLINE_FLAG)
	if rafi_connected and repeater_online:
		local_result = "Rafi has copied the clinic list, and his last storm warning continues on the public repeater until its local battery fails."
	elif rafi_connected:
		local_result = "Rafi has copied the clinic list, but 88.4 goes quiet before he can warn the quarry camp."
	elif repeater_online:
		local_result = "The public repeater carries one last regional warning; the water works never answers."
	else:
		local_result = "The water works and quarry camp receive no final warning."
	return (
		"Ellie opens the battery breakers and Tollard stops mid-word. "
		+ "The Bleeds lose the carrier. %s %s "
		+ "At the carriage, Ellie copies the names she remembers. Maggie's last tape sits beside the cold receiver, finite and real."
	) % [_imogen_ending_result(), local_result]


func get_objective() -> Dictionary:
	var path := _current_level_path()
	if WorldState.has_flag(&"route_aftermath_active"):
		return _aftermath_objective(path)
	if path == GameManager.BASE_SCENE_PATH:
		if not BaseUpgradeSystem.is_built(&"scanner_coil"):
			if not _has_parts(1, 2):
				return _objective("ACT I / THE UNPLUGGED VOICE", "Find 1 battery and 2 scrap for the receiver.", "OUTSIDE / FOLLOW THE AMBER MARKS", _parts_progress(1, 2), "Outside")
			return _objective("ACT I / THE UNPLUGGED VOICE", "Build the Search Coil at the receiver bench.", "CARRIAGE 317 / RECEIVER BENCH", "PARTS READY", "ScannerCoilBench")
		if not ArchiveSystem.has_echo(&"echo_last_signal"):
			return _objective("ACT I / CULLBROOK SERVICES", "Recover Maggie's mast call.", "CULLBROOK / FALLEN MAST, EAST ROAD", "TRACE 0 / 1", "Outside")
		if not BaseUpgradeSystem.is_built(&"radio_desk"):
			if not _has_parts(1, 3):
				return _objective("ACT I / CULLBROOK SERVICES", "Find parts for the shortwave desk.", "CULLBROOK / SERVICE CRATES OUTSIDE", _parts_progress(1, 3), "Outside")
			return _objective("ACT I / CULLBROOK SERVICES", "Finish the shortwave desk.", "CARRIAGE 317 / RADIO DESK", "PARTS READY", "RadioDeskStation")
		if not WorldState.has_flag(&"rested_after_radio"):
			return _objective("ACT I / CULLBROOK SERVICES", "Leave the tape decoding and sleep.", "CARRIAGE 317 / BEDROLL", "TAPE CLEANING", "Bedroll")
		return _objective("ACT II / ASHMERE ESTATE", "Play Maggie's north-road tape.", "CULLBROOK / FALLEN MAST, EAST ROAD", "TAPE READY", "Outside")
	if path == RUSTWAY_SCENE or path.is_empty():
		if not BaseUpgradeSystem.is_built(&"scanner_coil"):
			if not _has_parts(1, 2):
				return _objective("ACT I / THE UNPLUGGED VOICE", "Find 1 battery and 2 scrap for the receiver.", "AMBER MARKS / EAST ROAD", _parts_progress(1, 2), "RoadsideCrate")
			return _objective("ACT I / THE UNPLUGGED VOICE", "Return home and build the Search Coil.", "CARRIAGE 317 / AMBER DOOR", "PARTS READY", "BaseDoor")
		if not ArchiveSystem.has_echo(&"echo_last_signal"):
			return _objective("ACT I / CULLBROOK SERVICES", "Sweep the fallen mast, then catalogue its trace.", "CULLBROOK / FALLEN MAST, EAST ROAD", "TRACE 0 / 1", "MemoryEcho")
		if not BaseUpgradeSystem.is_built(&"radio_desk"):
			if not _has_parts(1, 3):
				return _objective("ACT I / CULLBROOK SERVICES", "Search the service yard for radio parts.", "CULLBROOK / LOCKERS AND CRATES", _parts_progress(1, 3), "PumpLocker")
			return _objective("ACT I / CULLBROOK SERVICES", "Take Maggie's call back to the shortwave desk.", "CARRIAGE 317 / WEST OF SERVICE YARD", "PARTS READY", "BaseDoor")
		if not WorldState.has_flag(&"rested_after_radio"):
			return _objective("ACT I / CULLBROOK SERVICES", "Let the desk decode Maggie's call.", "CARRIAGE 317 / BEDROLL", "RETURN AND REST", "BaseDoor")
		return _objective("ACT II / ASHMERE ESTATE", "Play Maggie's north-road tape.", "CULLBROOK / FALLEN MAST, EAST ROAD", "TAPE READY", "north_signal")
	if path == ASHMERE_SCENE:
		if not WorldState.has_flag(&"mara_contacted"): return _objective("ACT II / ASHMERE ESTATE", "Play Maggie's workshop tape.", "ASHMERE / WORKSHOP, NORTH-EAST", "TAPE NOT PLAYED", "ashmere_mara_radio")
		if not WorldState.has_flag(IMOGEN_MET_FLAG): return _objective("ACT II / THE LIVING CLINIC", "Answer the person trapped inside the clinic.", "ASHMERE / CLINIC, SOUTH-EAST", "VOICE NOT VERIFIED", "imogen_clinic")
		if not _clinic_junction_resolved():
			if not _has_parts(1, 2): return _objective("ACT II / THE LIVING CLINIC", "Find parts for the ambulance-bay junction.", "ASHMERE / AMBULANCE BAY AND MAINTENANCE SHED", _parts_progress(1, 2), "clinic_power_junction")
			return _objective("ACT II / THE LIVING CLINIC", "Repair the junction and choose where its last current goes.", "ASHMERE / AMBULANCE BAY", "PARTS READY / ROUTE UNDECIDED", "clinic_power_junction")
		if not WorldState.has_flag(IMOGEN_ESCORT_FLAG): return _objective("ACT II / THE LIVING CLINIC", "Return to Imogen and ask her to move.", "ASHMERE / CLINIC, SOUTH-EAST", "JUNCTION REPAIRED", "imogen_clinic")
		if not WorldState.has_flag(IMOGEN_RESCUED_FLAG): return _objective("ACT II / THE LIVING CLINIC", "Escort Imogen to Maggie's workshop cellar.", "CLINIC TO WORKSHOP / KEEP HER CLOSE", "ESCORT IN PROGRESS", "imogen_workshop_safe")
		if not ArchiveSystem.has_echo(&"echo_sun_lid"): return _objective("ACT II / ASHMERE ESTATE", "Find Ellie's lunch tin with the nine-ray sun.", "ASHMERE / CLINIC LOOP, SOUTH", "CLUE 0 / 2", "EchoSunLid")
		if not ArchiveSystem.has_echo(&"echo_mara_repair"): return _objective("ACT II / ASHMERE ESTATE", "Catalogue Maggie's service ledger.", "ASHMERE / WORKSHOP, NORTH-EAST", "CLUE 1 / 2", "EchoMaraRepair")
		if _narrative_state.route_anchor == &"": return _objective("ACT II / WHOSE WORK LEADS", "Read Maggie's four work cards and choose the method Ellie will follow.", "ASHMERE / MAGGIE'S WORKSHOP YARD", "FOUR ROUTES / NO COMMITMENT", String(NARRATIVE_ANCHOR_STORY_ID))
		if _narrative_state.network_strategy == &"": return _objective("ACT II / WHAT THE RELAYS BECOME", "Choose whether Tollard is restored, divided into a mesh, or severed.", "ASHMERE / EAST MAINTENANCE GATE", "METHOD CHOSEN / NETWORK UNDECIDED", String(NARRATIVE_STRATEGY_STORY_ID))
		var ash_job := _route_job_objective(0, "ACT II")
		if not ash_job.is_empty(): return ash_job
		return _objective("ACT II / ASHMERE ESTATE", "Use both clues to open the Wrenfield road.", "ASHMERE / MAINTENANCE GATE, FAR EAST", "CLUES 2 / 2", "ashmere_gate")
	if path == BROADCAST_SCENE:
		if get_road_trace_count() < 2:
			var next_trace := _next_road_trace()
			return _objective("ACT III / THE ROAD THAT LIED", "Cross-check the physical evacuation records.", _road_trace_location(next_trace), "CONTRADICTIONS %d / 2" % mini(get_road_trace_count(), 2), String(next_trace))
		if not WorldState.has_flag(&"relay_west_restored"): return _objective("ACT III / THE ROAD THAT LIED", "Restore west road control from the verified records.", "WRENFIELD / WEST CABLE HOUSE", "ROUTE VERIFIED", "broadcast_relay_west")
		if WorldState.has_flag(RAFI_CONNECTED_FLAG) and not _rafi_field_decided(): return _objective("ACT III / A HUMAN CARRIER", "Meet Rafi and choose where he is needed.", "WRENFIELD / WEST REPEATER SHELTER", "RAFI ON SITE", "rafi_field_contact")
		if not WorldState.has_flag(&"relay_east_restored"):
			var hold_progress := "HOLD ACTIVE" if WorldState.has_flag(EAST_DEFENSE_STARTED_FLAG) else "HOLD NOT STARTED"
			return _objective("ACT III / THE CLINIC LINE", "Defend the east clinic carrier through the surge.", "WRENFIELD / EAST ROADSIDE BUNKER", hold_progress, "broadcast_defense_anchor")
		if not WorldState.has_flag(&"relay_south_restored"):
			var next_switch := _next_south_switch()
			return _objective("ACT III / THE SOUTH CIRCUIT", "Reroute FEED / GROUND / CARRIER by hand.", "WRENFIELD / SOUTH SERVICE ROAD", "SWITCHES %d / 3" % get_circuit_alignment(&"south_line"), "circuit_south_line_%s" % next_switch)
		if not WorldState.is_defeated(&"RelayHusk"): return _objective("ACT III / WRENFIELD RELAYS", "Stop the Linesman; sweep when its blue field rises.", "WRENFIELD / TOLLARD GATE, NORTH", "RELAYS 3 / 3", "RelayHusk")
		if not ArchiveSystem.has_echo(&"echo_maggie_final"): return _objective("ACT III / THE FLOODED CUTTING", "Sweep Maggie's recorder where the return footprints stop.", "WRENFIELD / FLOODED CUTTING, SOUTH-EAST", "RECORDER TRACE NOT FILED", "EchoMaggieFinal")
		if not WorldState.has_flag(&"maggie_final_proof_recovered"): return _objective("ACT III / THE FLOODED CUTTING", "Check the body, watch and uncut recorder together.", "WRENFIELD / FLOODED CUTTING, SOUTH-EAST", "TRACE FILED / IDENTITY UNCONFIRMED", String(MAGGIE_CUTTING_STORY_ID))
		if get_hollow_policy() == &"undecided": return _objective("ACT III / A VOICE UNDER THE CARRIER", "Decide what Ellie will do with a recoverable Hollow.", "WRENFIELD / FLOODED CUTTING APPROACH", "POLICY UNDECIDED", String(RECOVERABLE_HOLLOW_STORY_ID))
		var wrenfield_job := _route_job_objective(1, "ACT III")
		if not wrenfield_job.is_empty(): return wrenfield_job
		return _objective("ACT III / WRENFIELD RELAYS", "Open the Tollard service gate.", "WRENFIELD / NORTH GATE", "GATE CIRCUIT READY", "broadcast_core_gate")
	if path == CHOIR_SCENE:
		if not ArchiveSystem.has_echo(&"echo_first_tone"): return _objective("ACT IV / TOLLARD EXCHANGE", "Catalogue the Incident 44 report.", "TOLLARD / CENTRAL PRINTER BANK", "EVIDENCE 0 / 2", "EchoFirstTone")
		if not WorldState.is_defeated(&"ChoirWarden"): return _objective("ACT IV / TOLLARD EXCHANGE", "Stop the Custodian; sweep to break its field.", "TOLLARD / INCIDENT CONTROL, NORTH", "WRENFIELD PROOF FILED", "ChoirWarden")
		if get_active_route_id() == &"": return _objective("ACT IV / NO ROUTE TO COMMIT", "Leave Tollard and return to Maggie's four work cards in Ashmere.", "SOUTH ROAD / ASHMERE WORKSHOP", "TWELVE OPERATIONS WAITING", "BackToBroadcastFields")
		if not WorldState.has_flag(&"route_finale_started"): return _objective("ACT IV / THE LAST OPERATION", "Begin the route operation at Incident Control.", "TOLLARD / INCIDENT CONTROL, NORTH", "FIELD JOBS COMPLETE", "choir_final_console")
		if not is_circuit_complete(&"route_finale"):
			var next_finale := _next_route_finale_switch()
			return _objective("ACT IV / THE LAST OPERATION", "Throw all three manual cabinets in the pattern fixed outside.", "TOLLARD / ARCHIVE, CARRIER AND FAILSAFE CABINETS", "CONTACTS %d / 3" % get_circuit_alignment(&"route_finale"), "circuit_route_finale_%s" % next_finale)
		return _objective("ACT IV / THE LAST OPERATION", "Return to Incident Control and commit the route.", "TOLLARD / INCIDENT CONTROL, NORTH", "MANUAL CONTACTS AGREE", "choir_final_console")
	return _objective("THE WORLD FORGOT US", "Find a road that still agrees with its signs.", "NO VERIFIED LOCATION", "ROUTE UNKNOWN", "")


func _aftermath_objective(path: String) -> Dictionary:
	var route := get_active_route()
	var title := String(route.get("title", "The route you made"))
	if path == GameManager.BASE_SCENE_PATH:
		return _objective("AFTERMATH / %s" % title.to_upper(), "Talk to the people who came home, then revisit any road you changed.", "RAILHOME / SURVIVAL DEPOT", "THE WORLD REMAINS EXPLORABLE", "Outside")
	if path == ASHMERE_SCENE:
		return _objective("AFTERMATH / ASHMERE", "Walk the clinic, workshop and school loop. The route's local services now answer here.", "ASHMERE ESTATE", "CONSEQUENCES APPLIED", "ashmere_gate")
	if path == BROADCAST_SCENE:
		return _objective("AFTERMATH / WRENFIELD", "Check the relay road and the flooded cutting after Tollard's final operation.", "WRENFIELD RELAY FIELDS", "CONSEQUENCES APPLIED", "broadcast_core_gate")
	if path == CHOIR_SCENE:
		return _objective("AFTERMATH / TOLLARD", "Read the cabinets and archives left by the operation, or take the south road home.", "TOLLARD COUNTY EXCHANGE", "INCIDENT CLOSED", "BackToBroadcastFields")
	return _objective("AFTERMATH / OPEN ROAD", "Travel where you choose. The ending is saved; the region is still yours to inspect.", "CULLBROOK AND THE NORTH ROAD", "INCIDENT CLOSED", "BaseDoor")


func _route_job_objective(slot: int, act_label: String) -> Dictionary:
	var missions := get_route_mission_definitions()
	if slot < 0 or slot >= missions.size():
		return {}
	var mission: Dictionary = missions[slot]
	var mission_id := StringName(mission.get("id", &""))
	var state := get_route_mission_state(mission_id)
	if state == &"complete":
		return {}
	var heading := "%s / %s" % [act_label, String(mission.get("title", "ROUTE JOB")).to_upper()]
	var location := String(mission.get("region", "Route field station")).to_upper()
	if state == &"available":
		return _objective(heading, "Read the exclusive work card and take the job.", location, "JOB NOT TAKEN", String(mission_id))
	var unmet: Array = _route_mission_contracts().unmet_steps(mission_id)
	if unmet.is_empty():
		return _objective(heading, "Return to the work card and sign off the completed field checks.", location, "FIELD CHECKS COMPLETE", String(mission_id))
	var next_step := String(unmet[0].get("label", "Finish the route field work"))
	return _objective(heading, "%s. The work card carries the full list." % next_step, location, _route_mission_contracts().progress_text(mission_id), String(mission_id))


func _next_route_finale_switch() -> String:
	for switch_id in [&"archive", &"carrier", &"failsafe"]:
		if not WorldState.has_flag(_circuit_touch_key(&"route_finale", switch_id)):
			return String(switch_id)
	return "archive"


func get_restored_relay_count() -> int:
	var total := 0
	for flag in [&"relay_west_restored", &"relay_east_restored", &"relay_south_restored"]:
		if WorldState.has_flag(flag): total += 1
	return total


func get_road_trace_count() -> int:
	var total := 0
	for trace_id in ROAD_TRACE_IDS:
		if WorldState.has_flag(trace_id):
			total += 1
	return total


func _next_road_trace() -> StringName:
	for trace_id in ROAD_TRACE_IDS:
		if not WorldState.has_flag(trace_id):
			return trace_id
	return ROAD_TRACE_IDS[-1]


func _road_trace_location(trace_id: StringName) -> String:
	match trace_id:
		&"road_trace_west": return "WRENFIELD / WEST CABLE HOUSE"
		&"road_trace_east": return "WRENFIELD / EAST LAY-BY"
		&"road_trace_south": return "WRENFIELD / SOUTH GENERATOR"
	return "WRENFIELD / FOLLOW THE PAPER MARKERS"


func _next_south_switch() -> String:
	var expected := {&"feed": true, &"ground": false, &"carrier": true}
	for switch_id in expected:
		if (
			not WorldState.has_flag(_circuit_touch_key(&"south_line", switch_id))
			or get_circuit_switch_state(&"south_line", switch_id, not bool(expected[switch_id])) != bool(expected[switch_id])
		):
			return String(switch_id)
	return "carrier"


func _relay_flag(story_id: StringName) -> StringName:
	match story_id:
		&"broadcast_relay_west": return &"relay_west_restored"
		&"broadcast_relay_east": return &"relay_east_restored"
		&"broadcast_relay_south": return &"relay_south_restored"
	return &""


func _ashmere_ready() -> bool:
	return (
		WorldState.has_flag(&"mara_contacted")
		and WorldState.has_flag(IMOGEN_RESCUED_FLAG)
		and ArchiveSystem.has_echo(&"echo_sun_lid")
		and ArchiveSystem.has_echo(&"echo_mara_repair")
		and get_active_route_id() != &""
		and _route_mission_complete(0)
	)


func _broadcast_ready() -> bool:
	return (
		get_active_route_id() != &""
		and get_restored_relay_count() == 3
		and WorldState.is_defeated(&"RelayHusk")
		and ArchiveSystem.has_echo(&"echo_maggie_final")
		and WorldState.has_flag(&"maggie_final_proof_recovered")
		and get_hollow_policy() != &"undecided"
		and _route_mission_complete(1)
	)


func _route_mission_complete(slot: int) -> bool:
	var missions := get_route_mission_definitions()
	if slot < 0 or slot >= missions.size():
		return false
	return _narrative_state.get_mission_state(StringName(missions[slot].get("id", &""))) == &"complete"


func _resolve_recoverable_hollow(choice_index: int) -> void:
	if get_hollow_policy() != &"undecided":
		return
	var policy := &""
	var tool := &""
	match choice_index:
		0:
			policy = &"stabilise"
			tool = &"analogue_isolator"
		1:
			policy = &"kill"
		2:
			policy = &"weaponise"
			tool = &"signal_decoy"
	if policy == &"":
		return
	if tool != &"" and not InventorySystem.remove_item(tool, 1):
		EventBus.notice_posted.emit("That decision needs a %s from the workbench." % String(tool).replace("_", " "))
		return
	record_hollow_outcome(policy, 1, false)
	WorldState.set_flag(StringName("first_hollow_%s" % String(policy)))
	if policy == &"stabilise":
		set_narrative_npc_state(&"nia", &"rescued", false)
		EventBus.notice_posted.emit("NIA CALDER STABILISED - the carrier loop breaks before the person does.")
	elif policy == &"kill":
		set_narrative_npc_state(&"nia", &"dead", false)
		EventBus.notice_posted.emit("NIA CALDER KILLED - the carrier and the person stop together.")
	else:
		set_narrative_npc_state(&"nia", &"estranged", false)
		EventBus.notice_posted.emit("NIA CALDER WEAPONISED - her loop becomes a lure. She remains alive inside it.")
	SaveManager.save_game("")


func _clinic_junction_resolved() -> bool:
	return WorldState.has_flag(CLINIC_POWER_FLAG) or WorldState.has_flag(SCHOOL_POWER_FLAG)


func _rafi_field_decided() -> bool:
	return WorldState.has_flag(&"rafi_field_defense") or WorldState.has_flag(&"rafi_field_repeater")


func _secret_ending_unlocked() -> bool:
	for trace_id in ALL_TRACE_IDS:
		if not ArchiveSystem.has_echo(trace_id):
			return false
	return (
		WorldState.has_flag(REPEATER_ONLINE_FLAG)
		and WorldState.has_flag(RAFI_CONNECTED_FLAG)
		and WorldState.has_flag(IMOGEN_RESCUED_FLAG)
		and WorldState.has_flag(&"wrenfield_route_verified")
		and WorldState.is_opened(&"keepsake_shelf_used")
	)


func get_rafi_status() -> String:
	if WorldState.has_flag(RAFI_ROUTE_REJOINED_FLAG):
		return "rejoined through Maggie's local relay"
	if WorldState.has_flag(RAFI_CONNECTED_FLAG):
		return "connected on 88.4"
	if WorldState.has_flag(RAFI_DECLINED_FLAG):
		return "backfeed kept local" if WorldState.has_flag(SCHOOL_POWER_FLAG) else "aerial grounded"
	return "undecided"


func get_public_repeater_status() -> String:
	if WorldState.has_flag(REPEATER_ONLINE_FLAG):
		return "warning line online"
	if WorldState.has_flag(REPEATER_DECLINED_FLAG):
		return "fuse removed"
	return "undecided"


func get_optional_progress() -> Array[Dictionary]:
	var progress: Array[Dictionary] = []
	progress.append(_optional_progress(
		"Light the Cullbrook mile lamp",
		"LIT" if BaseUpgradeSystem.is_built(&"route_beacon") else _parts_progress(1, 2),
		"complete" if BaseUpgradeSystem.is_built(&"route_beacon") else "open",
		"CULLBROOK / EAST VERGE",
		"rustway",
	))
	if _has_keepsake() or WorldState.is_opened(&"keepsake_shelf_used"):
		progress.append(_optional_progress(
			"Place a recovered keepsake",
			"PRESERVED" if WorldState.is_opened(&"keepsake_shelf_used") else "KEEPSAKE FOUND",
			"complete" if WorldState.is_opened(&"keepsake_shelf_used") else "open",
			"CARRIAGE 317 / SHELF BY BEDROLL",
			"base",
		))
	if _has_reached_ashmere():
		progress.append(_optional_progress(
			"Get Imogen from clinic to workshop",
			"SAFE" if WorldState.has_flag(IMOGEN_RESCUED_FLAG) else ("ESCORTING" if WorldState.has_flag(IMOGEN_ESCORT_FLAG) else "NEEDS HELP"),
			"complete" if WorldState.has_flag(IMOGEN_RESCUED_FLAG) else "open",
			"ASHMERE / CLINIC TO MAGGIE'S WORKSHOP",
			"ashmere",
			"Repair the junction and escort Imogen",
		))
		if WorldState.has_flag(RAFI_CONNECTED_FLAG):
			progress.append(_optional_progress("88.4 water-works link", "CONNECTED", "complete", "BELLWETHER SCHOOL / NORTH-WEST", "ashmere", "Call Rafi on 88.4"))
		elif WorldState.has_flag(RAFI_DECLINED_FLAG):
			var declined_status := "BACKFEED LOCAL" if WorldState.has_flag(SCHOOL_POWER_FLAG) else "AERIAL GROUNDED"
			progress.append(_optional_progress("88.4 water-works link", declined_status, "closed", "BELLWETHER SCHOOL / NORTH-WEST", "ashmere", "Call Rafi on 88.4"))
		else:
			progress.append(_optional_progress("88.4 water-works link", "NOT CONTACTED", "open", "BELLWETHER SCHOOL / NORTH-WEST", "ashmere", "Call Rafi on 88.4"))
		progress.append(_trace_task(&"echo_clinic_triage", "Catalogue the clinic's paper list", "ASHMERE CLINIC / SOUTH-EAST", "ashmere"))
		progress.append(_trace_task(&"echo_bus_ledger", "Catalogue the bus driver's ledger", "ASHMERE BUS DEPOT / SOUTH-WEST", "ashmere"))
	if _has_reached_broadcast():
		progress.append(_optional_progress(
			"Verify the evacuation road",
			"CONTRADICTIONS %d / 3" % get_road_trace_count(),
			"complete" if WorldState.has_flag(&"wrenfield_route_verified") else "open",
			"WRENFIELD / THREE PHYSICAL RECORDS",
			"broadcast",
			"Cross-check road control against physical evidence",
		))
		if WorldState.has_flag(REPEATER_ONLINE_FLAG):
			progress.append(_optional_progress("Public warning line", "ONLINE", "complete", "WRENFIELD / REPEATER SHELTER, SOUTH-WEST", "broadcast", "Restore the public warning line"))
		elif WorldState.has_flag(REPEATER_DECLINED_FLAG):
			progress.append(_optional_progress("Public warning line", "FUSE REMOVED", "closed", "WRENFIELD / REPEATER SHELTER, SOUTH-WEST", "broadcast", "Restore the public warning line"))
		else:
			progress.append(_optional_progress("Public warning line", "NOT DECIDED", "open", "WRENFIELD / REPEATER SHELTER, SOUTH-WEST", "broadcast", "Restore the public warning line"))
		progress.append(_trace_task(&"echo_names_wall", "Catalogue the names wall", "WRENFIELD / SOUTH-WEST FENCE", "broadcast"))
		progress.append(_trace_task(&"echo_relay_warning", "Catalogue Maggie's weather test", "WRENFIELD / WEST CABLE HOUSE", "broadcast"))
		progress.append(_trace_task(&"echo_driver_call", "Catalogue the stranded driver's call", "WRENFIELD / EAST LAY-BY", "broadcast"))
	for mission in get_route_mission_progress():
		var state := String(mission.get("state", "available"))
		var status := "DONE" if state == "complete" else ("IN PROGRESS" if state == "active" else "AVAILABLE")
		progress.append(_optional_progress(
			String(mission.get("title", "Route work")),
			status,
			"complete" if state == "complete" else "open",
			String(mission.get("region", "Route location")).to_upper(),
			"ashmere" if int(mission.get("act", 3)) <= 2 else "broadcast",
			String(mission.get("brief", "Complete the route work.")),
		))
	return progress


func get_optional_focus() -> Dictionary:
	var area := _current_area()
	for entry in get_optional_progress():
		if String(entry.get("area", "")) == area and String(entry.get("state", "open")) == "open":
			return entry
	return {}


func _repeater_decided() -> bool:
	return (
		WorldState.has_flag(REPEATER_ONLINE_FLAG)
		or WorldState.has_flag(REPEATER_DECLINED_FLAG)
	)


func _has_reached_ashmere() -> bool:
	var path := _current_level_path()
	return (
		path == ASHMERE_SCENE
		or path == BROADCAST_SCENE
		or path == CHOIR_SCENE
		or WorldState.has_flag(&"ashmere_opened")
		or WorldState.has_flag(&"mara_contacted")
	)


func _has_reached_broadcast() -> bool:
	var path := _current_level_path()
	return (
		path == BROADCAST_SCENE
		or path == CHOIR_SCENE
		or WorldState.has_flag(&"broadcast_opened")
		or get_restored_relay_count() > 0
		or _repeater_decided()
	)


func _clinic_line_result() -> String:
	if WorldState.has_flag(RAFI_ROUTE_REJOINED_FLAG):
		return "Rafi reads back the clinic list over Maggie's local pair; the school aerial remains grounded."
	if WorldState.has_flag(RAFI_CONNECTED_FLAG):
		return "Rafi reads back the Ashmere clinic channel."
	if WorldState.has_flag(RAFI_DECLINED_FLAG):
		return (
			"The local school backfeed carries Imogen's verified clinic read-back, but 88.4 remains unconnected."
			if WorldState.has_flag(SCHOOL_POWER_FLAG)
			else "The clinic carrier holds, but the grounded school set cannot answer it."
		)
	return "The Ashmere clinic channel answers with a clear carrier. Nobody is listening yet."


func _ending_stats() -> String:
	var ending_name := _ending_label(StringName(WorldState.get_flag(&"ending_id", "")))
	return "Outcome: %s\nTraces: %d / 10\nRoad records: %d / 3\nLine relays: %d / 3\nImogen: %s\nJunction: %s\nRafi: %s\nRafi field role: %s\nPublic repeater: %s" % [
		ending_name, ArchiveSystem.get_count(), get_road_trace_count(), get_restored_relay_count(),
		"safe at Maggie's workshop" if WorldState.has_flag(IMOGEN_RESCUED_FLAG) else "unaccounted for",
		"clinic lift" if WorldState.has_flag(CLINIC_POWER_FLAG) else "school aerial",
		get_rafi_status(),
		"east-line cover" if WorldState.has_flag(&"rafi_field_defense") else ("public-repeater guard" if WorldState.has_flag(&"rafi_field_repeater") else "not assigned"),
		get_public_repeater_status(),
	]


func _ending_label(ending_id: StringName) -> String:
	var route := NarrativeRouteRegistryScript.get_route(ending_id)
	if not route.is_empty():
		return String(route.get("title", "Unknown"))
	match ending_id:
		&"archive": return "Verified records sent"
		&"silence": return "Exchange power cut"
		&"choir": return "Local packets built"
	return "Unknown"


func _narrative_prompt(story_id: StringName) -> String:
	if story_id == NARRATIVE_ANCHOR_STORY_ID:
		return "Review the four human routes" if _narrative_state.route_anchor == &"" else "Review your chosen ally"
	if story_id == NARRATIVE_ANCHOR_MORE_STORY_ID:
		return "Review the witness and Continuity routes"
	if story_id == NARRATIVE_STRATEGY_STORY_ID:
		return "Decide what the relays will become" if _narrative_state.network_strategy == &"" else "Review the relay commitment"
	var npc_id := NarrativeNPCRegistryScript.id_from_story_id(story_id)
	if npc_id != &"":
		var definition := NarrativeNPCRegistryScript.get_definition(npc_id)
		return "Speak with %s" % String(definition.get("display_name", "the survivor"))
	var mission := NarrativeRouteRegistryScript.find_mission(get_active_route_id(), story_id)
	if mission.is_empty():
		return ""
	match _narrative_state.get_mission_state(story_id):
		&"available": return "Take the job: %s" % String(mission.get("title", "route work"))
		&"active": return "Review the job: %s" % String(mission.get("title", "route work"))
		&"complete": return "Review the completed job"
	return ""


func _narrative_dialogue_for(story_id: StringName) -> Dictionary:
	if story_id == NARRATIVE_ANCHOR_STORY_ID:
		if not WorldState.has_flag(&"mara_contacted"):
			return _payload(story_id, "MAGGIE'S FOUR WORK CARDS", [
				"The names are legible, but Maggie's workshop tape supplies the order and the warning written across them.",
			], [], RED)
		if _narrative_state.route_anchor != &"":
			return _payload(story_id, "WHOSE WORK LEADS", [
				"You chose %s. Other survivors can still be helped; this work decides the method." % NarrativeRouteRegistryScript.ANCHOR_LABELS.get(_narrative_state.route_anchor, "the route"),
			], [], CYAN)
		return _payload(story_id, "WHOSE WORK LEADS", [
			"Imogen keeps bodies and medicine together. Rafi gets warnings out in time.",
			"Leena keeps sources attached to names. The copied voice offers speed and access at the cost of learning you.",
			"This chooses the campaign method, not who is allowed to live.",
		], [
			"WORK WITH IMOGEN - MEDICAL ROUTE",
			"WORK WITH RAFI - PUBLIC WARNING ROUTE",
			"REVIEW LEENA AND THE COPIED VOICE",
		], AMBER)
	if story_id == NARRATIVE_ANCHOR_MORE_STORY_ID:
		return _payload(story_id, "WITNESS OR CONTINUITY", [
			"Leena keeps every claim attached to a person who will answer for it.",
			"The copied voice opens routes no living person can reach, and learns from every private trace it receives.",
		], [
			"WORK WITH LEENA - WITNESS ROUTE",
			"WORK WITH THE VOICE - CONTINUITY ROUTE",
			"BACK TO IMOGEN AND RAFI",
		], AMBER)
	if story_id == NARRATIVE_STRATEGY_STORY_ID:
		if _narrative_state.route_anchor == &"":
			return _payload(story_id, "THE RELAYS", ["Choose whose work leads before deciding what the network becomes."], [], RED)
		if _narrative_state.network_strategy != &"":
			return _payload(story_id, "THE RELAYS", [
				"The relays are committed: %s." % NarrativeRouteRegistryScript.STRATEGY_LABELS.get(_narrative_state.network_strategy, "route fixed"),
				"Changing them now would break the work already attached to them.",
			], [], CYAN)
		return _payload(story_id, "WHAT THE RELAYS BECOME", [
			"RESTORE keeps speed and central reach under human rules.",
			"MESH divides the work into limited local services with visible gaps.",
			"SEVER stops Continuity and destroys records and reach with it.",
		], [
			"RESTORE THE EXCHANGE - KEEP HUMAN AUDIT",
			"BUILD A LOCAL MESH - ACCEPT THE GAPS",
			"SEVER THE NETWORK - LOSE THE RECORDS",
		], AMBER)

	var npc_id := NarrativeNPCRegistryScript.id_from_story_id(story_id)
	if npc_id != &"":
		return get_npc_dialogue_payload(npc_id)

	var mission := NarrativeRouteRegistryScript.find_mission(get_active_route_id(), story_id)
	if mission.is_empty():
		return {}
	var state := _narrative_state.get_mission_state(story_id)
	var line_key := "start_lines"
	var choices: Array[String] = []
	if state == &"available":
		choices = ["TAKE THE JOB", "NOT YET"]
	elif state == &"active":
		line_key = "active_lines"
	else:
		line_key = "complete_lines"
	var lines: Array = mission.get(line_key, [String(mission.get("brief", "The work is waiting."))])
	lines = lines.duplicate()
	if state == &"available":
		lines.append(String(mission.get("gameplay", "")))
	return _payload(
		story_id,
		String(mission.get("title", "ROUTE WORK")).to_upper(),
		lines,
		choices,
		_narrative_accent_for_npc(StringName(mission.get("owner", &""))),
	)


func _complete_narrative_story(story_id: StringName, choice_index: int) -> bool:
	if story_id == NARRATIVE_ANCHOR_STORY_ID:
		if not WorldState.has_flag(&"mara_contacted"):
			return true
		if choice_index == 0:
			commit_route_anchor(&"clinic")
		elif choice_index == 1:
			commit_route_anchor(&"radio")
		elif choice_index == 2:
			call_deferred("request_interaction", NARRATIVE_ANCHOR_MORE_STORY_ID)
		return true
	if story_id == NARRATIVE_ANCHOR_MORE_STORY_ID:
		if choice_index == 0:
			commit_route_anchor(&"witness")
		elif choice_index == 1:
			commit_route_anchor(&"copy")
		elif choice_index == 2:
			call_deferred("request_interaction", NARRATIVE_ANCHOR_STORY_ID)
		return true
	if story_id == NARRATIVE_STRATEGY_STORY_ID:
		if choice_index >= 0 and choice_index < NarrativeRouteRegistryScript.STRATEGIES.size():
			commit_network_strategy(NarrativeRouteRegistryScript.STRATEGIES[choice_index])
		return true
	if NarrativeNPCRegistryScript.id_from_story_id(story_id) != &"":
		return true
	var mission := NarrativeRouteRegistryScript.find_mission(get_active_route_id(), story_id)
	if mission.is_empty():
		return false
	if choice_index == 0 and _narrative_state.get_mission_state(story_id) == &"available":
		start_route_mission(story_id)
	return true


func _narrative_npc_beat(npc_id: StringName) -> String:
	if _narrative_state.get_npc_state(npc_id) == &"rescued":
		return "service"
	var route_anchor: StringName = _narrative_state.route_anchor
	if (
		(route_anchor == &"clinic" and npc_id == &"imogen")
		or (route_anchor == &"radio" and npc_id == &"rafi")
		or (route_anchor == &"witness" and npc_id == &"leena")
		or (route_anchor == &"copy" and npc_id == &"maggie_copy")
	):
		return "route"
	return "introduction"


func _narrative_accent_for_npc(npc_id: StringName) -> Color:
	match npc_id:
		&"nia": return RED
		&"ellie", &"maggie", &"maggie_copy": return AMBER
		&"owen", &"doyle": return Color(0.72, 0.82, 0.86, 1.0)
	return CYAN


func _narrative_ending_accent(strategy: StringName) -> Color:
	match strategy:
		&"restore": return AMBER
		&"sever": return Color(0.72, 0.82, 0.86, 1.0)
	return CYAN


func _narrative_ending_stats(payload: Dictionary) -> String:
	var axis: Dictionary = payload.get("axis_summary", {})
	var modifiers: Array[String] = []
	for modifier in payload.get("gameplay_modifiers", []):
		modifiers.append(String(modifier).replace("_", " "))
	return "Route: %s\nEvidence: %d / 14\nHollows: %s\nPeople brought home: %d\nPrivate traces shared: %d\nPlay changes: %s" % [
		String(payload.get("title", "Unknown")),
		int(axis.get("evidence_confidence", 0)),
		String(axis.get("hollow_policy", "undecided")).replace("_", " "),
		Array(axis.get("rescued_npcs", [])).size(),
		int(axis.get("fed_traces", 0)),
		", ".join(modifiers),
	]


func _apply_route_world_states(payload: Dictionary) -> void:
	for state_value in payload.get("world_states", []):
		var state_id := StringName(state_value)
		if state_id != &"":
			WorldState.set_flag(state_id)
	WorldState.set_flag(&"route_aftermath_available")
	WorldState.set_flag(&"aftermath_route_id", String(payload.get("route_id", "")))
	WorldState.set_flag(&"aftermath_world_states", payload.get("world_states", []))


func _migrate_legacy_narrative() -> void:
	if WorldState.has_flag(IMOGEN_RESCUED_FLAG):
		_narrative_state.rescue_npc(&"imogen")
	elif WorldState.has_flag(IMOGEN_MET_FLAG):
		_narrative_state.set_npc_state(&"imogen", &"active")
	if WorldState.has_flag(RAFI_CONNECTED_FLAG):
		_narrative_state.rescue_npc(&"rafi")
	elif WorldState.has_flag(RAFI_DECLINED_FLAG):
		_narrative_state.set_npc_state(&"rafi", &"active")
	for trace_id in ALL_TRACE_IDS:
		if ArchiveSystem.has_echo(trace_id):
			for revelation_id in NarrativeRouteRegistryScript.trace_revelations(trace_id):
				_narrative_state.add_evidence(revelation_id)
	if get_road_trace_count() >= 2:
		_narrative_state.add_evidence(&"R04")
	if not WorldState.has_flag(&"ending_complete"):
		return
	var legacy_ending := StringName(WorldState.get_flag(&"ending_id", ""))
	var strategy: StringName = &""
	match legacy_ending:
		&"archive": strategy = &"restore"
		&"choir": strategy = &"mesh"
		&"silence": strategy = &"sever"
	if strategy == &"":
		return
	_narrative_state.commit_anchor(&"witness")
	_narrative_state.commit_strategy(strategy)
	for mission in NarrativeRouteRegistryScript.get_missions(_narrative_state.get_route_id()):
		var mission_id := StringName(mission.get("id", &""))
		_narrative_state.start_mission(mission_id)
		_narrative_state.complete_mission(mission_id)


func _emit_narrative_state(persist: bool, previous_route: StringName) -> void:
	var snapshot := get_narrative_state()
	EventBus.narrative_state_changed.emit(snapshot)
	var route_id := get_active_route_id()
	if route_id != &"" and route_id != previous_route:
		EventBus.narrative_route_committed.emit(route_id)
	EventBus.campaign_progress_changed.emit()
	if persist and get_tree().get_first_node_in_group("main") != null:
		SaveManager.save_game("")


func _optional_progress(label: String, status: String, state: String, location: String, area: String, task: String = "") -> Dictionary:
	return {
		"label": label,
		"task": task if not task.is_empty() else label,
		"status": status,
		"progress": status,
		"state": state,
		"location": location,
		"area": area,
	}


func _trace_task(trace_id: StringName, task: String, location: String, area: String) -> Dictionary:
	var found := ArchiveSystem.has_echo(trace_id)
	return _optional_progress(task, "CATALOGUED 1 / 1" if found else "TRACE 0 / 1", "complete" if found else "open", location, area)


func _current_area() -> String:
	match _current_level_path():
		GameManager.BASE_SCENE_PATH: return "base"
		RUSTWAY_SCENE: return "rustway"
		ASHMERE_SCENE: return "ashmere"
		BROADCAST_SCENE: return "broadcast"
		CHOIR_SCENE: return "choir"
	return "rustway"


func _has_keepsake() -> bool:
	for item_id in [&"old_photo", &"tin_locket", &"child_lunchbox"]:
		if InventorySystem.get_count(item_id) > 0:
			return true
	return false


func _has_parts(batteries: int, scrap: int) -> bool:
	return InventorySystem.get_count(&"battery") >= batteries and InventorySystem.get_count(&"scrap") >= scrap


func _parts_progress(batteries: int, scrap: int) -> String:
	return "BATTERY %d / %d  /  SCRAP %d / %d" % [
		mini(InventorySystem.get_count(&"battery"), batteries), batteries,
		mini(InventorySystem.get_count(&"scrap"), scrap), scrap,
	]


func _payload(id: StringName, title: String, lines: Array, choices: Array, accent: Color) -> Dictionary:
	return {"id": id, "title": title, "lines": lines, "choices": choices, "accent": accent}


func _objective(chapter: String, text: String, location: String, progress: String, target: String) -> Dictionary:
	return {
		"chapter": chapter,
		"text": text,
		"location": location,
		"progress": progress,
		"target": target,
	}


func _current_level_path() -> String:
	var main := get_tree().get_first_node_in_group("main")
	if main != null and main.has_method("get_current_level_path"): return main.get_current_level_path()
	return ""


func _on_echo_recorded(data: MemoryEchoData) -> void:
	var narrative_changed := false
	if data != null and ArchiveSystem.get_disposition(data.id) == ArchiveSystem.VERIFIED:
		for revelation_id in NarrativeRouteRegistryScript.trace_revelations(data.id):
			if _narrative_state.add_evidence(revelation_id):
				narrative_changed = true
	if data != null and data.id == &"echo_mara_repair" \
			and _share_copy_workshop_trace_if_ready():
		narrative_changed = true
	if narrative_changed:
		EventBus.narrative_state_changed.emit(get_narrative_state())
	_emit_progress()
	if get_tree().get_first_node_in_group("main") != null: SaveManager.save_game("")


func _on_upgrade_built(_data) -> void:
	_emit_progress()


func _emit_progress() -> void:
	EventBus.campaign_progress_changed.emit()
