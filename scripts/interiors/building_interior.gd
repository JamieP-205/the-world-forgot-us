class_name BuildingInterior
extends Node2D
## Builds a compact, readable one-to-three-room interior from an authored
## building brief. The geometry is modular; evidence, dressing and salvage are
## specific to the exterior the player entered.

const LOOT_SCENE := preload("res://scenes/world/loot_container.tscn")
const DOOR_SCENE := preload("res://scenes/world/building_door.tscn")
const BuildingCatalog = preload("res://scripts/world/building_catalog.gd")

const TEX_METAL := "res://assets/processed/decals/metal_floor.png"
const TEX_WOOD := "res://assets/processed/decals/wood_floor.png"
const TEX_CONCRETE := "res://assets/processed/decals/concrete_broken.png"
const TEX_DIRT := "res://assets/processed/decals/dirt_debris.png"
const MISLEADING_DECORATIVE_PROPS := [
	"chest", "crate", "toolbox", "locker", "vending",
	"medicine", "photo", "compass", "receiver",
]

static var _shared_practical_light_texture: GradientTexture2D

const PROP_PATHS := {
	"bedroll": "res://assets/processed/railhome_props/bedroll.png",
	"chest": "res://assets/processed/railhome_props/storage_chest.png",
	"lantern": "res://assets/processed/railhome_props/lantern.png",
	"map": "res://assets/processed/railhome_props/map_wall.png",
	"workbench": "res://assets/processed/railhome_props/workbench_tools.png",
	"empty_bench": "res://assets/processed/railhome_props/workbench_empty.png",
	"radio_desk": "res://assets/processed/railhome_props/radio_desk.png",
	"receiver": "res://assets/processed/scanner_memory_effects/mnemoscope_device.png",
	"counter": "res://assets/processed/petrol_station_props/station_counter.png",
	"vending": "res://assets/processed/petrol_station_props/vending_machine.png",
	"phone": "res://assets/processed/petrol_station_props/phone_booth.png",
	"barrier": "res://assets/processed/petrol_station_props/warning_barrier.png",
	"radio": "res://assets/processed/roadside_props/portable_radio.png",
	"poster": "res://assets/processed/roadside_props/missing_person_poster.png",
	"car": "res://assets/processed/roadside_props/broken_car.png",
	"toolbox": "res://assets/processed/loot_containers/toolbox_metal_closed.png",
	"locker": "res://assets/processed/loot_containers/locker_metal.png",
	"crate": "res://assets/processed/loot_containers/crate_wood_closed.png",
	"medicine": "res://assets/processed/item_icons_pack_01/icon_medicine.png",
	"photo": "res://assets/processed/item_icons_pack_01/icon_old_photo.png",
	"compass": "res://assets/processed/item_icons_pack_01/icon_compass.png",
}

const PROP_SPECS := {
	"bedroll": {"scale": 0.20, "solid": Vector2.ZERO, "lift": -8.0},
	"chest": {"scale": 0.20, "solid": Vector2.ZERO, "lift": -9.0},
	"lantern": {"scale": 0.14, "solid": Vector2.ZERO, "lift": -18.0},
	"map": {"scale": 0.17, "solid": Vector2.ZERO, "lift": -34.0},
	"workbench": {"scale": 0.19, "solid": Vector2(94, 44), "lift": -18.0},
	"empty_bench": {"scale": 0.18, "solid": Vector2(88, 40), "lift": -16.0},
	"radio_desk": {"scale": 0.20, "solid": Vector2(96, 48), "lift": -22.0},
	"receiver": {"scale": 0.13, "solid": Vector2.ZERO, "lift": -18.0},
	"counter": {"scale": 0.21, "solid": Vector2(104, 42), "lift": -18.0},
	"vending": {"scale": 0.18, "solid": Vector2(48, 34), "lift": -24.0},
	"phone": {"scale": 0.18, "solid": Vector2(44, 34), "lift": -24.0},
	"barrier": {"scale": 0.18, "solid": Vector2.ZERO, "lift": -8.0},
	"radio": {"scale": 0.16, "solid": Vector2.ZERO, "lift": -12.0},
	"poster": {"scale": 0.17, "solid": Vector2.ZERO, "lift": -34.0},
	"car": {"scale": 0.24, "solid": Vector2(112, 54), "lift": -20.0},
	"toolbox": {"scale": 0.17, "solid": Vector2.ZERO, "lift": -10.0},
	"locker": {"scale": 0.18, "solid": Vector2(46, 34), "lift": -22.0},
	"crate": {"scale": 0.16, "solid": Vector2.ZERO, "lift": -10.0},
	"medicine": {"scale": 0.18, "solid": Vector2.ZERO, "lift": -12.0},
	"photo": {"scale": 0.15, "solid": Vector2.ZERO, "lift": -30.0},
	"compass": {"scale": 0.14, "solid": Vector2.ZERO, "lift": -28.0},
}

