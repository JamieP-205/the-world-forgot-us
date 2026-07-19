extends Node
## Focused mixer, Web unlock and production cue reachability contract.

const REGIONS := ["railhome", "cullbrook", "ashmere", "wrenfield", "tollard"]
const REACHABILITY := [
	{
		"label": "receiver sweep",
		"path": "res://scripts/systems/audio_manager.gd",
		"tokens": ["EventBus.scanner_pulsed.connect", "play(&\"scan\")"],
	},
	{
		"label": "combat",
		"path": "res://scripts/player/player.gd",
		"tokens": ["AudioManager.play(&\"swing\"", "AudioManager.play(&\"dodge\""],
	},
	{
		"label": "enemy impact",
		"path": "res://scripts/enemies/enemy_hollow.gd",
		"tokens": ["AudioManager.play(&\"hollow_hit\"", "AudioManager.play(&\"hollow_death\""],
	},
	{
		"label": "footsteps",
		"path": "res://scripts/player/player.gd",
		"tokens": ["AudioManager.play_footstep"],
	},
	{
		"label": "crafting",
		"path": "res://scripts/systems/audio_manager.gd",
		"tokens": ["CraftingSystem.craft_completed.connect", "CraftingSystem.craft_rejected.connect"],
	},
	{
		"label": "button interface",
		"path": "res://scripts/systems/audio_manager.gd",
		"tokens": ["button.pressed.connect", "play(&\"ui_accept\""],
	},
	{
		"label": "dialogue",
		"path": "res://scripts/ui/dialogue_overlay.gd",
		"tokens": ["AudioManager.play(&\"dialogue_open\"", "AudioManager.play(&\"dialogue_tick\"", "AudioManager.play(&\"choice\""],
	},
	{
		"label": "opening story",
		"path": "res://scripts/ui/opening_cinematic.gd",
		"tokens": ["AudioManager.play(&\"radio_static\"", "AudioManager.play(&\"objective\""],
	},
	{
		"label": "campaign finale",
		"path": "res://scripts/systems/campaign_system.gd",
		"tokens": ["AudioManager.play(&\"finale\"", "AudioManager.play(&\"relay_restore\""],
	},
]

var _failures: Array[String] = []
var _checks := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	AudioManager.call("_initialize_playback_graph")
	await get_tree().process_frame
	_test_player_graph()
	_test_synthesis_contract()
	_test_cue_reachability()
	_test_web_unlock_contract()
	_test_volume_controls()
	await _test_region_lifecycle()
	await _stop_test_playback()

	if _failures.is_empty():
		print("AUDIO RELEASE CONTRACT: PASS (%d checks)" % _checks)
		get_tree().quit(0)
	else:
		for failure in _failures:
			push_error("AUDIO RELEASE CONTRACT: " + failure)
		print("AUDIO RELEASE CONTRACT: FAIL (%d failures / %d checks)" % [_failures.size(), _checks])
		get_tree().quit(1)


func _test_player_graph() -> void:
	var before: Dictionary = AudioManager.get_audio_runtime_report()
	_check(bool(before.get("graph_ready", false)), "playback graph initializes")
	_check(
		int(before.get("audio_child_count", -1)) == int(before.get("expected_player_count", -2)),
		"playback graph owns exactly the expected players",
	)
	_check(int(before.get("sfx_player_count", 0)) >= 12, "SFX pool supports overlapping cues")
	_check(int(before.get("music_player_count", 0)) == 2, "score owns one crossfade pair")
	_check((before.get("duplicate_player_references", []) as Array).is_empty(), "player references are unique")
	_check(
		int(before.get("unique_player_references", 0)) == int(before.get("audio_child_count", -1)),
		"every audio child has one player reference",
	)
	var names_before := before.get("player_names", []) as Array
	AudioManager.call("_initialize_playback_graph")
	var after: Dictionary = AudioManager.get_audio_runtime_report()
	_check(after.get("player_names", []) == names_before, "playback graph initialization is idempotent")
	_check(
		int(after.get("audio_child_count", -1)) == int(before.get("audio_child_count", -2)),
		"initializing twice creates no duplicate players",
	)
	_check(_centralized_player_ownership(), "AudioManager is the sole production AudioStreamPlayer owner")


func _test_synthesis_contract() -> void:
	var report: Dictionary = AudioManager.get_audio_smoke_report()
	var errors := report.get("contract_errors", []) as Array
	_check(errors.is_empty(), "synthesis contract passes: %s" % "; ".join(errors))
	_check(
		int(report.get("rendered_cues", 0)) == int(report.get("cue_count", -1)),
		"every cue renders valid PCM",
	)
	_check((report.get("silent_cues", []) as Array).is_empty(), "no authored cue renders silent")
	_check(int(report.get("clipped_samples", -1)) == 0, "cue PCM contains no clipped samples")
	_check(bool(report.get("deterministic_noise", false)), "seeded noise cues are deterministic")
	var runtime: Dictionary = AudioManager.get_audio_runtime_report()
	_check(
		int(runtime.get("cue_stream_count", 0)) == int(report.get("cue_count", -1)),
		"every authored cue is installed in the live stream table",
	)
	_check((runtime.get("invalid_cue_streams", []) as Array).is_empty(), "live cue table contains no invalid stream")


