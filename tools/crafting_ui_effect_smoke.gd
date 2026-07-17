extends Node
## Deterministic player-facing crafting contract test.
##
## Run with:
## godot --headless --path <project> --scene res://tools/crafting_ui_effect_smoke.tscn

const RECIPE_ORDER: Array[StringName] = [
	&"field_dressing", &"lock_shim", &"shielded_fuse", &"signal_decoy",
	&"analogue_isolator", &"circuit_bridge", &"hand_flare",
	&"tripwire_alarm", &"ash_filter", &"wire_splicer", &"relay_tester",
	&"carrier_grounder",
]

const EFFECT_IDS: Array[StringName] = [
	&"analogue_isolator", &"ash_filter", &"carrier_grounder",
	&"circuit_bridge", &"field_dressing", &"hand_flare", &"lock_shim",
	&"relay_tester", &"shielded_fuse", &"signal_decoy",
	&"tripwire_alarm", &"wire_splicer",
]
const LOOT_SCENE := preload("res://scenes/world/loot_container.tscn")
const CIRCUIT_SWITCH_SCENE := preload("res://scenes/world/circuit_switch.tscn")

class FakePlayer:
	extends Node2D
	var health := 50.0
	var max_health := 100.0

	func get_health() -> float:
		return health

	func get_max_health() -> float:
		return max_health

	func set_health(value: float) -> void:
		health = clampf(value, 0.0, max_health)


class FakeCraftTarget:
	extends Node2D
	var accepted_items: Array[StringName] = []
	var apply_succeeds := true
	var applied_items: Array[StringName] = []

	func can_apply_crafted_item(item_id: StringName) -> bool:
		return item_id in accepted_items

	func apply_crafted_item(item_id: StringName, _payload: Dictionary) -> bool:
		applied_items.append(item_id)
		return apply_succeeds


class FakeMain:
	extends Node
	var current_level: Node

	func get_current_level() -> Node:
		return current_level


var _failures: Array[String] = []
var _player: FakePlayer
var _scanner_pulses := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_run")


func _run() -> void:
	_reset_state()
	_player = FakePlayer.new()
	_player.name = "CraftingTestPlayer"
	add_child(_player)
	_player.add_to_group("player")

	_test_effect_catalogue()
	_test_ui_model_and_atomic_craft()
	_test_overlay_contract()
	_test_healing_and_status_effects()
	_test_contextual_tools_and_rollback()
	_test_production_contextual_targets()
	_test_reusable_test_tool()
	_test_deployed_field_items()
	_test_deployments_are_map_local()
	_test_new_run_clears_runtime_effects()
	_test_save_destination_validation()

	_reset_state()
	if _player != null and is_instance_valid(_player):
		_player.free()
	GameManager.set_dialogue_active(false)
	if _failures.is_empty():
		print("CRAFTING_UI_EFFECT_SMOKE: PASS")
		get_tree().quit(0)
		return
	for failure in _failures:
		push_error("CRAFTING_UI_EFFECT_SMOKE: " + failure)
	print("CRAFTING_UI_EFFECT_SMOKE: FAIL (%d)" % _failures.size())
	get_tree().quit(1)


func _test_effect_catalogue() -> void:
	_check(CraftedItemEffects.get_validation_errors().is_empty(), "authored effect definitions validate cleanly")
	_check(CraftedItemEffects.get_effect_item_ids() == EFFECT_IDS, "effect catalogue order is deterministic")
	for item_id in EFFECT_IDS:
		var data := CraftedItemEffects.get_definition(item_id)
		_check(data != null, "effect exists for '%s'" % item_id)
		if data == null:
			continue
		_check(data.action_label.length() >= 4, "effect '%s' has a human action label" % item_id)
		_check(data.use_summary.length() >= 32, "effect '%s' explains its field use" % item_id)
		_check(data.consequence.length() >= 32, "effect '%s' explains its consequence" % item_id)
	_check(CraftedItemEffects.get_definition(&"wire_splicer").consumes_on_use == false, "splicer is a reusable repair tool")
	_check(CraftedItemEffects.get_definition(&"relay_tester").consumes_on_use == false, "relay tester is reusable")


