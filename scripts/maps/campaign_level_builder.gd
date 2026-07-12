class_name CampaignLevelBuilder
extends Node2D
## Runtime authoring for the compact campaign's three new maps.
##
## Keeping the repeated ash-road language here makes the zones consistent while
## each small .tscn remains an independently loadable campaign destination. The
## current vertical-slice scenes and systems are intentionally untouched.

@export_enum("ashmere_verge", "broadcast_fields", "choir_core")
var campaign_id: String = "ashmere_verge"

const LOOT_SCENE := preload("res://scenes/world/loot_container.tscn")
const ECHO_SCENE := preload("res://scenes/world/memory_echo.tscn")
const EXIT_SCENE := preload("res://scenes/world/scene_exit.tscn")
const HOLLOW_SCENE := preload("res://scenes/enemies/enemy_hollow.tscn")

const CAMPAIGN_INTERACTABLE_PATH := "res://scenes/world/campaign_interactable.tscn"
const STATIC_WRAITH_PATH := "res://scenes/enemies/enemy_static_wraith.tscn"
const RELAY_HUSK_PATH := "res://scenes/enemies/enemy_relay_husk.tscn"

const ASH_GROUND := Color(0.045, 0.065, 0.068, 1.0)
const ASH_LIGHT := Color(0.105, 0.13, 0.13, 1.0)
const ROAD := Color(0.075, 0.085, 0.083, 1.0)
const ROAD_EDGE := Color(0.17, 0.14, 0.105, 1.0)
const RUST := Color(0.29, 0.16, 0.105, 1.0)
const RUST_DARK := Color(0.14, 0.09, 0.075, 1.0)
const METAL := Color(0.16, 0.19, 0.19, 1.0)
const CYAN := Color(0.28, 0.88, 0.92, 1.0)
const AMBER := Color(0.96, 0.72, 0.28, 1.0)


func _ready() -> void:
	add_to_group("campaign_levels")
	match campaign_id:
		"ashmere_verge":
			_build_ashmere_verge()
		"broadcast_fields":
			_build_broadcast_fields()
		"choir_core":
			_build_choir_core()
		_:
			push_warning("Unknown campaign level id: %s" % campaign_id)


# ---------------------------------------------------------------------------
# Chapter II: Ashmere Verge

