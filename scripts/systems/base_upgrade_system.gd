extends Node
## Autoload: BaseUpgradeSystem
##
## Tracks which base upgrades have been built and spends the materials to
## build them. Built state lives here, not on the station nodes, because
## the base level is re-instanced on every visit.

## Emitted when an upgrade is successfully built.
signal upgrade_built(data: BaseUpgradeData)

## upgrade id -> true
var _built: Dictionary = {}


## True if the inventory holds every material in the upgrade's cost.
func can_afford(data: BaseUpgradeData) -> bool:
	if data == null:
		return false
	for item_id in data.cost:
		if InventorySystem.get_count(item_id) < int(data.cost[item_id]):
			return false
	return true


## Spends the cost and marks the upgrade built. Returns false (changing
## nothing) if it's already built or unaffordable.
func build(data: BaseUpgradeData) -> bool:
	if data == null or is_built(data.id) or not can_afford(data):
		return false
	for item_id in data.cost:
		InventorySystem.remove_item(item_id, int(data.cost[item_id]))
	_built[data.id] = true
	upgrade_built.emit(data)
	return true


func is_built(id: StringName) -> bool:
	return _built.get(id, false)


## Read-only snapshot for save/load.
func get_built_ids() -> Array:
	return _built.keys()


## Restores saved upgrade ids.
func restore(ids: Array) -> void:
	_built.clear()
	for raw_id in ids:
		var id := StringName(str(raw_id))
		if id != &"":
			_built[id] = true