func _test_ui_model_and_atomic_craft() -> void:
	var model := CraftingUIModel.new()
	ArchiveSystem.restore([])
	InventorySystem.set_items({&"clean_cloth": 1, &"resin_tape": 1})
	var rows := model.get_recipe_rows()
	var ids: Array[StringName] = []
	for row in rows:
		ids.append(StringName(row["recipe_id"]))
	_check(ids == RECIPE_ORDER, "UI model preserves authored recipe order")
	var locked := model.get_recipe_row(&"field_dressing")
	_check(locked.state == "locked", "model exposes a knowledge-locked state")
	_check(not String(locked.status_text).is_empty(), "locked method has a player-facing explanation")
	_check((locked.missing_records as PackedStringArray).size() == 1, "locked method names the missing field record")

	ArchiveSystem.restore([&"echo_clinic_triage"])
	var short := model.get_recipe_row(&"field_dressing")
	_check(short.state == "materials", "learned recipe distinguishes missing materials")
	var cloth := _ingredient(short, &"clean_cloth")
	_check(int(cloth.owned) == 1 and int(cloth.needed) == 2 and not bool(cloth.enough), "model reports exact owned/needed counts")

	InventorySystem.set_items({&"clean_cloth": 2, &"resin_tape": 1})
	var ready := model.get_recipe_row(&"field_dressing")
	_check(bool(ready.craftable), "model marks a learned, supplied recipe ready")
	var crafted := CraftingSystem.craft(&"field_dressing", 1, &"field_kit")
	_check(bool(crafted.ok), "craft commits when all inputs and output space are valid")
	_check(InventorySystem.get_count(&"clean_cloth") == 0 and InventorySystem.get_count(&"resin_tape") == 0, "atomic craft spends every ingredient together")
	_check(InventorySystem.get_count(&"field_dressing") == 2, "atomic craft grants the complete authored output")

	InventorySystem.set_items({&"clean_cloth": 2, &"resin_tape": 1, &"field_dressing": 9})
	var before := InventorySystem.get_items()
	var full := CraftingSystem.craft(&"field_dressing", 1, &"field_kit")
	_check(full.code == CraftingSystem.OUTPUT_FULL, "full output stack reports its exact failure")
	_check(InventorySystem.get_items() == before, "failed output-capacity check never partially spends materials")


func _test_overlay_contract() -> void:
	var packed := load("res://scenes/ui/crafting_overlay.tscn") as PackedScene
	_check(packed != null, "workbench scene loads")
	if packed == null:
		return
	var overlay := packed.instantiate() as CraftingOverlay
	add_child(overlay)
	overlay.refresh_for_test()
	_check(overlay.get_visible_recipe_count() == RECIPE_ORDER.size(), "overlay renders all recipe rows")
	_check(overlay.get_selected_recipe_id() == RECIPE_ORDER[0], "overlay selection starts deterministically")
	var craft_button := overlay.get_node("%CraftButton") as Button
	var use_button := overlay.get_node("%UseButton") as Button
	_check(craft_button != null and craft_button.custom_minimum_size.y >= 54.0, "craft control has a touch-safe target")
	_check(use_button != null and use_button.custom_minimum_size.y >= 54.0, "field-use control has a touch-safe target")
	overlay.apply_responsive_layout(Vector2(1280.0, 2770.0), Vector2(390.0, 844.0))
	overlay.refresh_for_test()
	var phone_physical := 390.0 / 1280.0
	var heading := overlay.get_node("OuterMargin/RootLayout/PageScroll/Pages/MethodsPage/Margin/Layout/Heading") as Label
	var top_title := overlay.get_node("OuterMargin/RootLayout/TopStrip/Margin/Row/Title") as Label
	var top_hint := overlay.get_node("OuterMargin/RootLayout/TopStrip/Margin/Row/Hint") as Label
	var first_recipe := (overlay.get_node("%RecipeList") as VBoxContainer).get_child(0) as Button
	_check(heading.get_theme_font_size("font_size") * phone_physical >= 20.0,
		"portrait workbench heading remains physically readable")
	var recipe_physical_size := first_recipe.get_theme_font_size("font_size") * phone_physical
	_check(recipe_physical_size >= 12.0,
		"portrait recipe text remains physically readable (%.1f px)" % recipe_physical_size)
	_check(first_recipe.custom_minimum_size.y * phone_physical >= 48.0,
		"portrait recipe rows remain touch-safe")
	_check(craft_button.custom_minimum_size.y * phone_physical >= 48.0,
		"portrait craft action remains touch-safe")
	_check(top_title.text == "FIELD WORKBENCH  /  REPAIR BOOK" and not top_hint.visible,
		"portrait top strip uses the compact, unclipped wording")
	_check(InputMap.has_action("craft"), "craft input action is registered")
	var has_keyboard := false
	var has_controller := false
	for event in InputMap.action_get_events("craft"):
		if event is InputEventKey and (event as InputEventKey).physical_keycode == KEY_C:
			has_keyboard = true
		elif event is InputEventJoypadButton and (event as InputEventJoypadButton).button_index == JOY_BUTTON_Y:
			has_controller = true
	_check(has_keyboard, "workbench has a keyboard binding")
	_check(has_controller, "workbench has a controller binding")
	GameManager.set_dialogue_active(false)
	overlay.open_workbench()
	_check(overlay.visible and GameManager.dialogue_active, "open workbench takes the shared input lock")
	overlay.close_workbench()
	_check(not overlay.visible and not GameManager.dialogue_active, "close workbench releases its input lock")
	overlay.free()


