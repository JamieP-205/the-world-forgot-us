extends RefCounted
## One source of truth for every intact, enterable exterior.
##
## The world maps own approach, scale and sightlines. This catalogue owns what
## is behind each threshold: room count, material language, evidence and useful
## salvage. Keeping that contract here stops decorative doors and copy-pasted
## empty rooms drifting back into the project.

const INTERIOR_SCENE_PATH := "res://scenes/interiors/building_interior.tscn"
const PLAYER_REFERENCE := 68.0
const INTERIOR_IDENTITY_ATLAS := "res://assets/processed/interior_identity/building_identity_atlas.png"
const INTERIOR_ATLAS_GRID := Vector2i(5, 4)

static var REGION_BUILDINGS := {
	&"cullbrook": PackedStringArray([
		"cullbrook_service_office", "cullbrook_kiosk", "cullbrook_maintenance_shed",
		"cullbrook_north_bay", "cullbrook_south_bay",
	]),
	&"ashmere_verge": PackedStringArray([
		"ashmere_terrace_north", "ashmere_terrace_south", "ashmere_clinic",
		"ashmere_relay_workshop", "bellwether_school", "bellwether_school_hall",
		"ashmere_clinic_annex",
	]),
	&"broadcast_fields": PackedStringArray([
		"wrenfield_west_transformer", "wrenfield_east_transformer", "wrenfield_control_shed",
		"wrenfield_cable_house", "wrenfield_antenna_bunker", "wrenfield_generator_hall",
		"wrenfield_repeater_shelter",
	]),
}

