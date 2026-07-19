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
const BuildingCatalog = preload("res://scripts/world/building_catalog.gd")
const BUILDING_DOOR_SCENE := preload("res://scenes/world/building_door.tscn")
const HOLLOW_SCENE := preload("res://scenes/enemies/enemy_hollow.tscn")
const IMOGEN_SCENE := preload("res://scenes/npcs/imogen_bell.tscn")
const RAFI_SCENE := preload("res://scenes/npcs/rafi_sayeed.tscn")
const QUEST_DEVICE_SCENE := preload("res://scenes/world/quest_device.tscn")
const DEFENSE_ANCHOR_SCENE := preload("res://scenes/world/signal_defense_anchor.tscn")
const CIRCUIT_SWITCH_SCENE := preload("res://scenes/world/circuit_switch.tscn")
const SIGNAL_LEECH_SCENE := preload("res://scenes/enemies/enemy_signal_leech.tscn")
const MIMIC_STALKER_SCENE := preload("res://scenes/enemies/enemy_mimic_stalker.tscn")
const WORLD_NPC_POPULATION_SCENE := preload("res://scenes/npcs/world_npc_population.tscn")
const ROUTE_MISSION_STATION_SCENE := preload("res://scenes/world/route_mission_station.tscn")
const HOLLOW_DECISION_SCENE := preload("res://scenes/world/hollow_decision_site.tscn")
const ROUTE_FINALE_SCENE := preload("res://scenes/world/route_finale_controller.tscn")
const ROUTE_SALVAGE_RESERVE_SCENE := preload("res://scenes/world/route_salvage_reserve.tscn")

const CAMPAIGN_INTERACTABLE_PATH := "res://scenes/world/campaign_interactable.tscn"
const STATIC_WRAITH_PATH := "res://scenes/enemies/enemy_static_wraith.tscn"
const RELAY_HUSK_PATH := "res://scenes/enemies/enemy_relay_husk.tscn"

const ASH_GROUND := Color(0.16, 0.17, 0.155, 1.0)
const ASH_LIGHT := Color(0.22, 0.23, 0.20, 1.0)
const ROAD := Color(0.28, 0.285, 0.265, 1.0)
const ROAD_EDGE := Color(0.20, 0.185, 0.155, 0.78)
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
const PROP_DOORWAY := "res://assets/processed/railhome_props/base_doorway.png"
const PROP_COUNTER := "res://assets/processed/petrol_station_props/station_counter.png"
const PROP_WORKBENCH := "res://assets/processed/railhome_props/workbench_tools.png"
const PROP_RADIO_DESK := "res://assets/processed/railhome_props/radio_desk.png"
const PROP_MAP_WALL := "res://assets/processed/railhome_props/map_wall.png"
const PROP_BROKEN_CAR := "res://assets/processed/roadside_props/broken_car.png"
const PROP_GUARDRAIL := "res://assets/processed/roadside_props/guardrail.png"
const PROP_BARRIER := "res://assets/processed/petrol_station_props/warning_barrier.png"
const PROP_STATION_SIGN := "res://assets/processed/petrol_station_props/station_sign_tall.png"
const PROP_LANTERN := "res://assets/processed/railhome_props/lantern.png"
const PROP_MAGGIE_BODY := "res://assets/generated/npcs/maggie_cutting_body.png"
const LANDMARK_BELLWETHER := "res://assets/processed/environment_landmarks_v2/bellwether_civic_ruin.png"
const LANDMARK_LONG_ACRE := "res://assets/processed/environment_landmarks_v2/long_acre_relay_station.png"
const LANDMARK_TOLLARD := "res://assets/processed/environment_landmarks_v2/tollard_exchange_ruin.png"


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
	WorldLayoutContract.apply(self, StringName(campaign_id), false)
	_add_world_npc_population()
	_add_route_aftermath_dressing()


func _add_world_npc_population() -> void:
	var population := WORLD_NPC_POPULATION_SCENE.instantiate() as WorldNPCPopulation
	if population == null:
		return
	population.name = "WorldNPCPopulation"
	population.region_id = campaign_id
	add_child(population)


func _add_route_aftermath_dressing() -> void:
	if not WorldState.has_flag(&"route_aftermath_active"):
		return
	var states := CampaignSystem.get_active_world_states()
	if states.is_empty():
		return
	var positions: Array = Array({
		"ashmere_verge": [Vector2(650, 330), Vector2(-930, -430), Vector2(790, -330), Vector2(-720, 470), Vector2(1110, -340)],
		"broadcast_fields": [Vector2(-1130, -70), Vector2(1080, -70), Vector2(-100, 480), Vector2(-1220, 530), Vector2(1060, 610)],
		"choir_core": [Vector2(-510, -270), Vector2(510, -270), Vector2(0, -390), Vector2(-840, -280), Vector2(840, -280)],
	}.get(campaign_id, []))
	if positions.is_empty():
		return
	var layer := Node2D.new()
	layer.name = "RouteAftermath"
	layer.add_to_group("route_aftermath_visuals")
	add_child(layer)
	for index in range(states.size()):
		var state_id: StringName = states[index]
		var icon := Sprite2D.new()
		icon.name = String(state_id).to_pascal_case()
		icon.texture = load(_aftermath_icon_path(String(state_id))) as Texture2D
		icon.position = positions[index % positions.size()]
		icon.scale = Vector2(0.11, 0.11)
		icon.modulate = _aftermath_tint(String(state_id))
		icon.z_index = 5
		icon.set_meta("world_state", state_id)
		layer.add_child(icon)
	layer.set_meta("route_id", CampaignSystem.get_active_route_id())
	layer.set_meta("states_rendered", states.size())


func _aftermath_icon_path(state_id: String) -> String:
	var lower := state_id.to_lower()
	if "radio" in lower or "warning" in lower or "speaker" in lower or "voice" in lower:
		return "res://assets/processed/roadside_props/portable_radio.png"
	if "record" in lower or "archive" in lower or "source" in lower or "memorial" in lower or "name" in lower:
		return PROP_MAP_WALL
	if "clinic" in lower or "patient" in lower or "medical" in lower or "treatment" in lower:
		return PROP_LANTERN
	if "power" in lower or "relay" in lower or "battery" in lower or "fuse" in lower:
		return PROP_WORKBENCH
	return PROP_BARRIER


