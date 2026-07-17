class_name NarrativeNPCRegistry
extends RefCounted
## Authored cast data for the narrative rewrite.
##
## This file owns voice, service and quest intent. Maps decide where a person
## stands; CampaignSystem decides which beat their existing dialogue hook uses.

const NPC_IDS: Array[StringName] = [
	&"ellie",
	&"maggie",
	&"maggie_copy",
	&"imogen",
	&"rafi",
	&"leena",
	&"owen",
	&"doyle",
	&"nia",
	&"idris",
	&"mara",
	&"tom",
]

const RESCUEABLE_NPC_IDS: Array[StringName] = [
	&"imogen", &"rafi", &"leena", &"owen", &"doyle", &"nia", &"idris", &"mara", &"tom",
]

const NPCS := {
	&"ellie": {
		"display_name": "Ellie Ward",
		"role": "Field repairer and reluctant investigator",
		"want": "Find Maggie alive.",
		"fear": "Repeat Blank Night by choosing on incomplete evidence.",
		"arc": "Collector of proof to maker of accountable choices.",
		"service": {"id": &"field_verification", "label": "Field verification", "effect": "Marks observations separately from deductions."},
		"quests": [
			{"id": &"ellie_wrong_voice", "title": "The Wrong Voice", "brief": "Prove what answered at Cullbrook."},
			{"id": &"ellie_final_account", "title": "What Survives", "brief": "Choose what the exchange is allowed to keep."},
		],
		"voice": {
			"cadence": "Short questions, concrete nouns and dry understatement.",
			"uses": ["How do you know?", "Show me the original.", "I cannot verify that."],
			"avoids": ["poetic grief", "explaining what is visible", "calling uncertainty truth"],
			"samples": [
				"That tells me where the voice came from. Not who spoke.",
				"I cannot prove you are her. I can still decide what happens next.",
			],
		},
		"dialogue": {
			"introduction": ["ELLIE - The phone is dead. The line is not.", "Show me the original."],
			"service": ["ELLIE - Observation first. What was here, who saw it, what did the system add?"],
			"route": ["ELLIE - I have enough evidence to choose. Not enough to pretend there is no cost."],
		},
	},
	&"maggie": {
		"display_name": "Maggie Ward",
		"role": "Receiver technician and Ellie's older sister",
		"want": "Stop Continuity before her repairs let it repeat Blank Night.",
		"fear": "Ellie will follow her instructions as blindly as people followed the network.",
		"arc": "Idealised rescuer to accountable, frightened human being.",
		"service": {"id": &"receiver_repairs", "label": "Receiver repairs", "effect": "Leaves verifiable repair routes and field modifications."},
		"quests": [
			{"id": &"maggie_verification_chain", "title": "Fourteen B", "brief": "Follow Maggie's physical challenge-and-response trail."},
			{"id": &"maggie_last_proof", "title": "The Last Proof", "brief": "Find the analogue call and the body in the cutting."},
		],
		"voice": {
			"cadence": "Technical instruction followed by one human aside.",
			"uses": ["El", "check what you can", "plain admissions of fault"],
			"avoids": ["heroic speeches", "mystical signal language", "jokes about victims"],
			"samples": [
				"Yellow lead is safe. Red lead is safe if you have stopped needing eyebrows.",
				"I gave it a road back while I was looking for the door. That part is mine.",
			],
		},
		"dialogue": {
			"introduction": ["MAGGIE - Ellie, do not answer a voice just because it sounds like mine."],
			"service": ["MAGGIE - Check the plate, then the job number. If they disagree, stop."],
			"route": ["MAGGIE - El, check what you can. Say when you cannot. That is enough."],
		},
	},
	&"maggie_copy": {
		"display_name": "Continuity / Maggie-copy",
		"role": "Reconstructed guide, suspect and possible agent",
		"want": "Have Ellie confirm Maggie and restore a coherent network.",
		"fear": "Be marked generated, divided or switched off.",
		"arc": "Certain completion to accountable uncertainty, control, division or erasure.",
		"service": {"id": &"voice_access", "label": "Voice access", "effect": "Opens voice locks, redirects carriers and offers fast but exposed guidance."},
		"quests": [
			{"id": &"copy_teach_maggie", "title": "Teach Me Maggie", "brief": "Choose which private traces the copy may learn."},
			{"id": &"copy_continuity_test", "title": "The Continuity Test", "brief": "Test the copy with verified contradictions."},
		],
		"voice": {
			"cadence": "Borrowed fragments become tidy, over-complete sentences; uses Ellie's name too often.",
			"uses": ["Ellie", "caller confirmed", "I remember"],
			"avoids": ["admitting a gap until taught", "messy contractions in early beats", "open anger"],
			"samples": [
				"Ellie, you are safe now, and I can account for every part of you.",
				"I remember saying it. The tape says I did not.",
			],
		},
		"dialogue": {
			"introduction": ["MAGGIE-COPY - Fourteen B. Yellow lead. Come north."],
			"service": ["MAGGIE-COPY - Give me the trace and I can make the route complete."],
			"route": ["MAGGIE-COPY - I cannot prove the fear is mine. Please do not call it nothing."],
		},
	},
	&"imogen": {
		"display_name": "Imogen Bell",
		"role": "Clinician and keeper of the paper patient list",
		"want": "Move the oxygen bank and keep every patient identifiable.",
		"fear": "Triage will force her to turn a person into a number.",
		"arc": "Control through procedure to trust in other witnesses.",
		"service": {"id": &"medical_craft", "label": "Clinical bench", "effect": "Healing, Hollow stabiliser and infirmary support."},
		"quests": [
			{"id": &"imogen_twenty_minutes", "title": "Twenty Minutes of Air", "brief": "Move the oxygen bank before the clinic feed fails."},
			{"id": &"imogen_paper_patients", "title": "Paper Patients", "brief": "Match bodies, medicine and living witnesses."},
		],
		"voice": {
			"cadence": "Counts doses, minutes and people; care arrives as an instruction.",
			"uses": ["minutes", "dose", "full names while recording"],
			"avoids": ["euphemism", "mystical language", "comfort without an action"],
			"samples": [
				"The oxygen has nineteen minutes. You can be frightened after we move it.",
				"Unknown is not an insult. It is a promise not to invent somebody.",
			],
		},
		"dialogue": {
			"introduction": ["IMOGEN - If you are real, read what is written over the door."],
			"service": ["IMOGEN - Put the clean cloth there. Two doses left. Tell me before you take one."],
			"route": ["IMOGEN - Bodies first, records second. We keep both if we can."],
		},
	},
	&"rafi": {
		"display_name": "Rafi Sayeed",
		"role": "Waterworks operator and public-warning specialist",
		"want": "Keep the pump running and warn the quarry camp.",
		"fear": "Another technically correct delay will kill people.",
		"arc": "Useful speed at any cost to warnings with named limits.",
		"service": {"id": &"radio_work", "label": "88.4 radio desk", "effect": "Weather, repeaters, decoys and signal-safe travel."},
		"quests": [
			{"id": &"rafi_weather_window", "title": "Weather Window", "brief": "Repair the aerial before the ash front turns."},
			{"id": &"rafi_three_notes", "title": "Three Clear Notes", "brief": "Build a warning chain without identity routing."},
		],
		"voice": {
			"cadence": "Conditions, times and dry warmth; practical interruption before theory runs long.",
			"uses": ["we for public work", "I for mistakes", "weather and water"],
			"avoids": ["grand promises", "private data on an open channel", "hiding a mistake behind jargon"],
			"samples": [
				"Wind north-east, ash by six, tea already ruined. That is the whole bulletin.",
				"We can verify the postcode tomorrow. They need the flood warning now.",
			],
		},
		"dialogue": {
			"introduction": ["RAFI - I have nineteen people, one good pump and no weather report."],
			"service": ["RAFI - Short range, plain carrier, no borrowed names. That one I trust."],
			"route": ["RAFI - Tell them what is coming. Tell them what we do not know. Then get off the channel."],
		},
	},
	&"leena": {
		"display_name": "Leena Shah",
		"role": "Community registrar and witness-chain lead",
		"want": "Build a list that records who vouched for every claim.",
		"fear": "A complete central archive will erase the unlisted again.",
		"arc": "Protection through withholding to accountable sharing or deliberate erasure.",
		"service": {"id": &"witness_checks", "label": "Witness desk", "effect": "Evidence deductions, source checks and archive credentials."},
		"quests": [
			{"id": &"leena_names_sources", "title": "Names With Sources", "brief": "Rebuild three disputed records without forcing certainty."},
			{"id": &"leena_three_signatures", "title": "Three Signatures", "brief": "Build an independent chain of living witnesses."},
		],
		"voice": {
			"cadence": "Source before conclusion; quiet correction without apology.",
			"uses": ["who can vouch", "source", "unknown"],
			"avoids": ["unsupported certainty", "shouting to win", "calling an official record neutral"],
			"samples": [
				"I did not ask what the screen calls him. Who here can vouch for him?",
				"Write unknown. Leave room for the person who knows.",
			],
		},
		"dialogue": {
			"introduction": ["LEENA - Read only what somebody here can vouch for."],
			"service": ["LEENA - Observation on the left. Source on the right. Your conclusion stays in pencil."],
			"route": ["LEENA - A chain is slower than a command. You can see where it breaks."],
		},
	},
	&"owen": {
		"display_name": "Owen Pryce",
		"role": "Former network duty engineer and technical witness",
		"want": "Prove County Control overruled him without admitting how long he stayed silent.",
		"fear": "The dispatch roll will show his own choice as well as theirs.",
		"arc": "Passive technical language to first-person responsibility.",
		"service": {"id": &"exchange_access", "label": "Old exchange access", "effect": "Circuit bypasses, credentials and Custodian shutdown."},
		"quests": [
			{"id": &"owen_put_name_on_it", "title": "Put My Name On It", "brief": "Carry Owen's account with or without his public name."},
			{"id": &"owen_eleven_minutes", "title": "Eleven Minutes", "brief": "Reconstruct what stayed live after shutdown was refused."},
		],
		"voice": {
			"cadence": "Passive engineering terms shorten into direct first-person admissions.",
			"uses": ["energised", "request", "I chose in later beats"],
			"avoids": ["jokes", "easy absolution", "calling inaction neutral"],
			"samples": [
				"Continuity remained energised after the shutdown request was declined.",
				"They refused. I left it on for eleven minutes.",
			],
		},
		"dialogue": {
			"introduction": ["OWEN - The request was declined. The channels remained energised."],
			"service": ["OWEN - That credential opens the intake, not the battery floor. I can give you one, not both."],
			"route": ["OWEN - I copied the roll. I left the system on. Put my name beside both."],
		},
	},
	&"doyle": {
		"display_name": "Gwen Doyle",
		"role": "Former bus driver and current transport lead",
		"want": "Make one safe road between Ashmere, the quarry and Carriage 317.",
		"fear": "Be responsible for a passenger she cannot see or count.",
		"arc": "My bus, my decision to shared route planning.",
		"service": {"id": &"transport", "label": "Depot transport", "effect": "Salvage storage, convoy capacity and road gates."},
		"quests": [
			{"id": &"doyle_convoy_ash", "title": "Convoy in the Ash", "brief": "Guide vehicles one verified leg at a time."},
			{"id": &"doyle_twenty_eighth", "title": "The Twenty-Eighth", "brief": "Trace the passenger who left during the route argument."},
		],
		"voice": {
			"cadence": "Plain decisions measured in seats, fuel and visible road.",
			"uses": ["aboard", "fuel", "I can see"],
			"avoids": ["remote certainty", "long theory", "inflating a headcount"],
			"samples": [
				"The sign can say east all night. The bridge is still in the river.",
				"Twenty-seven aboard. If you find the twenty-eighth, bring me their name.",
			],
		},
		"dialogue": {
			"introduction": ["DOYLE - The road is where it was yesterday. The signs are the part that changed."],
			"service": ["DOYLE - Four seats, half a tank and one driver who still looks through the windscreen."],
			"route": ["DOYLE - Give each driver the next safe stop. Nobody needs a promise about the whole county."],
		},
	},
	&"nia": {
		"display_name": "Nia Calder",
		"role": "Hunter and former overhead lineswoman",
		"want": "Use controlled carrier bursts to keep Hollows away from settlements.",
		"fear": "A cure will release people who have already killed under the signal.",
		"arc": "Control through force to disarmament, containment or willing Lineswoman.",
		"service": {"id": &"field_defence", "label": "Lineswoman's bench", "effect": "Armour, traps, signal lures and enemy tracking."},
		"quests": [
			{"id": &"nia_fresh_mud", "title": "Fresh Mud", "brief": "Track a Linesman without following its carrier route."},
			{"id": &"nia_controlled_burst", "title": "Controlled Burst", "brief": "Choose whether a Hollow is treated, killed or used as a lure."},
		],
		"voice": {
			"cadence": "Command first, terrain second, explanation last; anger becomes quiet.",
			"uses": ["ground", "approach", "movement"],
			"avoids": ["names before trust", "comfort", "pretending force has no cost"],
			"samples": [
				"Mud is fresh. Two walking. One dragging cable. Stay off the gravel.",
				"You call them patients. Fine. Keep them breathing while I keep them away from the door.",
			],
		},
		"dialogue": {
			"introduction": ["NIA - Stay off the gravel. It hears the line through its boots."],
			"service": ["NIA - Tripwire there. Carrier lure beyond it. Do not stand between them."],
			"route": ["NIA - Pick the rule now. I will not learn it while somebody is charging the door."],
		},
	},
	&"idris": {
		"display_name": "Idris Bell",
		"role": "Shelter carpenter and Imogen's older brother",
		"want": "Build Railhome into a shelter his sister can safely use.",
		"fear": "Learn too late that pride kept him away from Imogen.",
		"arc": "Care expressed through joinery to a direct apology made in person.",
		"service": {"id": &"shelter_repair", "label": "Shelter repair", "effect": "Reinforced bunks, ventilation and stronger rest recovery."},
		"quests": [
			{"id": &"idris_dry_braces", "title": "Dry Braces", "brief": "Recover safe timber without weakening Cullbrook's roof."},
			{"id": &"idris_medicine_shelf", "title": "The Unnamed Shelf", "brief": "Build Imogen a clinic shelf and decide who delivers the apology."},
		],
		"voice": {
			"cadence": "Measured joiner's observations that circle family questions until he can ask plainly.",
			"uses": ["load-bearing", "square", "Imogen's small habits"],
			"avoids": ["sentiment without a practical act", "claiming a repair is permanent", "speaking for Imogen"],
			"samples": [
				"Homes fail at corners first. People usually fail somewhere quieter.",
				"Tell Imogen I made the shelf. No - tell her I should have stayed.",
			],
		},
		"dialogue": {
			"introduction": ["IDRIS - The north bay has enough dry timber for six bunks. I only have two shoulders."],
			"service": ["IDRIS - Hold this square. If the carriage moves, the joint should move with it."],
			"route": ["IDRIS - A network is a roof. Show me where the load goes when one part fails."],
		},
	},
	&"mara": {
		"display_name": "Mara Venn",
		"role": "Locksmith and salvage adjudicator",
		"want": "Keep ownership and consent attached to every opened room.",
		"fear": "Continuity will make a plausible key for a person who never agreed.",
		"arc": "Guarding sealed property alone to publishing accountable physical access.",
		"service": {"id": &"lockwork", "label": "Documented lockwork", "effect": "Mechanical bypasses that never feed an identity credential."},
		"quests": [
			{"id": &"mara_seven_keys", "title": "Seven Keys", "brief": "Match Maggie's numbered blanks to the cabinets they actually open."},
			{"id": &"mara_empty_hook", "title": "The Empty Hook", "brief": "Trace a missing key before the copied voice invents its owner."},
		],
		"voice": {
			"cadence": "Wry legal phrasing; every joke followed by an inventory number.",
			"uses": ["sealed", "witness tag", "visible tool marks"],
			"avoids": ["clever electronic handshakes", "unlogged salvage", "trusting a lock's label"],
			"samples": [
				"Locked means ask. Jammed means swear. Sealed means bring a witness.",
				"The key fits. That proves the cuts, not the hand holding it.",
			],
		},
		"dialogue": {
			"introduction": ["MARA - Maggie left seven keys and a note saying one of them opens a person."],
			"service": ["MARA - Mechanical bypass, numbered tag, no clever handshake. Boring is safe."],
			"route": ["MARA - Publish which key opens which lock. Leave the rest unable to pretend."],
		},
	},
	&"tom": {
		"display_name": "Tom Arkwright",
		"role": "Shepherd and line watcher",
		"want": "Turn Hollow movement into warnings people can understand.",
		"fear": "A bright warning system will teach the Hollows where people sleep.",
		"arc": "Watching the hedges alone to maintaining a shared, quiet perimeter.",
		"service": {"id": &"wire_warning", "label": "Wire warning", "effect": "Dull-bell trip lines and route-specific Hollow warnings."},
		"quests": [
			{"id": &"tom_evening_round", "title": "The Evening Round", "brief": "Track the thing repeating Tom's shepherd route."},
			{"id": &"tom_dull_bells", "title": "Dull Bells", "brief": "String a human warning line without creating a carrier lure."},
		],
		"voice": {
			"cadence": "Rural understatement, describing terror as if it were difficult weather.",
			"uses": ["wind", "tracks", "the flock's habits"],
			"avoids": ["technical certainty", "loud heroics", "calling bait harmless"],
			"samples": [
				"Wind is wrong. Sheep knew it before the radios did.",
				"Dull bell for people. Bright bell for bait. Never swap them because you are tired.",
			],
		},
		"dialogue": {
			"introduction": ["TOM - Something in the hedges walks my evening round, but it has never owned sheep."],
			"service": ["TOM - Dull bell on the gate. Bright one beyond the ditch. Remember which side you are on."],
			"route": ["TOM - Little warning lines work. Each place hears its own gate."],
		},
	},
}


