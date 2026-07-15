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

const ASH_GROUND := Color(0.16, 0.17, 0.155, 1.0)
const ASH_LIGHT := Color(0.22, 0.23, 0.20, 1.0)
const ROAD := Color(0.32, 0.33, 0.30, 1.0)
const ROAD_EDGE := Color(0.27, 0.24, 0.20, 0.68)
const RUST := Color(0.42, 0.25, 0.16, 1.0)
const RUST_DARK := Color(0.24, 0.16, 0.13, 1.0)
const METAL := Color(0.30, 0.33, 0.31, 1.0)
const CYAN := Color(0.28, 0.88, 0.92, 1.0)
const AMBER := Color(0.96, 0.72, 0.28, 1.0)

const TEX_DIRT := "res://assets/processed/decals/dirt_debris.png"
const TEX_GRAVEL := "res://assets/processed/decals/dirt_gravel.png"
const TEX_RUBBLE := "res://assets/processed/decals/gravel_rubble.png"
const TEX_ASPHALT := "res://assets/processed/decals/asphalt_cracked.png"
const TEX_CONCRETE := "res://assets/processed/decals/concrete_broken.png"
const TEX_METAL := "res://assets/processed/decals/metal_floor.png"
const TEX_PLANKS := "res://assets/processed/decals/rubble_planks.png"
const TEX_ASH_SEAMLESS := "res://assets/processed/environment/ash_asphalt_seamless.png"


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
	_add_ground(Vector2(2800, 1700), Color(0.34, 0.36, 0.33, 1.0), TEX_ASH_SEAMLESS)
	_add_ash_band("NorthAsh", Vector2(0, -710), Vector2(2800, 310), Color(0.23, 0.29, 0.28, 1.0), TEX_GRAVEL)
	_add_ash_band("SouthAsh", Vector2(0, 700), Vector2(2800, 300), Color(0.34, 0.28, 0.21, 1.0), TEX_RUBBLE)
	_add_textured_polygon("OldNorthRoad", PackedVector2Array([
		Vector2(-1100, -135), Vector2(-620, -165), Vector2(-180, -90),
		Vector2(260, -145), Vector2(690, -315), Vector2(1100, -365),
		Vector2(1100, -70), Vector2(720, -35), Vector2(300, 100),
		Vector2(-180, 175), Vector2(-650, 120), Vector2(-1100, 145),
	]), TEX_ASPHALT, ROAD, -1, Vector2(0.92, 0.92))
	_add_textured_polygon("RoadShoulder", PackedVector2Array([
		Vector2(-1100, 145), Vector2(-650, 120), Vector2(-180, 175),
		Vector2(300, 100), Vector2(720, -35), Vector2(1100, -70),
		Vector2(1100, 10), Vector2(720, 45), Vector2(310, 180),
		Vector2(-180, 245), Vector2(-660, 190), Vector2(-1100, 220),
	]), TEX_GRAVEL, ROAD_EDGE, -2, Vector2(1.18, 1.18))
	_add_faded_lane_markers("AshmereLane", [
		Vector2(-760, -18), Vector2(-475, -10), Vector2(-185, 22),
		Vector2(110, -20), Vector2(390, -105), Vector2(650, -205),
	], -0.12)
	# Bellwether is a loop rather than a single road: the school yard leads to
	# the terraces, the clinic lane bends through the bus depot, and a narrow
	# service cut reconnects both halves behind Mara's workshop.
	_add_textured_polygon("SchoolApproach", PackedVector2Array([
		Vector2(-1130, -90), Vector2(-930, -120), Vector2(-760, -520),
		Vector2(-560, -500), Vector2(-650, -150), Vector2(-1050, 20),
	]), TEX_GRAVEL, Color(0.29, 0.30, 0.27, 1.0), -1, Vector2(1.08, 1.08))
	_add_textured_polygon("ClinicLoop", PackedVector2Array([
		Vector2(-470, 190), Vector2(-620, 500), Vector2(-420, 670),
		Vector2(280, 620), Vector2(610, 400), Vector2(520, 180),
		Vector2(245, 320), Vector2(-190, 430),
	]), TEX_CONCRETE, Color(0.35, 0.33, 0.28, 1.0), -1, Vector2(0.82, 0.82))
	_add_textured_polygon("WorkshopCutThrough", PackedVector2Array([
		Vector2(500, -510), Vector2(760, -600), Vector2(1100, -500),
		Vector2(1310, -395), Vector2(1270, -245), Vector2(1010, -330),
		Vector2(730, -390), Vector2(520, -330),
	]), TEX_PLANKS, Color(0.31, 0.28, 0.23, 1.0), -1, Vector2(0.78, 0.78))

	_add_obstacle("RuinedTerraceNorth", Vector2(-210, -365), Vector2(520, 180), RUST_DARK)
	_add_obstacle("RuinedTerraceSouth", Vector2(-330, 390), Vector2(360, 150), RUST)
	_add_obstacle("AshmereClinic", Vector2(360, 335), Vector2(330, 190), METAL)
	_add_obstacle("RelayWorkshop", Vector2(670, -430), Vector2(300, 150), RUST_DARK)
	_add_obstacle("CollapsedBus", Vector2(-690, 335), Vector2(250, 92), Color(0.18, 0.15, 0.11, 1.0))
	_add_obstacle("BellwetherSchool", Vector2(-820, -610), Vector2(470, 190), Color(0.30, 0.27, 0.22, 1.0))
	_add_obstacle("SchoolHallEast", Vector2(-470, -540), Vector2(170, 270), Color(0.27, 0.25, 0.22, 1.0))
	_add_obstacle("BusDepotWall", Vector2(-720, 650), Vector2(390, 82), RUST_DARK)
	_add_obstacle("ClinicAnnex", Vector2(690, 480), Vector2(250, 160), METAL)
	_add_ruin_debris("TerraceFall", Vector2(-430, -280), -0.22, Vector2(0.62, 0.52))
	_add_ruin_debris("ClinicFall", Vector2(510, 445), 0.18, Vector2(0.72, 0.56))
	_add_guardrail_run("OldRoadRail", Vector2(-750, 142), 3, Vector2(118, 4), -0.02)
	_add_guardrail_run("WorkshopRail", Vector2(560, -345), 3, Vector2(112, -34), -0.28)
	_add_guardrail_run("SchoolYardRail", Vector2(-1090, -365), 3, Vector2(106, -18), -0.16)
	_add_guardrail_run("BusLoopRail", Vector2(-430, 700), 4, Vector2(108, -4), -0.04)

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
	_add_sprite("ClinicPump", "res://assets/processed/petrol_station_props/petrol_pump.png", Vector2(475, 160), Vector2(0.14, 0.14), 4, Color(0.72, 0.70, 0.61, 0.92))
	_add_sprite("ClinicCone", "res://assets/processed/roadside_props/traffic_cone.png", Vector2(270, 196), Vector2(0.10, 0.10), 4, Color(0.72, 0.62, 0.46, 0.90))
	_add_sprite("SchoolRadio", "res://assets/processed/roadside_props/portable_radio.png", Vector2(-1010, -505), Vector2(0.19, 0.19), 4)
	_add_sprite("SchoolNotice", "res://assets/processed/roadside_props/missing_person_poster.png", Vector2(-915, -505), Vector2(0.17, 0.17), 4)
	_add_sprite("DepotBarrier", "res://assets/processed/petrol_station_props/warning_barrier.png", Vector2(-520, 540), Vector2(0.18, 0.18), 4)
	_add_sprite("ClinicPhone", "res://assets/processed/petrol_station_props/phone_booth.png", Vector2(650, 340), Vector2(0.18, 0.18), 4)
	_add_decal("TerraceRubble", "res://assets/processed/decals/rubble_planks.png", Vector2(-215, -235), Vector2(0.72, 0.72), 1)
	_add_decal("ClinicConcrete", "res://assets/processed/decals/concrete_broken.png", Vector2(350, 210), Vector2(0.70, 0.70), 1)
	_add_decal("SunDirt", "res://assets/processed/decals/dirt_debris.png", Vector2(95, 470), Vector2(0.68, 0.68), 1)

	_add_loot("AshmereBusCache", Vector2(-675, 270), {&"scrap": 2, &"canned_food": 1}, "Search the bus emergency box")
	_add_loot("AshmereTerraceCrate", Vector2(-360, -235), {&"scrap": 2, &"battery": 1}, "Search the terrace crate")
	_add_loot("AshmereClinicLocker", Vector2(515, 265), {&"canned_food": 2, &"battery": 1}, "Search the clinic locker")
	_add_loot("AshmereWorkshopParts", Vector2(740, -325), {&"scrap": 3, &"battery": 1}, "Search Maggie's spare-parts box")
	_add_loot("BellwetherSchoolCupboard", Vector2(-1040, -570), {&"canned_food": 1, &"battery": 1}, "Open the school caretaker's cupboard")
	_add_loot("AshmereClinicPharmacy", Vector2(790, 565), {&"medical_kit": 1, &"canned_food": 1}, "Search the clinic dispensary")
	_add_loot("AshmereBusLostProperty", Vector2(-825, 560), {&"battery": 1, &"scrap": 2}, "Search the bus depot lost-property cage")
	_add_loot("BellwetherWorkshopShortcut", Vector2(1120, -420), {&"scrap": 2, &"battery": 1}, "Open the service-cut tool locker")

	_add_memory_echo("EchoSunLid", &"echo_sun_lid", Vector2(95, 470))
	_add_memory_echo("EchoMaraRepair", &"echo_mara_repair", Vector2(700, -215))
	_add_memory_echo("EchoClinicTriage", &"echo_clinic_triage", Vector2(565, 405))
	_add_memory_echo("EchoBusLedger", &"echo_bus_ledger", Vector2(-760, 525))
	_add_campaign_interactable("ashmere_mara_radio", Vector2(645, -250), "Answer the workshop radio")
	_add_campaign_interactable("bellwether_school_radio", Vector2(-1010, -505), "Call the quarry camp")
	_add_campaign_interactable("ashmere_gate", Vector2(1260, -360), "Unlock the Long Acre road")

	_add_enemy("AshmereRoadHollow", HOLLOW_SCENE, Vector2(-130, -20), &"AshmereRoadHollow")
	_add_enemy("AshmereClinicHollow", HOLLOW_SCENE, Vector2(455, 105), &"AshmereClinicHollow")
	_add_future_enemy("AshmereSunWraith", STATIC_WRAITH_PATH, Vector2(60, 350), &"AshmereSunWraith", Color(0.52, 0.98, 1.0, 0.88))
	_add_enemy("BellwetherSchoolHollow", HOLLOW_SCENE, Vector2(-690, -420), &"BellwetherSchoolHollow")
	_add_enemy("AshmereDepotHollow", HOLLOW_SCENE, Vector2(-440, 560), &"AshmereDepotHollow")
	_add_future_enemy("ClinicCorridorWraith", STATIC_WRAITH_PATH, Vector2(620, 315), &"ClinicCorridorWraith", Color(0.50, 0.92, 0.94, 0.86))

	_add_spawn("from_rustway", Vector2(-1240, 0))
	_add_spawn("from_broadcast", Vector2(1190, -330))
	_add_exit("BackToRustway", Vector2(-1330, 0), "Walk back to Cullbrook Service Station", "res://scenes/maps/test_map.tscn", &"from_base", -PI * 0.5)
	_add_world_bounds(Vector2(2800, 1700))
	_add_ash_drift("AshDriftWest", Vector2(-760, 0), Vector2(1100, 900), Vector2(-13, 7))
	_add_ash_drift("AshDriftEast", Vector2(700, -80), Vector2(1200, 960), Vector2(-10, 6))