# Room dressing is authored per address rather than selected from a theme-wide
# strip. Placement entries are [prop id, room-local position, scale, rotation].
# The atlas cell is the site's one-off visual anchor; layout_key lets validation
# catch an interior that has accidentally been copied from another building.
static var INTERIOR_IDENTITIES := {
	&"cullbrook_service_office": {
		"identity_key": "ledger_office",
		"layout_key": "three_room_counter_axis",
		"atlas_cell": Vector2i(0, 0),
		"palette": Color(0.31, 0.285, 0.235, 1.0),
		"runner_tint": Color(0.34, 0.27, 0.17, 0.58),
		"hero_room": 1, "hero_offset": Vector2(28, -112), "hero_scale": 0.64,
		"dressing": [
			[["locker", Vector2(-126, -124), 0.94, -0.03], ["map", Vector2(116, -142), 0.94, 0.02], ["chest", Vector2(118, 132), 0.84, 0.0]],
			[["counter", Vector2(-116, 130), 0.90, 0.01], ["radio_desk", Vector2(124, 126), 0.78, -0.02]],
			[["empty_bench", Vector2(-112, -126), 0.86, -0.02], ["radio", Vector2(112, 126), 0.90, 0.05]],
		],
	},
	&"cullbrook_kiosk": {
		"identity_key": "turned_price_card",
		"layout_key": "single_room_kiosk_hook",
		"atlas_cell": Vector2i(1, 0),
		"palette": Color(0.33, 0.29, 0.21, 1.0),
		"runner_tint": Color(0.40, 0.31, 0.16, 0.55),
		"hero_room": 0, "hero_offset": Vector2(-32, -112), "hero_scale": 0.62,
		"dressing": [[
			["vending", Vector2(132, -132), 0.92, 0.0], ["crate", Vector2(-132, 132), 0.86, -0.05], ["poster", Vector2(126, 128), 0.90, 0.03],
		]],
	},
	&"cullbrook_maintenance_shed": {
		"identity_key": "double_coil_jig",
		"layout_key": "two_room_coil_laboratory",
		"atlas_cell": Vector2i(2, 0),
		"palette": Color(0.245, 0.265, 0.235, 1.0),
		"runner_tint": Color(0.27, 0.29, 0.20, 0.58),
		"hero_room": 1, "hero_offset": Vector2(8, -118), "hero_scale": 0.66,
		"dressing": [
			[["workbench", Vector2(-118, -126), 0.90, -0.02], ["toolbox", Vector2(124, 128), 0.92, 0.04], ["barrier", Vector2(-92, 144), 0.76, -0.08]],
			[["empty_bench", Vector2(-126, -126), 0.86, -0.02], ["receiver", Vector2(-132, 126), 1.04, 0.02], ["chest", Vector2(126, 132), 0.84, -0.03]],
		],
	},
	&"cullbrook_north_bay": {
		"identity_key": "wet_track_bay",
		"layout_key": "single_room_vehicle_diagonal",
		"atlas_cell": Vector2i(3, 0),
		"palette": Color(0.235, 0.245, 0.225, 1.0),
		"runner_tint": Color(0.30, 0.245, 0.16, 0.48),
		"hero_room": 0, "hero_offset": Vector2(56, -120), "hero_scale": 0.63,
		"dressing": [[
			["car", Vector2(-118, 92), 0.90, -0.10], ["toolbox", Vector2(132, 132), 0.94, 0.02], ["barrier", Vector2(-116, -142), 0.80, 0.06],
		]],
	},
	&"cullbrook_south_bay": {
		"identity_key": "rain_coat_locker",
		"layout_key": "single_room_duty_nook",
		"atlas_cell": Vector2i(4, 0),
		"palette": Color(0.265, 0.255, 0.215, 1.0),
		"runner_tint": Color(0.28, 0.23, 0.17, 0.58),
		"hero_room": 0, "hero_offset": Vector2(72, -112), "hero_scale": 0.61,
		"dressing": [[
			["bedroll", Vector2(-126, 126), 0.88, -0.04], ["lantern", Vector2(126, 136), 0.90, 0.02], ["chest", Vector2(-130, -138), 0.80, 0.03],
		]],
	},
	&"ashmere_terrace_north": {
		"identity_key": "ward_photo_wall",
		"layout_key": "three_room_family_spine",
		"atlas_cell": Vector2i(0, 1),
		"palette": Color(0.34, 0.285, 0.235, 1.0),
		"runner_tint": Color(0.42, 0.29, 0.19, 0.54),
		"hero_room": 2, "hero_offset": Vector2(14, -130), "hero_scale": 0.66,
		"dressing": [
			[["bedroll", Vector2(-122, -122), 0.90, 0.03], ["chest", Vector2(124, 132), 0.82, -0.02]],
			[["empty_bench", Vector2(118, -128), 0.82, 0.02], ["lantern", Vector2(-126, 136), 0.90, -0.04], ["radio", Vector2(124, 132), 0.82, 0.0]],
			[["photo", Vector2(-132, -142), 1.05, -0.03], ["bedroll", Vector2(126, 128), 0.84, 0.04]],
		],
	},
	&"ashmere_terrace_south": {
		"identity_key": "eighteenth_tally",
		"layout_key": "two_room_safehouse_cross",
		"atlas_cell": Vector2i(1, 1),
		"palette": Color(0.315, 0.275, 0.225, 1.0),
		"runner_tint": Color(0.37, 0.25, 0.16, 0.60),
		"hero_room": 0, "hero_offset": Vector2(-30, -118), "hero_scale": 0.64,
		"dressing": [
			[["bedroll", Vector2(-132, 126), 0.84, -0.04], ["radio", Vector2(132, 132), 0.94, 0.04], ["lantern", Vector2(126, -136), 0.78, 0.0]],
			[["bedroll", Vector2(126, -124), 0.86, 0.02], ["chest", Vector2(-130, -132), 0.82, -0.04], ["poster", Vector2(126, 134), 0.86, 0.03]],
		],
	},
	&"ashmere_clinic": {
		"identity_key": "absent_triage_beds",
		"layout_key": "three_room_clinic_zigzag",
		"atlas_cell": Vector2i(2, 1),
		"palette": Color(0.285, 0.325, 0.295, 1.0),
		"runner_tint": Color(0.25, 0.34, 0.28, 0.50),
		"hero_room": 1, "hero_offset": Vector2(26, -118), "hero_scale": 0.64,
		"dressing": [
			[["bedroll", Vector2(-128, -124), 0.86, 0.0], ["medicine", Vector2(126, 132), 1.02, 0.03], ["locker", Vector2(130, -136), 0.86, -0.02]],
			[["counter", Vector2(-128, 130), 0.82, -0.02], ["medicine", Vector2(128, 132), 0.96, 0.05]],
			[["bedroll", Vector2(126, -124), 0.82, -0.03], ["locker", Vector2(-126, 130), 0.88, 0.02], ["medicine", Vector2(126, 136), 0.88, 0.0]],
		],
	},
	&"ashmere_relay_workshop": {
		"identity_key": "red_sleeve_test_deck",
		"layout_key": "two_room_tape_workbench",
		"atlas_cell": Vector2i(3, 1),
		"palette": Color(0.245, 0.265, 0.225, 1.0),
		"runner_tint": Color(0.31, 0.26, 0.15, 0.54),
		"hero_room": 1, "hero_offset": Vector2(-22, -118), "hero_scale": 0.64,
		"dressing": [
			[["workbench", Vector2(-124, -126), 0.88, -0.03], ["toolbox", Vector2(128, 132), 0.94, 0.04], ["receiver", Vector2(126, -130), 0.88, 0.0]],
			[["radio_desk", Vector2(-126, 130), 0.84, 0.02], ["chest", Vector2(128, 134), 0.80, -0.04]],
		],
	},
	&"bellwether_school": {
		"identity_key": "crayon_route_board",
		"layout_key": "three_room_classroom_rake",
		"atlas_cell": Vector2i(4, 1),
		"palette": Color(0.35, 0.30, 0.235, 1.0),
		"runner_tint": Color(0.38, 0.28, 0.16, 0.54),
		"hero_room": 2, "hero_offset": Vector2(18, -134), "hero_scale": 0.66,
		"dressing": [
			[["empty_bench", Vector2(-124, -126), 0.82, -0.03], ["empty_bench", Vector2(126, 130), 0.78, 0.03], ["poster", Vector2(126, -140), 0.86, 0.0]],
			[["empty_bench", Vector2(124, -126), 0.84, 0.02], ["chest", Vector2(-128, 132), 0.80, -0.02], ["map", Vector2(126, 138), 0.90, 0.02]],
			[["map", Vector2(-130, -142), 0.90, -0.02], ["empty_bench", Vector2(122, 130), 0.82, 0.04]],
		],
	},
	&"bellwether_school_hall": {
		"identity_key": "one_facing_chair",
		"layout_key": "two_room_assembly_fan",
		"atlas_cell": Vector2i(0, 2),
		"palette": Color(0.325, 0.285, 0.225, 1.0),
		"runner_tint": Color(0.43, 0.29, 0.16, 0.52),
		"hero_room": 0, "hero_offset": Vector2(12, -116), "hero_scale": 0.66,
		"dressing": [
			[["empty_bench", Vector2(-132, 130), 0.82, -0.08], ["empty_bench", Vector2(130, 134), 0.80, 0.08]],
			[["poster", Vector2(-132, -142), 0.92, -0.02], ["chest", Vector2(126, 132), 0.80, 0.04], ["empty_bench", Vector2(124, -124), 0.78, -0.03]],
		],
	},
	&"ashmere_clinic_annex": {
		"identity_key": "early_dispatch_rack",
		"layout_key": "two_room_ambulance_lane",
		"atlas_cell": Vector2i(1, 2),
		"palette": Color(0.275, 0.315, 0.285, 1.0),
		"runner_tint": Color(0.23, 0.33, 0.275, 0.52),
		"hero_room": 0, "hero_offset": Vector2(46, -120), "hero_scale": 0.64,
		"dressing": [
			[["medicine", Vector2(-130, 132), 1.02, -0.03], ["locker", Vector2(130, 130), 0.84, 0.03], ["barrier", Vector2(-122, -140), 0.76, 0.0]],
			[["bedroll", Vector2(-126, -124), 0.82, 0.02], ["medicine", Vector2(128, 134), 0.92, -0.02], ["counter", Vector2(128, -126), 0.78, 0.0]],
		],
	},
	&"wrenfield_west_transformer": {
		"identity_key": "thumbprint_breaker",
		"layout_key": "single_room_breaker_wall",
		"atlas_cell": Vector2i(2, 2),
		"palette": Color(0.225, 0.245, 0.22, 1.0),
		"runner_tint": Color(0.26, 0.28, 0.18, 0.50),
		"hero_room": 0, "hero_offset": Vector2(52, -122), "hero_scale": 0.62,
		"dressing": [[
			["workbench", Vector2(126, -126), 0.82, 0.02], ["receiver", Vector2(-130, -128), 0.94, -0.03], ["toolbox", Vector2(-128, 134), 0.88, 0.02], ["locker", Vector2(132, 136), 0.82, 0.0],
		]],
	},
	&"wrenfield_east_transformer": {
		"identity_key": "opposed_feeder_needles",
		"layout_key": "single_room_feeder_arc",
		"atlas_cell": Vector2i(3, 2),
		"palette": Color(0.235, 0.25, 0.215, 1.0),
		"runner_tint": Color(0.29, 0.27, 0.16, 0.51),
		"hero_room": 0, "hero_offset": Vector2(-46, -122), "hero_scale": 0.63,
		"dressing": [[
			["radio_desk", Vector2(132, 130), 0.82, 0.02], ["receiver", Vector2(-132, 134), 0.94, -0.04], ["locker", Vector2(130, -136), 0.82, 0.0],
		]],
	},
	&"wrenfield_control_shed": {
		"identity_key": "voiceprint_isolator",
		"layout_key": "two_room_control_horseshoe",
		"atlas_cell": Vector2i(4, 2),
		"palette": Color(0.22, 0.245, 0.215, 1.0),
		"runner_tint": Color(0.25, 0.29, 0.18, 0.52),
		"hero_room": 1, "hero_offset": Vector2(28, -120), "hero_scale": 0.62,
		"dressing": [
			[["radio_desk", Vector2(-128, -126), 0.84, -0.02], ["locker", Vector2(128, 132), 0.82, 0.03], ["receiver", Vector2(126, -132), 0.90, 0.0]],
			[["workbench", Vector2(-126, 132), 0.82, 0.02], ["toolbox", Vector2(128, 134), 0.88, -0.03]],
		],
	},
	&"wrenfield_cable_house": {
		"identity_key": "unlisted_pair_splice",
		"layout_key": "two_room_cable_s_curve",
		"atlas_cell": Vector2i(0, 3),
		"palette": Color(0.23, 0.24, 0.205, 1.0),
		"runner_tint": Color(0.31, 0.245, 0.14, 0.52),
		"hero_room": 0, "hero_offset": Vector2(-20, -118), "hero_scale": 0.66,
		"dressing": [
			[["workbench", Vector2(126, -126), 0.82, 0.02], ["toolbox", Vector2(-130, 134), 0.90, -0.04]],
			[["receiver", Vector2(-128, -130), 0.96, 0.0], ["chest", Vector2(128, 134), 0.82, 0.03], ["barrier", Vector2(-112, 144), 0.74, -0.05]],
		],
	},
	&"wrenfield_antenna_bunker": {
		"identity_key": "returning_bearing",
		"layout_key": "two_room_bearing_wedge",
		"atlas_cell": Vector2i(1, 3),
		"palette": Color(0.215, 0.23, 0.205, 1.0),
		"runner_tint": Color(0.235, 0.27, 0.17, 0.50),
		"hero_room": 1, "hero_offset": Vector2(-12, -120), "hero_scale": 0.64,
		"dressing": [
			[["radio", Vector2(-130, -132), 0.94, -0.02], ["locker", Vector2(130, 132), 0.82, 0.03], ["map", Vector2(128, -140), 0.86, 0.0]],
			[["receiver", Vector2(-130, 132), 1.02, -0.03], ["radio_desk", Vector2(128, 134), 0.80, 0.02]],
		],
	},
	&"wrenfield_generator_hall": {
		"identity_key": "voice_load_governor",
		"layout_key": "three_room_generator_procession",
		"atlas_cell": Vector2i(2, 3),
		"palette": Color(0.205, 0.225, 0.195, 1.0),
		"runner_tint": Color(0.32, 0.235, 0.13, 0.54),
		"hero_room": 2, "hero_offset": Vector2(6, -116), "hero_scale": 0.66,
		"dressing": [
			[["barrier", Vector2(-126, -142), 0.78, -0.05], ["toolbox", Vector2(128, 132), 0.92, 0.04], ["locker", Vector2(128, -136), 0.82, 0.0]],
			[["workbench", Vector2(-128, -126), 0.84, -0.03], ["radio_desk", Vector2(128, 132), 0.78, 0.02]],
			[["empty_bench", Vector2(126, -126), 0.82, 0.02], ["receiver", Vector2(-130, 132), 0.94, -0.02], ["toolbox", Vector2(130, 136), 0.88, 0.04]],
		],
	},
	&"wrenfield_repeater_shelter": {
		"identity_key": "forewritten_caller_log",
		"layout_key": "single_room_repeater_corner",
		"atlas_cell": Vector2i(3, 3),
		"palette": Color(0.225, 0.24, 0.205, 1.0),
		"runner_tint": Color(0.28, 0.25, 0.15, 0.50),
		"hero_room": 0, "hero_offset": Vector2(12, -116), "hero_scale": 0.65,
		"dressing": [[
			["radio", Vector2(-132, 132), 0.98, -0.04], ["locker", Vector2(132, -136), 0.80, 0.02], ["map", Vector2(130, 136), 0.86, 0.0],
		]],
	},
}

