class_name CraftingRecipeData
extends Resource
## Authored definition for one analogue-survival recipe.
##
## Recipes contain data only. CraftingSystem owns progression checks and the
## inventory transaction, keeping a future bench or field-kit UI declarative.

@export var id: StringName = &""
@export var display_name := ""
@export_multiline var description := ""
@export var category: StringName = &"fieldcraft"
@export var station_id: StringName = &"field_kit"
@export var station_label := "Field kit"
@export var sort_order := 0

## item id -> quantity consumed for one craft.
@export var ingredients: Dictionary = {}
@export var output_item_id: StringName = &""
@export_range(1, 99, 1) var output_amount := 1

## All listed requirements must be met. They are knowledge gates and are not
## consumed when the recipe is made.
@export var required_flags: Array[StringName] = []
@export var required_echoes: Array[StringName] = []
@export_multiline var unlock_note := ""


func scaled_ingredients(craft_count: int = 1) -> Dictionary:
	var scaled := {}
	if craft_count <= 0:
		return scaled
	for item_id in get_ingredient_ids():
		scaled[item_id] = int(ingredients.get(item_id, ingredients.get(String(item_id), 0))) * craft_count
	return scaled


func get_ingredient_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for raw_id in ingredients:
		var item_id := StringName(str(raw_id))
		if item_id != &"" and item_id not in ids:
			ids.append(item_id)
	ids.sort_custom(func(left: StringName, right: StringName) -> bool:
		return String(left) < String(right)
	)
	return ids
