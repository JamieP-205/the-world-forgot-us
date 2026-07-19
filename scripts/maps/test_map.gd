extends Node2D
## Content pass scene glue for the current hand-built demo map.

const CAMPAIGN_INTERACTABLE := preload("res://scenes/world/campaign_interactable.tscn")
const BUILDING_DOOR_SCENE := preload("res://scenes/world/building_door.tscn")
const WORLD_NPC_POPULATION_SCENE := preload("res://scenes/npcs/world_npc_population.tscn")
const BuildingCatalog = preload("res://scripts/world/building_catalog.gd")
const CULLBROOK_SCENE := "res://scenes/maps/test_map.tscn"
const RAILHOME_EXTERIOR := "res://assets/processed/environment_rebuild/railhome_depot_exterior.png"
const ASH_ASPHALT_SURFACE := "res://assets/processed/environment/ash_asphalt_seamless.png"

@onready var _mast_glow: Polygon2D = $RadioMast/RecoveredGlow
@onready var _spark_a: Polygon2D = $RadioMast/StaticSparkA
@onready var _spark_b: Polygon2D = $RadioMast/StaticSparkB
@onready var _spark_c: Polygon2D = $RadioMast/StaticSparkC
@onready var _north_signal: Node2D = $NorthSignal

var _time := 0.0
var _recovered := false


func _ready() -> void:
	ArchiveSystem.echo_recorded.connect(_on_echo_recorded)
	_author_cullbrook_layout()
	_remove_world_atlas_fills()
	_tune_world_palette()
	_restore_authored_world_surfaces()
	_dress_cullbrook_exteriors()
	_add_railhome_exterior()
	_add_enterable_buildings()
	_add_first_route_guidance()
	_tag_cullbrook_solids()
	WorldLayoutContract.apply(self, &"cullbrook")
	_add_world_npc_population()
	if ArchiveSystem.has_echo(&"echo_last_signal"):
		_apply_mast_recovered()
	# Once the Radio Desk is online, a new signal shows itself in the north.
	_north_signal.visible = BaseUpgradeSystem.is_built(&"radio_desk")
	if _north_signal.visible:
		_add_north_road_interaction()
		_maybe_show_ending_hook()


func _add_world_npc_population() -> void:
	var population := WORLD_NPC_POPULATION_SCENE.instantiate() as WorldNPCPopulation
	if population == null:
		return
	population.name = "WorldNPCPopulation"
	population.region_id = "cullbrook"
	add_child(population)


func _add_enterable_buildings() -> void:
	_add_building_door(&"cullbrook_service_office", Vector2(389, -188))
	_add_building_door(&"cullbrook_kiosk", Vector2(-405, 88))
	_add_building_door(&"cullbrook_maintenance_shed", Vector2(235, 176))
	_add_building_door(&"cullbrook_north_bay", Vector2(690, 350))
	_add_building_door(&"cullbrook_south_bay", Vector2(770, 520), Vector2(-108, 0))


func _add_building_door(
		building_id: StringName,
		position_value: Vector2,
		return_offset := Vector2(0, 96)) -> void:
	var spawn_name := StringName("return_%s" % String(building_id))
	var spawn := Marker2D.new()
	spawn.name = String(spawn_name)
	spawn.position = position_value + return_offset
	spawn.add_to_group("spawn_points")
	add_child(spawn)

	var door := BUILDING_DOOR_SCENE.instantiate() as BuildingDoor
	if door == null:
		return
	door.name = "%sThreshold" % String(building_id).to_pascal_case()
	door.position = position_value
	door.scale = Vector2(0.82, 0.82)
	door.building_id = building_id
	door.return_scene_path = CULLBROOK_SCENE
	door.return_spawn = spawn_name
	door.add_to_group("objective_targets")
	door.add_to_group("enterable_building_thresholds")
	door.set_meta("building_id", building_id)
	door.set_meta("room_count", int(BuildingCatalog.get_building(building_id).get("rooms", 1)))
	door.set_meta("threshold_clearance", WorldLayoutContract.PLAYER_REFERENCE * 1.12)
	add_child(door)


