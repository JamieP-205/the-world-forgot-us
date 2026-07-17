extends Node
## Runtime proof for readable loops, honest collision feet and every enterable
## world building. This loads the same authored scenes used by the campaign.

const MAP_SCENES := {
	&"cullbrook": preload("res://scenes/maps/test_map.tscn"),
	&"ashmere_verge": preload("res://scenes/maps/ashmere_verge.tscn"),
	&"broadcast_fields": preload("res://scenes/maps/broadcast_fields.tscn"),
	&"choir_core": preload("res://scenes/maps/choir_core.tscn"),
}
const INTERIOR_SCENE := preload("res://scenes/interiors/building_interior.tscn")
const BuildingCatalog = preload("res://scripts/world/building_catalog.gd")

var _failures: Array[String] = []
var _seen_buildings: Dictionary = {}
var _seen_interior_identities: Dictionary = {}
var _seen_layout_signatures: Dictionary = {}
var _seen_hero_cells: Dictionary = {}


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var world_before := WorldState.get_state()
	print("MAP_FLOW_SMOKE: catalogue")
	_check_catalog()
	for region_id in MAP_SCENES:
		print("MAP_FLOW_SMOKE: %s" % region_id)
		await _check_region(StringName(region_id), MAP_SCENES[region_id] as PackedScene)
	print("MAP_FLOW_SMOKE: interiors")
	await _check_interiors()
	WorldState.restore(world_before)
	_check(_seen_buildings.size() == BuildingCatalog.BUILDINGS.size(), "all 19 catalogue buildings have a live exterior threshold")
	_check(_seen_interior_identities.size() == BuildingCatalog.BUILDINGS.size(), "all 19 interiors own a distinct identity key")
	_check(_seen_layout_signatures.size() == BuildingCatalog.BUILDINGS.size(), "all 19 interiors own a distinct authored room layout")
	_check(_seen_hero_cells.size() == BuildingCatalog.BUILDINGS.size(), "all 19 interiors own a distinct hero-art cell")
	if _failures.is_empty():
		print("MAP FLOW + COLLISION SMOKE: PASS (4 regions, 19 buildings)")
		get_tree().quit(0)
		return
	for failure in _failures:
		push_error("MAP FLOW + COLLISION SMOKE: " + failure)
	print("MAP FLOW + COLLISION SMOKE: FAIL (%d)" % _failures.size())
	get_tree().quit(1)


func _check_catalog() -> void:
	for error in BuildingCatalog.validate():
		_fail("building catalogue: " + error)
	_check(BuildingCatalog.BUILDINGS.size() == 19, "catalogue contains the intended 19 enterable buildings")
	var assigned := 0
	for region_id in BuildingCatalog.REGION_BUILDINGS:
		assigned += BuildingCatalog.region_buildings(StringName(region_id)).size()
	_check(assigned == 19, "regional manifests assign every building exactly once")
	_check(ResourceLoader.exists(BuildingCatalog.INTERIOR_IDENTITY_ATLAS), "the interior identity atlas is importable")
	for building_value in BuildingCatalog.BUILDINGS:
		var building_id := StringName(building_value)
		var building := BuildingCatalog.get_building(building_id)
		var rooms := int(building.get("rooms", 0))
		_check(rooms >= 1 and rooms <= 3, "%s has one to three rooms" % building_id)
		var minimum := BuildingCatalog.minimum_exterior_size(building_id)
		_check(minimum.x >= WorldLayoutContract.PLAYER_REFERENCE * 4.5, "%s cannot shrink to prop scale" % building_id)
		var identity := BuildingCatalog.get_interior_identity(building_id)
		_check(not identity.is_empty(), "%s has an authored interior identity" % building_id)
		var dressing := identity.get("dressing", []) as Array
		_check(dressing.size() == rooms, "%s identity authors all %d rooms" % [building_id, rooms])
		for room_index in dressing.size():
			_check((dressing[room_index] as Array).size() >= 2, "%s room %d has a real prop composition" % [building_id, room_index + 1])
		for loot_value in (building.get("loot", {}) as Dictionary):
			var loot_id := StringName(loot_value)
			_check(ItemDatabase.get_item(loot_id) != null, "%s cache item %s is registered" % [building_id, loot_id])


