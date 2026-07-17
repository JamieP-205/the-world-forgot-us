extends RefCounted
## Playable field requirements for every exclusive route job.
##
## Route prose lives in NarrativeRouteRegistry. This file is deliberately
## mechanical: it ties each job to existing people, interiors, traces,
## circuits, enemies and a tool made at the workbench.

static var CONTRACTS: Dictionary = {
	&"mission_clinic_restore_air": _contract(&"field_dressing", &"imogen_workshop_safe", [
		_step("npc", &"imogen", 1, "Bring Imogen safely out of the clinic"),
		_step("flag", &"entered_ashmere_clinic", 1, "Inspect the clinic rooms"),
		_step("item", &"field_dressing", 1, "Make one field dressing"),
	]),
	&"mission_clinic_mesh_patients": _contract(&"clean_cloth", &"route_job_clinic_ashmere", [
		_step("archive", &"", 4, "Catalogue four physical traces"),
		_step("flag", &"entered_ashmere_terrace_north", 1, "Check Number 14B's paper records"),
		_step("item", &"clean_cloth", 1, "Prepare clean cloth for the patient packets"),
	]),
	&"mission_clinic_sever_one_source": _contract(&"analogue_isolator", &"clinic_power_junction", [
		_step("any_flag", &"clinic_lift_powered", 1, "Commit the ambulance-bay junction", [&"clinic_lift_powered", &"school_backfeed_powered"]),
		_step("flag", &"entered_ashmere_clinic_annex", 1, "Inspect the ambulance annex"),
		_step("item", &"analogue_isolator", 1, "Make an analogue isolator"),
	]),
	&"mission_radio_restore_window": _contract(&"relay_tester", &"bellwether_school_radio", [
		_step("npc", &"rafi", 1, "Bring Rafi onto the warning line"),
		_step("flag", &"entered_bellwether_school", 1, "Reach the Bellwether radio room"),
		_step("item", &"relay_tester", 1, "Make a relay tester"),
	]),
	&"mission_radio_mesh_notes": _contract(&"circuit_bridge", &"route_job_radio_ashmere", [
		_step("archive", &"", 3, "Catalogue three local carrier traces"),
		_step("flag", &"entered_bellwether_school_hall", 1, "Survey the assembly-hall repeater route"),
		_step("item", &"circuit_bridge", 1, "Make a circuit bridge"),
	]),
	&"mission_radio_sever_forecast": _contract(&"analogue_isolator", &"bellwether_school_radio", [
		_step("any_flag", &"helped_rafi", 1, "Resolve Rafi's quarry call", [&"helped_rafi", &"rafi_declined"]),
		_step("flag", &"entered_bellwether_school", 1, "Read the school weather instruments"),
		_step("item", &"analogue_isolator", 1, "Make an analogue isolator"),
	]),
	&"mission_witness_restore_sources": _contract(&"lock_shim", &"route_job_witness_ashmere", [
		_step("npc", &"leena", 1, "Win Leena's help"),
		_step("archive", &"", 4, "Catalogue four sourced traces"),
		_step("item", &"lock_shim", 1, "Make a lock shim for the records cage"),
	]),
	&"mission_witness_mesh_signatures": _contract(&"wire_splicer", &"route_job_witness_ashmere", [
		_step("npc", &"leena", 1, "Win Leena's signature"),
		_step("npc", &"doyle", 1, "Win Gwen Doyle's signature"),
		_step("item", &"wire_splicer", 1, "Make a wire splicer for the packet lamp"),
	]),
	&"mission_witness_sever_unlisted": _contract(&"signal_decoy", &"route_job_witness_ashmere", [
		_step("npc", &"leena", 1, "Ask Leena to hold the unlisted names"),
		_step("flag", &"entered_ashmere_terrace_south", 1, "Find the safe-house hand-off"),
		_step("item", &"signal_decoy", 1, "Make a signal decoy for the false trail"),
	]),
	&"mission_copy_restore_teach": _contract(&"analogue_isolator", &"ashmere_mara_radio", [
		_step("fed_traces", &"", 1, "Let the copied voice hear one private trace"),
		_step("archive", &"", 4, "Hold four traces for comparison"),
		_step("item", &"analogue_isolator", 1, "Make an isolator for the teaching set"),
	]),
	&"mission_copy_mesh_separate": _contract(&"circuit_bridge", &"route_job_copy_ashmere", [
		_step("archive", &"", 4, "Catalogue four distinct voices"),
		_step("flag", &"entered_ashmere_relay_workshop", 1, "Inspect Maggie's receiver benches"),
		_step("item", &"circuit_bridge", 1, "Make a bridge for the partition test"),
	]),
	&"mission_copy_sever_witness": _contract(&"analogue_isolator", &"route_job_copy_ashmere", [
		_step("archive", &"", 5, "Hold five traces against the copied claim"),
		_step("flag", &"entered_ashmere_relay_workshop", 1, "Find Maggie's verification notes"),
		_step("item", &"analogue_isolator", 1, "Make an isolator for the isolated test"),
	]),

	&"mission_clinic_restore_clean_line": _contract(&"shielded_fuse", &"broadcast_defense_anchor", [
		_step("flag", &"east_relay_defense_complete", 1, "Hold the east clinic carrier"),
		_step("flag", &"entered_wrenfield_antenna_bunker", 1, "Inspect the east antenna bunker"),
		_step("item", &"shielded_fuse", 1, "Make a shielded fuse"),
	]),
	&"mission_clinic_mesh_cold_chain": _contract(&"field_dressing", &"route_job_clinic_wrenfield", [
		_step("relay_count", &"", 2, "Restore two verified line relays"),
		_step("flag", &"entered_wrenfield_generator_hall", 1, "Survey the generator cold room"),
		_step("item", &"field_dressing", 1, "Pack one sealed field dressing"),
	]),
	&"mission_clinic_sever_carry_out": _contract(&"tripwire_alarm", &"route_job_clinic_wrenfield", [
		_step("defeated", &"RelayHusk", 1, "Clear the Linesman from the evacuation road"),
		_step("flag", &"entered_wrenfield_antenna_bunker", 1, "Open the east patient shelter"),
		_step("item", &"tripwire_alarm", 1, "Make a tripwire alarm for the rear guard"),
	]),
	&"mission_radio_restore_hold": _contract(&"signal_decoy", &"long_acre_repeater", [
		_step("flag", &"east_relay_defense_complete", 1, "Hold a live carrier through the surge"),
		_step("flag", &"public_repeater", 1, "Wire the public warning repeater"),
		_step("item", &"signal_decoy", 1, "Make a signal decoy for the transmission deck"),
	]),
	&"mission_radio_mesh_convoy": _contract(&"hand_flare", &"route_job_radio_wrenfield", [
		_step("npc", &"tom", 1, "Bring Tom Arkwright into the convoy plan"),
		_step("circuit", &"south_line", 1, "Align the south service circuit"),
		_step("item", &"hand_flare", 1, "Make a hand flare for the ash crossing"),
	]),
	&"mission_radio_sever_no_repeat": _contract(&"carrier_grounder", &"long_acre_repeater", [
		_step("flag", &"public_repeater_declined", 1, "Remove the public repeater's last fuse"),
		_step("circuit", &"south_line", 1, "Ground the south service circuit"),
		_step("item", &"carrier_grounder", 1, "Make a carrier grounder"),
	]),
	&"mission_witness_restore_name": _contract(&"clean_cloth", &"route_job_witness_wrenfield", [
		_step("npc", &"owen", 1, "Win Owen Pryce's deposition"),
		_step("road_traces", &"", 2, "Verify two contradictory road records"),
		_step("item", &"clean_cloth", 1, "Wrap the paper record in clean cloth"),
	]),
	&"mission_witness_mesh_packet": _contract(&"wire_splicer", &"route_job_witness_wrenfield", [
		_step("npc", &"owen", 1, "Bring Owen into the hand-off"),
		_step("circuit", &"south_line", 1, "Open the manual south packet route"),
		_step("item", &"wire_splicer", 1, "Make a wire splicer for the packet lamp"),
	]),
	&"mission_witness_sever_beacon": _contract(&"signal_decoy", &"route_job_witness_wrenfield", [
		_step("npc", &"owen", 1, "Ask Owen which names can safely travel"),
		_step("flag", &"relay_west_restored", 1, "Verify the west cable-house line"),
		_step("item", &"signal_decoy", 1, "Make a decoy for the identity beacon"),
	]),
	&"mission_copy_restore_test": _contract(&"relay_tester", &"route_job_copy_wrenfield", [
		_step("relay_count", &"", 3, "Bring all three manual relays online"),
		_step("fed_traces", &"", 1, "Let the copied voice learn one private trace"),
		_step("item", &"relay_tester", 1, "Make a relay tester for the false prompt"),
	]),
	&"mission_copy_mesh_answers": _contract(&"circuit_bridge", &"route_job_copy_wrenfield", [
		_step("road_traces", &"", 2, "Verify two local route records"),
		_step("circuit", &"south_line", 1, "Align the local-cell circuit"),
		_step("item", &"circuit_bridge", 1, "Make a bridge for the bounded sync"),
	]),
	&"mission_copy_sever_proof": _contract(&"analogue_isolator", &"maggie_cutting_recorder", [
		_step("flag", &"maggie_final_proof_recovered", 1, "Recover Maggie's recorder at the flooded cutting"),
		_step("trace", &"echo_maggie_final", 1, "Catalogue the recorder's physical trace"),
		_step("item", &"analogue_isolator", 1, "Make an isolator for the shutdown phrase"),
	]),
}


