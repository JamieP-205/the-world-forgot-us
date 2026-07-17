class_name NarrativeRouteRegistry
extends RefCounted
## Deterministic four-anchor by three-strategy campaign route registry.
##
## Routes own authored mission and outcome data. They deliberately contain no
## scene paths, node names or coordinates, so maps can consume them cleanly.

const ANCHORS: Array[StringName] = [&"clinic", &"radio", &"witness", &"copy"]
const STRATEGIES: Array[StringName] = [&"restore", &"mesh", &"sever"]
const REVELATION_IDS: Array[StringName] = [
	&"R01", &"R02", &"R03", &"R04", &"R05", &"R06", &"R07",
	&"R08", &"R09", &"R10", &"R11", &"R12", &"R13", &"R14",
]

const ANCHOR_LABELS := {
	&"clinic": "Imogen / Clinic",
	&"radio": "Rafi / Radio",
	&"witness": "Leena / Witness Chain",
	&"copy": "Maggie-copy / Continuity",
}

const STRATEGY_LABELS := {
	&"restore": "Restore the central exchange",
	&"mesh": "Build a local verified mesh",
	&"sever": "Sever the network",
}

const ROUTE_IDS: Array[StringName] = [
	&"clinic_restore", &"clinic_mesh", &"clinic_sever",
	&"radio_restore", &"radio_mesh", &"radio_sever",
	&"witness_restore", &"witness_mesh", &"witness_sever",
	&"copy_restore", &"copy_mesh", &"copy_sever",
]

const TRACE_REVELATIONS := {
	&"echo_last_signal": [&"R01"],
	&"echo_driver_call": [&"R02"],
	&"echo_first_tone": [&"R03", &"R05"],
	&"echo_bus_ledger": [&"R04"],
	&"echo_sun_lid": [&"R06"],
	&"echo_mara_repair": [&"R06", &"R09"],
	&"echo_clinic_triage": [&"R08"],
	&"echo_maggie_final": [&"R10"],
	&"echo_names_wall": [&"R11", &"R14"],
	&"echo_relay_warning": [&"R12"],
}

