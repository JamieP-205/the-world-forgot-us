class_name WorldLayoutContract
extends RefCounted
## Physical wayfinding and collision vocabulary shared by the four world maps.
##
## These marks are deliberately environmental: worn road paint, a battered
## county sign and a low service lamp at each decision point. They give three
## matching readings of a junction without drawing a route over the world.

const PLAYER_REFERENCE := 68.0
const ROAD_SIGN := "res://assets/processed/roadside_props/road_sign.png"
const LANTERN := "res://assets/processed/railhome_props/lantern.png"

static var REGIONS := {
	&"cullbrook": {
		"route_nodes": PackedStringArray([
			"Road", "CullbrookServiceLoop", "CullbrookDrainageTrack", "MaintenanceCut",
		]),
		"landmarks": [
			{"name": "RailhomeCarriage", "position": Vector2(-690, 282), "bearing": "south-west"},
			{"name": "ServiceStationClock", "position": Vector2(240, -170), "bearing": "centre"},
			{"name": "FallenRadioMast", "position": Vector2(650, -270), "bearing": "north-east"},
			{"name": "DrainageYard", "position": Vector2(850, 455), "bearing": "south-east"},
		],
		"side_pockets": [
			{"name": "KioskPocket", "position": Vector2(-405, 88)},
			{"name": "CulvertPocket", "position": Vector2(925, 535)},
		],
		"shortcut": {"name": "MaintenanceCutShortcut", "position": Vector2(475, 160), "route_node": "MaintenanceCut", "connects": PackedStringArray(["forecourt", "service-yard"])},
		"quiet_buffers": [
			{"name": "RailhomeBreathingSpace", "position": Vector2(-620, 410), "radius": 155.0},
			{"name": "WestRoadBreathingSpace", "position": Vector2(-760, -120), "radius": 145.0},
		],
		"cues": [
			{"name": "ForecourtCue", "position": Vector2(-175, 78), "rotation": -0.35, "accent": Color(0.78, 0.57, 0.28)},
			{"name": "YardCue", "position": Vector2(495, 205), "rotation": 0.18, "accent": Color(0.67, 0.73, 0.56)},
			{"name": "DrainCue", "position": Vector2(705, 390), "rotation": 0.48, "accent": Color(0.48, 0.70, 0.70)},
		],
	},
	&"ashmere_verge": {
		"route_nodes": PackedStringArray([
			"OldNorthRoad", "SchoolApproach", "ClinicLoop", "WorkshopCutThrough",
		]),
		"landmarks": [
			{"name": "BellwetherSchoolBearing", "position": Vector2(-820, -610), "bearing": "north-west"},
			{"name": "AshmereClinicBearing", "position": Vector2(360, 335), "bearing": "south-east"},
			{"name": "RelayWorkshopBearing", "position": Vector2(670, -430), "bearing": "north-east"},
		],
		"side_pockets": [
			{"name": "BusDepotPocket", "position": Vector2(-760, 545)},
			{"name": "SchoolCaretakerPocket", "position": Vector2(-1040, -570)},
		],
		"shortcut": {"name": "WorkshopServiceCut", "position": Vector2(1020, -410), "route_node": "WorkshopCutThrough", "connects": PackedStringArray(["clinic-loop", "workshop-road"])},
		"quiet_buffers": [
			{"name": "CullbrookRoadBuffer", "position": Vector2(-1220, 0), "radius": 185.0},
			{"name": "OldRoadLaybyBuffer", "position": Vector2(-930, 175), "radius": 145.0},
		],
		"cues": [
			{"name": "SchoolDecisionCue", "position": Vector2(-900, -280), "rotation": -1.38, "accent": Color(0.72, 0.56, 0.34)},
			{"name": "ClinicDecisionCue", "position": Vector2(80, 250), "rotation": -0.18, "accent": Color(0.62, 0.75, 0.68)},
			{"name": "WorkshopDecisionCue", "position": Vector2(610, -285), "rotation": -0.30, "accent": Color(0.76, 0.50, 0.30)},
		],
	},
	&"broadcast_fields": {
		"route_nodes": PackedStringArray([
			"SouthServiceRoad", "WestRelayRoad", "EastRelayRoad", "SouthGeneratorLoop", "RelayHub",
		]),
		"landmarks": [
			{"name": "WestCableRelayBearing", "position": Vector2(-1180, -120), "bearing": "west"},
			{"name": "EastAntennaBearing", "position": Vector2(1180, -115), "bearing": "east"},
			{"name": "SouthGeneratorBearing", "position": Vector2(0, 520), "bearing": "south"},
			{"name": "TollardGateBearing", "position": Vector2(0, -845), "bearing": "north"},
		],
		"side_pockets": [
			{"name": "CableYardPocket", "position": Vector2(-1390, -255)},
			{"name": "RoadsideBunkerPocket", "position": Vector2(1370, 250)},
		],
		"shortcut": {"name": "RelayHubCrossCut", "position": Vector2(0, 40), "route_node": "RelayHub", "connects": PackedStringArray(["west-relay", "east-relay"])},
		"quiet_buffers": [
			{"name": "BellwetherRoadBuffer", "position": Vector2(0, 865), "radius": 175.0},
			{"name": "WestServiceLaybyBuffer", "position": Vector2(-720, 690), "radius": 135.0},
		],
		"cues": [
			{"name": "WestRelayDecisionCue", "position": Vector2(-760, -85), "rotation": 0.10, "accent": Color(0.45, 0.72, 0.72)},
			{"name": "EastRelayDecisionCue", "position": Vector2(760, -80), "rotation": -0.10, "accent": Color(0.55, 0.69, 0.66)},
			{"name": "GeneratorDecisionCue", "position": Vector2(0, 330), "rotation": 0.0, "accent": Color(0.78, 0.56, 0.30)},
		],
	},
	&"choir_core": {
		"route_nodes": PackedStringArray([
			"ProcessionalLane", "ReceptionLoop", "PublicArchiveWing", "OperationsWing", "CoreFloor",
		]),
		"landmarks": [
			{"name": "PublicArchiveBearing", "position": Vector2(-760, -230), "bearing": "west"},
			{"name": "NightOperationsBearing", "position": Vector2(760, -230), "bearing": "east"},
			{"name": "ChoirChamberBearing", "position": Vector2(0, -420), "bearing": "north"},
		],
		"side_pockets": [
			{"name": "ArchiveEvidencePocket", "position": Vector2(-1030, -410)},
			{"name": "NightShiftPocket", "position": Vector2(1030, -390)},
		],
		"shortcut": {"name": "ReceptionCrossCut", "position": Vector2(0, 500), "route_node": "ReceptionLoop", "connects": PackedStringArray(["public-archive", "night-operations"])},
		"quiet_buffers": [
			{"name": "ExchangeIntakeBuffer", "position": Vector2(0, 745), "radius": 165.0},
			{"name": "ReceptionBreathingSpace", "position": Vector2(0, 575), "radius": 125.0},
		],
		"cues": [
			{"name": "ArchiveDecisionCue", "position": Vector2(-520, 250), "rotation": -0.72, "accent": Color(0.46, 0.74, 0.76)},
			{"name": "OperationsDecisionCue", "position": Vector2(520, 250), "rotation": 0.72, "accent": Color(0.70, 0.58, 0.36)},
			{"name": "ChoirDecisionCue", "position": Vector2(0, -180), "rotation": 0.0, "accent": Color(0.42, 0.83, 0.86)},
		],
	},
}