func _check_region(region_id: StringName, packed: PackedScene) -> void:
	var map := packed.instantiate() as Node2D
	_check(map != null, "%s map instantiates" % region_id)
	if map == null:
		return
	add_child(map)
	await get_tree().process_frame
	map.process_mode = Node.PROCESS_MODE_DISABLED
	_check_flow_contract(map, region_id)
	_check_building_thresholds(map, region_id)
	_check_blocked_ruins(map, region_id)
	_check_solid_contracts(map, region_id)
	_check_quiet_buffers(map, region_id)
	_check_field_tool_targets(map, region_id)
	map.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame


func _check_flow_contract(map: Node2D, region_id: StringName) -> void:
	var contract := map.get_node_or_null("MapFlowContract") as Node2D
	_check(contract != null, "%s owns a runtime map-flow contract" % region_id)
	if contract == null:
		return
	_check(String(contract.get_meta("layout_language", "")) == "hub-loop", "%s declares the hub-loop layout language" % region_id)
	_check("no route rail" in String(contract.get_meta("guidance_rule", "")), "%s does not draw a minimap rail through the world" % region_id)
	var route_nodes: PackedStringArray = contract.get_meta("route_nodes", PackedStringArray())
	_check(route_nodes.size() >= 4, "%s has a hub plus a traversable loop" % region_id)
	for route_node in route_nodes:
		var physical_route := map.get_node_or_null(NodePath(route_node)) as CanvasItem
		_check(physical_route != null and physical_route.visible, "%s route surface %s is physically authored" % [region_id, route_node])

	var landmarks := _nodes_in_group(map, "map_flow_landmarks")
	var pockets := _nodes_in_group(map, "map_flow_side_pockets")
	var shortcuts := _nodes_in_group(map, "map_flow_shortcuts")
	var buffers := _nodes_in_group(map, "map_flow_quiet_buffers")
	var cues := _nodes_in_group(map, "map_flow_cue_anchors")
	_check(landmarks.size() >= 3, "%s has at least three stable bearings" % region_id)
	var bearings: Dictionary = {}
	for landmark in landmarks:
		var bearing := String(landmark.get_meta("bearing", ""))
		_check(not bearing.is_empty(), "%s landmark %s names its bearing" % [region_id, landmark.name])
		bearings[bearing] = true
	_check(bearings.size() >= 3, "%s bearings are spatially distinct" % region_id)
	_check(pockets.size() >= 2, "%s has optional side pockets" % region_id)
	for pocket in pockets:
		_check(_has_nearby_optional_content(map, pocket.global_position, 185.0), "%s side pocket %s contains optional loot or evidence" % [region_id, pocket.name])
	_check(shortcuts.size() == 1, "%s has one legible cross-cut" % region_id)
	for shortcut in shortcuts:
		var connections: PackedStringArray = shortcut.get_meta("connects", PackedStringArray())
		var route_name := String(shortcut.get_meta("route_node", ""))
		_check(connections.size() == 2, "%s shortcut states the two route branches it reconnects" % region_id)
		_check(map.has_node(NodePath(route_name)), "%s shortcut is painted as route surface %s" % [region_id, route_name])
	_check(buffers.size() >= 2, "%s gives the player quiet buffers before pressure" % region_id)
	_check(cues.size() >= 3, "%s repeats wayfinding at every major decision" % region_id)
	for cue in cues:
		var channels: PackedStringArray = cue.get_meta("cue_channels", PackedStringArray())
		_check(channels == PackedStringArray(["ground", "sign", "light"]), "%s cue %s uses ground, sign and light together" % [region_id, cue.name])
		_check(_has_child_named(cue, ["WornThresholdPaint", "ThresholdPaint"]), "%s cue %s has worn ground paint" % [region_id, cue.name])
		_check(_has_child_named(cue, ["CountySign", "RouteSign"]), "%s cue %s has a physical sign" % [region_id, cue.name])
		_check(_has_child_named(cue, ["ServiceLamp"]), "%s cue %s has a physical lamp" % [region_id, cue.name])


