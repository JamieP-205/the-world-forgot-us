extends Node
## Headless contract for authored survivor identity, route reactivity,
## placement ownership, visible decisions and WorldState persistence.

const PopulationScene := preload("res://scenes/npcs/world_npc_population.tscn")
const ExpectedIDs: Array[StringName] = [
	&"continuity", &"doyle", &"idris", &"imogen", &"leena",
	&"mara", &"nia", &"owen", &"rafi", &"tom",
]

var _failures: Array[String] = []


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var world_before := WorldState.get_state()
	var narrative_before := CampaignSystem.get_narrative_state()
	WorldState.clear()
	CampaignSystem.clear_narrative_state(false)
	_check_catalog()
	_check_identity_atlases()
	_check_scene_identities()
	await _check_population_placements()
	await _check_route_reactivity()
	await _check_persistent_consequences()
	WorldState.restore(world_before)
	CampaignSystem.restore_narrative_state(narrative_before, SaveManager.SAVE_VERSION)
	GameManager.set_dialogue_active(false)
	if _failures.is_empty():
		print("NPC_POPULATION_SMOKE: PASS")
		get_tree().quit(0)
		return
	for failure in _failures:
		push_error("NPC_POPULATION_SMOKE: " + failure)
	print("NPC_POPULATION_SMOKE: FAIL (%d)" % _failures.size())
	get_tree().quit(1)


func _check_catalog() -> void:
	for error in WorldNPCCatalog.validate():
		_fail("catalog: " + error)
	for error in WorldNPCPopulation.validate_placements():
		_fail("placement: " + error)
	var actual_ids := WorldNPCCatalog.all_ids()
	_check(actual_ids.size() == ExpectedIDs.size(), "catalog exposes ten ids")
	for expected_id in ExpectedIDs:
		_check(expected_id in actual_ids, "catalog exposes intended id %s" % expected_id)

	var names: Dictionary = {}
	var voices: Dictionary = {}
	var services: Dictionary = {}
	var atlas_paths: Dictionary = {}
	var silhouettes: Dictionary = {}
	for profile in WorldNPCCatalog.all_profiles():
		_check(not names.has(profile.display_name), "%s has a unique display name" % profile.npc_id)
		_check(not voices.has(profile.voice_signature), "%s has a unique voice" % profile.npc_id)
		_check(not services.has(profile.service_id), "%s has a unique service" % profile.npc_id)
		var atlas_path := profile.sprite_atlas.resource_path if profile.sprite_atlas != null else ""
		_check(not atlas_path.is_empty(), "%s binds an authored atlas" % profile.npc_id)
		_check(not atlas_paths.has(atlas_path), "%s does not reuse another person's atlas" % profile.npc_id)
		_check(not silhouettes.has(profile.silhouette_signature), "%s has a unique silhouette contract" % profile.npc_id)
		_check(profile.story_reason.length() > 80, "%s has a concrete story reason" % profile.npc_id)
		_check(profile.service_description.length() > 30, "%s service states a gameplay purpose" % profile.npc_id)
		_check(profile.anchor_lines.size() == 4 and profile.strategy_lines.size() == 3, "%s reacts to every route axis" % profile.npc_id)
		names[profile.display_name] = true
		voices[profile.voice_signature] = true
		services[profile.service_id] = true
		atlas_paths[atlas_path] = true
		silhouettes[profile.silhouette_signature] = true


func _check_identity_atlases() -> void:
	var file_hashes: Dictionary = {}
	for profile in WorldNPCCatalog.all_profiles():
		if profile.sprite_atlas == null:
			continue
		var path := profile.sprite_atlas.resource_path
		var digest := FileAccess.get_sha256(path)
		_check(not digest.is_empty(), "%s atlas can be hashed" % profile.npc_id)
		_check(not file_hashes.has(digest), "%s atlas pixels are unique" % profile.npc_id)
		file_hashes[digest] = String(profile.npc_id)
		var image := profile.sprite_atlas.get_image()
		_check(image != null and not image.is_empty(), "%s atlas image is readable" % profile.npc_id)
		if image == null or image.is_empty():
			continue
		_check(image.get_width() == image.get_height() and image.get_width() >= 1024, "%s atlas is a production square sheet" % profile.npc_id)
		_check(image.get_pixel(0, 0).a < 0.02, "%s atlas has transparent outer padding" % profile.npc_id)
		for row in range(4):
			for column in range(4):
				var occupied := 0
				var x0 := int(column * image.get_width() / 4.0)
				var x1 := int((column + 1) * image.get_width() / 4.0)
				var y0 := int(row * image.get_height() / 4.0)
				var y1 := int((row + 1) * image.get_height() / 4.0)
				for y in range(y0, y1, 8):
					for x in range(x0, x1, 8):
						if image.get_pixel(x, y).a > 0.1:
							occupied += 1
				_check(occupied > 120, "%s direction %d frame %d contains an authored figure" % [profile.npc_id, row, column])

	var body_texture := load("res://assets/generated/npcs/maggie_cutting_body.png") as Texture2D
	_check(body_texture != null, "Maggie's flooded-cutting body sprite loads")
	if body_texture != null:
		var body := body_texture.get_image()
		_check(body != null and not body.is_empty(), "Maggie's body sprite has readable pixels")
		if body != null and not body.is_empty():
			_check(body.get_width() > body.get_height(), "Maggie's body sprite has a distinct horizontal silhouette")
			_check(body.get_pixel(0, 0).a < 0.02, "Maggie's body sprite has transparent outer padding")

	var actor_source := FileAccess.get_file_as_string("res://scripts/npcs/world_survivor_npc.gd")
	var quest_source := FileAccess.get_file_as_string("res://scripts/npcs/survivor_npc.gd")
	_check("IdentityAccessory" not in actor_source and "IdentityAccessory" not in quest_source, "identity is authored into atlases instead of procedural overlays")
	_check("IMOGEN_TEXTURE" not in actor_source and "RAFI_TEXTURE" not in actor_source, "world actors do not fall back to clone families")