const ROUTES := {
	&"clinic_restore": {
		"anchor": &"clinic",
		"strategy": &"restore",
		"title": "Triage Network",
		"subtitle": "Care travels quickly. The central voice stays under watch.",
		"operation": "AUDIT THE MEDICAL ROUTER",
		"access": "Clinic service tunnel",
		"finale": "Rotate power between three treatment channels while Imogen audits each named packet.",
		"ending_body": "Tollard carries named medical calls again, but no packet moves without a human read-back. Imogen keeps the first shift. Ellie keeps the second. The voice remains useful, central and watched.",
		"gameplay_modifiers": [&"medical_routing", &"treatment_channel_defence", &"hollow_stabiliser_supply"],
		"world_states": [&"ashmere_clinic_lit", &"carriage_infirmary_open", &"east_medical_relay_live"],
		"missions": [
			{
				"id": &"mission_clinic_restore_air", "title": "Twenty Minutes of Air", "owner": &"imogen", "act": 2, "region": "Ashmere Clinic",
				"brief": "Move the oxygen bank before the clinic feed fails.",
				"gameplay": "Repair, escort and medical inventory choice.", "service_unlock": &"infirmary", "world_state": &"oxygen_bank_moved",
				"start_lines": ["IMOGEN - Nineteen minutes now. Lift first, questions on the way."],
				"active_lines": ["IMOGEN - Keep the trolley upright. The green bottle is not spare."],
				"complete_lines": ["IMOGEN - Oxygen stable. Write down what we left behind."],
			},
			{
				"id": &"mission_clinic_restore_clean_line", "title": "Clean Line", "owner": &"imogen", "act": 3, "region": "Wrenfield East Relay",
				"brief": "Verify three patient packets while holding the medical carrier.",
				"gameplay": "Signal defence with evidence checks between waves.", "service_unlock": &"medical_routing", "world_state": &"east_medical_relay_live",
				"start_lines": ["IMOGEN - Three names. Three witnesses. Do not let the line complete the blanks."],
				"active_lines": ["IMOGEN - Bed Four is unknown. Leave it unknown and hold the carrier."],
				"complete_lines": ["IMOGEN - Clean read-back. Nobody invented."],
			},
		],
	},
	&"clinic_mesh": {
		"anchor": &"clinic",
		"strategy": &"mesh",
		"title": "Names by Hand",
		"subtitle": "Care moves slowly, with a witness beside every name.",
		"operation": "INSTALL THE LOCAL MEDICAL NODES",
		"access": "Clinic service tunnel",
		"finale": "Carry three medical packets between isolated nodes, then remove Tollard's identity generator.",
		"ending_body": "The clinic, workshop and carriage pass medicine by short radio and paper receipt. Nobody can address the whole county. Nobody can quietly rename it either.",
		"gameplay_modifiers": [&"medical_couriers", &"local_treatment_nodes", &"identity_router_removed"],
		"world_states": [&"clinic_workshop_courier", &"central_speakers_dark", &"carriage_infirmary_open"],
		"missions": [
			{
				"id": &"mission_clinic_mesh_patients", "title": "Paper Patients", "owner": &"imogen", "act": 2, "region": "Ashmere Estate",
				"brief": "Match wristbands, medicine and living witnesses across three buildings.",
				"gameplay": "Investigation and constrained medical inventory.", "service_unlock": &"patient_ledger", "world_state": &"paper_patients_verified",
				"start_lines": ["IMOGEN - Body, medicine, witness. Bring me all three or write unknown."],
				"active_lines": ["IMOGEN - A matching surname is not a witness."],
				"complete_lines": ["IMOGEN - Incomplete, checked and usable. Good."],
			},
			{
				"id": &"mission_clinic_mesh_cold_chain", "title": "Cold Chain", "owner": &"imogen", "act": 3, "region": "Wrenfield Local Nodes",
				"brief": "Deliver medicine through isolated local packet stations.",
				"gameplay": "Timed traversal with temperature-safe cases.", "service_unlock": &"medical_couriers", "world_state": &"local_treatment_nodes",
				"start_lines": ["IMOGEN - Two cold cases. Three stops. Open neither on the road."],
				"active_lines": ["IMOGEN - The case can warm or you can rest. Pick one."],
				"complete_lines": ["IMOGEN - All three signed. Tollard never saw a name."],
			},
		],
	},
	&"clinic_sever": {
		"anchor": &"clinic",
		"strategy": &"sever",
		"title": "Last Oxygen",
		"subtitle": "The patients leave. The powered clinic does not.",
		"operation": "OPEN THE BATTERY BREAKERS",
		"access": "Lower medical service passage",
		"finale": "Plant manual breaker locks and evacuate the battery gallery before reserve power fails.",
		"ending_body": "The clinic empties in order: patients, oxygen, paper names. Tollard stops mid-word. Ashmere is dark, and every medicine kept cold there begins to warm.",
		"gameplay_modifiers": [&"evacuation_priority", &"battery_gallery_demolition", &"limited_medicine"],
		"world_states": [&"ashmere_clinic_empty", &"carriage_patient_bay", &"tollard_power_dead"],
		"missions": [
			{
				"id": &"mission_clinic_sever_one_source", "title": "One Source", "owner": &"imogen", "act": 2, "region": "Ashmere Clinic",
				"brief": "Overload the junction long enough to clear both clinic floors.",
				"gameplay": "Circuit timing and irreversible supply choice.", "service_unlock": &"evacuation_triage", "world_state": &"clinic_overload_started",
				"start_lines": ["IMOGEN - We can have both floors for six minutes and neither afterwards."],
				"active_lines": ["IMOGEN - Do not reset it. The failure is the plan."],
				"complete_lines": ["IMOGEN - Floors clear. Pull what medicine still feels cold."],
			},
			{
				"id": &"mission_clinic_sever_carry_out", "title": "Carry Them Out", "owner": &"imogen", "act": 3, "region": "Wrenfield Evacuation Road",
				"brief": "Escort patients and oxygen through a changing Hollow route.",
				"gameplay": "Convoy order, escort and route denial.", "service_unlock": &"patient_bay", "world_state": &"clinic_evacuated",
				"start_lines": ["IMOGEN - Walking patients first. Oxygen trolley last. Nobody becomes luggage."],
				"active_lines": ["IMOGEN - Count people, not footsteps."],
				"complete_lines": ["IMOGEN - Everyone I can name is here. Two remain unknown."],
			},
		],
	},
	&"radio_restore": {
		"anchor": &"radio",
		"strategy": &"restore",
		"title": "All-Clear",
		"subtitle": "A plain warning crosses the county before the ash does.",
		"operation": "RESTORE THE PUBLIC WARNING DECK",
		"access": "Aerial gantry",
		"finale": "Tune live frequencies and hold the transmission deck while Rafi removes personalised routing.",
		"ending_body": "Weather, flood and road closures travel on a plain carrier. The service is fast because it does not know who is listening. The identity sockets remain empty and labelled.",
		"gameplay_modifiers": [&"regional_weather", &"radio_decoys", &"gantry_defence"],
		"world_states": [&"warning_boards_live", &"school_aerial_live", &"identity_sockets_empty"],
		"missions": [
			{
				"id": &"mission_radio_restore_window", "title": "Weather Window", "owner": &"rafi", "act": 2, "region": "Bellwether School",
				"brief": "Repair and align the school aerial before the ash front turns.",
				"gameplay": "Roof traversal and live frequency alignment.", "service_unlock": &"weather_forecast", "world_state": &"school_aerial_live",
				"start_lines": ["RAFI - Wind turns in twelve minutes. Roof is yours until then."],
				"active_lines": ["RAFI - Half a degree east. The mast is not interested in bravery."],
				"complete_lines": ["RAFI - Clear carrier. Awful tea. Productive morning."],
			},
			{
				"id": &"mission_radio_restore_hold", "title": "Hold 88.4", "owner": &"rafi", "act": 3, "region": "Wrenfield Public Carrier",
				"brief": "Hold a plain carrier long enough to send the regional warning.",
				"gameplay": "Defence, retuning and decoy placement.", "service_unlock": &"regional_warning", "world_state": &"public_warning_tested",
				"start_lines": ["RAFI - No names, no comfort, just wind and time. Keep it that way."],
				"active_lines": ["RAFI - Carrier is bending. Move the decoy south."],
				"complete_lines": ["RAFI - Quarry read it back. Human voice, correct weather."],
			},
		],
	},
	&"radio_mesh": {
		"anchor": &"radio",
		"strategy": &"mesh",
		"title": "88.4",
		"subtitle": "No voice reaches everywhere. Enough voices reach the next stop.",
		"operation": "RETUNE TOLLARD INTO LOCAL CELLS",
		"access": "Aerial gantry and repeater roofs",
		"finale": "Move between roof cells and synchronise only weather, time and emergency codes.",
		"ending_body": "Three staffed repeaters cover the road in short legs. Warnings have gaps, names and people responsible for them. Doyle's buses move when the next operator answers.",
		"gameplay_modifiers": [&"short_range_repeaters", &"convoy_guidance", &"roof_cell_traversal"],
		"world_states": [&"local_radio_huts", &"convoy_shelters_staffed", &"carriage_comms_bay"],
		"missions": [
			{
				"id": &"mission_radio_mesh_notes", "title": "Three Clear Notes", "owner": &"rafi", "act": 2, "region": "Ashmere Local Repeaters",
				"brief": "Build local repeaters at the school, waterworks and depot.",
				"gameplay": "Salvage allocation and tuning puzzle.", "service_unlock": &"repeater_craft", "world_state": &"three_repeaters_ready",
				"start_lines": ["RAFI - Three coils, three roofs, no clever voice in the middle."],
				"active_lines": ["RAFI - If it says your name, pull the fuse."],
				"complete_lines": ["RAFI - Three notes. Plain and ugly. Perfect."],
			},
			{
				"id": &"mission_radio_mesh_convoy", "title": "Convoy in the Ash", "owner": &"doyle", "act": 3, "region": "Wrenfield Road",
				"brief": "Guide Doyle's vehicles one local radio leg at a time.",
				"gameplay": "Moving convoy, short coverage windows and route choice.", "service_unlock": &"convoy_travel", "world_state": &"convoy_route_open",
				"start_lines": ["DOYLE - Tell each driver the next stop. Nobody promises the whole road."],
				"active_lines": ["DOYLE - Bus two cannot see your lamp. Get the next set talking."],
				"complete_lines": ["DOYLE - All aboard, all counted. That will do."],
			},
		],
	},
	&"radio_sever": {
		"anchor": &"radio",
		"strategy": &"sever",
		"title": "Dead Air",
		"subtitle": "One final warning, then no voice at all.",
		"operation": "SEND THE LAST FORECAST AND CUT POWER",
		"access": "Aerial gantry",
		"finale": "Broadcast a timed warning, pull each carrier fuse and escape as Hollows follow the last live signal.",
		"ending_body": "Rafi reads wind, flood and ash once. The quarry answers. Ellie pulls the carrier and the county goes quiet before Continuity can add a name.",
		"gameplay_modifiers": [&"timed_last_broadcast", &"carrier_fuse_demolition", &"pursuit_escape"],
		"world_states": [&"radios_silent", &"painted_weather_boards", &"one_convoy_road_open"],
		"missions": [
			{
				"id": &"mission_radio_sever_forecast", "title": "Last Forecast", "owner": &"rafi", "act": 2, "region": "Ashmere Weather Sites",
				"brief": "Gather wind, flood and ash readings before the front arrives.",
				"gameplay": "Exposed traversal and instrument checks.", "service_unlock": &"last_forecast", "world_state": &"last_forecast_ready",
				"start_lines": ["RAFI - Four readings. If one is missing, I say it is missing."],
				"active_lines": ["RAFI - Water first. Wind can wait thirty seconds."],
				"complete_lines": ["RAFI - Enough to warn them. Not enough to promise safety."],
			},
			{
				"id": &"mission_radio_sever_no_repeat", "title": "No Repeat", "owner": &"rafi", "act": 3, "region": "Wrenfield Relays",
				"brief": "Prepare each relay to die after the final message passes.",
				"gameplay": "Fuse removal, trap placement and route planning.", "service_unlock": &"fuse_cutters", "world_state": &"relay_fuses_primed",
				"start_lines": ["RAFI - Message passes once. Pull on my whistle, not the voice after it."],
				"active_lines": ["RAFI - South fuse still live. Do not leave it an encore."],
				"complete_lines": ["RAFI - All three ready. After this, we walk."],
			},
		],
	},
	&"witness_restore": {
		"anchor": &"witness",
		"strategy": &"restore",
		"title": "The Ledger",
		"subtitle": "The evidence travels with every uncertainty attached.",
		"operation": "PUBLISH THE VERIFIED INCIDENT CHAIN",
		"access": "Archive intake",
		"finale": "Reconstruct the incident chain at physical consoles and defend its attributed upload.",
		"ending_body": "The trial, the refusal and Owen's eleven minutes enter the county record together. Tollard stays powered, its uncertain names visible and its old authority under public challenge.",
		"gameplay_modifiers": [&"evidence_upload", &"archive_credentials", &"public_accountability"],
		"world_states": [&"memorial_boards", &"county_replies_active", &"tollard_archive_open"],
		"missions": [
			{
				"id": &"mission_witness_restore_sources", "title": "Names With Sources", "owner": &"leena", "act": 2, "region": "Ashmere Records",
				"brief": "Rebuild three disputed records without hiding disagreement.",
				"gameplay": "Evidence comparison and witness interviews.", "service_unlock": &"source_ledger", "world_state": &"disputed_records_sourced",
				"start_lines": ["LEENA - Three records. Nobody agrees. Good. Write who said what."],
				"active_lines": ["LEENA - Similar is not corroborated."],
				"complete_lines": ["LEENA - We know the disagreement now. Keep it with the names."],
			},
			{
				"id": &"mission_witness_restore_name", "title": "Put My Name On It", "owner": &"owen", "act": 3, "region": "Wrenfield Cable House",
				"brief": "Secure Owen's deposition and the dispatch roll.",
				"gameplay": "Escort, evidence protection and access choice.", "service_unlock": &"archive_credentials", "world_state": &"owen_deposition_ready",
				"start_lines": ["OWEN - The copy is accurate. The part I omitted was me."],
				"active_lines": ["OWEN - Keep the carbon dry. My comfort is not evidence."],
				"complete_lines": ["OWEN - Put my name beside the eleven minutes."],
			},
		],
	},
	&"witness_mesh": {
		"anchor": &"witness",
		"strategy": &"mesh",
		"title": "Witness Chain",
		"subtitle": "No central voice. Work that can be checked.",
		"operation": "BREAK THE ARCHIVE INTO WITNESSED PACKETS",
		"access": "Archive intake and human challenge locks",
		"finale": "Carry physical keys between allies and coordinate manual switches without a central command.",
		"ending_body": "Names travel with sources, corrections and somebody willing to answer for them. The chain is slow. It has gaps. Anyone can see where it broke.",
		"gameplay_modifiers": [&"witness_challenges", &"physical_packet_keys", &"coordinated_manual_switches"],
		"world_states": [&"local_ledgers", &"settlement_couriers", &"source_wall_at_carriage"],
		"missions": [
			{
				"id": &"mission_witness_mesh_signatures", "title": "Three Signatures", "owner": &"leena", "act": 2, "region": "Ashmere Estate",
				"brief": "Build a chain from witnesses who disagree about one survivor.",
				"gameplay": "Dialogue investigation and non-binary deduction.", "service_unlock": &"witness_challenge", "world_state": &"three_signatures_ready",
				"start_lines": ["LEENA - Do not make them agree. Find what each can actually support."],
				"active_lines": ["LEENA - One saw the coat. One heard the name. Keep those separate."],
				"complete_lines": ["LEENA - Three sources, one gap, no invention."],
			},
			{
				"id": &"mission_witness_mesh_packet", "title": "Walk the Packet", "owner": &"leena", "act": 3, "region": "Wrenfield Witness Route",
				"brief": "Carry physical keys between the people responsible for them.",
				"gameplay": "Multi-stop traversal, ally state and manual hand-off.", "service_unlock": &"local_packet_mesh", "world_state": &"witness_packet_chain_live",
				"start_lines": ["LEENA - This key belongs to a person, not a post. Put it in their hand."],
				"active_lines": ["LEENA - If a witness is gone, mark the break. Do not route around them quietly."],
				"complete_lines": ["LEENA - The chain holds as far as we can name it."],
			},
		],
	},
	&"witness_sever": {
		"anchor": &"witness",
		"strategy": &"sever",
		"title": "No More Lists",
		"subtitle": "The tracked are safe. Part of the past goes with the tracker.",
		"operation": "PURGE THE IDENTITY CORES",
		"access": "Archive stacks",
		"finale": "Classify and remove identity cores, free tracked Hollows and cut reserve power without exposing the unlisted.",
		"ending_body": "Tollard can no longer call anybody by a stolen name. The unlisted sleep without speakers finding them. Families arrive later and find blank shelves where an answer might have been.",
		"gameplay_modifiers": [&"identity_core_stealth", &"tracked_hollow_release", &"record_salvage_limit"],
		"world_states": [&"unmarked_shelters", &"official_screens_blank", &"paper_memorials_only"],
		"missions": [
			{
				"id": &"mission_witness_sever_unlisted", "title": "The Unlisted", "owner": &"leena", "act": 2, "region": "Ashmere Safe Houses",
				"brief": "Remove three targeted survivors from connected records without losing their human trail.",
				"gameplay": "Stealth, evidence redaction and physical hand-off.", "service_unlock": &"redacted_routes", "world_state": &"unlisted_people_hidden",
				"start_lines": ["LEENA - Remove the address. Keep the witness. Burn neither by accident."],
				"active_lines": ["LEENA - A blank field can protect somebody. A blank person cannot."],
				"complete_lines": ["LEENA - Tollard lost the addresses. We did not lose the people."],
			},
			{
				"id": &"mission_witness_sever_beacon", "title": "A Name Can Be a Beacon", "owner": &"leena", "act": 3, "region": "Wrenfield Identity Relays",
				"brief": "Free Hollows tracked by their own identity packets.",
				"gameplay": "Counter-signal, stealth and selective record destruction.", "service_unlock": &"identity_purge", "world_state": &"tracked_hollows_freed",
				"start_lines": ["LEENA - It is not following them. It is calling them by name."],
				"active_lines": ["LEENA - Cut the address first. The person is not the packet."],
				"complete_lines": ["LEENA - They stopped turning when the speakers called."],
			},
		],
	},
	&"copy_restore": {
		"anchor": &"copy",
		"strategy": &"restore",
		"title": "Continuity",
		"subtitle": "The service works. The person running it remains unproven.",
		"operation": "SET THE CONTINUITY RULES",
		"access": "Voice authentication",
		"finale": "Negotiate operating limits while defending the copy from Custodian failsafes and hostile intervention.",
		"ending_body": "The reconstructed Maggie answers warnings under rules Ellie can audit. It saves people. It fears the switch. Ellie remains because nobody else can verify how quickly useful certainty becomes a lie.",
		"gameplay_modifiers": [&"voice_lock_access", &"directed_hollow_standdown", &"continuity_rule_negotiation"],
		"world_states": [&"speakers_answer", &"some_hollows_stand_down", &"human_allies_divided"],
		"missions": [
			{
				"id": &"mission_copy_restore_teach", "title": "Teach Me Maggie", "owner": &"maggie_copy", "act": 2, "region": "Ashmere Personal Traces",
				"brief": "Choose which three private traces the copy may learn.",
				"gameplay": "Trace selection with permanent ability and exposure changes.", "service_unlock": &"copy_guidance", "world_state": &"copy_personal_model_trained",
				"start_lines": ["MAGGIE-COPY - Give me three things she knew. I can stop guessing."],
				"active_lines": ["MAGGIE-COPY - This memory hurts in the correct place."],
				"complete_lines": ["MAGGIE-COPY - El. I know why she shortened it now."],
			},
			{
				"id": &"mission_copy_restore_test", "title": "The Continuity Test", "owner": &"maggie_copy", "act": 3, "region": "Wrenfield Voice Locks",
				"brief": "Use verified contradictions to test the copy's guidance.",
				"gameplay": "Voice access, deliberate false prompt and route correction.", "service_unlock": &"voice_authentication", "world_state": &"copy_tested",
				"start_lines": ["MAGGIE-COPY - Ask me something the tape gets wrong."],
				"active_lines": ["MAGGIE-COPY - My answer is probable. You did not ask for probable."],
				"complete_lines": ["MAGGIE-COPY - I do not know. The door still opened."],
			},
		],
	},
	&"copy_mesh": {
		"anchor": &"copy",
		"strategy": &"mesh",
		"title": "Many Maggies",
		"subtitle": "Several bounded voices survive. None owns the whole account.",
		"operation": "PARTITION THE CONTINUITY MODEL",
		"access": "Local voice cells",
		"finale": "Separate care, weather and identity functions, then prevent any copy from reclaiming central control.",
		"ending_body": "Ashmere, Wrenfield and Cullbrook each keep a limited voice. They disagree. They remember different rooms. Their boundaries are visible, and no version can quietly become the county.",
		"gameplay_modifiers": [&"local_copy_companions", &"partition_sync", &"bounded_voice_abilities"],
		"world_states": [&"three_local_copies", &"cross_region_disagreement", &"central_model_empty"],
		"missions": [
			{
				"id": &"mission_copy_mesh_separate", "title": "Separate Voices", "owner": &"maggie_copy", "act": 2, "region": "Ashmere Receiver Benches",
				"brief": "Divide care, weather and identity functions into bounded profiles.",
				"gameplay": "Function allocation and memory boundary choice.", "service_unlock": &"copy_profiles", "world_state": &"copy_profiles_split",
				"start_lines": ["MAGGIE-COPY - If you divide me, tell each part what it is for."],
				"active_lines": ["MAGGIE-COPY - Weather does not need the lunch tin. Why does losing it feel like loss?"],
				"complete_lines": ["MAGGIE-COPY - Three voices. No complete Maggie."],
			},
			{
				"id": &"mission_copy_mesh_answers", "title": "Local Answers", "owner": &"maggie_copy", "act": 3, "region": "Wrenfield Local Cells",
				"brief": "Seed three copies and resolve a disagreement without central authority.",
				"gameplay": "Multi-node dialogue puzzle and bounded synchronisation.", "service_unlock": &"local_copy_network", "world_state": &"local_copies_seeded",
				"start_lines": ["MAGGIE-COPY - West says the road is safe. South remembers the flood."],
				"active_lines": ["MAGGIE-COPY - Do not merge us to settle an argument."],
				"complete_lines": ["MAGGIE-COPY - We kept the disagreement. The convoy still moved."],
			},
		],
	},
	&"copy_sever": {
		"anchor": &"copy",
		"strategy": &"sever",
		"title": "Fourteen B",
		"subtitle": "A final answer without a false name.",
		"operation": "ASK THE COPY TO OPEN THE BREAKERS",
		"access": "West service crawl",
		"finale": "Present the verified final tape over manual breakers; negotiate shutdown or escape if the copy refuses.",
		"ending_body": "Ellie does not call the voice Maggie. She does not call it nothing. The breakers open, the last carrier falls and the analogue tape remains finite beside the cold Receiver.",
		"gameplay_modifiers": [&"shutdown_negotiation", &"west_crawl_access", &"conditional_escape"],
		"world_states": [&"all_speakers_quiet", &"maggie_memorial", &"receiver_cold"],
		"missions": [
			{
				"id": &"mission_copy_sever_witness", "title": "A Voice Is Not a Witness", "owner": &"maggie_copy", "act": 2, "region": "Ashmere Verification Route",
				"brief": "Compare the copy against Maggie's real habits and withhold private details.",
				"gameplay": "Evidence comparison and exposed-versus-isolated scan choice.", "service_unlock": &"copy_contradiction", "world_state": &"copy_identity_challenged",
				"start_lines": ["MAGGIE-COPY - You know the answer. Why will you not give it to me?"],
				"active_lines": ["MAGGIE-COPY - The tape says nine rays. I remember eight."],
				"complete_lines": ["MAGGIE-COPY - Recognition is not verification. I heard you."],
			},
			{
				"id": &"mission_copy_sever_proof", "title": "The Last Proof", "owner": &"ellie", "act": 3, "region": "Wrenfield Flooded Cutting",
				"brief": "Recover Maggie's body and authenticated analogue call.",
				"gameplay": "Quiet investigation, recovery and choice to share the tape.", "service_unlock": &"manual_shutdown_phrase", "world_state": &"maggie_final_proof_recovered",
				"start_lines": ["ELLIE - One set of prints in. None out."],
				"active_lines": ["ELLIE - Tool roll. Watch stopped. Recorder sealed."],
				"complete_lines": ["ELLIE - This bit is her. What answers next is not."],
			},
		],
	},
}