# ---------------------------------------------------------------------------
# Chapter III: Broadcast Fields

func _build_broadcast_fields() -> void:
	_add_ground(Vector2(3200, 2000), Color(0.27, 0.34, 0.33, 1.0), TEX_ASH_SEAMLESS)
	_add_ash_band("SignalStormNorth", Vector2(0, -825), Vector2(3200, 350), Color(0.18, 0.29, 0.30, 1.0), TEX_RUBBLE)
	_add_ash_band("IronAshSouth", Vector2(0, 820), Vector2(3200, 340), Color(0.34, 0.26, 0.20, 1.0), TEX_DIRT)

	# Three readable lanes form a triangular relay-restoration route.
	_add_textured_polygon("SouthServiceRoad", PackedVector2Array([
		Vector2(-150, 700), Vector2(150, 700), Vector2(150, 140), Vector2(80, -40),
		Vector2(-80, -40), Vector2(-150, 140),
	]), TEX_ASPHALT, ROAD, -1, Vector2(0.95, 0.95))
	_add_textured_polygon("WestRelayRoad", PackedVector2Array([
		Vector2(-80, 90), Vector2(-760, 40), Vector2(-930, -130), Vector2(-780, -250),
		Vector2(-620, -105), Vector2(80, 40),
	]), TEX_ASPHALT, ROAD, -1, Vector2(0.95, 0.95))
	_add_textured_polygon("EastRelayRoad", PackedVector2Array([
		Vector2(80, 90), Vector2(760, 45), Vector2(930, -130), Vector2(780, -250),
		Vector2(620, -100), Vector2(-80, 40),
	]), TEX_ASPHALT, ROAD, -1, Vector2(0.95, 0.95))
	_add_textured_polygon("CoreApproach", PackedVector2Array([
		Vector2(-125, -20), Vector2(125, -20), Vector2(175, -700), Vector2(-175, -700),
	]), TEX_CONCRETE, Color(0.26, 0.31, 0.30, 1.0), -1, Vector2(0.82, 0.82))
	_add_textured_polygon("RelayHub", PackedVector2Array([
		Vector2(-240, -96), Vector2(-115, -202), Vector2(108, -196), Vector2(238, -88),
		Vector2(236, 116), Vector2(115, 204), Vector2(-118, 202), Vector2(-240, 104),
	]), TEX_METAL, Color(0.34, 0.38, 0.35, 1.0), 0, Vector2(0.76, 0.76))
	_add_textured_polygon("WestCableTrack", PackedVector2Array([
		Vector2(-700, 55), Vector2(-1480, 10), Vector2(-1490, -255), Vector2(-1160, -330),
		Vector2(-930, -185), Vector2(-650, -95),
	]), TEX_GRAVEL, Color(0.25, 0.30, 0.29, 1.0), -1, Vector2(1.12, 1.12))
	_add_textured_polygon("EastAntennaTrack", PackedVector2Array([
		Vector2(700, 55), Vector2(1480, 20), Vector2(1490, -245), Vector2(1180, -325),
		Vector2(930, -180), Vector2(650, -95),
	]), TEX_CONCRETE, Color(0.31, 0.33, 0.30, 1.0), -1, Vector2(0.86, 0.86))
	_add_textured_polygon("SouthGeneratorLoop", PackedVector2Array([
		Vector2(-150, 260), Vector2(-820, 500), Vector2(-1080, 760), Vector2(-850, 900),
		Vector2(0, 690), Vector2(850, 900), Vector2(1080, 760), Vector2(820, 500),
		Vector2(150, 260),
	]), TEX_ASPHALT, Color(0.30, 0.31, 0.28, 1.0), -1, Vector2(0.94, 0.94))
	_add_faded_lane_markers("SouthLane", [Vector2(0, 535), Vector2(0, 390), Vector2(0, 225)], -PI * 0.5)
	_add_faded_lane_markers("WestLane", [Vector2(-210, 38), Vector2(-430, -8), Vector2(-625, -62)], 0.12)
	_add_faded_lane_markers("EastLane", [Vector2(210, 38), Vector2(430, -8), Vector2(625, -62)], -0.12)

	_add_obstacle("WestTransformer", Vector2(-430, -360), Vector2(300, 150), RUST_DARK)
	_add_obstacle("EastTransformer", Vector2(430, -355), Vector2(300, 150), RUST_DARK)
	_add_obstacle("SouthControlShed", Vector2(300, 390), Vector2(340, 170), METAL)
	_add_obstacle("WestFence", Vector2(-700, 280), Vector2(420, 34), RUST)
	_add_obstacle("EastFence", Vector2(700, 285), Vector2(420, 34), RUST)
	_add_obstacle("CoreBulkheadWest", Vector2(-330, -510), Vector2(260, 95), METAL)
	_add_obstacle("CoreBulkheadEast", Vector2(330, -510), Vector2(260, 95), METAL)
	_add_obstacle("WestCableHouse", Vector2(-1210, -365), Vector2(360, 175), RUST_DARK)
	_add_obstacle("WestSpoolBank", Vector2(-1370, 180), Vector2(280, 120), RUST)
	_add_obstacle("EastAntennaBunker", Vector2(1210, -355), Vector2(340, 180), METAL)
	_add_obstacle("EastLaybyBus", Vector2(1320, 300), Vector2(310, 105), RUST_DARK)
	_add_obstacle("SouthGeneratorHall", Vector2(0, 650), Vector2(430, 200), METAL)
	_add_obstacle("RepeaterShelter", Vector2(-1260, 600), Vector2(290, 150), RUST_DARK)
	_add_ruin_debris("WestTransformerFall", Vector2(-480, -255), 0.14, Vector2(0.78, 0.54))
	_add_ruin_debris("EastTransformerFall", Vector2(490, -250), -0.16, Vector2(0.74, 0.56))
	_add_guardrail_run("WestFieldRail", Vector2(-660, 250), 4, Vector2(112, 2), 0.0)
	_add_guardrail_run("EastFieldRail", Vector2(660, 255), 4, Vector2(112, 2), 0.0)
	_add_guardrail_run("CoreBarrierWest", Vector2(-395, -405), 3, Vector2(104, -15), -0.14)
	_add_guardrail_run("CoreBarrierEast", Vector2(395, -405), 3, Vector2(-104, -15), 0.14)
	_add_guardrail_run("WestPocketRail", Vector2(-1500, -80), 3, Vector2(112, -4), -0.04)
	_add_guardrail_run("EastPocketRail", Vector2(1260, 90), 3, Vector2(112, 8), 0.07)
	_add_guardrail_run("SouthGeneratorRail", Vector2(-360, 785), 4, Vector2(112, 0), 0.0)

	_add_relay_landmark("WestRelay", Vector2(-1180, -120), -0.22)
	_add_relay_landmark("EastRelay", Vector2(1180, -115), 0.22)
	_add_relay_landmark("SouthRelay", Vector2(0, 520), 0.0)
	_add_glow("CoreGateGlow", Vector2(0, -845), 170.0, Color(CYAN, 0.13), 1)
	_add_glow("NamesWallGlow", Vector2(-945, 390), 100.0, Color(AMBER, 0.11), 1)

	_add_sprite("WestRadio", "res://assets/processed/roadside_props/portable_radio.png", Vector2(-675, -72), Vector2(0.16, 0.16), 4)
	_add_sprite("EastGuardrail", "res://assets/processed/roadside_props/guardrail.png", Vector2(675, 125), Vector2(0.22, 0.22), 3)
	_add_sprite("SouthWarning", "res://assets/processed/petrol_station_props/warning_barrier.png", Vector2(-145, 335), Vector2(0.20, 0.20), 4)
	_add_sprite("CoreStationSign", "res://assets/processed/petrol_station_props/station_sign_tall.png", Vector2(215, -565), Vector2(0.15, 0.15), 4)
	_add_sprite("NamesPoster", "res://assets/processed/roadside_props/missing_person_poster.png", Vector2(-940, 390), Vector2(0.18, 0.18), 4)
	_add_sprite("EastDebris", "res://assets/processed/roadside_props/debris_pile.png", Vector2(875, 230), Vector2(0.22, 0.22), 3)
	_add_sprite("WestCone", "res://assets/processed/roadside_props/traffic_cone.png", Vector2(-610, 110), Vector2(0.10, 0.10), 4, Color(0.74, 0.60, 0.42, 0.88))
	_add_sprite("EastCone", "res://assets/processed/roadside_props/traffic_cone.png", Vector2(590, 112), Vector2(0.10, 0.10), 4, Color(0.74, 0.60, 0.42, 0.88))
	_add_sprite("WestCableRadio", "res://assets/processed/roadside_props/portable_radio.png", Vector2(-1310, -245), Vector2(0.17, 0.17), 4)
	_add_sprite("EastDriverPhone", "res://assets/processed/petrol_station_props/phone_booth.png", Vector2(1240, 235), Vector2(0.18, 0.18), 4)
	_add_sprite("PublicRepeaterSet", "res://assets/processed/roadside_props/portable_radio.png", Vector2(-1270, 500), Vector2(0.20, 0.20), 4)
	_add_sprite("GeneratorWarning", "res://assets/processed/petrol_station_props/warning_barrier.png", Vector2(-230, 565), Vector2(0.18, 0.18), 4)
	_add_decal("HubMetal", "res://assets/processed/decals/metal_floor.png", Vector2(0, 40), Vector2(0.85, 0.85), 1)
	_add_decal("WestRubble", "res://assets/processed/decals/gravel_rubble.png", Vector2(-790, 5), Vector2(0.76, 0.76), 1)
	_add_decal("EastRubble", "res://assets/processed/decals/rubble_planks.png", Vector2(790, 10), Vector2(0.76, 0.76), 1)
	_add_decal("NamesDirt", "res://assets/processed/decals/dirt_gravel.png", Vector2(-945, 390), Vector2(0.68, 0.68), 1)

	_add_loot("BroadcastWestCache", Vector2(-665, -205), {&"scrap": 3, &"battery": 1}, "Search the west relay cache")
	_add_loot("BroadcastEastCache", Vector2(655, -200), {&"scrap": 2, &"canned_food": 1}, "Search the east relay cache")
	_add_loot("BroadcastSouthLocker", Vector2(245, 300), {&"battery": 1, &"canned_food": 1}, "Search the south control locker")
	_add_loot("BroadcastCoreEmergency", Vector2(-215, -505), {&"scrap": 3, &"canned_food": 1}, "Search the core emergency crate")
	_add_loot("LongAcreCableLocker", Vector2(-1390, -255), {&"scrap": 3, &"battery": 2}, "Open the cable-house locker")
	_add_loot("LongAcreDriverCache", Vector2(1370, 250), {&"canned_food": 1, &"battery": 1}, "Search the stranded driver's cab")
	_add_loot("LongAcreGeneratorKit", Vector2(250, 665), {&"scrap": 2, &"battery": 1}, "Search the generator service case")
	_add_loot("LongAcreRepeaterDonations", Vector2(-1380, 625), {&"canned_food": 2, &"scrap": 1}, "Open the public repeater donation tin")

	_add_campaign_interactable("broadcast_relay_west", Vector2(-1180, -120), "Reset the cable-yard relay")
	_add_campaign_interactable("broadcast_relay_east", Vector2(1180, -115), "Align the roadside relay")
	_add_campaign_interactable("broadcast_relay_south", Vector2(0, 520), "Restart the generator relay")
	_add_campaign_interactable("long_acre_repeater", Vector2(-1270, 500), "Repair the public repeater")
	_add_campaign_interactable("broadcast_core_gate", Vector2(0, -845), "Open the Tollard County Exchange")
	_add_memory_echo("EchoNamesWall", &"echo_names_wall", Vector2(-945, 390))
	_add_memory_echo("EchoRelayWarning", &"echo_relay_warning", Vector2(-1310, -245))
	_add_memory_echo("EchoDriverCall", &"echo_driver_call", Vector2(1240, 235))

	_add_enemy("BroadcastEntryHollow", HOLLOW_SCENE, Vector2(-105, 470), &"BroadcastEntryHollow")
	_add_enemy("BroadcastHubHollow", HOLLOW_SCENE, Vector2(125, -170), &"BroadcastHubHollow")
	_add_future_enemy("WestRelayWraith", STATIC_WRAITH_PATH, Vector2(-1040, -55), &"WestRelayWraith", Color(0.50, 0.96, 1.0, 0.88))
	_add_future_enemy("EastRelayWraith", STATIC_WRAITH_PATH, Vector2(1040, -45), &"EastRelayWraith", Color(0.50, 0.96, 1.0, 0.88))
	_add_future_enemy("SouthRelayWraith", STATIC_WRAITH_PATH, Vector2(-130, 455), &"SouthRelayWraith", Color(0.50, 0.96, 1.0, 0.88))
	_add_enemy("LongAcreCableHollow", HOLLOW_SCENE, Vector2(-1320, 80), &"LongAcreCableHollow")
	_add_enemy("LongAcreLaybyHollow", HOLLOW_SCENE, Vector2(1310, 105), &"LongAcreLaybyHollow")
	_add_enemy("LongAcreGeneratorHollow", HOLLOW_SCENE, Vector2(420, 625), &"LongAcreGeneratorHollow")
	_add_future_enemy("RelayHusk", RELAY_HUSK_PATH, Vector2(0, -650), &"RelayHusk", Color(1.0, 0.72, 0.32, 1.0), Vector2(1.25, 1.25))

	_add_spawn("from_ashmere", Vector2(0, 850))
	_add_spawn("from_core", Vector2(0, -790))
	_add_exit("BackToAshmere", Vector2(0, 940), "Take the Bellwether road", "res://scenes/maps/ashmere_verge.tscn", &"from_broadcast", PI)
	_add_world_bounds(Vector2(3200, 2000))
	_add_ash_drift("SignalAshWest", Vector2(-820, -40), Vector2(1500, 1300), Vector2(-17, 5))
	_add_ash_drift("SignalAshEast", Vector2(820, -40), Vector2(1500, 1300), Vector2(-15, 6))


