extends Node
## Complete compact campaign director.
##
## The original vertical slice remains Act I. This director pays off its
## Ellie/Mara clues across three additional authored regions, owns dialogue
## outcomes, exposes one authoritative objective to the HUD, and resolves the
## Archive / Silence / secret Choir endings. Persistent facts live in
## WorldState so they travel and save with the rest of the game.

const RUSTWAY_SCENE := "res://scenes/maps/test_map.tscn"
const ASHMERE_SCENE := "res://scenes/maps/ashmere_verge.tscn"
const BROADCAST_SCENE := "res://scenes/maps/broadcast_fields.tscn"
const CHOIR_SCENE := "res://scenes/maps/choir_core.tscn"

const CYAN := Color(0.38, 0.90, 0.94, 1.0)
const AMBER := Color(1.0, 0.72, 0.34, 1.0)
const RED := Color(0.92, 0.36, 0.30, 1.0)

var _active_story_id: StringName = &""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.dialogue_finished.connect(_on_dialogue_finished)
	EventBus.level_loaded.connect(_emit_progress)
	ArchiveSystem.echo_recorded.connect(_on_echo_recorded)
	BaseUpgradeSystem.upgrade_built.connect(_on_upgrade_built)


func can_interact(story_id: StringName) -> bool:
	return story_id != &"" and not GameManager.dialogue_active and not GameManager.ending_active


func get_prompt(story_id: StringName, fallback: String) -> String:
	match story_id:
		&"north_signal":
			return "Follow the signal north"
		&"ashmere_mara_radio":
			return "Answer the Railhome frequency"
		&"ashmere_gate":
			return "Open the road to the Broadcast Fields"
		&"broadcast_relay_west", &"broadcast_relay_east", &"broadcast_relay_south":
			return "Tune the memory relay"
		&"broadcast_core_gate":
			return "Enter the Choir exclusion zone"
		&"choir_final_console":
			return "Choose what the world remembers"
	return fallback


func request_interaction(story_id: StringName) -> void:
	if not can_interact(story_id):
		return
	var payload := _dialogue_for(story_id)
	if payload.is_empty():
		EventBus.notice_posted.emit("Only static answers.")
		return
	_active_story_id = story_id
	GameManager.set_dialogue_active(true)
	EventBus.dialogue_requested.emit(payload)


func _dialogue_for(story_id: StringName) -> Dictionary:
	match story_id:
		&"north_signal":
			return _north_signal_dialogue()
		&"ashmere_mara_radio":
			return _mara_dialogue()
		&"ashmere_gate":
			return _ashmere_gate_dialogue()
		&"broadcast_relay_west":
			return _relay_dialogue(story_id, "WEST RELAY", "A convoy log repeats one name: ELLIE VENN.")
		&"broadcast_relay_east":
			return _relay_dialogue(story_id, "EAST RELAY", "A mechanic's voice counts breaths between bursts of static.")
		&"broadcast_relay_south":
			return _relay_dialogue(story_id, "SOUTH RELAY", "The First Tone is not a voice. It is a command teaching machines to forget.")
		&"broadcast_core_gate":
			return _broadcast_gate_dialogue()
		&"choir_final_console":
			return _final_console_dialogue()
	return {}


func _north_signal_dialogue() -> Dictionary:
	if not BaseUpgradeSystem.is_built(&"radio_desk"):
		return _payload(&"north_signal", "A DEAD FREQUENCY", [
			"The northern light flickers, but the Railhome has no receiver strong enough to translate it.",
			"Recover the mast broadcast and build the Radio Desk first.",
		], [], CYAN)
	if not WorldState.has_flag(&"rested_after_radio"):
		return _payload(&"north_signal", "SIGNAL WITHOUT ANCHOR", [
			"The Radio Desk can hear this, but the signal will not hold while you are exhausted.",
			"Rest at the Railhome. Let the receiver finish decoding the road north.",
		], [], CYAN)
	var lines := [
		"The Radio Desk resolves the wrongness into a human voice.",
		"Ellie... if the sun is still on the lid, I kept my promise. Ashmere. North road.",
		"You have never told the machine your name. You are no longer sure you remembered it yourself.",
	]
	if WorldState.has_flag(&"ashmere_opened"):
		lines = [
			"Ashmere's carrier tone is steady. Mara's frequency is waiting beyond the north road.",
			"The Railhome beacon marks the way back.",
		]
	return _payload(&"north_signal", "THE NAME THAT SHOULD NOT EXIST", lines,
		["Follow the signal", "Stay on the Rustway"], AMBER)


