class_name RouteSalvageRecovery
extends RefCounted
## A progression safety net attached to Maggie's physical parts drawers.
## It calculates the current job's real recipe tree, replaces only missing raw
## inputs, runs the authored recipe, then seals one result against that mission
## card. Sealed tools cannot be spent on optional actions or farmed repeatedly.

const RECOVERY_COUNT_FLAG := &"route_salvage_recovery_count"
const MIN_SEARCHED_CACHES_BY_SLOT: Array[int] = [3, 6]


static func recover_current_mission() -> Dictionary:
	var missions := CampaignSystem.get_route_mission_definitions()
	for slot in range(missions.size()):
		var mission_id := StringName(missions[slot].get("id", &""))
		if CampaignSystem.get_route_mission_state(mission_id) != &"complete":
			return recover_for_slot(slot)
	return _result(false, {}, "Both route work cards are already signed off.")


static func recover_for_slot(slot: int = 0) -> Dictionary:
	var mission_id := mission_id_for_slot(slot)
	if mission_id == &"":
		return _result(false, {}, "Choose a route before opening the job-parts drawer.")
	var mission_state := CampaignSystem.get_route_mission_state(mission_id)
	if mission_state == &"complete":
		return _result(false, {}, "That work card is already signed off.")
	if mission_state != &"active":
		return _result(false, {}, "Read and accept the work card before breaking its emergency seal.")
	var required_searches := required_search_count_for_slot(slot)
	var searched := WorldState.get_searched_cache_count()
	if searched < required_searches:
		var remaining := required_searches - searched
		return _result(false, {}, "Search %d more supply cache%s before using the emergency job stock." % [
			remaining, "" if remaining == 1 else "s",
		])
	var item_id := StringName(CampaignSystem.get_route_mission_contract(mission_id).get("cost_item", &""))
	if item_id == &"":
		return _result(false, {}, "The active work card has no material schedule.")
	if has_reserved_tool(mission_id, item_id):
		return _result(false, {}, "A sealed %s is already signed to this work card." % _item_name(item_id))
	if WorldState.has_flag(_claim_flag(mission_id)):
		return _result(false, {}, "This work card's emergency stock has already been sealed.")
	if InventorySystem.get_count(item_id) > 0:
		return _result(false, {}, "The finished route tool is already in the field kit.")

	var missing := missing_raw_for_item(item_id, 1)
	if missing.is_empty():
		return _result(false, {}, "The parts for %s are already in the kit." % _item_name(item_id))
	var inventory_before := InventorySystem.get_items()
	if not InventorySystem.add_items_atomic(missing):
		return _result(false, {}, "The route-parts drawer cannot fit in the field kit yet.")
	var recipe := _recipe_for_output(item_id)
	if recipe != null:
		var crafted := _craft_item_for_recovery(item_id, 1, [])
		if not bool(crafted.get("ok", false)):
			InventorySystem.set_items(inventory_before)
			return _result(false, {}, String(crafted.get(
				"reason", "The emergency assembly did not hold. No stock was spent.")))
		var produced := InventorySystem.get_count(item_id) - int(inventory_before.get(item_id, 0))
		if produced <= 0 or not InventorySystem.remove_item(item_id, 1):
			InventorySystem.set_items(inventory_before)
			return _result(false, {}, "The emergency assembly could not be signed into the work card.")
	elif not InventorySystem.remove_item(item_id, 1):
		InventorySystem.set_items(inventory_before)
		return _result(false, {}, "The raw job stock could not be signed into the work card.")

	var count := int(WorldState.get_flag(RECOVERY_COUNT_FLAG, 0)) + 1
	WorldState.set_flag(RECOVERY_COUNT_FLAG, count)
	WorldState.set_flag(_claim_flag(mission_id))
	WorldState.set_flag(_escrow_flag(mission_id), String(item_id))
	WorldState.set_flag(&"route_salvage_recovery_last_mission", String(mission_id))
	var parts: Array[String] = []
	for raw_id in _sorted_ids(missing):
		parts.append("%d %s" % [int(missing[raw_id]), _item_name(raw_id)])
	var message := "Maggie's job drawer replaces the missing raw stock and seals one %s to the work card: %s." % [_item_name(item_id), ", ".join(parts)]
	EventBus.notice_posted.emit(message)
	if Engine.get_main_loop() is SceneTree \
			and (Engine.get_main_loop() as SceneTree).get_first_node_in_group("main") != null:
		SaveManager.save_game("")
	return _result(true, missing, message)


static func has_reserved_tool(
		mission_id: StringName,
		item_id: StringName,
		amount: int = 1,
	) -> bool:
	return amount <= 1 \
		and StringName(str(WorldState.get_flag(_escrow_flag(mission_id), ""))) == item_id


static func consume_reserved_tool(mission_id: StringName, item_id: StringName) -> bool:
	if not has_reserved_tool(mission_id, item_id):
		return false
	WorldState.set_flag(_escrow_flag(mission_id), false)
	return true