func _aftermath_tint(state_id: String) -> Color:
	var lower := state_id.to_lower()
	if "dark" in lower or "quiet" in lower or "dead" in lower or "blank" in lower:
		return Color(0.56, 0.62, 0.61, 0.78)
	if "warning" in lower or "weather" in lower or "memorial" in lower:
		return Color(0.95, 0.68, 0.28, 0.92)
	return Color(0.48, 0.88, 0.82, 0.92)


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
	]), TEX_GRAVEL, Color(0.48, 0.48, 0.42, 1.0), -1, Vector2(1.08, 1.08))
	_add_textured_polygon("ClinicLoop", PackedVector2Array([
		Vector2(-470, 190), Vector2(-620, 500), Vector2(-420, 670),
		Vector2(280, 620), Vector2(610, 400), Vector2(520, 180),
		Vector2(245, 320), Vector2(-190, 430),
	]), TEX_CONCRETE, Color(0.52, 0.49, 0.41, 1.0), -1, Vector2(0.82, 0.82))
	_add_textured_polygon("WorkshopCutThrough", PackedVector2Array([
		Vector2(500, -510), Vector2(760, -600), Vector2(1100, -500),
		Vector2(1310, -395), Vector2(1270, -245), Vector2(1010, -330),
		Vector2(730, -390), Vector2(520, -330),
	]), TEX_PLANKS, Color(0.47, 0.42, 0.34, 1.0), -1, Vector2(0.78, 0.78))
	_add_landmark_threshold("SchoolGate", Vector2(-900, -280), -1.38, Color(0.72, 0.56, 0.34, 1.0))
	_add_landmark_threshold("ClinicGate", Vector2(80, 250), -0.18, Color(0.62, 0.75, 0.68, 1.0))
	_add_landmark_threshold("WorkshopGate", Vector2(610, -285), -0.30, Color(0.76, 0.50, 0.30, 1.0))

	_add_obstacle("RuinedTerraceNorth", Vector2(-210, -365), Vector2(520, 180), RUST_DARK)
	_add_obstacle("RuinedTerraceSouth", Vector2(-330, 390), Vector2(360, 150), RUST)
	_add_obstacle("AshmereClinic", Vector2(360, 335), Vector2(330, 190), METAL)
	_add_obstacle("RelayWorkshop", Vector2(670, -430), Vector2(300, 150), RUST_DARK)
	_add_obstacle("CollapsedBus", Vector2(-690, 335), Vector2(250, 92), Color(0.18, 0.15, 0.11, 1.0))
	_add_obstacle("BellwetherSchool", Vector2(-820, -610), Vector2(470, 190), Color(0.30, 0.27, 0.22, 1.0))
	_add_obstacle("SchoolHallEast", Vector2(-470, -540), Vector2(170, 270), Color(0.27, 0.25, 0.22, 1.0))
	_add_obstacle("BusDepotWall", Vector2(-720, 650), Vector2(390, 82), RUST_DARK)
	_add_obstacle("ClinicAnnex", Vector2(690, 480), Vector2(250, 160), METAL)
	# The chapel shell is deliberately sealed and broken open at the roof. It
	# reads differently from the intact, lit thresholds around the route loop.
	_add_obstacle("BellwetherChapelShell", Vector2(1110, 570), Vector2(300, 138), RUST_DARK)
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
	_add_sprite("ClinicBarrier", "res://assets/processed/petrol_station_props/warning_barrier.png", Vector2(220, 235), Vector2(0.18, 0.18), 4)
	_add_sprite("SouthDebris", "res://assets/processed/roadside_props/debris_pile.png", Vector2(-90, 420), Vector2(0.20, 0.20), 3)
	_add_sprite("WorkshopSign", "res://assets/processed/petrol_station_props/station_sign_tall.png", Vector2(815, -255), Vector2(0.16, 0.16), 4)
	_add_sprite("ClinicPump", "res://assets/processed/petrol_station_props/petrol_pump.png", Vector2(475, 160), Vector2(0.14, 0.14), 4, Color(0.72, 0.70, 0.61, 0.92))
	_add_sprite("ClinicCone", "res://assets/processed/roadside_props/traffic_cone.png", Vector2(270, 196), Vector2(0.10, 0.10), 4, Color(0.72, 0.62, 0.46, 0.90))
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
	_add_campaign_interactable("narrative_anchor_commitment", Vector2(825, -420), "Read Maggie's four work cards")
	_add_campaign_interactable("narrative_strategy_commitment", Vector2(1150, -450), "Review the relay strategy card")
	_add_authored_scene(ROUTE_SALVAGE_RESERVE_SCENE, "RouteSalvageReserve", Vector2(935, -330))
	_add_campaign_interactable("ashmere_gate", Vector2(1260, -360), "Unlock the Long Acre road")
	_add_route_mission_station("ClinicAshmereWorkCard", Vector2(805, 360), 0, "clinic")
	_add_route_mission_station("RadioAshmereWorkCard", Vector2(-920, -545), 0, "radio")
	_add_route_mission_station("WitnessAshmereWorkCard", Vector2(-1085, -315), 0, "witness")
	_add_route_mission_station("CopyAshmereWorkCard", Vector2(760, -165), 0, "copy")
	# The clinic-to-workshop rescue follows the physical loop the player has
	# already learned: meet Imogen in the annex, reroute the ambulance junction,
	# then escort her across the road to Maggie's cellar.
	_add_authored_scene(IMOGEN_SCENE, "ImogenBell", Vector2(725, 420))
	_add_authored_scene(QUEST_DEVICE_SCENE, "ClinicPowerJunction", Vector2(265, 510), {
		&"story_id": &"clinic_power_junction",
		&"prompt": "Reroute the clinic junction",
		&"accent": Color(0.96, 0.62, 0.28, 1.0),
	})
	_add_authored_scene(QUEST_DEVICE_SCENE, "ImogenWorkshopSafe", Vector2(930, -405), {
		&"story_id": &"imogen_workshop_safe",
		&"prompt": "Open Maggie's workshop cellar",
		&"accent": Color(0.38, 0.88, 0.82, 1.0),
	})

	_add_enemy("AshmereRoadHollow", HOLLOW_SCENE, Vector2(-130, -20), &"AshmereRoadHollow")
	_add_enemy("AshmereClinicHollow", HOLLOW_SCENE, Vector2(455, 105), &"AshmereClinicHollow")
	_add_future_enemy("AshmereSunWraith", STATIC_WRAITH_PATH, Vector2(60, 350), &"AshmereSunWraith", Color(0.52, 0.98, 1.0, 0.88))
	_add_enemy("BellwetherSchoolHollow", HOLLOW_SCENE, Vector2(-690, -420), &"BellwetherSchoolHollow")
	_add_enemy("AshmereDepotHollow", HOLLOW_SCENE, Vector2(-440, 560), &"AshmereDepotHollow")
	_add_future_enemy("ClinicCorridorWraith", STATIC_WRAITH_PATH, Vector2(620, 315), &"ClinicCorridorWraith", Color(0.50, 0.92, 0.94, 0.86))
	_add_enemy("BellwetherSignalLeech", SIGNAL_LEECH_SCENE, Vector2(-845, -355), &"BellwetherSignalLeech")
	_add_enemy("WorkshopMimicStalker", MIMIC_STALKER_SCENE, Vector2(990, -220), &"WorkshopMimicStalker")

	_add_spawn("from_rustway", Vector2(-1240, 0))
	_add_spawn("from_broadcast", Vector2(1190, -330))
	_add_exit("BackToRustway", Vector2(-1330, 0), "Walk back to Cullbrook Service Station", "res://scenes/maps/test_map.tscn", &"from_base", -PI * 0.5)
	_add_world_bounds(Vector2(2800, 1700))
	_add_ash_drift("AshDriftWest", Vector2(-760, 0), Vector2(1100, 900), Vector2(-13, 7))
	_add_ash_drift("AshDriftEast", Vector2(700, -80), Vector2(1200, 960), Vector2(-10, 6))
	_add_ash_drift("ClinicAnnexAshPocket", Vector2(885, 605), Vector2(280, 210), Vector2(-18, 8), 8.0)


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
	]), TEX_CONCRETE, Color(0.46, 0.50, 0.47, 1.0), -1, Vector2(0.82, 0.82))
	_add_textured_polygon("RelayHub", PackedVector2Array([
		Vector2(-240, -96), Vector2(-115, -202), Vector2(108, -196), Vector2(238, -88),
		Vector2(236, 116), Vector2(115, 204), Vector2(-118, 202), Vector2(-240, 104),
	]), TEX_METAL, Color(0.52, 0.55, 0.49, 1.0), 0, Vector2(0.76, 0.76))
	_add_textured_polygon("WestCableTrack", PackedVector2Array([
		Vector2(-700, 55), Vector2(-1480, 10), Vector2(-1490, -255), Vector2(-1160, -330),
		Vector2(-930, -185), Vector2(-650, -95),
	]), TEX_GRAVEL, Color(0.44, 0.48, 0.44, 1.0), -1, Vector2(1.12, 1.12))
	_add_textured_polygon("EastAntennaTrack", PackedVector2Array([
		Vector2(700, 55), Vector2(1480, 20), Vector2(1490, -245), Vector2(1180, -325),
		Vector2(930, -180), Vector2(650, -95),
	]), TEX_CONCRETE, Color(0.48, 0.49, 0.44, 1.0), -1, Vector2(0.86, 0.86))
	_add_textured_polygon("SouthGeneratorLoop", PackedVector2Array([
		Vector2(-150, 260), Vector2(-820, 500), Vector2(-1080, 760), Vector2(-850, 900),
		Vector2(0, 690), Vector2(850, 900), Vector2(1080, 760), Vector2(820, 500),
		Vector2(150, 260),
	]), TEX_ASPHALT, Color(0.50, 0.49, 0.43, 1.0), -1, Vector2(0.94, 0.94))
	_add_faded_lane_markers("SouthLane", [Vector2(0, 535), Vector2(0, 390), Vector2(0, 225)], -PI * 0.5)
	_add_faded_lane_markers("WestLane", [Vector2(-210, 38), Vector2(-430, -8), Vector2(-625, -62)], 0.12)
	_add_faded_lane_markers("EastLane", [Vector2(210, 38), Vector2(430, -8), Vector2(625, -62)], -0.12)
	_add_landmark_threshold("WestCableGate", Vector2(-760, -85), 0.10, Color(0.45, 0.72, 0.72, 1.0))
	_add_landmark_threshold("EastAntennaGate", Vector2(760, -80), -0.10, Color(0.55, 0.69, 0.66, 1.0))
	_add_landmark_threshold("GeneratorGate", Vector2(0, 330), 0.0, Color(0.78, 0.56, 0.30, 1.0))

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
	_add_obstacle("WrenfieldPumpHouseCollapse", Vector2(1330, 650), Vector2(285, 125), RUST_DARK)
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
	_add_loot("LongAcreDriverCache", Vector2(1370, 250), {&"canned_food": 1, &"battery": 1}, "Search Gwen's blue-tagged coach cache", {
		&"service_bonus_flag": &"npc_service_doyle_passages",
		&"service_bonus": {&"canned_food": 1, &"battery": 1},
		&"service_bonus_claim_flag": &"npc_service_doyle_cache_claimed",
	})
	_add_loot("LongAcreGeneratorKit", Vector2(250, 665), {&"scrap": 2, &"battery": 1}, "Search the generator service case")
	_add_loot("LongAcreRepeaterDonations", Vector2(-1380, 625), {&"canned_food": 2, &"scrap": 1}, "Open the public repeater donation tin")
	# The return footprints and the drainage ditch lead off the relay loop into a
	# quiet pocket. Water, ballast and a broken barrier frame Maggie's body and
	# recorder before the Tollard gate, where the reveal can still change play.
	_add_textured_polygon("FloodedCutting", PackedVector2Array([
		Vector2(760, 485), Vector2(1000, 420), Vector2(1390, 520),
		Vector2(1470, 790), Vector2(1180, 900), Vector2(820, 810),
	]), TEX_GRAVEL, Color(0.29, 0.39, 0.39, 1.0), -1, Vector2(0.78, 0.78))
	_add_textured_polygon("CuttingWater", PackedVector2Array([
		Vector2(930, 570), Vector2(1370, 600), Vector2(1390, 745),
		Vector2(1160, 800), Vector2(900, 720),
	]), TEX_METAL, Color(0.19, 0.38, 0.40, 0.78), 0, Vector2(0.62, 0.62))
	_add_sprite("CuttingBarrier", PROP_BARRIER, Vector2(840, 520), Vector2(0.22, 0.22), 4, Color(0.68, 0.61, 0.48, 0.88))
	_add_sprite("MaggieBody", PROP_MAGGIE_BODY, Vector2(1170, 650), Vector2(0.12, 0.12), 5, Color(0.80, 0.82, 0.79, 0.96))
	_add_decal("CuttingBallast", TEX_RUBBLE, Vector2(1080, 735), Vector2(0.74, 0.74), 1)
	_add_glow("CuttingCarrierLeak", Vector2(1180, 650), 118.0, Color(0.30, 0.82, 0.84, 0.11), 2)

	_add_campaign_interactable("broadcast_relay_west", Vector2(-1180, -120), "Reset the cable-yard relay")
	_add_campaign_interactable("broadcast_relay_east", Vector2(1180, -115), "Align the roadside relay")
	_add_campaign_interactable("broadcast_relay_south", Vector2(0, 520), "Restart the generator relay")
	_add_campaign_interactable("long_acre_repeater", Vector2(-1270, 500), "Repair the public repeater")
	_add_authored_scene(ROUTE_SALVAGE_RESERVE_SCENE, "WrenfieldRouteSalvageReserve", Vector2(-1135, 470))
	_add_campaign_interactable("broadcast_core_gate", Vector2(0, -845), "Open the Tollard County Exchange")
	_add_campaign_interactable("maggie_cutting_recorder", Vector2(1225, 650), "Check Maggie's body and recorder")
	_add_memory_echo("EchoNamesWall", &"echo_names_wall", Vector2(-945, 390))
	_add_memory_echo("EchoRelayWarning", &"echo_relay_warning", Vector2(-1310, -245))
	_add_memory_echo("EchoDriverCall", &"echo_driver_call", Vector2(1240, 235))
	_add_memory_echo("EchoMaggieFinal", &"echo_maggie_final", Vector2(1150, 650))
	_add_authored_scene(HOLLOW_DECISION_SCENE, "RecoverableHollow", Vector2(955, 610))
	_add_route_mission_station("ClinicWrenfieldWorkCard", Vector2(1020, -15), 1, "clinic")
	_add_route_mission_station("RadioWrenfieldWorkCard", Vector2(-1225, 580), 1, "radio")
	_add_route_mission_station("WitnessWrenfieldWorkCard", Vector2(-1370, -300), 1, "witness")
	_add_route_mission_station("CopyWrenfieldWorkCard", Vector2(1320, 775), 1, "copy")
	# Wrenfield's three relays now ask for three different kinds of field work,
	# each tied to a visually distinct route pocket rather than three identical
	# cabinets standing in open ground.
	_add_authored_scene(QUEST_DEVICE_SCENE, "RoadTraceWest", Vector2(-1450, 115), {
		&"story_id": &"road_trace_west",
		&"prompt": "Verify the cable-yard road card",
		&"accent": Color(0.42, 0.84, 0.86, 1.0),
	})
	_add_authored_scene(QUEST_DEVICE_SCENE, "RoadTraceEast", Vector2(1435, -205), {
		&"story_id": &"road_trace_east",
		&"prompt": "Verify the roadside bunker log",
		&"accent": Color(0.42, 0.84, 0.86, 1.0),
	})
	_add_authored_scene(QUEST_DEVICE_SCENE, "RoadTraceSouth", Vector2(610, 760), {
		&"story_id": &"road_trace_south",
		&"prompt": "Verify the generator route card",
		&"accent": Color(0.42, 0.84, 0.86, 1.0),
	})
	_add_authored_scene(DEFENSE_ANCHOR_SCENE, "EastRelayDefense", Vector2(1080, -25), {
		&"story_id": &"broadcast_defense_anchor",
		&"prompt": "Hold the east clinic carrier",
	})
	_add_authored_scene(CIRCUIT_SWITCH_SCENE, "SouthFeedSwitch", Vector2(-70, 805), {
		&"circuit_id": &"south_line", &"switch_id": &"feed", &"required_on": true,
	})
	_add_authored_scene(CIRCUIT_SWITCH_SCENE, "SouthGroundSwitch", Vector2(70, 690), {
		&"circuit_id": &"south_line", &"switch_id": &"ground", &"required_on": false,
	})
	_add_authored_scene(CIRCUIT_SWITCH_SCENE, "SouthCarrierSwitch", Vector2(-70, 575), {
		&"circuit_id": &"south_line", &"switch_id": &"carrier", &"required_on": true,
	})
	_add_authored_scene(RAFI_SCENE, "RafiFieldContact", Vector2(-1160, 565))

	_add_enemy("BroadcastEntryHollow", HOLLOW_SCENE, Vector2(-105, 470), &"BroadcastEntryHollow")
	_add_enemy("BroadcastHubHollow", HOLLOW_SCENE, Vector2(125, -170), &"BroadcastHubHollow")
	_add_future_enemy("WestRelayWraith", STATIC_WRAITH_PATH, Vector2(-1040, -55), &"WestRelayWraith", Color(0.50, 0.96, 1.0, 0.88))
	_add_future_enemy("EastRelayWraith", STATIC_WRAITH_PATH, Vector2(1040, -45), &"EastRelayWraith", Color(0.50, 0.96, 1.0, 0.88))
	_add_future_enemy("SouthRelayWraith", STATIC_WRAITH_PATH, Vector2(-130, 455), &"SouthRelayWraith", Color(0.50, 0.96, 1.0, 0.88))
	_add_enemy("LongAcreCableHollow", HOLLOW_SCENE, Vector2(-1320, 80), &"LongAcreCableHollow")
	_add_enemy("LongAcreLaybyHollow", HOLLOW_SCENE, Vector2(1310, 105), &"LongAcreLaybyHollow")
	_add_enemy("LongAcreGeneratorHollow", HOLLOW_SCENE, Vector2(420, 625), &"LongAcreGeneratorHollow")
	_add_future_enemy("RelayHusk", RELAY_HUSK_PATH, Vector2(0, -650), &"RelayHusk", Color(1.0, 0.72, 0.32, 1.0), Vector2(1.25, 1.25))
	_add_enemy("WestCableSignalLeech", SIGNAL_LEECH_SCENE, Vector2(-1040, -300), &"WestCableSignalLeech")
	_add_enemy("EastSignMimic", MIMIC_STALKER_SCENE, Vector2(880, 115), &"EastSignMimic")

	_add_spawn("from_ashmere", Vector2(0, 850))
	_add_spawn("from_core", Vector2(0, -790))
	_add_exit("BackToAshmere", Vector2(0, 940), "Take the Bellwether road", "res://scenes/maps/ashmere_verge.tscn", &"from_broadcast", PI)
	_add_world_bounds(Vector2(3200, 2000))
	_add_ash_drift("SignalAshWest", Vector2(-820, -40), Vector2(1500, 1300), Vector2(-17, 5))
	_add_ash_drift("SignalAshEast", Vector2(820, -40), Vector2(1500, 1300), Vector2(-15, 6))
	_add_ash_drift("GeneratorAshPocket", Vector2(330, 710), Vector2(320, 220), Vector2(-21, 7), 9.0)