func _build_ashmere_verge() -> void:
	_add_ground(Vector2(2200, 1200))
	_add_ash_band("NorthAsh", Vector2(0, -470), Vector2(2200, 260), Color(0.08, 0.12, 0.13, 1.0))
	_add_ash_band("SouthAsh", Vector2(0, 480), Vector2(2200, 240), Color(0.12, 0.095, 0.075, 1.0))
	_add_polygon("OldNorthRoad", PackedVector2Array([
		Vector2(-1100, -135), Vector2(-620, -165), Vector2(-180, -90),
		Vector2(260, -145), Vector2(690, -315), Vector2(1100, -365),
		Vector2(1100, -70), Vector2(720, -35), Vector2(300, 100),
		Vector2(-180, 175), Vector2(-650, 120), Vector2(-1100, 145),
	]), ROAD, 0)
	_add_polygon("RoadShoulder", PackedVector2Array([
		Vector2(-1100, 145), Vector2(-650, 120), Vector2(-180, 175),
		Vector2(300, 100), Vector2(720, -35), Vector2(1100, -70),
		Vector2(1100, 10), Vector2(720, 45), Vector2(310, 180),
		Vector2(-180, 245), Vector2(-660, 190), Vector2(-1100, 220),
	]), ROAD_EDGE, -1)
	_add_route_arrow("AshmereRoadArrowA", Vector2(-720, -15), 0.0)
	_add_route_arrow("AshmereRoadArrowB", Vector2(-40, 30), -0.14)
	_add_route_arrow("AshmereRoadArrowC", Vector2(560, -110), -0.30)

	_add_obstacle("RuinedTerraceNorth", Vector2(-210, -365), Vector2(520, 180), RUST_DARK)
	_add_obstacle("RuinedTerraceSouth", Vector2(-330, 390), Vector2(360, 150), RUST)
	_add_obstacle("AshmereClinic", Vector2(360, 335), Vector2(330, 190), METAL)
	_add_obstacle("RelayWorkshop", Vector2(670, -430), Vector2(300, 150), RUST_DARK)
	_add_obstacle("CollapsedBus", Vector2(-690, 335), Vector2(250, 92), Color(0.18, 0.15, 0.11, 1.0))

	_add_glow("EntryLanternGlow", Vector2(-935, 0), 115.0, Color(AMBER, 0.13), 1)
	_add_glow("MaraRadioGlow", Vector2(650, -250), 145.0, Color(CYAN, 0.12), 1)
	_add_glow("SunMemoryGlow", Vector2(95, 470), 110.0, Color(AMBER, 0.10), 1)

	_add_sprite("BrokenCar", "res://assets/processed/roadside_props/broken_car.png", Vector2(-555, -45), Vector2(0.26, 0.26), 3)
	_add_sprite("MissingElliePoster", "res://assets/processed/roadside_props/missing_person_poster.png", Vector2(-30, 255), Vector2(0.18, 0.18), 4)
	_add_sprite("RoadSign", "res://assets/processed/roadside_props/road_sign.png", Vector2(-820, -135), Vector2(0.17, 0.17), 4)
	_add_sprite("AshmerePhone", "res://assets/processed/petrol_station_props/phone_booth.png", Vector2(405, 165), Vector2(0.22, 0.22), 4)
	_add_sprite("WorkshopRadio", "res://assets/processed/roadside_props/portable_radio.png", Vector2(645, -250), Vector2(0.20, 0.20), 4)
	_add_sprite("ClinicBarrier", "res://assets/processed/petrol_station_props/warning_barrier.png", Vector2(220, 235), Vector2(0.18, 0.18), 4)
	_add_sprite("SouthDebris", "res://assets/processed/roadside_props/debris_pile.png", Vector2(-90, 420), Vector2(0.20, 0.20), 3)
	_add_sprite("WorkshopSign", "res://assets/processed/petrol_station_props/station_sign_tall.png", Vector2(815, -255), Vector2(0.16, 0.16), 4)
	_add_decal("TerraceRubble", "res://assets/processed/decals/rubble_planks.png", Vector2(-215, -235), Vector2(0.72, 0.72), 1)
	_add_decal("ClinicConcrete", "res://assets/processed/decals/concrete_broken.png", Vector2(350, 210), Vector2(0.70, 0.70), 1)
	_add_decal("SunDirt", "res://assets/processed/decals/dirt_debris.png", Vector2(95, 470), Vector2(0.68, 0.68), 1)

	_add_loot("AshmereBusCache", Vector2(-675, 270), {&"scrap": 2, &"canned_food": 1}, "Search the bus emergency box")
	_add_loot("AshmereTerraceCrate", Vector2(-360, -235), {&"scrap": 2, &"battery": 1}, "Search the terrace crate")
	_add_loot("AshmereClinicLocker", Vector2(515, 265), {&"canned_food": 2, &"battery": 1}, "Search the clinic locker")
	_add_loot("AshmereWorkshopParts", Vector2(740, -325), {&"scrap": 3, &"battery": 1}, "Search Mara's spare-parts box")

	_add_memory_echo("EchoSunLid", &"echo_sun_lid", Vector2(95, 470))
	_add_memory_echo("EchoMaraRepair", &"echo_mara_repair", Vector2(700, -215))
	_add_campaign_interactable("ashmere_mara_radio", Vector2(645, -250), "Tune Mara's field radio")
	_add_campaign_interactable("ashmere_gate", Vector2(925, -300), "Open the north service gate")

	_add_enemy("AshmereRoadHollow", HOLLOW_SCENE, Vector2(-130, -20), &"AshmereRoadHollow")
	_add_enemy("AshmereClinicHollow", HOLLOW_SCENE, Vector2(455, 105), &"AshmereClinicHollow")
	_add_future_enemy("AshmereSunWraith", STATIC_WRAITH_PATH, Vector2(60, 350), &"AshmereSunWraith", Color(0.52, 0.98, 1.0, 0.88))

	_add_spawn("from_rustway", Vector2(-930, 0))
	_add_spawn("from_broadcast", Vector2(875, -260))
	_add_exit("BackToRustway", Vector2(-1030, 0), "Return to the Rustway", "res://scenes/maps/test_map.tscn", &"from_base", -PI * 0.5)
	_add_world_bounds(Vector2(2200, 1200))
	_add_ash_drift("AshDriftWest", Vector2(-620, 0), Vector2(760, 620), Vector2(-13, 7))
	_add_ash_drift("AshDriftEast", Vector2(500, -80), Vector2(920, 650), Vector2(-10, 6))