# Secondary dressing sits close to walls and work surfaces, away from the
# central navigation lane. These are still authored per address; they are not
# selected from a procedural theme pool.
static var INTERIOR_DETAILS := {
	&"cullbrook_service_office": [
		[["poster", Vector2(-8, 164), 1.05, -0.02]],
		[["photo", Vector2(-152, -158), 1.05, 0.02], ["compass", Vector2(150, -156), 1.00, -0.03]],
		[["poster", Vector2(-150, 158), 1.05, 0.03], ["compass", Vector2(150, -156), 1.02, 0.02]],
	],
	&"cullbrook_kiosk": [[
		["compass", Vector2(-150, -158), 1.08, -0.04],
	]],
	&"cullbrook_maintenance_shed": [
		[["poster", Vector2(0, 164), 1.08, 0.02]],
		[["map", Vector2(-154, -158), 1.02, -0.02], ["photo", Vector2(152, 158), 1.06, 0.03]],
	],
	&"cullbrook_north_bay": [[
		["map", Vector2(0, -164), 1.08, 0.02],
	]],
	&"cullbrook_south_bay": [[
		["photo", Vector2(-6, -164), 1.10, -0.03],
	]],
	&"ashmere_terrace_north": [
		[["photo", Vector2(-154, 158), 1.06, -0.03], ["poster", Vector2(152, -158), 1.02, 0.02]],
		[["map", Vector2(-4, -164), 1.04, -0.02]],
		[["poster", Vector2(-154, 158), 1.04, 0.02], ["compass", Vector2(152, 158), 1.00, -0.03]],
	],
	&"ashmere_terrace_south": [
		[["photo", Vector2(-152, -158), 1.06, 0.03]],
		[["compass", Vector2(152, -158), 1.02, -0.02]],
	],
	&"ashmere_clinic": [
		[["poster", Vector2(-4, 164), 1.04, 0.02]],
		[["map", Vector2(-154, -158), 1.00, -0.03], ["photo", Vector2(152, 158), 1.05, 0.02]],
		[["poster", Vector2(-152, -158), 1.03, 0.03]],
	],
	&"ashmere_relay_workshop": [
		[["map", Vector2(0, 164), 1.02, -0.02]],
		[["poster", Vector2(-154, -158), 1.04, 0.02], ["photo", Vector2(152, 158), 1.05, -0.02]],
	],
	&"bellwether_school": [
		[["photo", Vector2(-154, 158), 1.08, -0.02]],
		[["poster", Vector2(154, -158), 1.04, 0.03]],
		[["compass", Vector2(-154, 158), 1.02, -0.03], ["photo", Vector2(154, 158), 1.04, 0.02]],
	],
	&"bellwether_school_hall": [
		[["map", Vector2(-154, -158), 1.02, -0.02], ["poster", Vector2(154, 158), 1.04, 0.03]],
		[["photo", Vector2(-154, 158), 1.06, -0.03]],
	],
	&"ashmere_clinic_annex": [
		[["poster", Vector2(0, 164), 1.04, 0.02]],
		[["photo", Vector2(-154, 158), 1.05, -0.02]],
	],
	&"wrenfield_west_transformer": [[
		["map", Vector2(0, 164), 1.02, 0.02],
	]],
	&"wrenfield_east_transformer": [[
		["compass", Vector2(0, 164), 1.04, -0.03],
	]],
	&"wrenfield_control_shed": [
		[["map", Vector2(-154, 158), 1.02, -0.02]],
		[["poster", Vector2(-154, -158), 1.03, 0.03], ["compass", Vector2(154, 158), 1.02, -0.03]],
	],
	&"wrenfield_cable_house": [
		[["map", Vector2(-154, 158), 1.02, 0.02], ["poster", Vector2(154, -158), 1.04, -0.03]],
		[["compass", Vector2(0, 164), 1.02, 0.02]],
	],
	&"wrenfield_antenna_bunker": [
		[["poster", Vector2(0, 164), 1.04, -0.02]],
		[["map", Vector2(-154, -158), 1.02, 0.03], ["compass", Vector2(154, 158), 1.00, -0.02]],
	],
	&"wrenfield_generator_hall": [
		[["map", Vector2(0, 164), 1.02, -0.02]],
		[["poster", Vector2(-154, -158), 1.04, 0.03], ["compass", Vector2(154, 158), 1.02, -0.03]],
		[["map", Vector2(-154, 158), 1.02, 0.02], ["photo", Vector2(154, -158), 1.05, -0.02]],
	],
	&"wrenfield_repeater_shelter": [[
		["poster", Vector2(-154, 158), 1.05, 0.02],
	]],
}