# ---------------------------------------------------------------------------
# Finale: Choir Core

func _build_choir_core() -> void:
	_add_ground(Vector2(2400, 1800), Color(0.23, 0.30, 0.30, 1.0), TEX_ASH_SEAMLESS)
	_add_ash_band("CoreColdWash", Vector2(0, -610), Vector2(2400, 500), Color(0.17, 0.27, 0.29, 1.0), TEX_METAL)
	_add_textured_polygon("CoreFloor", PackedVector2Array([
		Vector2(-410, 440), Vector2(410, 440), Vector2(600, 180), Vector2(520, -390),
		Vector2(300, -540), Vector2(-300, -540), Vector2(-520, -390), Vector2(-600, 180),
	]), TEX_METAL, Color(0.36, 0.40, 0.37, 1.0), -1, Vector2(0.72, 0.72))
	_add_textured_polygon("ProcessionalLane", PackedVector2Array([
		Vector2(-90, 900), Vector2(90, 900), Vector2(125, -720), Vector2(-125, -720),
	]), TEX_PLANKS, Color(0.34, 0.30, 0.24, 1.0), 0, Vector2(0.72, 0.72))
	_add_textured_polygon("PublicArchiveWing", PackedVector2Array([
		Vector2(-1110, 170), Vector2(-520, 170), Vector2(-420, -440),
		Vector2(-690, -640), Vector2(-1090, -530),
	]), TEX_CONCRETE, Color(0.30, 0.34, 0.32, 1.0), -1, Vector2(0.78, 0.78))
	_add_textured_polygon("OperationsWing", PackedVector2Array([
		Vector2(1110, 170), Vector2(520, 170), Vector2(420, -440),
		Vector2(690, -640), Vector2(1090, -530),
	]), TEX_METAL, Color(0.29, 0.36, 0.35, 1.0), -1, Vector2(0.72, 0.72))
	_add_textured_polygon("ReceptionLoop", PackedVector2Array([
		Vector2(-520, 620), Vector2(-160, 760), Vector2(0, 610), Vector2(160, 760),
		Vector2(520, 620), Vector2(430, 400), Vector2(0, 480), Vector2(-430, 400),
	]), TEX_ASPHALT, Color(0.31, 0.31, 0.28, 1.0), -1, Vector2(0.92, 0.92))
	_add_signal_channel("MemoryCircuitWest", PackedVector2Array([
		Vector2(-510, 125), Vector2(-360, 112), Vector2(-240, 92), Vector2(-116, 88),
	]))
	_add_signal_channel("MemoryCircuitEast", PackedVector2Array([
		Vector2(510, 125), Vector2(360, 112), Vector2(240, 92), Vector2(116, 88),
	]))
	_add_signal_channel("ArchiveFeed", PackedVector2Array([
		Vector2(-920, -270), Vector2(-680, -230), Vector2(-470, -120), Vector2(-116, 88),
	]))
	_add_signal_channel("OperationsFeed", PackedVector2Array([
		Vector2(920, -270), Vector2(680, -230), Vector2(470, -120), Vector2(116, 88),
	]))
	_add_faded_lane_markers("CoreProcession", [Vector2(0, 445), Vector2(0, 295), Vector2(0, 135)], -PI * 0.5, Color(0.58, 0.49, 0.33, 0.24))

	_add_obstacle("CorePylonNW", Vector2(-350, -180), Vector2(130, 250), METAL)
	_add_obstacle("CorePylonNE", Vector2(350, -180), Vector2(130, 250), METAL)
	_add_obstacle("CorePylonSW", Vector2(-400, 250), Vector2(120, 220), RUST_DARK)
	_add_obstacle("CorePylonSE", Vector2(400, 250), Vector2(120, 220), RUST_DARK)
	_add_obstacle("ArchiveBankWest", Vector2(-560, -380), Vector2(200, 130), Color(0.12, 0.18, 0.18, 1.0))
	_add_obstacle("ArchiveBankEast", Vector2(560, -380), Vector2(200, 130), Color(0.12, 0.18, 0.18, 1.0))
	_add_obstacle("TollardArchiveStacksNorth", Vector2(-835, -500), Vector2(420, 115), Color(0.15, 0.20, 0.19, 1.0))
	_add_obstacle("TollardArchiveStacksSouth", Vector2(-870, 30), Vector2(350, 105), Color(0.15, 0.20, 0.19, 1.0))
	_add_obstacle("TollardOperationsDesk", Vector2(805, -440), Vector2(390, 130), METAL)
	_add_obstacle("TollardSwitchBank", Vector2(900, 30), Vector2(330, 120), METAL)
	_add_obstacle("ReceptionBarrierWest", Vector2(-350, 500), Vector2(310, 80), RUST_DARK)
	_add_obstacle("ReceptionBarrierEast", Vector2(350, 500), Vector2(310, 80), RUST_DARK)
	_add_ruin_debris("CoreThresholdFall", Vector2(-245, 405), -0.14, Vector2(0.58, 0.46))
	_add_ruin_debris("CoreArchiveFall", Vector2(510, -465), 0.18, Vector2(0.52, 0.42))

	_add_core_rings(Vector2(0, -420))
	_add_glow("FirstToneGlow", Vector2(0, -330), 165.0, Color(CYAN, 0.16), 3)
	_add_glow("FinalConsoleGlow", Vector2(0, -690), 140.0, Color(AMBER, 0.15), 3)
	_add_sprite("CoreRadio", "res://assets/processed/railhome_props/radio_desk.png", Vector2(0, -695), Vector2(0.25, 0.25), 5)
	_add_sprite("WestConsole", "res://assets/processed/railhome_props/workbench_tools.png", Vector2(-500, -315), Vector2(0.20, 0.20), 4)
	_add_sprite("EastConsole", "res://assets/processed/railhome_props/map_wall.png", Vector2(505, -315), Vector2(0.18, 0.18), 4)
	_add_sprite("CoreWarning", "res://assets/processed/petrol_station_props/warning_barrier.png", Vector2(0, 325), Vector2(0.22, 0.22), 4)
	_add_sprite("CoreLanternWest", "res://assets/processed/railhome_props/lantern.png", Vector2(-165, -370), Vector2(0.11, 0.11), 5, Color(0.78, 0.86, 0.82, 0.88))
	_add_sprite("CoreLanternEast", "res://assets/processed/railhome_props/lantern.png", Vector2(165, -370), Vector2(0.11, 0.11), 5, Color(0.78, 0.86, 0.82, 0.88))
	_add_sprite("ArchiveTapeDesk", "res://assets/processed/railhome_props/radio_desk.png", Vector2(-930, -300), Vector2(0.19, 0.19), 5)
	_add_sprite("OperationsMap", "res://assets/processed/railhome_props/map_wall.png", Vector2(900, -300), Vector2(0.18, 0.18), 5)
	_add_sprite("TollardIntakeBarrier", "res://assets/processed/petrol_station_props/warning_barrier.png", Vector2(0, 610), Vector2(0.20, 0.20), 4)
	_add_decal("CoreMetalA", "res://assets/processed/decals/metal_floor.png", Vector2(-190, 150), Vector2(0.85, 0.85), 1)
	_add_decal("CoreMetalB", "res://assets/processed/decals/metal_floor.png", Vector2(190, -35), Vector2(0.85, 0.85), 1)
	_add_decal("CoreRubble", "res://assets/processed/decals/gravel_rubble.png", Vector2(0, 390), Vector2(0.72, 0.72), 1)

	_add_loot("ChoirWestEmergency", Vector2(-535, 95), {&"canned_food": 2, &"battery": 1}, "Search the west emergency locker")
	_add_loot("ChoirEastEmergency", Vector2(535, 95), {&"canned_food": 1, &"scrap": 3}, "Search the east emergency locker")
	_add_loot("TollardArchiveEvidence", Vector2(-1030, -410), {&"battery": 1, &"scrap": 2}, "Open the county archive evidence drawer")
	_add_loot("TollardOperationsLocker", Vector2(1030, -390), {&"canned_food": 2, &"battery": 1}, "Open the night-shift locker")
	_add_loot("TollardReceptionCache", Vector2(470, 570), {&"scrap": 2, &"canned_food": 1}, "Search the reception emergency box")
	_add_memory_echo("EchoFirstTone", &"echo_first_tone", Vector2(0, -330))
	_add_memory_echo("EchoMaggieFinal", &"echo_maggie_final", Vector2(-930, -300))
	_add_campaign_interactable("choir_final_console", Vector2(0, -695), "Open the Tollard incident record")

	_add_future_enemy("ChoirWestWraith", STATIC_WRAITH_PATH, Vector2(-520, -55), &"ChoirWestWraith", Color(0.48, 0.96, 1.0, 0.88))
	_add_future_enemy("ChoirEastWraith", STATIC_WRAITH_PATH, Vector2(520, -55), &"ChoirEastWraith", Color(0.48, 0.96, 1.0, 0.88))
	_add_enemy("TollardArchiveHollow", HOLLOW_SCENE, Vector2(-720, 180), &"TollardArchiveHollow")
	_add_enemy("TollardOperationsHollow", HOLLOW_SCENE, Vector2(720, 190), &"TollardOperationsHollow")
	_add_future_enemy("TollardRecordsWraith", STATIC_WRAITH_PATH, Vector2(-865, -210), &"TollardRecordsWraith", Color(0.45, 0.88, 0.94, 0.86))
	_add_future_enemy("ChoirWarden", RELAY_HUSK_PATH, Vector2(0, -470), &"ChoirWarden", Color(0.52, 0.94, 1.0, 1.0), Vector2(1.55, 1.55))

	_add_spawn("from_fields", Vector2(0, 750))
	_add_exit("BackToBroadcastFields", Vector2(0, 840), "Return to Long Acre", "res://scenes/maps/broadcast_fields.tscn", &"from_core", PI)
	_add_world_bounds(Vector2(2400, 1800))
	_add_ash_drift("CoreSignalDust", Vector2(0, -80), Vector2(1900, 1450), Vector2(-8, 4))