func _author_cullbrook_layout() -> void:
	# Cullbrook is a compact hub with a forecourt loop, a service-yard loop and
	# a narrow maintenance cut between them. Scaling the entire bodies keeps the
	# painted walls and their collision perfectly registered.
	_scale_structure("PetrolStation", Vector2(1.35, 1.35))
	_scale_structure("RoadsideKiosk", Vector2(2.07, 2.07))
	_scale_structure("MaintenanceShed", Vector2(2.67, 2.67))
	_scale_structure("ServiceBayNorth", Vector2(2.10, 2.10), Vector2(690, 245))
	_scale_structure("ServiceBaySouth", Vector2(2.10, 2.10), Vector2(770, 415))
	$RadioMast.position = Vector2(650, -270)

	var cut := Polygon2D.new()
	cut.name = "MaintenanceCut"
	cut.z_index = -1
	cut.polygon = PackedVector2Array([
		Vector2(300, 84), Vector2(386, 92), Vector2(520, 172), Vector2(596, 238),
		Vector2(538, 276), Vector2(458, 205), Vector2(352, 145), Vector2(282, 134),
	])
	cut.color = Color(0.46, 0.43, 0.35, 0.92)
	add_child(cut)
	move_child(cut, 7)


func _remove_world_atlas_fills() -> void:
	# The processed decal sheets contain several objects on transparent cards;
	# repeating them inside roads or walls creates giant black rectangles.
	# World polygons keep their authored silhouettes and material colours while
	# actual props remain individual Sprite2D art.
	for node in find_children("*", "Polygon2D", true, false):
		var polygon := node as Polygon2D
		if polygon != null and polygon.texture != null:
			polygon.texture = null
			polygon.uv = PackedVector2Array()
			polygon.set_meta("atlas_fill_removed", true)


func _tune_world_palette() -> void:
	var palette := {
		^"Road": Color(0.29, 0.285, 0.255, 1.0),
		^"PetrolStation/StationFloor": Color(0.25, 0.255, 0.23, 1.0),
		^"PetrolStation/Office": Color(0.29, 0.27, 0.22, 1.0),
		^"PetrolStation/OfficeRoof": Color(0.25, 0.15, 0.105, 1.0),
		^"PetrolStation/Canopy": Color(0.27, 0.16, 0.11, 1.0),
		^"RoadsideKiosk/KioskWall": Color(0.27, 0.25, 0.20, 1.0),
		^"RoadsideKiosk/KioskRoof": Color(0.24, 0.145, 0.10, 1.0),
		^"RoadsideKiosk/KioskWindow": Color(0.105, 0.12, 0.105, 1.0),
		^"MaintenanceShed/ShedWall": Color(0.25, 0.27, 0.225, 1.0),
		^"MaintenanceShed/ShedRoof": Color(0.28, 0.22, 0.145, 1.0),
		^"MaintenanceShed/ShedGap": Color(0.105, 0.11, 0.095, 1.0),
		^"CullbrookServiceLoop": Color(0.28, 0.275, 0.25, 1.0),
		^"CullbrookDrainageTrack": Color(0.255, 0.245, 0.21, 0.94),
		^"ServiceYardApron": Color(0.27, 0.265, 0.235, 0.96),
		^"ServiceBayNorth/Visual": Color(0.255, 0.245, 0.21, 1.0),
		^"ServiceBaySouth/Visual": Color(0.24, 0.215, 0.175, 1.0),
	}
	for path in palette:
		var polygon := get_node_or_null(path) as Polygon2D
		if polygon != null:
			polygon.color = palette[path]


