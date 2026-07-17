extends Node
## Proves that route tools come from production salvage and real recipes in
## the order the player reaches them. No finished mission tool is injected by
## this test: each route carries its remaining inventory into Wrenfield, pays
## for a Hollow policy, then makes and spends its second contract tool.

const RouteRegistry = preload("res://scripts/narrative/narrative_route_registry.gd")
const Contracts = preload("res://scripts/narrative/route_mission_contracts.gd")
const BuildingCatalogScript = preload("res://scripts/world/building_catalog.gd")
const Recovery = preload("res://scripts/crafting/route_salvage_recovery.gd")
const RESERVE_SCENE := preload("res://scenes/world/route_salvage_reserve.tscn")

const REGIONS: Array[StringName] = [&"cullbrook", &"ashmere_verge", &"broadcast_fields"]
const REGION_SCENES := {
	&"cullbrook": "res://scenes/maps/test_map.tscn",
	&"ashmere_verge": "res://scenes/maps/ashmere_verge.tscn",
	&"broadcast_fields": "res://scenes/maps/broadcast_fields.tscn",
}
const REGION_FLAGS := {
	&"cullbrook": [],
	&"ashmere_verge": [
		&"mara_contacted", &"memory_burst_unlocked", &"imogen_rescued",
	],
	&"broadcast_fields": [
		&"wrenfield_route_verified", &"relay_west_restored", &"relay_east_restored",
	],
}
const HOLLOW_TOOLS: Array[StringName] = [&"analogue_isolator", &"signal_decoy"]

var _failures: Array[String] = []
var _loot_by_region: Dictionary = {}
var _echoes_by_region: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_run")


func _run() -> void:
	_reset_state()
	for region_id in REGIONS:
		await _capture_live_region(region_id)
	_check_contract_item_steps()
	_check_recipe_stage_gates()
	_check_raw_material_supply()
	_check_route_recovery_requires_salvage_effort()
	_check_route_recovery_after_exhaustion()
	_check_all_route_economies()
	_check_declined_rafi_can_rejoin_route()
	_check_copy_workshop_consent_ordering()
	_check_strategy_aware_repeater()
	_check_fed_records_do_not_verify_themselves()
	_check_imogen_kit_choice_is_atomic()
	_check_rafi_field_reward_is_atomic()
	_check_automatic_payout_notices_are_truthful()

	_reset_state()
	SaveManager.delete_save()
	if _failures.is_empty():
		print("CRAFTING_PROGRESSION_REACHABILITY: PASS")
		get_tree().quit(0)
		return
	for failure in _failures:
		push_error("CRAFTING_PROGRESSION_REACHABILITY: " + failure)
	print("CRAFTING_PROGRESSION_REACHABILITY: FAIL (%d)" % _failures.size())
	get_tree().quit(1)


func _capture_live_region(region_id: StringName) -> void:
	var scene_path := String(REGION_SCENES.get(region_id, ""))
	var packed := load(scene_path) as PackedScene
	if packed == null:
		_fail("%s production map could not be loaded" % region_id)
		return
	var root := packed.instantiate()
	add_child(root)
	await _frames(3)

	var loot: Dictionary = {}
	var echoes: Dictionary = {}
	var live_containers := 0
	var recovery_reserves := 0
	for node in _all_nodes(root):
		if node is LootContainer:
			live_containers += 1
			_merge_loot(loot, (node as LootContainer).loot)
		if node is MemoryEcho:
			var echo := node as MemoryEcho
			if echo.echo_data != null:
				echoes[echo.echo_data.id] = true
		if node is RouteSalvageReserve:
			recovery_reserves += 1
	_check(live_containers > 0, "%s has live production loot containers" % region_id)
	if region_id in [&"ashmere_verge", &"broadcast_fields"]:
		_check(recovery_reserves == 1,
			"%s physically places one labelled route-parts recovery drawer" % region_id)

	var building_ids := BuildingCatalogScript.region_buildings(region_id)
	_check(not building_ids.is_empty(), "%s has enterable-building salvage" % region_id)
	for building_id in building_ids:
		var building := BuildingCatalogScript.get_building(building_id)
		_merge_loot(loot, building.get("loot", {}) as Dictionary)

	_loot_by_region[region_id] = loot
	_echoes_by_region[region_id] = echoes
	root.queue_free()
	await _frames(2)


