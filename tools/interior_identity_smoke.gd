extends Node
## Focused proof that every enterable address has its own art and room plan,
## while the shared threshold and central travel lanes remain physically clear.

const INTERIOR_SCENE := preload("res://scenes/interiors/building_interior.tscn")
const BuildingCatalog = preload("res://scripts/world/building_catalog.gd")

var _failures: Array[String] = []
var _identity_keys: Dictionary = {}
var _layout_signatures: Dictionary = {}
var _atlas_cells: Dictionary = {}
var _pixel_signatures: Dictionary = {}
var _placement_total := 0
var _practical_light_total := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var world_before := WorldState.get_state()
	print("INTERIOR_IDENTITY_SMOKE: catalogue and atlas")
	_check_catalog_and_art()
	for building_value in BuildingCatalog.BUILDINGS:
		print("INTERIOR_IDENTITY_SMOKE: %s" % String(building_value))
		await _check_live_interior(StringName(building_value))
	WorldState.restore(world_before)
	_check(_identity_keys.size() == 19, "all nineteen identity keys are distinct")
	_check(_layout_signatures.size() == 19, "all nineteen placement signatures are distinct")
	_check(_atlas_cells.size() == 19, "all nineteen assigned atlas cells are distinct")
	_check(_pixel_signatures.size() == 19, "all nineteen used atlas cells contain distinct pixels")
	if _failures.is_empty():
		print("INTERIOR IDENTITY CONTRACT: PASS (19 buildings, 19 hero assets, %d authored placements, %d practical lights)" % [_placement_total, _practical_light_total])
		get_tree().quit(0)
		return
	for failure in _failures:
		push_error("INTERIOR IDENTITY CONTRACT: " + failure)
	print("INTERIOR IDENTITY CONTRACT: FAIL (%d)" % _failures.size())
	get_tree().quit(1)


func _check_catalog_and_art() -> void:
	for error in BuildingCatalog.validate():
		_fail("catalogue: " + error)
	_check(ResourceLoader.exists(BuildingCatalog.INTERIOR_IDENTITY_ATLAS), "identity atlas imports")
	# Read the source PNG directly. CompressedTexture2D.get_image() requires a
	# rendering texture and can stall on CI's dummy headless renderer.
	var image := Image.load_from_file(ProjectSettings.globalize_path(BuildingCatalog.INTERIOR_IDENTITY_ATLAS))
	_check(image != null and not image.is_empty(), "identity atlas exposes readable pixels")
	if image == null or image.is_empty():
		return
	for building_value in BuildingCatalog.BUILDINGS:
		var building_id := StringName(building_value)
		var identity := BuildingCatalog.get_interior_identity(building_id)
		var identity_key := String(identity.get("identity_key", ""))
		var layout_signature := BuildingCatalog.interior_layout_signature(building_id)
		var cell := identity.get("atlas_cell", Vector2i(-1, -1)) as Vector2i
		var cell_key := "%d,%d" % [cell.x, cell.y]
		_check(not _identity_keys.has(identity_key), "%s does not reuse an identity key" % building_id)
		_check(not _layout_signatures.has(layout_signature), "%s does not reuse a room plan" % building_id)
		_check(not _atlas_cells.has(cell_key), "%s does not reuse an atlas cell" % building_id)
		_identity_keys[identity_key] = building_id
		_layout_signatures[layout_signature] = building_id
		_atlas_cells[cell_key] = building_id

		var x0 := roundi(float(cell.x) * float(image.get_width()) / float(BuildingCatalog.INTERIOR_ATLAS_GRID.x))
		var x1 := roundi(float(cell.x + 1) * float(image.get_width()) / float(BuildingCatalog.INTERIOR_ATLAS_GRID.x))
		var y0 := roundi(float(cell.y) * float(image.get_height()) / float(BuildingCatalog.INTERIOR_ATLAS_GRID.y))
		var y1 := roundi(float(cell.y + 1) * float(image.get_height()) / float(BuildingCatalog.INTERIOR_ATLAS_GRID.y))
		var cell_image := image.get_region(Rect2i(x0, y0, x1 - x0, y1 - y0))
		var signature: int = hash(cell_image.get_data())
		_check(cell_image.get_used_rect().has_area(), "%s assigned cell has visible art" % building_id)
		_check(not _pixel_signatures.has(signature), "%s assigned cell is not a pixel duplicate" % building_id)
		_pixel_signatures[signature] = building_id


