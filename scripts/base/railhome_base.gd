class_name RailhomeBase
extends Node2D
## Carriage 317's local presentation controller. Geometry remains explicitly
## authored in the scene; this script only reflects durable upgrade, route and
## population state onto optional visual groups.

signal shelter_state_changed(snapshot: Dictionary)

const CELL_PITCH := 68.0
const SHELTER_BOUNDS := Rect2(-612.0, -306.0, 1224.0, 612.0)
const MAIN_ROUTE := Rect2(-552.0, -60.0, 1136.0, 120.0)

var _snapshot: Dictionary = {}


func _ready() -> void:
	add_to_group("railhome_bases")
	if not BaseUpgradeSystem.upgrade_built.is_connected(_on_upgrade_built):
		BaseUpgradeSystem.upgrade_built.connect(_on_upgrade_built)
	if not EventBus.campaign_progress_changed.is_connected(refresh_shelter_state):
		EventBus.campaign_progress_changed.connect(refresh_shelter_state)
	call_deferred("refresh_shelter_state")


func get_layout_contract() -> Dictionary:
	var zones: Dictionary = {}
	var functions: Dictionary = {}
	for node in get_tree().get_nodes_in_group("railhome_layout_zones"):
		if is_ancestor_of(node):
			zones[StringName(node.get_meta("zone_id", &""))] = node.get_meta("bounds", Rect2())
	for node in get_tree().get_nodes_in_group("railhome_functional_zones"):
		if is_ancestor_of(node):
			functions[StringName(node.get_meta("zone_id", &""))] = (node as Node2D).global_position
	return {
		"cell_pitch": CELL_PITCH,
		"shelter_bounds": SHELTER_BOUNDS,
		"main_route": MAIN_ROUTE,
		"zones": zones,
		"functional_zones": functions,
	}


func get_shelter_snapshot() -> Dictionary:
	return _snapshot.duplicate(true)


func refresh_shelter_state() -> void:
	apply_shelter_state({
		"built_upgrades": _built_upgrade_ids(),
		"route_stage": _route_stage(),
		"occupant_count": _visible_occupant_count(),
	})


## Public, data-only hook for save restoration, previews and focused tests.
## Missing keys fall back to the current durable state.
func apply_shelter_state(state: Dictionary) -> void:
	var built: Array[StringName] = []
	for raw_id in state.get("built_upgrades", _built_upgrade_ids()):
		var upgrade_id := StringName(str(raw_id))
		if upgrade_id != &"":
			built.append(upgrade_id)
	var route_stage := maxi(int(state.get("route_stage", _route_stage())), 0)
	var occupant_count := maxi(int(state.get("occupant_count", _visible_occupant_count())), 0)
	_snapshot = {
		"built_upgrades": built.duplicate(),
		"route_stage": route_stage,
		"occupant_count": occupant_count,
	}

	_apply_upgrade_visuals(built)
	_apply_staged_visibility("railhome_route_state", "min_route_stage", route_stage)
	_apply_staged_visibility("railhome_occupancy_state", "min_occupants", occupant_count)
	var lantern_built := &"base_lantern" in built
	for node in get_tree().get_nodes_in_group("railhome_warm_lights"):
		if is_ancestor_of(node):
			node.visible = lantern_built
	for node in get_tree().get_nodes_in_group("railhome_cold_lights"):
		if is_ancestor_of(node) and node is PointLight2D:
			var base_energy := float(node.get_meta("base_energy", 0.52))
			(node as PointLight2D).energy = base_energy * (0.56 if lantern_built else 1.0)
	shelter_state_changed.emit(get_shelter_snapshot())


func _apply_upgrade_visuals(built: Array[StringName]) -> void:
	for node in get_tree().get_nodes_in_group("railhome_upgrade_state"):
		if not is_ancestor_of(node):
			continue
		var upgrade_id := StringName(node.get_meta("upgrade_id", &""))
		node.visible = upgrade_id in built
	for node in get_tree().get_nodes_in_group("railhome_upgrade_benches"):
		if not is_ancestor_of(node) or not node.has_method("apply_built_state"):
			continue
		var data: BaseUpgradeData = node.get("upgrade_data") as BaseUpgradeData
		node.call("apply_built_state", data != null and data.id in built)


func _apply_staged_visibility(group_name: StringName, meta_name: StringName, current: int) -> void:
	for node in get_tree().get_nodes_in_group(group_name):
		if is_ancestor_of(node):
			node.visible = current >= int(node.get_meta(meta_name, 1))


func _built_upgrade_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for raw_id in BaseUpgradeSystem.get_built_ids():
		ids.append(StringName(str(raw_id)))
	ids.sort_custom(func(left: StringName, right: StringName) -> bool:
		return String(left) < String(right)
	)
	return ids


func _route_stage() -> int:
	if CampaignSystem.has_method("get_restored_relay_count"):
		return maxi(int(CampaignSystem.call("get_restored_relay_count")), 0)
	return 1 if WorldState.has_flag(&"wrenfield_route_verified") else 0


func _visible_occupant_count() -> int:
	for population in get_tree().get_nodes_in_group("npc_populations"):
		if is_ancestor_of(population) and population.has_method("get_spawned_actors"):
			return (population.call("get_spawned_actors", false) as Array).size()
	return 0


func _on_upgrade_built(_data: BaseUpgradeData) -> void:
	refresh_shelter_state()