func _check_scene_identities() -> void:
	var scene_contracts := {
		"res://scenes/npcs/leena_shah.tscn": &"leena",
		"res://scenes/npcs/owen_pryce.tscn": &"owen",
		"res://scenes/npcs/gwen_doyle.tscn": &"doyle",
		"res://scenes/npcs/idris_bell.tscn": &"idris",
		"res://scenes/npcs/mara_venn.tscn": &"mara",
		"res://scenes/npcs/tom_arkwright.tscn": &"tom",
		"res://scenes/npcs/nia_calder.tscn": &"nia",
		"res://scenes/npcs/continuity_presence.tscn": &"continuity",
	}
	for path in scene_contracts:
		var scene := load(path) as PackedScene
		_check(scene != null, "%s loads" % path)
		if scene == null:
			continue
		var actor := scene.instantiate() as WorldSurvivorNPC
		_check(actor != null and actor.profile != null, "%s is a profiled world actor" % path)
		if actor != null and actor.profile != null:
			_check(actor.profile.npc_id == scene_contracts[path], "%s binds the intended identity" % path)
			_check(actor.profile.sprite_atlas != null, "%s carries its authored atlas through the profile" % path)
		actor.free()

	var imogen_scene := load("res://scenes/npcs/imogen_bell.tscn") as PackedScene
	var rafi_scene := load("res://scenes/npcs/rafi_sayeed.tscn") as PackedScene
	var imogen := imogen_scene.instantiate() as SurvivorNPC if imogen_scene != null else null
	var rafi := rafi_scene.instantiate() as SurvivorNPC if rafi_scene != null else null
	_check(imogen != null and imogen.world_profile != null and imogen.world_profile.npc_id == &"imogen", "authored Imogen quest scene carries her world identity")
	_check(rafi != null and rafi.world_profile != null and rafi.world_profile.npc_id == &"rafi", "authored Rafi quest scene carries his world identity")
	if imogen != null and imogen.world_profile != null:
		_check((imogen.get_node("Visual") as Sprite2D).texture == imogen.world_profile.sprite_atlas, "Imogen quest scene uses her own atlas")
	if rafi != null and rafi.world_profile != null:
		_check((rafi.get_node("Visual") as Sprite2D).texture == rafi.world_profile.sprite_atlas, "Rafi quest scene uses his own atlas")
	if imogen != null: imogen.free()
	if rafi != null: rafi.free()


func _check_population_placements() -> void:
	for region in [&"cullbrook", &"ashmere_verge", &"broadcast_fields", &"choir_core", &"railhome"]:
		var population := _make_population(region)
		await get_tree().process_frame
		var expected_count := WorldNPCPopulation.get_region_placements(region).size()
		_check(population.get_spawned_actors().size() == expected_count, "%s instantiates every authored placement" % region)
		var placed_ids: Dictionary = {}
		var positions: Dictionary = {}
		for actor in population.get_spawned_actors():
			_check(not placed_ids.has(actor.population_id), "%s has no duplicate population id" % region)
			_check(not positions.has(actor.position), "%s actors do not share a placement" % region)
			_check(actor.has_meta("schedule") and actor.has_meta("service_id"), "%s placement exposes schedule and service metadata" % actor.profile.npc_id)
			_check((actor.get_node("Visual") as Sprite2D).texture == actor.profile.sprite_atlas, "%s placement renders its own atlas" % actor.profile.npc_id)
			_check(actor.get_node_or_null("IdentityAccessory") == null, "%s identity is not a procedural overlay" % actor.profile.npc_id)
			placed_ids[actor.population_id] = true
			positions[actor.position] = true
		population.populate()
		_check(population.get_spawned_actors().size() == expected_count, "%s repeated population is idempotent" % region)
		population.queue_free()
		await get_tree().process_frame


