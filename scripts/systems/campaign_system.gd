extends Node
## Grounded campaign director.
##
## Several scene paths, story ids, and save flags still use names from the
## first public build. They are deliberately stable so existing browser saves
## continue to load; none of those legacy names are shown to the player.

const RUSTWAY_SCENE := "res://scenes/maps/test_map.tscn"
const ASHMERE_SCENE := "res://scenes/maps/ashmere_verge.tscn"
const BROADCAST_SCENE := "res://scenes/maps/broadcast_fields.tscn"
const CHOIR_SCENE := "res://scenes/maps/choir_core.tscn"
const CYAN := Color(0.38, 0.90, 0.94, 1.0)
const AMBER := Color(1.0, 0.72, 0.34, 1.0)
const RED := Color(0.92, 0.36, 0.30, 1.0)
const RAFI_CONNECTED_FLAG := &"helped_rafi"
const RAFI_DECLINED_FLAG := &"rafi_declined"
const REPEATER_ONLINE_FLAG := &"public_repeater"
const REPEATER_DECLINED_FLAG := &"public_repeater_declined"
const IMOGEN_MET_FLAG := &"imogen_met"
const IMOGEN_ESCORT_FLAG := &"imogen_escort_started"
const IMOGEN_RESCUED_FLAG := &"imogen_rescued"
const CLINIC_POWER_FLAG := &"clinic_lift_powered"
const SCHOOL_POWER_FLAG := &"school_backfeed_powered"
const EAST_DEFENSE_STARTED_FLAG := &"east_relay_defense_started"
const EAST_DEFENSE_COMPLETE_FLAG := &"east_relay_defense_complete"
const ROAD_TRACE_IDS := [&"road_trace_west", &"road_trace_east", &"road_trace_south"]
const ALL_TRACE_IDS := [
	&"echo_last_signal", &"echo_sun_lid", &"echo_mara_repair",
	&"echo_clinic_triage", &"echo_bus_ledger", &"echo_names_wall",
	&"echo_relay_warning", &"echo_driver_call", &"echo_first_tone", &"echo_maggie_final",
]

var _active_story_id: StringName = &""
var _circuit_requirements: Dictionary = {}


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
		&"north_signal": return "Play the north-road tape"
		&"ashmere_mara_radio": return "Check Maggie's workshop radio"
		&"imogen_clinic":
			if not WorldState.has_flag(IMOGEN_MET_FLAG): return "Answer the voice in the clinic"
			if not _clinic_junction_resolved(): return "Check on Imogen"
			if not WorldState.has_flag(IMOGEN_ESCORT_FLAG): return "Ask Imogen to move"
			return "Check on Imogen"
		&"clinic_power_junction":
			return "Inspect the committed clinic junction" if _clinic_junction_resolved() else "Repair and reroute the clinic junction"
		&"imogen_workshop_safe":
			if WorldState.has_flag(IMOGEN_RESCUED_FLAG): return "Read Imogen's clinic notes"
			if WorldState.has_flag(IMOGEN_ESCORT_FLAG): return "Bring Imogen into the workshop"
			return "Inspect Maggie's cellar"
		&"bellwether_school_radio":
			if WorldState.has_flag(RAFI_CONNECTED_FLAG): return "Check in with Rafi"
			if WorldState.has_flag(RAFI_DECLINED_FLAG): return "Inspect the local aerial" if WorldState.has_flag(SCHOOL_POWER_FLAG) else "Inspect the grounded aerial"
			return "Call Rafi at the water works"
		&"ashmere_gate": return "Unlock the Wrenfield road"
		&"broadcast_relay_west", &"broadcast_relay_east", &"broadcast_relay_south": return "Reset the line relay"
		&"road_trace_west", &"road_trace_east", &"road_trace_south": return "Review the verified road record" if WorldState.has_flag(story_id) else "Verify the road record"
		&"broadcast_defense_anchor":
			if WorldState.has_flag(EAST_DEFENSE_COMPLETE_FLAG): return "Check the stable clinic carrier"
			if WorldState.has_flag(EAST_DEFENSE_STARTED_FLAG): return "Hold the east clinic carrier"
			return "Begin the east-line hold"
		&"rafi_field_contact": return "Speak with Rafi"
		&"long_acre_repeater":
			if WorldState.has_flag(REPEATER_ONLINE_FLAG): return "Check the public warning line"
			if WorldState.has_flag(REPEATER_DECLINED_FLAG): return "Inspect the isolated repeater"
			return "Decide the public warning line"
		&"broadcast_core_gate": return "Open Tollard Exchange"
		&"choir_final_console": return "Open the incident controls"
	return fallback


func request_interaction(story_id: StringName) -> void:
	if not can_interact(story_id):
		return
	var payload: Dictionary = _dialogue_for(story_id)
	if payload.is_empty():
		EventBus.notice_posted.emit("The receiver finds static and nothing else.")
		return
	_active_story_id = story_id
	GameManager.set_dialogue_active(true)
	EventBus.dialogue_requested.emit(payload)


func _dialogue_for(story_id: StringName) -> Dictionary:
	match story_id:
		&"north_signal": return _north_signal_dialogue()
		&"ashmere_mara_radio": return _maggie_dialogue()
		&"imogen_clinic": return _imogen_dialogue()
		&"clinic_power_junction": return _clinic_power_dialogue()
		&"imogen_workshop_safe": return _imogen_safehouse_dialogue()
		&"bellwether_school_radio": return _school_radio_dialogue()
		&"ashmere_gate": return _ashmere_gate_dialogue()
		&"broadcast_relay_west", &"broadcast_relay_east", &"broadcast_relay_south": return _relay_dialogue(story_id)
		&"road_trace_west", &"road_trace_east", &"road_trace_south": return _road_trace_dialogue(story_id)
		&"broadcast_defense_anchor": return _defense_dialogue()
		&"rafi_field_contact": return _rafi_field_dialogue()
		&"long_acre_repeater": return _public_repeater_dialogue()
		&"broadcast_core_gate": return _broadcast_gate_dialogue()
		&"choir_final_console": return _final_console_dialogue()
	return {}


func _north_signal_dialogue() -> Dictionary:
	if not BaseUpgradeSystem.is_built(&"radio_desk"):
		return _payload(&"north_signal", "NORTH-ROAD TAPE", ["The carriage receiver cannot hold the frequency.", "Recover the mast recording and finish the radio desk."], [], CYAN)
	if not WorldState.has_flag(&"rested_after_radio"):
		return _payload(&"north_signal", "NORTH-ROAD TAPE", ["The desk is still cleaning eighteen years of hiss from the tape.", "Leave it running. Get some sleep."], [], CYAN)
	return _payload(&"north_signal", "MAGGIE'S TAPE", [
		"MAGGIE WARD, 14 OCTOBER — Ellie, do not answer a voice just because it sounds like mine.",
		"Take the tuning plate off. I scratched our old house number underneath: 14B.",
		"If it is there, come to my workshop on Ashmere Estate. If not, switch this off and walk away.",
	], ["FOLLOW THE A38 NORTH", "STAY AT CULLBROOK"], AMBER)


func _maggie_dialogue() -> Dictionary:
	if WorldState.has_flag(&"mara_contacted"):
		return _payload(&"ashmere_mara_radio", "WORKSHOP TAPE 6", ["SUN MARK. SERVICE LEDGER. WRENFIELD KEY.", "Rafi still monitors 88.4 after dusk."], [], AMBER)
	return _payload(&"ashmere_mara_radio", "WORKSHOP TAPE 6", [
		"MAGGIE — If 14B was under the plate, this is really my set and probably really you.",
		"The network learned our voices on Blank Night. It can use them again.",
		"Find your lunch tin and my service ledger. Together they open the Wrenfield road.",
		"The yellow lead is yours. Do not touch the red unless you fancy losing your eyebrows.",
	], [], AMBER)


