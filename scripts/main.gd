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
@onready var _camera: Camera2D = $Player/Camera2D

var _current_level: Node = null
var _current_level_path: String = ""


func _ready() -> void:
	add_to_group("main")
	LightingDirector.install(self)
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
	_configure_camera_limits()
	EventBus.level_loaded.emit()


func get_current_level_path() -> String:
	return _current_level_path


func get_current_level() -> Node:
	return _current_level


func _apply_level_tint() -> void:
	if _world_tint == null:
		return
	if _current_level_path == GameManager.BASE_SCENE_PATH:
		_world_tint.color = Color(0.56, 0.46, 0.34, 1.0)
	elif _current_level_path.ends_with("ashmere_verge.tscn"):
		_world_tint.color = Color(0.34, 0.43, 0.47, 1.0)
	elif _current_level_path.ends_with("broadcast_fields.tscn"):
		_world_tint.color = Color(0.28, 0.37, 0.44, 1.0)
	elif _current_level_path.ends_with("choir_core.tscn"):
		_world_tint.color = Color(0.22, 0.31, 0.39, 1.0)
	else:
		_world_tint.color = Color(0.42, 0.50, 0.53, 1.0)


func _place_player(spawn: StringName) -> void:
	if spawn == &"":
		return
	var marker := _find_spawn(spawn)
	if marker != null:
		_player.global_position = marker.global_position
	else:
		push_warning("Main: spawn point '%s' not found in level." % spawn)


func _configure_camera_limits() -> void:
	if _camera == null or _current_level == null:
		return
	var ground := _current_level.get_node_or_null("Ground") as Polygon2D
	if ground == null:
		ground = _current_level.get_node_or_null("Floor") as Polygon2D
	if ground == null or ground.polygon.is_empty():
		return
	var first := ground.to_global(ground.polygon[0])
	var bounds := Rect2(first, Vector2.ZERO)
	for point in ground.polygon:
		bounds = bounds.expand(ground.to_global(point))
	_camera.limit_left = floori(bounds.position.x)
	_camera.limit_top = floori(bounds.position.y)
	_camera.limit_right = ceili(bounds.end.x)
	_camera.limit_bottom = ceili(bounds.end.y)
	_camera.reset_smoothing()


func _find_spawn(spawn: StringName) -> Marker2D:
	for node in get_tree().get_nodes_in_group("spawn_points"):
		if node is Marker2D and node.name == spawn:
			return node as Marker2D
	return null