var _building_id: StringName = &""
var _building: Dictionary = {}
var _identity: Dictionary = {}
var _room_count := 1
var _room_width := 380.0
var _interior_height := 460.0
var _interior_width := 760.0


func _ready() -> void:
	_building_id = StringName(WorldState.get_flag(&"active_interior_id", ""))
	if not BuildingCatalog.has(_building_id):
		_building_id = &"cullbrook_service_office"
	_building = BuildingCatalog.get_building(_building_id)
	_identity = BuildingCatalog.get_interior_identity(_building_id)
	_room_count = clampi(int(_building.get("rooms", 1)), 1, 3)
	_interior_width = _room_width * float(_room_count) + 80.0
	set_meta("interior_identity", String(_identity.get("identity_key", "")))
	set_meta("layout_identity", String(_identity.get("layout_key", "")))
	set_meta("layout_signature", BuildingCatalog.interior_layout_signature(_building_id))
	set_meta("hero_atlas_cell", _identity.get("atlas_cell", Vector2i(-1, -1)))
	set_meta("material_legibility_pass", true)
	_build_geometry()
	_dress_rooms()
	_add_practical_lights()
	_add_salvage()
	_add_thresholds()
	if not WorldState.has_flag(StringName("interior_arrival_%s" % String(_building_id))):
		WorldState.set_flag(StringName("interior_arrival_%s" % String(_building_id)))
		EventBus.notice_posted.emit(_arrival_line())


func _build_geometry() -> void:
	var apron := Polygon2D.new()
	apron.name = "WastelandApron"
	apron.polygon = _rect_points(Vector2(_interior_width + 900.0, _interior_height + 700.0))
	apron.color = Color(0.018, 0.021, 0.020, 1.0)
	apron.z_index = -6
	add_child(apron)

	var floor := Polygon2D.new()
	floor.name = "Floor"
	floor.polygon = _rect_points(Vector2(_interior_width, _interior_height))
	floor.color = _floor_tint()
	floor.z_index = -3
	add_child(floor)
	_add_floor_insets()
	_add_floor_seams()

	var runner := Polygon2D.new()
	runner.name = "ThresholdRunner"
	runner.position = Vector2(0, 74)
	runner.polygon = _rect_points(Vector2(_interior_width - 96.0, 46.0))
	runner.color = _runner_tint()
	runner.z_index = -2
	add_child(runner)

	var half_w := _interior_width * 0.5
	var half_h := _interior_height * 0.5
	_add_wall("NorthWall", Vector2(0, -half_h), Vector2(_interior_width + 36.0, 34.0))
	_add_wall("WestWall", Vector2(-half_w, 0), Vector2(34.0, _interior_height + 36.0))
	_add_wall("EastWall", Vector2(half_w, 0), Vector2(34.0, _interior_height + 36.0))
	var entry_x := _entry_x()
	var west_length := entry_x - 70.0 + half_w
	var east_length := half_w - (entry_x + 70.0)
	_add_wall("SouthWallWest", Vector2(-half_w + west_length * 0.5, half_h), Vector2(west_length, 34.0))
	_add_wall("SouthWallEast", Vector2(entry_x + 70.0 + east_length * 0.5, half_h), Vector2(east_length, 34.0))

	for divider in range(1, _room_count):
		var x := -_interior_width * 0.5 + 40.0 + _room_width * float(divider)
		var passage_y := _divider_passage_y(divider)
		var gap_half := 58.0
		var north_length := passage_y - gap_half + half_h
		var south_length := half_h - (passage_y + gap_half)
		_add_wall(
			"Divider%dNorth" % divider,
			Vector2(x, -half_h + north_length * 0.5),
			Vector2(24.0, north_length))
		_add_wall(
			"Divider%dSouth" % divider,
			Vector2(x, passage_y + gap_half + south_length * 0.5),
			Vector2(24.0, south_length))
		_add_door_header(x, passage_y)


