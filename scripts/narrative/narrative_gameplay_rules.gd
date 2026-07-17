class_name NarrativeGameplayRules
extends RefCounted
## Numerical play consequences for every authored route modifier.
## Values multiply, then CampaignSystem clamps them to a safe range.

const EFFECTS := {
	&"medical_routing": {&"healing": 1.18},
	&"treatment_channel_defence": {&"damage_taken": 0.92},
	&"hollow_stabiliser_supply": {&"scan_range": 1.10},
	&"medical_couriers": {&"move_speed": 1.06},
	&"local_treatment_nodes": {&"healing": 1.12},
	&"identity_router_removed": {&"damage_taken": 0.96},
	&"evacuation_priority": {&"move_speed": 1.08},
	&"battery_gallery_demolition": {&"outgoing_damage": 1.12},
	&"limited_medicine": {&"healing": 0.88},
	&"regional_weather": {&"scan_range": 1.12},
	&"radio_decoys": {&"damage_taken": 0.94},
	&"gantry_defence": {&"outgoing_damage": 1.08},
	&"short_range_repeaters": {&"scanner_energy": 0.88},
	&"convoy_guidance": {&"move_speed": 1.06},
	&"roof_cell_traversal": {&"dodge_speed": 1.12},
	&"timed_last_broadcast": {&"outgoing_damage": 1.10},
	&"carrier_fuse_demolition": {&"scanner_energy": 0.90},
	&"pursuit_escape": {&"move_speed": 1.10},
	&"evidence_upload": {&"scan_range": 1.14},
	&"archive_credentials": {&"scanner_energy": 0.90},
	&"public_accountability": {&"outgoing_damage": 1.06},
	&"witness_challenges": {&"scan_range": 1.08},
	&"physical_packet_keys": {&"move_speed": 1.04},
	&"coordinated_manual_switches": {&"dodge_speed": 1.08},
	&"identity_core_stealth": {&"damage_taken": 0.90},
	&"tracked_hollow_release": {&"scanner_energy": 0.92},
	&"record_salvage_limit": {&"scanner_energy": 1.08},
	&"voice_lock_access": {&"scan_range": 1.09},
	&"directed_hollow_standdown": {&"damage_taken": 0.90},
	&"continuity_rule_negotiation": {&"healing": 1.05},
	&"local_copy_companions": {&"move_speed": 1.06},
	&"partition_sync": {&"scanner_energy": 0.88},
	&"bounded_voice_abilities": {&"outgoing_damage": 1.07},
	&"shutdown_negotiation": {&"damage_taken": 0.94},
	&"west_crawl_access": {&"dodge_speed": 1.15},
	&"conditional_escape": {&"move_speed": 1.08},
	&"evidence_unsteady": {&"scan_range": 0.94},
	&"evidence_corroborated": {&"scan_range": 1.04},
	&"evidence_supported": {&"scan_range": 1.08},
	&"hollows_stabilise": {&"damage_taken": 0.96},
	&"hollows_kill": {&"outgoing_damage": 1.05},
	&"hollows_weaponise": {&"scan_range": 1.06},
	&"copy_intimate": {&"scan_range": 1.05},
	&"copy_learning": {&"scanner_energy": 0.96},
	&"copy_unfed": {&"scanner_energy": 1.04},
}


static func value(modifiers: Array[StringName], rule_id: StringName, fallback: float = 1.0) -> float:
	var result := fallback
	for modifier_id in modifiers:
		var effects: Dictionary = EFFECTS.get(modifier_id, {})
		if effects.has(rule_id):
			result *= float(effects[rule_id])
		elif String(modifier_id).begins_with("service_"):
			result *= _service_value(String(modifier_id).trim_prefix("service_"), rule_id)
		elif String(modifier_id).begins_with("ally_") and rule_id == &"move_speed":
			result *= 1.01
	return clampf(result, 0.72, 1.42)


static func _service_value(service_id: String, rule_id: StringName) -> float:
	if rule_id == &"healing" and _contains_any(service_id, ["medical", "patient", "triage", "infirmary", "treatment"]):
		return 1.08
	if rule_id == &"move_speed" and _contains_any(service_id, ["courier", "convoy", "routes", "packet", "forecast"]):
		return 1.05
	if rule_id == &"scan_range" and _contains_any(service_id, ["ledger", "archive", "witness", "copy", "voice", "guidance"]):
		return 1.06
	if rule_id == &"outgoing_damage" and _contains_any(service_id, ["fuse", "purge", "shutdown", "contradiction"]):
		return 1.05
	return 1.015 if rule_id == &"healing" else 1.0


static func _contains_any(value: String, needles: Array[String]) -> bool:
	for needle in needles:
		if needle in value:
			return true
	return false


static func validate(route_modifiers: Array[StringName]) -> Array[String]:
	var errors: Array[String] = []
	for modifier_id in route_modifiers:
		if not EFFECTS.has(modifier_id):
			errors.append("route gameplay modifier %s has no production rule" % modifier_id)
		elif Dictionary(EFFECTS[modifier_id]).is_empty():
			errors.append("route gameplay modifier %s has an empty production rule" % modifier_id)
	return errors