func _check_contract_item_steps() -> void:
	for mission_id in Contracts.all_mission_ids():
		var contract := Contracts.get_contract(mission_id)
		var cost_item := StringName(contract.get("cost_item", &""))
		var item_steps: Array[Dictionary] = []
		for raw_step in contract.get("steps", []):
			var step := Dictionary(raw_step)
			if String(step.get("kind", "")) == "item":
				item_steps.append(step)
		_check(item_steps.size() == 1, "%s has one explicit item check" % mission_id)
		if item_steps.size() != 1:
			continue
		var step_item := StringName(item_steps[0].get("id", &""))
		_check(step_item == cost_item, "%s item check matches its consumed tool" % mission_id)
		var item := ItemDatabase.get_item(cost_item)
		if item == null:
			continue
		var words := item.display_name.to_lower().split(" ", false)
		var noun := words[words.size() - 1] if not words.is_empty() else String(cost_item)
		_check(noun in String(item_steps[0].get("label", "")).to_lower(),
			"%s field copy names its %s" % [mission_id, item.display_name])


func _check_recipe_stage_gates() -> void:
	for route_id in RouteRegistry.all_route_ids():
		var missions := RouteRegistry.get_missions(route_id)
		_check(missions.size() == 2, "%s has two staged route jobs" % route_id)
		for slot in range(mini(2, missions.size())):
			var mission_id := StringName(missions[slot].get("id", &""))
			var cost_item := StringName(Contracts.get_contract(mission_id).get("cost_item", &""))
			var stage_index := 1 if slot == 0 else 2
			_audit_recipe_chain(cost_item, stage_index, "%s slot %d" % [route_id, slot], [])
			if _recipe_for_output(cost_item) == null:
				var loot := _loot_through(stage_index)
				_check(int(loot.get(cost_item, 0)) > 0,
					"%s raw contract item %s exists before its sign-off" % [mission_id, cost_item])


func _audit_recipe_chain(
		item_id: StringName,
		stage_index: int,
		context: String,
		chain: Array[StringName],
	) -> void:
	var recipe := _recipe_for_output(item_id)
	if recipe == null:
		return
	if item_id in chain:
		_fail("%s recipe chain cycles at %s" % [context, item_id])
		return
	var next_chain: Array[StringName] = chain.duplicate()
	next_chain.append(item_id)
	for flag_id in recipe.required_flags:
		_check(_flag_available_through(flag_id, stage_index),
			"%s learns %s flag %s by region %s" % [context, item_id, flag_id, REGIONS[stage_index]])
	for echo_id in recipe.required_echoes:
		_check(_echo_available_through(echo_id, stage_index),
			"%s finds %s record %s by region %s" % [context, item_id, echo_id, REGIONS[stage_index]])
	for ingredient_id in recipe.get_ingredient_ids():
		_audit_recipe_chain(ingredient_id, stage_index, context, next_chain)


func _check_raw_material_supply() -> void:
	var outputs: Dictionary = {}
	for recipe in CraftingRecipeDatabase.get_recipes():
		outputs[recipe.output_item_id] = true
	var raw_requirements: Dictionary = {}
	for recipe in CraftingRecipeDatabase.get_recipes():
		for ingredient_id in recipe.get_ingredient_ids():
			if outputs.has(ingredient_id):
				continue
			raw_requirements[ingredient_id] = maxi(
				int(raw_requirements.get(ingredient_id, 0)),
				int(recipe.ingredients.get(ingredient_id, recipe.ingredients.get(String(ingredient_id), 0)))
			)
	var available := _loot_through(REGIONS.size() - 1)
	for ingredient_id in raw_requirements:
		var needed := int(raw_requirements[ingredient_id])
		var found := int(available.get(ingredient_id, 0))
		_check(found >= needed,
			"production salvage supplies %s (%d available, %d needed at once)" % [ingredient_id, found, needed])
	_check(int(available.get(&"resin_tape", 0)) >= 5,
		"resin tape supports the two-job wire-splicer route plus a Hollow stabiliser")
	_check(int(available.get(&"lamp_oil", 0)) >= 2,
		"lamp oil has a spare charge beyond the Wrenfield flare contract")