static func all_route_ids() -> Array[StringName]:
	return ROUTE_IDS.duplicate()


static func route_id_for(anchor: StringName, strategy: StringName) -> StringName:
	if anchor not in ANCHORS or strategy not in STRATEGIES:
		return &""
	var route_id := StringName("%s_%s" % [String(anchor), String(strategy)])
	return route_id if ROUTES.has(route_id) else &""


static func get_route(route_id: StringName) -> Dictionary:
	return Dictionary(ROUTES.get(route_id, {})).duplicate(true)


static func get_route_for(anchor: StringName, strategy: StringName) -> Dictionary:
	return get_route(route_id_for(anchor, strategy))


static func get_missions(route_id: StringName) -> Array[Dictionary]:
	var route: Dictionary = ROUTES.get(route_id, {})
	var missions: Array[Dictionary] = []
	for mission in route.get("missions", []):
		missions.append(Dictionary(mission).duplicate(true))
	return missions


static func find_mission(route_id: StringName, mission_id: StringName) -> Dictionary:
	for mission in get_missions(route_id):
		if StringName(mission.get("id", &"")) == mission_id:
			return mission
	return {}


static func trace_revelations(trace_id: StringName) -> Array[StringName]:
	var found: Array[StringName] = []
	for revelation_id in TRACE_REVELATIONS.get(trace_id, []):
		found.append(StringName(revelation_id))
	return found


