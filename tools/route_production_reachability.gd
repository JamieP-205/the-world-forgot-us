extends Node
## Production reachability contract for the twelve-route campaign.
## Run with an isolated APPDATA directory:
## godot --headless --path <project> --scene res://tools/route_production_reachability.tscn

const RouteRegistry = preload("res://scripts/narrative/narrative_route_registry.gd")
const Contracts = preload("res://scripts/narrative/route_mission_contracts.gd")

const ASHMERE_SCENE := "res://scenes/maps/ashmere_verge.tscn"
const BROADCAST_SCENE := "res://scenes/maps/broadcast_fields.tscn"
const CHOIR_SCENE := "res://scenes/maps/choir_core.tscn"
const ENDING_OVERLAY_SCENE := preload("res://scenes/ui/ending_overlay.tscn")

const ARCHIVE_FIXTURES: Array[StringName] = [
	&"echo_last_signal", &"echo_sun_lid", &"echo_mara_repair",
	&"echo_clinic_triage", &"echo_bus_ledger", &"echo_names_wall",
	&"echo_relay_warning", &"echo_driver_call", &"echo_first_tone",
	&"echo_maggie_final",
]
const RELAY_FLAGS: Array[StringName] = [
	&"relay_west_restored", &"relay_east_restored", &"relay_south_restored",
]
const ROAD_FLAGS: Array[StringName] = [
	&"road_trace_west", &"road_trace_east", &"road_trace_south",
]
const FINALE_PATTERNS := {
	&"restore": {&"archive": true, &"carrier": true, &"failsafe": true},
	&"mesh": {&"archive": true, &"carrier": false, &"failsafe": true},
	&"sever": {&"archive": false, &"carrier": false, &"failsafe": false},
}


class AftermathMainFixture:
	extends Node
	var level_path := "res://scenes/maps/choir_core.tscn"

	func get_current_level_path() -> String:
		return level_path


var _failures: Array[String] = []
var _last_dialogue: Dictionary = {}
var _last_ending: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.dialogue_requested.connect(_capture_dialogue)
	EventBus.ending_requested.connect(_capture_ending)
	call_deferred("_run")


func _run() -> void:
	_reset_run_state()
	var ash_root := await _load_level(ASHMERE_SCENE)
	var broadcast_root := await _load_level(BROADCAST_SCENE)
	if ash_root != null and broadcast_root != null:
		_check_physical_route_nodes(ash_root, broadcast_root)
		_check_route_station_matrix(ash_root, broadcast_root)
		_check_all_mission_contracts(ash_root, broadcast_root)
		await _check_full_production_route(ash_root, broadcast_root)
	await _check_finale_patterns()

	GameManager.set_ending_active(false)
	GameManager.set_dialogue_active(false)
	SaveManager.delete_save()
	if _failures.is_empty():
		print("ROUTE_PRODUCTION_REACHABILITY: PASS")
		get_tree().quit(0)
		return
	for failure in _failures:
		push_error("ROUTE_PRODUCTION_REACHABILITY: " + failure)
	print("ROUTE_PRODUCTION_REACHABILITY: FAIL (%d)" % _failures.size())
	get_tree().quit(1)


func _check_physical_route_nodes(ash_root: Node, broadcast_root: Node) -> void:
	_check(_find_story_node(ash_root, &"narrative_anchor_commitment") != null,
		"Ashmere contains the physical four-work-card commitment")
	_check(_find_story_node(ash_root, &"narrative_strategy_commitment") != null,
		"Ashmere contains the physical relay-strategy commitment")

	var ash_stations := _route_stations(ash_root)
	var broadcast_stations := _route_stations(broadcast_root)
	_check(ash_stations.size() == 4, "Ashmere contains four anchor-specific route stations")
	_check(broadcast_stations.size() == 4, "Wrenfield contains four anchor-specific route stations")
	var anchors: Dictionary = {}
	for station in ash_stations:
		anchors[String(station.required_anchor)] = true
		_check(station.mission_slot == 0, "%s is wired to the Ashmere mission slot" % station.name)
	for station in broadcast_stations:
		anchors[String(station.required_anchor)] = true
		_check(station.mission_slot == 1, "%s is wired to the Wrenfield mission slot" % station.name)
	_check(anchors.size() == 4, "the eight stations cover clinic, radio, witness and copy anchors")

	_check(_find_named_node(broadcast_root, "FloodedCutting") != null,
		"Wrenfield contains the flooded-cutting investigation pocket")
	var maggie_body := _find_named_node(broadcast_root, "MaggieBody") as Node2D
	_check(maggie_body != null,
		"the flooded cutting visibly contains Maggie beside the recorder")
	if maggie_body != null:
		var body_visual := maggie_body.get_node_or_null("Visual") as Sprite2D
		_check(body_visual != null and body_visual.texture != null \
			and body_visual.texture.resource_path.ends_with("maggie_cutting_body.png"),
			"Maggie's discovery uses the authored body-and-recorder art")
	_check(_find_story_node(broadcast_root, &"maggie_cutting_recorder") != null,
		"the flooded cutting contains Maggie's body-and-recorder interaction")
	_check(_find_story_node(broadcast_root, &"wrenfield_recoverable_hollow") is HollowDecisionSite,
		"the flooded cutting contains the recoverable Hollow decision")
	_check(_find_memory_echo(broadcast_root, &"echo_maggie_final") != null,
		"Maggie's analogue recorder is a physical trace in the cutting")