func _test_cue_reachability() -> void:
	for entry_value in REACHABILITY:
		var entry := entry_value as Dictionary
		var path := String(entry.path)
		var source := FileAccess.get_file_as_string(path)
		_check(not source.is_empty(), "%s source is readable" % String(entry.label))
		for token_value in entry.tokens as Array:
			var token := String(token_value)
			_check(source.contains(token), "%s reaches %s" % [String(entry.label), token])

	var report: Dictionary = AudioManager.get_audio_smoke_report()
	var cue_ids: Array = report.get("cue_ids", [])
	var known: Dictionary = {}
	for cue_value in cue_ids:
		known[String(cue_value)] = true
	var play_pattern := RegEx.new()
	play_pattern.compile("AudioManager\\.play\\(&\"([a-z0-9_]+)\"")
	for path in _collect_files("res://scripts", ".gd"):
		var source := FileAccess.get_file_as_string(path)
		for match_value in play_pattern.search_all(source):
			var cue_id := (match_value as RegExMatch).get_string(1)
			_check(known.has(cue_id), "%s calls a registered cue (%s)" % [path, cue_id])


func _test_web_unlock_contract() -> void:
	var shell := FileAccess.get_file_as_string("res://web/shell.html")
	_check(not shell.is_empty(), "Web shell is readable")
	for token in [
		"new Proxy(NativeAudioContext",
		"registerAudioContext",
		"context.resume()",
		"pointerdown",
		"touchstart",
		"keydown",
		"capture: true",
		"app.dataset.audioState",
		'id="sound-unlock"',
		"window.__twfuResumeAudio",
		"resumeAudio();",
	]:
		_check(shell.contains(token), "Web shell includes audio unlock token: %s" % token)
	var wrapper_index := shell.find("new Proxy(NativeAudioContext")
	var runtime_index := shell.find('<script src="$GODOT_URL"></script>')
	_check(
		wrapper_index >= 0 and runtime_index >= 0 and wrapper_index < runtime_index,
		"Web shell wraps AudioContext before the Godot runtime can cache it",
	)
	_check(
		shell.contains('</header>\n\n    <button class="sound-chip" id="sound-unlock"'),
		"sound recovery control sits outside the fading launch chrome",
	)
	_check(not shell.contains(String.chr(0x00c2)), "Web shell contains no double-decoded UTF-8 artefact")
	var manager_source := FileAccess.get_file_as_string("res://scripts/systems/audio_manager.gd")
	for token in ["InputEventKey", "InputEventMouseButton", "InputEventScreenTouch", "InputEventJoypadButton"]:
		_check(manager_source.contains(token), "Godot unlock accepts %s" % token)
	var menu_source := FileAccess.get_file_as_string("res://scripts/ui/main_menu.gd")
	_check(menu_source.contains("AudioManager.unlock_audio()"), "main-menu gestures reach the Godot unlock")


func _test_volume_controls() -> void:
	var original := {
		"master": SettingsManager.get_float("audio", "master", 0.86),
		"music": SettingsManager.get_float("audio", "music", 0.64),
		"sfx": SettingsManager.get_float("audio", "sfx", 0.88),
	}
	SettingsManager.set_value("audio", "master", 0.0, false)
	var master := AudioServer.get_bus_index("Master")
	_check(master >= 0 and AudioServer.is_bus_mute(master), "zero master volume mutes Master")
	SettingsManager.set_value("audio", "master", 0.5, false)
	_check(not AudioServer.is_bus_mute(master), "raising master volume unmutes Master")
	_check(is_equal_approx(AudioServer.get_bus_volume_db(master), linear_to_db(0.5)), "master slider applies linear gain")

	SettingsManager.set_value("audio", "music", 0.25, false)
	var music := AudioServer.get_bus_index("Music")
	_check(music >= 0 and is_equal_approx(AudioServer.get_bus_volume_db(music), linear_to_db(0.25)), "music slider controls Music")
	SettingsManager.set_value("audio", "sfx", 0.75, false)
	var sfx := AudioServer.get_bus_index("SFX")
	_check(sfx >= 0 and is_equal_approx(AudioServer.get_bus_volume_db(sfx), linear_to_db(0.75)), "SFX slider controls SFX")
	_check(AudioServer.get_bus_send(AudioServer.get_bus_index("Ambience")) == "SFX", "ambience follows the SFX setting")
	_check(AudioServer.get_bus_send(AudioServer.get_bus_index("UI")) == "SFX", "interface cues follow the SFX setting")

	for key in original:
		SettingsManager.set_value("audio", key, original[key], false)


