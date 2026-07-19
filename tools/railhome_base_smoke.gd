extends Node
## Focused contract for Carriage 317's authored layout, restoration state and
## collision-safe population schedules.

const RailhomeScene := preload("res://scenes/base/railhome_base.tscn")
const EXPECTED_ZONES: Array[StringName] = [&"recovery", &"operations", &"commons"]
const EXPECTED_FIXTURES := 12
const EXPECTED_RELOCATABLE_SURVIVORS := 9
const NPC_CLEARANCE := 22.0

var _failures: Array[String] = []


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var upgrades_before := BaseUpgradeSystem.get_built_ids()
	var world_before := WorldState.get_state()
	BaseUpgradeSystem.restore([&"scanner_coil", &"radio_desk", &"base_lantern"])

	var base := RailhomeScene.instantiate() as RailhomeBase
	_check(base != null, "Railhome scene instantiates as RailhomeBase")
	if base == null:
		_finish(upgrades_before, world_before)
		return
	add_child(base)
	await get_tree().process_frame
	await get_tree().process_frame

	_check_named_contracts(base)
	_check_layout_contract(base)
	var fixture_rects := _check_fixture_contract(base)
	_check_clear_route(base)
	_check_population_contract(base, fixture_rects)
	_check_upgrade_restoration(base)
	_check_staged_dressing(base)

	base.free()
	await get_tree().process_frame
	_finish(upgrades_before, world_before)


func _check_named_contracts(base: RailhomeBase) -> void:
	_check(base.y_sort_enabled, "Railhome root enables Y-sort")
	_check(
		base.get_meta("camera_zoom", Vector2.ZERO) == Vector2(1.3, 1.3),
		"Railhome widens the camera enough to read its connected work bays",
	)
	var camera_bounds := base.get_node_or_null("CameraBounds") as Polygon2D
	_check(camera_bounds != null, "Railhome defines carriage-only camera bounds")
	if camera_bounds != null:
		_check(
			_polygon_rect(camera_bounds.polygon) == RailhomeBase.SHELTER_BOUNDS,
			"camera bounds match the authored carriage shell",
		)
	var floor := base.get_node_or_null("Floor") as Polygon2D
	_check(floor != null, "Floor remains a direct Polygon2D contract")
	if floor != null:
		_check(_polygon_rect(floor.polygon) == Rect2(-760, -430, 1520, 860), "Floor bounds frame the full carriage apron")

	var spawn := base.get_node_or_null("from_world") as Marker2D
	_check(spawn != null, "from_world remains a direct Marker2D contract")
	if spawn != null:
		_check(spawn.is_in_group("spawn_points"), "from_world remains registered as a spawn point")
		_check(spawn.position == Vector2(466, 0), "from_world lands in the clear egress spine")
		_check_entry_frame(base, spawn)

	var outside := base.get_node_or_null("Outside") as Area2D
	_check(outside != null, "Outside remains a direct scene exit")
	if outside != null:
		_check(String(outside.get("target_scene_path")) == "res://scenes/maps/test_map.tscn", "Outside returns to Cullbrook")
		_check(StringName(outside.get("target_spawn")) == &"from_base", "Outside targets the authored exterior spawn")
		_check(outside.collision_layer == 4 and outside.collision_mask == 0, "Outside stays on the interactable layer")

	var bedroll := base.get_node_or_null("Bunks/Bedroll") as Area2D
	var coil := base.get_node_or_null("ScannerCoilBench") as Area2D
	var radio := base.get_node_or_null("RadioDeskStation") as Area2D
	_check(bedroll != null and bedroll.name == &"Bedroll", "Bedroll campaign target is preserved")
	_check(coil != null and coil.name == &"ScannerCoilBench", "ScannerCoilBench campaign target is preserved")
	_check(radio != null and radio.name == &"RadioDeskStation", "RadioDeskStation campaign target is preserved")
	for interactable in [bedroll, coil, radio]:
		if interactable != null:
			_check(interactable.collision_layer == 4 and interactable.collision_mask == 0, "%s stays on the interactable layer" % interactable.name)
	if coil != null:
		var coil_data := coil.get("upgrade_data") as BaseUpgradeData
		_check(coil_data != null and coil_data.id == &"scanner_coil", "Scanner bench keeps the scanner_coil upgrade ID")
	if radio != null:
		var radio_data := radio.get("upgrade_data") as BaseUpgradeData
		_check(radio_data != null and radio_data.id == &"radio_desk", "Radio desk keeps the radio_desk upgrade ID")
	var lantern := base.get_node_or_null("SignalLantern") as Area2D
	_check(lantern != null, "signal lantern station exists")
	if lantern != null:
		var lantern_data := lantern.get("upgrade_data") as BaseUpgradeData
		_check(lantern_data != null and lantern_data.id == &"base_lantern", "Signal lantern keeps the base_lantern upgrade ID")