# ---------------------------------------------------------------------------
# Finale: Choir Core

func _build_choir_core() -> void:
	_add_ground(Vector2(2400, 1800), Color(0.23, 0.30, 0.30, 1.0), TEX_ASH_SEAMLESS)
	_add_ash_band("CoreColdWash", Vector2(0, -610), Vector2(2400, 500), Color(0.17, 0.27, 0.29, 1.0), TEX_METAL)
	_add_textured_polygon("CoreFloor", PackedVector2Array([
		Vector2(-410, 440), Vector2(410, 440), Vector2(600, 180), Vector2(520, -390),
		Vector2(300, -540), Vector2(-300, -540), Vector2(-520, -390), Vector2(-600, 180),
	]), TEX_METAL, Color(0.50, 0.53, 0.48, 1.0), -1, Vector2(0.72, 0.72))
	_add_textured_polygon("ProcessionalLane", PackedVector2Array([
		Vector2(-90, 900), Vector2(90, 900), Vector2(125, -720), Vector2(-125, -720),
	]), TEX_PLANKS, Color(0.50, 0.44, 0.35, 1.0), 0, Vector2(0.72, 0.72))
	_add_textured_polygon("PublicArchiveWing", PackedVector2Array([
		Vector2(-1110, 170), Vector2(-520, 170), Vector2(-420, -440),
		Vector2(-690, -640), Vector2(-1090, -530),
	]), TEX_CONCRETE, Color(0.45, 0.49, 0.45, 1.0), -1, Vector2(0.78, 0.78))
	_add_textured_polygon("OperationsWing", PackedVector2Array([
		Vector2(1110, 170), Vector2(520, 170), Vector2(420, -440),
		Vector2(690, -640), Vector2(1090, -530),
	]), TEX_METAL, Color(0.44, 0.50, 0.48, 1.0), -1, Vector2(0.72, 0.72))
	_add_textured_polygon("ReceptionLoop", PackedVector2Array([
		Vector2(-520, 620), Vector2(-160, 760), Vector2(0, 610), Vector2(160, 760),
		Vector2(520, 620), Vector2(430, 400), Vector2(0, 480), Vector2(-430, 400),
	]), TEX_ASPHALT, Color(0.49, 0.48, 0.42, 1.0), -1, Vector2(0.92, 0.92))
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
	_add_landmark_threshold("ArchiveThreshold", Vector2(-520, 250), -0.72, Color(0.46, 0.74, 0.76, 1.0))
	_add_landmark_threshold("OperationsThreshold", Vector2(520, 250), 0.72, Color(0.70, 0.58, 0.36, 1.0))
	_add_landmark_threshold("ChoirThreshold", Vector2(0, -180), 0.0, Color(0.42, 0.83, 0.86, 1.0))

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
	_add_obstacle("CountyRecordsAnnexCollapse", Vector2(-1040, 455), Vector2(285, 125), RUST_DARK)
	_add_ruin_debris("CoreThresholdFall", Vector2(-245, 405), -0.14, Vector2(0.58, 0.46))
	_add_ruin_debris("CoreArchiveFall", Vector2(510, -465), 0.18, Vector2(0.52, 0.42))

	_add_core_rings(Vector2(0, -420))
	_add_glow("FirstToneGlow", Vector2(0, -330), 165.0, Color(CYAN, 0.16), 3)
	_add_glow("FinalConsoleGlow", Vector2(0, -690), 140.0, Color(AMBER, 0.15), 3)
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
	_add_loot("TollardArchiveEvidence", Vector2(-1030, -410), {&"battery": 1, &"scrap": 2}, "Open the county archive evidence drawer", {
		&"required_service_flag": &"mechanical_bypass_available",
		&"locked_prompt": "Secured archive drawer - Mara's numbered bypass is required",
	})
	_add_loot("TollardOperationsLocker", Vector2(1030, -390), {&"canned_food": 2, &"battery": 1}, "Open the night-shift locker")
	_add_loot("TollardReceptionCache", Vector2(470, 570), {&"scrap": 2, &"canned_food": 1}, "Search the reception emergency box")
	_add_memory_echo("EchoFirstTone", &"echo_first_tone", Vector2(0, -330))
	_add_campaign_interactable("choir_final_console", Vector2(0, -695), "Open the Tollard incident record")
	_add_authored_scene(ROUTE_FINALE_SCENE, "RouteFinaleController", Vector2(0, -205))

	_add_future_enemy("ChoirWestWraith", STATIC_WRAITH_PATH, Vector2(-520, -55), &"ChoirWestWraith", Color(0.48, 0.96, 1.0, 0.88))
	_add_future_enemy("ChoirEastWraith", STATIC_WRAITH_PATH, Vector2(520, -55), &"ChoirEastWraith", Color(0.48, 0.96, 1.0, 0.88))
	_add_enemy("TollardArchiveHollow", HOLLOW_SCENE, Vector2(-720, 180), &"TollardArchiveHollow")
	_add_enemy("TollardOperationsHollow", HOLLOW_SCENE, Vector2(720, 190), &"TollardOperationsHollow")
	_add_future_enemy("TollardRecordsWraith", STATIC_WRAITH_PATH, Vector2(-865, -210), &"TollardRecordsWraith", Color(0.45, 0.88, 0.94, 0.86))
	_add_future_enemy("ChoirWarden", RELAY_HUSK_PATH, Vector2(0, -470), &"ChoirWarden", Color(0.52, 0.94, 1.0, 1.0), Vector2(1.55, 1.55))
	_add_enemy("ArchiveSignalLeech", SIGNAL_LEECH_SCENE, Vector2(-680, 300), &"ArchiveSignalLeech")
	_add_enemy("OperationsMimic", MIMIC_STALKER_SCENE, Vector2(690, -250), &"OperationsMimic")

	_add_spawn("from_fields", Vector2(0, 750))
	_add_exit("BackToBroadcastFields", Vector2(0, 840), "Return to Long Acre", "res://scenes/maps/broadcast_fields.tscn", &"from_core", PI)
	_add_world_bounds(Vector2(2400, 1800))
	_add_ash_drift("CoreSignalDust", Vector2(0, -80), Vector2(1900, 1450), Vector2(-8, 4))
	_add_ash_drift("ArchiveAshPocket", Vector2(-1030, -410), Vector2(300, 230), Vector2(-16, 5), 10.0)