func _check_all_route_economies() -> void:
	for route_id in RouteRegistry.all_route_ids():
		_reset_state()
		var route := RouteRegistry.get_route(route_id)
		_check(CampaignSystem.commit_route_anchor(StringName(route.get("anchor", &"")), false),
			"%s anchor commits for the economy run" % route_id)
		_check(CampaignSystem.commit_network_strategy(StringName(route.get("strategy", &"")), false),
			"%s strategy commits for the economy run" % route_id)
		_open_region(&"cullbrook")
		_open_region(&"ashmere_verge")

		var missions := RouteRegistry.get_missions(route_id)
		if missions.size() != 2:
			continue
		var ash_mission := StringName(missions[0].get("id", &""))
		var ash_tool := StringName(Contracts.get_contract(ash_mission).get("cost_item", &""))
		if not _obtain_or_craft(ash_tool, 1, "%s Ashmere job" % route_id, []):
			continue
		_check(InventorySystem.remove_item(ash_tool, 1),
			"%s can spend its Ashmere contract tool" % route_id)

		_open_region(&"broadcast_fields")
		var wrenfield_start := InventorySystem.get_items()
		var wren_mission := StringName(missions[1].get("id", &""))
		var wren_tool := StringName(Contracts.get_contract(wren_mission).get("cost_item", &""))
		for hollow_tool in HOLLOW_TOOLS:
			InventorySystem.set_items(wrenfield_start)
			var policy := "STABILISE" if hollow_tool == &"analogue_isolator" else "WEAPONISE"
			var context := "%s / %s" % [route_id, policy]
			_check(InventorySystem.remove_item(&"copper_wire", 2),
				"%s keeps a two-wire margin for optional field repairs" % context)
			if not _obtain_or_craft(hollow_tool, 1, "%s Hollow decision" % context, []):
				continue
			_check(InventorySystem.remove_item(hollow_tool, 1),
				"%s can spend its Hollow tool before slot 1" % context)
			if not _obtain_or_craft(wren_tool, 1, "%s Wrenfield job" % context, []):
				continue
			_check(InventorySystem.remove_item(wren_tool, 1),
				"%s can spend its Wrenfield contract tool before Tollard" % context)