# One inexpensive practical per room. Entries are
# [room-local position, tone, radius, energy, physical fixture].
static var INTERIOR_LIGHTING := {
	&"cullbrook_service_office": [
		[Vector2(-24, -76), "amber", 275.0, 0.58, "shade"],
		[Vector2(34, -72), "amber", 265.0, 0.55, "shade"],
		[Vector2(8, -70), "cold", 255.0, 0.50, "tube"],
	],
	&"cullbrook_kiosk": [[Vector2(12, -68), "amber", 265.0, 0.56, "shade"]],
	&"cullbrook_maintenance_shed": [
		[Vector2(-26, -76), "amber", 275.0, 0.58, "shade"],
		[Vector2(24, -72), "cold", 265.0, 0.53, "tube"],
	],
	&"cullbrook_north_bay": [[Vector2(12, -64), "cold", 285.0, 0.55, "tube"]],
	&"cullbrook_south_bay": [[Vector2(18, -70), "amber", 270.0, 0.56, "shade"]],
	&"ashmere_terrace_north": [
		[Vector2(-18, -72), "amber", 260.0, 0.54, "shade"],
		[Vector2(22, -68), "amber", 255.0, 0.52, "shade"],
		[Vector2(8, -74), "amber", 265.0, 0.55, "shade"],
	],
	&"ashmere_terrace_south": [
		[Vector2(-16, -68), "amber", 265.0, 0.55, "shade"],
		[Vector2(18, -72), "amber", 260.0, 0.53, "shade"],
	],
	&"ashmere_clinic": [
		[Vector2(-18, -70), "cold", 280.0, 0.58, "tube"],
		[Vector2(22, -68), "cold", 275.0, 0.56, "tube"],
		[Vector2(8, -72), "cold", 270.0, 0.54, "tube"],
	],
	&"ashmere_relay_workshop": [
		[Vector2(-22, -76), "amber", 275.0, 0.57, "shade"],
		[Vector2(24, -70), "cold", 265.0, 0.52, "tube"],
	],
	&"bellwether_school": [
		[Vector2(-18, -70), "amber", 260.0, 0.52, "shade"],
		[Vector2(20, -68), "amber", 255.0, 0.50, "shade"],
		[Vector2(6, -72), "amber", 265.0, 0.53, "shade"],
	],
	&"bellwether_school_hall": [
		[Vector2(-18, -66), "amber", 285.0, 0.54, "shade"],
		[Vector2(20, -70), "amber", 280.0, 0.52, "shade"],
	],
	&"ashmere_clinic_annex": [
		[Vector2(-18, -70), "cold", 280.0, 0.57, "tube"],
		[Vector2(20, -68), "cold", 270.0, 0.54, "tube"],
	],
	&"wrenfield_west_transformer": [[Vector2(10, -68), "cold", 270.0, 0.53, "tube"]],
	&"wrenfield_east_transformer": [[Vector2(-10, -70), "cold", 270.0, 0.53, "tube"]],
	&"wrenfield_control_shed": [
		[Vector2(-20, -72), "cold", 275.0, 0.54, "tube"],
		[Vector2(22, -68), "cold", 270.0, 0.52, "tube"],
	],
	&"wrenfield_cable_house": [
		[Vector2(-20, -74), "amber", 275.0, 0.55, "shade"],
		[Vector2(22, -68), "cold", 265.0, 0.51, "tube"],
	],
	&"wrenfield_antenna_bunker": [
		[Vector2(-18, -70), "cold", 265.0, 0.51, "tube"],
		[Vector2(20, -72), "cold", 275.0, 0.54, "tube"],
	],
	&"wrenfield_generator_hall": [
		[Vector2(-18, -70), "amber", 285.0, 0.58, "shade"],
		[Vector2(20, -68), "cold", 275.0, 0.52, "tube"],
		[Vector2(8, -74), "amber", 290.0, 0.60, "shade"],
	],
	&"wrenfield_repeater_shelter": [[Vector2(8, -70), "amber", 270.0, 0.54, "shade"]],
}

