extends Node
## Focused headless contract test for recipe data, progression gates and
## inventory atomicity.
##
## Run with:
## godot --headless --path <project> --scene res://tools/crafting_smoke.tscn

const LOOT_SCENE := preload("res://scenes/world/loot_container.tscn")

const EXPECTED_RECIPES: Array[StringName] = [
	&"field_dressing",
	&"lock_shim",
	&"shielded_fuse",
	&"signal_decoy",
	&"analogue_isolator",
	&"circuit_bridge",
	&"hand_flare",
	&"tripwire_alarm",
	&"ash_filter",
	&"wire_splicer",
	&"relay_tester",
	&"carrier_grounder",
]

const EXPECTED_NEW_ITEMS: Array[StringName] = [
	&"clean_cloth", &"resin_tape", &"copper_wire", &"ceramic_fuse",
	&"lamp_oil", &"filter_charcoal", &"field_dressing", &"lock_shim",
	&"shielded_fuse", &"signal_decoy", &"analogue_isolator",
	&"circuit_bridge", &"hand_flare", &"tripwire_alarm", &"ash_filter",
	&"wire_splicer", &"relay_tester", &"carrier_grounder",
]

var _failures: Array[String] = []
var _inventory_signal_count := 0
var _item_added_signal_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_reset_state()
	_test_catalogue()
	_test_validation_rejects_unknown_items()
	_test_stack_limits_and_atomic_helpers()
	_test_loot_capacity_is_atomic()
	_test_choice_capacity_is_atomic()
	_test_unlocks_and_atomic_craft()
	_test_bulk_craft_and_signal_count()
	_reset_state()
	# Allow queued frees and cached script resources to settle before the raw
	# shutdown gate inspects ObjectDB. Production runs naturally have many such
	# frames; this focused harness otherwise quits in its first deferred frame.
	await get_tree().process_frame
	await get_tree().process_frame

	if _failures.is_empty():
		print("CRAFTING_SMOKE: PASS")
		get_tree().quit(0)
		return
	for failure in _failures:
		push_error("CRAFTING_SMOKE: " + failure)
	print("CRAFTING_SMOKE: FAIL (%d)" % _failures.size())
	get_tree().quit(1)


func _test_catalogue() -> void:
	_check(CraftingRecipeDatabase.get_validation_errors().is_empty(), "authored recipes validate cleanly")
	_check(CraftingRecipeDatabase.get_recipe_ids() == EXPECTED_RECIPES, "recipes have deterministic authored order")
	_check(CraftingRecipeDatabase.get_recipes().size() >= 10, "at least ten recipes are loaded")

	for item_id in EXPECTED_NEW_ITEMS:
		_check(ItemDatabase.has_item(item_id), "new item '%s' is registered" % item_id)

	var recipes_with_flags := 0
	var recipes_with_echoes := 0
	var icon_regions: Dictionary = {}
	for recipe in CraftingRecipeDatabase.get_recipes():
		_check(recipe != null, "recipe entry is not null")
		if recipe == null:
			continue
		_check(not recipe.description.strip_edges().is_empty(), "recipe '%s' has human description" % recipe.id)
		_check(not recipe.unlock_note.strip_edges().is_empty(), "recipe '%s' explains its unlock" % recipe.id)
		_check(ItemDatabase.has_item(recipe.output_item_id), "recipe '%s' output is known" % recipe.id)
		var output := ItemDatabase.get_item(recipe.output_item_id)
		_check(output != null and output.icon is AtlasTexture,
			"recipe '%s' has its own painted atlas icon" % recipe.id)
		if output != null and output.icon is AtlasTexture:
			var icon := output.icon as AtlasTexture
			var region_key := str(icon.region)
			_check(not icon_regions.has(region_key),
				"recipe '%s' does not reuse another output icon" % recipe.id)
			icon_regions[region_key] = true
			_check(icon.atlas != null and icon.atlas.resource_path.ends_with("crafted_items_atlas.png"),
				"recipe '%s' uses the authored crafting atlas" % recipe.id)
		for ingredient_id in recipe.get_ingredient_ids():
			_check(ItemDatabase.has_item(ingredient_id), "recipe '%s' ingredient '%s' is known" % [recipe.id, ingredient_id])
		if not recipe.required_flags.is_empty():
			recipes_with_flags += 1
		if not recipe.required_echoes.is_empty():
			recipes_with_echoes += 1
	_check(recipes_with_flags >= 6, "the catalogue uses campaign-flag unlocks")
	_check(recipes_with_echoes == EXPECTED_RECIPES.size(), "every recipe is grounded in a recovered field record")
	_check(icon_regions.size() == EXPECTED_RECIPES.size(), "all twelve crafted outputs have distinct painted icons")

	var field_recipes := CraftingSystem.get_recipes_for_station(&"field_kit")
	var field_ids: Array[StringName] = []
	for recipe in field_recipes:
		field_ids.append(recipe.id)
	_check(field_ids == [&"field_dressing", &"lock_shim", &"hand_flare", &"ash_filter"], "station filtering preserves recipe order")


