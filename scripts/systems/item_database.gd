extends Node
## Autoload: ItemDatabase
##
## Loads every ItemData .tres from ITEMS_DIR at startup and provides
## id -> ItemData lookups for the inventory, loot containers, and (later)
## crafting, trading, and the memory archive.
##
## To add a new item: duplicate any .tres in resources/items/, change its
## id and display fields, done -- no code changes needed.

const ITEMS_DIR := "res://resources/items"

## id (StringName) -> ItemData
var _items: Dictionary = {}


func _ready() -> void:
	_load_items()


func has_item(item_id: StringName) -> bool:
	return _items.has(item_id)


func get_item(item_id: StringName) -> ItemData:
	return _items.get(item_id)


func _load_items() -> void:
	var dir := DirAccess.open(ITEMS_DIR)
	if dir == null:
		push_error("ItemDatabase: cannot open '%s'." % ITEMS_DIR)
		return

	for file_name in dir.get_files():
		# In exported builds resources are renamed to "*.tres.remap".
		var res_name := file_name.trim_suffix(".remap")
		if not res_name.ends_with(".tres"):
			continue
		var item := load("%s/%s" % [ITEMS_DIR, res_name]) as ItemData
		if item == null or item.id == &"":
			push_warning("ItemDatabase: skipped invalid item '%s'." % res_name)
			continue
		_items[item.id] = item
