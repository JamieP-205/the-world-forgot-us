extends Node
## Autoload: CraftingRecipeDatabase
##
## Loads and validates authored recipes once. File discovery and public lists
## are sorted so tests and future recipe menus never depend on directory order.

const RECIPES_DIR := "res://resources/recipes"

var _recipes: Dictionary = {}
var _ordered_ids: Array[StringName] = []
var _validation_errors := PackedStringArray()


func _ready() -> void:
	reload()


func reload() -> void:
	_recipes.clear()
	_ordered_ids.clear()
	_validation_errors.clear()

	var dir := DirAccess.open(RECIPES_DIR)
	if dir == null:
		_validation_errors.append("Cannot open recipe directory: %s" % RECIPES_DIR)
		push_warning("CraftingRecipeDatabase: cannot open '%s'." % RECIPES_DIR)
		return

	var file_names := dir.get_files()
	file_names.sort()
	var loaded_paths := {}
	for file_name in file_names:
		var resource_name := file_name.trim_suffix(".remap")
		if not resource_name.ends_with(".tres"):
			continue
		var resource_path := "%s/%s" % [RECIPES_DIR, resource_name]
		if loaded_paths.has(resource_path):
			continue
		loaded_paths[resource_path] = true
		var recipe := load(resource_path) as CraftingRecipeData
		var errors := validate_recipe(recipe)
		if not errors.is_empty():
			for error in errors:
				_validation_errors.append("%s: %s" % [resource_name, error])
			push_warning("CraftingRecipeDatabase: skipped '%s': %s" % [resource_name, "; ".join(errors)])
			continue
		if _recipes.has(recipe.id):
			var duplicate := "%s: duplicate recipe id '%s'" % [resource_name, recipe.id]
			_validation_errors.append(duplicate)
			push_warning("CraftingRecipeDatabase: " + duplicate)
			continue
		_recipes[recipe.id] = recipe

	_ordered_ids.assign(_recipes.keys())
	_ordered_ids.sort_custom(func(left_id: StringName, right_id: StringName) -> bool:
		var left: CraftingRecipeData = _recipes[left_id]
		var right: CraftingRecipeData = _recipes[right_id]
		if left.sort_order != right.sort_order:
			return left.sort_order < right.sort_order
		return String(left.id) < String(right.id)
	)


func has_recipe(recipe_id: StringName) -> bool:
	return _recipes.has(recipe_id)


func get_recipe(recipe_id: StringName) -> CraftingRecipeData:
	return _recipes.get(recipe_id)


func get_recipe_ids() -> Array[StringName]:
	return _ordered_ids.duplicate()


func get_recipes() -> Array[CraftingRecipeData]:
	var result: Array[CraftingRecipeData] = []
	for recipe_id in _ordered_ids:
		result.append(_recipes[recipe_id])
	return result


func get_validation_errors() -> PackedStringArray:
	return _validation_errors.duplicate()


func validate_recipe(recipe: CraftingRecipeData) -> PackedStringArray:
	var errors := PackedStringArray()
	if recipe == null:
		errors.append("resource is not CraftingRecipeData")
		return errors
	if recipe.id == &"":
		errors.append("id is empty")
	if recipe.display_name.strip_edges().is_empty():
		errors.append("display name is empty")
	if recipe.description.strip_edges().is_empty():
		errors.append("description is empty")
	if recipe.unlock_note.strip_edges().is_empty():
		errors.append("unlock note is empty")
	if recipe.station_id == &"":
		errors.append("station id is empty")
	if recipe.ingredients.is_empty():
		errors.append("ingredients are empty")

	var seen_items := {}
	for raw_id in recipe.ingredients:
		var item_id := StringName(str(raw_id))
		if item_id == &"":
			errors.append("ingredient id is empty")
			continue
		if seen_items.has(item_id):
			errors.append("ingredient '%s' is listed more than once" % item_id)
			continue
		seen_items[item_id] = true
		var amount := int(recipe.ingredients[raw_id])
		if amount <= 0:
			errors.append("ingredient '%s' has a non-positive quantity" % item_id)
		if not ItemDatabase.has_item(item_id):
			errors.append("ingredient '%s' is not a known item" % item_id)

	if recipe.output_item_id == &"":
		errors.append("output item id is empty")
	elif not ItemDatabase.has_item(recipe.output_item_id):
		errors.append("output '%s' is not a known item" % recipe.output_item_id)
	elif recipe.output_amount > ItemDatabase.get_item(recipe.output_item_id).stack_size:
		errors.append("one craft exceeds the output stack limit")
	if recipe.output_amount <= 0:
		errors.append("output amount must be positive")

	_validate_requirement_ids(recipe.required_flags, "flag", errors)
	var seen_echoes := {}
	for echo_id in recipe.required_echoes:
		if echo_id == &"":
			errors.append("echo requirement is empty")
		elif seen_echoes.has(echo_id):
			errors.append("echo requirement '%s' is duplicated" % echo_id)
		else:
			seen_echoes[echo_id] = true
			if not EchoDatabase.has_echo(echo_id):
				errors.append("echo requirement '%s' is unknown" % echo_id)
	return errors


func _validate_requirement_ids(ids: Array[StringName], label: String, errors: PackedStringArray) -> void:
	var seen := {}
	for requirement_id in ids:
		if requirement_id == &"":
			errors.append("%s requirement is empty" % label)
		elif seen.has(requirement_id):
			errors.append("%s requirement '%s' is duplicated" % [label, requirement_id])
		else:
			seen[requirement_id] = true