func _check_route_station_matrix(ash_root: Node, broadcast_root: Node) -> void:
	var reachable_ids: Dictionary = {}
	var roots: Array[Node] = [ash_root, broadcast_root]
	for route_id in RouteRegistry.all_route_ids():
		_reset_run_state()
		var route := RouteRegistry.get_route(route_id)
		var anchor := StringName(route.get("anchor", &""))
		var strategy := StringName(route.get("strategy", &""))
		_check(CampaignSystem.commit_route_anchor(anchor, false), "%s anchor commits" % route_id)
		_check(CampaignSystem.commit_network_strategy(strategy, false), "%s strategy commits" % route_id)
		var missions := RouteRegistry.get_missions(route_id)
		for slot in range(missions.size()):
			var station := _find_station(roots, anchor, slot)
			var mission_id := StringName(missions[slot].get("id", &""))
			_check(station != null, "%s has a physical station for mission slot %d" % [route_id, slot])
			if station == null:
				continue
			_check(station.visible, "%s station %d becomes visible after commitment" % [route_id, slot])
			_check(StringName(station.get_meta("story_id", &"")) == mission_id,
				"%s station metadata resolves to %s" % [route_id, mission_id])
			_check(station.get_mission_id() == mission_id,
				"%s station API resolves to %s" % [route_id, mission_id])
			reachable_ids[mission_id] = true
	_check(reachable_ids.size() == 24, "all 24 exclusive mission ids resolve on physical map stations")
	for mission_id in Contracts.all_mission_ids():
		_check(reachable_ids.has(mission_id), "%s is reachable through a production station" % mission_id)


func _check_all_mission_contracts(ash_root: Node, broadcast_root: Node) -> void:
	var registry_ids: Array[StringName] = []
	for route_id in RouteRegistry.all_route_ids():
		for mission in RouteRegistry.get_missions(route_id):
			registry_ids.append(StringName(mission.get("id", &"")))
	for error in Contracts.validate(registry_ids):
		_fail("field contract: " + error)
	_check(registry_ids.size() == 24, "route registry contains 24 field jobs")
	_check(Contracts.all_mission_ids().size() == 24, "field contract table contains 24 field jobs")

	var roots: Array[Node] = [ash_root, broadcast_root]
	for route_id in RouteRegistry.all_route_ids():
		var route := RouteRegistry.get_route(route_id)
		var anchor := StringName(route.get("anchor", &""))
		var strategy := StringName(route.get("strategy", &""))
		var missions := RouteRegistry.get_missions(route_id)
		for slot in range(missions.size()):
			_reset_run_state()
			CampaignSystem.commit_route_anchor(anchor, false)
			CampaignSystem.commit_network_strategy(strategy, false)
			var mission := missions[slot]
			var mission_id := StringName(mission.get("id", &""))
			var station := _find_station(roots, anchor, slot)
			if station == null:
				_fail("%s has no station for its completion contract" % mission_id)
				continue

			_interact_and_finish(station, mission_id, 0)
			_check(CampaignSystem.get_route_mission_state(mission_id) == &"active",
				"%s starts from its physical work card" % mission_id)
			var contract := Contracts.get_contract(mission_id)
			var steps: Array = contract.get("steps", [])
			var unmet_before := Contracts.unmet_steps(mission_id)
			_check(unmet_before.size() == steps.size(),
				"%s begins with every authored field check unmet" % mission_id)
			station.interact(null)
			_check(CampaignSystem.get_route_mission_state(mission_id) == &"active",
				"%s cannot be signed off before its field checks" % mission_id)

			_satisfy_contract(mission_id)
			_check(Contracts.is_complete(mission_id), "%s accepts its complete field evidence" % mission_id)
			var cost_item := StringName(contract.get("cost_item", &""))
			var cost_before := InventorySystem.get_count(cost_item)
			station.interact(null)
			_check(CampaignSystem.get_route_mission_state(mission_id) == &"complete",
				"%s signs off through the physical work card" % mission_id)
			_check(InventorySystem.get_count(cost_item) == cost_before - 1,
				"%s consumes its crafted field tool on sign-off" % mission_id)
			var world_state := StringName(mission.get("world_state", &""))
			var service_unlock := StringName(mission.get("service_unlock", &""))
			_check(WorldState.has_flag(world_state), "%s applies world state %s" % [mission_id, world_state])
			_check(WorldState.has_flag(StringName("service_%s" % String(service_unlock))),
				"%s unlocks service %s" % [mission_id, service_unlock])
			_finish_active_dialogue(mission_id, -1)