# ---------------------------------------------------------------------------
# Shared authoring helpers

func _add_ground(size: Vector2, color: Color = ASH_GROUND, texture_path: String = TEX_DIRT) -> void:
	var texture := load(texture_path) as Texture2D
	if texture != null:
		var ground := Sprite2D.new()
		ground.name = "Ground"
		ground.texture = texture
		ground.centered = true
		ground.region_enabled = true
		ground.region_rect = Rect2(Vector2.ZERO, size)
		ground.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		ground.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		ground.modulate = color.lightened(0.66)
		ground.z_index = -6
		add_child(ground)
	else:
		_add_rect_visual("Ground", Vector2.ZERO, size, color, -6)
	# A near-black apron keeps the playable space grounded instead of ending in
	# a bright, game-board-like rectangle at the camera edge.
	var apron := _add_rect_visual("GroundApron", Vector2.ZERO, size + Vector2(54, 54), Color(0.055, 0.065, 0.06, 1.0), -7)
	move_child(apron, 0)


func _add_ash_band(
		node_name: String,
		center: Vector2,
		size: Vector2,
		color: Color,
		texture_path: String = TEX_GRAVEL) -> void:
	var half := size * 0.5
	var stagger := minf(72.0, size.y * 0.22)
	var points := PackedVector2Array([
		Vector2(-half.x, -half.y + stagger), Vector2(-half.x * 0.62, -half.y),
		Vector2(-half.x * 0.16, -half.y + stagger * 0.35), Vector2(half.x * 0.31, -half.y - stagger * 0.12),
		Vector2(half.x, -half.y + stagger * 0.6), Vector2(half.x, half.y - stagger * 0.25),
		Vector2(half.x * 0.52, half.y), Vector2(half.x * 0.05, half.y - stagger * 0.4),
		Vector2(-half.x * 0.46, half.y + stagger * 0.18), Vector2(-half.x, half.y - stagger * 0.5),
	])
	var band := _add_polygon(node_name, points, color, -5)
	_texture_polygon_once(band, texture_path, points)
	band.position = center