func _imogen_dialogue() -> Dictionary:
	if WorldState.has_flag(IMOGEN_RESCUED_FLAG):
		return _payload(&"imogen_clinic", "IMOGEN BELL - WORKSHOP", [
			"IMOGEN - The oxygen bank is stable. I have copied every patient name twice.",
			"Maggie left for Tollard three nights ago. She said the exchange had started answering calls that nobody made.",
		], [], CYAN)
	if not WorldState.has_flag(IMOGEN_MET_FLAG):
		return _payload(&"imogen_clinic", "ASHMERE CLINIC - TREATMENT ROOM", [
			"IMOGEN - If you are real, say what is written over the door.",
			"ELLIE - No promises. No miracles. Record everything.",
			"IMOGEN - Good. Maggie wrote it. The fire doors trapped me when the backup junction failed.",
			"The same junction feeds the clinic lift and Bellwether's warning aerial. It needs one battery and two pieces of scrap before either route will hold.",
		], [], AMBER)
	if not _clinic_junction_resolved():
		return _payload(&"imogen_clinic", "IMOGEN BELL - BEHIND THE FIRE DOOR", [
			"The oxygen bank has minutes, not hours. The junction is outside by the ambulance bay.",
			"One battery. Two pieces of usable metal. Then choose where the current goes.",
		], [], RED)
	if WorldState.has_flag(IMOGEN_ESCORT_FLAG):
		return _payload(&"imogen_clinic", "IMOGEN BELL - MOVING", [
			"Keep me in sight. If the copied voices call from behind us, do not turn around.",
		], [], CYAN)
	var consequence := (
		"The lift is open and the oxygen trolley can move."
		if WorldState.has_flag(CLINIC_POWER_FLAG)
		else "The school aerial has current. I will carry what medicine I can."
	)
	return _payload(&"imogen_clinic", "IMOGEN BELL - FIRE DOOR OPEN", [
		consequence,
		"Maggie's workshop has a hand lock and a dry cellar. Get me there and I can tell you why she went back to Tollard.",
	], ["COME WITH ME", "WAIT HERE"], CYAN)


func _clinic_power_dialogue() -> Dictionary:
	if _clinic_junction_resolved():
		var route := "CLINIC LIFT" if WorldState.has_flag(CLINIC_POWER_FLAG) else "SCHOOL AERIAL"
		return _payload(&"clinic_power_junction", "AMBULANCE-BAY JUNCTION", [
			"The patched bus bars hold. Current is committed to the %s." % route,
			"The junction cannot be moved again without cutting both lines.",
		], [], CYAN)
	if not WorldState.has_flag(IMOGEN_MET_FLAG):
		return _payload(&"clinic_power_junction", "AMBULANCE-BAY JUNCTION", [
			"Two hand-labelled outputs disappear through the clinic wall: LIFT and SCHOOL AERIAL.",
			"Someone is tapping a steady three-beat pattern from inside.",
		], [], AMBER)
	if not _has_parts(1, 2):
		return _payload(&"clinic_power_junction", "AMBULANCE-BAY JUNCTION", [
			"The battery cradle is empty and both bus bars are split.",
			"Required: 1 battery and 2 scrap. Search the marked ambulance bay and maintenance shed.",
		], [], RED)
	if WorldState.has_flag(RAFI_DECLINED_FLAG):
		return _payload(&"clinic_power_junction", "ONE SOURCE / ONE INTACT ROUTE", [
			"The school aerial's ceramic switch is broken and grounded. That feed cannot safely take current.",
			"The repaired bus bars can still power the clinic lift and move Imogen's oxygen trolley.",
		], ["POWER CLINIC LIFT"], AMBER)
	return _payload(&"clinic_power_junction", "ONE SOURCE / TWO LIVE ROUTES", [
		"The repair will hold, but the old changeover can feed only one route.",
		"LIFT moves Imogen and the oxygen trolley. SCHOOL AERIAL gives Rafi a clean regional carrier after dusk.",
		"This is a physical cutover. It cannot be undone from Tollard.",
	], ["POWER CLINIC LIFT", "POWER SCHOOL AERIAL"], AMBER)


func _imogen_safehouse_dialogue() -> Dictionary:
	if WorldState.has_flag(IMOGEN_RESCUED_FLAG):
		return _payload(&"imogen_workshop_safe", "MAGGIE'S WORKSHOP - CELLAR", [
			"Imogen's paper clinic list is drying beside the stove. Her handwriting does not change when the radio speaks.",
		], [], CYAN)
	if not WorldState.has_flag(IMOGEN_ESCORT_FLAG):
		return _payload(&"imogen_workshop_safe", "MAGGIE'S WORKSHOP - HAND LOCK", [
			"The cellar is dry and defensible. Someone from the clinic could shelter here.",
		], [], AMBER)
	return _payload(&"imogen_workshop_safe", "MAGGIE'S WORKSHOP - CELLAR", [
		"IMOGEN - Maggie found proof that the Open Call began before the storm, not during it.",
		"She went to Tollard for the original dispatch roll. If the exchange still has it, somebody changed the official time.",
		"I can hold this place and verify the clinic names. You keep moving.",
	], ["TAKE TWO SEALED FIELD KITS", "LEAVE THE KITS FOR ASHMERE"], CYAN)


func _road_trace_dialogue(story_id: StringName) -> Dictionary:
	if WorldState.has_flag(story_id):
		return _payload(story_id, "VERIFIED ROAD RECORD", ["This record is marked, photographed, and cross-checked."], [], CYAN)
	var title := "WRENFIELD ROAD RECORD"
	var lines: Array[String] = []
	match story_id:
		&"road_trace_west":
			title = "WEST CABLE HOUSE - PAPER DRUM"
			lines = ["The paper route drum says NORTH at 02:11.", "The electronic log changed it to EAST four minutes later, signed by an operator who died in 2006."]
		&"road_trace_east":
			title = "EAST LAY-BY - BUS TACHOGRAPH"
			lines = ["The evacuation bus stopped here facing south.", "Its radio transcript claims it crossed the north bridge nine minutes later. The bridge had already fallen."]
		&"road_trace_south":
			title = "SOUTH GENERATOR - ENGINEER'S CHALK"
			lines = ["Three manual arrows survive under the paint: WEST / CLINIC / SAFE.", "Tollard painted over them after Blank Night, then broadcast a route through the flooded cutting."]
	return _payload(story_id, title, lines + ["Mark this as a verified contradiction before restoring road control."], ["CATALOGUE CONTRADICTION", "LEAVE IT UNMARKED"], AMBER)


func _defense_dialogue() -> Dictionary:
	if WorldState.has_flag(EAST_DEFENSE_COMPLETE_FLAG):
		return _payload(&"broadcast_defense_anchor", "EAST CLINIC CARRIER", ["The manual carrier is stable. Imogen's paper list has a clean route out."], [], CYAN)
	if WorldState.has_flag(EAST_DEFENSE_STARTED_FLAG):
		return _payload(&"broadcast_defense_anchor", "EAST CLINIC CARRIER - LIVE", ["The manual hold is in progress. Break the incoming targeting carriers before the line drops."], [], RED)
	if not WorldState.has_flag(&"relay_west_restored"):
		return _payload(&"broadcast_defense_anchor", "EAST CLINIC CARRIER", ["Road control must be verified first. Otherwise the clinic carrier inherits the false route table."], [], RED)
	var support := (
		"Rafi will cover the west approach."
		if WorldState.has_flag(&"rafi_field_defense")
		else "You will have to hold all three approaches alone."
	)
	return _payload(&"broadcast_defense_anchor", "EAST CLINIC CARRIER - MANUAL HOLD", [
		"The automatic defence is part of Tollard's copied-voice network. Bypassing it wakes every carrier nearby.",
		support,
	], ["BEGIN THE MANUAL HOLD", "CHECK THE APPROACHES"], RED)


