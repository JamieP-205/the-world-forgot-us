extends Node
## Autoload: ArchiveSystem
##
## The Railhome Archive's memory. Records every memory echo the player
## recovers, de-duplicated by id. This is the backbone of "memory as
## progression": later the Memorial Wall UI, achievements, NPC trust,
## and ending conditions all read from here.

## Emitted when a new (not previously recovered) echo is recorded.
signal echo_recorded(data: MemoryEchoData)

const VERIFIED: StringName = &"verified"
const FED: StringName = &"fed"

var _recovered: Array[MemoryEchoData] = []
var _dispositions: Dictionary = {}


## Records an echo and the player's handling decision. No-op if null or
## already recovered; a record cannot quietly change provenance later.
func record_echo(data: MemoryEchoData, disposition: StringName = VERIFIED) -> void:
	if data == null or has_echo(data.id):
		return
	disposition = _normalise_disposition(disposition)
	_dispositions[data.id] = disposition
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


func get_disposition(id: StringName) -> StringName:
	return StringName(_dispositions.get(id, VERIFIED))


## JSON-safe decision map stored alongside the legacy id array in saves.
func get_dispositions() -> Dictionary:
	var out: Dictionary = {}
	for data in _recovered:
		out[String(data.id)] = String(get_disposition(data.id))
	return out


## Restores saved echo ids and optional decisions. Older saves omit the map
## and therefore remain verified records by default.
func restore(ids: Array, dispositions: Dictionary = {}) -> void:
	_recovered.clear()
	_dispositions.clear()
	var seen: Dictionary = {}
	for raw_id in ids:
		var id := StringName(str(raw_id))
		if id == &"" or seen.has(id):
			continue
		seen[id] = true
		var data := EchoDatabase.get_echo(id)
		if data == null:
			push_warning("ArchiveSystem: skipped unknown saved echo '%s'." % id)
			continue
		_dispositions[id] = _normalise_disposition(StringName(
			dispositions.get(String(id), dispositions.get(id, VERIFIED))))
		_recovered.append(data)


func _normalise_disposition(disposition: StringName) -> StringName:
	return FED if disposition == FED else VERIFIED