func _dress_rooms() -> void:
	var dressing := _identity.get("dressing", []) as Array
	for room in _room_count:
		var center_x := _room_center_x(room)
		var placements: Array = []
		if room < dressing.size():
			placements.append_array(dressing[room] as Array)
		for placement_index in placements.size():
			var placement := placements[placement_index] as Array
			if placement.size() < 4:
				continue
			var prop_id := String(placement[0])
			if prop_id in MISLEADING_DECORATIVE_PROPS:
				continue
			var local_position := placement[1] as Vector2
			_add_prop(
				"Room%d_%02d_%s" % [room + 1, placement_index + 1, prop_id],
				prop_id,
				Vector2(center_x + local_position.x, local_position.y),
				float(placement[2]),
				float(placement[3]),
				room
			)
		_add_room_decal(room, center_x)
	_add_identity_hero()
	set_meta("authored_placement_count", _authored_placement_count())


func _add_practical_lights() -> void:
	var briefs := BuildingCatalog.get_interior_lighting(_building_id)
	var lighting := Node2D.new()
	lighting.name = "AuthoredPracticalLighting"
	add_child(lighting)
	for room_index in mini(_room_count, briefs.size()):
		var brief := briefs[room_index] as Array
		if brief.size() < 5:
			continue
		var local_position := brief[0] as Vector2
		var tone := String(brief[1])
		var radius := clampf(float(brief[2]), 220.0, 300.0)
		var energy := clampf(float(brief[3]), 0.0, 0.65)
		var position_value := Vector2(_room_center_x(room_index) + local_position.x, local_position.y)

		var light := PointLight2D.new()
		light.name = "Room%dPracticalLight" % (room_index + 1)
		light.position = position_value
		light.texture = _practical_light_texture()
		light.texture_scale = radius / 64.0
		light.energy = energy
		light.color = Color(0.98, 0.79, 0.56) if tone == "amber" else Color(0.72, 0.82, 0.76)
		light.blend_mode = Light2D.BLEND_MODE_ADD
		light.shadow_enabled = false
		light.set_meta("room_index", room_index)
		light.set_meta("tone", tone)
		light.set_meta("radius", radius)
		light.set_meta("web_mobile_safe", true)
		light.add_to_group("interior_practical_lights")
		lighting.add_child(light)
		var fixture_position := Vector2(position_value.x, -_interior_height * 0.5 + 48.0)
		_add_practical_fixture(lighting, fixture_position, tone, String(brief[4]), room_index)
	set_meta("practical_light_count", lighting.get_child_count() / 2)


