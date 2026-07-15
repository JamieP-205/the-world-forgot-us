extends Node
## End-to-end campaign smoke test. Run with an isolated APPDATA directory:
## godot --headless --path <project> --scene res://tools/complete_game_smoke.tscn

var _failures: Array[String] = []
var _main: Node = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_run")


func _run() -> void:
	SaveManager.clear_run_state()
	GameManager.set_paused(false)
	GameManager.set_dialogue_active(false)
	GameManager.set_ending_active(false)

	_check_resources()
	await _check_full_flow()
	GameManager.set_ending_active(false)
	GameManager.set_dialogue_active(false)
	if _main != null and is_instance_valid(_main):
		_main.free()
		_main = null
	await _frames(2)

	if _failures.is_empty():
		print("COMPLETE_GAME_SMOKE: PASS")
		get_tree().quit(0)
	else:
		for failure in _failures:
			push_error("COMPLETE_GAME_SMOKE: " + failure)
		print("COMPLETE_GAME_SMOKE: FAIL (%d)" % _failures.size())
		get_tree().quit(1)


func _check_resources() -> void:
	var required := [
		"res://scenes/maps/ashmere_verge.tscn",
		"res://scenes/maps/broadcast_fields.tscn",
		"res://scenes/maps/choir_core.tscn",
		"res://scenes/enemies/enemy_static_wraith.tscn",
		"res://scenes/enemies/enemy_relay_husk.tscn",
		"res://scenes/enemies/enemy_signal_leech.tscn",
		"res://scenes/enemies/enemy_mimic_stalker.tscn",
		"res://scenes/npcs/imogen_bell.tscn",
		"res://scenes/npcs/rafi_sayeed.tscn",
		"res://scenes/world/campaign_interactable.tscn",
		"res://scenes/world/quest_device.tscn",
		"res://scenes/world/circuit_switch.tscn",
		"res://scenes/world/signal_defense_anchor.tscn",
		"res://scenes/ui/dialogue_overlay.tscn",
		"res://scenes/ui/archive_overlay.tscn",
		"res://scenes/ui/ending_overlay.tscn",
		"res://resources/echoes/echo_last_signal.tres",
		"res://resources/echoes/echo_sun_lid.tres",
		"res://resources/echoes/echo_mara_repair.tres",
		"res://resources/echoes/echo_clinic_triage.tres",
		"res://resources/echoes/echo_bus_ledger.tres",
		"res://resources/echoes/echo_names_wall.tres",
		"res://resources/echoes/echo_relay_warning.tres",
		"res://resources/echoes/echo_driver_call.tres",
		"res://resources/echoes/echo_first_tone.tres",
		"res://resources/echoes/echo_maggie_final.tres",
		"res://resources/items/medical_kit.tres",
		"res://resources/quests/imogen_rescue.tres",
		"res://resources/quests/wrenfield_lines.tres",
		"res://assets/generated/npcs/imogen_idle.png",
		"res://assets/generated/npcs/rafi_idle.png",
	]
	for path in required:
		if not ResourceLoader.exists(path):
			_fail("missing resource " + path)
		elif load(path) == null:
			_fail("resource failed to load " + path)


