class_name RouteSalvageReserve
extends Interactable
## Maggie's labelled emergency drawer beside the Ashmere work cards.

const Recovery = preload("res://scripts/crafting/route_salvage_recovery.gd")


func _ready() -> void:
	add_to_group("objective_targets")
	add_to_group("route_salvage_reserves")
	set_meta("story_id", &"route_salvage_reserve")


func get_prompt() -> String:
	if CampaignSystem.get_active_route_id() == &"":
		return "Check Maggie's labelled job-parts drawer"
	var missions := CampaignSystem.get_route_mission_definitions()
	for slot in range(missions.size()):
		var mission_id := StringName(missions[slot].get("id", &""))
		var state := CampaignSystem.get_route_mission_state(mission_id)
		if state == &"complete":
			continue
		if state != &"active":
			return "Emergency stock sealed - accept the work card first"
		var required := Recovery.required_search_count_for_slot(slot)
		var searched := WorldState.get_searched_cache_count()
		if searched < required:
			return "Emergency stock sealed - search %d more supply cache%s" % [
				required - searched, "" if required - searched == 1 else "s",
			]
		break
	return "Replace missing parts for the current work card"


func interact(_player: Node2D) -> void:
	recover_now()


func recover_now() -> Dictionary:
	return Recovery.recover_current_mission()