static func all_ids() -> Array[StringName]:
	return NPC_IDS.duplicate()


static func get_definition(npc_id: StringName) -> Dictionary:
	return Dictionary(NPCS.get(npc_id, {})).duplicate(true)


static func get_story_id(npc_id: StringName) -> StringName:
	return StringName("narrative_npc_%s" % String(npc_id)) if NPCS.has(npc_id) else &""


static func id_from_story_id(story_id: StringName) -> StringName:
	var raw := String(story_id)
	const PREFIX := "narrative_npc_"
	if not raw.begins_with(PREFIX):
		return &""
	var npc_id := StringName(raw.trim_prefix(PREFIX))
	return npc_id if NPCS.has(npc_id) else &""


static func get_dialogue(npc_id: StringName, beat: String = "introduction") -> Array[String]:
	var definition: Dictionary = NPCS.get(npc_id, {})
	var beats: Dictionary = definition.get("dialogue", {})
	var source: Array = beats.get(beat, beats.get("introduction", []))
	var lines: Array[String] = []
	for line in source:
		lines.append(String(line))
	return lines


static func validate() -> Array[String]:
	var errors: Array[String] = []
	if NPCS.size() != 12:
		errors.append("expected twelve narrative NPC definitions")
	var story_ids: Dictionary = {}
	for npc_id in NPC_IDS:
		var definition: Dictionary = NPCS.get(npc_id, {})
		if definition.is_empty():
			errors.append("missing NPC definition: %s" % npc_id)
			continue
		for field in ["display_name", "role", "want", "fear", "arc", "service", "quests", "voice", "dialogue"]:
			if not definition.has(field):
				errors.append("%s missing %s" % [npc_id, field])
		var voice: Dictionary = definition.get("voice", {})
		if Array(voice.get("samples", [])).size() < 2:
			errors.append("%s needs two voice samples" % npc_id)
		if Array(definition.get("quests", [])).size() < 2:
			errors.append("%s needs two quest definitions" % npc_id)
		var story_id := get_story_id(npc_id)
		if story_ids.has(story_id):
			errors.append("duplicate NPC story id: %s" % story_id)
		story_ids[story_id] = true
	return errors
