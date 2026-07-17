extends Node
## Headless production contract for every WorldNPCProfile service.

const Rules = preload("res://scripts/narrative/npc_service_rules.gd")
const SurvivorScene := preload("res://scenes/npcs/world_survivor_npc.tscn")
const CircuitScene := preload("res://scenes/world/circuit_switch.tscn")
const LootScene := preload("res://scenes/world/loot_container.tscn")
const ExitScene := preload("res://scenes/world/scene_exit.tscn")
const MimicScene := preload("res://scenes/enemies/enemy_mimic_stalker.tscn")
const HollowScene := preload("res://scenes/enemies/enemy_hollow.tscn")

class ServicePlayer extends Node2D:
	var health := 40.0
	var full_heals := 0

	func heal_full() -> void:
		health = 100.0
		full_heals += 1

	func get_health() -> float:
		return health

	func set_health(amount: float) -> void:
		health = clampf(amount, 0.0, 100.0)


var _failures: Array[String] = []
var _last_notice := ""


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var world_before := WorldState.get_state()
	var narrative_before := CampaignSystem.get_narrative_state()
	var inventory_before := InventorySystem.get_items()
	WorldState.clear()
	CampaignSystem.clear_narrative_state(false)
	InventorySystem.set_items({})
	EventBus.notice_posted.connect(_on_notice)

	for error in WorldNPCCatalog.validate():
		_fail("catalog: " + error)
	for profile in WorldNPCCatalog.all_profiles():
		_check(Rules.has_production_consumer(profile.service_id),
			"%s service is registered as a production consumer" % profile.npc_id)
		_check(not Rules.effect_notice(profile.service_id).is_empty(),
			"%s service explains its exact consequence" % profile.npc_id)

	var player := ServicePlayer.new()
	add_child(player)
	await _activate_every_service(player)
	_check(player.full_heals == 1 and is_equal_approx(player.health, 100.0),
		"Imogen's field triage calls the player's full heal")

	_check(Rules.gameplay_value(&"scanner_energy", 1.0) < 0.80,
		"Rafi's forecast and Continuity's checksum reduce production receiver cost")
	_check(CampaignSystem.get_evidence_confidence() == 1,
		"Leena's ledger adds one bounded corroboration step")
	_check(Rules.gameplay_value(&"scan_range", 1.0) > 1.20,
		"Leena's ledger and Nia's tracking extend production sweeps")
	_check(Rules.gameplay_value(&"move_speed", 1.0) > 1.11,
		"Owen's survey and Gwen's passage change production movement")
	_check(Rules.gameplay_value(&"damage_taken", 1.0) <= 0.90,
		"Gwen's safe passage reduces incoming production damage")

	await _check_owen_circuit()
	await _check_gwen_cache()
	await _check_mara_bypass()
	await _check_idris_recovery(player)
	await _check_tom_warning()
	await _check_nia_tracking()
	_check_continuity_outcome()

	player.queue_free()
	WorldState.restore(world_before)
	CampaignSystem.restore_narrative_state(narrative_before, SaveManager.SAVE_VERSION)
	InventorySystem.set_items(inventory_before)
	GameManager.set_dialogue_active(false)
	if _failures.is_empty():
		print("NPC_SERVICE_CONTRACT: PASS (10 services)")
		get_tree().quit(0)
		return
	for failure in _failures:
		push_error("NPC_SERVICE_CONTRACT: " + failure)
	print("NPC_SERVICE_CONTRACT: FAIL (%d)" % _failures.size())
	get_tree().quit(1)


func _activate_every_service(player: ServicePlayer) -> void:
	for profile in WorldNPCCatalog.all_profiles():
		WorldState.set_flag(profile.helped_flag)
		var actor := SurvivorScene.instantiate() as WorldSurvivorNPC
		actor.profile = profile
		actor.location_mode = "settlement"
		add_child(actor)
		await get_tree().process_frame
		_last_notice = ""
		actor.use_service(player, false)
		_check(WorldState.has_flag(profile.service_flag),
			"%s conversation activates its durable service flag" % profile.npc_id)
		_check(Rules.effect_notice(profile.service_id) in _last_notice,
			"%s activation notice states the production consequence" % profile.npc_id)
		actor.queue_free()
		await get_tree().process_frame