func _check_full_production_route(ash_root: Node, broadcast_root: Node) -> void:
	_reset_run_state()
	var mara := _find_story_node(ash_root, &"ashmere_mara_radio")
	var anchor_card := _find_story_node(ash_root, &"narrative_anchor_commitment")
	var strategy_card := _find_story_node(ash_root, &"narrative_strategy_commitment")
	if mara == null or anchor_card == null or strategy_card == null:
		_fail("full route cannot begin because an Ashmere commitment node is missing")
		return

	_interact_and_finish(mara, &"ashmere_mara_radio", 0)
	_check(WorldState.has_flag(&"mara_contacted"), "Maggie's physical workshop radio unlocks the route cards")
	_interact_and_finish(anchor_card, &"narrative_anchor_commitment", 2)
	await _frames(2)
	_check(StringName(_last_dialogue.get("id", &"")) == &"narrative_anchor_more",
		"the physical work card reaches its witness/copy continuation")
	_finish_active_dialogue(&"narrative_anchor_more", 1)
	_interact_and_finish(strategy_card, &"narrative_strategy_commitment", 2)
	_check(CampaignSystem.get_active_route_id() == &"copy_sever",
		"physical commitments reach the copy/sever campaign")

	var roots: Array[Node] = [ash_root, broadcast_root]
	var ash_job := _find_station(roots, &"copy", 0)
	var ash_mission := &"mission_copy_sever_witness"
	if ash_job == null:
		_fail("copy/sever Ashmere work card is missing")
		return
	_interact_and_finish(ash_job, ash_mission, 0)
	_record_echoes(5)
	WorldState.set_flag(&"entered_ashmere_relay_workshop")
	InventorySystem.add_item(&"analogue_isolator", 1)
	_check(Contracts.is_complete(ash_mission), "copy/sever Ashmere checks can be completed in world state")
	ash_job.interact(null)
	_check(CampaignSystem.get_route_mission_state(ash_mission) == &"complete",
		"copy/sever Ashmere job signs off at its map station")
	_finish_active_dialogue(ash_mission, -1)

	var wrenfield_job := _find_station(roots, &"copy", 1)
	var wrenfield_mission := &"mission_copy_sever_proof"
	if wrenfield_job == null:
		_fail("copy/sever Wrenfield work card is missing")
		return
	_interact_and_finish(wrenfield_job, wrenfield_mission, 0)

	var maggie_echo := _find_memory_echo(broadcast_root, &"echo_maggie_final")
	_check(maggie_echo != null, "Maggie's recorder trace is present for the full route")
	if maggie_echo != null:
		_check(maggie_echo.detect_from(maggie_echo.global_position + Vector2(54, 0)),
			"the flooded-cutting recorder enters Detect")
		_check(maggie_echo.focus_trace(), "the flooded-cutting recorder enters Focus")
		_check(maggie_echo.reveal_trace(), "the flooded-cutting recorder enters Reveal")
		_check(maggie_echo.resolve_trace(ArchiveSystem.VERIFIED),
			"the flooded-cutting recorder can be verified and filed")
	_check(ArchiveSystem.has_echo(&"echo_maggie_final"), "Maggie's recorder reaches the physical archive")

	var recorder := _find_story_node(broadcast_root, &"maggie_cutting_recorder")
	if recorder != null:
		_interact_and_finish(recorder, &"maggie_cutting_recorder", 0)
	_check(WorldState.has_flag(&"maggie_final_proof_recovered"),
		"body, watch and recorder establish Maggie's final proof")
	_check(CampaignSystem.get_evidence_confidence() > 0,
		"the flooded-cutting reveal contributes to narrative evidence")

	InventorySystem.add_item(&"analogue_isolator", 2)
	var hollow := _find_story_node(broadcast_root, &"wrenfield_recoverable_hollow")
	if hollow != null:
		_interact_and_finish(hollow, &"wrenfield_recoverable_hollow", 0)
	_check(CampaignSystem.get_hollow_policy() == &"stabilise",
		"the physical Hollow decision changes the campaign policy")
	_check(CampaignSystem.get_narrative_npc_state(&"nia") == &"rescued",
		"stabilising the recoverable Hollow brings Nia home")

	_check(Contracts.is_complete(wrenfield_mission),
		"copy/sever Wrenfield checks include the filed recorder and remaining isolator")
	wrenfield_job.interact(null)
	_check(CampaignSystem.get_route_mission_state(wrenfield_mission) == &"complete",
		"copy/sever Wrenfield job signs off at its map station")
	_finish_active_dialogue(wrenfield_mission, -1)
	_check(CampaignSystem.are_route_missions_complete(),
		"both exclusive copy/sever jobs are complete before Tollard")

	for trace_id in [&"road_trace_west", &"road_trace_east"]:
		var trace_node := _find_story_node(broadcast_root, trace_id)
		if trace_node != null:
			_interact_and_finish(trace_node, trace_id, 0)
	var west_relay := _find_story_node(broadcast_root, &"broadcast_relay_west")
	if west_relay != null:
		_interact_and_finish(west_relay, &"broadcast_relay_west", 0)
	CampaignSystem.report_field_task(&"east_relay_defense")
	_align_circuit(_circuit_switches(broadcast_root, &"south_line"), &"south_line")
	_check(CampaignSystem.get_restored_relay_count() == 3,
		"investigation, defense and physical circuit open all three Wrenfield lines")
	WorldState.mark_defeated(&"RelayHusk")
	var core_gate := _find_story_node(broadcast_root, &"broadcast_core_gate")
	if core_gate != null:
		_interact_and_finish(core_gate, &"broadcast_core_gate", 0)
	_check(WorldState.has_flag(&"choir_opened"),
		"the production Wrenfield gate accepts the completed route")

	var choir_root := await _load_level(CHOIR_SCENE)
	if choir_root == null:
		return
	var controller := _find_finale_controller(choir_root)
	_check(controller != null, "Tollard instantiates the route finale controller")
	_check(controller != null and StringName(controller.get_meta("route_id", &"")) == &"copy_sever",
		"Tollard finale keeps the committed route id")
	WorldState.mark_defeated(&"ChoirWarden")
	var console := _find_story_node(choir_root, &"choir_final_console")
	if console == null:
		_fail("Tollard Incident Control is missing")
		choir_root.queue_free()
		return
	_interact_and_finish(console, &"choir_final_console", 0)
	_check(WorldState.has_flag(&"route_finale_started"),
		"Incident Control starts the physical final operation")
	_align_circuit(_circuit_switches(choir_root, &"route_finale"), &"route_finale")
	_check(CampaignSystem.is_circuit_complete(&"route_finale"),
		"all three sever-pattern cabinets agree")

	var ending_overlay := ENDING_OVERLAY_SCENE.instantiate()
	add_child(ending_overlay)
	_interact_and_finish(console, &"choir_final_console", 0)
	_check(WorldState.has_flag(&"ending_complete"), "the production console finishes the committed route")
	_check(StringName(WorldState.get_flag(&"ending_id", "")) == &"copy_sever",
		"the saved ending id is the route played")
	_check(StringName(_last_ending.get("route_id", &"")) == &"copy_sever",
		"the ending UI receives the copy/sever outcome")
	var applied_states: Array = _last_ending.get("world_states", [])
	_check(applied_states.size() >= 5, "ending payload includes route and mission world changes")
	for raw_state in applied_states:
		var state_id := StringName(raw_state)
		_check(WorldState.has_flag(state_id), "ending applies aftermath world state %s" % state_id)
	_check(WorldState.has_flag(&"route_aftermath_available"),
		"ending leaves an explorable aftermath available")
	_check(StringName(WorldState.get_flag(&"aftermath_route_id", "")) == &"copy_sever",
		"aftermath records the route that produced it")

	var aftermath_main := AftermathMainFixture.new()
	add_child(aftermath_main)
	aftermath_main.add_to_group("main")
	ending_overlay.call("_on_continue_aftermath")
	_check(WorldState.has_flag(&"route_aftermath_active"),
		"Continue enters the explorable aftermath instead of clearing the run")
	_check(not GameManager.ending_active, "aftermath continuation returns control to play")
	aftermath_main.level_path = GameManager.BASE_SCENE_PATH
	EventBus.level_loaded.emit()
	_check(_saved_level_path() == GameManager.BASE_SCENE_PATH,
		"aftermath continuation saves the Railhome arrival, not the old finale room")
	aftermath_main.free()
	var aftermath_objective := CampaignSystem.get_objective()
	_check("AFTERMATH" in String(aftermath_objective.get("chapter", "")),
		"campaign objectives switch to aftermath exploration")
	ending_overlay.queue_free()
	choir_root.queue_free()
	await _frames(2)