func _add_polygon(node_name: String, points: PackedVector2Array, color: Color, z: int) -> Polygon2D:
	var polygon := Polygon2D.new()
	polygon.name = node_name
	polygon.polygon = points
	polygon.color = color
	polygon.z_index = z
	add_child(polygon)
	return polygon


func _add_textured_polygon(
		node_name: String,
		points: PackedVector2Array,
		texture_path: String,
		color: Color,
		z: int,
		texture_scale_value: Vector2 = Vector2.ONE) -> Polygon2D:
	var polygon := _add_polygon(node_name, points, color, z)
	var texture := load(texture_path) as Texture2D
	if texture != null:
		polygon.texture = texture
		polygon.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		polygon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		polygon.texture_scale = texture_scale_value
	return polygon


func _texture_polygon_once(polygon: Polygon2D, texture_path: String, points: PackedVector2Array) -> void:
	var texture := load(texture_path) as Texture2D
	if texture == null or points.is_empty():
		return
	var minimum := points[0]
	var maximum := points[0]
	for point in points:
		minimum.x = minf(minimum.x, point.x)
		minimum.y = minf(minimum.y, point.y)
		maximum.x = maxf(maximum.x, point.x)
		maximum.y = maxf(maximum.y, point.y)
	var span := maximum - minimum
	span.x = maxf(span.x, 1.0)
	span.y = maxf(span.y, 1.0)
	var texture_size := texture.get_size()
	var mapped_uv := PackedVector2Array()
	for point in points:
		var normalized := (point - minimum) / span
		mapped_uv.append(normalized * texture_size)
	polygon.texture = texture
	polygon.uv = mapped_uv
	polygon.texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
	polygon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS


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
	var shadow := Polygon2D.new()
	shadow.name = "FootprintShadow"
	shadow.position = Vector2(13, 17)
	shadow.polygon = PackedVector2Array([
		Vector2(-visual_half.x * 0.94, -visual_half.y * 0.72),
		Vector2(-visual_half.x * 0.50, -visual_half.y),
		Vector2(visual_half.x * 0.82, -visual_half.y * 0.90),
		Vector2(visual_half.x, -visual_half.y * 0.26),
		Vector2(visual_half.x * 0.88, visual_half.y),
		Vector2(-visual_half.x * 0.78, visual_half.y * 0.88),
		Vector2(-visual_half.x, visual_half.y * 0.22),
	])
	shadow.color = Color(0.025, 0.03, 0.028, 0.56)
	shadow.z_index = 1
	body.add_child(shadow)
	var visual := Polygon2D.new()
	visual.name = "Visual"
	visual.polygon = PackedVector2Array([
		Vector2(-visual_half.x * 0.94, -visual_half.y * 0.72),
		Vector2(-visual_half.x * 0.50, -visual_half.y),
		Vector2(visual_half.x * 0.82, -visual_half.y * 0.90),
		Vector2(visual_half.x, -visual_half.y * 0.26),
		Vector2(visual_half.x * 0.88, visual_half.y),
		Vector2(-visual_half.x * 0.78, visual_half.y * 0.88),
		Vector2(-visual_half.x, visual_half.y * 0.22),
	])
	visual.color = Color(0.72, 0.69, 0.59, 1.0).lerp(color.lightened(0.55), 0.32)
	visual.texture = load(TEX_CONCRETE) as Texture2D
	visual.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	visual.texture_scale = Vector2(0.74, 0.74)
	visual.z_index = 2
	body.add_child(visual)
	var ruin_texture := load("res://assets/processed/roadside_props/debris_pile.png") as Texture2D
	if ruin_texture != null and size.x >= 260.0 and size.x / maxf(size.y, 1.0) >= 1.35:
		var ruin_crown := Sprite2D.new()
		ruin_crown.name = "RuinCrown"
		ruin_crown.texture = ruin_texture
		ruin_crown.position = Vector2(-size.x * 0.12, -size.y * 0.10)
		ruin_crown.rotation = -0.07
		var crown_scale := maxf(0.36, minf(size.x / 430.0, size.y / 330.0) * 1.18)
		ruin_crown.scale = Vector2(crown_scale, crown_scale)
		ruin_crown.modulate = Color(0.72, 0.70, 0.62, 0.82)
		ruin_crown.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		ruin_crown.z_index = 3
		body.add_child(ruin_crown)
	var roof := Polygon2D.new()
	roof.name = "RustEdge"
	roof.polygon = PackedVector2Array([
		Vector2(-visual_half.x * 0.50, -visual_half.y), Vector2(visual_half.x * 0.82, -visual_half.y * 0.90),
		Vector2(visual_half.x * 0.73, -visual_half.y * 0.76), Vector2(-visual_half.x * 0.46, -visual_half.y * 0.84),
	])
	roof.color = Color(0.35, 0.27, 0.21, 0.30)
	roof.z_index = 3
	body.add_child(roof)
	# Match collision to the authored ruin silhouette. The previous rectangle
	# left invisible corners that caught the player several pixels outside the
	# visible wall.
	var shape := ConvexPolygonShape2D.new()
	shape.points = visual.polygon
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
	for i in 24:
		var angle := TAU * float(i) / 24.0
		var wobble := 0.88 + sin(float(i * 5)) * 0.045
		points.append(Vector2(cos(angle) * radius, sin(angle) * radius * 0.62) * wobble)
	var grounded_color := color
	grounded_color.a *= 0.38
	var glow := _add_polygon(node_name, points, grounded_color, z)
	glow.position = center
	return glow