func _check_full_flow() -> void:
	var main_scene := load("res://scenes/main.tscn") as PackedScene
	if main_scene == null:
		_fail("main scene failed to load")
		return
	_main = main_scene.instantiate()
	add_child(_main)
	await _frames(3)
	_expect_level(CampaignSystem.RUSTWAY_SCENE)
	_check(_main.get_node_or_null("Player") != null, "persistent player exists")
	_check(_main.get_node_or_null("HUD/DialogueOverlay") != null, "dialogue overlay exists")
	_check(_main.get_node_or_null("HUD/ArchiveOverlay") != null, "archive overlay exists")
	_check(_main.get_node_or_null("HUD/EndingOverlay") != null, "ending overlay exists")
	var player := _main.get_node_or_null("Player")
	_check(player != null and player.has_method("get_dodge_cooldown_ratio"), "dodge ability API exists")
	_check(player != null and player.has_method("get_burst_cooldown_ratio"), "Memory Burst API exists")
	_check_intro_progress_guard(_main.get_node_or_null("HUD"))
	_check_school_power_coherence()
	_check_healing_supplies(player)
	_check_lighting()
	await _check_new_encounter_behaviors()

	# Complete Act I requirements and follow the newly playable north signal.
	InventorySystem.set_items({"scrap": 10, "battery": 5, "canned_food": 3})
	ArchiveSystem.restore(["echo_last_signal"])
	BaseUpgradeSystem.restore(["scanner_coil", "radio_desk"])
	WorldState.set_flag(&"rested_after_radio")
	CampaignSystem.call("_complete_story", &"north_signal", 0)
	await _frames(4)
	_expect_level(CampaignSystem.ASHMERE_SCENE)
	_expect_story_node(&"ashmere_mara_radio")
	_expect_story_node(&"bellwether_school_radio")
	_expect_story_node(&"ashmere_gate")
	_expect_story_node(&"imogen_clinic")
	_expect_story_node(&"clinic_power_junction")
	_expect_story_node(&"imogen_workshop_safe")

	# Play Maggie's workshop tape, then exercise both irreversible outcomes of
	# the optional call before continuing with the accepted branch.
	CampaignSystem.call("_complete_story", &"ashmere_mara_radio", -1)
	InventorySystem.set_items({"battery": 2, "scrap": 4, "medical_kit": 1})
	CampaignSystem.call("_complete_story", &"imogen_clinic", -1)
	_check(WorldState.has_flag(CampaignSystem.IMOGEN_MET_FLAG), "Imogen introduction records the living survivor")
	CampaignSystem.call("_complete_story", &"clinic_power_junction", 0)
	_check(WorldState.has_flag(CampaignSystem.CLINIC_POWER_FLAG), "clinic power decision persists")
	_check(InventorySystem.get_count(&"battery") == 1 and InventorySystem.get_count(&"scrap") == 2, "clinic repair consumes exact parts")
	_check("Repair" not in CampaignSystem.get_prompt(&"clinic_power_junction", ""), "completed clinic junction prompt is no longer stale")
	CampaignSystem.call("_complete_story", &"imogen_clinic", 0)
	_check(WorldState.has_flag(CampaignSystem.IMOGEN_ESCORT_FLAG), "Imogen escort starts")
	CampaignSystem.call("_complete_story", &"imogen_workshop_safe", 1)
	_check(WorldState.has_flag(CampaignSystem.IMOGEN_RESCUED_FLAG), "Imogen reaches the workshop")
	_check(WorldState.has_flag(&"imogen_kit_left"), "field-kit consequence persists")
	_check("Bring Imogen" not in CampaignSystem.get_prompt(&"imogen_workshop_safe", ""), "rescued Imogen prompt is no longer stale")
	_exercise_persistent_choice(
		&"bellwether_school_radio",
		CampaignSystem.RAFI_CONNECTED_FLAG,
		CampaignSystem.RAFI_DECLINED_FLAG,
		"get_rafi_status",
		"connected on 88.4",
		"aerial grounded",
		"Rafi aerial",
	)
	ArchiveSystem.restore(["echo_last_signal", "echo_sun_lid", "echo_mara_repair"])
	CampaignSystem.call("_complete_story", &"ashmere_gate", 0)
	await _frames(4)
	_expect_level(CampaignSystem.BROADCAST_SCENE)
	_expect_story_node(&"broadcast_relay_west")
	_expect_story_node(&"broadcast_relay_east")
	_expect_story_node(&"broadcast_relay_south")
	_expect_story_node(&"long_acre_repeater")
	_expect_story_node(&"road_trace_west")
	_expect_story_node(&"road_trace_east")
	_expect_story_node(&"road_trace_south")
	_expect_story_node(&"broadcast_defense_anchor")
	_expect_story_node(&"rafi_field_contact")
	_check(_main.get_current_level().find_child("RelayHusk", true, false) != null, "Relay Husk boss placed")
	_exercise_persistent_choice(
		&"long_acre_repeater",
		CampaignSystem.REPEATER_ONLINE_FLAG,
		CampaignSystem.REPEATER_DECLINED_FLAG,
		"get_public_repeater_status",
		"warning line online",
		"fuse removed",
		"public repeater",
	)
	_check_optional_progress_copy()
	_check("Rafi" in String(CampaignSystem.call("_archive_delivery_result")), "archive ending reflects the Rafi connection")
	_check("public repeater" in String(CampaignSystem.call("_archive_delivery_result")), "archive ending reflects the public warning line")
	_check("public repeater" in String(CampaignSystem.call("_silence_ending_body")), "power-cut ending preserves the local repeater consequence")

	# Restore each field line through a different verb: investigate physical
	# records, defend a carrier, then align a persistent manual circuit.
	CampaignSystem.call("_complete_story", &"road_trace_west", 0)
	_check("Verify" not in CampaignSystem.get_prompt(&"road_trace_west", ""), "verified road-record prompt is no longer stale")
	CampaignSystem.call("_complete_story", &"road_trace_east", 0)
	_check(CampaignSystem.get_road_trace_count() == 2, "two physical road records verified")
	_check(WorldState.has_flag(&"wrenfield_route_verified"), "verified route consequence unlocked")
	var route_reward_scrap := InventorySystem.get_count(&"scrap")
	CampaignSystem.call("_complete_story", &"road_trace_south", 0)
	_check(CampaignSystem.get_road_trace_count() == 3, "optional third road record remains cataloguable")
	_check(InventorySystem.get_count(&"scrap") == route_reward_scrap, "route-verification scrap reward is granted only once")
	CampaignSystem.call("_complete_story", &"broadcast_relay_west", 0)
	CampaignSystem.call("_complete_story", &"rafi_field_contact", 0)
	_check(WorldState.has_flag(&"rafi_field_defense"), "Rafi field assignment persists")
	CampaignSystem.call("_complete_story", &"broadcast_defense_anchor", 0)
	_check(WorldState.has_flag(CampaignSystem.EAST_DEFENSE_STARTED_FLAG), "east carrier defense starts")
	CampaignSystem.report_field_task(&"east_relay_defense")
	_check(WorldState.has_flag(CampaignSystem.EAST_DEFENSE_COMPLETE_FLAG), "east carrier defense completes")
	_check("Begin" not in CampaignSystem.get_prompt(&"broadcast_defense_anchor", ""), "completed defense prompt is no longer stale")
	CampaignSystem.register_circuit_switch(&"south_line", &"feed", true)
	CampaignSystem.register_circuit_switch(&"south_line", &"ground", false)
	CampaignSystem.register_circuit_switch(&"south_line", &"carrier", true)
	CampaignSystem.set_circuit_switch(&"south_line", &"feed", true)
	CampaignSystem.set_circuit_switch(&"south_line", &"ground", false)
	CampaignSystem.set_circuit_switch(&"south_line", &"carrier", true)
	_check(CampaignSystem.is_circuit_complete(&"south_line"), "south circuit alignment completes")
	_check(CampaignSystem.get_restored_relay_count() == 3, "all three varied relay objectives restore")
	WorldState.mark_defeated(&"RelayHusk")
	CampaignSystem.call("_complete_story", &"broadcast_core_gate", 0)
	await _frames(4)
	_expect_level(CampaignSystem.CHOIR_SCENE)
	_expect_story_node(&"choir_final_console")
	_check(_main.get_current_level().find_child("ChoirWarden", true, false) != null, "Choir Warden boss placed")
	_check_secret_ending_prerequisites()

	# Resolve a complete ending and prove the final UI receives it.
	WorldState.mark_defeated(&"ChoirWarden")
	CampaignSystem.call("_finish_ending", &"archive")
	await _frames(2)
	_check(WorldState.has_flag(&"ending_complete"), "ending state persisted")
	var ending := _main.get_node_or_null("HUD/EndingOverlay")
	_check(ending != null and ending.visible, "ending overlay shown")