func _check_entry_frame(base: RailhomeBase, spawn: Marker2D) -> void:
	var zoom: Vector2 = base.get_meta("camera_zoom", Vector2.ZERO)
	if zoom.x <= 0.0 or zoom.y <= 0.0:
		return
	var camera_bounds := base.get_node_or_null("CameraBounds") as Polygon2D
	if camera_bounds == null:
		return
	var bounds_rect := _polygon_rect(camera_bounds.polygon)
	var half_view := Vector2(1280.0 / zoom.x, 720.0 / zoom.y) * 0.5
	var camera_center := bounds_rect.get_center()
	if bounds_rect.size.x > half_view.x * 2.0:
		camera_center.x = clampf(
			spawn.position.x,
			bounds_rect.position.x + half_view.x,
			bounds_rect.end.x - half_view.x,
		)
	if bounds_rect.size.y > half_view.y * 2.0:
		camera_center.y = clampf(
			spawn.position.y,
			bounds_rect.position.y + half_view.y,
			bounds_rect.end.y - half_view.y,
		)
	var entry_frame := Rect2(camera_center - half_view, half_view * 2.0)
	for node_path in [
		"Workbench",
		"PowerLockerA",
		"PowerLockerB",
		"StorageBox",
		"MudBench",
		"CarvedInitials",
		"Outside",
	]:
		var fixture := base.get_node_or_null(node_path) as Node2D
		_check(
			fixture != null and entry_frame.has_point(fixture.position),
			"%s is visible in the first shelter frame" % node_path,
		)


func _check_layout_contract(base: RailhomeBase) -> void:
	var contract := base.get_layout_contract()
	_check(float(contract.get("cell_pitch", 0.0)) == 68.0, "layout keeps the 68-pixel authored pitch")
	_check(contract.get("shelter_bounds", Rect2()) == Rect2(-612, -220, 1224, 440), "layout exposes the carriage shell bounds")
	var route: Rect2 = contract.get("main_route", Rect2())
	_check(route == Rect2(-552, -60, 1136, 120), "layout exposes a continuous 120-pixel travel spine")
	var zones: Dictionary = contract.get("zones", {})
	_check(zones.size() == 3, "layout exposes exactly three readable bays")
	for zone_id in EXPECTED_ZONES:
		_check(zones.has(zone_id), "layout exposes the %s bay" % zone_id)
	if zones.has(&"recovery") and zones.has(&"operations") and zones.has(&"commons"):
		var recovery: Rect2 = zones[&"recovery"]
		var operations: Rect2 = zones[&"operations"]
		var commons: Rect2 = zones[&"commons"]
		_check(recovery.end.x < operations.position.x, "west recovery reads separately from operations")
		_check(operations.end.x < commons.position.x, "operations reads separately from east commons")
		_check(recovery.size.y == operations.size.y and operations.size.y == commons.size.y, "all three bays share the carriage depth")
	var functions: Dictionary = contract.get("functional_zones", {})
	for function_id in [
		&"threshold_mud_room", &"sleeping_medical", &"radio_investigation",
		&"workshop_crafting", &"storage_power", &"water_food", &"upgrade_stations",
	]:
		_check(functions.has(function_id), "layout marks %s" % function_id)