func _check_route_recovery_after_exhaustion() -> void:
	for route_id in RouteRegistry.all_route_ids():
		_reset_state()
		var route := RouteRegistry.get_route(route_id)
		CampaignSystem.commit_route_anchor(StringName(route.get("anchor", &"")), false)
		CampaignSystem.commit_network_strategy(StringName(route.get("strategy", &"")), false)
		_open_region(&"cullbrook")
		_open_region(&"ashmere_verge")
		var missions := RouteRegistry.get_missions(route_id)
		if missions.size() != 2:
			continue
		for slot in range(2):
			if slot == 1:
				_open_region(&"broadcast_fields")
			var mission_id := StringName(missions[slot].get("id", &""))
			var cost_item := StringName(Contracts.get_contract(mission_id).get("cost_item", &""))
			CampaignSystem.start_route_mission(mission_id, false)
			_mark_salvage_effort(Recovery.required_search_count_for_slot(slot))

			# Model every relevant raw part and prefabricated intermediate being
			# spent before Ellie returns to the region's labelled job drawer.
			var exhausted := InventorySystem.get_items()
			for recipe in CraftingRecipeDatabase.get_recipes():
				exhausted.erase(recipe.output_item_id)
			for raw_id in Recovery.raw_requirements_for_item(cost_item):
				exhausted.erase(raw_id)
			InventorySystem.set_items(exhausted)
			var missing_before := Recovery.missing_raw_for_item(cost_item, 1)
			_check(not missing_before.is_empty(),
				"%s slot %d exhaustion removes its ordinary material path" % [route_id, slot])

			var reserve := RESERVE_SCENE.instantiate() as RouteSalvageReserve
			add_child(reserve)
			var recovery_result := reserve.recover_now()
			_check(bool(recovery_result.get("ok", false)),
				"%s slot %d recovers through the physical parts drawer: %s" % [
					route_id, slot, recovery_result.get("reason", "no reason")])
			var granted := recovery_result.get("granted", {}) as Dictionary
			_check(granted == missing_before,
				"%s slot %d recovery uses exactly its missing raw stock" % [route_id, slot])
			for raw_id in granted:
				_check(_recipe_for_output(StringName(raw_id)) == null,
					"%s slot %d recovery grants no finished or intermediate tool" % [route_id, slot])
			_check(Recovery.has_reserved_tool(mission_id, cost_item),
				"%s slot %d seals one mission-bound route tool" % [route_id, slot])
			var cost_recipe := _recipe_for_output(cost_item)
			var expected_surplus := 0
			if cost_recipe != null:
				expected_surplus = maxi(cost_recipe.output_amount - 1, 0)
			_check(InventorySystem.get_count(cost_item) == expected_surplus,
				"%s slot %d preserves the authored batch surplus" % [route_id, slot])
			_check(not _contract_has_unmet_item_step(mission_id),
				"%s slot %d reserved tool satisfies the physical work card" % [route_id, slot])

			var inventory_after := InventorySystem.get_items()
			var recovery_count := int(WorldState.get_flag(Recovery.RECOVERY_COUNT_FLAG, 0))
			var repeated := reserve.recover_now()
			_check(not bool(repeated.get("ok", false))
					and InventorySystem.get_items() == inventory_after
					and int(WorldState.get_flag(Recovery.RECOVERY_COUNT_FLAG, 0)) == recovery_count,
				"%s slot %d recovery cannot be farmed" % [route_id, slot])
			reserve.queue_free()

			_check(Contracts.consume_completion_cost(mission_id),
				"%s slot %d sign-off consumes the sealed tool" % [route_id, slot])
			_check(not Recovery.has_reserved_tool(mission_id, cost_item)
					and InventorySystem.get_count(cost_item) == expected_surplus,
				"%s slot %d leaves only the authored batch surplus" % [route_id, slot])
			_check(CampaignSystem.complete_route_mission(mission_id, false),
				"%s slot %d recovery reaches a completed mission state" % [route_id, slot])


func _check_route_recovery_requires_salvage_effort() -> void:
	_reset_state()
	CampaignSystem.commit_route_anchor(&"clinic", false)
	CampaignSystem.commit_network_strategy(&"restore", false)
	_open_region(&"cullbrook")
	_open_region(&"ashmere_verge")
	# Keep the authored recipe knowledge while modelling a player who has not
	# searched a single supply cache for usable stock.
	InventorySystem.set_items({})
	var mission_id := Recovery.mission_id_for_slot(0)
	var cost_item := StringName(Contracts.get_contract(mission_id).get("cost_item", &""))
	var inventory_before := InventorySystem.get_items()
	var unopened := Recovery.recover_for_slot(0)
	_check(not bool(unopened.get("ok", false)) and InventorySystem.get_items() == inventory_before,
		"the route drawer stays sealed before its work card is accepted")

	CampaignSystem.start_route_mission(mission_id, false)
	var no_search := Recovery.recover_for_slot(0)
	_check(not bool(no_search.get("ok", false)) and InventorySystem.get_items() == inventory_before,
		"a fresh route cannot fabricate its first contract tool without scavenging")
	_check(not WorldState.has_flag(StringName(
			"route_salvage_claimed_%s" % String(mission_id))),
		"an early drawer attempt consumes no emergency claim")

	_mark_salvage_effort(Recovery.required_search_count_for_slot(0))
	var after_search := Recovery.recover_for_slot(0)
	_check(bool(after_search.get("ok", false)) and Recovery.has_reserved_tool(mission_id, cost_item),
		"the drawer becomes a mission-bound safety net after meaningful salvage effort")