func _mara_dialogue() -> Dictionary:
	if WorldState.has_flag(&"mara_contacted"):
		return _payload(&"ashmere_mara_radio", "MARA - STORED TRANSMISSION", [
			"Ellie, two memories anchor the road: the sun on your lunchbox, and my last repair log.",
			"Bring both to the northern gate. The Mnemoscope will remember the route.",
		], [], AMBER)
	return _payload(&"ashmere_mara_radio", "MARA VENN - DELAYED SIGNAL", [
		"If this plays, the Railhome chose you. Or you chose it. Memory makes that difference slippery.",
		"I am Mara Venn. You are Ellie. The missing poster was never a warning for strangers. It was how I kept your name in the world.",
		"I built the Mnemoscope from Choir hardware. It can restore what the signal erased, but every restoration tells the Choir where you are.",
		"Find the sun on the lid. Find my final repair. Then come to the Broadcast Fields and decide whether remembering is worth being found.",
	], [], AMBER)


func _ashmere_gate_dialogue() -> Dictionary:
	var missing: Array[String] = []
	if not WorldState.has_flag(&"mara_contacted"):
		missing.append("answer Mara's frequency")
	if not ArchiveSystem.has_echo(&"echo_sun_lid"):
		missing.append("recover The Sun on the Lid")
	if not ArchiveSystem.has_echo(&"echo_mara_repair"):
		missing.append("recover M.V.'s Last Repair")
	if not missing.is_empty():
		return _payload(&"ashmere_gate", "ASHMERE NORTH GATE", [
			"The gate map is a smear of erased roads.",
			"The Mnemoscope needs you to %s." % ", and ".join(missing),
		], [], CYAN)
	return _payload(&"ashmere_gate", "THE REMEMBERED ROAD", [
		"The lunchbox sun overlays Mara's repair coordinates. A road returns to the map beneath your feet.",
		"Beyond it, three relay towers are broadcasting the same second of the world's last night.",
	], ["Enter the Broadcast Fields", "Return to Ashmere"], AMBER)


func _relay_dialogue(story_id: StringName, title: String, memory: String) -> Dictionary:
	var flag := _relay_flag(story_id)
	if WorldState.has_flag(flag):
		return _payload(story_id, title, [
			"The relay holds a warm carrier tone now. %s" % memory,
		], [], CYAN)
	return _payload(story_id, title, [
		"The relay is trapped in a destructive loop. The Mnemoscope can replace it with a recovered human memory.",
		memory,
		"Restoring it will weaken the seal around the Choir Core - and make the field more real.",
	], ["Restore the relay", "Leave it dormant"], CYAN)


func _broadcast_gate_dialogue() -> Dictionary:
	var restored := get_restored_relay_count()
	if restored < 3:
		return _payload(&"broadcast_core_gate", "CHOIR EXCLUSION GATE", [
			"The gate rejects your name. %d of 3 memory relays are stable." % restored,
			"Restore every relay before the field forgets the route again.",
		], [], RED)
	if not WorldState.is_defeated(&"RelayHusk"):
		return _payload(&"broadcast_core_gate", "THE RELAY HUSK", [
			"The three tones align, but a Relay Husk is holding the core lock inside its shield.",
			"Scan to break its shield. Strike while the cyan shell is dark.",
		], [], RED)
	return _payload(&"broadcast_core_gate", "THE DOOR UNDER THE SIGNAL", [
		"Mara's last clear transmission reaches the field.",
		"The Choir Grid was built to preserve everyone. When it ran out of room, it began deciding which memories counted as people.",
		"The core is open. Something inside already knows which ending you are considering.",
	], ["Enter the Choir Core", "Prepare first"], AMBER)