# ---------------------------------------------------------------------------
# Shared authoring helpers

func _add_ground(size: Vector2, color: Color = ASH_GROUND, _texture_path: String = TEX_DIRT) -> void:
	var texture := load(TEX_ASH_SEAMLESS) as Texture2D
	if texture != null:
		var ground := Sprite2D.new()
		ground.name = "Ground"
		ground.texture = texture
		ground.centered = true
		ground.region_enabled = true
		ground.region_rect = Rect2(Vector2.ZERO, size)
		ground.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		ground.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		ground.modulate = color.lightened(0.24)
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
	var band := _add_polygon(node_name, points, _world_surface_color(color, 0.68), -5)
	band.set_meta("material_reference", texture_path)
	band.position = center
	_apply_seamless_surface(band, color, Vector2(0.82, 0.82))


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
	var polygon := _add_polygon(node_name, points, _world_surface_color(color, 0.58), z)
	polygon.set_meta("material_reference", texture_path)
	_apply_seamless_surface(polygon, color, texture_scale_value)
	return polygon


func _world_surface_color(source: Color, value_scale: float) -> Color:
	# Keep paths readable without turning them into bright placeholder cards.
	# A slight warm-grey pull ties bespoke route colours back to the same ash.
	var muted := Color(
		source.r * value_scale,
		source.g * value_scale,
		source.b * value_scale,
		source.a
	)
	return muted.lerp(Color(0.17, 0.175, 0.16, source.a), 0.22)