func _mark_salvage_effort(required_count: int) -> void:
	var next_index := WorldState.get_searched_cache_count()
	while WorldState.get_searched_cache_count() < required_count:
		WorldState.mark_opened(StringName("reachability_supply_cache_%d" % next_index))
		next_index += 1


func _check_declined_rafi_can_rejoin_route() -> void:
	_reset_state()
	WorldState.set_flag(&"rafi_declined")
	CampaignSystem.set_narrative_npc_state(&"rafi", &"active", false)
	_check(CampaignSystem.commit_route_anchor(&"radio", false),
		"a declined school aerial does not lock the radio lead")
	_check(WorldState.has_flag(&"rafi_declined"),
		"Rafi's original aerial consequence remains recorded")
	_check(WorldState.has_flag(&"rafi_route_rejoined") and WorldState.has_flag(&"helped_rafi"),
		"the radio work card reconnects Rafi through Maggie's local relay")
	_check(CampaignSystem.get_narrative_npc_state(&"rafi") == &"rescued",
		"Rafi is physically available for the radio contract")
	var payload: Dictionary = CampaignSystem.call("_school_radio_dialogue")
	_check("LOCAL RELAY" in String(payload.get("title", "")),
		"the repaired relationship does not pretend the school aerial came back")

	_reset_state()
	CampaignSystem.commit_route_anchor(&"radio", false)
	CampaignSystem.call("_complete_story", &"bellwether_school_radio", 1)
	_check(WorldState.has_flag(&"rafi_declined") and WorldState.has_flag(&"rafi_route_rejoined"),
		"declining the aerial after choosing Radio immediately opens Maggie's local pair")
	_check(CampaignSystem.get_narrative_npc_state(&"rafi") == &"rescued",
		"radio-first ordering also keeps Rafi's contract reachable")


func _check_copy_workshop_consent_ordering() -> void:
	_reset_state()
	var mara := EchoDatabase.get_echo(&"echo_mara_repair")
	ArchiveSystem.record_echo(mara, ArchiveSystem.VERIFIED)
	CampaignSystem.commit_route_anchor(&"copy", false)
	_check(WorldState.has_flag(&"copy_workshop_trace_shared")
			and CampaignSystem.get_fed_trace_count() == 1,
		"scanning Maggie's ledger before choosing Copy shares one explicit copy")
	_check(ArchiveSystem.get_disposition(&"echo_mara_repair") == ArchiveSystem.VERIFIED,
		"sharing with Continuity does not rewrite the filed archive provenance")

	_reset_state()
	CampaignSystem.commit_route_anchor(&"copy", false)
	_check(CampaignSystem.get_fed_trace_count() == 0,
		"Copy commitment waits when Maggie's ledger is not yet filed")
	ArchiveSystem.record_echo(mara, ArchiveSystem.VERIFIED)
	_check(WorldState.has_flag(&"copy_workshop_trace_shared")
			and CampaignSystem.get_fed_trace_count() == 1,
		"filing Maggie's ledger after Copy commitment fulfils the prior consent")
	_check(ArchiveSystem.get_disposition(&"echo_mara_repair") == ArchiveSystem.VERIFIED,
		"commit-first sharing also preserves verified provenance")

	var world_snapshot := WorldState.get_state()
	var archive_ids := ArchiveSystem.get_recovered_ids()
	var archive_dispositions := ArchiveSystem.get_dispositions()
	var narrative_snapshot := CampaignSystem.get_narrative_state()
	_reset_state()
	WorldState.restore(world_snapshot)
	ArchiveSystem.restore(archive_ids, archive_dispositions)
	CampaignSystem.restore_narrative_state(narrative_snapshot, SaveManager.SAVE_VERSION)
	_check(WorldState.has_flag(&"copy_workshop_trace_shared")
			and CampaignSystem.get_fed_trace_count() == 1
			and CampaignSystem.get_active_route_id() == &"",
		"copy workshop consent survives an atomic snapshot reload before strategy selection")