func _check_building_thresholds(map: Node2D, region_id: StringName) -> void:
	var expected := BuildingCatalog.region_buildings(region_id)
	var thresholds := _nodes_in_group(map, "enterable_building_thresholds")
	_check(thresholds.size() == expected.size(), "%s exposes %d intended building thresholds" % [region_id, expected.size()])
	for threshold_node in thresholds:
		var threshold := threshold_node as BuildingDoor
		_check(threshold != null, "%s threshold %s uses BuildingDoor" % [region_id, threshold_node.name])
		if threshold == null:
			continue
		var building_id := threshold.building_id
		_check(building_id in expected, "%s threshold %s belongs to its regional manifest" % [region_id, building_id])
		_check(not _seen_buildings.has(building_id), "%s has only one world threshold" % building_id)
		_seen_buildings[building_id] = true
		var building := BuildingCatalog.get_building(building_id)
		var rooms := int(building.get("rooms", 0))
		_check(int(threshold.get_meta("room_count", 0)) == rooms, "%s threshold carries its %d-room contract" % [building_id, rooms])
		_check(not threshold.return_scene_path.is_empty() and threshold.return_spawn != &"", "%s has a safe world return" % building_id)
		_check(map.has_node(NodePath(String(threshold.return_spawn))), "%s return spawn exists in its map" % building_id)
		var exterior := _find_exterior(map, building_id)
		_check(exterior != null, "%s owns an intact physical exterior" % building_id)
		if exterior == null:
			continue
		_check(String(exterior.get_meta("entry_state", "")) == "intact-enterable", "%s is visibly marked intact and enterable" % building_id)
		_check(int(exterior.get_meta("room_count", 0)) == rooms, "%s exterior and interior agree on room count" % building_id)
		var extent := _body_collision_aabb(exterior, true).size
		var minimum := BuildingCatalog.minimum_exterior_size(building_id)
		_check(extent.x + 1.0 >= minimum.x and extent.y + 1.0 >= minimum.y, "%s exterior is architecture-sized (%.0fx%.0f, minimum %.0fx%.0f)" % [building_id, extent.x, extent.y, minimum.x, minimum.y])
		_check(not _point_hits_body(exterior, threshold.global_position), "%s threshold is clear of its solid foot" % building_id)


func _check_blocked_ruins(map: Node2D, region_id: StringName) -> void:
	var blocked: Array[Node] = []
	for node in _nodes_in_group(map, "world_solid_footprints"):
		if StringName(node.get_meta("solid_kind", &"")) == &"blocked_ruin":
			blocked.append(node)
	_check(not blocked.is_empty(), "%s includes a visibly blocked ruin distinct from intact doors" % region_id)
	for ruin in blocked:
		_check(String(ruin.get_meta("entry_state", "")) == "visibly-blocked", "%s ruin %s declares its blocked state" % [region_id, ruin.name])
		_check(_has_visible_sprite(ruin), "%s ruin %s uses visible debris instead of an invisible blocker" % [region_id, ruin.name])
		_check(StringName(ruin.get_meta("building_id", &"")) == &"", "%s ruin %s cannot masquerade as an enterable building" % [region_id, ruin.name])


