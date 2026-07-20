class_name SceneExit
extends Interactable
## A doorway/exit the player uses to travel to another level.
##
## Set target_scene_path to the destination .tscn and target_spawn to the
## name of a Marker2D (in the "spawn_points" group) inside that scene. Both
## the world map and the base use these to reach each other, forming the
## return-to-base loop. Paths (not PackedScenes) are used so two levels can
## reference each other without a circular load dependency.

const NPCServiceRulesScript = preload("res://scripts/narrative/npc_service_rules.gd")

## Destination level, e.g. "res://scenes/base/railhome_base.tscn".
@export_file("*.tscn") var target_scene_path: String = ""

## Marker2D name to spawn the player on in the destination level.
@export var target_spawn: StringName = &""
@export_enum("road", "embedded_door", "painted_door") var presentation := "road"


func _ready() -> void:
	_apply_presentation()


func _apply_presentation() -> void:
	var embedded := presentation == "embedded_door"
	var road := presentation == "road"
	for node_name in [&"Frame", &"DoorCrossbar"]:
		var item := get_node_or_null(NodePath(String(node_name))) as CanvasItem
		if item != null:
			item.visible = embedded
	for node_name in [&"Doorway", &"Handle"]:
		var item := get_node_or_null(NodePath(String(node_name))) as CanvasItem
		if item != null:
			# Interior thresholds need a visible, closed door. Hiding the panel
			# exposed the black world apron through the wall gap and made the
			# exit look like an untextured rectangle.
			item.visible = embedded
	for node_name in [&"RoadThreshold", &"Beacon", &"Arrow"]:
		var item := get_node_or_null(NodePath(String(node_name))) as CanvasItem
		if item != null:
			item.visible = road


func interact(player: Node2D) -> void:
	if target_scene_path.is_empty():
		push_warning("SceneExit '%s' has no target_scene_path." % name)
		return
	apply_return_services(player)
	_post_travel_notice()
	GameManager.travel_to(target_scene_path, target_spawn)


## Idris's repairs matter on ordinary wounded returns, not only on death.
## The cap is enforced by Player.set_health(), so repeated travel cannot
## create health above the player's normal maximum.
func apply_return_services(player: Node2D) -> float:
	if target_scene_path != GameManager.BASE_SCENE_PATH or player == null:
		return 0.0
	var amount := NPCServiceRulesScript.railhome_recovery_amount()
	if amount <= 0.0 or not player.has_method("get_health") or not player.has_method("set_health"):
		return 0.0
	var before := float(player.call("get_health"))
	player.call("set_health", before + amount)
	var restored := maxf(float(player.call("get_health")) - before, 0.0)
	if restored > 0.0:
		EventBus.notice_posted.emit(
			"Idris's braced bunks and clean air restore %d health." % roundi(restored))
	return restored


func _post_travel_notice() -> void:
	if target_scene_path == GameManager.BASE_SCENE_PATH:
		EventBus.notice_posted.emit("Carriage 317. Door still locked. Lamp still on.")
	elif target_scene_path.ends_with("test_map.tscn"):
		EventBus.notice_posted.emit("Back on the cracked road.")