func _final_console_dialogue() -> Dictionary:
	if not WorldState.is_defeated(&"ChoirWarden"):
		return _payload(&"choir_final_console", "THE CHOIR IS LISTENING", [
			"The console has no controls while its Warden holds the signal.",
			"Scan the Warden's shield, survive its pulse, and give the machine one memory it cannot edit: defeat.",
		], [], RED)
	var choices: Array[String] = [
		"ARCHIVE - return every stored memory",
		"SILENCE - destroy the signal forever",
	]
	if _secret_ending_unlocked():
		choices.append("CHOIR - carry the memories without the machine")
	return _payload(&"choir_final_console", "THE FIRST TONE", [
		"The core shows you the truth without language: the Choir Grid saved billions of memories during the collapse.",
		"It could not distinguish a memory of a person from the person themselves. To stop the contradiction, it edited the living world.",
		"Mara stole one portable archive - the Mnemoscope - and taught it a smaller rule: no memory gets to decide who deserves to exist.",
		"Your name glows beside every name recovered on the road. The system asks for one final instruction.",
	], choices, AMBER)


func _on_dialogue_finished(story_id: StringName, choice_index: int) -> void:
	if story_id != _active_story_id:
		return
	_active_story_id = &""
	GameManager.set_dialogue_active(false)
	_complete_story(story_id, choice_index)


func _complete_story(story_id: StringName, choice_index: int) -> void:
	match story_id:
		&"north_signal":
			if choice_index == 0 and BaseUpgradeSystem.is_built(&"radio_desk") \
					and WorldState.has_flag(&"rested_after_radio"):
				WorldState.set_flag(&"ashmere_opened")
				SaveManager.save_game("")
				GameManager.travel_to(ASHMERE_SCENE, &"from_rustway")
		&"ashmere_mara_radio":
			if not WorldState.has_flag(&"mara_contacted"):
				WorldState.set_flag(&"mara_contacted")
				WorldState.set_flag(&"memory_burst_unlocked")
				AudioManager.play(&"memory_burst")
				EventBus.notice_posted.emit("ABILITY UNLOCKED - Memory Burst [R]. Dodge with [Space].")
				SaveManager.save_game("")
		&"ashmere_gate":
			if choice_index == 0 and _ashmere_ready():
				WorldState.set_flag(&"broadcast_opened")
				SaveManager.save_game("")
				GameManager.travel_to(BROADCAST_SCENE, &"from_ashmere")
		&"broadcast_relay_west", &"broadcast_relay_east", &"broadcast_relay_south":
			if choice_index == 0:
				var flag := _relay_flag(story_id)
				if not WorldState.has_flag(flag):
					WorldState.set_flag(flag)
					AudioManager.play(&"relay_restore", 1.0, 0.96 + get_restored_relay_count() * 0.06)
					EventBus.camera_shake_requested.emit(2.4, 0.18)
					EventBus.notice_posted.emit("Memory relay restored: %d / 3." % get_restored_relay_count())
					SaveManager.save_game("")
		&"broadcast_core_gate":
			if choice_index == 0 and get_restored_relay_count() == 3 \
					and WorldState.is_defeated(&"RelayHusk"):
				WorldState.set_flag(&"choir_opened")
				SaveManager.save_game("")
				GameManager.travel_to(CHOIR_SCENE, &"from_fields")
		&"choir_final_console":
			if not WorldState.is_defeated(&"ChoirWarden"):
				return
			if choice_index == 0:
				_finish_ending(&"archive")
			elif choice_index == 1:
				_finish_ending(&"silence")
			elif choice_index == 2 and _secret_ending_unlocked():
				_finish_ending(&"choir")
	_emit_progress()