func _test_validation_rejects_unknown_items() -> void:
	var invalid := CraftingRecipeData.new()
	invalid.id = &"invalid_test_recipe"
	invalid.display_name = "Invalid test recipe"
	invalid.description = "Used only to exercise validation."
	invalid.station_id = &"field_kit"
	invalid.ingredients = {&"item_that_does_not_exist": 1}
	invalid.output_item_id = &"another_missing_item"
	invalid.required_echoes = [&"echo_that_does_not_exist"]
	var errors := CraftingRecipeDatabase.validate_recipe(invalid)
	_check(_contains(errors, "not a known item"), "validation rejects an unknown ingredient")
	_check(_contains(errors, "output") and _contains(errors, "not a known item"), "validation rejects an unknown output")
	_check(_contains(errors, "echo requirement") and _contains(errors, "unknown"), "validation rejects an unknown echo gate")

	InventorySystem.set_items({})
	_check(not InventorySystem.add_items_atomic({&"item_that_does_not_exist": 1}), "inventory rejects unknown atomic output")
	_check(InventorySystem.get_items().is_empty(), "unknown atomic output changes nothing")
	_check(not InventorySystem.add_items_atomic({&"": 1}), "inventory rejects an empty transaction item id")


func _test_stack_limits_and_atomic_helpers() -> void:
	InventorySystem.set_items({&"battery": 999})
	_check(InventorySystem.get_count(&"battery") == 10, "restore clamps an item to its authored stack limit")
	InventorySystem.add_item(&"battery", 4)
	_check(InventorySystem.get_count(&"battery") == 10, "ordinary item grants cannot overflow a stack")

	InventorySystem.set_items({&"scrap": 2})
	_check(InventorySystem.remove_items_atomic({&"scrap": 2}), "atomic removal can consume the final stack")
	_check(InventorySystem.get_items().is_empty(), "final-stack removal commits an empty inventory")

	InventorySystem.set_items({&"scrap": 1, &"battery": 1})
	var before := InventorySystem.get_items()
	_check(not InventorySystem.remove_items_atomic({&"scrap": 2, &"battery": 1}), "atomic removal fails on one missing ingredient")
	_check(InventorySystem.get_items() == before, "failed atomic removal preserves every ingredient")


func _test_loot_capacity_is_atomic() -> void:
	WorldState.clear()
	InventorySystem.set_items({&"battery": 9})
	var cache := LOOT_SCENE.instantiate() as LootContainer
	cache.persistent_id = &"crafting_capacity_test_cache"
	cache.loot = {&"battery": 2}
	add_child(cache)
	cache.interact(null)
	_check(InventorySystem.get_count(&"battery") == 9, "an over-capacity cache changes no inventory stacks")
	_check(not WorldState.is_opened(cache.persistent_id), "an over-capacity cache remains sealed for a later visit")

	InventorySystem.set_items({&"battery": 8})
	cache.interact(null)
	_check(InventorySystem.get_count(&"battery") == 10, "a cache transfers its full payload once it fits")
	_check(WorldState.is_opened(cache.persistent_id), "a fully recovered cache persists as searched")
	cache.free()