func _restore_authored_world_surfaces() -> void:
	# Decal sheets are prop atlases and must never be stretched over geometry.
	# Cullbrook's seamless asphalt is a true material tile, so it can carry
	# detail across roads, forecourts and building shells without introducing
	# rectangular cards or mismatched collision.
	var texture := load(ASH_ASPHALT_SURFACE) as Texture2D
	if texture == null:
		return
	var surfaces := {
		^"Road": Color(0.66, 0.64, 0.56, 1.0),
		^"MaintenanceCut": Color(0.62, 0.58, 0.48, 0.94),
		^"CullbrookServiceLoop": Color(0.64, 0.63, 0.56, 1.0),
		^"CullbrookDrainageTrack": Color(0.58, 0.55, 0.47, 0.96),
		^"ServiceYardApron": Color(0.62, 0.61, 0.54, 0.96),
		^"PetrolStation/StationFloor": Color(0.62, 0.62, 0.56, 1.0),
		^"PetrolStation/Office": Color(0.55, 0.50, 0.42, 1.0),
		^"PetrolStation/OfficeRoof": Color(0.50, 0.34, 0.25, 1.0),
		^"PetrolStation/Canopy": Color(0.54, 0.36, 0.25, 1.0),
		^"RoadsideKiosk/KioskWall": Color(0.54, 0.50, 0.42, 1.0),
		^"RoadsideKiosk/KioskRoof": Color(0.50, 0.34, 0.25, 1.0),
		^"MaintenanceShed/ShedWall": Color(0.52, 0.54, 0.46, 1.0),
		^"MaintenanceShed/ShedRoof": Color(0.52, 0.42, 0.29, 1.0),
		^"ServiceBayNorth/Visual": Color(0.52, 0.50, 0.43, 1.0),
		^"ServiceBayNorth/Roof": Color(0.46, 0.34, 0.25, 1.0),
		^"ServiceBaySouth/Visual": Color(0.50, 0.45, 0.36, 1.0),
	}
	for path in surfaces:
		var polygon := get_node_or_null(path) as Polygon2D
		if polygon == null:
			continue
		polygon.texture = texture
		polygon.uv = PackedVector2Array()
		polygon.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		polygon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		var world_scale := maxf(absf(polygon.global_scale.x), absf(polygon.global_scale.y))
		polygon.texture_scale = Vector2.ONE * maxf(world_scale, 1.0)
		polygon.color = surfaces[path]
		polygon.set_meta("seamless_world_surface", true)


func _dress_cullbrook_exteriors() -> void:
	# These buildings are deliberately architecture-sized. Layered roofs,
	# shallow front panels and one aligned door keep that mass readable instead
	# of leaving a large textured rectangle with no sense of facade.
	_dress_compact_exterior($RoadsideKiosk, Vector2(150, 66), 0.0, Color(0.72, 0.52, 0.35, 1.0))
	_dress_compact_exterior($MaintenanceShed, Vector2(152, 70), 4.0, Color(0.68, 0.56, 0.38, 1.0))
	_dress_compact_exterior($ServiceBayNorth, Vector2(150, 70), 0.0, Color(0.62, 0.57, 0.46, 1.0))
	_dress_compact_exterior($ServiceBaySouth, Vector2(150, 70), 0.0, Color(0.68, 0.50, 0.34, 1.0))

	var office_door := Polygon2D.new()
	office_door.name = "AlignedOfficeDoor"
	office_door.position = Vector2(288, -177)
	office_door.polygon = WorldLayoutContract.rectangle_points(Vector2(34, 48))
	office_door.color = Color(0.09, 0.105, 0.095, 1.0)
	office_door.z_index = 3
	$PetrolStation.add_child(office_door)
	var office_lintel := Polygon2D.new()
	office_lintel.name = "AlignedOfficeLintel"
	office_lintel.position = Vector2(288, -204)
	office_lintel.polygon = WorldLayoutContract.rectangle_points(Vector2(46, 5))
	office_lintel.color = Color(0.63, 0.43, 0.20, 0.68)
	office_lintel.z_index = 4
	$PetrolStation.add_child(office_lintel)