static func _step(
		kind: String,
		id: StringName,
		amount: int,
		label: String,
		ids: Array[StringName] = [],
	) -> Dictionary:
	return {"kind": kind, "id": id, "amount": amount, "label": label, "ids": ids}


static func _contract(cost_item: StringName, target: StringName, steps: Array) -> Dictionary:
	return {"cost_item": cost_item, "target": target, "steps": steps}


static func get_contract(mission_id: StringName) -> Dictionary:
	return Dictionary(CONTRACTS.get(mission_id, {})).duplicate(true)


static func all_mission_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(CONTRACTS.keys())
	ids.sort()
	return ids


static func unmet_steps(mission_id: StringName) -> Array[Dictionary]:
	var unmet: Array[Dictionary] = []
	for raw_step in get_contract(mission_id).get("steps", []):
		var step := Dictionary(raw_step)
		if not _step_met(step, mission_id):
			unmet.append(step)
	return unmet


static func is_complete(mission_id: StringName) -> bool:
	return not get_contract(mission_id).is_empty() and unmet_steps(mission_id).is_empty()


static func completion_target(mission_id: StringName) -> StringName:
	return StringName(get_contract(mission_id).get("target", &""))


static func consume_completion_cost(mission_id: StringName) -> bool:
	var item_id := StringName(get_contract(mission_id).get("cost_item", &""))
	return item_id == &"" \
		or _consume_reserved_tool(mission_id, item_id) \
		or InventorySystem.remove_item(item_id, 1)