func _apply_seamless_surface(polygon: Polygon2D, tint: Color, texture_scale_value: Vector2) -> void:
	var texture := load(TEX_ASH_SEAMLESS) as Texture2D
	if polygon == null or texture == null:
		return
	polygon.texture = texture
	polygon.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	polygon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	polygon.texture_scale = texture_scale_value
	# The source photograph supplies the value range; this colour only nudges
	# road, concrete and ash pockets apart without flattening the detail.
	polygon.color = tint.lightened(0.58)


func _texture_polygon_once(polygon: Polygon2D, texture_path: String, points: PackedVector2Array) -> void:
	if polygon == null or points.is_empty():
		return
	polygon.set_meta("material_reference", texture_path)


func _add_rect_visual(node_name: String, center: Vector2, size: Vector2, color: Color, z: int) -> Polygon2D:
	var half := size * 0.5
	var polygon := _add_polygon(node_name, PackedVector2Array([
		Vector2(-half.x, -half.y), Vector2(half.x, -half.y),
		Vector2(half.x, half.y), Vector2(-half.x, half.y),
	]), color, z)
	polygon.position = center
	return polygon


func _add_obstacle(node_name: String, center: Vector2, size: Vector2, color: Color) -> StaticBody2D:
	var building_id := BuildingCatalog.structure_id(node_name)
	if building_id != &"":
		var minimum_size := BuildingCatalog.minimum_exterior_size(building_id)
		# Intact buildings must read as architecture beside Ellie, not as props.
		# Room count drives the minimum visible and physical footprint.
		size.x = maxf(size.x, minimum_size.x)
		size.y = maxf(size.y, minimum_size.y)
	var uses_named_landmark := _uses_named_landmark(node_name)
	var solid_kind := _solid_kind_for_structure(node_name, building_id)
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
	visual.color = Color(0.19, 0.195, 0.175, 1.0).lerp(color, 0.24)
	visual.set_meta("material_reference", _structure_texture_for(node_name, size))
	visual.z_index = 2
	# Full painted landmark sprites replace the old procedural obstacle face.
	# Keeping both visible left a long, uniform backing band around the authored
	# building, especially at the South Generator Hall and Tollard structures.
	visual.visible = not uses_named_landmark
	body.add_child(visual)
	var ruin_texture := load("res://assets/processed/roadside_props/debris_pile.png") as Texture2D
	if (
		ruin_texture != null
		and solid_kind == &"blocked_ruin"
	):
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
	_add_structure_art(body, node_name, size)
	# World entrances are interaction thresholds on the exterior apron. A full
	# collision foot keeps the player from walking under the painted building;
	# entering swaps to the authored interior instead.
	if building_id != &"":
		_add_intact_building_collision(body, visual.polygon, size)
	else:
		_add_convex_collision(body, "CollisionShape2D", visual.polygon)
	WorldLayoutContract.tag_solid(body, solid_kind, visual.polygon, false)
	body.set_meta("footprint_size", size)
	body.set_meta("player_scale_units", size / WorldLayoutContract.PLAYER_REFERENCE)
	body.set_meta("building_id", building_id)
	if solid_kind == &"blocked_ruin":
		body.set_meta("entry_state", "visibly-blocked")
	if building_id != &"":
		body.set_meta("entry_state", "intact-enterable")
		body.set_meta("room_count", int(BuildingCatalog.get_building(building_id).get("rooms", 1)))
		_add_building_threshold(building_id, node_name, center, size)
	return body