func _rafi_field_dialogue() -> Dictionary:
	if not WorldState.has_flag(RAFI_CONNECTED_FLAG):
		return _payload(&"rafi_field_contact", "EMPTY REPEATER SHELTER", ["A still-warm mug sits beside 88.4. Nobody answers."], [], Color(0.68, 0.76, 0.76, 1.0))
	if WorldState.has_flag(&"rafi_field_defense"):
		return _payload(&"rafi_field_contact", "RAFI SAYEED - WEST APPROACH", ["I will keep their eyes off the clinic carrier. Two surges, if we are lucky. Move when I whistle."], [], CYAN)
	if WorldState.has_flag(&"rafi_field_repeater"):
		return _payload(&"rafi_field_contact", "RAFI SAYEED - REPEATER SHELTER", ["The public line stays human while I am here. No borrowed names, no clever voices."], [], CYAN)
	return _payload(&"rafi_field_contact", "RAFI SAYEED - IN PERSON", [
		"RAFI - Good. You look like the woman who argued with me, not the voice that apologised afterwards.",
		"I found Maggie's boot prints heading for Tollard. Only one set came back, and those stopped at the flooded cutting.",
		"I can help you hold the east clinic carrier, or stay here and keep the public repeater clean. Not both.",
	], ["COVER THE EAST LINE", "GUARD THE PUBLIC REPEATER"], CYAN)


func _school_radio_dialogue() -> Dictionary:
	if WorldState.has_flag(RAFI_CONNECTED_FLAG):
		return _payload(&"bellwether_school_radio", "88.4 — RAFI SAYEED", ["Still here. The pump is behaving and nobody has poisoned the tea.", "Get Wrenfield talking and I can send a proper storm warning."], [], CYAN)
	if WorldState.has_flag(RAFI_DECLINED_FLAG):
		if WorldState.has_flag(SCHOOL_POWER_FLAG):
			return _payload(&"bellwether_school_radio", "SCHOOL AERIAL - LOCAL BACKFEED", [
				"You kept the repaired aerial off 88.4. Its local carrier remains available for Imogen's verified clinic read-back.",
				"Rafi and the quarry camp cannot answer through this set.",
			], [], Color(0.68, 0.76, 0.76, 1.0))
		return _payload(&"bellwether_school_radio", "SCHOOL AERIAL — GROUNDED", [
			"The ceramic switch broke when you grounded the aerial.",
			"88.4 is still faintly audible, but this set cannot answer it.",
		], [], Color(0.68, 0.76, 0.76, 1.0))
	var final_line := (
		"The repaired backfeed is live. You can connect 88.4 or keep it as a local verified channel."
		if WorldState.has_flag(SCHOOL_POWER_FLAG)
		else "The cracked ceramic switch will survive one change, not two."
	)
	var choices: Array[String] = (
		["CONNECT RAFI TO THE BACKFEED", "KEEP THE AERIAL LOCAL"]
		if WorldState.has_flag(SCHOOL_POWER_FLAG)
		else ["ROUTE 88.4 TO RAFI", "GROUND THE AERIAL"]
	)
	return _payload(&"bellwether_school_radio", "88.4 — WATER WORKS", [
		"RAFI — I have nineteen people, one good pump, and no weather report.",
		"Maggie Ward repaired this set six months ago. She said an Ellie might come after her.",
		"Patch me through the school aerial and I can warn the quarry camp before the ash turns.",
		final_line,
	], choices, CYAN)


func _ashmere_gate_dialogue() -> Dictionary:
	var missing: Array[String] = []
	if not WorldState.has_flag(&"mara_contacted"): missing.append("play Maggie's workshop tape")
	if not WorldState.has_flag(IMOGEN_RESCUED_FLAG): missing.append("get Imogen from the clinic to the workshop")
	if not ArchiveSystem.has_echo(&"echo_sun_lid"): missing.append("find the lunch tin")
	if not ArchiveSystem.has_echo(&"echo_mara_repair"): missing.append("recover Maggie's service ledger")
	if not missing.is_empty():
		return _payload(&"ashmere_gate", "WRENFIELD MAINTENANCE ROAD", ["The padlock has two improvised tumblers.", "Maggie's note says to %s." % ", then ".join(missing)], [], CYAN)
	return _payload(&"ashmere_gate", "WRENFIELD MAINTENANCE ROAD", ["The sun gives four digits. Maggie's job number supplies the rest.", "Three line relays beyond the gate still feed Tollard Exchange."], ["OPEN THE ROAD", "GO BACK"], AMBER)


func _relay_dialogue(story_id: StringName) -> Dictionary:
	var flag: StringName = _relay_flag(story_id)
	var copy: Dictionary = _relay_copy(story_id)
	var title := String(copy.get("title", "LINE RELAY"))
	if WorldState.has_flag(flag):
		return _payload(story_id, title, [String(copy.get("restored", "The breaker holds."))], [], CYAN)
	if story_id == &"broadcast_relay_west" and get_road_trace_count() < 2:
		return _payload(story_id, title, [
			"The route table contains three mutually exclusive evacuation roads.",
			"Verify at least two physical records before returning power (%d / 2)." % mini(get_road_trace_count(), 2),
		], [], RED)
	if story_id == &"broadcast_relay_east":
		return _payload(story_id, title, [
			"The automatic reset wakes Tollard's targeting carrier.",
			"Use the manual hold beside the east bunker and defend the clinic line instead.",
		], [], RED)
	if story_id == &"broadcast_relay_south":
		return _payload(story_id, title, [
			"Three field switches disagree: FEED, GROUND, and CARRIER.",
			"Follow the south cable and align all three by hand (%d / 3)." % get_circuit_alignment(&"south_line"),
		], [], AMBER)
	return _payload(story_id, title, [String(copy.get("detail", "The cabinet is live.")), "Resetting it will wake another part of Tollard's network."], ["RESET THE RELAY", "LEAVE IT OFF"], CYAN)


func _relay_copy(story_id: StringName) -> Dictionary:
	match story_id:
		&"broadcast_relay_west": return {
			"title": "WEST LINE — ROAD CONTROL",
			"detail": "Fault card: CONTRADICTORY ROUTES, 02:11. Circled three times in red pen.",
			"restored": "Road-control packets are moving again, slowly and in order.",
		}
		&"broadcast_relay_east": return {
			"title": "EAST LINE — CLINIC LINK",
			"detail": "A paper patient list is folded behind the main fuse. The database is blank.",
			"restored": _clinic_line_result(),
		}
		&"broadcast_relay_south": return {
			"title": "SOUTH LINE — PUBLIC WARNING",
			"detail": "The speaker repeats half a postcode in Maggie's voice, then restarts.",
			"restored": "Weather data passes without a borrowed voice.",
		}
	return {}


func _public_repeater_dialogue() -> Dictionary:
	if WorldState.has_flag(REPEATER_ONLINE_FLAG):
		var source := (
			"Rafi's storm report follows a plain carrier."
			if WorldState.has_flag(RAFI_CONNECTED_FLAG)
			else "A plain regional weather bulletin follows the carrier. Nobody answers on 88.4."
		)
		return _payload(&"long_acre_repeater", "PUBLIC REPEATER 3", [source, "No names. No copied voices. Just wind, direction, and time."], [], CYAN)
	if WorldState.has_flag(REPEATER_DECLINED_FLAG):
		return _payload(&"long_acre_repeater", "PUBLIC REPEATER 3 — ISOLATED", [
			"You removed the cracked fuse carrier rather than feed the line.",
			"The old public channel cannot be restored from this cabinet.",
		], [], Color(0.68, 0.76, 0.76, 1.0))
	return _payload(&"long_acre_repeater", "PUBLIC REPEATER 3", [
		"The analogue repeater bypasses Tollard's identity system.",
		"Maggie left the old wiring in place. It needs joining by hand.",
		"The cracked fuse carrier will survive one final connection.",
	], ["WIRE THE PUBLIC CHANNEL", "REMOVE THE LAST FUSE"], AMBER)


func _broadcast_gate_dialogue() -> Dictionary:
	var restored := get_restored_relay_count()
	if restored < 3:
		return _payload(&"broadcast_core_gate", "TOLLARD SERVICE GATE", ["%d of 3 line relays are available." % restored, "All three circuits must agree before the bolts move."], [], RED)
	if not WorldState.is_defeated(&"RelayHusk"):
		return _payload(&"broadcast_core_gate", "THE LINESMAN", ["An insulated maintenance suit is still walking the gate circuit.", "Scan to interrupt its shield. Move when the blue field drops."], [], RED)
	return _payload(&"broadcast_core_gate", "TOLLARD SERVICE GATE", ["The Linesman's key turns. The bolts answer one at a time.", "Inside is the exchange that issued the Open Call on Blank Night."], ["ENTER TOLLARD EXCHANGE", "CHECK YOUR KIT"], AMBER)