func _test_healing_and_status_effects() -> void:
	CraftedItemEffects.clear_runtime_state()
	_player.health = 50.0
	InventorySystem.set_items({&"field_dressing": 1})
	var heal := CraftedItemEffects.use_item(&"field_dressing")
	_check(bool(heal.ok), "field dressing can be applied to a wound")
	_check(is_equal_approx(_player.health, 78.0), "field dressing restores its authored health amount")
	_check(InventorySystem.get_count(&"field_dressing") == 0, "field dressing is consumed only after healing succeeds")
	_player.health = 100.0
	InventorySystem.set_items({&"field_dressing": 1})
	var full := CraftedItemEffects.use_item(&"field_dressing")
	_check(full.code == CraftedItemEffects.NOT_NEEDED, "full-health use reports why dressing is unnecessary")
	_check(InventorySystem.get_count(&"field_dressing") == 1, "rejected full-health use preserves the dressing")

	CraftedItemEffects.clear_runtime_state()
	InventorySystem.set_items({&"shielded_fuse": 1})
	var fuse := CraftedItemEffects.use_item(&"shielded_fuse")
	_check(bool(fuse.ok) and CraftedItemEffects.get_receiver_stability() >= 0.29, "shielded fuse stabilises the receiver")
	_check(CraftedItemEffects.get_receiver_energy_cost_multiplier() < 1.0 and CraftedItemEffects.get_receiver_recharge_multiplier() > 1.0, "receiver stability changes both drain and recovery")

	CraftedItemEffects.clear_runtime_state()
	InventorySystem.set_items({&"analogue_isolator": 1})
	var isolator := CraftedItemEffects.use_item(&"analogue_isolator")
	_check(bool(isolator.ok) and CraftedItemEffects.get_receiver_stability() >= 0.54, "analogue isolator supplies the stronger receiver state")

	CraftedItemEffects.clear_runtime_state()
	InventorySystem.set_items({&"ash_filter": 1})
	var filter := CraftedItemEffects.use_item(&"ash_filter")
	_check(bool(filter.ok) and CraftedItemEffects.get_ash_resistance() >= 0.64, "ash filter exposes active protection")
	_check(CraftedItemEffects.get_ash_damage_multiplier() <= 0.36, "ash protection API supplies the reduced damage multiplier")


