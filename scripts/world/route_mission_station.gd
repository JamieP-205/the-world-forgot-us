class_name RouteMissionStation
extends Interactable
## A physical work card for one route-exclusive field job.

const Contracts = preload("res://scripts/narrative/route_mission_contracts.gd")

@export_range(0, 1) var mission_slot := 0
@export_enum("clinic", "radio", "witness", "copy") var required_anchor := "clinic"
@export var station_label := "field work card"

@onready var _lamp: Polygon2D = $Visual/StatusLamp


func _ready() -> void:
	add_to_group("objective_targets")
	EventBus.narrative_state_changed.connect(_on_narrative_state_changed)
	EventBus.campaign_progress_changed.connect(_refresh)
	_refresh()


func get_mission_id() -> StringName:
	var missions := CampaignSystem.get_route_mission_definitions()
	if mission_slot < 0 or mission_slot >= missions.size():
		return &""
	return StringName(missions[mission_slot].get("id", &""))


func is_available() -> bool:
	return visible and get_mission_id() != &"" \
		and CampaignSystem.can_interact(get_mission_id())


func get_prompt() -> String:
	var mission_id := get_mission_id()
	if mission_id == &"":
		return "The work card is still blank"
	var mission := CampaignSystem.get_route_mission_definitions()[mission_slot]
	var title := String(mission.get("title", station_label))
	match CampaignSystem.get_route_mission_state(mission_id):
		&"available": return "Read the job card: %s" % title
		&"active":
			var remaining := Contracts.unmet_steps(mission_id).size()
			return "Sign off %s" % title if remaining == 0 else "Review %s (%d checks left)" % [title, remaining]
		&"complete": return "Read the signed-off job: %s" % title
	return "Review %s" % station_label


func interact(_player: Node2D) -> void:
	var mission_id := get_mission_id()
	if mission_id == &"" or not is_available():
		return
	var state := CampaignSystem.get_route_mission_state(mission_id)
	if state != &"active":
		CampaignSystem.request_interaction(mission_id)
		return
	var unmet := Contracts.unmet_steps(mission_id)
	if not unmet.is_empty():
		EventBus.notice_posted.emit("FIELD CARD / %s\n%s" % [
			Contracts.progress_text(mission_id), Contracts.unmet_summary(mission_id),
		])
		return
	if not Contracts.consume_completion_cost(mission_id):
		EventBus.notice_posted.emit("The field tool is missing. Make another before signing this off.")
		return
	if CampaignSystem.complete_route_mission(mission_id):
		AudioManager.play(&"relay_restore", -2.0, 1.08)
		EventBus.notice_posted.emit("ROUTE JOB SIGNED OFF\n%s is now part of your field plan." % _service_label(mission_id))
		CampaignSystem.request_interaction(mission_id)


func _service_label(mission_id: StringName) -> String:
	for mission in CampaignSystem.get_route_mission_definitions():
		if StringName(mission.get("id", &"")) == mission_id:
			return String(mission.get("service_unlock", "The field service")).replace("_", " ").capitalize()
	return "The field service"


func _refresh() -> void:
	var state := CampaignSystem.get_narrative_state()
	var route_matches := String(state.get("route_anchor", "")) == required_anchor \
		and not String(state.get("network_strategy", "")).is_empty()
	visible = route_matches
	monitorable = route_matches
	var mission_id := get_mission_id()
	set_meta("story_id", mission_id)
	set_meta("mission_slot", mission_slot)
	set_meta("required_anchor", required_anchor)
	if _lamp != null:
		var mission_state := CampaignSystem.get_route_mission_state(mission_id)
		_lamp.color = (
			Color(0.34, 0.92, 0.72, 0.95) if mission_state == &"complete"
			else Color(1.0, 0.72, 0.28, 0.95) if mission_state == &"active"
			else Color(0.42, 0.84, 0.86, 0.88)
		)


func _on_narrative_state_changed(_snapshot: Dictionary) -> void:
	_refresh()