const STRUCTURE_IDS := {
	"RuinedTerraceNorth": &"ashmere_terrace_north",
	"RuinedTerraceSouth": &"ashmere_terrace_south",
	"AshmereClinic": &"ashmere_clinic",
	"RelayWorkshop": &"ashmere_relay_workshop",
	"BellwetherSchool": &"bellwether_school",
	"SchoolHallEast": &"bellwether_school_hall",
	"ClinicAnnex": &"ashmere_clinic_annex",
	"WestTransformer": &"wrenfield_west_transformer",
	"EastTransformer": &"wrenfield_east_transformer",
	"SouthControlShed": &"wrenfield_control_shed",
	"WestCableHouse": &"wrenfield_cable_house",
	"EastAntennaBunker": &"wrenfield_antenna_bunker",
	"SouthGeneratorHall": &"wrenfield_generator_hall",
	"RepeaterShelter": &"wrenfield_repeater_shelter",
}

const BUILDINGS := {
	&"cullbrook_service_office": {
		"title": "Cullbrook Service Office",
		"rooms": 3,
		"theme": "service",
		"hero": "counter",
		"evidence_prompt": "Inspect the night ledger",
		"evidence": "The 02:03 entry is in Maggie's hand. The next line copies her spacing exactly, but the ink was laid down three days later.",
		"scanned": "Two carriers overlap in the paper fibres. One stops at 02:03. The other keeps writing after the pen was capped.",
		"loot": {&"scrap": 2, &"battery": 1, &"resin_tape": 1, &"lamp_oil": 1},
	},
	&"cullbrook_kiosk": {
		"title": "Cullbrook Road Kiosk",
		"rooms": 1,
		"theme": "shop",
		"hero": "vending",
		"evidence_prompt": "Read the price card",
		"evidence": "A child has turned the old price card over and written: DO NOT FOLLOW THE SIGNS. FOLLOW WHO CAME BACK.",
		"scanned": "A small hand writes the warning twice. In the second pass, the reflection in the kiosk glass writes first.",
		"loot": {&"canned_food": 1, &"copper_wire": 1},
	},
	&"cullbrook_maintenance_shed": {
		"title": "Cullbrook Maintenance Shed",
		"rooms": 2,
		"theme": "workshop",
		"hero": "workbench",
		"evidence_prompt": "Check the coil jig",
		"evidence": "Maggie wound two receiver coils. One is labelled ELLIE. The second is labelled ELLIE / IF SHE ANSWERS.",
		"scanned": "The empty jig hums at the same pitch as the voice on Ellie's receiver.",
		"loot": {&"scrap": 3, &"copper_wire": 2, &"resin_tape": 2},
	},
	&"cullbrook_north_bay": {
		"title": "North Service Bay",
		"rooms": 1,
		"theme": "garage",
		"hero": "toolbox",
		"evidence_prompt": "Inspect the tyre marks",
		"evidence": "The last vehicle left toward Ashmere. A second set of wet tracks returns to the locked bay and simply ends.",
		"scanned": "An engine idles behind the sealed shutter for six seconds. Nothing disturbs the dust.",
		"loot": {&"scrap": 2, &"clean_cloth": 1},
	},
	&"cullbrook_south_bay": {
		"title": "South Service Bay",
		"rooms": 1,
		"theme": "garage",
		"hero": "locker",
		"evidence_prompt": "Open the duty locker",
		"evidence": "The duty coat is still wet at the shoulders. The rain stopped eighteen years ago.",
		"scanned": "A woman's outline removes the coat, hangs it up, then remains standing inside it.",
		"loot": {&"clean_cloth": 2, &"field_dressing": 1},
	},
	&"ashmere_terrace_north": {
		"title": "North Terrace, Number 14B",
		"rooms": 3,
		"theme": "home",
		"hero": "bedroll",
		"evidence_prompt": "Examine the Ward photograph wall",
		"evidence": "Every family photograph includes Maggie except the newest print. That one shows Ellie alone, already wearing today's coat.",
		"scanned": "The missing figure returns when the receiver gain drops. She is facing out of the photograph, not toward the camera.",
		"loot": {&"clean_cloth": 2, &"canned_food": 1},
	},
	&"ashmere_terrace_south": {
		"title": "South Terrace Safe House",
		"rooms": 2,
		"theme": "home",
		"hero": "radio",
		"evidence_prompt": "Read the wall tally",
		"evidence": "Seventeen people slept here after Blank Night. The tally reaches eighteen whenever the receiver is switched on.",
		"scanned": "Seventeen sleepers breathe. An eighteenth breath comes from the cupboard under the stairs.",
		"loot": {&"canned_food": 2, &"clean_cloth": 1},
	},
	&"ashmere_clinic": {
		"title": "Ashmere Community Clinic",
		"rooms": 3,
		"theme": "clinic",
		"hero": "medicine",
		"evidence_prompt": "Check the triage board",
		"evidence": "Imogen's paper list records twenty-six patients. Continuity's printout adds four names, complete with pulse and dosage, but no beds were assigned.",
		"scanned": "Four absent monitors answer the receiver in perfect time. One pulse matches Ellie.",
		"loot": {&"field_dressing": 2, &"clean_cloth": 2, &"medical_kit": 1},
	},
	&"ashmere_relay_workshop": {
		"title": "Maggie's Relay Workshop",
		"rooms": 2,
		"theme": "workshop",
		"hero": "radio_desk",
		"evidence_prompt": "Inspect Maggie's test deck",
		"evidence": "The final cassette contains only room tone. Its label reads: IF IT SOUNDS LIKE ME, ASK WHAT I FORGOT ON PURPOSE.",
		"scanned": "The blank tape answers before Ellie can form the question: THE RED SLEEVE.",
		"loot": {&"copper_wire": 3, &"ceramic_fuse": 1, &"resin_tape": 3, &"scrap": 2},
	},
	&"bellwether_school": {
		"title": "Bellwether Primary School",
		"rooms": 3,
		"theme": "school",
		"hero": "map",
		"evidence_prompt": "Study the evacuation drawings",
		"evidence": "The children's maps disagree about every road except one footpath behind the clinic. None of the official route cards include it.",
		"scanned": "Crayon arrows lift from the paper and point through the east wall. A distant child whispers that the wall was not there then.",
		"loot": {&"clean_cloth": 1, &"filter_charcoal": 2, &"canned_food": 1},
	},
	&"bellwether_school_hall": {
		"title": "Bellwether Assembly Hall",
		"rooms": 2,
		"theme": "school",
		"hero": "chairs",
		"evidence_prompt": "Inspect the attendance register",
		"evidence": "The register marks the children safe at 01:52. At 02:03 the same names are marked safe again, this time at three different shelters.",
		"scanned": "Rows of empty chairs scrape toward three exits at once. One chair remains facing Ellie.",
		"loot": {&"clean_cloth": 2, &"copper_wire": 2, &"scrap": 1},
	},
	&"ashmere_clinic_annex": {
		"title": "Ashmere Ambulance Annex",
		"rooms": 2,
		"theme": "clinic",
		"hero": "oxygen",
		"evidence_prompt": "Read the ambulance card",
		"evidence": "The ambulance was dispatched to collect Imogen six minutes before she made the call asking for it.",
		"scanned": "A dispatcher repeats Imogen's request in her own voice, six minutes early. The second voice coughs between words.",
		"loot": {&"field_dressing": 1, &"battery": 1, &"clean_cloth": 1},
	},
	&"wrenfield_west_transformer": {
		"title": "West Transformer Hut",
		"rooms": 1,
		"theme": "utility",
		"hero": "switchgear",
		"evidence_prompt": "Inspect the breaker wax",
		"evidence": "The breaker was opened by hand, not by overload. A thumbprint in the wax matches no Wrenfield engineer on file.",
		"scanned": "The print resolves into Ellie's thumbprint. The wax is eighteen years old.",
		"loot": {&"ceramic_fuse": 1, &"copper_wire": 1},
	},
	&"wrenfield_east_transformer": {
		"title": "East Transformer Hut",
		"rooms": 1,
		"theme": "utility",
		"hero": "switchgear",
		"evidence_prompt": "Check the feeder chart",
		"evidence": "Power was diverted away from Tollard and into the shelters. The chart has been amended in Rafi's hand, then amended back by a machine printer.",
		"scanned": "The feeder needles replay both decisions at once. Nearby lights brighten and die in alternating rooms.",
		"loot": {&"battery": 1, &"ceramic_fuse": 1},
	},
	&"wrenfield_control_shed": {
		"title": "South Line Control Shed",
		"rooms": 2,
		"theme": "utility",
		"hero": "control_bank",
		"evidence_prompt": "Read the isolation order",
		"evidence": "Maggie ordered the south line isolated. Someone used her voiceprint to cancel the order ninety seconds later.",
		"scanned": "The cancel message is Maggie's voice with no breath, chair noise or room reflection.",
		"loot": {&"ceramic_fuse": 2, &"copper_wire": 1, &"scrap": 1},
	},
	&"wrenfield_cable_house": {
		"title": "Long Acre Cable House",
		"rooms": 2,
		"theme": "utility",
		"hero": "cable_reel",
		"evidence_prompt": "Inspect the carrier splice",
		"evidence": "A field splice joins the county carrier to an unlisted pair running toward the old waterworks.",
		"scanned": "Voices travel down the unlisted pair in both directions. One is Rafi. The reply is Rafi too.",
		"loot": {&"copper_wire": 3, &"resin_tape": 2, &"scrap": 2},
	},
	&"wrenfield_antenna_bunker": {
		"title": "East Antenna Bunker",
		"rooms": 2,
		"theme": "bunker",
		"hero": "aerial_console",
		"evidence_prompt": "Check the bearing tape",
		"evidence": "The final bearing points at Tollard. The pencil note beneath it says: IT IS POINTING BACK.",
		"scanned": "The aerial turns without power until it faces Ellie. Every loose screw on the bench follows.",
		"loot": {&"battery": 2, &"ceramic_fuse": 1},
	},
	&"wrenfield_generator_hall": {
		"title": "South Generator Hall",
		"rooms": 3,
		"theme": "industrial",
		"hero": "generator",
		"evidence_prompt": "Inspect the governor log",
		"evidence": "The generator held frequency for nine hours after its fuel line was cut. The log calls the extra output VOICE LOAD.",
		"scanned": "The dead flywheel turns once. Beneath the machinery, hundreds of people inhale together.",
		"loot": {&"scrap": 3, &"battery": 1, &"resin_tape": 1, &"lamp_oil": 2},
	},
	&"wrenfield_repeater_shelter": {
		"title": "Public Repeater Shelter",
		"rooms": 1,
		"theme": "bunker",
		"hero": "radio",
		"evidence_prompt": "Read the caller notes",
		"evidence": "Callers wrote their names before speaking so the operator could verify them. The last page lists names in the operator's handwriting before any calls arrived.",
		"scanned": "The receiver reads the next blank line aloud. It uses Ellie's name.",
		"loot": {&"copper_wire": 1, &"filter_charcoal": 1, &"battery": 1},
	},
}