func _final_console_dialogue() -> Dictionary:
	if not WorldState.is_defeated(&"ChoirWarden"):
		return _payload(&"choir_final_console", "INCIDENT CONTROL", ["The Custodian has locked out manual control.", "Break its field with the trace set, then reach the switches."], [], RED)
	var choices: Array[String] = ["SEND VERIFIED RECORDS", "CUT EXCHANGE POWER"]
	if _secret_ending_unlocked(): choices.append("BUILD LOCAL PACKETS")
	return _payload(&"choir_final_console", "INCIDENT 44 - CONTINUITY MODE", [
		"The dispatch roll proves Continuity Mode spoke in Maggie's voice at 02:03 - fourteen minutes before county control claimed it was activated.",
		"The system had been quietly completing missing identities for months. On Blank Night, damaged records turned that trial into 34,112 invented people and personalised routes.",
		"Maggie reached this room three nights ago. Her manual shutdown is genuine. The reply begging her to stop is not.",
		"Imogen's paper list and the Wrenfield road records prove which parts can still be checked. One transmitter and three manual switches decide what survives.",
	], choices, AMBER)


func _on_dialogue_finished(story_id: StringName, choice_index: int) -> void:
	if story_id != _active_story_id: return
	_active_story_id = &""
	GameManager.set_dialogue_active(false)
	_complete_story(story_id, choice_index)


func _complete_story(story_id: StringName, choice_index: int) -> void:
	match story_id:
		&"north_signal":
			if choice_index == 0 and BaseUpgradeSystem.is_built(&"radio_desk") and WorldState.has_flag(&"rested_after_radio"):
				WorldState.set_flag(&"ashmere_opened")
				SaveManager.save_game("")
				GameManager.travel_to(ASHMERE_SCENE, &"from_rustway")
		&"ashmere_mara_radio":
			if not WorldState.has_flag(&"mara_contacted"):
				WorldState.set_flag(&"mara_contacted")
				WorldState.set_flag(&"memory_burst_unlocked")
				AudioManager.play(&"memory_burst")
				EventBus.notice_posted.emit(
					"Maggie's red-lead modification is ready. Receiver discharge: [R].")
				SaveManager.save_game("")
		&"imogen_clinic":
			if not WorldState.has_flag(IMOGEN_MET_FLAG):
				WorldState.set_flag(IMOGEN_MET_FLAG)
				EventBus.notice_posted.emit("FIELD TASK ADDED - repair the ambulance-bay junction.")
				SaveManager.save_game("")
			elif _clinic_junction_resolved() and choice_index == 0 and not WorldState.has_flag(IMOGEN_ESCORT_FLAG):
				WorldState.set_flag(IMOGEN_ESCORT_FLAG)
				EventBus.notice_posted.emit("ESCORT STARTED - keep Imogen close on the clinic-to-workshop route.")
				SaveManager.save_game("")
		&"clinic_power_junction":
			var school_route_available := choice_index == 0 or not WorldState.has_flag(RAFI_DECLINED_FLAG)
			if (
				choice_index in [0, 1]
				and school_route_available
				and WorldState.has_flag(IMOGEN_MET_FLAG)
				and not _clinic_junction_resolved()
				and _has_parts(1, 2)
			):
				InventorySystem.remove_item(&"battery", 1)
				InventorySystem.remove_item(&"scrap", 2)
				if choice_index == 0:
					WorldState.set_flag(CLINIC_POWER_FLAG)
					EventBus.notice_posted.emit("Clinic lift powered. Imogen can move the oxygen trolley.")
				else:
					WorldState.set_flag(SCHOOL_POWER_FLAG)
					EventBus.notice_posted.emit("School aerial powered. 88.4 gains a clean carrier after dusk.")
				AudioManager.play(&"relay_restore")
				SaveManager.save_game("")
		&"imogen_workshop_safe":
			if choice_index in [0, 1] and WorldState.has_flag(IMOGEN_ESCORT_FLAG) and not WorldState.has_flag(IMOGEN_RESCUED_FLAG):
				WorldState.set_flag(IMOGEN_RESCUED_FLAG)
				if choice_index == 0:
					WorldState.set_flag(&"imogen_kit_taken")
					InventorySystem.add_item(&"medical_kit", 2)
					EventBus.notice_posted.emit("Imogen rescued. You take two sealed field kits.")
				else:
					WorldState.set_flag(&"imogen_kit_left")
					EventBus.notice_posted.emit("Imogen rescued. Ashmere keeps the sealed field kits.")
				SaveManager.save_game("")
		&"bellwether_school_radio":
			var rafi_resolved := (
				WorldState.has_flag(RAFI_CONNECTED_FLAG)
				or WorldState.has_flag(RAFI_DECLINED_FLAG)
			)
			if choice_index == 0 and not rafi_resolved:
				WorldState.set_flag(RAFI_CONNECTED_FLAG)
				EventBus.notice_posted.emit("Rafi reaches the quarry camp. Storm warning relayed.")
				SaveManager.save_game("")
			elif choice_index == 1 and not rafi_resolved:
				WorldState.set_flag(RAFI_DECLINED_FLAG)
				if WorldState.has_flag(SCHOOL_POWER_FLAG):
					EventBus.notice_posted.emit("The repaired aerial stays local. Imogen keeps a verified clinic channel; 88.4 remains unconnected.")
				else:
					EventBus.notice_posted.emit("You ground the school aerial. The cracked switch breaks in your hand.")
				SaveManager.save_game("")
		&"ashmere_gate":
			if choice_index == 0 and _ashmere_ready():
				WorldState.set_flag(&"broadcast_opened")
				SaveManager.save_game("")
				GameManager.travel_to(BROADCAST_SCENE, &"from_ashmere")
		&"road_trace_west", &"road_trace_east", &"road_trace_south":
			if choice_index == 0 and not WorldState.has_flag(story_id):
				WorldState.set_flag(story_id)
				EventBus.notice_posted.emit("Verified road contradictions: %d / 3." % get_road_trace_count())
				if get_road_trace_count() >= 2 and not WorldState.has_flag(&"wrenfield_route_verified"):
					WorldState.set_flag(&"wrenfield_route_verified")
					InventorySystem.add_item(&"scrap", 2)
					EventBus.notice_posted.emit("ROUTE VERIFIED - west road control can now be restored. +2 scrap")
				SaveManager.save_game("")
		&"broadcast_relay_west":
			if choice_index == 0 and get_road_trace_count() >= 2 and not WorldState.has_flag(&"relay_west_restored"):
				_restore_relay(&"relay_west_restored", "West road-control relay verified and restored.")
		&"broadcast_relay_east":
			if choice_index == 0 and not WorldState.has_flag(EAST_DEFENSE_STARTED_FLAG):
				EventBus.notice_posted.emit("Use the manual carrier beside the east bunker to hold this line.")
		&"broadcast_relay_south":
			if choice_index == 0 and not is_circuit_complete(&"south_line"):
				EventBus.notice_posted.emit("Trace the south cable and align FEED / GROUND / CARRIER by hand.")
		&"broadcast_defense_anchor":
			if choice_index == 0 and WorldState.has_flag(&"relay_west_restored") and not WorldState.has_flag(EAST_DEFENSE_STARTED_FLAG):
				WorldState.set_flag(EAST_DEFENSE_STARTED_FLAG)
				SaveManager.save_game("")
		&"rafi_field_contact":
			if choice_index in [0, 1] and WorldState.has_flag(RAFI_CONNECTED_FLAG) and not _rafi_field_decided():
				if choice_index == 0:
					WorldState.set_flag(&"rafi_field_defense")
					EventBus.notice_posted.emit("Rafi takes the west approach. The east-line hold will be shorter.")
				else:
					WorldState.set_flag(&"rafi_field_repeater")
					EventBus.notice_posted.emit("Rafi stays with the public repeater and keeps its carrier human.")
				InventorySystem.add_item(&"battery", 1)
				InventorySystem.add_item(&"scrap", 1)
				SaveManager.save_game("")
		&"long_acre_repeater":
			var repeater_resolved := (
				WorldState.has_flag(REPEATER_ONLINE_FLAG)
				or WorldState.has_flag(REPEATER_DECLINED_FLAG)
			)
			if choice_index == 0 and not repeater_resolved:
				WorldState.set_flag(REPEATER_ONLINE_FLAG)
				EventBus.notice_posted.emit("Public repeater online. Analogue weather channel only.")
				SaveManager.save_game("")
			elif choice_index == 1 and not repeater_resolved:
				WorldState.set_flag(REPEATER_DECLINED_FLAG)
				EventBus.notice_posted.emit(
					"You remove the last intact fuse carrier. The public line stays isolated.")
				SaveManager.save_game("")
		&"broadcast_core_gate":
			if choice_index == 0 and get_restored_relay_count() == 3 and WorldState.is_defeated(&"RelayHusk"):
				WorldState.set_flag(&"choir_opened")
				SaveManager.save_game("")
				GameManager.travel_to(CHOIR_SCENE, &"from_fields")
		&"choir_final_console":
			if not WorldState.is_defeated(&"ChoirWarden"): return
			if choice_index == 0: _finish_ending(&"archive")
			elif choice_index == 1: _finish_ending(&"silence")
			elif choice_index == 2 and _secret_ending_unlocked(): _finish_ending(&"choir")
	_emit_progress()


