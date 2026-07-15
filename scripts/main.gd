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
		_world_tint.color = Color(0.72, 0.62, 0.50, 1.0)
	elif _current_level_path.ends_with("ashmere_verge.tscn"):
		_world_tint.color = Color(0.52, 0.60, 0.63, 1.0)
	elif _current_level_path.ends_with("broadcast_fields.tscn"):
		_world_tint.color = Color(0.46, 0.55, 0.63, 1.0)
	elif _current_level_path.ends_with("choir_core.tscn"):
		_world_tint.color = Color(0.40, 0.49, 0.58, 1.0)
	else:
		_world_tint.color = Color(0.58, 0.64, 0.66, 1.0)


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
	var bounds_node := _current_level.get_node_or_null("Ground") as Node2D
	if bounds_node == null:
		bounds_node = _current_level.get_node_or_null("Floor") as Node2D
	if bounds_node == null:
		bounds_node = _current_level.get_node_or_null("WastelandApron") as Node2D
	var bounds := _world_bounds_for(bounds_node)
	if bounds.size.x <= 0.0 or bounds.size.y <= 0.0:
		return
	_camera.limit_left = floori(bounds.position.x)
	_camera.limit_top = floori(bounds.position.y)
	_camera.limit_right = ceili(bounds.end.x)
	_camera.limit_bottom = ceili(bounds.end.y)
	_camera.reset_smoothing()


func _world_bounds_for(node: Node2D) -> Rect2:
	if node == null:
		return Rect2()
	var local_bounds := Rect2()
	if node is Polygon2D:
		var polygon := (node as Polygon2D).polygon
		if polygon.is_empty():
			return Rect2()
		local_bounds = Rect2(polygon[0], Vector2.ZERO)
		for point in polygon:
			local_bounds = local_bounds.expand(point)
	elif node is Sprite2D:
		local_bounds = (node as Sprite2D).get_rect()
	else:
		return Rect2()
	var corners := PackedVector2Array([
		node.to_global(local_bounds.position),
		node.to_global(Vector2(local_bounds.end.x, local_bounds.position.y)),
		node.to_global(local_bounds.end),
		node.to_global(Vector2(local_bounds.position.x, local_bounds.end.y)),
	])
	var world_bounds := Rect2(corners[0], Vector2.ZERO)
	for corner in corners:
		world_bounds = world_bounds.expand(corner)
	return world_bounds


func _find_spawn(spawn: StringName) -> Marker2D:
	for node in get_tree().get_nodes_in_group("spawn_points"):
		if node is Marker2D and node.name == spawn:
			return node as Marker2D
	return null