func _check_strategy_aware_repeater() -> void:
	_prepare_strategy(&"restore")
	var payload: Dictionary = CampaignSystem.call("_public_repeater_dialogue")
	var choices: Array = payload.get("choices", [])
	_check(choices == ["WIRE THE PUBLIC CHANNEL", "LEAVE IT FOR NOW"],
		"RESTORE offers wiring or a reversible pause, never fuse removal")
	CampaignSystem.call("_complete_story", &"long_acre_repeater", 1)
	_check(not WorldState.has_flag(&"public_repeater") and not WorldState.has_flag(&"public_repeater_declined"),
		"RESTORE leave-for-now commits no repeater outcome")
	CampaignSystem.call("_complete_story", &"long_acre_repeater", 0)
	_check(WorldState.has_flag(&"public_repeater") and not WorldState.has_flag(&"public_repeater_declined"),
		"RESTORE index zero wires the public line")

	_prepare_strategy(&"sever")
	payload = CampaignSystem.call("_public_repeater_dialogue")
	choices = payload.get("choices", [])
	_check(choices == ["REMOVE THE LAST FUSE", "LEAVE IT FOR NOW"],
		"SEVER offers fuse removal or a reversible pause, never wiring")
	CampaignSystem.call("_complete_story", &"long_acre_repeater", 1)
	_check(not WorldState.has_flag(&"public_repeater") and not WorldState.has_flag(&"public_repeater_declined"),
		"SEVER leave-for-now commits no repeater outcome")
	CampaignSystem.call("_complete_story", &"long_acre_repeater", 0)
	_check(WorldState.has_flag(&"public_repeater_declined") and not WorldState.has_flag(&"public_repeater"),
		"SEVER index zero removes the last fuse")

	_prepare_strategy(&"mesh")
	payload = CampaignSystem.call("_public_repeater_dialogue")
	choices = payload.get("choices", [])
	_check(choices == ["WIRE THE PUBLIC CHANNEL", "REMOVE THE LAST FUSE"],
		"MESH retains both irreversible local choices")
	CampaignSystem.call("_complete_story", &"long_acre_repeater", 1)
	_check(WorldState.has_flag(&"public_repeater_declined"),
		"MESH fuse-removal choice still resolves deliberately")


func _check_fed_records_do_not_verify_themselves() -> void:
	_reset_state()
	var fed := EchoDatabase.get_echo(&"echo_last_signal")
	var verified := EchoDatabase.get_echo(&"echo_sun_lid")
	ArchiveSystem.record_echo(fed, ArchiveSystem.FED)
	_check(CampaignSystem.get_evidence_confidence() == 0,
		"feeding a trace to Continuity does not count as verification")
	ArchiveSystem.record_echo(verified, ArchiveSystem.VERIFIED)
	_check(CampaignSystem.get_evidence_confidence() == 1,
		"filing a verified trace adds its authored revelation")


func _check_imogen_kit_choice_is_atomic() -> void:
	_reset_state()
	WorldState.set_flag(CampaignSystem.IMOGEN_ESCORT_FLAG)
	InventorySystem.set_items({&"medical_kit": 4})
	CampaignSystem.call("_complete_story", &"imogen_workshop_safe", 0)
	_check(InventorySystem.get_count(&"medical_kit") == 4,
		"a full field kit accepts no partial Imogen reward")
	_check(not WorldState.has_flag(CampaignSystem.IMOGEN_RESCUED_FLAG)
			and not WorldState.has_flag(&"imogen_kit_taken")
			and CampaignSystem.get_narrative_npc_state(&"imogen") != &"rescued",
		"failed kit delivery leaves Imogen's irreversible choice open")

	InventorySystem.set_items({&"medical_kit": 3})
	CampaignSystem.call("_complete_story", &"imogen_workshop_safe", 0)
	_check(InventorySystem.get_count(&"medical_kit") == 5,
		"two sealed medical kits are granted atomically when both fit")
	_check(WorldState.has_flag(CampaignSystem.IMOGEN_RESCUED_FLAG)
			and WorldState.has_flag(&"imogen_kit_taken")
			and CampaignSystem.get_narrative_npc_state(&"imogen") == &"rescued",
		"successful kit delivery commits Imogen's rescue exactly once")