# ---------------------------------------------------------------------------
# Chapter III: Broadcast Fields

func _build_broadcast_fields() -> void:
	_add_ground(Vector2(2400, 1400))
	_add_ash_band("SignalStormNorth", Vector2(0, -560), Vector2(2400, 280), Color(0.055, 0.12, 0.135, 1.0))
	_add_ash_band("IronAshSouth", Vector2(0, 570), Vector2(2400, 260), Color(0.13, 0.085, 0.07, 1.0))

	# Three readable lanes form a triangular relay-restoration route.
	_add_polygon("SouthServiceRoad", PackedVector2Array([
		Vector2(-150, 700), Vector2(150, 700), Vector2(150, 140), Vector2(80, -40),
		Vector2(-80, -40), Vector2(-150, 140),
	]), ROAD, 0)
	_add_polygon("WestRelayRoad", PackedVector2Array([
		Vector2(-80, 90), Vector2(-760, 40), Vector2(-930, -130), Vector2(-780, -250),
		Vector2(-620, -105), Vector2(80, 40),
	]), ROAD, 0)
	_add_polygon("EastRelayRoad", PackedVector2Array([
		Vector2(80, 90), Vector2(760, 45), Vector2(930, -130), Vector2(780, -250),
		Vector2(620, -100), Vector2(-80, 40),
	]), ROAD, 0)
	_add_polygon("CoreApproach", PackedVector2Array([
		Vector2(-125, -20), Vector2(125, -20), Vector2(175, -700), Vector2(-175, -700),
	]), Color(0.07, 0.10, 0.105, 1.0), 0)

	_add_obstacle("WestTransformer", Vector2(-430, -360), Vector2(300, 150), RUST_DARK)
	_add_obstacle("EastTransformer", Vector2(430, -355), Vector2(300, 150), RUST_DARK)
	_add_obstacle("SouthControlShed", Vector2(300, 390), Vector2(340, 170), METAL)
	_add_obstacle("WestFence", Vector2(-700, 280), Vector2(420, 34), RUST)
	_add_obstacle("EastFence", Vector2(700, 285), Vector2(420, 34), RUST)
	_add_obstacle("CoreBulkheadWest", Vector2(-330, -510), Vector2(260, 95), METAL)
	_add_obstacle("CoreBulkheadEast", Vector2(330, -510), Vector2(260, 95), METAL)

	_add_relay_landmark("WestRelay", Vector2(-790, -120), -0.22)
	_add_relay_landmark("EastRelay", Vector2(790, -115), 0.22)
	_add_relay_landmark("SouthRelay", Vector2(0, 315), 0.0)
	_add_glow("CoreGateGlow", Vector2(0, -585), 170.0, Color(CYAN, 0.13), 1)
	_add_glow("NamesWallGlow", Vector2(-945, 390), 100.0, Color(AMBER, 0.11), 1)

	_add_sprite("WestRadio", "res://assets/processed/roadside_props/portable_radio.png", Vector2(-675, -72), Vector2(0.16, 0.16), 4)
	_add_sprite("EastGuardrail", "res://assets/processed/roadside_props/guardrail.png", Vector2(675, 125), Vector2(0.22, 0.22), 3)
	_add_sprite("SouthWarning", "res://assets/processed/petrol_station_props/warning_barrier.png", Vector2(-145, 335), Vector2(0.20, 0.20), 4)
	_add_sprite("CoreStationSign", "res://assets/processed/petrol_station_props/station_sign_tall.png", Vector2(215, -565), Vector2(0.15, 0.15), 4)
	_add_sprite("NamesPoster", "res://assets/processed/roadside_props/missing_person_poster.png", Vector2(-940, 390), Vector2(0.18, 0.18), 4)
	_add_sprite("EastDebris", "res://assets/processed/roadside_props/debris_pile.png", Vector2(875, 230), Vector2(0.22, 0.22), 3)
	_add_decal("HubMetal", "res://assets/processed/decals/metal_floor.png", Vector2(0, 40), Vector2(0.85, 0.85), 1)
	_add_decal("WestRubble", "res://assets/processed/decals/gravel_rubble.png", Vector2(-790, 5), Vector2(0.76, 0.76), 1)
	_add_decal("EastRubble", "res://assets/processed/decals/rubble_planks.png", Vector2(790, 10), Vector2(0.76, 0.76), 1)
	_add_decal("NamesDirt", "res://assets/processed/decals/dirt_gravel.png", Vector2(-945, 390), Vector2(0.68, 0.68), 1)

	_add_loot("BroadcastWestCache", Vector2(-665, -205), {&"scrap": 3, &"battery": 1}, "Search the west relay cache")
	_add_loot("BroadcastEastCache", Vector2(655, -200), {&"scrap": 2, &"canned_food": 1}, "Search the east relay cache")
	_add_loot("BroadcastSouthLocker", Vector2(245, 300), {&"battery": 1, &"canned_food": 1}, "Search the south control locker")
	_add_loot("BroadcastCoreEmergency", Vector2(-215, -505), {&"scrap": 3, &"canned_food": 1}, "Search the core emergency crate")

	_add_campaign_interactable("broadcast_relay_west", Vector2(-790, -120), "Restore the west relay")
	_add_campaign_interactable("broadcast_relay_east", Vector2(790, -115), "Restore the east relay")
	_add_campaign_interactable("broadcast_relay_south", Vector2(0, 315), "Restore the south relay")
	_add_campaign_interactable("broadcast_core_gate", Vector2(0, -585), "Open the Choir Core bulkhead")
	_add_memory_echo("EchoNamesWall", &"echo_names_wall", Vector2(-945, 390))

	_add_enemy("BroadcastEntryHollow", HOLLOW_SCENE, Vector2(-105, 470), &"BroadcastEntryHollow")
	_add_enemy("BroadcastHubHollow", HOLLOW_SCENE, Vector2(125, -170), &"BroadcastHubHollow")
	_add_future_enemy("WestRelayWraith", STATIC_WRAITH_PATH, Vector2(-650, -70), &"WestRelayWraith", Color(0.50, 0.96, 1.0, 0.88))
	_add_future_enemy("EastRelayWraith", STATIC_WRAITH_PATH, Vector2(650, -65), &"EastRelayWraith", Color(0.50, 0.96, 1.0, 0.88))
	_add_future_enemy("SouthRelayWraith", STATIC_WRAITH_PATH, Vector2(-80, 265), &"SouthRelayWraith", Color(0.50, 0.96, 1.0, 0.88))
	_add_future_enemy("RelayHusk", RELAY_HUSK_PATH, Vector2(0, -410), &"RelayHusk", Color(1.0, 0.72, 0.32, 1.0), Vector2(1.25, 1.25))

	_add_spawn("from_ashmere", Vector2(0, 575))
	_add_spawn("from_core", Vector2(0, -510))
	_add_exit("BackToAshmere", Vector2(0, 655), "Return to Ashmere Verge", "res://scenes/maps/ashmere_verge.tscn", &"from_broadcast", PI)
	_add_world_bounds(Vector2(2400, 1400))
	_add_ash_drift("SignalAshWest", Vector2(-620, -40), Vector2(1000, 900), Vector2(-17, 5))
	_add_ash_drift("SignalAshEast", Vector2(620, -40), Vector2(1000, 900), Vector2(-15, 6))


