class_name BuildingDoor
extends SceneExit
## A real threshold into an authored interior, or the matching way back out.

const BuildingCatalog = preload("res://scripts/world/building_catalog.gd")

@export var building_id: StringName = &""
@export_file("*.tscn") var return_scene_path: String = ""
@export var return_spawn: StringName = &""
@export var returns_to_world := false


func get_prompt() -> String:
	if returns_to_world:
		return "Leave %s" % String(WorldState.get_flag(&"interior_title", "the building"))
	if BuildingCatalog.has(building_id):
		return "Enter %s" % BuildingCatalog.display_name(building_id)
	return prompt


func interact(_player: Node2D) -> void:
	if returns_to_world:
		var world_path := String(WorldState.get_flag(&"interior_return_scene", ""))
		var world_spawn := StringName(WorldState.get_flag(&"interior_return_spawn", ""))
		if world_path.is_empty():
			push_warning("BuildingDoor: interior has no return scene.")
			return
		EventBus.notice_posted.emit("Back outside. The carrier sounds farther away for a moment.")
		GameManager.travel_to(world_path, world_spawn)
		return

	if not BuildingCatalog.has(building_id):
		push_warning("BuildingDoor '%s' has unknown building id '%s'." % [name, building_id])
		return
	if return_scene_path.is_empty() or return_spawn == &"":
		push_warning("BuildingDoor '%s' has no safe return threshold." % name)
		return

	var title := BuildingCatalog.display_name(building_id)
	var theme := String(BuildingCatalog.get_building(building_id).get("theme", ""))
	WorldState.set_flag(&"active_interior_id", String(building_id))
	WorldState.set_flag(&"active_interior_theme", theme)
	WorldState.set_flag(&"interior_title", title)
	WorldState.set_flag(&"interior_return_scene", return_scene_path)
	WorldState.set_flag(&"interior_return_spawn", String(return_spawn))
	WorldState.set_flag(StringName("entered_%s" % String(building_id)))
	EventBus.notice_posted.emit("%s. The receiver drops half a bar at the threshold." % title)
	GameManager.travel_to(BuildingCatalog.INTERIOR_SCENE_PATH, &"from_world")