func _check_fixture_contract(base: RailhomeBase) -> Array[Rect2]:
	var fixtures: Array[Node] = []
	for node in get_tree().get_nodes_in_group("railhome_solid_fixtures"):
		if base.is_ancestor_of(node):
			fixtures.append(node)
	_check(fixtures.size() == EXPECTED_FIXTURES, "all twelve major fixtures expose authored footprints")
	var occupied: Array[Rect2] = []
	var fixture_ids: Dictionary = {}
	for fixture in fixtures:
		var fixture_id := StringName(fixture.get_meta("fixture_id", &""))
		var zone_id := StringName(fixture.get_meta("zone_id", &""))
		_check(fixture_id != &"", "%s has a stable fixture ID" % fixture.name)
		_check(not fixture_ids.has(fixture_id), "%s fixture ID is unique" % fixture_id)
		fixture_ids[fixture_id] = true
		_check(zone_id in EXPECTED_ZONES, "%s belongs to a readable bay" % fixture.name)

		var solid := fixture as StaticBody2D
		if solid == null:
			solid = fixture.find_child("SolidFootprint", true, false) as StaticBody2D
		_check(solid != null, "%s has a world-solid footprint" % fixture.name)
		if solid == null:
			continue
		_check(solid.collision_layer == 1 and solid.collision_mask == 0, "%s footprint stays on the world layer" % fixture.name)
		var collision: CollisionShape2D = null
		var solid_shapes := solid.find_children("*", "CollisionShape2D", true, false)
		if not solid_shapes.is_empty():
			collision = solid_shapes[0] as CollisionShape2D
		_check(collision != null and collision.shape != null, "%s has an enabled collision shape" % fixture.name)
		var occluder := solid.find_child("Occluder", true, false) as LightOccluder2D
		_check(occluder != null and occluder.occluder != null, "%s has an authored light occluder" % fixture.name)
		if collision == null or collision.shape == null:
			continue
		var footprint := _collision_rect_in_base(collision, base)
		occupied.append(footprint)
		var art := _first_textured_sprite(fixture)
		_check(art != null, "%s footprint is tied to visible prop art" % fixture.name)
		if art != null:
			var art_size := art.texture.get_size() * art.scale.abs()
			var width_ratio := footprint.size.x / maxf(art_size.x, 1.0)
			var height_ratio := footprint.size.y / maxf(art_size.y, 1.0)
			_check(width_ratio >= 0.68 and width_ratio <= 1.16, "%s collision width follows its painted footprint" % fixture.name)
			_check(height_ratio >= 0.35 and height_ratio <= 0.86, "%s collision depth follows its painted footprint" % fixture.name)
		if occluder != null and occluder.occluder != null:
			var occ_rect := _polygon_rect(occluder.occluder.polygon)
			var shape_rect := collision.shape.get_rect()
			_check(occ_rect.size.is_equal_approx(shape_rect.size), "%s occluder matches its solid footprint" % fixture.name)
	return occupied


func _check_clear_route(base: RailhomeBase) -> void:
	var route: Rect2 = base.get_layout_contract().get("main_route", Rect2())
	var spawn := base.get_node("from_world") as Marker2D
	_check(route.has_point(spawn.position), "spawn sits inside the 120-pixel travel spine")
	_check(route.has_point(Vector2(576, 0)), "travel spine reaches the exit threshold")
	for node in base.find_children("*", "StaticBody2D", true, false):
		var body := node as StaticBody2D
		for shape_node in body.find_children("*", "CollisionShape2D", true, false):
			var collision := shape_node as CollisionShape2D
			if collision.disabled or collision.shape == null:
				continue
			var solid_rect := _collision_rect_in_base(collision, base)
			_check(not route.intersects(solid_rect), "%s does not obstruct the 120-pixel travel spine" % collision.get_path())