static func has_region(region_id: StringName) -> bool:
	return REGIONS.has(region_id)


static func get_region(region_id: StringName) -> Dictionary:
	return (REGIONS.get(region_id, {}) as Dictionary).duplicate(true)


static func apply(root: Node2D, region_id: StringName, author_cues := true) -> Node2D:
	if root == null or not has_region(region_id):
		return null
	var existing := root.get_node_or_null("MapFlowContract") as Node2D
	if existing != null:
		return existing
	var spec := get_region(region_id)
	var contract := Node2D.new()
	contract.name = "MapFlowContract"
	contract.set_meta("region_id", region_id)
	contract.set_meta("route_nodes", spec.get("route_nodes", PackedStringArray()))
	contract.set_meta("layout_language", "hub-loop")
	contract.set_meta("guidance_rule", "ground+sign+light; no route rail")
	root.add_child(contract)

	for landmark_value in spec.get("landmarks", []):
		var landmark := landmark_value as Dictionary
		_add_role_marker(contract, landmark, &"landmark", "map_flow_landmarks")
	for pocket_value in spec.get("side_pockets", []):
		var pocket := pocket_value as Dictionary
		_add_role_marker(contract, pocket, &"side_pocket", "map_flow_side_pockets")
	for buffer_value in spec.get("quiet_buffers", []):
		var buffer := buffer_value as Dictionary
		_add_role_marker(contract, buffer, &"quiet_buffer", "map_flow_quiet_buffers")
	var shortcut := spec.get("shortcut", {}) as Dictionary
	if not shortcut.is_empty():
		_add_role_marker(contract, shortcut, &"shortcut", "map_flow_shortcuts")
	if author_cues:
		for cue_value in spec.get("cues", []):
			_add_wayfinding_bundle(contract, cue_value as Dictionary)
	_tag_nested_prop_solids(root)
	return contract