func _saved_level_path() -> String:
	var file := FileAccess.open(SaveManager.SAVE_PATH, FileAccess.READ)
	if file == null:
		return ""
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	return String(parsed.get("level", "")) if typeof(parsed) == TYPE_DICTIONARY else ""


func _check_finale_patterns() -> void:
	var fingerprints: Dictionary = {}
	for strategy in FINALE_PATTERNS:
		_reset_run_state()
		CampaignSystem.commit_route_anchor(&"clinic", false)
		CampaignSystem.commit_network_strategy(strategy, false)
		var choir_root := await _load_level(CHOIR_SCENE)
		if choir_root == null:
			continue
		var controller := _find_finale_controller(choir_root)
		_check(controller != null, "%s finale controller is physically instantiated" % strategy)
		var switches := _circuit_switches(choir_root, &"route_finale")
		_check(switches.size() == 3, "%s finale builds three manual cabinets" % strategy)
		var expected: Dictionary = FINALE_PATTERNS[strategy]
		var fingerprint: Array[String] = []
		for cabinet in switches:
			var switch_id: StringName = cabinet.switch_id
			var required := bool(expected.get(switch_id, not cabinet.required_on))
			_check(cabinet.required_on == required,
				"%s finale gives %s its authored state" % [strategy, switch_id])
			var initial := CampaignSystem.get_circuit_switch_state(
				&"route_finale", switch_id, cabinet.initial_on)
			_check(initial != required,
				"%s/%s begins misaligned and requires a physical throw" % [strategy, switch_id])
			fingerprint.append("%s:%s" % [switch_id, required])
		fingerprint.sort()
		fingerprints["|".join(fingerprint)] = strategy
		WorldState.set_flag(&"route_finale_started")
		_align_circuit(switches, &"route_finale")
		_check(CampaignSystem.is_circuit_complete(&"route_finale"),
			"%s finale can be completed through its three cabinets" % strategy)
		choir_root.queue_free()
		await _frames(2)
	_check(fingerprints.size() == 3, "restore, mesh and sever use three distinct switch patterns")