func _add_practical_fixture(
		host: Node2D,
		position_value: Vector2,
		tone: String,
		fixture_kind: String,
		room_index: int
) -> void:
	var fixture := Node2D.new()
	fixture.name = "Room%dPracticalFixture" % (room_index + 1)
	fixture.position = position_value
	fixture.set_meta("room_index", room_index)
	fixture.set_meta("fixture_kind", fixture_kind)
	fixture.rotation = -0.035 if room_index % 2 == 0 else 0.028
	fixture.add_to_group("interior_practical_fixtures")
	host.add_child(fixture)
	if fixture_kind == "shade":
		var sprite := Sprite2D.new()
		sprite.name = "LanternShade"
		sprite.texture = load(PROP_PATHS["lantern"]) as Texture2D
		sprite.scale = Vector2.ONE * 0.075
		sprite.modulate = Color(0.95, 0.82, 0.60, 0.96)
		sprite.z_index = 5
		fixture.add_child(sprite)
		return
	var backplate := Polygon2D.new()
	backplate.name = "TubeBackplate"
	backplate.polygon = _rect_points(Vector2(46, 12))
	backplate.color = Color(0.15, 0.16, 0.145, 0.94)
	backplate.light_mask = 0
	backplate.z_index = 4
	fixture.add_child(backplate)
	for segment_index in 2:
		var tube := Polygon2D.new()
		tube.name = "DullTube%d" % (segment_index + 1)
		tube.position = Vector2(-10 if segment_index == 0 else 10, 0)
		tube.polygon = _rect_points(Vector2(16, 4))
		tube.color = Color(0.44, 0.48, 0.42, 0.86) if tone == "cold" else Color(0.52, 0.43, 0.31, 0.86)
		tube.light_mask = 0
		tube.z_index = 5
		fixture.add_child(tube)


func _practical_light_texture() -> GradientTexture2D:
	if _shared_practical_light_texture != null:
		return _shared_practical_light_texture
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.48, 1.0])
	gradient.colors = PackedColorArray([
		Color(1, 1, 1, 0.92),
		Color(1, 1, 1, 0.34),
		Color(1, 1, 1, 0.0),
	])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 128
	texture.height = 128
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	_shared_practical_light_texture = texture
	return _shared_practical_light_texture


func _authored_placement_count() -> int:
	var count := 0
	for child in get_children():
		if bool(child.get_meta("authored_placement", false)):
			count += 1
	return count


func _add_evidence() -> void:
	var evidence := InteriorEvidence.new()
	evidence.name = "Evidence"
	evidence.evidence_id = _building_id
	evidence.title = "%s / FIELD EVIDENCE" % String(_building.get("title", "UNKNOWN SITE")).to_upper()
	evidence.prompt = String(_building.get("evidence_prompt", "Inspect the evidence"))
	evidence.observation = String(_building.get("evidence", ""))
	evidence.carrier_reading = String(_building.get("scanned", ""))
	evidence.position = Vector2(_room_center_x(_room_count - 1) - 72.0, 8.0)
	evidence.collision_layer = 4
	evidence.collision_mask = 0
	evidence.monitoring = false
	add_child(evidence)

	var visual := Sprite2D.new()
	visual.name = "Visual"
	visual.texture = load(_evidence_texture()) as Texture2D
	visual.scale = Vector2.ONE * 0.15
	visual.position = Vector2(0, -10)
	visual.modulate = Color(0.90, 0.83, 0.66, 1.0)
	visual.z_index = 4
	evidence.add_child(visual)

	var shape := RectangleShape2D.new()
	shape.size = Vector2(66, 56)
	var collision := CollisionShape2D.new()
	collision.name = "TriggerShape"
	collision.shape = shape
	evidence.add_child(collision)

	var marker := Polygon2D.new()
	marker.name = "PaperMarker"
	marker.position = Vector2(0, 12)
	marker.polygon = PackedVector2Array([Vector2(-24, -12), Vector2(24, -10), Vector2(20, 16), Vector2(-22, 14)])
	marker.color = Color(0.72, 0.63, 0.46, 0.24)
	marker.z_index = 3
	evidence.add_child(marker)


func _add_salvage() -> void:
	var cache := LOOT_SCENE.instantiate() as LootContainer
	if cache == null:
		return
	cache.name = "InteriorCache_%s" % String(_building_id)
	cache.persistent_id = StringName(cache.name)
	cache.prompt = "Search the useful remains"
	cache.loot = (_building.get("loot", {&"scrap": 1}) as Dictionary).duplicate(true)
	cache.position = _choose_cache_position()
	cache.set_meta("interaction_visual_contract", "one-visible-cache-one-trigger")
	cache.set_meta("building_id", _building_id)
	add_child(cache)