func _check_secret_ending_prerequisites() -> void:
	_check(CampaignSystem.has_method("_secret_ending_unlocked"), "secret ending predicate exists")
	if not CampaignSystem.has_method("_secret_ending_unlocked"):
		return
	_check(
		not bool(CampaignSystem.call("_secret_ending_unlocked")),
		"secret ending remains locked before optional prerequisites"
	)
	ArchiveSystem.restore([
		"echo_last_signal", "echo_sun_lid", "echo_mara_repair",
		"echo_clinic_triage", "echo_bus_ledger", "echo_names_wall",
		"echo_relay_warning", "echo_driver_call", "echo_first_tone", "echo_maggie_final",
	])
	_check(
		not bool(CampaignSystem.call("_secret_ending_unlocked")),
		"played Rafi/repeater choices and all traces still require the keepsake"
	)
	WorldState.mark_opened(&"keepsake_shelf_used")
	_check(
		bool(CampaignSystem.call("_secret_ending_unlocked")),
		"secret ending prerequisite wiring resolves structurally"
	)


func _check_intro_progress_guard(hud: Node) -> void:
	_check(hud != null and hud.has_method("_has_meaningful_progress"), "HUD exposes legacy-intro progress guard")
	if hud == null or not hud.has_method("_has_meaningful_progress"):
		return
	var world_before := WorldState.get_state()
	var items_before := InventorySystem.get_items()
	WorldState.clear()
	InventorySystem.set_items({})
	WorldState.set_flag(&"intro_pending")
	_check(not bool(hud.call("_has_meaningful_progress")), "fresh intro-pending run is not mistaken for legacy progress")
	InventorySystem.add_item(&"scrap", 1)
	_check(bool(hud.call("_has_meaningful_progress")), "legacy inventory suppresses the new intro")
	InventorySystem.set_items({})
	WorldState.mark_opened(&"legacy_audit_container")
	_check(bool(hud.call("_has_meaningful_progress")), "legacy world state suppresses the new intro")
	WorldState.restore(world_before)
	InventorySystem.set_items(items_before)


