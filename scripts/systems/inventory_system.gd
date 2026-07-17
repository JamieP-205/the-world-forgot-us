extends Node
## Autoload: InventorySystem
##
## Id -> count inventory with authored stack limits and atomic transactions.
## Slots, weight and equipment can still be layered on later; crafting only
## relies on the transaction API below.

## Emitted after any change; UI listens to this to refresh itself.
signal inventory_changed

## Emitted when items are gained (useful later for pickup popups/sounds).
signal item_added(item_id: StringName, amount: int)

## item id -> count
var _items: Dictionary = {}


func add_item(item_id: StringName, amount: int = 1) -> int:
	if amount <= 0:
		return 0
	if not ItemDatabase.has_item(item_id):
		push_warning("InventorySystem: rejected unknown item id '%s'." % item_id)
		return 0
	var accepted := mini(amount, get_stack_limit(item_id) - get_count(item_id))
	if accepted <= 0:
		return 0
	_items[item_id] = get_count(item_id) + accepted
	item_added.emit(item_id, accepted)
	inventory_changed.emit()
	return accepted


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


func get_stack_limit(item_id: StringName) -> int:
	var data: ItemData = ItemDatabase.get_item(item_id)
	return maxi(data.stack_size, 1) if data != null else 0


func has_items(requirements: Dictionary) -> bool:
	return get_missing_items(requirements).is_empty()


func get_missing_items(requirements: Dictionary) -> Dictionary:
	var missing := {}
	for item_id in _normalised_ids(requirements):
		var required := int(requirements.get(item_id, requirements.get(String(item_id), 0)))
		if required <= 0:
			continue
		var shortfall := required - get_count(item_id)
		if shortfall > 0:
			missing[item_id] = shortfall
	return missing


## Returns whether a complete consume/produce operation would fit. The check
## runs against a copy, including space freed by consumed ingredients.
func can_apply_transaction(consumed: Dictionary, produced: Dictionary = {}) -> bool:
	return _transaction_snapshot(consumed, produced) != null


## Commits a consume/produce operation once, or changes nothing. This is the
## only API crafting uses, so an output-capacity failure never eats materials.
func apply_transaction(consumed: Dictionary, produced: Dictionary = {}) -> bool:
	var snapshot: Variant = _transaction_snapshot(consumed, produced)
	if snapshot == null:
		return false
	var candidate: Dictionary = snapshot
	_items = candidate
	for item_id in _normalised_ids(produced):
		var amount := int(produced.get(item_id, produced.get(String(item_id), 0)))
		if amount > 0:
			item_added.emit(item_id, amount)
	inventory_changed.emit()
	return true


func remove_items_atomic(requirements: Dictionary) -> bool:
	return apply_transaction(requirements, {})


func add_items_atomic(items: Dictionary) -> bool:
	return apply_transaction({}, items)


## Read-only snapshot for UI and SaveManager.
func get_items() -> Dictionary:
	var ordered := {}
	for item_id in _normalised_ids(_items):
		ordered[item_id] = int(_items[item_id])
	return ordered


## Restores a saved id -> count snapshot.
func set_items(items: Dictionary) -> void:
	_items.clear()
	for item_id in _normalised_ids(items):
		var amount := int(items.get(item_id, items.get(String(item_id), 0)))
		if amount <= 0:
			continue
		if not ItemDatabase.has_item(item_id):
			push_warning("InventorySystem: skipped unknown restored item '%s'." % item_id)
			continue
		_items[item_id] = mini(amount, get_stack_limit(item_id))
	inventory_changed.emit()


func _transaction_snapshot(consumed: Dictionary, produced: Dictionary) -> Variant:
	if not _is_valid_transaction_dictionary(consumed) or not _is_valid_transaction_dictionary(produced):
		return null
	var candidate := _items.duplicate()
	for item_id in _normalised_ids(consumed):
		var amount := int(consumed.get(item_id, consumed.get(String(item_id), 0)))
		if amount <= 0 or not ItemDatabase.has_item(item_id) or int(candidate.get(item_id, 0)) < amount:
			return null
		candidate[item_id] = int(candidate.get(item_id, 0)) - amount
		if int(candidate[item_id]) == 0:
			candidate.erase(item_id)
	for item_id in _normalised_ids(produced):
		var amount := int(produced.get(item_id, produced.get(String(item_id), 0)))
		if amount <= 0 or not ItemDatabase.has_item(item_id):
			return null
		var next_count := int(candidate.get(item_id, 0)) + amount
		if next_count > get_stack_limit(item_id):
			return null
		candidate[item_id] = next_count
	return candidate


func _is_valid_transaction_dictionary(items: Dictionary) -> bool:
	for raw_id in items:
		var item_id := StringName(str(raw_id))
		if item_id == &"" or not ItemDatabase.has_item(item_id) or int(items[raw_id]) <= 0:
			return false
	return true


func _normalised_ids(items: Dictionary) -> Array[StringName]:
	var ids: Array[StringName] = []
	for raw_id in items:
		var item_id := StringName(str(raw_id))
		if item_id != &"" and item_id not in ids:
			ids.append(item_id)
	ids.sort_custom(func(left: StringName, right: StringName) -> bool:
		return String(left) < String(right)
	)
	return ids