func _add_sprite(
		node_name: String,
		path: String,
		position_value: Vector2,
		scale_value: Vector2,
		z: int,
		tint: Color = Color(0.84, 0.82, 0.72, 0.94)) -> void:
	var texture := load(path) as Texture2D
	if texture == null:
		return
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = texture
	sprite.position = position_value
	sprite.scale = scale_value
	sprite.modulate = tint
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
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
	sprite.modulate = Color(0.72, 0.74, 0.67, 0.42)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.z_index = z
	add_child(sprite)


func _add_faded_lane_markers(
		prefix: String,
		centers: Array[Vector2],
		rotation_value: float,
		color: Color = Color(0.60, 0.52, 0.34, 0.20)) -> void:
	for index in centers.size():
		var marker := Polygon2D.new()
		marker.name = "%s%d" % [prefix, index + 1]
		marker.position = centers[index]
		marker.rotation = rotation_value
		marker.polygon = PackedVector2Array([
			Vector2(-28, -2.5), Vector2(28, -2.5), Vector2(28, 2.5), Vector2(-28, 2.5),
		])
		marker.color = color
		marker.z_index = 1
		add_child(marker)


func _add_signal_channel(node_name: String, points: PackedVector2Array) -> void:
	var shadow := Line2D.new()
	shadow.name = node_name + "Bed"
	shadow.points = points
	shadow.width = 10.0
	shadow.default_color = Color(0.025, 0.04, 0.04, 0.78)
	shadow.z_index = 1
	add_child(shadow)
	var channel := Line2D.new()
	channel.name = node_name
	channel.points = points
	channel.width = 2.25
	channel.default_color = Color(CYAN, 0.24)
	channel.z_index = 2
	add_child(channel)