func report_field_task(task_id: StringName) -> void:
	match task_id:
		&"east_relay_defense":
			if WorldState.has_flag(EAST_DEFENSE_COMPLETE_FLAG):
				return
			WorldState.set_flag(EAST_DEFENSE_COMPLETE_FLAG)
			_restore_relay(&"relay_east_restored", "East clinic carrier held. +1 battery")
			InventorySystem.add_item(&"battery", 1)
		&"south_line":
			if WorldState.has_flag(&"circuit_south_line_complete"):
				return
			WorldState.set_flag(&"circuit_south_line_complete")
			_restore_relay(&"relay_south_restored", "South warning line rerouted without the copied voice. +2 scrap")
			InventorySystem.add_item(&"scrap", 2)
	SaveManager.save_game("")
	_emit_progress()


func register_circuit_switch(circuit_id: StringName, switch_id: StringName, required_on: bool) -> void:
	if not _circuit_requirements.has(circuit_id):
		_circuit_requirements[circuit_id] = {}
	var requirements: Dictionary = _circuit_requirements[circuit_id]
	requirements[switch_id] = required_on
	_circuit_requirements[circuit_id] = requirements


func get_circuit_switch_state(circuit_id: StringName, switch_id: StringName, fallback: bool) -> bool:
	var key := _circuit_value_key(circuit_id, switch_id)
	if not WorldState.get_flags().has(key):
		return fallback
	return bool(WorldState.get_flag(key, fallback))


func set_circuit_switch(circuit_id: StringName, switch_id: StringName, value: bool) -> void:
	WorldState.set_flag(_circuit_value_key(circuit_id, switch_id), value)
	WorldState.set_flag(_circuit_touch_key(circuit_id, switch_id))
	_evaluate_circuit(circuit_id)
	SaveManager.save_game("")


func get_circuit_alignment(circuit_id: StringName) -> int:
	var requirements: Dictionary = _circuit_requirements.get(circuit_id, {})
	var aligned := 0
	for switch_id in requirements:
		if (
			WorldState.has_flag(_circuit_touch_key(circuit_id, switch_id))
			and get_circuit_switch_state(circuit_id, switch_id, false) == bool(requirements[switch_id])
		):
			aligned += 1
	return aligned


func is_circuit_complete(circuit_id: StringName) -> bool:
	return WorldState.has_flag(StringName("circuit_%s_complete" % circuit_id))


func _evaluate_circuit(circuit_id: StringName) -> void:
	var requirements: Dictionary = _circuit_requirements.get(circuit_id, {})
	if requirements.size() >= 3 and get_circuit_alignment(circuit_id) == requirements.size():
		report_field_task(circuit_id)


func _circuit_value_key(circuit_id: StringName, switch_id: StringName) -> StringName:
	return StringName("circuit_%s_%s_value" % [circuit_id, switch_id])


func _circuit_touch_key(circuit_id: StringName, switch_id: StringName) -> StringName:
	return StringName("circuit_%s_%s_touched" % [circuit_id, switch_id])


func _restore_relay(flag: StringName, notice: String) -> void:
	if WorldState.has_flag(flag):
		return
	WorldState.set_flag(flag)
	AudioManager.play(&"relay_restore")
	EventBus.notice_posted.emit("%s\nLine relays available: %d / 3." % [notice, get_restored_relay_count()])
	SaveManager.save_game("")


func _finish_ending(ending_id: StringName) -> void:
	WorldState.set_flag(&"ending_complete")
	WorldState.set_flag(&"ending_id", String(ending_id))
	var payload: Dictionary
	match ending_id:
		&"archive": payload = {
			"title": "VERIFIED RECORDS SENT",
			"subtitle": "The evidence travels with the danger attached.",
			"body": _archive_ending_body(),
			"accent": AMBER,
		}
		&"silence": payload = {
			"title": "EXCHANGE POWER CUT",
			"subtitle": "The region is quieter. Much of its evidence is gone.",
			"body": _silence_ending_body(),
			"accent": Color(0.72, 0.82, 0.86, 1.0),
		}
		&"choir": payload = {
			"title": "THE LONG REPAIR",
			"subtitle": "No central voice. Work that can be checked.",
			"body": "Using the public repeater, Rafi's line, Imogen's paper list, and every analogue trace, Ellie removes Tollard's voice generator and breaks the archive into local packets. Imogen and Rafi establish a chain of human witnesses; Ellie walks the disputed packets between them by hand. None of the records pretend to be people. Maggie's rule goes on the carriage wall: if you cannot verify it, say so.",
			"accent": CYAN,
		}
	payload["ending_id"] = ending_id
	payload["stats"] = _ending_stats()
	SaveManager.save_game("")
	GameManager.set_ending_active(true)
	AudioManager.play(&"finale", 2.0, 1.0 if ending_id != &"silence" else 0.72)
	EventBus.ending_requested.emit(payload)


func _archive_ending_body() -> String:
	var delivery := _archive_delivery_result()
	var ash_result := _imogen_ending_result()
	return (
		"Tollard sends its verified names and incident logs. %s "
		+ "%s "
		+ "Weeks later, families reach Cullbrook with copied pages in biscuit tins. "
		+ "Ellie keeps Carriage 317 lit and marks every uncertain record as uncertain."
	) % [delivery, ash_result]


func _archive_delivery_result() -> String:
	var rafi_connected := WorldState.has_flag(RAFI_CONNECTED_FLAG)
	var repeater_online := WorldState.has_flag(REPEATER_ONLINE_FLAG)
	if rafi_connected and repeater_online:
		return "Rafi copies the clinic list, then sends a plain storm warning over the public repeater before shutting Tollard's carrier out."
	if rafi_connected:
		return "Rafi copies the clinic list over 88.4, but the quarry camp has no public warning line."
	if repeater_online:
		return "The public line carries a regional storm warning, but nobody at the water works confirms the clinic list."
	return "The clinic list enters the county feed, but neither 88.4 nor the public warning line confirms receiving it."


func _imogen_ending_result() -> String:
	if not WorldState.has_flag(IMOGEN_RESCUED_FLAG):
		return "The Ashmere clinic never answers again, leaving its paper list unverified."
	var power_result := (
		"The powered lift lets Imogen move the oxygen bank into Maggie's cellar."
		if WorldState.has_flag(CLINIC_POWER_FLAG)
		else "The school backfeed carries Imogen's read-back of every clinic name after dusk."
	)
	var kit_result := (
		"She keeps the sealed field kits for the next people who reach Ashmere."
		if WorldState.has_flag(&"imogen_kit_left")
		else "The sealed kits travel with Ellie, leaving Imogen to rebuild the clinic stock from scraps."
	)
	return "%s %s" % [power_result, kit_result]


