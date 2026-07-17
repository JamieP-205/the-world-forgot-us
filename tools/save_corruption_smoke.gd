extends Node
## Corruption-recovery contract for SaveManager.
##
## A locally edited or otherwise malformed save must never crash the load path
## or half-apply itself to the live run, and a well-formed save must still
## round-trip every persisted system. Run with an isolated APPDATA directory:
## godot --headless --path <project> --scene res://tools/save_corruption_smoke.tscn

const VALID_LEVEL := "res://scenes/maps/test_map.tscn"

var _failures: Array[String] = []


## Stands in for the Main root so save_game() can record a loadable level path
## without booting the whole game world in the headless harness.
class StubMain extends Node:
	func get_current_level_path() -> String:
		return "res://scenes/maps/test_map.tscn"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_run")


func _run() -> void:
	_check_rejects_malformed_top_level()
	_check_rejects_unparseable_payload()
	_check_survives_malformed_nested_fields()
	_check_valid_save_round_trips()

	SaveManager.clear_run_state()

	if _failures.is_empty():
		print("SAVE_CORRUPTION_SMOKE: PASS")
		get_tree().quit(0)
	else:
		for failure in _failures:
			push_error("SAVE_CORRUPTION_SMOKE: " + failure)
		print("SAVE_CORRUPTION_SMOKE: FAIL (%d)" % _failures.size())
		get_tree().quit(1)


## A save whose top-level field carries the wrong container type must be
## rejected atomically, before any live system is touched.
func _check_rejects_malformed_top_level() -> void:
	var cases: Array = [
		{"label": "inventory as number", "field": "inventory", "value": 5},
		{"label": "inventory as string", "field": "inventory", "value": "corrupt"},
		{"label": "inventory as array", "field": "inventory", "value": []},
		{"label": "archive as dictionary", "field": "archive", "value": {}},
		{"label": "archive_dispositions as array", "field": "archive_dispositions", "value": []},
		{"label": "upgrades as dictionary", "field": "upgrades", "value": {}},
		{"label": "world as array", "field": "world", "value": []},
		{"label": "narrative as array", "field": "narrative", "value": []},
		{"label": "player as array", "field": "player", "value": []},
		{"label": "version as dictionary", "field": "version", "value": {}},
	]
	for entry in cases:
		_seed_sentinel()
		var data := _valid_min_save()
		data[entry["field"]] = entry["value"]
		_write_save(JSON.stringify(data))
		var ok: bool = SaveManager.load_game()
		_check(not ok, "malformed %s is rejected" % entry["label"])
		_check_sentinel_intact("after rejecting %s" % entry["label"])


## Text that is not a JSON object at all must be rejected the same way.
func _check_rejects_unparseable_payload() -> void:
	var cases: Dictionary = {
		"unparseable garbage": "this is not json {{{",
		"top-level array": "[]",
		"top-level number": "42",
		"top-level string": "\"hello\"",
		"empty file": "",
	}
	for label in cases:
		_seed_sentinel()
		_write_save(cases[label])
		var ok: bool = SaveManager.load_game()
		_check(not ok, "%s is rejected" % label)
		_check_sentinel_intact("after rejecting %s" % label)


## A well-formed top-level payload with a malformed nested field must recover
## best-effort: skip the bad field, never crash the restore.
func _check_survives_malformed_nested_fields() -> void:
	var cases: Array = [
		{"label": "world.choices as array", "field": "world", "value": {"choices": []}},
		{"label": "world.flags as string", "field": "world", "value": {"flags": "corrupt"}},
		{"label": "world.opened as number", "field": "world", "value": {"opened": 3}},
		{"label": "world.defeated as number", "field": "world", "value": {"defeated": 3}},
		{"label": "world.opened elements as numbers", "field": "world", "value": {"opened": [1, 2, 3]}},
		{"label": "narrative.npc_states as array", "field": "narrative", "value": {"npc_states": []}},
		{"label": "narrative.hollow_outcomes as array", "field": "narrative", "value": {"hollow_outcomes": []}},
		{"label": "narrative.mission_states as array", "field": "narrative", "value": {"mission_states": []}},
		{"label": "narrative.route_anchor as dictionary", "field": "narrative", "value": {"route_anchor": {}}},
		{"label": "narrative.rescued_npcs as number", "field": "narrative", "value": {"rescued_npcs": 1}},
		{"label": "narrative.fed_trace_ids as number", "field": "narrative", "value": {"fed_trace_ids": 1}},
		{"label": "narrative.completed_missions as number", "field": "narrative", "value": {"completed_missions": 1}},
		{"label": "narrative.evidence_ids as number", "field": "narrative", "value": {"evidence_ids": 1}},
	]
	for entry in cases:
		SaveManager.clear_run_state()
		var data := _valid_min_save()
		data[entry["field"]] = entry["value"]
		_write_save(JSON.stringify(data))
		var ok: bool = SaveManager.load_game()
		_check(ok, "malformed %s recovers without crashing" % entry["label"])