func _check_live_interior(building_id: StringName) -> void:
	WorldState.set_flag(&"active_interior_id", String(building_id))
	var interior := INTERIOR_SCENE.instantiate() as BuildingInterior
	_check(interior != null, "%s interior instantiates" % building_id)
	if interior == null:
		return
	add_child(interior)
	await get_tree().process_frame
	interior.process_mode = Node.PROCESS_MODE_DISABLED

	var building := BuildingCatalog.get_building(building_id)
	var identity := BuildingCatalog.get_interior_identity(building_id)
	var details := BuildingCatalog.get_interior_details(building_id)
	var rooms := int(building.get("rooms", 0))
	var expected_placements := 0
	var expected_by_room: Array[int] = []
	var dressing := identity.get("dressing", []) as Array
	for room_index in rooms:
		var room_count := (dressing[room_index] as Array).size() + (details[room_index] as Array).size()
		expected_by_room.append(room_count)
		expected_placements += room_count
		_check(room_count >= 4, "%s room %d has at least four purposeful placements" % [building_id, room_index + 1])
	_placement_total += expected_placements
	var live_placements := 0
	var live_by_room: Dictionary = {}
	for node in _descendants(interior):
		if bool(node.get_meta("authored_placement", false)):
			live_placements += 1
			var placed_room := int(node.get_meta("room_index", -1))
			live_by_room[placed_room] = int(live_by_room.get(placed_room, 0)) + 1
	_check(live_placements == expected_placements, "%s instantiates all %d authored placements" % [building_id, expected_placements])
	for room_index in rooms:
		_check(int(live_by_room.get(room_index, 0)) == expected_by_room[room_index], "%s room %d instantiates its full dressing brief" % [building_id, room_index + 1])
	_check(String(interior.get_meta("interior_identity", "")) == String(identity.get("identity_key", "")), "%s carries its runtime identity" % building_id)
	_check(String(interior.get_meta("layout_signature", "")) == BuildingCatalog.interior_layout_signature(building_id), "%s carries its runtime room plan" % building_id)
	_check(bool(interior.get_meta("material_legibility_pass", false)), "%s opts into the legible material pass" % building_id)

	var practical_lights := _nodes_in_group(interior, "interior_practical_lights")
	var practical_fixtures := _nodes_in_group(interior, "interior_practical_fixtures")
	_practical_light_total += practical_lights.size()
	_check(practical_lights.size() == rooms, "%s owns one practical light per room" % building_id)
	_check(practical_fixtures.size() == rooms, "%s owns one visible practical fixture per room" % building_id)
	var lit_rooms: Dictionary = {}
	for light_node in practical_lights:
		var practical := light_node as PointLight2D
		_check(practical != null, "%s practical lighting uses PointLight2D" % building_id)
		if practical == null:
			continue
		var lit_room := int(practical.get_meta("room_index", -1))
		lit_rooms[lit_room] = true
		_check(practical.texture != null, "%s room %d practical has a radial texture" % [building_id, lit_room + 1])
		_check(not practical.shadow_enabled, "%s room %d practical is Web/mobile safe" % [building_id, lit_room + 1])
		_check(practical.energy > 0.42 and practical.energy <= 0.65, "%s room %d practical stays restrained" % [building_id, lit_room + 1])
		_check(float(practical.get_meta("radius", 0.0)) >= 220.0 and float(practical.get_meta("radius", 0.0)) <= 300.0, "%s room %d practical covers the work area without flooding the map" % [building_id, lit_room + 1])
		_check(bool(practical.get_meta("web_mobile_safe", false)), "%s room %d practical declares its low-cost profile" % [building_id, lit_room + 1])
	_check(lit_rooms.size() == rooms, "%s practical lights cover every room exactly once" % building_id)
	var floor := interior.get_node_or_null("Floor") as Polygon2D
	var north_wall := interior.get_node_or_null("NorthWall/Visual") as Polygon2D
	_check(floor != null and floor.color.get_luminance() >= 0.32, "%s floor material remains readable under practical light" % building_id)
	_check(north_wall != null and north_wall.color.get_luminance() >= 0.27, "%s wall material remains readable under practical light" % building_id)

	var heroes := _nodes_in_group(interior, "interior_identity_heroes")
	_check(heroes.size() == 1, "%s has exactly one building-specific hero" % building_id)
	if heroes.size() == 1:
		var hero := heroes[0]
		var plate := hero.get_node_or_null("SitePlate") as Polygon2D
		var stripe := hero.get_node_or_null("IdentityStripe") as Polygon2D
		_check(plate != null and plate.visible and stripe != null and stripe.visible,
			"%s identity is a wall plate, not a miniature building collage" % building_id)
		_check(String(hero.get_meta("presentation", "")) == "site-plate",
			"%s declares its restrained identity presentation" % building_id)
		_check(hero.get_meta("atlas_cell", Vector2i(-1, -1)) == identity.get("atlas_cell", Vector2i(-1, -1)), "%s hero uses its assigned cell" % building_id)

	var evidence_nodes: Array[InteriorEvidence] = []
	for node in _descendants(interior):
		if node is InteriorEvidence:
			evidence_nodes.append(node as InteriorEvidence)
	_check(evidence_nodes.size() == 1, "%s has exactly one physical evidence interaction" % building_id)
	if evidence_nodes.size() == 1:
		var evidence := evidence_nodes[0] as InteriorEvidence
		GameManager.set_dialogue_active(false)
		evidence.interact(null)
		_check(GameManager.is_input_locked(), "%s evidence dialogue locks movement and touch input" % building_id)
		EventBus.dialogue_finished.emit(StringName("evidence_%s" % String(building_id)), -1)
		_check(not GameManager.is_input_locked(), "%s evidence dialogue releases its input lock" % building_id)

	var width := 420.0 * float(rooms) + 100.0
	for room_index in rooms:
		var center := Vector2(-width * 0.5 + 50.0 + 420.0 * (float(room_index) + 0.5), 0)
		_check(not _point_hits_solid(interior, center), "%s room %d keeps its centre lane clear" % [building_id, room_index + 1])
	for sample_x in range(int(-width * 0.5 + 88.0), int(width * 0.5 - 88.0), 24):
		_check(not _point_hits_solid(interior, Vector2(float(sample_x), 0)), "%s keeps a continuous cross-room route" % building_id)
	var spawn := interior.get_node_or_null("from_world") as Marker2D
	_check(spawn != null and not _point_hits_solid(interior, spawn.position), "%s arrival marker is outside all collision" % building_id)
	var exit := interior.get_node_or_null("ReturnToWorld") as BuildingDoor
	_check(exit != null and not _point_hits_solid(interior, exit.position), "%s return threshold is outside all collision" % building_id)

	interior.queue_free()
	await get_tree().process_frame


func _point_hits_solid(interior: Node2D, local_point: Vector2) -> bool:
	var global_point := interior.to_global(local_point)
	for node in _descendants(interior):
		var body := node as StaticBody2D
		if body == null:
			continue
		for child in _descendants(body):
			var collision := child as CollisionShape2D
			if collision == null or collision.shape == null or collision.disabled:
				continue
			var rectangle := collision.shape as RectangleShape2D
			if rectangle == null:
				continue
			var points := WorldLayoutContract.rectangle_points(rectangle.size)
			var transformed := PackedVector2Array()
			for point in points:
				transformed.append(collision.global_transform * point)
			if Geometry2D.is_point_in_polygon(global_point, transformed):
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


func _check(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _fail(message: String) -> void:
	_failures.append(message)