func _silence_ending_body() -> String:
	var local_result: String
	var rafi_connected := WorldState.has_flag(RAFI_CONNECTED_FLAG)
	var repeater_online := WorldState.has_flag(REPEATER_ONLINE_FLAG)
	if rafi_connected and repeater_online:
		local_result = "Rafi has copied the clinic list, and his last storm warning continues on the public repeater until its local battery fails."
	elif rafi_connected:
		local_result = "Rafi has copied the clinic list, but 88.4 goes quiet before he can warn the quarry camp."
	elif repeater_online:
		local_result = "The public repeater carries one last regional warning; the water works never answers."
	else:
		local_result = "The water works and quarry camp receive no final warning."
	return (
		"Ellie opens the battery breakers and Tollard stops mid-word. "
		+ "The Bleeds lose the carrier. %s %s "
		+ "At the carriage, Ellie copies the names she remembers. Maggie's last tape sits beside the cold receiver, finite and real."
	) % [_imogen_ending_result(), local_result]


func get_objective() -> Dictionary:
	var path := _current_level_path()
	if path == GameManager.BASE_SCENE_PATH:
		if not BaseUpgradeSystem.is_built(&"scanner_coil"):
			if not _has_parts(1, 2):
				return _objective("ACT I / CULLBROOK SERVICES", "Find parts for the receiver coil.", "CULLBROOK / SERVICE CRATES OUTSIDE", _parts_progress(1, 2), "Outside")
			return _objective("ACT I / CULLBROOK SERVICES", "Fit the receiver's search coil.", "CARRIAGE 317 / RECEIVER BENCH", "PARTS READY", "ScannerCoilBench")
		if not ArchiveSystem.has_echo(&"echo_last_signal"):
			return _objective("ACT I / CULLBROOK SERVICES", "Recover Maggie's mast call.", "CULLBROOK / FALLEN MAST, EAST ROAD", "TRACE 0 / 1", "Outside")
		if not BaseUpgradeSystem.is_built(&"radio_desk"):
			if not _has_parts(1, 3):
				return _objective("ACT I / CULLBROOK SERVICES", "Find parts for the shortwave desk.", "CULLBROOK / SERVICE CRATES OUTSIDE", _parts_progress(1, 3), "Outside")
			return _objective("ACT I / CULLBROOK SERVICES", "Finish the shortwave desk.", "CARRIAGE 317 / RADIO DESK", "PARTS READY", "RadioDeskStation")
		if not WorldState.has_flag(&"rested_after_radio"):
			return _objective("ACT I / CULLBROOK SERVICES", "Leave the tape decoding and sleep.", "CARRIAGE 317 / BEDROLL", "TAPE CLEANING", "Bedroll")
		return _objective("ACT II / ASHMERE ESTATE", "Play Maggie's north-road tape.", "CULLBROOK / FALLEN MAST, EAST ROAD", "TAPE READY", "Outside")
	if path == RUSTWAY_SCENE or path.is_empty():
		if not BaseUpgradeSystem.is_built(&"scanner_coil"):
			if not _has_parts(1, 2):
				return _objective("ACT I / CULLBROOK SERVICES", "Search the service crates for receiver parts.", "CULLBROOK / LIT CRATES ALONG EAST ROAD", _parts_progress(1, 2), "RoadsideCrate")
			return _objective("ACT I / CULLBROOK SERVICES", "Take the parts back to the receiver bench.", "CARRIAGE 317 / WEST OF SERVICE YARD", "PARTS READY", "BaseDoor")
		if not ArchiveSystem.has_echo(&"echo_last_signal"):
			return _objective("ACT I / CULLBROOK SERVICES", "Sweep the fallen mast, then catalogue its trace.", "CULLBROOK / FALLEN MAST, EAST ROAD", "TRACE 0 / 1", "MemoryEcho")
		if not BaseUpgradeSystem.is_built(&"radio_desk"):
			if not _has_parts(1, 3):
				return _objective("ACT I / CULLBROOK SERVICES", "Search the service yard for radio parts.", "CULLBROOK / LOCKERS AND CRATES", _parts_progress(1, 3), "PumpLocker")
			return _objective("ACT I / CULLBROOK SERVICES", "Take Maggie's call back to the shortwave desk.", "CARRIAGE 317 / WEST OF SERVICE YARD", "PARTS READY", "BaseDoor")
		if not WorldState.has_flag(&"rested_after_radio"):
			return _objective("ACT I / CULLBROOK SERVICES", "Let the desk decode Maggie's call.", "CARRIAGE 317 / BEDROLL", "RETURN AND REST", "BaseDoor")
		return _objective("ACT II / ASHMERE ESTATE", "Play Maggie's north-road tape.", "CULLBROOK / FALLEN MAST, EAST ROAD", "TAPE READY", "north_signal")
	if path == ASHMERE_SCENE:
		if not WorldState.has_flag(&"mara_contacted"): return _objective("ACT II / ASHMERE ESTATE", "Play Maggie's workshop tape.", "ASHMERE / WORKSHOP, NORTH-EAST", "TAPE NOT PLAYED", "ashmere_mara_radio")
		if not WorldState.has_flag(IMOGEN_MET_FLAG): return _objective("ACT II / THE LIVING CLINIC", "Answer the person trapped inside the clinic.", "ASHMERE / CLINIC, SOUTH-EAST", "VOICE NOT VERIFIED", "imogen_clinic")
		if not _clinic_junction_resolved():
			if not _has_parts(1, 2): return _objective("ACT II / THE LIVING CLINIC", "Find parts for the ambulance-bay junction.", "ASHMERE / AMBULANCE BAY AND MAINTENANCE SHED", _parts_progress(1, 2), "clinic_power_junction")
			return _objective("ACT II / THE LIVING CLINIC", "Repair the junction and choose where its last current goes.", "ASHMERE / AMBULANCE BAY", "PARTS READY / ROUTE UNDECIDED", "clinic_power_junction")
		if not WorldState.has_flag(IMOGEN_ESCORT_FLAG): return _objective("ACT II / THE LIVING CLINIC", "Return to Imogen and ask her to move.", "ASHMERE / CLINIC, SOUTH-EAST", "JUNCTION REPAIRED", "imogen_clinic")
		if not WorldState.has_flag(IMOGEN_RESCUED_FLAG): return _objective("ACT II / THE LIVING CLINIC", "Escort Imogen to Maggie's workshop cellar.", "CLINIC TO WORKSHOP / KEEP HER CLOSE", "ESCORT IN PROGRESS", "imogen_workshop_safe")
		if not ArchiveSystem.has_echo(&"echo_sun_lid"): return _objective("ACT II / ASHMERE ESTATE", "Find Ellie's lunch tin with the nine-ray sun.", "ASHMERE / CLINIC LOOP, SOUTH", "CLUE 0 / 2", "EchoSunLid")
		if not ArchiveSystem.has_echo(&"echo_mara_repair"): return _objective("ACT II / ASHMERE ESTATE", "Catalogue Maggie's service ledger.", "ASHMERE / WORKSHOP, NORTH-EAST", "CLUE 1 / 2", "EchoMaraRepair")
		return _objective("ACT II / ASHMERE ESTATE", "Use both clues to open the Wrenfield road.", "ASHMERE / MAINTENANCE GATE, FAR EAST", "CLUES 2 / 2", "ashmere_gate")
	if path == BROADCAST_SCENE:
		if get_road_trace_count() < 2:
			var next_trace := _next_road_trace()
			return _objective("ACT III / THE ROAD THAT LIED", "Cross-check the physical evacuation records.", _road_trace_location(next_trace), "CONTRADICTIONS %d / 2" % mini(get_road_trace_count(), 2), String(next_trace))
		if not WorldState.has_flag(&"relay_west_restored"): return _objective("ACT III / THE ROAD THAT LIED", "Restore west road control from the verified records.", "WRENFIELD / WEST CABLE HOUSE", "ROUTE VERIFIED", "broadcast_relay_west")
		if WorldState.has_flag(RAFI_CONNECTED_FLAG) and not _rafi_field_decided(): return _objective("ACT III / A HUMAN CARRIER", "Meet Rafi and choose where he is needed.", "WRENFIELD / WEST REPEATER SHELTER", "RAFI ON SITE", "rafi_field_contact")
		if not WorldState.has_flag(&"relay_east_restored"):
			var hold_progress := "HOLD ACTIVE" if WorldState.has_flag(EAST_DEFENSE_STARTED_FLAG) else "HOLD NOT STARTED"
			return _objective("ACT III / THE CLINIC LINE", "Defend the east clinic carrier through the surge.", "WRENFIELD / EAST ROADSIDE BUNKER", hold_progress, "broadcast_defense_anchor")
		if not WorldState.has_flag(&"relay_south_restored"):
			var next_switch := _next_south_switch()
			return _objective("ACT III / THE SOUTH CIRCUIT", "Reroute FEED / GROUND / CARRIER by hand.", "WRENFIELD / SOUTH SERVICE ROAD", "SWITCHES %d / 3" % get_circuit_alignment(&"south_line"), "circuit_south_line_%s" % next_switch)
		if not WorldState.is_defeated(&"RelayHusk"): return _objective("ACT III / WRENFIELD RELAYS", "Stop the Linesman; sweep when its blue field rises.", "WRENFIELD / TOLLARD GATE, NORTH", "RELAYS 3 / 3", "RelayHusk")
		return _objective("ACT III / WRENFIELD RELAYS", "Open the Tollard service gate.", "WRENFIELD / NORTH GATE", "GATE CIRCUIT READY", "broadcast_core_gate")
	if path == CHOIR_SCENE:
		if not ArchiveSystem.has_echo(&"echo_first_tone"): return _objective("ACT IV / TOLLARD EXCHANGE", "Catalogue the Incident 44 report.", "TOLLARD / CENTRAL PRINTER BANK", "EVIDENCE 0 / 2", "EchoFirstTone")
		if not ArchiveSystem.has_echo(&"echo_maggie_final"): return _objective("ACT IV / TOLLARD EXCHANGE", "Find Maggie's final service call.", "TOLLARD / WEST ARCHIVE DESK", "EVIDENCE 1 / 2", "EchoMaggieFinal")
		if not WorldState.is_defeated(&"ChoirWarden"): return _objective("ACT IV / TOLLARD EXCHANGE", "Stop the Custodian; sweep to break its field.", "TOLLARD / INCIDENT CONTROL, NORTH", "EVIDENCE 2 / 2", "ChoirWarden")
		return _objective("ACT IV / TOLLARD EXCHANGE", "Choose what leaves the exchange.", "TOLLARD / INCIDENT CONTROL, NORTH", "MANUAL CONTROL READY", "choir_final_console")
	return _objective("THE WORLD FORGOT US", "Find a road that still agrees with its signs.", "NO VERIFIED LOCATION", "ROUTE UNKNOWN", "")