func _test_contextual_tools_and_rollback() -> void:
	var masking := _make_target(&"craft_access_targets", [&"circuit_bridge"])
	masking.position = Vector2(8.0, 0.0)
	var usable := _make_target(&"craft_access_targets", [&"lock_shim"])
	usable.position = Vector2(42.0, 0.0)
	InventorySystem.set_items({&"lock_shim": 1})
	var selected := CraftedItemEffects.use_item(&"lock_shim")
	_check(bool(selected.ok) and masking.applied_items.is_empty() \
		and usable.applied_items == [&"lock_shim"],
		"auto-targeting skips a nearer incompatible fitting for the closest usable one")
	masking.free()
	usable.free()

	var access := _make_target(&"craft_access_targets", [&"lock_shim"])
	InventorySystem.set_items({&"lock_shim": 1})
	var shim := CraftedItemEffects.use_item(&"lock_shim")
	_check(bool(shim.ok) and access.applied_items == [&"lock_shim"], "lock shim applies to a nearby access target")
	_check(InventorySystem.get_count(&"lock_shim") == 0, "successful shim use consumes exactly one")
	access.free()

	var bridge := _make_target(&"craft_bridge_targets", [&"circuit_bridge"])
	InventorySystem.set_items({&"circuit_bridge": 1})
	var bridged := CraftedItemEffects.use_item(&"circuit_bridge")
	_check(bool(bridged.ok) and bridge.applied_items == [&"circuit_bridge"], "circuit bridge powers a compatible nearby target")
	_check(InventorySystem.get_count(&"circuit_bridge") == 0, "successful circuit bridge is consumed")
	bridge.free()

	CraftedItemEffects.clear_runtime_state()
	var repair := _make_target(&"craft_repair_targets", [&"wire_splicer"])
	InventorySystem.set_items({&"wire_splicer": 1})
	var repaired := CraftedItemEffects.use_item(&"wire_splicer")
	_check(bool(repaired.ok) and repair.applied_items == [&"wire_splicer"], "wire splicer repairs a compatible nearby target")
	_check(InventorySystem.get_count(&"wire_splicer") == 1, "wire splicer remains in the kit after repair")
	repair.free()

	CraftedItemEffects.clear_runtime_state()
	var failing := _make_target(&"craft_access_targets", [&"lock_shim"], false)
	InventorySystem.set_items({&"lock_shim": 1})
	var rejected := CraftedItemEffects.use_item(&"lock_shim", {"target": failing})
	_check(rejected.code == CraftedItemEffects.APPLY_FAILED, "target-side failure is surfaced")
	_check(InventorySystem.get_count(&"lock_shim") == 1, "failed target application rolls the consumed item back atomically")
	failing.free()


func _test_production_contextual_targets() -> void:
	WorldState.clear()
	var secured := LOOT_SCENE.instantiate() as LootContainer
	secured.name = "ProductionShimDrawer"
	secured.persistent_id = &"production_shim_drawer"
	secured.required_service_flag = &"production_service_not_granted"
	secured.position = Vector2(18.0, 0.0)
	add_child(secured)
	_check(secured.is_in_group("craft_access_targets"), "a live secured drawer advertises lock-shim access")
	InventorySystem.set_items({&"lock_shim": 1})
	var shimmed := CraftedItemEffects.use_item(&"lock_shim", {"target": secured})
	_check(bool(shimmed.ok) and WorldState.has_flag(&"crafted_lock_bypass_production_shim_drawer"),
		"lock shim opens a production LootContainer and persists its bypass")
	_check(InventorySystem.get_count(&"lock_shim") == 0, "production drawer consumes one successful shim")
	secured.free()

	WorldState.clear()
	var bridge_switch := CIRCUIT_SWITCH_SCENE.instantiate() as CircuitSwitch
	bridge_switch.circuit_id = &"production_bridge_contract"
	bridge_switch.switch_id = &"dead_feed"
	bridge_switch.required_on = true
	bridge_switch.initial_on = false
	bridge_switch.position = Vector2(18.0, 0.0)
	add_child(bridge_switch)
	_check(bridge_switch.is_in_group("craft_bridge_targets"), "a live circuit cabinet advertises bridge access")
	InventorySystem.set_items({&"circuit_bridge": 1})
	var bridged := CraftedItemEffects.use_item(&"circuit_bridge", {"target": bridge_switch})
	_check(bool(bridged.ok) and CampaignSystem.get_circuit_switch_state(
		bridge_switch.circuit_id, bridge_switch.switch_id, false),
		"circuit bridge aligns a real production cabinet")
	_check(InventorySystem.get_count(&"circuit_bridge") == 0, "production circuit consumes one bridge")
	bridge_switch.free()

	WorldState.clear()
	var repair_switch := CIRCUIT_SWITCH_SCENE.instantiate() as CircuitSwitch
	repair_switch.circuit_id = &"production_repair_contract"
	repair_switch.switch_id = &"torn_ground"
	repair_switch.required_on = false
	repair_switch.initial_on = false
	repair_switch.position = Vector2(18.0, 0.0)
	add_child(repair_switch)
	repair_switch.interact(null)
	_check(repair_switch.is_in_group("craft_repair_targets") \
		and repair_switch.can_apply_crafted_item(&"wire_splicer"),
		"a misthrown production cabinet exposes its torn linkage")
	InventorySystem.set_items({&"wire_splicer": 1})
	var repaired := CraftedItemEffects.use_item(&"wire_splicer", {"target": repair_switch})
	_check(bool(repaired.ok) and not CampaignSystem.get_circuit_switch_state(
		repair_switch.circuit_id, repair_switch.switch_id, true),
		"wire splicer repairs a real production cabinet to its marked state")
	_check(InventorySystem.get_count(&"wire_splicer") == 1, "production splice keeps the reusable tool")
	repair_switch.free()

	CraftedItemEffects.clear_runtime_state()
	InventorySystem.set_items({&"ash_filter": 1})
	_check(bool(CraftedItemEffects.use_item(&"ash_filter").ok), "production ash fixture activates its filter")
	var ash := AshDrift.new()
	ash.exposure_damage = 10.0
	_check(ash.calculate_exposure_damage() <= 3.6,
		"production AshDrift consumes the live filter multiplier when dealing exposure")
	ash.free()


