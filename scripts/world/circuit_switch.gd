class_name CircuitSwitch
extends Interactable
## One physical switch in a persistent multi-node rerouting puzzle.
## Every switch must be touched; CampaignSystem validates the authored target.

const NPCServiceRulesScript = preload("res://scripts/narrative/npc_service_rules.gd")

@export var circuit_id: StringName = &"south_line"
@export var switch_id: StringName = &"feed"
@export var required_on: bool = true
@export var initial_on: bool = false
@export var on_label: String = "LINE"
@export var off_label: String = "GROUND"
@export var activation_flag: StringName = &""

@onready var _lever: Node2D = $Visual/Lever
@onready var _lamp: Polygon2D = $Visual/Lamp

var _is_on := false
var _survey_used_for_last_throw := false


func _ready() -> void:
	add_to_group("objective_targets")
	add_to_group("craft_bridge_targets")
	add_to_group("craft_repair_targets")
	set_meta("story_id", StringName("circuit_%s_%s" % [circuit_id, switch_id]))
	_is_on = CampaignSystem.get_circuit_switch_state(circuit_id, switch_id, initial_on)
	CampaignSystem.register_circuit_switch(circuit_id, switch_id, required_on)
	_refresh_visual(false)


func get_prompt() -> String:
	if activation_flag != &"" and not WorldState.has_flag(activation_flag):
		return "The operation has not begun"
	if CampaignSystem.is_circuit_complete(circuit_id):
		return "%s circuit locked" % String(circuit_id).replace("_", " ").capitalize()
	if _has_unused_grid_score():
		return "Owen's score: set %s to %s" % [
			String(switch_id).replace("_", " "), on_label if required_on else off_label,
		]
	return "Set %s to %s" % [String(switch_id).replace("_", " "), off_label if _is_on else on_label]


func is_available() -> bool:
	return (activation_flag == &"" or WorldState.has_flag(activation_flag)) \
		and not CampaignSystem.is_circuit_complete(circuit_id)


func interact(_player: Node2D) -> void:
	if not is_available():
		return
	_survey_used_for_last_throw = _has_unused_grid_score()
	_is_on = required_on if _survey_used_for_last_throw else not _is_on
	CampaignSystem.set_circuit_switch(circuit_id, switch_id, _is_on)
	_refresh_visual(true)
	_survey_used_for_last_throw = false


func can_apply_crafted_item(item_id: StringName) -> bool:
	if not is_available():
		return false
	var touched := WorldState.has_flag(_touch_flag())
	match item_id:
		&"circuit_bridge":
			return not touched
		&"wire_splicer":
			return touched and _is_on != required_on
	return false


func apply_crafted_item(item_id: StringName, _payload: Dictionary) -> bool:
	if not can_apply_crafted_item(item_id):
		return false
	_is_on = required_on
	CampaignSystem.set_circuit_switch(circuit_id, switch_id, _is_on)
	_refresh_visual(false)
	AudioManager.play(&"relay_restore", -1.5, 1.08)
	var action := "BRIDGED" if item_id == &"circuit_bridge" else "SPLICED"
	EventBus.notice_posted.emit(
		"%s / %s CONTACT %s\nThe cabinet now holds its marked %s position."
		% [String(circuit_id).replace("_", " ").to_upper(),
			String(switch_id).replace("_", " ").to_upper(), action,
			on_label if required_on else off_label])
	return true


func _touch_flag() -> StringName:
	return StringName("circuit_%s_%s_touched" % [circuit_id, switch_id])


func _has_unused_grid_score() -> bool:
	if WorldState.has_flag(StringName("circuit_%s_%s_touched" % [circuit_id, switch_id])):
		return false
	return NPCServiceRulesScript.has_grid_survey_for(CampaignSystem.get_active_route_id())


func _refresh_visual(with_feedback: bool) -> void:
	if _lever != null:
		_lever.rotation = deg_to_rad(30.0 if _is_on else -30.0)
	if _lamp != null:
		_lamp.color = Color(0.34, 0.95, 0.82, 0.95) if _is_on else Color(0.92, 0.38, 0.22, 0.82)
	if with_feedback:
		AudioManager.play(&"relay_restore", 0.0, 1.18 if _is_on else 0.82)
		var source := "OWEN'S SCORE / " if _survey_used_for_last_throw else ""
		EventBus.notice_posted.emit(
			"%s%s / %s: %s\nManual contacts aligned: %d / 3."
			% [source, String(circuit_id).replace("_", " ").to_upper(), String(switch_id).replace("_", " ").to_upper(), on_label if _is_on else off_label, CampaignSystem.get_circuit_alignment(circuit_id)])