func _test_region_lifecycle() -> void:
	AudioManager.call("_activate_audio", "railhome")
	await get_tree().process_frame
	var unlocked: Dictionary = AudioManager.get_audio_runtime_report()
	_check(bool(unlocked.get("audio_unlocked", false)), "gesture activation unlocks the mixer")
	_check(bool(unlocked.get("ambience_bed_ready", false)), "unlock prepares the ambience bed")
	_check(bool(unlocked.get("ambience_detail_ready", false)), "unlock prepares ambience detail")
	_check(bool(unlocked.get("tension_ready", false)), "unlock prepares the danger stem")
	var unlock_requests := unlocked.get("start_requests", {}) as Dictionary
	_check(int(unlock_requests.get(&"ambience_bed", 0)) > 0, "ambience starts after unlock")
	_check(int(unlock_requests.get(&"ambience_detail", 0)) > 0, "ambience detail starts after unlock")
	_check(int(unlock_requests.get(&"tension", 0)) > 0, "danger stem starts after unlock")

	_finish_score_build()
	await get_tree().process_frame
	var railhome: Dictionary = AudioManager.get_audio_runtime_report()
	_check(String(railhome.get("playing_region", "")) == "railhome", "unlock starts the current regional score")
	_check(bool(railhome.get("music_stream_ready", false)), "regional music owns a valid stream")
	_check(int((railhome.get("start_requests", {}) as Dictionary).get(&"music", 0)) > 0, "regional music starts after unlock")

	var ambience_hashes: Dictionary = {}
	var detail_hashes: Dictionary = {}
	for region in REGIONS:
		AudioManager.call("_set_audio_region", region)
		var bed := AudioManager.get("_ambience") as AudioStreamPlayer
		var detail := AudioManager.get("_ambience_detail") as AudioStreamPlayer
		_check(bed != null and bed.stream is AudioStreamWAV, "%s ambience bed is valid" % region)
		_check(detail != null and detail.stream is AudioStreamWAV, "%s ambience detail is valid" % region)
		if bed != null and bed.stream is AudioStreamWAV:
			ambience_hashes[hash((bed.stream as AudioStreamWAV).data)] = region
		if detail != null and detail.stream is AudioStreamWAV:
			detail_hashes[hash((detail.stream as AudioStreamWAV).data)] = region
		var state: Dictionary = AudioManager.get_audio_runtime_report()
		_check(String(state.get("ambience_region", "")) == region, "%s profile becomes active" % region)
		var requests := state.get("start_requests", {}) as Dictionary
		_check(int(requests.get(&"ambience_bed", 0)) > 0, "%s bed receives a start request" % region)
		_check(int(requests.get(&"ambience_detail", 0)) > 0, "%s detail receives a start request" % region)
	_check(ambience_hashes.size() == REGIONS.size(), "every region has a distinct ambience bed")
	_check(detail_hashes.size() == REGIONS.size(), "every region has distinct ambience detail")

	AudioManager.call("_set_audio_region", "wrenfield")
	_finish_score_build()
	await get_tree().process_frame
	var transitioned: Dictionary = AudioManager.get_audio_runtime_report()
	_check(String(transitioned.get("current_region", "")) == "wrenfield", "region transition updates mixer state")
	_check(String(transitioned.get("playing_region", "")) == "wrenfield", "region transition changes the score")
	_check(int((transitioned.get("start_requests", {}) as Dictionary).get(&"music", 0)) >= 2, "music restarts across a region transition")

	_check(
		String(AudioManager.call("_region_from_scene_path", "res://scenes/maps/ashmere_verge.tscn")) == "ashmere",
		"Ashmere scene resolves to its audio profile",
	)
	_check(
		String(AudioManager.call("_region_from_scene_path", "res://scenes/maps/broadcast_fields.tscn")) == "wrenfield",
		"Wrenfield scene resolves to its audio profile",
	)
	_check(
		String(AudioManager.call("_region_from_scene_path", "res://scenes/maps/choir_core.tscn")) == "tollard",
		"Tollard scene resolves to its audio profile",
	)


func _finish_score_build() -> void:
	for _iteration in 96:
		if String(AudioManager.get("_score_build_region")).is_empty():
			return
		AudioManager.call("_advance_score_build")
	_check(false, "regional score synthesis completes inside its work budget")


func _stop_test_playback() -> void:
	AudioManager.call("_release_playback_graph", true)
	await get_tree().process_frame
	await get_tree().process_frame


func _centralized_player_ownership() -> bool:
	for path in _collect_files("res://scripts", ".gd"):
		if path == "res://scripts/systems/audio_manager.gd":
			continue
		if FileAccess.get_file_as_string(path).contains("AudioStreamPlayer"):
			return false
	for path in _collect_files("res://scenes", ".tscn"):
		if FileAccess.get_file_as_string(path).contains("AudioStreamPlayer"):
			return false
	return true


func _collect_files(root: String, extension: String) -> Array[String]:
	var found: Array[String] = []
	var directory := DirAccess.open(root)
	if directory == null:
		return found
	directory.list_dir_begin()
	while true:
		var entry := directory.get_next()
		if entry.is_empty():
			break
		if entry.begins_with("."):
			continue
		var path := root.path_join(entry)
		if directory.current_is_dir():
			found.append_array(_collect_files(path, extension))
		elif entry.ends_with(extension):
			found.append(path)
	directory.list_dir_end()
	return found


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
