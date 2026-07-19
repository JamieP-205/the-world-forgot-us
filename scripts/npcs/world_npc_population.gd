class_name WorldNPCPopulation
extends Node2D
## Region-owned population layer. Map geometry only supplies the region id;
## this script owns identities, schedules and relocation without duplicating an
## actor when a scene refreshes its campaign state.

const ACTOR_SCENE := preload("res://scenes/npcs/world_survivor_npc.tscn")
const ACTOR_SCENES := {
	&"leena": preload("res://scenes/npcs/leena_shah.tscn"),
	&"owen": preload("res://scenes/npcs/owen_pryce.tscn"),
	&"doyle": preload("res://scenes/npcs/gwen_doyle.tscn"),
	&"idris": preload("res://scenes/npcs/idris_bell.tscn"),
	&"mara": preload("res://scenes/npcs/mara_venn.tscn"),
	&"tom": preload("res://scenes/npcs/tom_arkwright.tscn"),
	&"nia": preload("res://scenes/npcs/nia_calder.tscn"),
	&"continuity": preload("res://scenes/npcs/continuity_presence.tscn"),
}

const REGION_PLACEMENTS := {
	&"cullbrook": [
		{&"npc_id": &"idris", &"position": Vector2(-430, 238), &"work": Vector2(34, -16), &"ignored": Vector2(92, 44)},
	],
	&"ashmere_verge": [
		{&"npc_id": &"leena", &"position": Vector2(-1040, -390), &"work": Vector2(74, 12), &"ignored": Vector2(-116, 72)},
		{&"npc_id": &"doyle", &"position": Vector2(-975, 470), &"work": Vector2(92, 35), &"ignored": Vector2(-94, 94)},
		{&"npc_id": &"mara", &"position": Vector2(890, -245), &"work": Vector2(84, -28), &"ignored": Vector2(132, 62)},
	],
	&"broadcast_fields": [
		{&"npc_id": &"owen", &"position": Vector2(-1450, -170), &"work": Vector2(76, 44), &"ignored": Vector2(-90, 92)},
		{&"npc_id": &"tom", &"position": Vector2(540, 700), &"work": Vector2(96, 18), &"ignored": Vector2(126, 62)},
	],
	&"choir_core": [
		{&"npc_id": &"continuity", &"position": Vector2(215, -565), &"work": Vector2(-36, 18), &"ignored": Vector2(0, 0), &"mode": "presence"},
	],
	&"railhome": [
		# Each short schedule stays in a furnished bay without crossing a solid
		# footprint or stopping in the carriage's central egress spine.
		{&"npc_id": &"imogen", &"position": Vector2(-520, 64), &"work": Vector2(90, 0), &"settled": Vector2(-20, 0)},
		{&"npc_id": &"rafi", &"position": Vector2(-180, 64), &"work": Vector2(75, 0), &"settled": Vector2(-25, 0)},
		{&"npc_id": &"leena", &"position": Vector2(-50, 64), &"work": Vector2(80, 0), &"settled": Vector2(-20, 0)},
		{&"npc_id": &"owen", &"position": Vector2(250, 64), &"work": Vector2(65, 0), &"settled": Vector2(-20, 0)},
		{&"npc_id": &"doyle", &"position": Vector2(365, 64), &"work": Vector2(55, 0), &"settled": Vector2(-20, 0)},
		{&"npc_id": &"idris", &"position": Vector2(-500, -64), &"work": Vector2(70, 0), &"settled": Vector2(-20, 0)},
		{&"npc_id": &"mara", &"position": Vector2(90, -64), &"work": Vector2(80, 0), &"settled": Vector2(-20, 0)},
		{&"npc_id": &"tom", &"position": Vector2(425, -64), &"work": Vector2(80, 0), &"settled": Vector2(-20, 0)},
		{&"npc_id": &"nia", &"position": Vector2(520, -64), &"work": Vector2(60, 0), &"settled": Vector2(-18, 0)},
	],
}

## Imogen and Rafi retain their authored quest scenes in the field. Listing
## them here lets placement validation prove that every profile has one and
## only one home-region owner without spawning a duplicate actor.
const LEGACY_HOME_OWNERS := {
	&"imogen": &"ashmere_verge",
	&"rafi": &"broadcast_fields",
	&"nia": &"broadcast_fields",
}

@export_enum("cullbrook", "ashmere_verge", "broadcast_fields", "choir_core", "railhome")
var region_id: String = "cullbrook"
@export var auto_populate: bool = true