# ---------------------------------------------------------------------------
# Finale: Choir Core

func _build_choir_core() -> void:
	_add_ground(Vector2(1600, 1200), Color(0.035, 0.052, 0.056, 1.0))
	_add_ash_band("CoreColdWash", Vector2(0, -360), Vector2(1600, 450), Color(0.04, 0.105, 0.12, 1.0))
	_add_polygon("CoreFloor", PackedVector2Array([
		Vector2(-410, 440), Vector2(410, 440), Vector2(600, 180), Vector2(520, -390),
		Vector2(300, -540), Vector2(-300, -540), Vector2(-520, -390), Vector2(-600, 180),
	]), Color(0.105, 0.13, 0.13, 1.0), 0)
	_add_polygon("ProcessionalLane", PackedVector2Array([
		Vector2(-90, 600), Vector2(90, 600), Vector2(125, -470), Vector2(-125, -470),
	]), ROAD, 1)
	_add_polygon("MemoryCircuitWest", PackedVector2Array([
		Vector2(-500, 105), Vector2(-115, 65), Vector2(-115, 120), Vector2(-500, 165),
	]), Color(CYAN, 0.20), 2)
	_add_polygon("MemoryCircuitEast", PackedVector2Array([
		Vector2(500, 105), Vector2(115, 65), Vector2(115, 120), Vector2(500, 165),
	]), Color(CYAN, 0.20), 2)

	_add_obstacle("CorePylonNW", Vector2(-350, -180), Vector2(130, 250), METAL)
	_add_obstacle("CorePylonNE", Vector2(350, -180), Vector2(130, 250), METAL)
	_add_obstacle("CorePylonSW", Vector2(-400, 250), Vector2(120, 220), RUST_DARK)
	_add_obstacle("CorePylonSE", Vector2(400, 250), Vector2(120, 220), RUST_DARK)
	_add_obstacle("ArchiveBankWest", Vector2(-560, -380), Vector2(200, 130), Color(0.12, 0.18, 0.18, 1.0))
	_add_obstacle("ArchiveBankEast", Vector2(560, -380), Vector2(200, 130), Color(0.12, 0.18, 0.18, 1.0))

	_add_core_rings(Vector2(0, -250))
	_add_glow("FirstToneGlow", Vector2(0, -170), 165.0, Color(CYAN, 0.16), 3)
	_add_glow("FinalConsoleGlow", Vector2(0, -430), 140.0, Color(AMBER, 0.15), 3)
	_add_sprite("CoreRadio", "res://assets/processed/railhome_props/radio_desk.png", Vector2(0, -435), Vector2(0.25, 0.25), 5)
	_add_sprite("WestConsole", "res://assets/processed/railhome_props/workbench_tools.png", Vector2(-500, -315), Vector2(0.20, 0.20), 4)
	_add_sprite("EastConsole", "res://assets/processed/railhome_props/map_wall.png", Vector2(505, -315), Vector2(0.18, 0.18), 4)
	_add_sprite("CoreWarning", "res://assets/processed/petrol_station_props/warning_barrier.png", Vector2(0, 325), Vector2(0.22, 0.22), 4)
	_add_decal("CoreMetalA", "res://assets/processed/decals/metal_floor.png", Vector2(-190, 150), Vector2(0.85, 0.85), 1)
	_add_decal("CoreMetalB", "res://assets/processed/decals/metal_floor.png", Vector2(190, -35), Vector2(0.85, 0.85), 1)
	_add_decal("CoreRubble", "res://assets/processed/decals/gravel_rubble.png", Vector2(0, 390), Vector2(0.72, 0.72), 1)

	_add_loot("ChoirWestEmergency", Vector2(-535, 95), {&"canned_food": 2, &"battery": 1}, "Search the west emergency locker")
	_add_loot("ChoirEastEmergency", Vector2(535, 95), {&"canned_food": 1, &"scrap": 3}, "Search the east emergency locker")
	_add_memory_echo("EchoFirstTone", &"echo_first_tone", Vector2(0, -170))
	_add_campaign_interactable("choir_final_console", Vector2(0, -435), "Choose what the Choir will remember")

	_add_future_enemy("ChoirWestWraith", STATIC_WRAITH_PATH, Vector2(-230, 25), &"ChoirWestWraith", Color(0.48, 0.96, 1.0, 0.88))
	_add_future_enemy("ChoirEastWraith", STATIC_WRAITH_PATH, Vector2(230, 25), &"ChoirEastWraith", Color(0.48, 0.96, 1.0, 0.88))
	_add_future_enemy("ChoirWarden", RELAY_HUSK_PATH, Vector2(0, -285), &"ChoirWarden", Color(0.52, 0.94, 1.0, 1.0), Vector2(1.55, 1.55))

	_add_spawn("from_fields", Vector2(0, 490))
	_add_exit("BackToBroadcastFields", Vector2(0, 555), "Leave the Choir Core", "res://scenes/maps/broadcast_fields.tscn", &"from_core", PI)
	_add_world_bounds(Vector2(1600, 1200))
	_add_ash_drift("CoreSignalDust", Vector2(0, -60), Vector2(1100, 850), Vector2(-8, 4))