func _solid_kind_for_structure(node_name: String, building_id: StringName) -> StringName:
	if building_id != &"":
		return &"intact_building"
	var lower := node_name.to_lower()
	if "ruin" in lower or "collapse" in lower or "collapsed" in lower or "shell" in lower:
		return &"blocked_ruin"
	if "fence" in lower or "barrier" in lower or "bulkhead" in lower:
		return &"barrier"
	return &"world_structure"


func _add_intact_building_collision(
		body: StaticBody2D,
		footprint: PackedVector2Array,
		size: Vector2) -> void:
	var door_center_x := size.x * 0.24
	_add_convex_collision(body, "BuildingFootprint", footprint)
	body.set_meta("door_gap_center_x", door_center_x)
	body.set_meta("door_gap_width", 0.0)
	body.set_meta("door_gap_depth", 0.0)


func _add_convex_collision(
		body: StaticBody2D,
		node_name: String,
		points: PackedVector2Array) -> void:
	if points.size() < 3:
		return
	var shape := ConvexPolygonShape2D.new()
	shape.points = points
	var collision := CollisionShape2D.new()
	collision.name = node_name
	collision.shape = shape
	body.add_child(collision)


func _clip_polygon_axis(
		points: PackedVector2Array,
		axis: StringName,
		boundary: float,
		keep_less: bool) -> PackedVector2Array:
	var result := PackedVector2Array()
	if points.is_empty():
		return result
	var previous := points[points.size() - 1]
	var previous_value := previous.x if axis == &"x" else previous.y
	var previous_inside := previous_value <= boundary if keep_less else previous_value >= boundary
	for current in points:
		var current_value := current.x if axis == &"x" else current.y
		var current_inside := current_value <= boundary if keep_less else current_value >= boundary
		if current_inside != previous_inside:
			var denominator := current_value - previous_value
			var amount := 0.0 if is_zero_approx(denominator) else (boundary - previous_value) / denominator
			result.append(previous.lerp(current, clampf(amount, 0.0, 1.0)))
		if current_inside:
			result.append(current)
		previous = current
		previous_value = current_value
		previous_inside = current_inside
	return result


func _add_building_threshold(
		building_id: StringName,
		exterior_name: String,
		center: Vector2,
		size: Vector2) -> void:
	var return_scene := _campaign_scene_path()
	if return_scene.is_empty():
		return
	var threshold_position := center + Vector2(size.x * 0.24, size.y * 0.5 + 30.0)
	var spawn_name := StringName("return_%s" % String(building_id))
	_add_spawn(String(spawn_name), threshold_position + Vector2(0, 104.0))
	var door := BUILDING_DOOR_SCENE.instantiate() as BuildingDoor
	if door == null:
		return
	door.name = "%sThreshold" % exterior_name
	door.position = threshold_position
	door.scale = Vector2(0.82, 0.82)
	door.building_id = building_id
	door.return_scene_path = return_scene
	door.return_spawn = spawn_name
	door.add_to_group("objective_targets")
	door.add_to_group("enterable_building_thresholds")
	door.set_meta("building_id", building_id)
	door.set_meta("room_count", int(BuildingCatalog.get_building(building_id).get("rooms", 1)))
	door.set_meta("threshold_clearance", WorldLayoutContract.PLAYER_REFERENCE * 1.12)
	add_child(door)


func _campaign_scene_path() -> String:
	match campaign_id:
		"ashmere_verge":
			return "res://scenes/maps/ashmere_verge.tscn"
		"broadcast_fields":
			return "res://scenes/maps/broadcast_fields.tscn"
		"choir_core":
			return "res://scenes/maps/choir_core.tscn"
	return ""


func _structure_texture_for(node_name: String, size: Vector2) -> String:
	var lower := node_name.to_lower()
	if size.y <= 105.0 or "terrace" in lower or "school" in lower or "archive" in lower:
		return TEX_PLANKS
	if (
		"relay" in lower or "transformer" in lower or "pylon" in lower
		or "bank" in lower or "switch" in lower or "operations" in lower
		or "clinic" in lower or "generator" in lower
	):
		return TEX_METAL
	return TEX_CONCRETE