func _check_rafi_field_reward_is_atomic() -> void:
	_reset_state()
	WorldState.set_flag(CampaignSystem.RAFI_CONNECTED_FLAG)
	InventorySystem.set_items({&"battery": 10})
	CampaignSystem.call("_complete_story", &"rafi_field_contact", 0)
	_check(InventorySystem.get_count(&"battery") == 10
			and InventorySystem.get_count(&"scrap") == 0,
		"a full battery stack accepts none of Rafi's two-part field pack")
	_check(not WorldState.has_flag(&"rafi_field_defense")
			and not WorldState.has_flag(&"rafi_field_repeater"),
		"failed field-pack delivery leaves Rafi's irreversible post undecided")

	InventorySystem.set_items({&"battery": 9, &"scrap": 98})
	CampaignSystem.call("_complete_story", &"rafi_field_contact", 0)
	_check(InventorySystem.get_count(&"battery") == 10
			and InventorySystem.get_count(&"scrap") == 99,
		"Rafi's full field pack is granted atomically when both items fit")
	_check(WorldState.has_flag(&"rafi_field_defense")
			and not WorldState.has_flag(&"rafi_field_repeater"),
		"successful field-pack delivery commits exactly one Rafi post")


func _check_automatic_payout_notices_are_truthful() -> void:
	var notices: Array[String] = []
	var observer := func(message: String) -> void: notices.append(message)
	EventBus.notice_posted.connect(observer)

	_reset_state()
	InventorySystem.set_items({&"scrap": 99})
	CampaignSystem.call("_complete_story", &"road_trace_west", 0)
	CampaignSystem.call("_complete_story", &"road_trace_east", 0)
	var road_copy := "\n".join(notices)
	_check(InventorySystem.get_count(&"scrap") == 99
			and "No scrap recovered" in road_copy and "+2 scrap" not in road_copy,
		"route verification tells the truth when its one-shot scrap payout cannot fit")

	notices.clear()
	_reset_state()
	InventorySystem.set_items({&"battery": 10})
	CampaignSystem.report_field_task(&"east_relay_defense")
	var east_copy := "\n".join(notices)
	_check(InventorySystem.get_count(&"battery") == 10
			and "No battery recovered" in east_copy and "+1 battery" not in east_copy,
		"east relay completion tells the truth when its battery payout cannot fit")

	notices.clear()
	_reset_state()
	InventorySystem.set_items({&"scrap": 99})
	CampaignSystem.report_field_task(&"south_line")
	var south_copy := "\n".join(notices)
	_check(InventorySystem.get_count(&"scrap") == 99
			and "No scrap recovered" in south_copy and "+2 scrap" not in south_copy,
		"south line completion tells the truth when its scrap payout cannot fit")

	EventBus.notice_posted.disconnect(observer)


func _prepare_strategy(strategy: StringName) -> void:
	_reset_state()
	CampaignSystem.commit_route_anchor(&"clinic", false)
	CampaignSystem.commit_network_strategy(strategy, false)


func _contract_has_unmet_item_step(mission_id: StringName) -> bool:
	for step in Contracts.unmet_steps(mission_id):
		if String(step.get("kind", "")) == "item":
			return true
	return false


