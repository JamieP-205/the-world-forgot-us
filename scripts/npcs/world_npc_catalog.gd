class_name WorldNPCCatalog
extends RefCounted
## Canonical resources for the ten people/presences the player can follow,
## abandon, and later find changed at Railhome or Tollard.

const NPCServiceRulesScript = preload("res://scripts/narrative/npc_service_rules.gd")

const PROFILES := {
	&"imogen": preload("res://resources/npcs/imogen_bell.tres"),
	&"rafi": preload("res://resources/npcs/rafi_sayeed.tres"),
	&"leena": preload("res://resources/npcs/leena_shah.tres"),
	&"owen": preload("res://resources/npcs/owen_pryce.tres"),
	&"doyle": preload("res://resources/npcs/gwen_doyle.tres"),
	&"idris": preload("res://resources/npcs/idris_bell.tres"),
	&"mara": preload("res://resources/npcs/mara_venn.tres"),
	&"tom": preload("res://resources/npcs/tom_arkwright.tres"),
	&"nia": preload("res://resources/npcs/nia_calder.tres"),
	&"continuity": preload("res://resources/npcs/continuity_presence.tres"),
}


static func all_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for npc_id in PROFILES:
		ids.append(StringName(npc_id))
	ids.sort()
	return ids


static func get_profile(npc_id: StringName) -> WorldNPCProfile:
	return PROFILES.get(npc_id) as WorldNPCProfile


static func all_profiles() -> Array[WorldNPCProfile]:
	var profiles: Array[WorldNPCProfile] = []
	for npc_id in all_ids():
		profiles.append(get_profile(npc_id))
	return profiles


static func validate() -> Array[String]:
	var errors: Array[String] = []
	var names: Dictionary = {}
	var voices: Dictionary = {}
	var services: Dictionary = {}
	var story_ids: Dictionary = {}
	var atlases: Dictionary = {}
	var silhouettes: Dictionary = {}
	for npc_id in all_ids():
		var profile := get_profile(npc_id)
		if profile == null:
			errors.append("%s profile could not be loaded" % npc_id)
			continue
		errors.append_array(profile.validate())
		if not NPCServiceRulesScript.has_production_consumer(profile.service_id):
			errors.append("%s service %s has no production consumer" % [npc_id, profile.service_id])
		_check_unique(names, profile.display_name, npc_id, "display name", errors)
		_check_unique(voices, profile.voice_signature, npc_id, "voice signature", errors)
		_check_unique(services, String(profile.service_id), npc_id, "service", errors)
		_check_unique(story_ids, String(profile.story_id()), npc_id, "story id", errors)
		if profile.sprite_atlas != null:
			_check_unique(atlases, profile.sprite_atlas.resource_path, npc_id, "sprite atlas", errors)
		_check_unique(silhouettes, profile.silhouette_signature, npc_id, "silhouette signature", errors)
	return errors


static func _check_unique(
		seen: Dictionary,
		value: String,
		npc_id: StringName,
		label: String,
		errors: Array[String]) -> void:
	if value.is_empty():
		return
	if seen.has(value):
		errors.append("%s duplicates %s '%s' from %s" % [npc_id, label, value, seen[value]])
	else:
		seen[value] = String(npc_id)