var _spawned_population_ids: Dictionary = {}


func _ready() -> void:
	add_to_group("npc_populations")
	set_meta("region_id", region_id)
	if auto_populate:
		populate()


func populate() -> void:
	for placement in get_region_placements(StringName(region_id)):
		var npc_id := StringName(placement.get(&"npc_id", &""))
		var profile := WorldNPCCatalog.get_profile(npc_id)
		if profile == null:
			push_warning("NPC population '%s' references unknown profile '%s'." % [region_id, npc_id])
			continue
		var placed_id := StringName("%s:%s" % [String(region_id), String(npc_id)])
		if _spawned_population_ids.has(placed_id) or _tree_has_population_id(placed_id):
			continue
		var actor_scene: PackedScene = ACTOR_SCENES.get(npc_id, ACTOR_SCENE)
		var actor := actor_scene.instantiate() as WorldSurvivorNPC
		if actor == null:
			continue
		actor.name = "%s_%s" % [profile.display_name.replace(" ", ""), String(region_id).to_pascal_case()]
		actor.profile = profile
		actor.population_id = placed_id
		actor.position = placement.get(&"position", Vector2.ZERO)
		actor.location_mode = String(placement.get(&"mode", "settlement" if region_id == "railhome" else "home"))
		actor.schedule_home = Vector2.ZERO
		actor.schedule_work = placement.get(&"work", Vector2(58, -18))
		actor.schedule_settled = placement.get(&"settled", Vector2(-30, 12))
		actor.schedule_ignored = placement.get(&"ignored", Vector2(96, 42))
		_spawned_population_ids[placed_id] = true
		add_child(actor)


func refresh() -> void:
	populate()
	for child in get_children():
		if child is WorldSurvivorNPC:
			child.call("_refresh_state", true)
			child.call("_update_schedule_target", false)


func get_spawned_actors(include_hidden: bool = true) -> Array[WorldSurvivorNPC]:
	var actors: Array[WorldSurvivorNPC] = []
	for child in get_children():
		if child is WorldSurvivorNPC and (include_hidden or child.visible):
			actors.append(child as WorldSurvivorNPC)
	return actors


static func get_region_placements(requested_region: StringName) -> Array[Dictionary]:
	var placements: Array[Dictionary] = []
	for raw_placement in REGION_PLACEMENTS.get(requested_region, []):
		placements.append(Dictionary(raw_placement).duplicate(true))
	return placements


static func validate_placements() -> Array[String]:
	var errors: Array[String] = []
	var home_owners: Dictionary = {}
	for npc_id in LEGACY_HOME_OWNERS:
		home_owners[npc_id] = LEGACY_HOME_OWNERS[npc_id]
	for requested_region in REGION_PLACEMENTS:
		var region_seen: Dictionary = {}
		for placement in get_region_placements(requested_region):
			var npc_id := StringName(placement.get(&"npc_id", &""))
			if npc_id == &"":
				errors.append("%s has a placement without an npc_id" % requested_region)
				continue
			if region_seen.has(npc_id):
				errors.append("%s spawns %s more than once" % [requested_region, npc_id])
			region_seen[npc_id] = true
			var profile := WorldNPCCatalog.get_profile(npc_id)
			if profile == null:
				errors.append("%s placement references unknown %s" % [requested_region, npc_id])
				continue
			if requested_region == profile.home_region:
				if home_owners.has(npc_id):
					errors.append("%s has duplicate home owners %s and %s" % [npc_id, home_owners[npc_id], requested_region])
				else:
					home_owners[npc_id] = requested_region
	for profile in WorldNPCCatalog.all_profiles():
		if not home_owners.has(profile.npc_id):
			errors.append("%s has no field/home placement" % profile.npc_id)
		if profile.relocates_to_railhome and not _region_contains(&"railhome", profile.npc_id):
			errors.append("%s cannot visibly relocate to Railhome" % profile.npc_id)
	return errors


static func _region_contains(requested_region: StringName, npc_id: StringName) -> bool:
	for placement in get_region_placements(requested_region):
		if StringName(placement.get(&"npc_id", &"")) == npc_id:
			return true
	return false


func _tree_has_population_id(placed_id: StringName) -> bool:
	for actor in get_tree().get_nodes_in_group("world_npcs"):
		if StringName(actor.get_meta("population_id", &"")) == placed_id:
			return true
	return false