func _check_school_power_coherence() -> void:
	var world_before := WorldState.get_state()
	var items_before := InventorySystem.get_items()

	# Grounding the aerial first removes the unsafe school-feed option and a
	# forged choice index cannot create contradictory flags.
	WorldState.clear()
	WorldState.set_flag(CampaignSystem.IMOGEN_MET_FLAG)
	WorldState.set_flag(CampaignSystem.RAFI_DECLINED_FLAG)
	InventorySystem.set_items({"battery": 1, "scrap": 2})
	var grounded_payload: Dictionary = CampaignSystem.call("_clinic_power_dialogue")
	var grounded_choices: Array = grounded_payload.get("choices", [])
	_check(grounded_choices.size() == 1 and "CLINIC" in String(grounded_choices[0]), "grounded aerial leaves only the clinic-lift route")
	CampaignSystem.call("_complete_story", &"clinic_power_junction", 1)
	_check(not WorldState.has_flag(CampaignSystem.SCHOOL_POWER_FLAG), "grounded aerial cannot be repowered through a stale choice")
	_check(InventorySystem.get_count(&"battery") == 1 and InventorySystem.get_count(&"scrap") == 2, "rejected school route consumes no repair parts")

	# Powering the backfeed first keeps a later decline coherent: local clinic
	# carrier, no Rafi connection, and no claim that the aerial was destroyed.
	WorldState.clear()
	WorldState.set_flag(CampaignSystem.IMOGEN_MET_FLAG)
	InventorySystem.set_items({"battery": 1, "scrap": 2})
	CampaignSystem.call("_complete_story", &"clinic_power_junction", 1)
	CampaignSystem.call("_complete_story", &"bellwether_school_radio", 1)
	_check(WorldState.has_flag(CampaignSystem.SCHOOL_POWER_FLAG) and WorldState.has_flag(CampaignSystem.RAFI_DECLINED_FLAG), "local backfeed outcome persists without connecting Rafi")
	_check(CampaignSystem.get_rafi_status() == "backfeed kept local", "Rafi status describes the coherent local-backfeed outcome")
	_check("LOCAL BACKFEED" in String(CampaignSystem.call("_school_radio_dialogue").get("title", "")), "school follow-up no longer calls a powered backfeed grounded")
	_check("local school backfeed" in String(CampaignSystem.call("_clinic_line_result")), "downstream clinic report reflects the local backfeed")

	WorldState.restore(world_before)
	InventorySystem.set_items(items_before)


func _check_new_encounter_behaviors() -> void:
	var leech_scene := load("res://scenes/enemies/enemy_signal_leech.tscn") as PackedScene
	var stalker_scene := load("res://scenes/enemies/enemy_mimic_stalker.tscn") as PackedScene
	var anchor_scene := load("res://scenes/world/signal_defense_anchor.tscn") as PackedScene
	_check(leech_scene != null and stalker_scene != null and anchor_scene != null, "new encounter scenes instantiate")
	if leech_scene == null or stalker_scene == null or anchor_scene == null:
		return
	var leech := leech_scene.instantiate()
	var stalker := stalker_scene.instantiate()
	_check(leech.has_method("on_signal_burst") and leech.has_method("take_damage"), "Signal Leech exposes ranged-jam combat API")
	_check(stalker.has_method("on_signal_burst") and stalker.has_method("take_damage"), "Mimic Stalker exposes ambush-break combat API")
	leech.free()
	stalker.free()

	var anchor := anchor_scene.instantiate()
	anchor.position = Vector2(10000, 10000)
	add_child(anchor)
	anchor.call("_spawn_wave", 0)
	await _frames(2)
	var first := get_node_or_null("EastDefense_1_1")
	var second := get_node_or_null("EastDefense_1_2")
	_check(first != null and second != null, "defense anchor authors a mixed encounter wave")
	if first != null:
		first.free()
	if second != null:
		second.free()
	anchor.free()


