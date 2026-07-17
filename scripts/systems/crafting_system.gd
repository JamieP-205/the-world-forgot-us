extends Node
## Autoload: CraftingSystem
##
## Evaluates knowledge gates and commits each craft as one inventory
## transaction. No ingredient is spent unless every output can be stored.

signal craft_completed(recipe: CraftingRecipeData, craft_count: int)
signal craft_rejected(recipe_id: StringName, code: StringName)

const OK := &"ok"
const UNKNOWN_RECIPE := &"unknown_recipe"
const INVALID_COUNT := &"invalid_count"
const WRONG_STATION := &"wrong_station"
const MISSING_FLAGS := &"missing_flags"
const MISSING_ECHOES := &"missing_echoes"
const MISSING_INGREDIENTS := &"missing_ingredients"
const OUTPUT_FULL := &"output_full"
const INVENTORY_CHANGED := &"inventory_changed"


func get_status(
	recipe_id: StringName,
	craft_count: int = 1,
	station_id: StringName = &""
) -> Dictionary:
	var recipe := CraftingRecipeDatabase.get_recipe(recipe_id)
	if recipe == null:
		return _status(false, UNKNOWN_RECIPE, "Unknown recipe.")
	if craft_count <= 0:
		return _status(false, INVALID_COUNT, "Craft count must be positive.", recipe)
	if station_id != &"" and station_id != recipe.station_id:
		var wrong_station := _status(false, WRONG_STATION, "This recipe needs the %s." % recipe.station_label, recipe)
		wrong_station["required_station"] = recipe.station_id
		return wrong_station

	var missing_flags: Array[StringName] = []
	for flag_id in recipe.required_flags:
		if not WorldState.has_flag(flag_id):
			missing_flags.append(flag_id)
	missing_flags.sort_custom(_sort_names)
	if not missing_flags.is_empty():
		var locked_flags := _status(false, MISSING_FLAGS, "The method has not been learned yet.", recipe)
		locked_flags["missing_flags"] = missing_flags
		return locked_flags

	var missing_echoes: Array[StringName] = []
	for echo_id in recipe.required_echoes:
		if not ArchiveSystem.has_echo(echo_id):
			missing_echoes.append(echo_id)
	missing_echoes.sort_custom(_sort_names)
	if not missing_echoes.is_empty():
		var locked_echoes := _status(false, MISSING_ECHOES, "A field record still holds part of this method.", recipe)
		locked_echoes["missing_echoes"] = missing_echoes
		return locked_echoes

	var consumed := recipe.scaled_ingredients(craft_count)
	var missing_items := InventorySystem.get_missing_items(consumed)
	if not missing_items.is_empty():
		var shortfall := _status(false, MISSING_INGREDIENTS, "Required materials are missing.", recipe)
		shortfall["missing_items"] = missing_items
		shortfall["consumed"] = consumed
		return shortfall

	var produced := {recipe.output_item_id: recipe.output_amount * craft_count}
	if not InventorySystem.can_apply_transaction(consumed, produced):
		var full := _status(false, OUTPUT_FULL, "There is no room for the finished item.", recipe)
		full["consumed"] = consumed
		full["produced"] = produced
		return full

	var ready := _status(true, OK, "Ready to make.", recipe)
	ready["consumed"] = consumed
	ready["produced"] = produced
	ready["craft_count"] = craft_count
	return ready


func can_craft(recipe_id: StringName, craft_count: int = 1, station_id: StringName = &"") -> bool:
	return bool(get_status(recipe_id, craft_count, station_id).get("ok", false))


func craft(recipe_id: StringName, craft_count: int = 1, station_id: StringName = &"") -> Dictionary:
	var status := get_status(recipe_id, craft_count, station_id)
	if not bool(status.get("ok", false)):
		craft_rejected.emit(recipe_id, StringName(status.get("code", UNKNOWN_RECIPE)))
		return status

	var consumed: Dictionary = status["consumed"]
	var produced: Dictionary = status["produced"]
	if not InventorySystem.apply_transaction(consumed, produced):
		var changed := _status(
			false,
			INVENTORY_CHANGED,
			"Supplies changed before the work was finished.",
			CraftingRecipeDatabase.get_recipe(recipe_id)
		)
		craft_rejected.emit(recipe_id, INVENTORY_CHANGED)
		return changed

	var recipe := CraftingRecipeDatabase.get_recipe(recipe_id)
	craft_completed.emit(recipe, craft_count)
	status["reason"] = "%s made." % recipe.display_name
	return status


func get_recipes_for_station(station_id: StringName, include_locked := true) -> Array[CraftingRecipeData]:
	var result: Array[CraftingRecipeData] = []
	for recipe in CraftingRecipeDatabase.get_recipes():
		if station_id != &"" and recipe.station_id != station_id:
			continue
		if include_locked or _requirements_met(recipe):
			result.append(recipe)
	return result


func _requirements_met(recipe: CraftingRecipeData) -> bool:
	for flag_id in recipe.required_flags:
		if not WorldState.has_flag(flag_id):
			return false
	for echo_id in recipe.required_echoes:
		if not ArchiveSystem.has_echo(echo_id):
			return false
	return true


func _status(ok: bool, code: StringName, reason: String, recipe: CraftingRecipeData = null) -> Dictionary:
	return {
		"ok": ok,
		"code": code,
		"reason": reason,
		"recipe_id": recipe.id if recipe != null else &"",
	}


func _sort_names(left: StringName, right: StringName) -> bool:
	return String(left) < String(right)
