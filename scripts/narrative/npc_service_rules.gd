class_name NPCServiceRules
extends RefCounted
## Production consequences for the ten survivor services.
##
## WorldSurvivorNPC owns the conversation and durable flags. This class is
## the single balance contract used by movement, the receiver, circuits,
## caches, travel and enemy behaviour after those flags have been earned.

const MAX_EVIDENCE_COUNT := 14

const SERVICE_FLAGS := {
	&"field_triage": &"npc_service_imogen_triage",
	&"carrier_forecast": &"npc_service_rafi_forecast",
	&"witness_ledger": &"npc_service_leena_ledger",
	&"grid_survey": &"npc_service_owen_grid",
	&"coach_passages": &"npc_service_doyle_passages",
	&"shelter_repair": &"npc_service_idris_repair",
	&"lockwork": &"npc_service_mara_lockwork",
	&"wire_warning": &"npc_service_tom_warning",
	&"field_defence": &"npc_service_nia_defence",
	&"identity_checksum": &"npc_service_continuity_checksum",
}

const EFFECT_NOTICES := {
	&"field_triage": "Health restored in full.",
	&"carrier_forecast": "Receiver sweeps now use 18% less charge.",
	&"witness_ledger": "The ledger adds one corroboration step and extends evidence sweeps by 12%.",
	&"grid_survey": "Owen's score sets each untouched circuit contact correctly; open-ground pace rises by 8%.",
	&"coach_passages": "Gwen's passage cuts incoming harm by 10%, improves road pace, and marks extra supplies in her coach cache.",
	&"shelter_repair": "Each wounded return to Railhome now restores up to 25 health.",
	&"lockwork": "Mara's numbered bypass opens the secured archive drawer inside Tollard.",
	&"wire_warning": "Mimics stay visible while stalking and take 45% longer to commit to a lunge.",
	&"field_defence": "Hollows enter receiver sweeps; Nia's lure cuts their detection reach and contact damage by 20%.",
	&"identity_checksum": "The checksum lowers receiver drain by 8% and will be attached to the final incident record.",
}


static func is_active(service_id: StringName) -> bool:
	var flag: StringName = SERVICE_FLAGS.get(service_id, &"")
	return flag != &"" and WorldState.has_flag(flag)


static func has_production_consumer(service_id: StringName) -> bool:
	return SERVICE_FLAGS.has(service_id) and EFFECT_NOTICES.has(service_id)


static func effect_notice(service_id: StringName) -> String:
	return String(EFFECT_NOTICES.get(service_id, ""))


## Multiplies the route balance value with bounded, service-specific help.
static func gameplay_value(rule_id: StringName, route_value: float = 1.0) -> float:
	var result := route_value
	match rule_id:
		&"scanner_energy":
			if is_active(&"carrier_forecast"):
				result *= 0.82
			if is_active(&"identity_checksum"):
				result *= 0.92
		&"scan_range":
			if is_active(&"witness_ledger"):
				result *= 1.12
			if is_active(&"field_defence"):
				result *= 1.08
		&"move_speed":
			if is_active(&"grid_survey"):
				result *= 1.08
			if is_active(&"coach_passages"):
				result *= 1.04
		&"dodge_speed":
			if is_active(&"grid_survey"):
				result *= 1.06
		&"damage_taken":
			if is_active(&"coach_passages"):
				result *= 0.90
	return clampf(result, 0.65, 1.50)


static func effective_evidence_confidence(base_count: int) -> int:
	var ledger_step := 1 if is_active(&"witness_ledger") else 0
	return clampi(base_count + ledger_step, 0, MAX_EVIDENCE_COUNT)


static func railhome_recovery_amount() -> float:
	if not is_active(&"shelter_repair"):
		return 0.0
	return clampf(float(WorldState.get_flag(&"railhome_recovery_bonus", 25)), 0.0, 25.0)


static func can_open_secured_cache(required_flag: StringName) -> bool:
	return required_flag == &"" or WorldState.has_flag(required_flag)


static func has_grid_survey_for(route_id: StringName) -> bool:
	if not is_active(&"grid_survey"):
		return false
	var surveyed_route := StringName(WorldState.get_flag(&"npc_service_safe_grid_route", ""))
	return surveyed_route == &"" or route_id == &"" or surveyed_route == route_id


static func mimic_windup_duration(base_duration: float) -> float:
	return base_duration * (1.45 if is_active(&"wire_warning") else 1.0)


static func mimic_visibility_alpha(dormant: bool, base_alpha: float) -> float:
	if not is_active(&"wire_warning"):
		return base_alpha
	return maxf(base_alpha, 0.36 if dormant else 0.82)


static func hollow_tracking_active() -> bool:
	return is_active(&"field_defence") and WorldState.has_flag(&"hollow_tracking_active")


static func hollow_detection_radius(base_radius: float) -> float:
	return base_radius * (0.80 if is_active(&"field_defence") else 1.0)


static func hollow_contact_damage(base_damage: float) -> float:
	return base_damage * (0.80 if is_active(&"field_defence") else 1.0)


static func identity_checksum_line() -> String:
	if not is_active(&"identity_checksum"):
		return ""
	var stored: Variant = WorldState.get_flag(&"identity_checksum", {})
	if not stored is Dictionary:
		return "Continuity's checksum remains unresolved and is filed as such."
	var checksum: Dictionary = stored
	var evidence := int(checksum.get("evidence_confidence", 0))
	var fed_traces := int(checksum.get("fed_traces", 0))
	if fed_traces >= 3:
		return "Continuity's checksum records %d corroborated points, but %d private traces make a clean identity claim unsafe." % [evidence, fed_traces]
	if evidence >= 8:
		return "Continuity's checksum records %d corroborated points and still labels Maggie's identity unresolved." % evidence
	return "Continuity's checksum finds only %d corroborated points and refuses to call the receiver voice Maggie." % evidence


static func ending_lines(base_evidence_count: int) -> Array[String]:
	var lines: Array[String] = []
	if is_active(&"witness_ledger"):
		lines.append("Leena's witness ledger raises the usable evidence chain from %d to %d corroboration steps." % [
			base_evidence_count, effective_evidence_confidence(base_evidence_count),
		])
	var checksum_line := identity_checksum_line()
	if not checksum_line.is_empty():
		lines.append(checksum_line)
	return lines
