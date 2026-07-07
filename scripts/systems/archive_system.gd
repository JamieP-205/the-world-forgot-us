extends Node
## Autoload: ArchiveSystem
##
## The Railhome Archive's memory. Records every memory echo the player
## recovers, de-duplicated by id. This is the backbone of "memory as
## progression": later the Memorial Wall UI, achievements, NPC trust,
## and ending conditions all read from here.

## Emitted when a new (not previously recovered) echo is recorded.
signal echo_recorded(data: MemoryEchoData)

var _recovered: Array[MemoryEchoData] = []


## Records an echo. No-op if null or already recovered.
func record_echo(data: MemoryEchoData) -> void:
	if data == null or has_echo(data.id):
		return
	_recovered.append(data)
	echo_recorded.emit(data)


func has_echo(id: StringName) -> bool:
	for data in _recovered:
		if data.id == id:
			return true
	return false


func get_count() -> int:
	return _recovered.size()


## Read-only snapshot for UI and SaveManager.
func get_recovered() -> Array[MemoryEchoData]:
	return _recovered.duplicate()


func get_recovered_ids() -> Array:
	var ids := []
	for data in _recovered:
		ids.append(data.id)
	return ids


## Restores saved echo ids by looking up their authored data resources.
func restore(ids: Array) -> void:
	_recovered.clear()
	for raw_id in ids:
		var id := StringName(str(raw_id))
		var data := EchoDatabase.get_echo(id)
		if data == null:
			push_warning("ArchiveSystem: skipped unknown saved echo '%s'." % id)
			continue
		_recovered.append(data)
		echo_recorded.emit(data)