func _satisfy_contract(mission_id: StringName) -> void:
	for raw_step in Contracts.get_contract(mission_id).get("steps", []):
		var step := Dictionary(raw_step)
		var kind := String(step.get("kind", ""))
		var id := StringName(step.get("id", &""))
		var amount := int(step.get("amount", 1))
		match kind:
			"flag":
				WorldState.set_flag(id)
			"any_flag":
				var candidates: Array = step.get("ids", [])
				if not candidates.is_empty():
					WorldState.set_flag(StringName(candidates[0]))
			"npc":
				CampaignSystem.rescue_narrative_npc(id, false)
			"archive":
				_record_echoes(amount)
			"trace":
				_record_echo(id)
			"item":
				InventorySystem.add_item(id, amount)
			"fed_traces":
				for index in range(amount):
					CampaignSystem.record_trace_fed(
						StringName("contract_fed_%d" % index), true, false)
			"road_traces":
				for index in range(mini(amount, ROAD_FLAGS.size())):
					WorldState.set_flag(ROAD_FLAGS[index])
			"relay_count":
				for index in range(mini(amount, RELAY_FLAGS.size())):
					WorldState.set_flag(RELAY_FLAGS[index])
			"circuit":
				WorldState.set_flag(StringName("circuit_%s_complete" % String(id)))
			"defeated":
				WorldState.mark_defeated(id)


func _record_echoes(amount: int) -> void:
	for echo_id in ARCHIVE_FIXTURES:
		if ArchiveSystem.get_count() >= amount:
			return
		_record_echo(echo_id)


