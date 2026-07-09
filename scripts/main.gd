class_name Main
extends Node2D
## Persistent game root.
##
## Main owns the things that must survive travel between locations -- the
## Player, the camera (a child of the Player), and the HUD -- and holds a
## single swappable "level" underneath LevelHolder. Levels (the world map,
## the base) are therefore pure environment scenes with no player or UI in
## them, which keeps them small and reusable.
##
## Travel is driven entirely through EventBus.travel_requested, so nothing
## needs a direct reference to Main.

## Level loaded on startup (the world map for now).
@export var start_level: PackedScene

## Spawn point to use for the start level. &"" keeps the player where
## this scene's Player node is authored.
@export var start_spawn: StringName = &""

@onready var _level_holder: Node2D = $LevelHolder
@onready var _player: Player = $Player

var _current_level: Node = null
var _current_level_path: String = ""


func _ready() -> void:
	add_to_group("main")
	EventBus.travel_requested.connect(_on_travel_requested)
	if SaveManager.has_save() and SaveManager.load_game():
		return
	if start_level != null:
		_load_level(start_level, start_spawn)


func _on_travel_requested(scene: PackedScene, spawn: StringName) -> void:
	# Defer: the request originates from inside the current level (a
	# SceneExit.interact() call is still on the stack), so we must let that
	# unwind before freeing the level it belongs to.
	_load_level.call_deferred(scene, spawn)


func _load_level(scene: PackedScene, spawn: StringName) -> void:
	if _current_level != null:
		# Immediate free (safe now the input stack has unwound) so the old
		# level's spawn markers can't collide with the new level's.
		_current_level.free()
		_current_level = null

	_current_level = scene.instantiate()
	_current_level_path = scene.resource_path
	_level_holder.add_child(_current_level)
	_place_player(spawn)
	EventBus.level_loaded.emit()


func get_current_level_path() -> String:
	return _current_level_path


## The live level node under LevelHolder (for the HUD compass to locate the
## current objective target). May be null between travels.
func get_current_level() -> Node:
	return _current_level


## Moves the player onto the named spawn marker in the freshly loaded level.
func _place_player(spawn: StringName) -> void:
	if spawn == &"":
		return
	var marker := _find_spawn(spawn)
	if marker != null:
		_player.global_position = marker.global_position
	else:
		push_warning("Main: spawn point '%s' not found in level." % spawn)


func _find_spawn(spawn: StringName) -> Marker2D:
	for node in get_tree().get_nodes_in_group("spawn_points"):
		if node is Marker2D and node.name == spawn:
			return node as Marker2D
	return null