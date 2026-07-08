class_name SceneExit
extends Interactable
## A doorway/exit the player uses to travel to another level.
##
## Set target_scene_path to the destination .tscn and target_spawn to the
## name of a Marker2D (in the "spawn_points" group) inside that scene. Both
## the world map and the base use these to reach each other, forming the
## return-to-base loop. Paths (not PackedScenes) are used so two levels can
## reference each other without a circular load dependency.

## Destination level, e.g. "res://scenes/base/railhome_base.tscn".
@export_file("*.tscn") var target_scene_path: String = ""

## Marker2D name to spawn the player on in the destination level.
@export var target_spawn: StringName = &""


func interact(_player: Node2D) -> void:
	if target_scene_path.is_empty():
		push_warning("SceneExit '%s' has no target_scene_path." % name)
		return
	_post_travel_notice()
	GameManager.travel_to(target_scene_path, target_spawn)


func _post_travel_notice() -> void:
	if target_scene_path == GameManager.BASE_SCENE_PATH:
		EventBus.notice_posted.emit("Railhome reached.")
	elif target_scene_path.ends_with("test_map.tscn"):
		EventBus.notice_posted.emit("Back on the cracked road.")