func _check_population_contract(base: RailhomeBase, fixture_rects: Array[Rect2]) -> void:
	var populations: Array[WorldNPCPopulation] = []
	for child in _descendants(base):
		if child is WorldNPCPopulation:
			populations.append(child as WorldNPCPopulation)
	_check(populations.size() == 1, "Railhome owns exactly one WorldNPCPopulation")
	if populations.is_empty():
		return
	var population := populations[0]
	_check(population.region_id == "railhome", "population is scoped to Railhome")
	_check(population.position == Vector2.ZERO, "population placements use carriage-local coordinates")
	var placements := WorldNPCPopulation.get_region_placements(&"railhome")
	_check(placements.size() == EXPECTED_RELOCATABLE_SURVIVORS, "all nine relocatable survivors have a Railhome schedule")
	var endpoints: Dictionary = {}
	for placement in placements:
		var npc_id := StringName(placement.get(&"npc_id", &""))
		var anchor: Vector2 = placement.get(&"position", Vector2.ZERO)
		var settled := anchor + Vector2(placement.get(&"settled", Vector2.ZERO))
		var work := anchor + Vector2(placement.get(&"work", Vector2.ZERO))
		for endpoint in [settled, work]:
			_check(RailhomeBase.SHELTER_BOUNDS.grow(-28.0).has_point(endpoint), "%s schedule stays inside the carriage" % npc_id)
			_check(absf(endpoint.y) > 60.0, "%s schedule leaves the central spine clear" % npc_id)
			_check(not endpoints.has(endpoint), "%s schedule endpoint is not shared" % npc_id)
			endpoints[endpoint] = npc_id
		var crosses_fixture := false
		for step in range(21):
			var sample := settled.lerp(work, float(step) / 20.0)
			for fixture_rect in fixture_rects:
				if fixture_rect.grow(NPC_CLEARANCE).has_point(sample):
					crosses_fixture = true
					break
			if crosses_fixture:
				break
		_check(not crosses_fixture, "%s schedule does not pass through furniture" % npc_id)


func _check_upgrade_restoration(base: RailhomeBase) -> void:
	var coil := base.get_node("ScannerCoilBench") as BaseUpgradeBench
	var radio := base.get_node("RadioDeskStation") as BaseUpgradeStation
	var lantern := base.get_node("SignalLantern") as BaseUpgradeBench
	_check(not coil.is_available() and not radio.is_available() and not lantern.is_available(), "saved upgrades restore as already built")
	_check((coil.get_node("Visual/Coil") as CanvasItem).visible, "restored Search Coil appears on the receiver bench")
	_check((radio.get_node("Visual/SignalGlow") as CanvasItem).visible, "restored radio desk carries a live signal glow")
	_check((radio.get_node("Visual/PowerLight") as CanvasItem).visible, "restored radio desk carries a live power lamp")
	_check((base.get_node("WarmOverlay") as CanvasItem).visible, "restored signal lantern warms the full carriage")
	for light in _group_children(base, &"railhome_warm_lights"):
		_check((light as PointLight2D).visible, "%s turns on with the restored lantern" % light.name)
	for light in _group_children(base, &"railhome_cold_lights"):
		var point := light as PointLight2D
		var authored := float(point.get_meta("base_energy", 0.0))
		_check(is_equal_approx(point.energy, authored * 0.56), "%s yields to the warm restored lights" % point.name)

	base.apply_shelter_state({"built_upgrades": [], "route_stage": 0, "occupant_count": 0})
	_check(coil.is_available() and radio.is_available() and lantern.is_available(), "unbuilt preview reactivates all three work stations")
	_check(not (coil.get_node("Visual/Coil") as CanvasItem).visible, "unbuilt preview removes the fitted coil")
	_check(not (radio.get_node("Visual/SignalGlow") as CanvasItem).visible, "unbuilt preview powers down the radio")
	_check(not (base.get_node("WarmOverlay") as CanvasItem).visible, "unbuilt preview removes the lantern wash")
	for light in _group_children(base, &"railhome_warm_lights"):
		_check(not (light as PointLight2D).visible, "%s powers down without the lantern" % light.name)
	for light in _group_children(base, &"railhome_cold_lights"):
		var point := light as PointLight2D
		_check(is_equal_approx(point.energy, float(point.get_meta("base_energy", 0.0))), "%s returns to authored cold energy" % point.name)

	base.apply_shelter_state({
		"built_upgrades": [&"scanner_coil", &"radio_desk", &"base_lantern"],
		"route_stage": 3,
		"occupant_count": 4,
	})
	_check(not coil.is_available() and not radio.is_available() and not lantern.is_available(), "live state refresh rebuilds all station visuals")