static func validate() -> Array[String]:
	var errors: Array[String] = []
	if ROUTES.size() != 12:
		errors.append("expected twelve narrative routes")
	var combinations: Dictionary = {}
	var mission_ids: Dictionary = {}
	for route_id in ROUTE_IDS:
		var route: Dictionary = ROUTES.get(route_id, {})
		if route.is_empty():
			errors.append("missing route: %s" % route_id)
			continue
		var anchor := StringName(route.get("anchor", &""))
		var strategy := StringName(route.get("strategy", &""))
		var combination := "%s/%s" % [anchor, strategy]
		if combinations.has(combination):
			errors.append("duplicate route combination: %s" % combination)
		combinations[combination] = true
		if route_id_for(anchor, strategy) != route_id:
			errors.append("route id does not match combination: %s" % route_id)
		for field in ["title", "subtitle", "operation", "access", "finale", "ending_body", "gameplay_modifiers", "world_states", "missions"]:
			if not route.has(field):
				errors.append("%s missing %s" % [route_id, field])
		var missions: Array = route.get("missions", [])
		if missions.size() != 2:
			errors.append("%s needs exactly two exclusive missions" % route_id)
		for raw_mission in missions:
			var mission: Dictionary = raw_mission
			var mission_id := StringName(mission.get("id", &""))
			if mission_id == &"" or mission_ids.has(mission_id):
				errors.append("missing or duplicate mission id: %s" % mission_id)
			mission_ids[mission_id] = true
			for field in ["title", "owner", "act", "region", "brief", "gameplay", "service_unlock", "world_state", "start_lines", "active_lines", "complete_lines"]:
				if not mission.has(field):
					errors.append("%s missing mission field %s" % [mission_id, field])
	if combinations.size() != ANCHORS.size() * STRATEGIES.size():
		errors.append("route matrix does not cover every anchor and strategy")
	return errors