# ---------------------------------------------------------------------------
# Shared authoring helpers

func _add_ground(size: Vector2, color: Color = ASH_GROUND) -> void:
	_add_rect_visual("Ground", Vector2.ZERO, size, color, -5)


func _add_ash_band(node_name: String, center: Vector2, size: Vector2, color: Color) -> void:
	_add_rect_visual(node_name, center, size, color, -4)


func _add_polygon(node_name: String, points: PackedVector2Array, color: Color, z: int) -> Polygon2D:
	var polygon := Polygon2D.new()
	polygon.name = node_name
	polygon.polygon = points
	polygon.color = color
	polygon.z_index = z
	add_child(polygon)
	return polygon


func _add_rect_visual(node_name: String, center: Vector2, size: Vector2, color: Color, z: int) -> Polygon2D:
	var half := size * 0.5
	var polygon := _add_polygon(node_name, PackedVector2Array([
		Vector2(-half.x, -half.y), Vector2(half.x, -half.y),
		Vector2(half.x, half.y), Vector2(-half.x, half.y),
	]), color, z)
	polygon.position = center
	return polygon


func _add_obstacle(node_name: String, center: Vector2, size: Vector2, color: Color) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.name = node_name
	body.position = center
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	var visual_half := size * 0.5
	var visual := Polygon2D.new()
	visual.name = "Visual"
	visual.polygon = PackedVector2Array([
		Vector2(-visual_half.x, -visual_half.y), Vector2(visual_half.x, -visual_half.y),
		Vector2(visual_half.x, visual_half.y), Vector2(-visual_half.x, visual_half.y),
	])
	visual.color = color
	visual.z_index = 2
	body.add_child(visual)
	var roof := Polygon2D.new()
	roof.name = "RustEdge"
	roof.polygon = PackedVector2Array([
		Vector2(-visual_half.x, -visual_half.y), Vector2(visual_half.x, -visual_half.y),
		Vector2(visual_half.x - 12.0, -visual_half.y + 12.0), Vector2(-visual_half.x + 12.0, -visual_half.y + 12.0),
	])
	roof.color = Color(0.54, 0.29, 0.14, 0.72)
	roof.z_index = 3
	body.add_child(roof)
	var shape := RectangleShape2D.new()
	shape.size = size
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	collision.shape = shape
	body.add_child(collision)
	return body