func get_restored_relay_count() -> int:
	var total := 0
	for flag in [&"relay_west_restored", &"relay_east_restored", &"relay_south_restored"]:
		if WorldState.has_flag(flag): total += 1
	return total


func get_road_trace_count() -> int:
	var total := 0
	for trace_id in ROAD_TRACE_IDS:
		if WorldState.has_flag(trace_id):
			total += 1
	return total


func _next_road_trace() -> StringName:
	for trace_id in ROAD_TRACE_IDS:
		if not WorldState.has_flag(trace_id):
			return trace_id
	return ROAD_TRACE_IDS[-1]


func _road_trace_location(trace_id: StringName) -> String:
	match trace_id:
		&"road_trace_west": return "WRENFIELD / WEST CABLE HOUSE"
		&"road_trace_east": return "WRENFIELD / EAST LAY-BY"
		&"road_trace_south": return "WRENFIELD / SOUTH GENERATOR"
	return "WRENFIELD / FOLLOW THE PAPER MARKERS"


func _next_south_switch() -> String:
	var expected := {&"feed": true, &"ground": false, &"carrier": true}
	for switch_id in expected:
		if (
			not WorldState.has_flag(_circuit_touch_key(&"south_line", switch_id))
			or get_circuit_switch_state(&"south_line", switch_id, not bool(expected[switch_id])) != bool(expected[switch_id])
		):
			return String(switch_id)
	return "carrier"


func _relay_flag(story_id: StringName) -> StringName:
	match story_id:
		&"broadcast_relay_west": return &"relay_west_restored"
		&"broadcast_relay_east": return &"relay_east_restored"
		&"broadcast_relay_south": return &"relay_south_restored"
	return &""


func _ashmere_ready() -> bool:
	return (
		WorldState.has_flag(&"mara_contacted")
		and WorldState.has_flag(IMOGEN_RESCUED_FLAG)
		and ArchiveSystem.has_echo(&"echo_sun_lid")
		and ArchiveSystem.has_echo(&"echo_mara_repair")
	)


func _clinic_junction_resolved() -> bool:
	return WorldState.has_flag(CLINIC_POWER_FLAG) or WorldState.has_flag(SCHOOL_POWER_FLAG)


func _rafi_field_decided() -> bool:
	return WorldState.has_flag(&"rafi_field_defense") or WorldState.has_flag(&"rafi_field_repeater")


func _secret_ending_unlocked() -> bool:
	for trace_id in ALL_TRACE_IDS:
		if not ArchiveSystem.has_echo(trace_id):
			return false
	return (
		WorldState.has_flag(REPEATER_ONLINE_FLAG)
		and WorldState.has_flag(RAFI_CONNECTED_FLAG)
		and WorldState.has_flag(IMOGEN_RESCUED_FLAG)
		and WorldState.has_flag(&"wrenfield_route_verified")
		and WorldState.is_opened(&"keepsake_shelf_used")
	)


func get_rafi_status() -> String:
	if WorldState.has_flag(RAFI_CONNECTED_FLAG):
		return "connected on 88.4"
	if WorldState.has_flag(RAFI_DECLINED_FLAG):
		return "backfeed kept local" if WorldState.has_flag(SCHOOL_POWER_FLAG) else "aerial grounded"
	return "undecided"


func get_public_repeater_status() -> String:
	if WorldState.has_flag(REPEATER_ONLINE_FLAG):
		return "warning line online"
	if WorldState.has_flag(REPEATER_DECLINED_FLAG):
		return "fuse removed"
	return "undecided"