func _test_choice_capacity_is_atomic() -> void:
	WorldState.clear()
	InventorySystem.set_items({&"battery": 9})
	var cache := Node2D.new()
	cache.name = "CapacityChoiceCache"
	add_child(cache)

	var chosen := ChoiceOption.new()
	chosen.name = "BatteryBundle"
	chosen.choice_group = &"crafting_capacity_test_choice"
	chosen.option_id = &"battery_bundle"
	chosen.loot = {&"battery": 1}
	chosen.keepsake_item = &"battery"
	cache.add_child(chosen)
	var alternative := ChoiceOption.new()
	alternative.name = "Alternative"
	alternative.choice_group = chosen.choice_group
	alternative.option_id = &"alternative"
	cache.add_child(alternative)

	chosen.interact(null)
	_check(InventorySystem.get_count(&"battery") == 9, "an over-capacity choice changes no inventory stacks")
	_check(not WorldState.choice_taken(chosen.choice_group), "an over-capacity choice remains unresolved")
	_check(chosen.is_available() and alternative.is_available(), "a failed choice locks neither option")

	InventorySystem.set_items({&"battery": 8})
	chosen.interact(null)
	_check(InventorySystem.get_count(&"battery") == 10, "a choice transfers its full combined reward once it fits")
	_check(WorldState.chosen_option(chosen.choice_group) == "battery_bundle", "a fully recovered choice persists its selected option")
	_check(not chosen.is_available() and not alternative.is_available(), "a successful choice locks every sibling option")
	cache.free()


func _test_unlocks_and_atomic_craft() -> void:
	InventorySystem.set_items({&"clean_cloth": 2, &"resin_tape": 1})
	ArchiveSystem.restore([])
	var locked := CraftingSystem.get_status(&"field_dressing", 1, &"field_kit")
	_check(locked.code == CraftingSystem.MISSING_ECHOES, "recipe reports its missing echo gate")

	ArchiveSystem.restore([&"echo_clinic_triage"])
	var wrong_station := CraftingSystem.get_status(&"field_dressing", 1, &"signal_bench")
	_check(wrong_station.code == CraftingSystem.WRONG_STATION, "recipe rejects the wrong station")
	_check(CraftingSystem.can_craft(&"field_dressing", 1, &"field_kit"), "unlocked recipe with materials is craftable")

	var crafted := CraftingSystem.craft(&"field_dressing", 1, &"field_kit")
	_check(bool(crafted.ok), "field dressing craft succeeds")
	_check(InventorySystem.get_count(&"clean_cloth") == 0, "successful craft consumes cloth")
	_check(InventorySystem.get_count(&"resin_tape") == 0, "successful craft consumes tape")
	_check(InventorySystem.get_count(&"field_dressing") == 2, "successful craft grants the full output")

	InventorySystem.set_items({
		&"clean_cloth": 2,
		&"resin_tape": 1,
		&"field_dressing": 9,
	})
	var before := InventorySystem.get_items()
	var full := CraftingSystem.craft(&"field_dressing", 1, &"field_kit")
	_check(full.code == CraftingSystem.OUTPUT_FULL, "craft reports output-capacity failure")
	_check(InventorySystem.get_items() == before, "full output stack consumes no ingredients")

	ArchiveSystem.restore([&"echo_last_signal"])
	WorldState.set_flag(&"memory_burst_unlocked", false)
	var missing_flag := CraftingSystem.get_status(&"signal_decoy", 1, &"signal_bench")
	_check(missing_flag.code == CraftingSystem.MISSING_FLAGS, "campaign flag gates are enforced")


func _test_bulk_craft_and_signal_count() -> void:
	ArchiveSystem.restore([&"echo_bus_ledger"])
	InventorySystem.set_items({&"scrap": 4})
	_inventory_signal_count = 0
	_item_added_signal_count = 0
	InventorySystem.inventory_changed.connect(_on_inventory_changed)
	InventorySystem.item_added.connect(_on_item_added)

	var result := CraftingSystem.craft(&"lock_shim", 2, &"field_kit")
	_check(bool(result.ok), "bulk craft succeeds")
	_check(InventorySystem.get_count(&"scrap") == 0, "bulk craft consumes scaled ingredients")
	_check(InventorySystem.get_count(&"lock_shim") == 2, "bulk craft grants scaled output")
	_check(_inventory_signal_count == 1, "one craft transaction emits one inventory refresh")
	_check(_item_added_signal_count == 1, "one output stack emits one item-added event")

	InventorySystem.inventory_changed.disconnect(_on_inventory_changed)
	InventorySystem.item_added.disconnect(_on_item_added)


func _on_inventory_changed() -> void:
	_inventory_signal_count += 1


func _on_item_added(_item_id: StringName, _amount: int) -> void:
	_item_added_signal_count += 1


func _reset_state() -> void:
	InventorySystem.set_items({})
	ArchiveSystem.restore([])
	WorldState.clear()


func _contains(lines: PackedStringArray, fragment: String) -> bool:
	for line in lines:
		if fragment in line:
			return true
	return false


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