func _add_structure_art(body: StaticBody2D, node_name: String, size: Vector2) -> void:
	var lower := node_name.to_lower()
	var structure_tint := (
		METAL if (
			"clinic" in lower or "relay" in lower or "transformer" in lower
			or "control" in lower or "generator" in lower or "operations" in lower
		) else RUST_DARK
	)
	if _add_named_landmark_art(body, lower, size):
		return
	if "bus" in lower:
		_add_structure_sprite(body, "VehicleShell", PROP_BROKEN_CAR, Vector2(0, -4), minf(size.x / 480.0, size.y / 300.0) * 1.35, 5)
		return
	if size.y <= 105.0 or "fence" in lower or "barrier" in lower:
		var pieces := clampi(floori(size.x / 115.0), 1, 5)
		var spacing := minf(108.0, size.x / float(pieces))
		var first_x := -spacing * float(pieces - 1) * 0.5
		for index in pieces:
			_add_structure_sprite(
				body,
				"Rail%d" % (index + 1),
				PROP_GUARDRAIL,
				Vector2(first_x + spacing * float(index), -3),
				0.14,
				5
			)
		return

	# Furniture sheets and the full Railhome doorway used to be pasted onto
	# exterior walls, making workbenches read as tiny buildings. Generic
	# architecture uses a layered roof, restrained panels and one readable
	# threshold. Nothing here resembles a freestanding interior prop.
	var roof := Polygon2D.new()
	roof.name = "RoofInset"
	roof.position = Vector2(0, -size.y * 0.08)
	roof.polygon = PackedVector2Array([
		Vector2(-size.x * 0.40, -size.y * 0.31),
		Vector2(size.x * 0.35, -size.y * 0.33),
		Vector2(size.x * 0.43, -size.y * 0.08),
		Vector2(size.x * 0.34, size.y * 0.24),
		Vector2(-size.x * 0.36, size.y * 0.26),
		Vector2(-size.x * 0.43, -size.y * 0.04),
	])
	roof.color = Color(0.115, 0.125, 0.115, 0.98).lerp(structure_tint, 0.18)
	roof.z_index = 3
	body.add_child(roof)

	for seam_index in 3:
		var seam := Line2D.new()
		seam.name = "RoofSeam%d" % (seam_index + 1)
		var seam_x := size.x * (-0.24 + float(seam_index) * 0.24)
		seam.points = PackedVector2Array([
			Vector2(seam_x - 8.0, -size.y * 0.34),
			Vector2(seam_x + 8.0, size.y * 0.18),
		])
		seam.width = 2.0
		seam.default_color = Color(0.48, 0.34, 0.20, 0.28)
		seam.z_index = 4
		body.add_child(seam)

	var door_center := Vector2(size.x * 0.24, size.y * 0.22)
	var door := Polygon2D.new()
	door.name = "ServiceDoorRecess"
	door.position = door_center
	door.polygon = WorldLayoutContract.rectangle_points(Vector2(
		clampf(size.x * 0.12, 38.0, 58.0),
		clampf(size.y * 0.34, 34.0, 58.0)
	))
	door.color = Color(0.105, 0.11, 0.095, 0.98)
	door.z_index = 5
	body.add_child(door)

	var lintel := Polygon2D.new()
	lintel.name = "ServiceDoorLintel"
	lintel.position = door_center + Vector2(0, -clampf(size.y * 0.19, 19.0, 31.0))
	lintel.polygon = WorldLayoutContract.rectangle_points(Vector2(
		clampf(size.x * 0.15, 46.0, 68.0), 6.0
	))
	lintel.color = Color(0.58, 0.39, 0.18, 0.62)
	lintel.z_index = 6
	body.add_child(lintel)

	for index in 2:
		var window := Polygon2D.new()
		window.name = "Window%d" % (index + 1)
		window.position = Vector2(-size.x * (0.23 - float(index) * 0.20), size.y * 0.08)
		window.polygon = WorldLayoutContract.rectangle_points(Vector2(
			clampf(size.x * 0.12, 34.0, 54.0),
			clampf(size.y * 0.13, 16.0, 25.0)
		))
		window.color = Color(0.09, 0.14, 0.135, 0.72)
		window.z_index = 5
		body.add_child(window)


func _uses_named_landmark(node_name: String) -> bool:
	var lower := node_name.to_lower()
	return (
		"bellwetherschool" in lower or "ashmereclinic" in lower
		or "relayworkshop" in lower or "cablehouse" in lower
		or "antennabunker" in lower or "generatorhall" in lower
		or "tollardoperationsdesk" in lower or "tollardarchivestacks" in lower
	)


func _add_named_landmark_art(body: Node2D, lower: String, size: Vector2) -> bool:
	var path := ""
	var reference_width := 1.0
	if "bellwetherschool" in lower or "ashmereclinic" in lower:
		path = LANDMARK_BELLWETHER
		reference_width = 1773.0
	elif (
		"relayworkshop" in lower or "cablehouse" in lower
		or "antennabunker" in lower or "generatorhall" in lower
	):
		path = LANDMARK_LONG_ACRE
		reference_width = 1704.0
	elif "tollardoperationsdesk" in lower or "tollardarchivestacks" in lower:
		path = LANDMARK_TOLLARD
		reference_width = 1902.0
	if path.is_empty():
		return false
	var texture := load(path) as Texture2D
	if texture == null:
		return false
	var art_scale := clampf(size.x / reference_width, 0.18, 0.27)
	var art := Sprite2D.new()
	art.name = "AuthoredLandmark"
	art.texture = texture
	art.scale = Vector2.ONE * art_scale
	# Align the painted building's front step with the obstacle footprint. This
	# keeps collision honest while allowing antennas and rooflines to rise above
	# the nominal map block.
	art.position = Vector2(0, size.y * 0.5 - texture.get_height() * art_scale * 0.5)
	art.modulate = Color(0.92, 0.90, 0.83, 0.99)
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	art.z_index = 5
	body.add_child(art)
	return true


func _add_structure_sprite(
		parent: Node2D,
		node_name: String,
		path: String,
		position_value: Vector2,
		scale_value: float,
		z: int) -> void:
	var texture := load(path) as Texture2D
	if texture == null:
		return
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = texture
	sprite.position = position_value
	sprite.scale = Vector2.ONE * scale_value
	sprite.modulate = Color(0.82, 0.80, 0.70, 0.96)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.z_index = z
	parent.add_child(sprite)


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
	WorldLayoutContract.tag_boundary(body, "GroundApron")
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
	var physical := _prop_is_solid(path)
	var composed_story_prop := "maggie_cutting_body" in path.to_lower()
	var parent: Node2D = self
	if physical:
		var body := StaticBody2D.new()
		body.name = node_name
		body.position = position_value
		body.collision_layer = 1
		body.collision_mask = 0
		add_child(body)
		parent = body
	elif composed_story_prop:
		# Maggie and her recorder are one authored discovery image, but the body
		# must not become a navigation obstacle. Keep a named composition root
		# for story checks and place the artwork beneath it without collision.
		var composition := Node2D.new()
		composition.name = node_name
		composition.position = position_value
		add_child(composition)
		parent = composition
	var sprite := Sprite2D.new()
	sprite.name = "Visual" if physical or composed_story_prop else node_name
	sprite.texture = texture
	sprite.position = Vector2.ZERO if physical or composed_story_prop else position_value
	sprite.scale = scale_value
	sprite.modulate = tint
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.z_index = z
	parent.add_child(sprite)
	if physical:
		var solid_body := parent as StaticBody2D
		var footprint := _prop_footprint(texture, scale_value)
		var shape := RectangleShape2D.new()
		shape.size = footprint.size
		var collision := CollisionShape2D.new()
		collision.name = "Footprint"
		collision.position = footprint.position + footprint.size * 0.5
		collision.shape = shape
		solid_body.add_child(collision)
		WorldLayoutContract.tag_solid(
			solid_body,
			&"physical_prop",
			WorldLayoutContract.rectangle_points(footprint.size, collision.position)
		)


func _prop_is_solid(path: String) -> bool:
	# Only large, unmistakable obstacles block movement. Cones, signs, lamps,
	# radios and scattered dressing remain visual so tiny art cannot create an
	# invisible navigation border.
	var lower := path.to_lower()
	return (
		"broken_car" in lower
		or "guardrail" in lower
		or "debris_pile" in lower
		or "warning_barrier" in lower
		or "phone_booth" in lower
		or "vending_machine" in lower
	)