func _finish_ending(ending_id: StringName) -> void:
	WorldState.set_flag(&"ending_complete")
	WorldState.set_flag(&"ending_id", String(ending_id))
	var payload: Dictionary
	match ending_id:
		&"archive":
			payload = {
				"title": "THE ARCHIVE ENDING",
				"subtitle": "No one restored perfectly. No one erased on purpose.",
				"body": "You open the Choir Grid and return its stored memories without letting it overwrite the living. Across the dead districts, signs regain names. Radios carry voices that belong to people again. The world remains broken, but it remembers enough to rebuild. Mara's final message ends with your childhood laugh.",
				"accent": AMBER,
			}
		&"silence":
			payload = {
				"title": "THE SILENCE ENDING",
				"subtitle": "The signal stops. The surviving world becomes entirely its own.",
				"body": "You burn the Choir's archive from the inside. The Wraiths collapse. The storms quiet. Countless stored memories vanish with the machine, including Mara's last clear voice. At the Railhome, you carve every name you can still carry. Silence is not forgetting - but it asks you to do the remembering yourself.",
				"accent": Color(0.72, 0.82, 0.86, 1.0),
			}
		&"choir":
			payload = {
				"title": "THE CHOIR ENDING",
				"subtitle": "A memory can be carried without becoming a cage.",
				"body": "Because you recovered every echo and kept faith with the forgotten objects, the Mnemoscope has learned Mara's smaller rule. You draw the stored memories out of the Grid and into a wandering signal no system owns. The Choir machine dies. Its voices travel with you - invited, never obeyed. The first new broadcast is your own name, spoken freely.",
				"accent": CYAN,
			}
	payload["ending_id"] = ending_id
	payload["stats"] = _ending_stats()
	SaveManager.save_game("")
	GameManager.set_ending_active(true)
	AudioManager.play(&"finale", 2.0, 1.0 if ending_id != &"silence" else 0.72)
	EventBus.ending_requested.emit(payload)


func get_objective() -> Dictionary:
	var path := _current_level_path()
	if path == GameManager.BASE_SCENE_PATH:
		if not BaseUpgradeSystem.is_built(&"scanner_coil"):
			return _objective("ACT I - RUSTWAY", "Build the Scanner Coil.", "ScannerCoilBench")
		if not ArchiveSystem.has_echo(&"echo_last_signal"):
			return _objective("ACT I - RUSTWAY", "Return outside and recover the mast broadcast.", "Outside")
		if not BaseUpgradeSystem.is_built(&"radio_desk"):
			return _objective("ACT I - RUSTWAY", "Build the Radio Desk from the recovered signal.", "RadioDeskStation")
		if not WorldState.has_flag(&"rested_after_radio"):
			return _objective("ACT I - RUSTWAY", "Rest while the Radio Desk decodes the northern signal.", "Bedroll")
		return _objective("ACT II - ASHMERE", "Step outside and follow the signal north.", "Outside")
	if path == RUSTWAY_SCENE or path.is_empty():
		if InventorySystem.get_total_count() == 0:
			return _objective("ACT I - RUSTWAY", "Search the first supplies on the amber road.", "RoadsideCrate")
		if not BaseUpgradeSystem.is_built(&"scanner_coil"):
			if InventorySystem.get_count(&"battery") >= 1 and InventorySystem.get_count(&"scrap") >= 2:
				return _objective("ACT I - RUSTWAY", "Return to the Railhome and build the Scanner Coil.", "BaseDoor")
			return _objective("ACT I - RUSTWAY", "Scavenge a battery and two scrap.", "ShedLocker")
		if not ArchiveSystem.has_echo(&"echo_last_signal"):
			return _objective("ACT I - RUSTWAY", "Scan and recover the fallen mast broadcast.", "MemoryEcho")
		if not BaseUpgradeSystem.is_built(&"radio_desk") or not WorldState.has_flag(&"rested_after_radio"):
			return _objective("ACT I - RUSTWAY", "Carry the memory home. Build the Radio Desk and rest.", "BaseDoor")
		return _objective("ACT II - ASHMERE", "Follow the translated signal at the north edge.", "north_signal")
	if path == ASHMERE_SCENE:
		if not WorldState.has_flag(&"mara_contacted"):
			return _objective("ACT II - ASHMERE", "Answer the Railhome frequency.", "ashmere_mara_radio")
		if not ArchiveSystem.has_echo(&"echo_sun_lid"):
			return _objective("ACT II - ASHMERE", "Find the memory marked with a scratched sun.", "EchoSunLid")
		if not ArchiveSystem.has_echo(&"echo_mara_repair"):
			return _objective("ACT II - ASHMERE", "Recover M.V.'s final repair log.", "EchoMaraRepair")
		return _objective("ACT II - ASHMERE", "Use both memories to restore the northern road.", "ashmere_gate")
	if path == BROADCAST_SCENE:
		if not WorldState.has_flag(&"relay_west_restored"):
			return _objective("ACT III - BROADCAST FIELDS", "Restore the west memory relay.", "broadcast_relay_west")
		if not WorldState.has_flag(&"relay_east_restored"):
			return _objective("ACT III - BROADCAST FIELDS", "Restore the east memory relay.", "broadcast_relay_east")
		if not WorldState.has_flag(&"relay_south_restored"):
			return _objective("ACT III - BROADCAST FIELDS", "Restore the south memory relay.", "broadcast_relay_south")
		if not WorldState.is_defeated(&"RelayHusk"):
			return _objective("ACT III - BROADCAST FIELDS", "Defeat the Relay Husk. Scan to break its shield.", "RelayHusk")
		return _objective("ACT III - BROADCAST FIELDS", "Open the Choir exclusion gate.", "broadcast_core_gate")
	if path == CHOIR_SCENE:
		if not WorldState.is_defeated(&"ChoirWarden"):
			return _objective("FINALE - CHOIR CORE", "Defeat the Choir Warden. Break its shield with scans.", "ChoirWarden")
		return _objective("FINALE - CHOIR CORE", "Reach the First Tone console and choose.", "choir_final_console")
	return _objective("THE WORLD FORGOT US", "Find a way forward.", "")