## A well-formed save must restore every persisted system exactly.
func _check_valid_save_round_trips() -> void:
	SaveManager.clear_run_state()
	var stub := StubMain.new()
	stub.add_to_group("main")
	add_child(stub)

	InventorySystem.set_items({"scrap": 5, "battery": 2})
	var scrap_expected := InventorySystem.get_count(&"scrap")
	var battery_expected := InventorySystem.get_count(&"battery")
	ArchiveSystem.restore(["echo_sun_lid", "echo_mara_repair"])
	var echo_count_expected := ArchiveSystem.get_count()
	BaseUpgradeSystem.restore(["scanner_coil", "radio_desk"])
	WorldState.set_flag(&"mara_contacted")
	WorldState.set_flag(&"salvage_runs", 3)
	WorldState.mark_opened(&"test_crate")
	WorldState.mark_choice(&"test_group", &"test_option")
	WorldState.mark_defeated(&"RelayHusk")
	CampaignSystem.commit_route_anchor(&"clinic", false)
	CampaignSystem.commit_network_strategy(&"restore", false)
	CampaignSystem.record_narrative_evidence(&"R04", false)
	CampaignSystem.rescue_narrative_npc(&"imogen", false)
	CampaignSystem.record_trace_fed(&"echo_mara_repair", true, false)
	CampaignSystem.set_hollow_policy(&"kill", false)

	_check(SaveManager.save_game(""), "valid state writes a save file")

	InventorySystem.set_items({})
	ArchiveSystem.restore([])
	BaseUpgradeSystem.restore([])
	WorldState.clear()
	CampaignSystem.clear_narrative_state(false)
	_check(InventorySystem.get_count(&"scrap") == 0, "inventory clears before reload")
	_check(CampaignSystem.get_active_route_id() == &"", "route clears before reload")

	_check(SaveManager.load_game(), "valid save reloads")

	_check(InventorySystem.get_count(&"scrap") == scrap_expected, "scrap count round-trips")
	_check(InventorySystem.get_count(&"battery") == battery_expected, "battery count round-trips")
	_check(ArchiveSystem.has_echo(&"echo_sun_lid"), "recovered echo round-trips")
	_check(ArchiveSystem.get_count() == echo_count_expected, "recovered echo count round-trips")
	_check(BaseUpgradeSystem.is_built(&"scanner_coil"), "scanner upgrade round-trips")
	_check(BaseUpgradeSystem.is_built(&"radio_desk"), "radio upgrade round-trips")
	_check(WorldState.has_flag(&"mara_contacted"), "boolean world flag round-trips")
	_check(int(WorldState.get_flag(&"salvage_runs", 0)) == 3, "numeric world flag round-trips")
	_check(WorldState.is_opened(&"test_crate"), "opened container round-trips")
	_check(WorldState.chosen_option(&"test_group") == "test_option", "either/or choice round-trips")
	_check(WorldState.is_defeated(&"RelayHusk"), "defeated enemy round-trips")
	_check(CampaignSystem.get_active_route_id() == &"clinic_restore", "committed route round-trips")
	_check("R04" in CampaignSystem.get_narrative_state().get("evidence_ids", []), "narrative evidence round-trips")
	_check(CampaignSystem.get_narrative_npc_state(&"imogen") == &"rescued", "npc rescue state round-trips")
	_check(CampaignSystem.get_fed_trace_count() == 1, "fed trace round-trips")
	_check(CampaignSystem.get_hollow_policy() == &"kill", "hollow policy round-trips")

	stub.free()


func _valid_min_save() -> Dictionary:
	return {"version": SaveManager.SAVE_VERSION, "level": VALID_LEVEL}


func _seed_sentinel() -> void:
	SaveManager.clear_run_state()
	InventorySystem.set_items({"scrap": 1})
	WorldState.set_flag(&"sentinel_flag")


func _check_sentinel_intact(context: String) -> void:
	_check(InventorySystem.get_count(&"scrap") == 1, "inventory untouched %s" % context)
	_check(WorldState.has_flag(&"sentinel_flag"), "world flags untouched %s" % context)


func _write_save(text: String) -> void:
	var file := FileAccess.open(SaveManager.SAVE_PATH, FileAccess.WRITE)
	if file == null:
		_fail("could not open save file for writing")
		return
	file.store_string(text)
	file.close()


func _check(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _fail(message: String) -> void:
	_failures.append(message)