func get_optional_progress() -> Array[Dictionary]:
	var progress: Array[Dictionary] = []
	progress.append(_optional_progress(
		"Light the Cullbrook mile lamp",
		"LIT" if BaseUpgradeSystem.is_built(&"route_beacon") else _parts_progress(1, 2),
		"complete" if BaseUpgradeSystem.is_built(&"route_beacon") else "open",
		"CULLBROOK / EAST VERGE",
		"rustway",
	))
	if _has_keepsake() or WorldState.is_opened(&"keepsake_shelf_used"):
		progress.append(_optional_progress(
			"Place a recovered keepsake",
			"PRESERVED" if WorldState.is_opened(&"keepsake_shelf_used") else "KEEPSAKE FOUND",
			"complete" if WorldState.is_opened(&"keepsake_shelf_used") else "open",
			"CARRIAGE 317 / SHELF BY BEDROLL",
			"base",
		))
	if _has_reached_ashmere():
		progress.append(_optional_progress(
			"Get Imogen from clinic to workshop",
			"SAFE" if WorldState.has_flag(IMOGEN_RESCUED_FLAG) else ("ESCORTING" if WorldState.has_flag(IMOGEN_ESCORT_FLAG) else "NEEDS HELP"),
			"complete" if WorldState.has_flag(IMOGEN_RESCUED_FLAG) else "open",
			"ASHMERE / CLINIC TO MAGGIE'S WORKSHOP",
			"ashmere",
			"Repair the junction and escort Imogen",
		))
		if WorldState.has_flag(RAFI_CONNECTED_FLAG):
			progress.append(_optional_progress("88.4 water-works link", "CONNECTED", "complete", "BELLWETHER SCHOOL / NORTH-WEST", "ashmere", "Call Rafi on 88.4"))
		elif WorldState.has_flag(RAFI_DECLINED_FLAG):
			var declined_status := "BACKFEED LOCAL" if WorldState.has_flag(SCHOOL_POWER_FLAG) else "AERIAL GROUNDED"
			progress.append(_optional_progress("88.4 water-works link", declined_status, "closed", "BELLWETHER SCHOOL / NORTH-WEST", "ashmere", "Call Rafi on 88.4"))
		else:
			progress.append(_optional_progress("88.4 water-works link", "NOT CONTACTED", "open", "BELLWETHER SCHOOL / NORTH-WEST", "ashmere", "Call Rafi on 88.4"))
		progress.append(_trace_task(&"echo_clinic_triage", "Catalogue the clinic's paper list", "ASHMERE CLINIC / SOUTH-EAST", "ashmere"))
		progress.append(_trace_task(&"echo_bus_ledger", "Catalogue the bus driver's ledger", "ASHMERE BUS DEPOT / SOUTH-WEST", "ashmere"))
	if _has_reached_broadcast():
		progress.append(_optional_progress(
			"Verify the evacuation road",
			"CONTRADICTIONS %d / 3" % get_road_trace_count(),
			"complete" if WorldState.has_flag(&"wrenfield_route_verified") else "open",
			"WRENFIELD / THREE PHYSICAL RECORDS",
			"broadcast",
			"Cross-check road control against physical evidence",
		))
		if WorldState.has_flag(REPEATER_ONLINE_FLAG):
			progress.append(_optional_progress("Public warning line", "ONLINE", "complete", "WRENFIELD / REPEATER SHELTER, SOUTH-WEST", "broadcast", "Restore the public warning line"))
		elif WorldState.has_flag(REPEATER_DECLINED_FLAG):
			progress.append(_optional_progress("Public warning line", "FUSE REMOVED", "closed", "WRENFIELD / REPEATER SHELTER, SOUTH-WEST", "broadcast", "Restore the public warning line"))
		else:
			progress.append(_optional_progress("Public warning line", "NOT DECIDED", "open", "WRENFIELD / REPEATER SHELTER, SOUTH-WEST", "broadcast", "Restore the public warning line"))
		progress.append(_trace_task(&"echo_names_wall", "Catalogue the names wall", "WRENFIELD / SOUTH-WEST FENCE", "broadcast"))
		progress.append(_trace_task(&"echo_relay_warning", "Catalogue Maggie's weather test", "WRENFIELD / WEST CABLE HOUSE", "broadcast"))
		progress.append(_trace_task(&"echo_driver_call", "Catalogue the stranded driver's call", "WRENFIELD / EAST LAY-BY", "broadcast"))
	return progress


func get_optional_focus() -> Dictionary:
	var area := _current_area()
	for entry in get_optional_progress():
		if String(entry.get("area", "")) == area and String(entry.get("state", "open")) == "open":
			return entry
	return {}


func _repeater_decided() -> bool:
	return (
		WorldState.has_flag(REPEATER_ONLINE_FLAG)
		or WorldState.has_flag(REPEATER_DECLINED_FLAG)
	)


func _has_reached_ashmere() -> bool:
	var path := _current_level_path()
	return (
		path == ASHMERE_SCENE
		or path == BROADCAST_SCENE
		or path == CHOIR_SCENE
		or WorldState.has_flag(&"ashmere_opened")
		or WorldState.has_flag(&"mara_contacted")
	)


func _has_reached_broadcast() -> bool:
	var path := _current_level_path()
	return (
		path == BROADCAST_SCENE
		or path == CHOIR_SCENE
		or WorldState.has_flag(&"broadcast_opened")
		or get_restored_relay_count() > 0
		or _repeater_decided()
	)


func _clinic_line_result() -> String:
	if WorldState.has_flag(RAFI_CONNECTED_FLAG):
		return "Rafi reads back the Ashmere clinic channel."
	if WorldState.has_flag(RAFI_DECLINED_FLAG):
		return (
			"The local school backfeed carries Imogen's verified clinic read-back, but 88.4 remains unconnected."
			if WorldState.has_flag(SCHOOL_POWER_FLAG)
			else "The clinic carrier holds, but the grounded school set cannot answer it."
		)
	return "The Ashmere clinic channel answers with a clear carrier. Nobody is listening yet."


func _ending_stats() -> String:
	var ending_name := _ending_label(StringName(WorldState.get_flag(&"ending_id", "")))
	return "Outcome: %s\nTraces: %d / 10\nRoad records: %d / 3\nLine relays: %d / 3\nImogen: %s\nJunction: %s\nRafi: %s\nRafi field role: %s\nPublic repeater: %s" % [
		ending_name, ArchiveSystem.get_count(), get_road_trace_count(), get_restored_relay_count(),
		"safe at Maggie's workshop" if WorldState.has_flag(IMOGEN_RESCUED_FLAG) else "unaccounted for",
		"clinic lift" if WorldState.has_flag(CLINIC_POWER_FLAG) else "school aerial",
		get_rafi_status(),
		"east-line cover" if WorldState.has_flag(&"rafi_field_defense") else ("public-repeater guard" if WorldState.has_flag(&"rafi_field_repeater") else "not assigned"),
		get_public_repeater_status(),
	]


func _ending_label(ending_id: StringName) -> String:
	match ending_id:
		&"archive": return "Verified records sent"
		&"silence": return "Exchange power cut"
		&"choir": return "Local packets built"
	return "Unknown"


func _optional_progress(label: String, status: String, state: String, location: String, area: String, task: String = "") -> Dictionary:
	return {
		"label": label,
		"task": task if not task.is_empty() else label,
		"status": status,
		"progress": status,
		"state": state,
		"location": location,
		"area": area,
	}


func _trace_task(trace_id: StringName, task: String, location: String, area: String) -> Dictionary:
	var found := ArchiveSystem.has_echo(trace_id)
	return _optional_progress(task, "CATALOGUED 1 / 1" if found else "TRACE 0 / 1", "complete" if found else "open", location, area)


func _current_area() -> String:
	match _current_level_path():
		GameManager.BASE_SCENE_PATH: return "base"
		RUSTWAY_SCENE: return "rustway"
		ASHMERE_SCENE: return "ashmere"
		BROADCAST_SCENE: return "broadcast"
		CHOIR_SCENE: return "choir"
	return "rustway"


func _has_keepsake() -> bool:
	for item_id in [&"old_photo", &"tin_locket", &"child_lunchbox"]:
		if InventorySystem.get_count(item_id) > 0:
			return true
	return false


func _has_parts(batteries: int, scrap: int) -> bool:
	return InventorySystem.get_count(&"battery") >= batteries and InventorySystem.get_count(&"scrap") >= scrap


func _parts_progress(batteries: int, scrap: int) -> String:
	return "BATTERY %d / %d  /  SCRAP %d / %d" % [
		mini(InventorySystem.get_count(&"battery"), batteries), batteries,
		mini(InventorySystem.get_count(&"scrap"), scrap), scrap,
	]


func _payload(id: StringName, title: String, lines: Array, choices: Array, accent: Color) -> Dictionary:
	return {"id": id, "title": title, "lines": lines, "choices": choices, "accent": accent}


func _objective(chapter: String, text: String, location: String, progress: String, target: String) -> Dictionary:
	return {
		"chapter": chapter,
		"text": text,
		"location": location,
		"progress": progress,
		"target": target,
	}


func _current_level_path() -> String:
	var main := get_tree().get_first_node_in_group("main")
	if main != null and main.has_method("get_current_level_path"): return main.get_current_level_path()
	return ""


func _on_echo_recorded(_data: MemoryEchoData) -> void:
	_emit_progress()
	if get_tree().get_first_node_in_group("main") != null: SaveManager.save_game("")


func _on_upgrade_built(_data) -> void:
	_emit_progress()


func _emit_progress() -> void:
	EventBus.campaign_progress_changed.emit()
