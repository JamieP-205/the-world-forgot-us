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
		"res://scenes/world/campaign_interactable.tscn",
		"res://scenes/ui/dialogue_overlay.tscn",
		"res://scenes/ui/archive_overlay.tscn",
		"res://scenes/ui/ending_overlay.tscn",
		"res://resources/echoes/echo_sun_lid.tres",
		"res://resources/echoes/echo_mara_repair.tres",
		"res://resources/echoes/echo_names_wall.tres",
		"res://resources/echoes/echo_first_tone.tres",
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
	_check_lighting()

	# Complete Act I requirements and follow the newly playable north signal.
	InventorySystem.set_items({"scrap": 10, "battery": 5, "canned_food": 3})
	ArchiveSystem.restore(["echo_last_signal"])
	BaseUpgradeSystem.restore(["scanner_coil", "radio_desk"])
	WorldState.set_flag(&"rested_after_radio")
	CampaignSystem.call("_complete_story", &"north_signal", 0)
	await _frames(4)
	_expect_level(CampaignSystem.ASHMERE_SCENE)
	_expect_story_node(&"ashmere_mara_radio")
	_expect_story_node(&"ashmere_gate")

	# Pay off Ellie/Mara and the two anchor memories.
	CampaignSystem.call("_complete_story", &"ashmere_mara_radio", -1)
	ArchiveSystem.restore(["echo_last_signal", "echo_sun_lid", "echo_mara_repair"])
	CampaignSystem.call("_complete_story", &"ashmere_gate", 0)
	await _frames(4)
	_expect_level(CampaignSystem.BROADCAST_SCENE)
	_expect_story_node(&"broadcast_relay_west")
	_expect_story_node(&"broadcast_relay_east")
	_expect_story_node(&"broadcast_relay_south")
	_check(_main.get_current_level().find_child("RelayHusk", true, false) != null, "Relay Husk boss placed")

	# Restore the field, defeat its guardian, and enter the finale.
	WorldState.set_flag(&"relay_west_restored")
	WorldState.set_flag(&"relay_east_restored")
	WorldState.set_flag(&"relay_south_restored")
	WorldState.mark_defeated(&"RelayHusk")
	CampaignSystem.call("_complete_story", &"broadcast_core_gate", 0)
	await _frames(4)
	_expect_level(CampaignSystem.CHOIR_SCENE)
	_expect_story_node(&"choir_final_console")
	_check(_main.get_current_level().find_child("ChoirWarden", true, false) != null, "Choir Warden boss placed")

	# Resolve a complete ending and prove the final UI receives it.
	WorldState.mark_defeated(&"ChoirWarden")
	CampaignSystem.call("_finish_ending", &"archive")
	await _frames(2)
	_check(WorldState.has_flag(&"ending_complete"), "ending state persisted")
	var ending := _main.get_node_or_null("HUD/EndingOverlay")
	_check(ending != null and ending.visible, "ending overlay shown")


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
	_check(int(stats.get("occluders", 0)) > 0, "shadow occluders generated")
	_check(int(stats.get("level_lights", 0)) > 0, "dynamic level lights generated")
	var player_light := _main.get_node_or_null("Player/__LightingPlayerWarm") as PointLight2D
	_check(player_light != null, "player light generated")
	_check(player_light != null and player_light.shadow_enabled, "player light casts shadows")


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
