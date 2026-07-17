extends Node2D
## Content pass scene glue for the current hand-built demo map.

const CAMPAIGN_INTERACTABLE := preload("res://scenes/world/campaign_interactable.tscn")
const BUILDING_DOOR_SCENE := preload("res://scenes/world/building_door.tscn")
const WORLD_NPC_POPULATION_SCENE := preload("res://scenes/npcs/world_npc_population.tscn")
const BuildingCatalog = preload("res://scripts/world/building_catalog.gd")
const CULLBROOK_SCENE := "res://scenes/maps/test_map.tscn"
const RAILHOME_EXTERIOR := "res://assets/processed/environment_rebuild/railhome_depot_exterior.png"

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
	_add_railhome_exterior()
	_add_enterable_buildings()
	_add_cullbrook_prop_footprints()
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
	var gravel := load("res://assets/processed/decals/dirt_gravel.png") as Texture2D
	if gravel != null:
		cut.texture = gravel
		cut.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		cut.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		cut.texture_scale = Vector2(1.04, 1.04)
	add_child(cut)
	move_child(cut, 7)


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
	# The painted shell and its collision share one footprint; the inset
	# threshold owns a real gap so the player never catches an invisible lip.
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
		art.z_index = 5
		exterior.add_child(art)

	# The carriage door sits within the isometric foot, so its collision is
	# three honest pieces rather than a solid rectangle over the threshold.
	_add_rect_collision(exterior, "DepotFootLeft", Vector2(122, 142), Vector2(-148, -34))
	_add_rect_collision(exterior, "DepotFootRight", Vector2(202, 142), Vector2(108, -34))
	_add_rect_collision(exterior, "DepotDoorLintel", Vector2(94, 45), Vector2(-47, -82.5))
	WorldLayoutContract.tag_solid(
		exterior,
		&"home_base_exterior",
		WorldLayoutContract.rectangle_points(Vector2(418, 142), Vector2(0, -34)),
		true
	)
	exterior.set_meta("door_gap_center_x", -47.0)
	exterior.set_meta("door_gap_width", 94.0)
	exterior.set_meta("entry_state", "intact-enterable")
	exterior.set_meta("player_scale_units", Vector2(418, 142) / WorldLayoutContract.PLAYER_REFERENCE)

	var threshold_shadow := Polygon2D.new()
	threshold_shadow.name = "ThresholdApron"
	threshold_shadow.position = Vector2(-690, 293)
	threshold_shadow.polygon = PackedVector2Array([
		Vector2(-92, -28), Vector2(92, -28), Vector2(126, 58), Vector2(-126, 58),
	])
	threshold_shadow.color = Color(0.09, 0.085, 0.07, 0.84)
	threshold_shadow.z_index = 2
	add_child(threshold_shadow)

	$BaseDoor.scale = Vector2(0.86, 0.86)
	$BaseDoor.position = Vector2(-690, 282)
	$from_base.position = Vector2(-626, 356)


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


func _add_cullbrook_prop_footprints() -> void:
	var paths: Array[NodePath] = [
		^"EnvironmentalSilhouettes/WestDebris",
		^"EnvironmentalSilhouettes/StationDebris",
		^"EnvironmentalSilhouettes/SouthDebris",
		^"EnvironmentalSilhouettes/RoadConeA",
		^"EnvironmentalSilhouettes/RoadConeB",
		^"EnvironmentalSilhouettes/RoadRailA",
		^"EnvironmentalSilhouettes/RoadRailB",
		^"StationSignLandmark",
		^"YardFloodlight",
	]
	for path in paths:
		var sprite := get_node_or_null(path) as Sprite2D
		if sprite != null:
			_add_sprite_footprint(sprite)


func _add_sprite_footprint(sprite: Sprite2D) -> void:
	if sprite.texture == null:
		return
	var body := StaticBody2D.new()
	body.name = "%sFootprint" % sprite.name
	body.position = to_local(sprite.global_position)
	body.rotation = sprite.global_rotation - global_rotation
	body.collision_layer = 1
	body.collision_mask = 0
	var global_scale := sprite.global_transform.get_scale().abs()
	var image := sprite.texture.get_image()
	var used := Rect2i(Vector2i.ZERO, Vector2i(sprite.texture.get_width(), sprite.texture.get_height()))
	if image != null and not image.is_empty():
		used = image.get_used_rect()
	var width := clampf(float(used.size.x) * global_scale.x * 0.72, 12.0, 210.0)
	var depth := clampf(float(used.size.y) * global_scale.y * 0.18, 9.0, 62.0)
	var used_bottom := float(used.position.y + used.size.y) - float(sprite.texture.get_height()) * 0.5
	var center_y := used_bottom * global_scale.y - depth * 0.5
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width, depth)
	var collision := CollisionShape2D.new()
	collision.name = "Footprint"
	collision.position = Vector2(0, center_y)
	collision.shape = shape
	body.add_child(collision)
	add_child(body)
	WorldLayoutContract.tag_solid(
		body,
		&"physical_prop",
		WorldLayoutContract.rectangle_points(shape.size, collision.position)
	)


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