func _add_ruin_debris(
		node_name: String,
		center: Vector2,
		rotation_value: float,
		scale_value: Vector2) -> void:
	var rubble := load("res://assets/processed/roadside_props/debris_pile.png") as Texture2D
	if rubble == null:
		return
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = rubble
	sprite.position = center
	sprite.rotation = rotation_value
	sprite.scale = scale_value
	sprite.modulate = Color(0.63, 0.62, 0.54, 0.88)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.z_index = 3
	add_child(sprite)


func _add_guardrail_run(
		prefix: String,
		start: Vector2,
		count: int,
		step: Vector2,
		rotation_value: float) -> void:
	for index in count:
		_add_guardrail_piece("%s%d" % [prefix, index + 1], start + step * float(index), rotation_value)


func _add_guardrail_piece(node_name: String, center: Vector2, rotation_value: float) -> void:
	var texture := load("res://assets/processed/roadside_props/guardrail.png") as Texture2D
	if texture == null:
		return
	var body := StaticBody2D.new()
	body.name = node_name
	body.position = center
	body.rotation = rotation_value
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	var piece := Sprite2D.new()
	piece.name = "Visual"
	piece.texture = texture
	piece.scale = Vector2(0.14, 0.14)
	piece.modulate = Color(0.66, 0.66, 0.59, 0.84)
	piece.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	piece.z_index = 3
	body.add_child(piece)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(104, 14)
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	collision.shape = shape
	body.add_child(collision)


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
	exit.scale = Vector2(0.68, 0.68)
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
