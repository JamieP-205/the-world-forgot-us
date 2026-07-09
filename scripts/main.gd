class_name Main
extends Node2D
## Persistent game root.
##
## Main owns the things that must survive travel between locations -- the
## Player, the camera (a child of the Player), and the HUD -- and holds a
## single swappable "level" underneath LevelHolder.

@export var start_level: PackedScene
@export var start_spawn: StringName = &""

@onready var _world_tint: CanvasModulate = $WorldTint
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
	_load_level.call_deferred(scene, spawn)


func _load_level(scene: PackedScene, spawn: StringName) -> void:
	if _current_level != null:
		_current_level.free()
		_current_level = null

	_current_level = scene.instantiate()
	_current_level_path = scene.resource_path
	_level_holder.add_child(_current_level)
	_apply_level_tint()
	_place_player(spawn)
	EventBus.level_loaded.emit()


func get_current_level_path() -> String:
	return _current_level_path


func get_current_level() -> Node:
	return _current_level


func _apply_level_tint() -> void:
	if _world_tint == null:
		return
	if _current_level_path == GameManager.BASE_SCENE_PATH:
		_world_tint.color = Color(0.92, 0.82, 0.66, 1.0)
	else:
		_world_tint.color = Color(0.64, 0.72, 0.72, 1.0)


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