func _dress_compact_exterior(
		body: StaticBody2D,
		size: Vector2,
		door_x: float,
		roof_tint: Color) -> void:
	if body == null:
		return
	var half := size * 0.5
	var roof := Polygon2D.new()
	roof.name = "RoofInset"
	roof.position = Vector2(0, -size.y * 0.10)
	roof.polygon = PackedVector2Array([
		Vector2(-half.x * 0.84, -half.y * 0.66),
		Vector2(half.x * 0.78, -half.y * 0.72),
		Vector2(half.x * 0.88, half.y * 0.02),
		Vector2(half.x * 0.72, half.y * 0.46),
		Vector2(-half.x * 0.78, half.y * 0.48),
		Vector2(-half.x * 0.88, -half.y * 0.02),
	])
	roof.color = roof_tint
	roof.z_index = 2
	var roof_texture := load(ASH_ASPHALT_SURFACE) as Texture2D
	if roof_texture != null:
		roof.texture = roof_texture
		roof.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		roof.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		var world_scale := maxf(absf(body.global_scale.x), absf(body.global_scale.y))
		roof.texture_scale = Vector2.ONE * maxf(world_scale, 1.0)
		roof.set_meta("seamless_world_surface", true)
	body.add_child(roof)

	for index in 3:
		var seam := Line2D.new()
		seam.name = "RoofSeam%d" % (index + 1)
		var x := size.x * (-0.25 + float(index) * 0.25)
		seam.points = PackedVector2Array([
			Vector2(x - 3, -size.y * 0.36),
			Vector2(x + 3, size.y * 0.10),
		])
		seam.width = 1.2
		seam.default_color = Color(0.70, 0.45, 0.20, 0.30)
		seam.z_index = 3
		body.add_child(seam)

	var door := Polygon2D.new()
	door.name = "AlignedDoor"
	door.position = Vector2(door_x, size.y * 0.17)
	door.polygon = WorldLayoutContract.rectangle_points(Vector2(27, 31))
	door.color = Color(0.085, 0.10, 0.09, 1.0)
	door.z_index = 4
	body.add_child(door)

	var lintel := Polygon2D.new()
	lintel.name = "AlignedLintel"
	lintel.position = Vector2(door_x, -1)
	lintel.polygon = WorldLayoutContract.rectangle_points(Vector2(36, 4))
	lintel.color = Color(0.60, 0.40, 0.18, 0.68)
	lintel.z_index = 5
	body.add_child(lintel)

	for side in [-1.0, 1.0]:
		var window := Polygon2D.new()
		window.name = "WindowWest" if side < 0.0 else "WindowEast"
		window.position = Vector2(size.x * 0.25 * side, size.y * 0.16)
		window.polygon = WorldLayoutContract.rectangle_points(Vector2(24, 12))
		window.color = Color(0.07, 0.13, 0.125, 0.78)
		window.z_index = 4
		body.add_child(window)


func _scale_structure(
		node_path: NodePath,
		scale_value: Vector2,
		position_value := Vector2(INF, INF)) -> void:
	var body := get_node_or_null(node_path) as StaticBody2D
	if body == null:
		return
	body.scale = scale_value
	if is_finite(position_value.x) and is_finite(position_value.y):
		body.position = position_value