static func has(building_id: StringName) -> bool:
	return BUILDINGS.has(building_id)


static func get_building(building_id: StringName) -> Dictionary:
	return (BUILDINGS.get(building_id, {}) as Dictionary).duplicate(true)


static func get_interior_identity(building_id: StringName) -> Dictionary:
	return (INTERIOR_IDENTITIES.get(building_id, {}) as Dictionary).duplicate(true)


static func get_interior_details(building_id: StringName) -> Array:
	return (INTERIOR_DETAILS.get(building_id, []) as Array).duplicate(true)


static func get_interior_lighting(building_id: StringName) -> Array:
	return (INTERIOR_LIGHTING.get(building_id, []) as Array).duplicate(true)


static func interior_layout_signature(building_id: StringName) -> String:
	var identity := get_interior_identity(building_id)
	var parts := PackedStringArray([String(identity.get("layout_key", ""))])
	var details := get_interior_details(building_id)
	var dressing := identity.get("dressing", []) as Array
	for room_index in dressing.size():
		var room_parts := PackedStringArray()
		var room_placements := (dressing[room_index] as Array).duplicate()
		if room_index < details.size():
			room_placements.append_array(details[room_index] as Array)
		for placement_value in room_placements:
			var placement := placement_value as Array
			if placement.size() < 4:
				continue
			var point := placement[1] as Vector2
			room_parts.append("%s@%.0f,%.0f:%.2f:%.2f" % [
				String(placement[0]), point.x, point.y,
				float(placement[2]), float(placement[3]),
			])
		parts.append("|".join(room_parts))
	return "/".join(parts)