func _record_echo(echo_id: StringName) -> void:
	if ArchiveSystem.has_echo(echo_id):
		return
	var data := EchoDatabase.get_echo(echo_id)
	if data == null:
		_fail("archive fixture is missing: %s" % echo_id)
		return
	ArchiveSystem.record_echo(data, ArchiveSystem.VERIFIED)


func _align_circuit(switches: Array[CircuitSwitch], circuit_id: StringName) -> void:
	for cabinet in switches:
		var current := CampaignSystem.get_circuit_switch_state(
			circuit_id, cabinet.switch_id, cabinet.initial_on)
		if current == cabinet.required_on:
			cabinet.interact(null)
		cabinet.interact(null)


func _interact_and_finish(node: Node, story_id: StringName, choice_index: int) -> void:
	_last_dialogue = {}
	if node == null or not node.has_method("interact"):
		_fail("%s is not a production interactable" % story_id)
		return
	node.call("interact", null)
	_check(GameManager.dialogue_active, "%s opens production dialogue" % story_id)
	_check(StringName(_last_dialogue.get("id", &"")) == story_id,
		"%s sends its own story id to dialogue" % story_id)
	_finish_active_dialogue(story_id, choice_index)


func _finish_active_dialogue(story_id: StringName, choice_index: int) -> void:
	if not GameManager.dialogue_active:
		return
	CampaignSystem.call("_on_dialogue_finished", story_id, choice_index)
	_check(not GameManager.dialogue_active, "%s dialogue returns control to play" % story_id)


func _reset_run_state() -> void:
	GameManager.set_ending_active(false)
	GameManager.set_dialogue_active(false)
	GameManager.set_paused(false)
	WorldState.clear()
	ArchiveSystem.restore([])
	InventorySystem.set_items({})
	CampaignSystem.clear_narrative_state(true)
	_last_dialogue = {}
	_last_ending = {}


func _load_level(path: String) -> Node:
	var scene := load(path) as PackedScene
	if scene == null:
		_fail("map failed to load: %s" % path)
		return null
	var level := scene.instantiate()
	add_child(level)
	await _frames(3)
	return level


func _route_stations(root: Node) -> Array[RouteMissionStation]:
	var stations: Array[RouteMissionStation] = []
	for node in _all_nodes(root):
		if node is RouteMissionStation:
			stations.append(node as RouteMissionStation)
	return stations


func _find_station(
		roots: Array[Node],
		anchor: StringName,
		slot: int,
	) -> RouteMissionStation:
	for root in roots:
		for station in _route_stations(root):
			if StringName(station.required_anchor) == anchor and station.mission_slot == slot:
				return station
	return null


func _circuit_switches(root: Node, circuit_id: StringName) -> Array[CircuitSwitch]:
	var switches: Array[CircuitSwitch] = []
	for node in _all_nodes(root):
		if node is CircuitSwitch and (node as CircuitSwitch).circuit_id == circuit_id:
			switches.append(node as CircuitSwitch)
	switches.sort_custom(func(left: CircuitSwitch, right: CircuitSwitch) -> bool:
		return String(left.switch_id) < String(right.switch_id)
	)
	return switches


func _find_story_node(root: Node, story_id: StringName) -> Node:
	for node in _all_nodes(root):
		if StringName(node.get_meta("story_id", &"")) == story_id:
			return node
	return null


func _find_memory_echo(root: Node, echo_id: StringName) -> MemoryEcho:
	for node in _all_nodes(root):
		if node is MemoryEcho:
			var echo := node as MemoryEcho
			if echo.echo_data != null and echo.echo_data.id == echo_id:
				return echo
	return null


func _find_finale_controller(root: Node) -> RouteFinaleController:
	for node in _all_nodes(root):
		if node is RouteFinaleController:
			return node as RouteFinaleController
	return null


func _find_named_node(root: Node, node_name: String) -> Node:
	if root.name == node_name:
		return root
	return root.find_child(node_name, true, false)


func _all_nodes(root: Node) -> Array[Node]:
	var nodes: Array[Node] = [root]
	for child in root.get_children():
		nodes.append_array(_all_nodes(child))
	return nodes


func _capture_dialogue(payload: Dictionary) -> void:
	_last_dialogue = payload.duplicate(true)


func _capture_ending(payload: Dictionary) -> void:
	_last_ending = payload.duplicate(true)


func _frames(count: int) -> void:
	for _index in range(count):
		await get_tree().process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _fail(message: String) -> void:
	_failures.append(message)