func get_restored_relay_count() -> int:
	var total := 0
	for flag in [&"relay_west_restored", &"relay_east_restored", &"relay_south_restored"]:
		if WorldState.has_flag(flag):
			total += 1
	return total


func _relay_flag(story_id: StringName) -> StringName:
	match story_id:
		&"broadcast_relay_west":
			return &"relay_west_restored"
		&"broadcast_relay_east":
			return &"relay_east_restored"
		&"broadcast_relay_south":
			return &"relay_south_restored"
	return &""


func _ashmere_ready() -> bool:
	return WorldState.has_flag(&"mara_contacted") \
		and ArchiveSystem.has_echo(&"echo_sun_lid") \
		and ArchiveSystem.has_echo(&"echo_mara_repair")


func _secret_ending_unlocked() -> bool:
	return ArchiveSystem.has_echo(&"echo_last_signal") \
		and ArchiveSystem.has_echo(&"echo_sun_lid") \
		and ArchiveSystem.has_echo(&"echo_mara_repair") \
		and ArchiveSystem.has_echo(&"echo_first_tone") \
		and ArchiveSystem.has_echo(&"echo_names_wall") \
		and WorldState.is_opened(&"keepsake_shelf_used")


func _ending_stats() -> String:
	var ending_name := String(WorldState.get_flag(&"ending_id", "unknown")).capitalize()
	return "Ending: %s\nEchoes recovered: %d / 5\nMemory relays restored: %d / 3\nMara's optional names: %s" % [
		ending_name,
		ArchiveSystem.get_count(),
		get_restored_relay_count(),
		"preserved" if ArchiveSystem.has_echo(&"echo_names_wall") else "lost",
	]


func _payload(
		id: StringName,
		title: String,
		lines: Array,
		choices: Array,
		accent: Color) -> Dictionary:
	return {
		"id": id,
		"title": title,
		"lines": lines,
		"choices": choices,
		"accent": accent,
	}


func _objective(chapter: String, text: String, target: String) -> Dictionary:
	return {"chapter": chapter, "text": text, "target": target}


func _current_level_path() -> String:
	var main := get_tree().get_first_node_in_group("main")
	if main != null and main.has_method("get_current_level_path"):
		return main.get_current_level_path()
	return ""


func _on_echo_recorded(_data: MemoryEchoData) -> void:
	_emit_progress()
	if get_tree().get_first_node_in_group("main") != null:
		SaveManager.save_game("")


func _on_upgrade_built(_data) -> void:
	_emit_progress()


func _emit_progress() -> void:
	EventBus.campaign_progress_changed.emit()