func _check_solid_contracts(map: Node2D, region_id: StringName) -> void:
	var solids := _nodes_in_group(map, "world_solid_footprints")
	_check(solids.size() >= 8, "%s has authored solid-foot coverage" % region_id)
	for node in _descendants(map):
		var body := node as StaticBody2D
		if body == null or _collision_shapes(body).is_empty():
			continue
		_check(body in solids or body.is_in_group("world_boundaries"), "%s solid %s is classified instead of relying on an unexplained box" % [region_id, body.name])
	for solid_node in solids:
		var body := solid_node as StaticBody2D
		_check(body != null, "%s collision contract belongs to StaticBody2D" % solid_node.name)
		if body == null:
			continue
		_check(String(body.get_meta("collision_contract", "")) == "visible-foot", "%s/%s uses the visible-foot contract" % [region_id, body.name])
		var visible: PackedVector2Array = body.get_meta("visible_footprint", PackedVector2Array())
		_check(visible.size() >= 3, "%s/%s records its visible foot" % [region_id, body.name])
		var visible_bounds := _points_aabb(visible)
		var collision_bounds := _body_collision_aabb(body, false)
		_check(collision_bounds.has_area(), "%s/%s has active collision geometry" % [region_id, body.name])
		if visible_bounds.has_area() and collision_bounds.has_area():
			_check(_rect_contains(visible_bounds.grow(2.5), collision_bounds), "%s/%s collision never extends beyond visible footing" % [region_id, body.name])
			_check(collision_bounds.size.x >= visible_bounds.size.x * 0.24 and collision_bounds.size.y >= visible_bounds.size.y * 0.24, "%s/%s cannot be walked through as an empty picture" % [region_id, body.name])
		if bool(body.get_meta("split_threshold", false)):
			_check(_collision_shapes(body).size() >= 3, "%s/%s splits collision around its threshold" % [region_id, body.name])

	# The Railhome carriage uses an isometric inset door; prove that the actual
	# travel trigger occupies its deliberate gap rather than the old rectangle.
	if region_id == &"cullbrook":
		var carriage := map.get_node_or_null("Carriage317Exterior") as StaticBody2D
		var base_door := map.get_node_or_null("BaseDoor") as Node2D
		_check(carriage != null and base_door != null, "Cullbrook has the full Railhome exterior and threshold")
		if carriage != null and base_door != null:
			_check(not _point_hits_body(carriage, base_door.global_position), "Railhome threshold sits in the painted carriage-door gap")


func _check_quiet_buffers(map: Node2D, region_id: StringName) -> void:
	var enemies := _nodes_in_group(map, "enemies")
	for buffer in _nodes_in_group(map, "map_flow_quiet_buffers"):
		var radius := float(buffer.get_meta("radius", 0.0))
		_check(radius >= WorldLayoutContract.PLAYER_REFERENCE * 1.8, "%s quiet buffer %s has useful breathing room" % [region_id, buffer.name])
		for enemy in enemies:
			var actor := enemy as Node2D
			if actor != null:
				_check(actor.global_position.distance_to((buffer as Node2D).global_position) >= radius, "%s quiet buffer %s starts clear of %s" % [region_id, buffer.name, actor.name])


func _check_field_tool_targets(map: Node2D, region_id: StringName) -> void:
	var ash_zones := _nodes_in_group(map, "ash_exposure_zones")
	if region_id in [&"ashmere_verge", &"broadcast_fields", &"choir_core"]:
		_check(not ash_zones.is_empty(), "%s has an authored contaminated side pocket for the ash filter" % region_id)
	for zone in ash_zones:
		_check(zone is AshDrift and float(zone.get_meta("base_exposure_damage", 0.0)) > 0.0,
			"%s ash pocket %s deals explicit filtered exposure" % [region_id, zone.name])
	if region_id == &"broadcast_fields":
		var bridge_targets := _nodes_in_group(map, "craft_bridge_targets")
		var repair_targets := _nodes_in_group(map, "craft_repair_targets")
		_check(bridge_targets.size() >= 3, "Long Acre has three physical circuit-bridge targets")
		_check(repair_targets.size() >= 3, "Long Acre has three physical wire-splice targets")
	if region_id == &"choir_core":
		var access_targets := _nodes_in_group(map, "craft_access_targets")
		_check(not access_targets.is_empty(), "Tollard has a physical secured drawer for the lock shim")
		for target in access_targets:
			_check(target is LootContainer and target.has_method("apply_crafted_item"),
				"Tollard access target %s uses the production drawer contract" % target.name)