func _add_railhome_exterior() -> void:
	# Carriage 317 is a converted relay depot, not a freestanding magic door.
	# Its shell is one honest solid foot; the travel threshold sits on the
	# exterior apron, so the player can never walk under the painted building.
	var exterior := StaticBody2D.new()
	exterior.name = "Carriage317Exterior"
	# The painted doorway sits left of the depot's visual centre. This offset
	# aligns it with the real interaction threshold at (-690, 282).
	exterior.position = Vector2(-643, 308)
	exterior.collision_layer = 1
	exterior.collision_mask = 0
	exterior.add_to_group("lighting_amber")
	exterior.set_meta("lighting_priority", 340.0)
	add_child(exterior)

	var texture := load(RAILHOME_EXTERIOR) as Texture2D
	if texture != null:
		var art := Sprite2D.new()
		art.name = "DepotShell"
		art.texture = texture
		art.position = Vector2(0, -28)
		art.scale = Vector2(0.255, 0.255)
		art.modulate = Color(0.72, 0.70, 0.61, 0.98)
		art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		art.z_index = 0
		exterior.add_child(art)

	_add_rect_collision(exterior, "DepotFoot", Vector2(418, 142), Vector2(0, -34))
	WorldLayoutContract.tag_solid(
		exterior,
		&"home_base_exterior",
		WorldLayoutContract.rectangle_points(Vector2(418, 142), Vector2(0, -34)),
		false
	)
	exterior.set_meta("door_gap_center_x", -47.0)
	exterior.set_meta("door_gap_width", 0.0)
	exterior.set_meta("entry_state", "intact-enterable")
	exterior.set_meta("player_scale_units", Vector2(418, 142) / WorldLayoutContract.PLAYER_REFERENCE)

	var threshold_shadow := Polygon2D.new()
	threshold_shadow.name = "ThresholdApron"
	threshold_shadow.position = Vector2(-690, 351)
	threshold_shadow.polygon = PackedVector2Array([
		Vector2(-58, -8), Vector2(58, -8), Vector2(72, 24), Vector2(-72, 24),
	])
	threshold_shadow.color = Color(0.09, 0.085, 0.07, 0.34)
	threshold_shadow.z_index = 2
	add_child(threshold_shadow)

	$BaseDoor.scale = Vector2(0.86, 0.86)
	$BaseDoor.position = Vector2(-690, 355)
	$BaseDoor.presentation = "painted_door"
	$BaseDoor.call("_apply_presentation")
	$from_base.position = Vector2(-690, 415)


func _add_rect_collision(
		body: StaticBody2D,
		node_name: String,
		size: Vector2,
		position_value: Vector2) -> void:
	var shape := RectangleShape2D.new()
	shape.size = size
	var collision := CollisionShape2D.new()
	collision.name = node_name
	collision.position = position_value
	collision.shape = shape
	body.add_child(collision)


func _tag_cullbrook_solids() -> void:
	WorldLayoutContract.tag_boundary($WastelandBounds, "WastelandApron")
	_tag_existing_solid(
		$BrokenCar, &"physical_prop",
		WorldLayoutContract.rectangle_points(Vector2(110, 48))
	)
	_tag_enterable_exterior(
		$PetrolStation, &"cullbrook_service_office",
		WorldLayoutContract.rectangle_points(Vector2(388, 215), Vector2(110, -125))
	)
	_tag_enterable_exterior(
		$RoadsideKiosk, &"cullbrook_kiosk",
		WorldLayoutContract.rectangle_points(Vector2(150, 66))
	)
	_tag_enterable_exterior(
		$MaintenanceShed, &"cullbrook_maintenance_shed",
		WorldLayoutContract.rectangle_points(Vector2(152, 70))
	)
	_tag_enterable_exterior(
		$ServiceBayNorth, &"cullbrook_north_bay",
		WorldLayoutContract.rectangle_points(Vector2(150, 70))
	)
	_tag_enterable_exterior(
		$ServiceBaySouth, &"cullbrook_south_bay",
		WorldLayoutContract.rectangle_points(Vector2(150, 70))
	)
	_tag_existing_solid(
		$RadioMast, &"signal_landmark",
		WorldLayoutContract.rectangle_points(Vector2(180, 80))
	)
	_tag_existing_solid(
		$Rubble, &"blocked_ruin",
		WorldLayoutContract.rectangle_points(Vector2(730, 320), Vector2(-80, 180))
	)
	$Rubble.set_meta("entry_state", "visibly-blocked")


func _tag_existing_solid(
		body: StaticBody2D,
		kind: StringName,
		footprint: PackedVector2Array) -> void:
	WorldLayoutContract.tag_solid(body, kind, footprint)


func _tag_enterable_exterior(
		body: StaticBody2D,
		building_id: StringName,
		footprint: PackedVector2Array) -> void:
	WorldLayoutContract.tag_solid(body, &"intact_building", footprint)
	var building := BuildingCatalog.get_building(building_id)
	body.set_meta("building_id", building_id)
	body.set_meta("room_count", int(building.get("rooms", 1)))
	body.set_meta("entry_state", "intact-enterable")
	body.set_meta("player_scale_units", _collision_extent_world(body) / WorldLayoutContract.PLAYER_REFERENCE)


