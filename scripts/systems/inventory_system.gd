extends Node
## Autoload: InventorySystem
##
## Minimal id -> count inventory. No slots, weight, or equipment yet.
## UI and gameplay code only talk to it through these methods and signals,
## so later upgrades (stack limits, encumbrance, a real inventory screen,
## save/load) won't break anything that uses it.

## Emitted after any change; UI listens to this to refresh itself.
signal inventory_changed

## Emitted when items are gained (useful later for pickup popups/sounds).
signal item_added(item_id: StringName, amount: int)

## item id -> count
var _items: Dictionary = {}


func add_item(item_id: StringName, amount: int = 1) -> void:
	if amount <= 0:
		return
	if not ItemDatabase.has_item(item_id):
		push_warning("InventorySystem: unknown item id '%s' (added anyway)." % item_id)
	_items[item_id] = get_count(item_id) + amount
	item_added.emit(item_id, amount)
	inventory_changed.emit()


## Returns false (and changes nothing) if there aren't enough items.
func remove_item(item_id: StringName, amount: int = 1) -> bool:
	if amount <= 0 or get_count(item_id) < amount:
		return false
	_items[item_id] -= amount
	if _items[item_id] <= 0:
		_items.erase(item_id)
	inventory_changed.emit()
	return true


func get_count(item_id: StringName) -> int:
	return _items.get(item_id, 0)


func get_total_count() -> int:
	var total := 0
	for count in _items.values():
		total += count
	return total


## Read-only snapshot for UI and SaveManager.
func get_items() -> Dictionary:
	return _items.duplicate()


## Restores a saved id -> count snapshot.
func set_items(items: Dictionary) -> void:
	_items.clear()
	for raw_id in items:
		var amount := int(items[raw_id])
		if amount <= 0:
			continue
		_items[StringName(str(raw_id))] = amount
	inventory_changed.emit()