func _check_healing_supplies(player: Node) -> void:
	_check(ItemDatabase.has_item(&"medical_kit"), "medical kit registered in item database")
	_check(player != null and player.has_method("_try_consume_healing"), "field-healing action exists")
	if player == null or not player.has_method("_try_consume_healing"):
		return
	var notices: Array[String] = []
	var collect_notice := func(message: String) -> void: notices.append(message)
	EventBus.notice_posted.connect(collect_notice)

	# A serious wound selects the stronger kit while preserving the ration.
	InventorySystem.set_items({"medical_kit": 1, "canned_food": 1})
	player.call("set_health", 20.0)
	player.call("_try_consume_healing")
	_check(InventorySystem.get_count(&"medical_kit") == 0, "serious wound consumes medical kit")
	_check(InventorySystem.get_count(&"canned_food") == 1, "serious wound preserves smaller ration")
	_check(float(player.call("get_health")) > 20.0, "medical kit restores health")
	_check(not notices.is_empty() and "first-aid kit" in notices[-1], "medical kit posts a clear use notice")

	# A smaller wound conserves the rare kit and uses a ration.
	InventorySystem.set_items({"medical_kit": 1, "canned_food": 1})
	player.call("set_health", 75.0)
	player.call("_try_consume_healing")
	_check(InventorySystem.get_count(&"canned_food") == 0, "small wound consumes ration")
	_check(InventorySystem.get_count(&"medical_kit") == 1, "small wound conserves medical kit")

	# Full health must never waste either item.
	player.call("set_health", 100.0)
	player.call("_try_consume_healing")
	_check(InventorySystem.get_count(&"canned_food") == 0, "full health consumes no ration")
	_check(InventorySystem.get_count(&"medical_kit") == 1, "full health consumes no medical kit")
	_check(not notices.is_empty() and "No supplies used" in notices[-1], "full-health notice explains no item was spent")
	EventBus.notice_posted.disconnect(collect_notice)
	InventorySystem.set_items({})
	player.call("set_health", 100.0)


func _exercise_persistent_choice(
		story_id: StringName,
		accepted_flag: StringName,
		declined_flag: StringName,
		status_method: String,
		accepted_status: String,
		declined_status: String,
		label: String) -> void:
	var before := WorldState.get_state()

	CampaignSystem.call("_complete_story", story_id, 1)
	_check(WorldState.has_flag(declined_flag), label + " decline branch records its state")
	_check(not WorldState.has_flag(accepted_flag), label + " decline branch excludes acceptance")
	_check(String(CampaignSystem.call(status_method)) == declined_status, label + " decline status is player-facing")
	_check_choice_copy(story_id, false, label)
	_check(_saved_world_has_flag(declined_flag), label + " decline state reaches the save file")
	var declined_snapshot := WorldState.get_state()
	WorldState.clear()
	WorldState.restore(declined_snapshot)
	_check(WorldState.has_flag(declined_flag), label + " decline survives state round-trip")
	CampaignSystem.call("_complete_story", story_id, 0)
	_check(not WorldState.has_flag(accepted_flag), label + " decline cannot be reversed")

	WorldState.restore(before)
	CampaignSystem.call("_complete_story", story_id, 0)
	_check(WorldState.has_flag(accepted_flag), label + " accept branch records its state")
	_check(not WorldState.has_flag(declined_flag), label + " accept branch excludes decline")
	_check(String(CampaignSystem.call(status_method)) == accepted_status, label + " accept status is player-facing")
	_check_choice_copy(story_id, true, label)
	_check(_saved_world_has_flag(accepted_flag), label + " accept state reaches the save file")
	var accepted_snapshot := WorldState.get_state()
	WorldState.clear()
	WorldState.restore(accepted_snapshot)
	_check(WorldState.has_flag(accepted_flag), label + " acceptance survives state round-trip")
	CampaignSystem.call("_complete_story", story_id, 1)
	_check(not WorldState.has_flag(declined_flag), label + " acceptance cannot be reversed")