func _collision_extent_world(body: StaticBody2D) -> Vector2:
	var first := true
	var bounds := Rect2()
	for child in body.get_children():
		var collision := child as CollisionShape2D
		if collision == null or collision.shape == null:
			continue
		var local_rect := collision.shape.get_rect()
		var transformed := Rect2(collision.position + local_rect.position, local_rect.size)
		if first:
			bounds = transformed
			first = false
		else:
			bounds = bounds.merge(transformed)
	return bounds.size * body.scale.abs()


func _add_first_route_guidance() -> void:
	# Old county crews marked safe service access with three amber dashes.
	# Repeating that language from the carriage to the first crate guides the
	# eye without a floating arrow or quest rail.
	var route_marks := Node2D.new()
	route_marks.name = "FirstSupplyRouteMarks"
	route_marks.set_meta("guides_to", "RoadsideCrate")
	add_child(route_marks)
	var positions := [
		Vector2(-656, 365),
		Vector2(-604, 316),
		Vector2(-558, 266),
		Vector2(-520, 226),
	]
	for index in positions.size():
		var mark := Polygon2D.new()
		mark.name = "WornAmberDash%d" % (index + 1)
		mark.position = positions[index]
		mark.rotation = -0.76
		mark.polygon = WorldLayoutContract.rectangle_points(Vector2(24, 6))
		mark.color = Color(0.78, 0.55, 0.25, 0.34 + float(index) * 0.06)
		mark.z_index = -1
		route_marks.add_child(mark)


func _process(delta: float) -> void:
	_time += delta
	var cold_alpha := 0.34 + sin(_time * 4.1) * 0.12
	if _recovered:
		var warm_alpha := 0.24 + sin(_time * 2.3) * 0.08
		_mast_glow.color = Color(1.0, 0.86, 0.42, warm_alpha)
	else:
		_spark_a.color.a = cold_alpha
		_spark_b.color.a = cold_alpha * 0.8
		_spark_c.color.a = cold_alpha * 0.65
	if _north_signal.visible:
		_north_signal.modulate.a = 0.6 + sin(_time * 3.0) * 0.32


## Act transition: after the Radio Desk is built and the player explicitly
## rests, the signal introduces the playable road to Ashmere.
func _maybe_show_ending_hook() -> void:
	if WorldState.ending_hook_shown:
		return
	if not WorldState.has_flag(&"rested_after_radio"):
		return
	WorldState.ending_hook_shown = true
	var msg := "A NEW SIGNAL claws in from the north - louder than the last, and wrong somewhere underneath.\n\"...come north... it isn't finished forgetting...\"\nThe next road is out there, and it is already changing."
	msg = "A NEW SIGNAL claws in from the north - louder than the last, and carrying a name.\nEllie... Ashmere... follow the sun on the lid.\nThe north road is open."
	if BaseUpgradeSystem.is_built(&"route_beacon"):
		msg += "\nBehind you the beacon burns steady. The way home, at least, will keep."
	AudioManager.play(&"ending")
	EventBus.notice_posted.emit(msg)
	EventBus.camera_shake_requested.emit(2.0, 0.16)


func _add_north_road_interaction() -> void:
	if _north_signal.has_node("NorthRoad"):
		return
	var gate := CAMPAIGN_INTERACTABLE.instantiate() as CampaignInteractable
	if gate == null:
		return
	gate.name = "NorthRoad"
	gate.story_id = &"north_signal"
	gate.prompt = "Follow the signal north"
	gate.accent = Color(1.0, 0.72, 0.34, 1.0)
	gate.position = Vector2.ZERO
	_north_signal.add_child(gate)


func _on_echo_recorded(data: MemoryEchoData) -> void:
	if data != null and data.id == &"echo_last_signal":
		_apply_mast_recovered()


func _apply_mast_recovered() -> void:
	_recovered = true
	_mast_glow.visible = true
	_spark_a.color = Color(1.0, 0.86, 0.42, 0.75)
	_spark_b.color = Color(1.0, 0.86, 0.42, 0.65)
	_spark_c.color = Color(1.0, 0.86, 0.42, 0.55)