static func tag_solid(
		body: StaticBody2D,
		kind: StringName,
		visible_footprint: PackedVector2Array,
		split_threshold := false) -> void:
	if body == null:
		return
	body.add_to_group("world_solid_footprints")
	body.set_meta("collision_contract", "visible-foot")
	body.set_meta("solid_kind", kind)
	body.set_meta("visible_footprint", visible_footprint)
	body.set_meta("split_threshold", split_threshold)


static func tag_boundary(body: StaticBody2D, visible_apron_name: String) -> void:
	if body == null:
		return
	body.add_to_group("world_boundaries")
	body.set_meta("collision_contract", "world-edge")
	body.set_meta("visible_apron", visible_apron_name)


static func rectangle_points(size: Vector2, center := Vector2.ZERO) -> PackedVector2Array:
	var half := size * 0.5
	return PackedVector2Array([
		center + Vector2(-half.x, -half.y), center + Vector2(half.x, -half.y),
		center + Vector2(half.x, half.y), center + Vector2(-half.x, half.y),
	])


static func _tag_nested_prop_solids(root: Node) -> void:
	# Loot containers own a nested StaticBody so the trigger remains usable.
	# Register that physical foot as part of the same world collision audit.
	for node in root.find_children("SolidBody", "StaticBody2D", true, false):
		var body := node as StaticBody2D
		if body == null or body.is_in_group("world_solid_footprints"):
			continue
		var collision := body.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if collision == null or collision.shape == null:
			continue
		var rect := collision.shape.get_rect()
		tag_solid(body, &"loot_container", rectangle_points(rect.size, collision.position + rect.get_center()))
		body.set_meta("visual_source", "../Visual")


static func _add_role_marker(
		parent: Node2D,
		data: Dictionary,
		role: StringName,
		group_name: String) -> void:
	var marker := Marker2D.new()
	marker.name = String(data.get("name", String(role).to_pascal_case()))
	marker.position = data.get("position", Vector2.ZERO)
	marker.add_to_group(group_name)
	marker.set_meta("flow_role", role)
	for key in data:
		if key != "name" and key != "position":
			marker.set_meta(StringName(key), data[key])
	parent.add_child(marker)


static func _add_wayfinding_bundle(parent: Node2D, data: Dictionary) -> void:
	var cue := Node2D.new()
	cue.name = String(data.get("name", "DecisionCue"))
	cue.position = data.get("position", Vector2.ZERO)
	cue.rotation = float(data.get("rotation", 0.0))
	cue.add_to_group("map_flow_cue_anchors")
	cue.set_meta("flow_role", &"decision_cue")
	cue.set_meta("cue_channels", PackedStringArray(["ground", "sign", "light"]))
	parent.add_child(cue)
	var accent: Color = data.get("accent", Color(0.70, 0.57, 0.33))

	var paint := Line2D.new()
	paint.name = "WornThresholdPaint"
	paint.points = PackedVector2Array([Vector2(-84, 0), Vector2(-24, 2), Vector2(30, -2), Vector2(84, 0)])
	paint.width = 4.0
	paint.default_color = Color(accent, 0.24)
	paint.z_index = 1
	cue.add_child(paint)

	var sign_texture := load(ROAD_SIGN) as Texture2D
	if sign_texture != null:
		var sign := Sprite2D.new()
		sign.name = "CountySign"
		sign.texture = sign_texture
		sign.position = Vector2(-106, -38)
		sign.scale = Vector2(0.085, 0.085)
		sign.modulate = Color(accent.lightened(0.12), 0.88)
		sign.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		sign.z_index = 4
		cue.add_child(sign)

	var lantern_texture := load(LANTERN) as Texture2D
	if lantern_texture != null:
		var lantern := Sprite2D.new()
		lantern.name = "ServiceLamp"
		lantern.texture = lantern_texture
		lantern.position = Vector2(104, -22)
		lantern.scale = Vector2(0.075, 0.075)
		lantern.modulate = Color(accent.lightened(0.24), 0.82)
		lantern.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		lantern.z_index = 4
		cue.add_child(lantern)

	var pool := Polygon2D.new()
	pool.name = "LampFalloff"
	pool.position = Vector2(104, 2)
	pool.polygon = PackedVector2Array([
		Vector2(-38, 0), Vector2(-24, -11), Vector2(0, -15), Vector2(28, -9),
		Vector2(42, 2), Vector2(25, 13), Vector2(-8, 15), Vector2(-34, 9),
	])
	pool.color = Color(accent, 0.065)
	pool.z_index = 2
	cue.add_child(pool)