func _check_choice_copy(story_id: StringName, accepted: bool, label: String) -> void:
	if story_id == &"bellwether_school_radio":
		var clinic_result := String(CampaignSystem.call("_clinic_line_result"))
		_check(
			("Rafi" in clinic_result) if accepted else ("grounded" in clinic_result),
			label + " changes the downstream clinic-line report",
		)
	elif story_id == &"long_acre_repeater":
		var payload: Dictionary = CampaignSystem.call("_public_repeater_dialogue")
		var copy := String(payload.get("title", ""))
		if accepted:
			var lines: Array = payload.get("lines", [])
			copy = ""
			for line in lines:
				copy += " " + String(line)
		_check(
			("Rafi" in copy) if accepted else ("ISOLATED" in copy),
			label + " changes the repeater follow-up",
		)


func _check_optional_progress_copy() -> void:
	var visible_lines: Array[String] = []
	for entry in CampaignSystem.get_optional_progress():
		visible_lines.append("%s / %s" % [entry.get("label", ""), entry.get("status", "")])
	var visible := "\n".join(visible_lines)
	_check("88.4 water-works link / CONNECTED" in visible, "optional progress shows Rafi outcome")
	_check("Public warning line / ONLINE" in visible, "optional progress shows repeater outcome")
	_check(not "helped_rafi" in visible and not "public_repeater" in visible, "optional progress hides legacy save ids")


func _saved_world_has_flag(flag: StringName) -> bool:
	if not FileAccess.file_exists(SaveManager.SAVE_PATH):
		return false
	var file := FileAccess.open(SaveManager.SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	var world: Dictionary = parsed.get("world", {})
	var flags: Dictionary = world.get("flags", {})
	return bool(flags.get(String(flag), false))


func _expect_level(expected: String) -> void:
	if _main == null or not _main.has_method("get_current_level_path"):
		_fail("main level API missing")
		return
	_check(_main.get_current_level_path() == expected,
		"expected level %s, got %s" % [expected, _main.get_current_level_path()])


func _check_lighting() -> void:
	var director := _main.get_node_or_null("LightingDirector")
	_check(director != null and director.has_method("get_stats"), "lighting director installed")
	if director == null or not director.has_method("get_stats"):
		return
	var stats: Dictionary = director.call("get_stats")
	_check(int(stats.get("normal_pairs", 0)) > 0, "normal maps paired at runtime")
	_check(
		int(stats.get("polygon_normal_pairs", 0)) > 0,
		"textured Polygon2D normal maps paired at runtime"
	)
	_check(int(stats.get("occluders", 0)) > 0, "shadow occluders generated")
	_check(int(stats.get("level_lights", 0)) > 0, "dynamic level lights generated")
	_check(
		int(stats.get("shadowed_level_lights", 0)) > 0,
		"authored static shadow light selected"
	)
	_check(
		int(stats.get("shadowed_level_lights", 0))
			<= int(director.get("max_shadowed_level_lights")),
		"static shadow light budget respected"
	)
	_check_atlas_normal_pairing(director)
	var player_light := _main.get_node_or_null("Player/__LightingPlayerWarm") as PointLight2D
	_check(player_light != null, "player light generated")
	_check(player_light != null and player_light.shadow_enabled, "player light casts shadows")


func _check_atlas_normal_pairing(director: Node) -> void:
	var diffuse := load("res://assets/processed/decals/asphalt_cracked.png") as Texture2D
	_check(diffuse != null, "atlas normal-pair fixture diffuse exists")
	if diffuse == null:
		return
	var atlas := AtlasTexture.new()
	atlas.atlas = diffuse
	atlas.region = Rect2(Vector2.ZERO, diffuse.get_size())
	var upgraded: Texture2D = director.call("_upgrade_texture", atlas)
	_check(upgraded is CanvasTexture, "atlas normal pair keeps CanvasTexture outermost")
	if upgraded is CanvasTexture:
		var canvas := upgraded as CanvasTexture
		_check(canvas.diffuse_texture is AtlasTexture, "atlas diffuse region preserved")
		_check(canvas.normal_texture is AtlasTexture, "atlas normal region preserved")


func _expect_story_node(story_id: StringName) -> void:
	var level: Node = _main.get_current_level()
	var found := false
	for node in get_tree().get_nodes_in_group("objective_targets"):
		if level.is_ancestor_of(node) and StringName(node.get_meta("story_id", &"")) == story_id:
			found = true
			break
	_check(found, "story node exists: " + String(story_id))


func _frames(count: int) -> void:
	for _i in count:
		await get_tree().process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _fail(message: String) -> void:
	_failures.append(message)