static func progress_text(mission_id: StringName) -> String:
	var contract := get_contract(mission_id)
	var total := Array(contract.get("steps", [])).size()
	var remaining := unmet_steps(mission_id).size()
	return "FIELD CHECKS %d / %d" % [total - remaining, total]


static func unmet_summary(mission_id: StringName, maximum: int = 3) -> String:
	var lines: Array[String] = []
	for step in unmet_steps(mission_id).slice(0, maximum):
		lines.append("- %s" % String(step.get("label", "Finish the field work")))
	return "\n".join(lines)


static func validate(route_mission_ids: Array[StringName]) -> Array[String]:
	var errors: Array[String] = []
	for mission_id in route_mission_ids:
		var contract := get_contract(mission_id)
		if contract.is_empty():
			errors.append("%s has no playable field contract" % mission_id)
			continue
		if StringName(contract.get("target", &"")) == &"":
			errors.append("%s has no production target" % mission_id)
		if StringName(contract.get("cost_item", &"")) == &"":
			errors.append("%s has no crafted field tool" % mission_id)
		if Array(contract.get("steps", [])).size() < 3:
			errors.append("%s has fewer than three field checks" % mission_id)
	for mission_id in all_mission_ids():
		if mission_id not in route_mission_ids:
			errors.append("orphan field contract %s" % mission_id)
	return errors


static func _step_met(step: Dictionary, mission_id: StringName = &"") -> bool:
	var kind := String(step.get("kind", ""))
	var id := StringName(step.get("id", &""))
	var amount := int(step.get("amount", 1))
	var campaign := _campaign_system()
	match kind:
		"flag":
			return WorldState.has_flag(id)
		"any_flag":
			for candidate in step.get("ids", []):
				if WorldState.has_flag(StringName(candidate)):
					return true
			return false
		"npc":
			return campaign != null \
				and StringName(campaign.call("get_narrative_npc_state", id)) == &"rescued"
		"archive":
			return ArchiveSystem.get_count() >= amount
		"trace":
			return ArchiveSystem.has_echo(id)
		"item":
			return InventorySystem.get_count(id) >= amount \
				or _has_reserved_tool(mission_id, id, amount)
		"fed_traces":
			return campaign != null and int(campaign.call("get_fed_trace_count")) >= amount
		"road_traces":
			return campaign != null and int(campaign.call("get_road_trace_count")) >= amount
		"relay_count":
			return campaign != null and int(campaign.call("get_restored_relay_count")) >= amount
		"circuit":
			return campaign != null and bool(campaign.call("is_circuit_complete", id))
		"defeated":
			return WorldState.is_defeated(id)
	return false


## Keep the mission ledger independent of the recovery helper. CampaignSystem
## loads this contract table while the recovery helper calls back into the
## campaign, so sharing the tiny escrow convention here avoids a script cycle.
static func _has_reserved_tool(
		mission_id: StringName,
		item_id: StringName,
		amount: int = 1,
	) -> bool:
	return amount <= 1 \
		and StringName(str(WorldState.get_flag(_escrow_flag(mission_id), ""))) == item_id


static func _consume_reserved_tool(mission_id: StringName, item_id: StringName) -> bool:
	if not _has_reserved_tool(mission_id, item_id):
		return false
	WorldState.set_flag(_escrow_flag(mission_id), false)
	return true


static func _escrow_flag(mission_id: StringName) -> StringName:
	return StringName("route_salvage_reserved_%s" % String(mission_id))


static func _campaign_system() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.root.get_node_or_null("CampaignSystem") if tree != null else null