func _add_world_bounds(size: Vector2) -> void:
	var margin := 38.0
	_add_invisible_wall("NorthBoundary", Vector2(0, -size.y * 0.5 - margin), Vector2(size.x + 160.0, 90.0))
	_add_invisible_wall("SouthBoundary", Vector2(0, size.y * 0.5 + margin), Vector2(size.x + 160.0, 90.0))
	_add_invisible_wall("WestBoundary", Vector2(-size.x * 0.5 - margin, 0), Vector2(90.0, size.y + 160.0))
	_add_invisible_wall("EastBoundary", Vector2(size.x * 0.5 + margin, 0), Vector2(90.0, size.y + 160.0))


func _add_invisible_wall(node_name: String, center: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.name = node_name
	body.position = center
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := RectangleShape2D.new()
	shape.size = size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	body.add_child(collision)
	add_child(body)


func _add_glow(node_name: String, center: Vector2, radius: float, color: Color, z: int) -> Polygon2D:
	var points := PackedVector2Array()
	for i in 20:
		var angle := TAU * float(i) / 20.0
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	var glow := _add_polygon(node_name, points, color, z)
	glow.position = center
	return glow


func _add_route_arrow(node_name: String, center: Vector2, rotation_value: float) -> void:
	var arrow := _add_polygon(node_name, PackedVector2Array([
		Vector2(-28, -8), Vector2(8, -8), Vector2(8, -20),
		Vector2(38, 0), Vector2(8, 20), Vector2(8, 8), Vector2(-28, 8),
	]), Color(AMBER, 0.62), 2)
	arrow.position = center
	arrow.rotation = rotation_value


func _add_sprite(node_name: String, path: String, position_value: Vector2, scale_value: Vector2, z: int) -> void:
	var texture := load(path) as Texture2D
	if texture == null:
		return
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = texture
	sprite.position = position_value
	sprite.scale = scale_value
	sprite.z_index = z
	add_child(sprite)


func _add_decal(node_name: String, path: String, position_value: Vector2, scale_value: Vector2, z: int) -> void:
	var texture := load(path) as Texture2D
	if texture == null:
		return
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = texture
	sprite.position = position_value
	sprite.scale = scale_value
	sprite.modulate = Color(1, 1, 1, 0.62)
	sprite.z_index = z
	add_child(sprite)


func _add_loot(node_name: String, position_value: Vector2, loot: Dictionary, prompt_text: String) -> void:
	var container := LOOT_SCENE.instantiate()
	container.name = node_name
	container.position = position_value
	container.set("persistent_id", StringName(node_name))
	container.set("loot", loot)
	container.set("prompt", prompt_text)
	add_child(container)


func _add_memory_echo(node_name: String, echo_id: StringName, position_value: Vector2) -> void:
	var data_path := "res://resources/echoes/%s.tres" % String(echo_id)
	var data := load(data_path)
	if data == null:
		push_warning("Campaign echo resource missing: %s" % data_path)
		return
	var echo := ECHO_SCENE.instantiate()
	echo.name = node_name
	echo.position = position_value
	echo.set("echo_data", data)
	echo.add_to_group("objective_targets")
	add_child(echo)


func _add_campaign_interactable(node_name: String, position_value: Vector2, prompt_text: String) -> void:
	var node: Node2D
	if ResourceLoader.exists(CAMPAIGN_INTERACTABLE_PATH):
		var packed := load(CAMPAIGN_INTERACTABLE_PATH) as PackedScene
		node = packed.instantiate() as Node2D if packed != null else null
	else:
		node = null
	if node == null:
		node = _campaign_interactable_fallback(node_name)
	node.name = node_name
	node.position = position_value
	_set_property_if_present(node, &"story_id", StringName(node_name))
	_set_property_if_present(node, &"prompt", prompt_text)
	node.set_meta("story_id", StringName(node_name))
	node.set_meta("prompt", prompt_text)
	node.add_to_group("objective_targets")
	add_child(node)


func _campaign_interactable_fallback(node_name: String) -> Area2D:
	# Editor-safe stand-in until the shared campaign_interactable scene lands.
	var area := Area2D.new()
	area.name = node_name
	area.collision_layer = 4
	area.collision_mask = 0
	area.monitoring = false
	var visual := Polygon2D.new()
	visual.name = "FallbackVisual"
	visual.polygon = PackedVector2Array([
		Vector2(0, -24), Vector2(18, -8), Vector2(18, 8),
		Vector2(0, 24), Vector2(-18, 8), Vector2(-18, -8),
	])
	visual.color = Color(CYAN, 0.82)
	area.add_child(visual)
	var shape := CircleShape2D.new()
	shape.radius = 34.0
	var collision := CollisionShape2D.new()
	collision.shape = shape
	area.add_child(collision)
	return area


func _add_enemy(node_name: String, scene: PackedScene, position_value: Vector2, persistent_id: StringName) -> void:
	var enemy := scene.instantiate() as Node2D
	if enemy == null:
		return
	enemy.name = node_name
	enemy.position = position_value
	_set_property_if_present(enemy, &"persistent_id", persistent_id)
	add_child(enemy)


func _add_future_enemy(
		node_name: String,
		path: String,
		position_value: Vector2,
		persistent_id: StringName,
		fallback_modulate: Color,
		scale_value: Vector2 = Vector2.ONE) -> void:
	var scene: PackedScene = null
	if ResourceLoader.exists(path):
		scene = load(path) as PackedScene
	var using_fallback := scene == null
	if scene == null:
		scene = HOLLOW_SCENE
	var enemy := scene.instantiate() as Node2D
	if enemy == null:
		return
	enemy.name = node_name
	enemy.position = position_value
	enemy.scale = scale_value
	_set_property_if_present(enemy, &"persistent_id", persistent_id)
	if using_fallback:
		enemy.modulate = fallback_modulate
		enemy.set_meta("future_enemy_scene", path)
	add_child(enemy)


func _add_spawn(node_name: String, position_value: Vector2) -> void:
	var marker := Marker2D.new()
	marker.name = node_name
	marker.position = position_value
	marker.add_to_group("spawn_points")
	add_child(marker)


func _add_exit(
		node_name: String,
		position_value: Vector2,
		prompt_text: String,
		target_path: String,
		target_spawn: StringName,
		rotation_value: float) -> void:
	var exit := EXIT_SCENE.instantiate() as Node2D
	if exit == null:
		return
	exit.name = node_name
	exit.position = position_value
	exit.rotation = rotation_value
	exit.set("prompt", prompt_text)
	exit.set("target_scene_path", target_path)
	exit.set("target_spawn", target_spawn)
	exit.add_to_group("objective_targets")
	add_child(exit)


func _add_ash_drift(node_name: String, position_value: Vector2, area_value: Vector2, drift_value: Vector2) -> void:
	var drift_script := load("res://scripts/world/ash_drift.gd") as Script
	if drift_script == null:
		return
	var ash := Node2D.new()
	ash.name = node_name
	ash.position = position_value
	ash.set_script(drift_script)
	ash.set("particle_count", 58)
	ash.set("area", area_value)
	ash.set("drift", drift_value)
	add_child(ash)


func _add_relay_landmark(node_name: String, center: Vector2, lean: float) -> void:
	var relay := Node2D.new()
	relay.name = node_name
	relay.position = center
	relay.rotation = lean
	add_child(relay)
	var pool := _make_local_polygon("SignalPool", PackedVector2Array([
		Vector2(0, -54), Vector2(50, -18), Vector2(42, 36),
		Vector2(0, 58), Vector2(-42, 36), Vector2(-50, -18),
	]), Color(CYAN, 0.13), 1)
	relay.add_child(pool)
	var mast := _make_local_polygon("Mast", PackedVector2Array([
		Vector2(-8, 42), Vector2(8, 42), Vector2(18, -84), Vector2(2, -90),
	]), Color(0.35, 0.25, 0.18, 1.0), 3)
	relay.add_child(mast)
	var dish := _make_local_polygon("Dish", PackedVector2Array([
		Vector2(-34, -72), Vector2(28, -93), Vector2(18, -48), Vector2(-18, -44),
	]), Color(0.24, 0.32, 0.32, 1.0), 4)
	relay.add_child(dish)
	var spark := _make_local_polygon("SignalSpark", PackedVector2Array([
		Vector2(20, -105), Vector2(28, -88), Vector2(43, -82),
		Vector2(29, -74), Vector2(25, -55), Vector2(16, -75), Vector2(2, -82), Vector2(16, -90),
	]), Color(CYAN, 0.86), 5)
	relay.add_child(spark)


func _add_core_rings(center: Vector2) -> void:
	for index in 3:
		var radius := 105.0 + float(index) * 72.0
		var points := PackedVector2Array()
		for i in 32:
			var angle := TAU * float(i) / 32.0
			var wobble := 1.0 + sin(float(i * 3 + index)) * 0.035
			points.append(Vector2(cos(angle), sin(angle)) * radius * wobble)
		var ring := Line2D.new()
		ring.name = "ChoirRing%d" % (index + 1)
		ring.position = center
		ring.points = points
		ring.closed = true
		ring.width = 3.0 - float(index) * 0.5
		ring.default_color = Color(CYAN, 0.42 - float(index) * 0.08)
		ring.z_index = 2
		add_child(ring)


func _make_local_polygon(node_name: String, points: PackedVector2Array, color: Color, z: int) -> Polygon2D:
	var polygon := Polygon2D.new()
	polygon.name = node_name
	polygon.polygon = points
	polygon.color = color
	polygon.z_index = z
	return polygon


func _set_property_if_present(object: Object, property_name: StringName, value: Variant) -> void:
	for property_data in object.get_property_list():
		if StringName(property_data.get("name", "")) == property_name:
			object.set(property_name, value)
			return