func _test_reusable_test_tool() -> void:
	CraftedItemEffects.clear_runtime_state()
	InventorySystem.set_items({&"relay_tester": 1})
	_scanner_pulses = 0
	EventBus.scanner_pulsed.connect(_on_scanner_pulsed)
	var tested := CraftedItemEffects.use_item(&"relay_tester")
	_check(bool(tested.ok) and _scanner_pulses == 1, "relay tester emits one controlled carrier pulse")
	_check(InventorySystem.get_count(&"relay_tester") == 1, "relay tester is not consumed")
	var cooling := CraftedItemEffects.use_item(&"relay_tester")
	_check(cooling.code == CraftedItemEffects.ON_COOLDOWN, "reusable tester exposes its cooldown instead of double-firing")
	EventBus.scanner_pulsed.disconnect(_on_scanner_pulsed)


func _test_deployed_field_items() -> void:
	var expected := {
		&"signal_decoy": &"signal_decoy",
		&"hand_flare": &"flare",
		&"tripwire_alarm": &"tripwire_alarm",
		&"carrier_grounder": &"carrier_grounder",
	}
	for item_id in expected:
		CraftedItemEffects.clear_runtime_state()
		InventorySystem.set_items({item_id: 1})
		var result := CraftedItemEffects.use_item(item_id, {"world_position": Vector2(24.0, 18.0)})
		_check(bool(result.ok), "deployed item '%s' activates" % item_id)
		_check(InventorySystem.get_count(item_id) == 0, "deployed item '%s' is consumed after placement" % item_id)
		var payload: Dictionary = result.get("payload", {})
		var effect := payload.get("field_effect") as CraftedFieldEffect
		_check(effect != null and effect.effect_kind == expected[item_id], "deployed item '%s' creates its authored world effect" % item_id)
		if item_id == &"hand_flare" and effect != null:
			_check(effect.find_child("PointLight2D", true, false) != null or _has_point_light(effect), "hand flare creates a real local light")
		if effect != null and is_instance_valid(effect):
			effect.free()


func _test_deployments_are_map_local() -> void:
	CraftedItemEffects.clear_runtime_state()
	var main := FakeMain.new()
	main.name = "ProductionMainFixture"
	add_child(main)
	main.add_to_group("main")
	var level := Node2D.new()
	level.name = "SwappableLevel"
	main.add_child(level)
	main.current_level = level

	InventorySystem.set_items({&"signal_decoy": 1})
	var deployed := CraftedItemEffects.use_item(
		&"signal_decoy", {"world_position": Vector2(42.0, 16.0)})
	var effect := (deployed.get("payload", {}) as Dictionary).get("field_effect") as CraftedFieldEffect
	_check(bool(deployed.ok) and effect != null and effect.get_parent() == level,
		"deployed field gear is parented to Main's swappable production level")
	level.free()
	_check(not is_instance_valid(effect), "travelling away frees the old map's deployed field gear")
	main.current_level = null
	main.free()