func _check_interiors() -> void:
	for building_value in BuildingCatalog.BUILDINGS:
		var building_id := StringName(building_value)
		var rooms := int(BuildingCatalog.get_building(building_id).get("rooms", 0))
		WorldState.set_flag(&"active_interior_id", String(building_id))
		var interior := INTERIOR_SCENE.instantiate() as BuildingInterior
		add_child(interior)
		await get_tree().process_frame
		var wear_count := 0
		var authored_placements := 0
		for node in _descendants(interior):
			if node.name.begins_with("Room") and node.name.ends_with("Wear"):
				wear_count += 1
			if bool(node.get_meta("authored_placement", false)):
				authored_placements += 1
		_check(wear_count == rooms, "%s builds %d separately dressed rooms" % [building_id, rooms])
		var identity := BuildingCatalog.get_interior_identity(building_id)
		var identity_key := String(identity.get("identity_key", ""))
		var layout_signature := BuildingCatalog.interior_layout_signature(building_id)
		var atlas_cell := identity.get("atlas_cell", Vector2i(-1, -1)) as Vector2i
		_check(String(interior.get_meta("interior_identity", "")) == identity_key, "%s carries its identity key at runtime" % building_id)
		_check(String(interior.get_meta("layout_signature", "")) == layout_signature, "%s carries its actual placement signature" % building_id)
		_check(not _seen_interior_identities.has(identity_key), "%s identity key is not reused" % building_id)
		_check(not _seen_layout_signatures.has(layout_signature), "%s authored room composition is not reused" % building_id)
		var cell_key := "%d,%d" % [atlas_cell.x, atlas_cell.y]
		_check(not _seen_hero_cells.has(cell_key), "%s hero-art cell is not reused" % building_id)
		_seen_interior_identities[identity_key] = building_id
		_seen_layout_signatures[layout_signature] = building_id
		_seen_hero_cells[cell_key] = building_id
		var expected_placements := 0
		for room_value in identity.get("dressing", []):
			expected_placements += (room_value as Array).size()
		for room_value in BuildingCatalog.get_interior_details(building_id):
			expected_placements += (room_value as Array).size()
		_check(authored_placements == expected_placements, "%s instantiates all %d authored placements" % [building_id, expected_placements])
		_check(_nodes_in_group(interior, "interior_practical_lights").size() == rooms, "%s lights every room with one restrained practical" % building_id)
		var heroes := _nodes_in_group(interior, "interior_identity_heroes")
		_check(heroes.size() == 1, "%s instantiates exactly one building-specific hero asset" % building_id)
		if heroes.size() == 1:
			var hero := heroes[0]
			_check(String(hero.get_meta("interior_identity", "")) == identity_key, "%s hero asset carries the site identity" % building_id)
			_check(hero.get_meta("atlas_cell", Vector2i(-1, -1)) == atlas_cell, "%s hero asset uses its assigned atlas cell" % building_id)
			var hero_visual := hero.get_node_or_null("HeroVisual") as Sprite2D
			_check(hero_visual != null and hero_visual.texture is AtlasTexture, "%s hero renders from the generated atlas" % building_id)
		var interior_width := 420.0 * float(rooms) + 100.0
		for room_index in rooms:
			var room_center := Vector2(-interior_width * 0.5 + 50.0 + 420.0 * (float(room_index) + 0.5), 0)
			_check(not _point_hits_interior_solid(interior, room_center), "%s room %d keeps its central exploration lane clear" % [building_id, room_index + 1])
		for sample_x in range(int(-interior_width * 0.5 + 88.0), int(interior_width * 0.5 - 88.0), 24):
			_check(not _point_hits_interior_solid(interior, Vector2(float(sample_x), 0)), "%s keeps a continuous route through every room" % building_id)
		var spawn := interior.get_node_or_null("from_world") as Marker2D
		_check(spawn != null and not _point_hits_interior_solid(interior, spawn.position), "%s arrival point remains outside all collision" % building_id)
		for divider in range(1, rooms):
			_check(
				interior.has_node("Divider%dNorth" % divider) and interior.has_node("Divider%dSouth" % divider),
				"%s room %d connects through a split physical threshold" % [building_id, divider]
			)
		var cache := interior.get_node_or_null("InteriorCache_%s" % String(building_id)) as LootContainer
		_check(cache != null and not cache.loot.is_empty(), "%s interior contains its useful cache" % building_id)
		if cache != null:
			for loot_value in cache.loot:
				_check(ItemDatabase.get_item(StringName(loot_value)) != null, "%s live interior cache resolves %s" % [building_id, loot_value])
		interior.queue_free()
		await get_tree().process_frame