func _check_owen_circuit() -> void:
	var circuit := CircuitScene.instantiate() as CircuitSwitch
	circuit.circuit_id = &"npc_service_test"
	circuit.switch_id = &"survey_contact"
	circuit.required_on = true
	circuit.initial_on = false
	add_child(circuit)
	await get_tree().process_frame
	_check("Owen's score" in circuit.get_prompt(),
		"Owen marks the required setting on an untouched physical contact")
	circuit.interact(null)
	_check(CampaignSystem.get_circuit_switch_state(
		&"npc_service_test", &"survey_contact", false),
		"Owen's scored contact lands on its authored safe state")
	circuit.queue_free()
	await get_tree().process_frame


func _check_gwen_cache() -> void:
	InventorySystem.set_items({})
	var cache := LootScene.instantiate() as LootContainer
	cache.persistent_id = &"NPCServiceCoachCache"
	cache.loot = {&"scrap": 1}
	cache.service_bonus_flag = &"npc_service_doyle_passages"
	cache.service_bonus = {&"canned_food": 1, &"battery": 1}
	cache.service_bonus_claim_flag = &"npc_service_doyle_cache_test_claimed"
	add_child(cache)
	await get_tree().process_frame
	cache.interact(null)
	_check(InventorySystem.get_count(&"scrap") == 1
		and InventorySystem.get_count(&"canned_food") == 1
		and InventorySystem.get_count(&"battery") == 1,
		"Gwen's labelled coach cache grants its bounded extra parcel")
	_check(WorldState.has_flag(&"npc_service_doyle_cache_test_claimed"),
		"Gwen's extra parcel is one-shot and persistent")
	cache.queue_free()
	await get_tree().process_frame


func _check_mara_bypass() -> void:
	WorldState.set_flag(&"mechanical_bypass_available", false)
	var cache := LootScene.instantiate() as LootContainer
	cache.persistent_id = &"NPCServiceSecuredCache"
	cache.loot = {&"scrap": 1}
	cache.required_service_flag = &"mechanical_bypass_available"
	add_child(cache)
	await get_tree().process_frame
	cache.interact(null)
	_check(not WorldState.is_opened(&"NPCServiceSecuredCache"),
		"Tollard-style secured cache refuses the automatic credential reader")
	WorldState.set_flag(&"mechanical_bypass_available")
	cache.interact(null)
	_check(WorldState.is_opened(&"NPCServiceSecuredCache"),
		"Mara's numbered bypass opens the secured cache in production")
	cache.queue_free()
	await get_tree().process_frame


func _check_idris_recovery(player: ServicePlayer) -> void:
	var exit := ExitScene.instantiate() as SceneExit
	exit.target_scene_path = GameManager.BASE_SCENE_PATH
	add_child(exit)
	await get_tree().process_frame
	player.health = 40.0
	var restored := exit.apply_return_services(player)
	_check(is_equal_approx(restored, 25.0) and is_equal_approx(player.health, 65.0),
		"Idris's shelter repair restores exactly 25 health on a wounded return")
	exit.queue_free()
	await get_tree().process_frame


func _check_tom_warning() -> void:
	var mimic := MimicScene.instantiate() as EnemyMimicStalker
	add_child(mimic)
	await get_tree().process_frame
	_check(mimic.get_effective_windup_duration() > mimic.windup_duration * 1.44,
		"Tom's warning line lengthens the Mimic's actual lunge wind-up")
	var visual := mimic.get_node("Visual") as AnimatedSprite2D
	_check(visual.modulate.a >= 0.36,
		"Tom's warning line keeps a dormant Mimic visibly readable")
	mimic.queue_free()
	await get_tree().process_frame


func _check_nia_tracking() -> void:
	var hollow := HollowScene.instantiate() as EnemyHollow
	add_child(hollow)
	await get_tree().process_frame
	_check(hollow.is_in_group("scannables"),
		"Nia's Hollow tracking puts ordinary Hollows in receiver sweeps")
	_check(hollow.get_effective_detection_radius() < hollow.detection_radius
		and hollow.get_effective_contact_damage() < hollow.contact_damage,
		"Nia's grounded lure reduces Hollow detection and contact damage")
	var feedback := hollow.get_scanner_feedback(Vector2.ZERO)
	_check("Nia" in String(feedback.get("noise", "")),
		"tracked Hollow receiver feedback names the source of the warning")
	hollow.queue_free()
	await get_tree().process_frame


func _check_continuity_outcome() -> void:
	var lines := CampaignSystem.get_npc_service_ending_lines()
	_check(lines.size() == 2,
		"Leena's ledger and Continuity's checksum both reach the ending record")
	_check("checksum" in " ".join(lines).to_lower(),
		"Continuity's stored checksum produces a visible final incident finding")


func _on_notice(text: String) -> void:
	_last_notice = text


func _check(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _fail(message: String) -> void:
	_failures.append(message)