func _choose_cache_position() -> Vector2:
	# Put the one real cache where it does not sit on top of a map, desk or the
	# building-specific evidence fixture. The last room rewards exploration.
	var room := _room_count - 1
	var centre := _room_center_x(room)
	var candidates := [
		Vector2(centre - 118.0, -112.0),
		Vector2(centre + 118.0, -112.0),
		Vector2(centre - 118.0, 112.0),
		Vector2(centre + 118.0, 112.0),
		Vector2(centre - 104.0, 34.0),
		Vector2(centre + 104.0, 34.0),
	]
	var occupied: Array[Vector2] = []
	for child in get_children():
		if child is Node2D and (
				bool(child.get_meta("authored_placement", false))
				or child.is_in_group("interior_identity_heroes")):
			occupied.append((child as Node2D).position)
	var entry := Vector2(_entry_x(), _interior_height * 0.5 - 82.0)
	occupied.append(entry)
	var best := candidates[0] as Vector2
	var best_clearance := -1.0
	for candidate_value in candidates:
		var candidate := candidate_value as Vector2
		var clearance := INF
		for occupied_position in occupied:
			clearance = minf(clearance, candidate.distance_to(occupied_position))
		if clearance > best_clearance:
			best_clearance = clearance
			best = candidate
	return best


func _add_thresholds() -> void:
	var spawn := Marker2D.new()
	spawn.name = "from_world"
	spawn.position = Vector2(_entry_x(), _interior_height * 0.5 - 82.0)
	spawn.add_to_group("spawn_points")
	add_child(spawn)

	var exit := DOOR_SCENE.instantiate() as BuildingDoor
	if exit != null:
		exit.name = "ReturnToWorld"
		exit.returns_to_world = true
		exit.position = Vector2(_entry_x(), _interior_height * 0.5 - 10.0)
		exit.scale = Vector2(0.86, 0.86)
		add_child(exit)


func _add_wall(node_name: String, position_value: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.name = node_name
	body.position = position_value
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)

	var visual := Polygon2D.new()
	visual.name = "Visual"
	visual.polygon = _rect_points(size)
	visual.color = _wall_tint()
	visual.z_index = 8
	body.add_child(visual)

	var shape := RectangleShape2D.new()
	shape.size = size
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	collision.shape = shape
	body.add_child(collision)


func _add_door_header(x: float, passage_y: float) -> void:
	var header := Polygon2D.new()
	header.name = "RoomThreshold"
	header.position = Vector2(x, passage_y)
	# A narrow worn sill marks the passage without painting a false door-sized
	# blocker over the deliberately open collision gap.
	header.polygon = PackedVector2Array([Vector2(-5, -48), Vector2(5, -48), Vector2(5, 48), Vector2(-5, 48)])
	header.color = Color(0.39, 0.31, 0.20, 0.38)
	header.z_index = 0
	add_child(header)