func _check_route_reactivity() -> void:
	var population := _make_population(&"ashmere_verge")
	await get_tree().process_frame
	var leena := _actor_by_id(population, &"leena")
	_check(leena != null, "Leena is placed at Bellwether School")
	if leena == null:
		population.queue_free()
		await get_tree().process_frame
		return
	var before := leena.get_route_reaction_signature()
	_check(CampaignSystem.commit_route_anchor(&"witness", false), "test can commit witness anchor")
	_check(CampaignSystem.commit_network_strategy(&"sever", false), "test can commit sever strategy")
	var after := leena.get_route_reaction_signature()
	_check(before != after and "LEENA" in after and after.count("|") == 1, "Leena responds to both route commitment axes")
	for actor in population.get_spawned_actors():
		var signature := actor.get_route_reaction_signature()
		_check(not signature.is_empty(), "%s exposes route-aware conversation" % actor.profile.npc_id)
	population.queue_free()
	await get_tree().process_frame
	CampaignSystem.clear_narrative_state(false)


func _check_persistent_consequences() -> void:
	var field := _make_population(&"cullbrook")
	var base := _make_population(&"railhome")
	await get_tree().process_frame
	var field_idris := _actor_by_id(field, &"idris")
	var base_idris := _actor_by_id(base, &"idris")
	var base_nia := _actor_by_id(base, &"nia")
	_check(field_idris != null and field_idris.visible, "unresolved Idris is visible at the maintenance bay")
	_check(base_idris != null and not base_idris.visible, "unresolved Idris is not duplicated at Railhome")
	_check(base_nia != null and not base_nia.visible, "unresolved Nia is not prematurely visible at Railhome")
	if field_idris == null or base_idris == null:
		field.queue_free()
		base.queue_free()
		await get_tree().process_frame
		return

	field_idris.resolve_helped(false)
	base.refresh()
	_check(not field_idris.visible and base_idris.visible, "helped Idris visibly relocates from Cullbrook to Railhome")
	_check(CampaignSystem.get_narrative_npc_state(&"idris") == &"rescued", "helping Idris updates the narrative NPC axis")
	field_idris.use_service(null, false)
	_check(WorldState.has_flag(&"npc_service_idris_repair"), "Idris service activation persists as its unique flag")
	_check(int(WorldState.get_flag(&"railhome_recovery_bonus", 0)) == 25, "Idris shelter service applies a gameplay value")

	var saved_variant: Variant = JSON.parse_string(JSON.stringify(WorldState.get_state()))
	_check(typeof(saved_variant) == TYPE_DICTIONARY, "NPC decision serialises to JSON")
	WorldState.clear()
	WorldState.restore(saved_variant if typeof(saved_variant) == TYPE_DICTIONARY else {})
	field.refresh()
	base.refresh()
	_check(field_idris.get_state_name() == &"helped" and not field_idris.visible, "helped state survives WorldState restore in the field")
	_check(base_idris.get_state_name() == &"helped" and base_idris.visible, "helped state survives WorldState restore at Railhome")

	field_idris.resolve_ignored(false)
	base.refresh()
	_check(field_idris.visible and field_idris.get_state_name() == &"ignored", "ignored Idris remains visibly at his departure point")
	_check(CampaignSystem.get_narrative_npc_state(&"idris") == &"left", "leaving Idris updates the narrative NPC axis")
	_check(not base_idris.visible, "ignored Idris is absent from Railhome")
	_check(field_idris.position != Vector2(385, 180), "ignored placement visibly changes Idris's schedule position")

	if base_nia != null:
		_check(CampaignSystem.rescue_narrative_npc(&"nia", false), "Nia can be stabilised through the Hollow decision")
		base.refresh()
		_check(base_nia.visible, "stabilised Nia becomes physically present at Railhome")
		_check(CampaignSystem.set_narrative_npc_state(&"nia", &"dead", false), "Nia can enter the dead consequence state")
		base.refresh()
		_check(not base_nia.visible, "dead Nia is absent from Railhome")
		_check(CampaignSystem.set_narrative_npc_state(&"nia", &"estranged", false), "Nia can enter the estranged consequence state")
		base.refresh()
		_check(not base_nia.visible, "estranged Nia is absent from Railhome")

	var choir := _make_population(&"choir_core")
	await get_tree().process_frame
	var continuity := _actor_by_id(choir, &"continuity")
	_check(continuity != null, "Continuity presence is instantiated in Tollard")
	if continuity != null:
		continuity.resolve_helped(false)
		_check(CampaignSystem.get_narrative_npc_state(&"maggie_copy") == &"active", "keeping Continuity isolated maps to the Maggie-copy narrative id")
		continuity.resolve_ignored(false)
		_check(CampaignSystem.get_narrative_npc_state(&"maggie_copy") == &"left", "darkening Continuity updates the Maggie-copy narrative id")
	choir.queue_free()

	field.queue_free()
	base.queue_free()
	await get_tree().process_frame


func _make_population(region: StringName) -> WorldNPCPopulation:
	var population := PopulationScene.instantiate() as WorldNPCPopulation
	population.auto_populate = false
	population.region_id = String(region)
	add_child(population)
	population.populate()
	return population


func _actor_by_id(population: WorldNPCPopulation, npc_id: StringName) -> WorldSurvivorNPC:
	for actor in population.get_spawned_actors():
		if actor.profile != null and actor.profile.npc_id == npc_id:
			return actor
	return null


func _check(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _fail(message: String) -> void:
	_failures.append(message)