func _open_region(region_id: StringName) -> void:
	for item_id in (_loot_by_region.get(region_id, {}) as Dictionary):
		InventorySystem.add_item(StringName(item_id), int(_loot_by_region[region_id][item_id]))
	for echo_id in (_echoes_by_region.get(region_id, {}) as Dictionary):
		var data := EchoDatabase.get_echo(StringName(echo_id))
		if data != null and not ArchiveSystem.has_echo(data.id):
			ArchiveSystem.record_echo(data, ArchiveSystem.VERIFIED)
	for flag_id in REGION_FLAGS.get(region_id, []):
		WorldState.set_flag(StringName(flag_id))


func _obtain_or_craft(
		item_id: StringName,
		amount: int,
		context: String,
		chain: Array[StringName],
	) -> bool:
	if InventorySystem.get_count(item_id) >= amount:
		return true
	var recipe := _recipe_for_output(item_id)
	if recipe == null:
		_fail("%s is short %s and no production recipe can make it" % [context, item_id])
		return false
	if item_id in chain:
		_fail("%s reaches a recipe cycle at %s" % [context, item_id])
		return false
	var next_chain: Array[StringName] = chain.duplicate()
	next_chain.append(item_id)
	var missing := amount - InventorySystem.get_count(item_id)
	var craft_count := ceili(float(missing) / float(recipe.output_amount))
	for ingredient_id in recipe.get_ingredient_ids():
		var per_craft := int(recipe.ingredients.get(
			ingredient_id, recipe.ingredients.get(String(ingredient_id), 0)))
		var required_total := per_craft * craft_count
		if not _obtain_or_craft(ingredient_id, required_total, context, next_chain):
			return false
	var status := CraftingSystem.get_status(recipe.id, craft_count, recipe.station_id)
	if not bool(status.get("ok", false)):
		_fail("%s cannot make %s: %s (%s)" % [
			context, item_id, status.get("reason", "recipe blocked"), status.get("code", &"unknown")])
		return false
	var result := CraftingSystem.craft(recipe.id, craft_count, recipe.station_id)
	if not bool(result.get("ok", false)):
		_fail("%s failed the atomic %s craft" % [context, item_id])
		return false
	return InventorySystem.get_count(item_id) >= amount


func _recipe_for_output(item_id: StringName) -> CraftingRecipeData:
	for recipe in CraftingRecipeDatabase.get_recipes():
		if recipe.output_item_id == item_id:
			return recipe
	return null


func _loot_through(stage_index: int) -> Dictionary:
	var total: Dictionary = {}
	for index in range(mini(stage_index + 1, REGIONS.size())):
		_merge_loot(total, _loot_by_region.get(REGIONS[index], {}) as Dictionary)
	return total


func _flag_available_through(flag_id: StringName, stage_index: int) -> bool:
	for index in range(mini(stage_index + 1, REGIONS.size())):
		if flag_id in REGION_FLAGS.get(REGIONS[index], []):
			return true
	return false


func _echo_available_through(echo_id: StringName, stage_index: int) -> bool:
	for index in range(mini(stage_index + 1, REGIONS.size())):
		if (_echoes_by_region.get(REGIONS[index], {}) as Dictionary).has(echo_id):
			return true
	return false


func _merge_loot(target: Dictionary, source: Dictionary) -> void:
	for raw_id in source:
		var item_id := StringName(str(raw_id))
		target[item_id] = int(target.get(item_id, 0)) + int(source[raw_id])


func _reset_state() -> void:
	GameManager.set_dialogue_active(false)
	GameManager.set_ending_active(false)
	GameManager.set_paused(false)
	WorldState.clear()
	ArchiveSystem.restore([])
	InventorySystem.set_items({})
	CampaignSystem.clear_narrative_state(false)


func _all_nodes(root: Node) -> Array[Node]:
	var nodes: Array[Node] = [root]
	for child in root.get_children():
		nodes.append_array(_all_nodes(child))
	return nodes


func _frames(count: int) -> void:
	for _index in range(count):
		await get_tree().process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _fail(message: String) -> void:
	_failures.append(message)