func _test_new_run_clears_runtime_effects() -> void:
	CraftedItemEffects.clear_runtime_state()
	InventorySystem.set_items({&"shielded_fuse": 1, &"relay_tester": 1})
	_check(bool(CraftedItemEffects.use_item(&"shielded_fuse").ok),
		"runtime reset fixture activates receiver stability")
	_check(bool(CraftedItemEffects.use_item(&"relay_tester").ok),
		"runtime reset fixture starts a reusable-tool cooldown")
	_check(CraftedItemEffects.get_receiver_stability() > 0.0 \
		and CraftedItemEffects.get_cooldown_remaining(&"relay_tester") > 0.0,
		"runtime fixture owns live timers before a new run")
	SaveManager.clear_run_state()
	_check(CraftedItemEffects.get_receiver_stability() == 0.0,
		"New Game clears receiver buffs from the previous run")
	_check(CraftedItemEffects.get_ash_resistance() == 0.0 \
		and CraftedItemEffects.get_cooldown_remaining(&"relay_tester") == 0.0,
		"New Game clears protection and item cooldown timers")


func _test_save_destination_validation() -> void:
	InventorySystem.set_items({&"resin_tape": 2})
	WorldState.clear()
	WorldState.set_flag(&"save_validation_current_run")
	_player.position = Vector2(77.0, 88.0)
	_player.health = 61.0
	var invalid_save := {
		"version": SaveManager.SAVE_VERSION,
		"level": "res://scenes/maps/missing_save_destination.tscn",
		"player": {"x": 900.0, "y": 901.0, "health": 3.0},
		"inventory": {"battery": 9},
		"archive": [],
		"archive_dispositions": {},
		"upgrades": [],
		"world": {"opened": [], "choices": {}, "defeated": [],
			"flags": {"stale_save_world": true}},
		"narrative": {},
	}
	var file := FileAccess.open(SaveManager.SAVE_PATH, FileAccess.WRITE)
	_check(file != null, "invalid-destination save fixture can be written")
	if file == null:
		return
	file.store_string(JSON.stringify(invalid_save))
	file.close()

	_check(not SaveManager.load_game(), "missing save destination is rejected")
	_check(InventorySystem.get_count(&"resin_tape") == 2 \
		and InventorySystem.get_count(&"battery") == 0,
		"rejected save cannot replace the live inventory")
	_check(WorldState.has_flag(&"save_validation_current_run") \
		and not WorldState.has_flag(&"stale_save_world"),
		"rejected save cannot replace the live world state")
	_check(_player.position == Vector2(77.0, 88.0) and is_equal_approx(_player.health, 61.0),
		"rejected save cannot arm a stale player transform")
	var restore_callback := Callable(SaveManager, "_on_level_loaded")
	_check(Dictionary(SaveManager.get("_pending_player")).is_empty() \
		and not EventBus.level_loaded.is_connected(restore_callback),
		"rejected save leaves no pending level callback")

	SaveManager.set("_pending_player", {"x": 444.0, "y": 445.0, "health": 1.0})
	EventBus.level_loaded.connect(restore_callback, CONNECT_ONE_SHOT)
	_player.position = Vector2(12.0, 34.0)
	_player.health = 72.0
	SaveManager.clear_run_state()
	EventBus.level_loaded.emit()
	_check(_player.position == Vector2(12.0, 34.0) and is_equal_approx(_player.health, 72.0),
		"New Game cancels a player restore left by an interrupted load")
	_check(Dictionary(SaveManager.get("_pending_player")).is_empty() \
		and not EventBus.level_loaded.is_connected(restore_callback),
		"New Game clears the pending restore and its one-shot connection")


func _make_target(group_name: StringName, accepted: Array[StringName], succeeds := true) -> FakeCraftTarget:
	var target := FakeCraftTarget.new()
	target.accepted_items = accepted
	target.apply_succeeds = succeeds
	target.position = Vector2(18.0, 0.0)
	add_child(target)
	target.add_to_group(group_name)
	return target


func _ingredient(row: Dictionary, item_id: StringName) -> Dictionary:
	for ingredient in row.get("ingredients", []):
		if StringName(ingredient.get("item_id", &"")) == item_id:
			return ingredient
	return {}


func _has_point_light(node: Node) -> bool:
	for child in node.get_children():
		if child is PointLight2D:
			return true
	return false


func _on_scanner_pulsed(_origin: Vector2, _radius: float) -> void:
	_scanner_pulses += 1


func _reset_state() -> void:
	InventorySystem.set_items({})
	ArchiveSystem.restore([])
	WorldState.clear()
	CraftedItemEffects.clear_runtime_state()
	GameManager.set_paused(false)
	GameManager.set_dialogue_active(false)
	GameManager.set_ending_active(false)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