static func mission_id_for_slot(slot: int) -> StringName:
	var missions := CampaignSystem.get_route_mission_definitions()
	if slot < 0 or slot >= missions.size():
		return &""
	return StringName(missions[slot].get("id", &""))


static func required_search_count_for_slot(slot: int) -> int:
	if slot < 0 or slot >= MIN_SEARCHED_CACHES_BY_SLOT.size():
		return MIN_SEARCHED_CACHES_BY_SLOT.back()
	return MIN_SEARCHED_CACHES_BY_SLOT[slot]


static func _claim_flag(mission_id: StringName) -> StringName:
	return StringName("route_salvage_claimed_%s" % String(mission_id))


static func _escrow_flag(mission_id: StringName) -> StringName:
	return StringName("route_salvage_reserved_%s" % String(mission_id))


static func missing_raw_for_item(item_id: StringName, amount: int = 1) -> Dictionary:
	var stock := InventorySystem.get_items().duplicate(true)
	var missing: Dictionary = {}
	_plan_item(item_id, maxi(amount, 1), stock, missing, [])
	return missing


static func _craft_item_for_recovery(
		item_id: StringName,
		amount: int,
		chain: Array[StringName],
	) -> Dictionary:
	if InventorySystem.get_count(item_id) >= amount:
		return {"ok": true, "reason": "Already in stock."}
	var recipe := _recipe_for_output(item_id)
	if recipe == null:
		return {"ok": false, "reason": "No field method can make %s." % _item_name(item_id)}
	if item_id in chain:
		return {"ok": false, "reason": "The field method for %s contains a cycle." % _item_name(item_id)}

	var next_chain: Array[StringName] = chain.duplicate()
	next_chain.append(item_id)
	var missing_amount := amount - InventorySystem.get_count(item_id)
	var craft_count: int = ceili(float(missing_amount) / float(recipe.output_amount))
	for ingredient_id in recipe.get_ingredient_ids():
		var per_craft := int(recipe.ingredients.get(
			ingredient_id, recipe.ingredients.get(String(ingredient_id), 0)))
		var ingredient_result := _craft_item_for_recovery(
			ingredient_id, per_craft * craft_count, next_chain)
		if not bool(ingredient_result.get("ok", false)):
			return ingredient_result

	var status := CraftingSystem.get_status(recipe.id, craft_count, recipe.station_id)
	if not bool(status.get("ok", false)):
		return status
	var crafted := CraftingSystem.craft(recipe.id, craft_count, recipe.station_id)
	if not bool(crafted.get("ok", false)):
		return crafted
	if InventorySystem.get_count(item_id) < amount:
		return {"ok": false, "reason": "The emergency assembly produced too little %s." % _item_name(item_id)}
	return crafted


static func raw_requirements_for_item(item_id: StringName, amount: int = 1) -> Dictionary:
	var stock: Dictionary = {}
	var missing: Dictionary = {}
	_plan_item(item_id, maxi(amount, 1), stock, missing, [])
	return missing


static func _plan_item(
		item_id: StringName,
		amount: int,
		stock: Dictionary,
		missing: Dictionary,
		chain: Array[StringName],
	) -> bool:
	var held := int(stock.get(item_id, 0))
	var used := mini(held, amount)
	if used > 0:
		stock[item_id] = held - used
		if int(stock[item_id]) <= 0:
			stock.erase(item_id)
	var remaining := amount - used
	if remaining <= 0:
		return true

	var recipe := _recipe_for_output(item_id)
	if recipe == null:
		missing[item_id] = int(missing.get(item_id, 0)) + remaining
		return true
	if item_id in chain:
		return false
	var next_chain: Array[StringName] = chain.duplicate()
	next_chain.append(item_id)
	var craft_count := ceili(float(remaining) / float(recipe.output_amount))
	for ingredient_id in recipe.get_ingredient_ids():
		var per_craft := int(recipe.ingredients.get(
			ingredient_id, recipe.ingredients.get(String(ingredient_id), 0)))
		if not _plan_item(ingredient_id, per_craft * craft_count, stock, missing, next_chain):
			return false
	var surplus := recipe.output_amount * craft_count - remaining
	if surplus > 0:
		stock[item_id] = int(stock.get(item_id, 0)) + surplus
	return true


static func _recipe_for_output(item_id: StringName) -> CraftingRecipeData:
	for recipe in CraftingRecipeDatabase.get_recipes():
		if recipe.output_item_id == item_id:
			return recipe
	return null


static func _item_name(item_id: StringName) -> String:
	var data := ItemDatabase.get_item(item_id)
	return data.display_name if data != null else String(item_id).replace("_", " ")


static func _sorted_ids(items: Dictionary) -> Array[StringName]:
	var ids: Array[StringName] = []
	for raw_id in items:
		ids.append(StringName(raw_id))
	ids.sort()
	return ids


static func _result(ok: bool, granted: Dictionary, reason: String) -> Dictionary:
	return {"ok": ok, "granted": granted.duplicate(true), "reason": reason}
