class_name RouteFinaleController
extends Node2D
## Builds the route's physical final operation from three manual cabinets.
## Restore opens every channel, Mesh isolates the middle carrier, and Sever
## grounds all three. Every cabinet must be visited and thrown by hand.

const SWITCH_SCENE := preload("res://scenes/world/circuit_switch.tscn")
const SWITCH_IDS := [&"archive", &"carrier", &"failsafe"]
const POSITIONS := [Vector2(-470, 0), Vector2(0, -135), Vector2(470, 0)]
const PATTERNS := {
	&"restore": [true, true, true],
	&"mesh": [true, false, true],
	&"sever": [false, false, false],
}


func _ready() -> void:
	add_to_group("route_finale_controllers")
	var strategy := StringName(CampaignSystem.get_narrative_state().get("network_strategy", &""))
	if not PATTERNS.has(strategy):
		visible = false
		return
	var pattern: Array = PATTERNS[strategy]
	for index in range(SWITCH_IDS.size()):
		var cabinet := SWITCH_SCENE.instantiate() as CircuitSwitch
		if cabinet == null:
			continue
		var switch_id: StringName = SWITCH_IDS[index]
		var required_on := bool(pattern[index])
		cabinet.name = "RouteFinale%s" % String(switch_id).to_pascal_case()
		cabinet.position = POSITIONS[index]
		cabinet.circuit_id = &"route_finale"
		cabinet.switch_id = switch_id
		cabinet.required_on = required_on
		cabinet.initial_on = not required_on
		cabinet.activation_flag = &"route_finale_started"
		cabinet.on_label = _on_label(strategy, switch_id)
		cabinet.off_label = _off_label(strategy, switch_id)
		add_child(cabinet)
	set_meta("route_id", CampaignSystem.get_active_route_id())
	set_meta("strategy", strategy)
	set_meta("operation_nodes", SWITCH_IDS.size())


func _on_label(strategy: StringName, switch_id: StringName) -> String:
	if strategy == &"restore":
		return "AUDITED %s" % String(switch_id).to_upper()
	if strategy == &"mesh":
		return "LOCAL %s" % String(switch_id).to_upper()
	return "LIVE %s" % String(switch_id).to_upper()


func _off_label(strategy: StringName, switch_id: StringName) -> String:
	if strategy == &"sever":
		return "GROUND %s" % String(switch_id).to_upper()
	if strategy == &"mesh":
		return "ISOLATE %s" % String(switch_id).to_upper()
	return "CLOSED %s" % String(switch_id).to_upper()
