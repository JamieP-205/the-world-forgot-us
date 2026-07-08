extends Node
## Autoload: GameManager
##
## Owns global game state. For now that's only pausing; later it will
## coordinate scene transitions (base <-> world), the day/storm cycle,
## and save/load.

## Home base -- where the player wakes after dying.
const BASE_SCENE_PATH := "res://scenes/base/railhome_base.tscn"

var is_paused := false


func _ready() -> void:
	# Keep processing input while the tree is paused so Esc can unpause.
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.player_died.connect(_on_player_died)


func _unhandled_input(event: InputEvent) -> void:
	# Only pause during actual gameplay (the Main root is in the tree). On the
	# main menu there is no Main node, so Esc must not freeze the menu.
	if event.is_action_pressed("pause") and get_tree().get_first_node_in_group("main") != null:
		set_paused(not is_paused)


func set_paused(paused: bool) -> void:
	is_paused = paused
	get_tree().paused = paused
	EventBus.paused_changed.emit(paused)


## Travels to another level, placing the player at the named spawn point.
## Called by SceneExit interactables. Loads the scene here (so callers pass
## a path and there are no circular scene dependencies) and hands the swap
## to Main via EventBus. This is the natural place to hook "save on travel"
## and the day/storm cycle later.
func travel_to(scene_path: String, spawn: StringName = &"") -> void:
	if scene_path.is_empty():
		return
	var scene := load(scene_path) as PackedScene
	if scene == null:
		push_error("GameManager: could not load level '%s'." % scene_path)
		return
	if is_paused:
		set_paused(false)
	EventBus.travel_requested.emit(scene, spawn)


## On death, the player wakes back at the Railhome (the player heals itself).
func _on_player_died() -> void:
	travel_to(BASE_SCENE_PATH, &"from_world")
