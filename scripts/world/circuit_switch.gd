class_name CircuitSwitch
extends Interactable
## One physical switch in a persistent multi-node rerouting puzzle.
## Every switch must be touched; CampaignSystem validates the authored target.

@export var circuit_id: StringName = &"south_line"
@export var switch_id: StringName = &"feed"
@export var required_on: bool = true
@export var initial_on: bool = false
@export var on_label: String = "LINE"
@export var off_label: String = "GROUND"

@onready var _lever: Node2D = $Visual/Lever
@onready var _lamp: Polygon2D = $Visual/Lamp

var _is_on := false


func _ready() -> void:
	add_to_group("objective_targets")
	set_meta("story_id", StringName("circuit_%s_%s" % [circuit_id, switch_id]))
	_is_on = CampaignSystem.get_circuit_switch_state(circuit_id, switch_id, initial_on)
	CampaignSystem.register_circuit_switch(circuit_id, switch_id, required_on)
	_refresh_visual(false)


func get_prompt() -> String:
	if CampaignSystem.is_circuit_complete(circuit_id):
		return "%s circuit locked" % String(circuit_id).replace("_", " ").capitalize()
	return "Set %s to %s" % [String(switch_id).replace("_", " "), off_label if _is_on else on_label]


func is_available() -> bool:
	return not CampaignSystem.is_circuit_complete(circuit_id)


func interact(_player: Node2D) -> void:
	if not is_available():
		return
	_is_on = not _is_on
	CampaignSystem.set_circuit_switch(circuit_id, switch_id, _is_on)
	_refresh_visual(true)


func _refresh_visual(with_feedback: bool) -> void:
	if _lever != null:
		_lever.rotation = deg_to_rad(30.0 if _is_on else -30.0)
	if _lamp != null:
		_lamp.color = Color(0.34, 0.95, 0.82, 0.95) if _is_on else Color(0.92, 0.38, 0.22, 0.82)
	if with_feedback:
		AudioManager.play(&"relay_restore", 0.0, 1.18 if _is_on else 0.82)
		EventBus.notice_posted.emit(
			"%s / %s: %s\nSouth-line switches aligned: %d / 3."
			% [String(circuit_id).replace("_", " ").to_upper(), String(switch_id).replace("_", " ").to_upper(), on_label if _is_on else off_label, CampaignSystem.get_circuit_alignment(circuit_id)])