func _add_prop(
	node_name: String,
	prop_id: String,
	position_value: Vector2,
	scale_multiplier := 1.0,
	rotation_value := 0.0,
	room_index := -1
) -> void:
	var path := String(PROP_PATHS.get(prop_id, ""))
	var spec: Dictionary = PROP_SPECS.get(prop_id, {})
	var texture := load(path) as Texture2D
	if texture == null or spec.is_empty():
		return
	var solid: Vector2 = spec.get("solid", Vector2.ZERO)
	var holder: Node2D
	if solid.length_squared() > 0.0:
		var body := StaticBody2D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		holder = body
	else:
		holder = Node2D.new()
	holder.name = node_name
	holder.position = position_value
	holder.rotation = rotation_value
	if room_index >= 0:
		holder.set_meta("authored_placement", true)
		holder.set_meta("interior_identity", String(_identity.get("identity_key", "")))
		holder.set_meta("room_index", room_index)
		holder.set_meta("prop_id", prop_id)
	add_child(holder)

	var sprite := Sprite2D.new()
	sprite.name = "Visual"
	sprite.texture = texture
	sprite.scale = Vector2.ONE * float(spec.get("scale", 0.16)) * scale_multiplier
	sprite.position = Vector2(0, float(spec.get("lift", -10.0)))
	sprite.modulate = Color(0.95, 0.91, 0.82, 1.0)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.z_index = 4
	holder.add_child(sprite)

	if solid.length_squared() > 0.0:
		var shape := RectangleShape2D.new()
		shape.size = solid * scale_multiplier
		var collision := CollisionShape2D.new()
		collision.name = "CollisionShape2D"
		collision.position = Vector2(0, solid.y * 0.10)
		collision.shape = shape
		holder.add_child(collision)


func _add_identity_hero() -> void:
	var cell := _identity.get("atlas_cell", Vector2i(-1, -1)) as Vector2i
	if cell.x < 0 or cell.y < 0:
		return

	var hero_room := clampi(int(_identity.get("hero_room", 0)), 0, _room_count - 1)
	var offset := _identity.get("hero_offset", Vector2(0, -112)) as Vector2
	var holder := InteriorEvidence.new()
	holder.name = "Evidence_%s" % String(_identity.get("identity_key", "unknown"))
	holder.evidence_id = _building_id
	holder.title = "%s / FIELD EVIDENCE" % String(
		_building.get("title", "UNKNOWN SITE")).to_upper()
	holder.prompt = String(_building.get("evidence_prompt", "Inspect the evidence"))
	holder.observation = String(_building.get("evidence", ""))
	holder.carrier_reading = String(_building.get("scanned", ""))
	holder.position = Vector2(
		_room_center_x(hero_room) + clampf(offset.x, -118.0, 118.0),
		clampf(offset.y, -132.0, -76.0)
	)
	holder.collision_layer = 4
	holder.collision_mask = 0
	holder.monitoring = false
	holder.set_meta("building_id", _building_id)
	holder.set_meta("interior_identity", String(_identity.get("identity_key", "")))
	holder.set_meta("layout_identity", String(_identity.get("layout_key", "")))
	holder.set_meta("atlas_cell", cell)
	holder.set_meta("presentation", "interactive-identity-fixture")
	holder.add_to_group("interior_identity_heroes")
	add_child(holder)

	var atlas := load(BuildingCatalog.INTERIOR_IDENTITY_ATLAS) as Texture2D
	if atlas == null:
		return
	var cell_size := atlas.get_size() / Vector2(BuildingCatalog.INTERIOR_ATLAS_GRID)
	var crop_inset := Vector2(14, 10)
	var texture := AtlasTexture.new()
	texture.atlas = atlas
	texture.region = Rect2(
		Vector2(cell) * cell_size + crop_inset,
		cell_size - crop_inset * 2.0)
	texture.filter_clip = true
	var visual := Sprite2D.new()
	visual.name = "Visual"
	visual.texture = texture
	visual.scale = Vector2.ONE * float(_identity.get("hero_scale", 0.64))
	visual.position = Vector2(0, -12)
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	visual.z_index = 4
	holder.add_child(visual)

	var trigger_shape := RectangleShape2D.new()
	trigger_shape.size = Vector2(150, 92)
	var trigger := CollisionShape2D.new()
	trigger.name = "TriggerShape"
	trigger.position = Vector2(0, 10)
	trigger.shape = trigger_shape
	holder.add_child(trigger)

	var solid := StaticBody2D.new()
	solid.name = "SolidFootprint"
	solid.collision_layer = 1
	solid.collision_mask = 0
	holder.add_child(solid)
	var solid_shape := RectangleShape2D.new()
	solid_shape.size = Vector2(118, 48)
	var solid_collision := CollisionShape2D.new()
	solid_collision.name = "CollisionShape2D"
	solid_collision.position = Vector2(0, 22)
	solid_collision.shape = solid_shape
	solid.add_child(solid_collision)

	var glint := Polygon2D.new()
	glint.name = "EvidenceGlint"
	glint.position = Vector2(0, -58)
	glint.polygon = PackedVector2Array([
		Vector2(-4, -9), Vector2(0, -2), Vector2(8, 0),
		Vector2(0, 3), Vector2(-4, 11), Vector2(-8, 3),
		Vector2(-16, 0), Vector2(-8, -3),
	])
	glint.color = Color(0.48, 0.88, 0.84, 0.66)
	glint.z_index = 6
	holder.add_child(glint)


