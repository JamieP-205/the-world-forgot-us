class_name WorldNPCProfile
extends Resource
## Authored identity and behaviour contract for a survivor in the world.
##
## Placement remains map-owned. This resource owns why the person is there,
## how they speak, what practical help they provide, and which durable flags
## move them from their home location to Railhome.

@export var npc_id: StringName = &""
@export var display_name: String = "Survivor"
@export var role: String = ""
@export_multiline var story_reason: String = ""
@export var home_region: StringName = &""

@export_category("Service")
@export var service_id: StringName = &""
@export var service_name: String = ""
@export_multiline var service_description: String = ""
@export var service_flag: StringName = &""
@export var service_choice: String = "ASK FOR HELP"
@export var service_notice: String = ""

@export_category("Persistence")
@export var helped_flag: StringName = &""
@export var ignored_flag: StringName = &""
@export var legacy_helped_flag: StringName = &""
@export var relocates_to_railhome: bool = true

@export_category("Voice")
@export var voice_signature: String = ""
@export_multiline var greeting: String = ""
@export var intro_lines: Array[String] = []
@export var helped_lines: Array[String] = []
@export var ignored_lines: Array[String] = []
@export var service_lines: Array[String] = []
@export var anchor_lines: Dictionary = {}
@export var strategy_lines: Dictionary = {}
@export var help_choice: String = "OFFER A HAND"
@export var ignore_choice: String = "LEAVE THEM HERE"

@export_category("Visual Identity")
@export var sprite_atlas: Texture2D
@export var silhouette_signature: String = ""
@export_multiline var visual_notes: String = ""
@export var identity_accent: Color = Color(0.9, 0.65, 0.25, 1.0)


func story_id() -> StringName:
	return StringName("world_npc_%s" % String(npc_id))


func state_flag(suffix: String) -> StringName:
	return StringName("npc_%s_%s" % [String(npc_id), suffix])


func validate() -> Array[String]:
	var errors: Array[String] = []
	if npc_id == &"": errors.append("missing npc_id")
	if display_name.strip_edges().is_empty(): errors.append("%s has no name" % npc_id)
	if story_reason.strip_edges().is_empty(): errors.append("%s has no reason to exist in the world" % npc_id)
	if home_region == &"": errors.append("%s has no home region" % npc_id)
	if service_id == &"" or service_flag == &"": errors.append("%s has no durable service" % npc_id)
	if voice_signature.strip_edges().is_empty(): errors.append("%s has no voice signature" % npc_id)
	if intro_lines.size() < 2: errors.append("%s needs at least two introduction lines" % npc_id)
	if helped_lines.is_empty() or ignored_lines.is_empty(): errors.append("%s needs helped and ignored consequences" % npc_id)
	if anchor_lines.size() < 4: errors.append("%s does not react to all route anchors" % npc_id)
	if strategy_lines.size() < 3: errors.append("%s does not react to all network strategies" % npc_id)
	if sprite_atlas == null:
		errors.append("%s has no authored sprite atlas" % npc_id)
	else:
		var atlas_size := sprite_atlas.get_size()
		if atlas_size.x != atlas_size.y or atlas_size.x < 1024.0:
			errors.append("%s atlas is not a production square four-by-four sheet" % npc_id)
	if silhouette_signature.strip_edges().is_empty(): errors.append("%s has no silhouette signature" % npc_id)
	if visual_notes.strip_edges().length() < 40: errors.append("%s visual identity is not documented" % npc_id)
	return errors