static func structure_id(node_name: String) -> StringName:
	return STRUCTURE_IDS.get(node_name, &"")


static func display_name(building_id: StringName) -> String:
	var data := get_building(building_id)
	return String(data.get("title", "Unknown building"))


static func region_buildings(region_id: StringName) -> Array[StringName]:
	var result: Array[StringName] = []
	for building_value in REGION_BUILDINGS.get(region_id, PackedStringArray()):
		result.append(StringName(building_value))
	return result


static func minimum_exterior_size(building_id: StringName) -> Vector2:
	var rooms := clampi(int(get_building(building_id).get("rooms", 1)), 1, 3)
	# Exteriors must read as architecture beside a 68 px actor, but room count
	# does not map directly to facade width: a kiosk is narrow and the service
	# office's three rooms run into the depth of the building.
	return Vector2(
		PLAYER_REFERENCE * (2.75 + float(rooms - 1) * 0.22),
		PLAYER_REFERENCE * (2.0 + float(rooms - 1) * 0.20)
	)


static func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	var region_ids: Dictionary = {}
	var identity_keys: Dictionary = {}
	var layout_keys: Dictionary = {}
	var atlas_cells: Dictionary = {}
	for region_id in REGION_BUILDINGS:
		for building_value in REGION_BUILDINGS[region_id]:
			var building_id := StringName(building_value)
			if region_ids.has(building_id):
				errors.append("building %s is assigned to two regions" % building_id)
			region_ids[building_id] = region_id
	for building_value in BUILDINGS:
		var building_id := StringName(building_value)
		var data := BUILDINGS[building_id] as Dictionary
		var rooms := int(data.get("rooms", 0))
		if rooms < 1 or rooms > 3:
			errors.append("building %s has invalid room count %d" % [building_id, rooms])
		if not region_ids.has(building_id):
			errors.append("building %s has no world region" % building_id)
		var loot := data.get("loot", {}) as Dictionary
		if loot.is_empty():
			errors.append("building %s has no useful cache" % building_id)
		for item_value in loot:
			var item_id := StringName(item_value)
			if not ResourceLoader.exists("res://resources/items/%s.tres" % String(item_id)):
				errors.append("building %s uses unknown loot %s" % [building_id, item_id])
			if int(loot[item_id]) <= 0:
				errors.append("building %s has a non-positive %s reward" % [building_id, item_id])
		var identity := get_interior_identity(building_id)
		if identity.is_empty():
			errors.append("building %s has no authored interior identity" % building_id)
			continue
		var identity_key := String(identity.get("identity_key", ""))
		var layout_key := String(identity.get("layout_key", ""))
		var atlas_cell := identity.get("atlas_cell", Vector2i(-1, -1)) as Vector2i
		if identity_key.is_empty() or identity_keys.has(identity_key):
			errors.append("building %s does not own a unique identity key" % building_id)
		identity_keys[identity_key] = building_id
		if layout_key.is_empty() or layout_keys.has(layout_key):
			errors.append("building %s does not own a unique layout key" % building_id)
		layout_keys[layout_key] = building_id
		var cell_key := "%d,%d" % [atlas_cell.x, atlas_cell.y]
		if atlas_cell.x < 0 or atlas_cell.y < 0 or atlas_cell.x >= INTERIOR_ATLAS_GRID.x or atlas_cell.y >= INTERIOR_ATLAS_GRID.y:
			errors.append("building %s has an atlas cell outside the %dx%d sheet" % [building_id, INTERIOR_ATLAS_GRID.x, INTERIOR_ATLAS_GRID.y])
		elif atlas_cells.has(cell_key):
			errors.append("building %s shares atlas cell %s with %s" % [building_id, cell_key, atlas_cells[cell_key]])
		atlas_cells[cell_key] = building_id
		var dressing := identity.get("dressing", []) as Array
		var details := get_interior_details(building_id)
		var lighting := get_interior_lighting(building_id)
		if dressing.size() != rooms:
			errors.append("building %s authors %d room layouts for a %d-room interior" % [building_id, dressing.size(), rooms])
		if details.size() != rooms:
			errors.append("building %s authors %d detail sets for a %d-room interior" % [building_id, details.size(), rooms])
		if lighting.size() != rooms:
			errors.append("building %s authors %d practical lights for a %d-room interior" % [building_id, lighting.size(), rooms])
		for room_index in dressing.size():
			var placements := dressing[room_index] as Array
			var room_details: Array = []
			if room_index < details.size():
				room_details = details[room_index] as Array
			if placements.size() < 2:
				errors.append("building %s room %d has fewer than two structural placements" % [building_id, room_index + 1])
			for placement_value in placements:
				var placement := placement_value as Array
				if placement.size() != 4 or String(placement[0]).is_empty():
					errors.append("building %s room %d has a malformed placement" % [building_id, room_index + 1])
			for detail_value in room_details:
				var detail := detail_value as Array
				if detail.size() != 4 or String(detail[0]).is_empty():
					errors.append("building %s room %d has malformed detail dressing" % [building_id, room_index + 1])
			if room_index < lighting.size():
				var practical := lighting[room_index] as Array
				if practical.size() != 5 or float(practical[2]) < 220.0 or float(practical[2]) > 300.0 or float(practical[3]) > 0.65:
					errors.append("building %s room %d has an unsafe practical-light brief" % [building_id, room_index + 1])
		var hero_room := int(identity.get("hero_room", -1))
		if hero_room < 0 or hero_room >= rooms:
			errors.append("building %s places its hero art outside the room plan" % building_id)
	if region_ids.size() != BUILDINGS.size():
		errors.append("region manifest covers %d of %d buildings" % [region_ids.size(), BUILDINGS.size()])
	if INTERIOR_IDENTITIES.size() != BUILDINGS.size():
		errors.append("interior manifest covers %d of %d buildings" % [INTERIOR_IDENTITIES.size(), BUILDINGS.size()])
	if INTERIOR_DETAILS.size() != BUILDINGS.size():
		errors.append("interior detail manifest covers %d of %d buildings" % [INTERIOR_DETAILS.size(), BUILDINGS.size()])
	if INTERIOR_LIGHTING.size() != BUILDINGS.size():
		errors.append("interior lighting manifest covers %d of %d buildings" % [INTERIOR_LIGHTING.size(), BUILDINGS.size()])
	if not ResourceLoader.exists(INTERIOR_IDENTITY_ATLAS):
		errors.append("interior identity atlas is missing")
	return errors