func _add_room_decal(room: int, center_x: float) -> void:
	var cell := _identity.get("atlas_cell", Vector2i.ZERO) as Vector2i
	var identity_seed := cell.y * BuildingCatalog.INTERIOR_ATLAS_GRID.x + cell.x
	var decal := Polygon2D.new()
	decal.name = "Room%dWear" % (room + 1)
	var x_offset := -46.0 + float((identity_seed * 29 + room * 47) % 93)
	var y_offset := -8.0 + float((identity_seed * 17 + room * 31) % 47)
	decal.position = Vector2(center_x + x_offset, y_offset)
	decal.rotation = -0.14 + float((identity_seed * 11 + room * 7) % 29) * 0.01
	decal.polygon = PackedVector2Array([
		Vector2(-58, -12), Vector2(-20, -18), Vector2(50, -8),
		Vector2(64, 9), Vector2(12, 16), Vector2(-54, 10),
	])
	decal.color = Color(0.11, 0.105, 0.09, 0.16)
	decal.z_index = -1
	decal.set_meta("interior_identity", String(_identity.get("identity_key", "")))
	add_child(decal)


func _add_floor_insets() -> void:
	var theme := String(_building.get("theme", "service"))
	for room in _room_count:
		var inset := Polygon2D.new()
		inset.name = "Room%dMaterialInset" % (room + 1)
		inset.position = Vector2(_room_center_x(room), -8)
		inset.polygon = _rect_points(Vector2(_room_width - 38.0, _interior_height - 62.0))
		inset.color = {
			"home": Color(0.19, 0.145, 0.105, 0.64),
			"school": Color(0.20, 0.16, 0.105, 0.60),
			"shop": Color(0.17, 0.15, 0.105, 0.62),
			"clinic": Color(0.145, 0.18, 0.17, 0.62),
			"garage": Color(0.115, 0.135, 0.13, 0.70),
			"workshop": Color(0.12, 0.145, 0.135, 0.68),
			"utility": Color(0.105, 0.13, 0.125, 0.72),
			"bunker": Color(0.10, 0.115, 0.11, 0.74),
			"industrial": Color(0.11, 0.125, 0.115, 0.72),
			"service": Color(0.155, 0.145, 0.115, 0.66),
		}.get(theme, Color(0.14, 0.145, 0.125, 0.66))
		inset.z_index = -2
		add_child(inset)


func _add_floor_seams() -> void:
	var seams := Node2D.new()
	seams.name = "FloorSeams"
	seams.z_index = -2
	add_child(seams)
	for room in _room_count:
		var centre := _room_center_x(room)
		var horizontal_material := String(_building.get("theme", "")) in [
			"home", "school", "shop", "service"]
		for stripe in range(-2, 3):
			var seam := Polygon2D.new()
			if horizontal_material:
				seam.position = Vector2(centre, float(stripe) * 68.0 - 8.0)
				seam.polygon = _rect_points(Vector2(_room_width - 52.0, 2.0))
			else:
				seam.position = Vector2(centre + float(stripe) * 64.0, -8.0)
				seam.polygon = _rect_points(Vector2(2.0, _interior_height - 76.0))
			seam.color = Color(0.035, 0.042, 0.039, 0.32)
			seams.add_child(seam)


func _room_center_x(room: int) -> float:
	return -_interior_width * 0.5 + 40.0 + _room_width * (float(room) + 0.5)