func _check_staged_dressing(base: RailhomeBase) -> void:
	for node in _group_children(base, &"railhome_route_state"):
		_check((node as CanvasItem).visible, "%s appears at route stage three" % node.name)
	for node in _group_children(base, &"railhome_occupancy_state"):
		_check((node as CanvasItem).visible, "%s appears when four survivors settle in" % node.name)
	var snapshot := base.get_shelter_snapshot()
	_check(int(snapshot.get("route_stage", -1)) == 3, "shelter snapshot records route dressing")
	_check(int(snapshot.get("occupant_count", -1)) == 4, "shelter snapshot records occupied dressing")


func _collision_rect_in_base(collision: CollisionShape2D, base: Node2D) -> Rect2:
	var rect := collision.shape.get_rect()
	var to_base := base.global_transform.affine_inverse() * collision.global_transform
	return _transformed_rect(rect, to_base)


func _transformed_rect(rect: Rect2, transform: Transform2D) -> Rect2:
	var points := PackedVector2Array([
		transform * rect.position,
		transform * Vector2(rect.end.x, rect.position.y),
		transform * rect.end,
		transform * Vector2(rect.position.x, rect.end.y),
	])
	var result := Rect2(points[0], Vector2.ZERO)
	for point in points:
		result = result.expand(point)
	return result


func _polygon_rect(polygon: PackedVector2Array) -> Rect2:
	if polygon.is_empty():
		return Rect2()
	var rect := Rect2(polygon[0], Vector2.ZERO)
	for point in polygon:
		rect = rect.expand(point)
	return rect


func _first_textured_sprite(root: Node) -> Sprite2D:
	if root is Sprite2D and (root as Sprite2D).texture != null:
		return root as Sprite2D
	for child in root.get_children():
		var found := _first_textured_sprite(child)
		if found != null:
			return found
	return null


func _descendants(root: Node) -> Array[Node]:
	var result: Array[Node] = []
	for child in root.get_children():
		result.append(child)
		result.append_array(_descendants(child))
	return result


func _group_children(base: Node, group_name: StringName) -> Array[Node]:
	var result: Array[Node] = []
	for node in get_tree().get_nodes_in_group(group_name):
		if base.is_ancestor_of(node):
			result.append(node)
	return result


func _finish(upgrades_before: Array, world_before: Dictionary) -> void:
	BaseUpgradeSystem.restore(upgrades_before)
	WorldState.restore(world_before)
	if _failures.is_empty():
		print("RAILHOME_BASE_SMOKE: PASS")
		get_tree().quit(0)
		return
	for failure in _failures:
		push_error("RAILHOME_BASE_SMOKE: " + failure)
	print("RAILHOME_BASE_SMOKE: FAIL (%d)" % _failures.size())
	get_tree().quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
