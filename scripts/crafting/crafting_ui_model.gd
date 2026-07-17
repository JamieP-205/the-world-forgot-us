class_name CraftingUIModel
extends RefCounted
## Deterministic presentation model shared by the overlay and headless tests.


func get_recipe_rows(station_filter: StringName = &"") -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for recipe in CraftingRecipeDatabase.get_recipes():
		if station_filter != &"" and recipe.station_id != station_filter:
			continue
		rows.append(_build_row(recipe))
	return rows


func get_recipe_row(recipe_id: StringName) -> Dictionary:
	var recipe := CraftingRecipeDatabase.get_recipe(recipe_id)
	return _build_row(recipe) if recipe != null else {}


func _build_row(recipe: CraftingRecipeData) -> Dictionary:
	var craft_status := CraftingSystem.get_status(recipe.id)
	var output := ItemDatabase.get_item(recipe.output_item_id)
	var effect := CraftedItemEffects.get_definition(recipe.output_item_id)
	var ingredients: Array[Dictionary] = []
	for item_id in recipe.get_ingredient_ids():
		var item := ItemDatabase.get_item(item_id)
		var needed := int(recipe.ingredients.get(item_id, recipe.ingredients.get(String(item_id), 0)))
		var owned := InventorySystem.get_count(item_id)
		ingredients.append({
			"item_id": item_id,
			"name": item.display_name if item != null else String(item_id),
			"icon": item.icon if item != null else null,
			"owned": owned,
			"needed": needed,
			"enough": owned >= needed,
		})
	var state := "ready" if bool(craft_status.get("ok", false)) else _state_for_code(StringName(craft_status.get("code", &"")))
	return {
		"recipe_id": recipe.id,
		"title": recipe.display_name,
		"description": recipe.description,
		"category": recipe.category,
		"station_id": recipe.station_id,
		"station_label": recipe.station_label,
		"output_item_id": recipe.output_item_id,
		"output_name": output.display_name if output != null else String(recipe.output_item_id),
		"output_icon": output.icon if output != null else null,
		"output_amount": recipe.output_amount,
		"output_owned": InventorySystem.get_count(recipe.output_item_id),
		"output_stack_limit": InventorySystem.get_stack_limit(recipe.output_item_id),
		"ingredients": ingredients,
		"craftable": bool(craft_status.get("ok", false)),
		"craft_code": StringName(craft_status.get("code", &"")),
		"state": state,
		"status_text": _craft_status_text(recipe, craft_status),
		"unlock_note": recipe.unlock_note,
		"missing_records": _missing_record_titles(craft_status),
		"use_action": effect.action_label if effect != null else "NO FIELD USE",
		"use_summary": effect.use_summary if effect != null else "No field use has been authored.",
		"consequence": effect.consequence if effect != null else "Keep it for a later repair.",
		"consumes_on_use": effect.consumes_on_use if effect != null else false,
	}


func _craft_status_text(recipe: CraftingRecipeData, status: Dictionary) -> String:
	var code := StringName(status.get("code", &""))
	match code:
		CraftingSystem.OK:
			return "Materials checked. The method is ready."
		CraftingSystem.MISSING_FLAGS, CraftingSystem.MISSING_ECHOES:
			return recipe.unlock_note
		CraftingSystem.MISSING_INGREDIENTS:
			return "The work can wait; the missing materials cannot be improvised safely."
		CraftingSystem.OUTPUT_FULL:
			return "The field kit has no room for the finished stack."
	return String(status.get("reason", "The method is unavailable."))


func _missing_record_titles(status: Dictionary) -> PackedStringArray:
	var titles := PackedStringArray()
	for echo_id in status.get("missing_echoes", []):
		var echo := EchoDatabase.get_echo(echo_id)
		titles.append(echo.title if echo != null else String(echo_id))
	titles.sort()
	return titles


func _state_for_code(code: StringName) -> String:
	if code in [CraftingSystem.MISSING_FLAGS, CraftingSystem.MISSING_ECHOES]:
		return "locked"
	if code == CraftingSystem.MISSING_INGREDIENTS:
		return "materials"
	if code == CraftingSystem.OUTPUT_FULL:
		return "full"
	return "unavailable"
