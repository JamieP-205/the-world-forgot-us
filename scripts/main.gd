class_name Main
extends Node2D
## Persistent game root.
##
## Main owns the things that must survive travel between locations -- the
## Player, the camera (a child of the Player), and the HUD -- and holds a
## single swappable "level" underneath LevelHolder.

const DEFAULT_CAMERA_ZOOM := Vector2(1.9, 1.9)

@export var start_level: PackedScene
@export var start_spawn: StringName = &""

@onready var _level_holder: Node2D = $LevelHolder
@onready var _player: Player = $Player
@onready var _camera: Camera2D = $Player/Camera2D
@onready var _day_night_cycle: DayNightCycle = $DayNightCycle

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
	if _day_night_cycle != null:
		_day_night_cycle.configure_level(_current_level_path)
	_place_player(spawn)
	_configure_camera_limits()
	EventBus.level_loaded.emit()


func get_current_level_path() -> String:
	return _current_level_path


func get_current_level() -> Node:
	return _current_level


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
	_camera.zoom = _level_camera_zoom()
	var bounds_node := _current_level.get_node_or_null("CameraBounds") as Node2D
	if bounds_node == null:
		bounds_node = _current_level.get_node_or_null("Ground") as Node2D
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


func _level_camera_zoom() -> Vector2:
	var requested: Variant = _current_level.get_meta("camera_zoom", DEFAULT_CAMERA_ZOOM)
	if requested is Vector2:
		var zoom_value := requested as Vector2
		if zoom_value.x > 0.0 and zoom_value.y > 0.0:
			return zoom_value
	return DEFAULT_CAMERA_ZOOM


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


func get_day_phase() -> float:
	return _day_night_cycle.phase if _day_night_cycle != null else 0.25


func get_day_phase_name() -> StringName:
	return _day_night_cycle.get_phase_name() if _day_night_cycle != null else &"day"


func is_night() -> bool:
	return _day_night_cycle != null and _day_night_cycle.is_night()
