extends Node
## Autoload: EchoDatabase
##
## Loads every MemoryEchoData .tres from ECHOES_DIR at startup and provides
## id -> MemoryEchoData lookups. Mirrors ItemDatabase. Used by save/load to
## rebuild the ArchiveSystem from saved ids, and available to a future
## archive UI.

const ECHOES_DIR := "res://resources/echoes"

## id (StringName) -> MemoryEchoData
var _echoes: Dictionary = {}


func _ready() -> void:
	_load_echoes()


func has_echo(id: StringName) -> bool:
	return _echoes.has(id)


func get_echo(id: StringName) -> MemoryEchoData:
	return _echoes.get(id)


func _load_echoes() -> void:
	var dir := DirAccess.open(ECHOES_DIR)
	if dir == null:
		push_error("EchoDatabase: cannot open '%s'." % ECHOES_DIR)
		return

	for file_name in dir.get_files():
		# In exported builds resources are renamed to "*.tres.remap".
		var res_name := file_name.trim_suffix(".remap")
		if not res_name.ends_with(".tres"):
			continue
		var echo := load("%s/%s" % [ECHOES_DIR, res_name]) as MemoryEchoData
		if echo == null or echo.id == &"":
			push_warning("EchoDatabase: skipped invalid echo '%s'." % res_name)
			continue
		_echoes[echo.id] = echo