func _divider_passage_y(divider: int) -> float:
	var layout_key := String(_identity.get("layout_key", ""))
	var hash_value: int = absi(layout_key.hash() + divider * 97)
	var passage_options: PackedFloat32Array = PackedFloat32Array([-78.0, 0.0, 78.0])
	return passage_options[hash_value % 3]


func _entry_x() -> float:
	# With two rooms the geometric centre is also the partition. Putting the
	# threshold there used to spawn the player inside Divider1South.
	return _room_center_x(0) if _room_count == 2 else 0.0


func _hero_prop(hero: String) -> String:
	return {
		"counter": "counter",
		"vending": "vending",
		"workbench": "workbench",
		"toolbox": "toolbox",
		"locker": "locker",
		"radio": "radio_desk",
		"bedroll": "bedroll",
		"medicine": "medicine",
		"map": "map",
		"chairs": "empty_bench",
		"oxygen": "medicine",
		"radio_desk": "radio_desk",
		"switchgear": "receiver",
		"control_bank": "radio_desk",
		"cable_reel": "workbench",
		"aerial_console": "receiver",
		"generator": "workbench",
	}.get(hero, "")


func _evidence_texture() -> String:
	var theme := String(_building.get("theme", ""))
	if theme in ["home", "school"]:
		return PROP_PATHS["photo"]
	if theme in ["utility", "bunker", "industrial", "workshop"]:
		return PROP_PATHS["radio"]
	if theme == "clinic":
		return PROP_PATHS["medicine"]
	return PROP_PATHS["compass"]


func _floor_texture() -> String:
	var theme := String(_building.get("theme", ""))
	if theme in ["home", "school", "shop"]:
		return TEX_WOOD
	if theme in ["utility", "bunker", "industrial", "workshop", "garage"]:
		return TEX_METAL
	return TEX_CONCRETE


func _floor_tint() -> Color:
	if _identity.has("palette"):
		var authored := _identity["palette"] as Color
		return authored.darkened(0.34)
	var theme := String(_building.get("theme", ""))
	if theme in ["home", "school", "shop"]:
		return Color(0.34, 0.30, 0.24, 1.0)
	if theme == "clinic":
		return Color(0.31, 0.34, 0.31, 1.0)
	return Color(0.27, 0.29, 0.27, 1.0)


func _wall_tint() -> Color:
	var authored := _identity.get("palette", Color(0.28, 0.27, 0.23, 1.0)) as Color
	return authored.darkened(0.48).lerp(Color(0.12, 0.13, 0.12, 1.0), 0.46)


func _runner_tint() -> Color:
	var authored := _identity.get("runner_tint", Color(0.28, 0.25, 0.20, 0.54)) as Color
	var grounded := authored.darkened(0.34)
	grounded.a = 0.62
	return grounded


func _arrival_line() -> String:
	var theme := String(_building.get("theme", "building"))
	return {
		"home": "The rooms still hold heat in the fabric. Nothing else here should be warm.",
		"clinic": "Antiseptic, damp plaster and the soft carrier whine of an unplugged monitor.",
		"school": "The hall is quiet enough to hear paper settling in locked cupboards.",
		"workshop": "Tools remain where someone dropped them. One bench light is already on.",
		"garage": "Rain ticks on the shutters. Somewhere inside, an engine cools.",
		"utility": "Dead switchgear answers the Receiver with a slow electrical knock.",
		"bunker": "The concrete swallows the wind. The voice does not get quieter.",
		"industrial": "The machinery is still. Its rhythm continues under the floor.",
	}.get(theme, "Inside, ordinary objects have been left in the middle of ordinary tasks.")


func _rect_points(size: Vector2) -> PackedVector2Array:
	var half := size * 0.5
	return PackedVector2Array([
		Vector2(-half.x, -half.y), Vector2(half.x, -half.y),
		Vector2(half.x, half.y), Vector2(-half.x, half.y),
	])