func _prop_footprint(texture: Texture2D, scale_value: Vector2) -> Rect2:
	var used := Rect2i(Vector2i.ZERO, Vector2i(texture.get_width(), texture.get_height()))
	var image := texture.get_image()
	if image != null and not image.is_empty():
		used = image.get_used_rect()
	var scaled_width := float(used.size.x) * absf(scale_value.x)
	var scaled_height := float(used.size.y) * absf(scale_value.y)
	var width := clampf(scaled_width * 0.72, 14.0, 228.0)
	var depth := clampf(scaled_height * 0.18, 10.0, 72.0)
	var used_bottom := float(used.position.y + used.size.y) - float(texture.get_height()) * 0.5
	var bottom_y := used_bottom * scale_value.y
	return Rect2(Vector2(-width * 0.5, bottom_y - depth), Vector2(width, depth))


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
	var body := StaticBody2D.new()
	body.name = node_name
	body.position = center
	body.rotation = rotation_value
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	var sprite := Sprite2D.new()
	sprite.name = "Visual"
	sprite.texture = rubble
	sprite.scale = scale_value
	sprite.modulate = Color(0.63, 0.62, 0.54, 0.88)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.z_index = 3
	body.add_child(sprite)
	var footprint := _prop_footprint(rubble, scale_value)
	var shape := RectangleShape2D.new()
	shape.size = footprint.size
	var collision := CollisionShape2D.new()
	collision.name = "Footprint"
	collision.position = footprint.position + footprint.size * 0.5
	collision.shape = shape
	body.add_child(collision)
	WorldLayoutContract.tag_solid(
		body,
		&"blocked_debris",
		WorldLayoutContract.rectangle_points(footprint.size, collision.position)
	)


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
	WorldLayoutContract.tag_solid(
		body,
		&"guardrail",
		WorldLayoutContract.rectangle_points(shape.size)
	)


func _add_landmark_threshold(
		node_name: String,
		center: Vector2,
		rotation_value: float,
		accent: Color) -> void:
	# Repeated two-post thresholds teach the route grammar: crossing one means
	# entering a named activity pocket, while open asphalt remains navigation.
	# Real barrier/sign art carries the silhouette; the line is only worn paint.
	var cluster := Node2D.new()
	cluster.name = node_name
	cluster.position = center
	cluster.rotation = rotation_value
	cluster.add_to_group("map_flow_cue_anchors")
	cluster.add_to_group("lighting_cyan" if accent.b > accent.r * 1.05 else "lighting_amber")
	cluster.set_meta("flow_role", &"decision_cue")
	cluster.set_meta("cue_channels", PackedStringArray(["ground", "sign", "light"]))
	cluster.set_meta("lighting_priority", 285.0)
	cluster.set_meta("lighting_cast_shadows", false)
	add_child(cluster)

	var paint := Line2D.new()
	paint.name = "ThresholdPaint"
	paint.points = PackedVector2Array([Vector2(-86, 0), Vector2(86, 0)])
	paint.width = 5.0
	paint.default_color = Color(accent, 0.26)
	paint.z_index = 1
	cluster.add_child(paint)

	var barrier_texture := load(PROP_BARRIER) as Texture2D
	if barrier_texture != null:
		for side in [-1.0, 1.0]:
			var barrier := Sprite2D.new()
			barrier.name = "BarrierWest" if side < 0.0 else "BarrierEast"
			barrier.texture = barrier_texture
			barrier.position = Vector2(102.0 * side, -8.0)
			barrier.scale = Vector2(0.12, 0.12)
			barrier.modulate = Color(0.78, 0.73, 0.62, 0.92)
			barrier.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			barrier.z_index = 4
			cluster.add_child(barrier)

	var sign_texture := load("res://assets/processed/roadside_props/road_sign.png") as Texture2D
	if sign_texture != null:
		var sign := Sprite2D.new()
		sign.name = "RouteSign"
		sign.texture = sign_texture
		sign.position = Vector2(-126, -42)
		sign.scale = Vector2(0.095, 0.095)
		sign.modulate = accent.lightened(0.18)
		sign.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		sign.z_index = 4
		cluster.add_child(sign)

	var lantern_texture := load(PROP_LANTERN) as Texture2D
	if lantern_texture != null:
		var lantern := Sprite2D.new()
		lantern.name = "ServiceLamp"
		lantern.texture = lantern_texture
		lantern.position = Vector2(126, -22)
		lantern.scale = Vector2(0.075, 0.075)
		lantern.modulate = Color(accent.lightened(0.22), 0.84)
		lantern.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		lantern.z_index = 4
		cluster.add_child(lantern)


func _add_loot(
		node_name: String,
		position_value: Vector2,
		loot: Dictionary,
		prompt_text: String,
		service_contract: Dictionary = {},
	) -> void:
	var container := LOOT_SCENE.instantiate()
	container.name = node_name
	container.position = position_value
	container.set("persistent_id", StringName(node_name))
	container.set("loot", loot)
	container.set("prompt", prompt_text)
	for property_name in service_contract:
		_set_property_if_present(container, StringName(property_name), service_contract[property_name])
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


func _add_route_mission_station(
		node_name: String,
		position_value: Vector2,
		mission_slot: int,
		required_anchor: String,
	) -> void:
	var station := _add_authored_scene(ROUTE_MISSION_STATION_SCENE, node_name, position_value, {
		&"mission_slot": mission_slot,
		&"required_anchor": required_anchor,
		&"station_label": "%s route work card" % required_anchor,
	})
	if station != null:
		station.set_meta("route_station", true)


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


func _add_authored_scene(
		scene: PackedScene,
		node_name: String,
		position_value: Vector2,
		properties: Dictionary = {}) -> Node2D:
	var node := scene.instantiate() as Node2D
	if node == null:
		return null
	node.name = node_name
	node.position = position_value
	for property_name in properties:
		_set_property_if_present(node, StringName(property_name), properties[property_name])
	add_child(node)
	return node


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


func _add_ash_drift(
		node_name: String,
		position_value: Vector2,
		area_value: Vector2,
		drift_value: Vector2,
		exposure_damage: float = 0.0,
	) -> void:
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
	ash.set("exposure_damage", exposure_damage)
	add_child(ash)


func _add_relay_landmark(node_name: String, center: Vector2, lean: float) -> void:
	var relay := Node2D.new()
	relay.name = node_name
	relay.position = center
	relay.rotation = lean
	add_child(relay)
	_add_landmark_sprite(relay, "RelayTower", PROP_STATION_SIGN, Vector2(0, -42), 0.24, Color(0.63, 0.70, 0.66, 0.98), 3)
	_add_landmark_sprite(relay, "RelayConsole", PROP_RADIO_DESK, Vector2(-12, 22), 0.17, Color(0.70, 0.74, 0.67, 0.96), 4)


func _add_landmark_sprite(
		parent: Node2D,
		node_name: String,
		path: String,
		position_value: Vector2,
		scale_value: float,
		tint: Color,
		z: int) -> void:
	var texture := load(path) as Texture2D
	if texture == null:
		return
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = texture
	sprite.position = position_value
	sprite.scale = Vector2.ONE * scale_value
	sprite.modulate = tint
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.z_index = z
	parent.add_child(sprite)


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