func _find_exterior(map: Node2D, building_id: StringName) -> StaticBody2D:
	for node in _nodes_in_group(map, "world_solid_footprints"):
		if StringName(node.get_meta("building_id", &"")) == building_id:
			return node as StaticBody2D
	return null


func _has_nearby_optional_content(map: Node2D, position_value: Vector2, radius: float) -> bool:
	for node in _descendants(map):
		if node is LootContainer or node is MemoryEcho:
			var placed := node as Node2D
			if placed.global_position.distance_to(position_value) <= radius:
				return true
	return false


func _nodes_in_group(root: Node, group_name: StringName) -> Array[Node]:
	var result: Array[Node] = []
	for node in get_tree().get_nodes_in_group(group_name):
		if node == root or root.is_ancestor_of(node):
			result.append(node)
	return result


func _descendants(root: Node) -> Array[Node]:
	var result: Array[Node] = []
	var pending: Array[Node] = [root]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		result.append(node)
		for child in node.get_children():
			pending.append(child)
	return result


func _collision_shapes(body: StaticBody2D) -> Array[CollisionShape2D]:
	var result: Array[CollisionShape2D] = []
	for node in _descendants(body):
		var collision := node as CollisionShape2D
		if collision != null and collision.shape != null and not collision.disabled:
			result.append(collision)
	return result


func _shape_points(collision: CollisionShape2D, global_space: bool) -> PackedVector2Array:
	var points := PackedVector2Array()
	var rectangle := collision.shape as RectangleShape2D
	var convex := collision.shape as ConvexPolygonShape2D
	if rectangle != null:
		points = WorldLayoutContract.rectangle_points(rectangle.size)
	elif convex != null:
		points = convex.points
	else:
		var rect := collision.shape.get_rect()
		points = WorldLayoutContract.rectangle_points(rect.size, rect.get_center())
	var transform := collision.global_transform if global_space else collision.transform
	var transformed := PackedVector2Array()
	for point in points:
		transformed.append(transform * point)
	return transformed


func _body_collision_aabb(body: StaticBody2D, global_space: bool) -> Rect2:
	var first := true
	var result := Rect2()
	for collision in _collision_shapes(body):
		var bounds := _points_aabb(_shape_points(collision, global_space))
		if first:
			result = bounds
			first = false
		else:
			result = result.merge(bounds)
	return result


func _point_hits_body(body: StaticBody2D, point: Vector2) -> bool:
	for collision in _collision_shapes(body):
		if Geometry2D.is_point_in_polygon(point, _shape_points(collision, true)):
			return true
	return false


func _point_hits_interior_solid(interior: Node2D, local_point: Vector2) -> bool:
	var global_point := interior.to_global(local_point)
	for node in _descendants(interior):
		var body := node as StaticBody2D
		if body != null and _point_hits_body(body, global_point):
			return true
	return false


func _points_aabb(points: PackedVector2Array) -> Rect2:
	if points.is_empty():
		return Rect2()
	var minimum := points[0]
	var maximum := points[0]
	for point in points:
		minimum.x = minf(minimum.x, point.x)
		minimum.y = minf(minimum.y, point.y)
		maximum.x = maxf(maximum.x, point.x)
		maximum.y = maxf(maximum.y, point.y)
	return Rect2(minimum, maximum - minimum)


func _rect_contains(outer: Rect2, inner: Rect2) -> bool:
	return (
		outer.has_point(inner.position)
		and outer.has_point(inner.position + Vector2(inner.size.x, 0))
		and outer.has_point(inner.position + Vector2(0, inner.size.y))
		and outer.has_point(inner.end)
	)


func _has_child_named(root: Node, candidates: Array[String]) -> bool:
	for candidate in candidates:
		if root.get_node_or_null(NodePath(candidate)) != null:
			return true
	return false


func _has_visible_sprite(root: Node) -> bool:
	for node in _descendants(root):
		var item := node as CanvasItem
		if item != null and item.visible and (node is Sprite2D or node is Polygon2D):
			return true
	return false


func _check(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _fail(message: String) -> void:
	_failures.append(message)
