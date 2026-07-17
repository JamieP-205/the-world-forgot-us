extends Node
## Procedural score and sound direction. Every region has its own restrained
## harmonic language; a second stem rises when enemies close in. The approach
## keeps the download small while providing authored variation rather than a
## single endless drone.

const MIX_RATE := 22050
const SFX_POOL_SIZE := 14
const SFX_GAIN_DB := -4.5
const CUE_CALL_MIN_DB := -36.0
const CUE_CALL_MAX_DB := 2.0
const CUE_OUTPUT_MAX_DB := -1.5
const MUSIC_LEVEL_DB := -16.0
const MUSIC_DUCK_DB := -22.0
const MUSIC_FADE := 1.35
const SCORE_DURATION := 16.0
const SCORE_BUILD_CHUNK := 8192
const AMBIENCE_DURATION := 8.0
const SAFE_SYNTH_PEAK := 0.9
const MUSIC_PLAYER_COUNT := 2
const CONTINUOUS_PLAYER_COUNT := 3
const EXPECTED_PLAYER_COUNT := SFX_POOL_SIZE + MUSIC_PLAYER_COUNT + CONTINUOUS_PLAYER_COUNT

const REQUIRED_CUES := [
	&"pickup", &"scan", &"signal_tick", &"weak_signal", &"echo_reveal",
	&"echo_recover", &"hollow_hit", &"hollow_death", &"player_hurt",
	&"build", &"beacon", &"rest", &"ending", &"eat", &"keepsake",
	&"swing", &"dodge", &"memory_burst", &"dialogue_open",
	&"dialogue_tick", &"choice", &"archive", &"relay_restore", &"finale",
	&"ui_move", &"ui_accept", &"ui_back", &"focus", &"objective",
	&"travel", &"map_open", &"settings_apply", &"radio_static",
	&"step_grit", &"step_metal", &"audio_wake", &"door_open", &"door_close",
	&"craft_success", &"craft_fail", &"danger_rise",
]

const CUE_SPECS := {
	&"pickup": {"duration": 0.15, "frequency": 523.0, "options": {"freq2": 784.0, "decay": 15.0, "amp": 0.27}},
	&"scan": {"duration": 0.46, "frequency": 294.0, "options": {"freq2": 882.0, "sweep": 1.25, "wobble": 0.55, "decay": 4.7, "amp": 0.24}},
	&"signal_tick": {"duration": 0.09, "frequency": 1175.0, "options": {"freq2": 880.0, "decay": 28.0, "amp": 0.16}},
	&"weak_signal": {"duration": 0.52, "frequency": 185.0, "options": {"freq2": 555.0, "sweep": -0.22, "noise": 0.14, "decay": 4.0, "amp": 0.22}},
	&"echo_reveal": {"duration": 0.86, "frequency": 659.0, "options": {"freq2": 988.0, "wobble": 8.0, "decay": 2.4, "amp": 0.25}},
	&"echo_recover": {"duration": 0.95, "frequency": 392.0, "options": {"freq2": 659.0, "wobble": 1.6, "decay": 2.1, "amp": 0.26}},
	&"hollow_hit": {"duration": 0.14, "frequency": 147.0, "options": {"freq2": 441.0, "noise": 0.54, "decay": 21.0, "amp": 0.28}},
	&"hollow_death": {"duration": 0.58, "frequency": 349.0, "options": {"sweep": -0.68, "noise": 0.22, "decay": 5.1, "amp": 0.24}},
	&"player_hurt": {"duration": 0.26, "frequency": 104.0, "options": {"freq2": 416.0, "noise": 0.42, "decay": 10.0, "amp": 0.30}},
	&"build": {"duration": 0.61, "frequency": 330.0, "options": {"freq2": 494.0, "decay": 3.4, "amp": 0.27}},
	&"beacon": {"duration": 0.48, "frequency": 392.0, "options": {"freq2": 587.0, "decay": 5.0, "amp": 0.23}},
	&"rest": {"duration": 0.62, "frequency": 262.0, "options": {"freq2": 349.0, "decay": 3.5, "amp": 0.21}},
	&"ending": {"duration": 0.90, "frequency": 110.0, "options": {"freq2": 440.0, "wobble": 3.0, "noise": 0.06, "decay": 2.1, "amp": 0.25}},
	&"eat": {"duration": 0.25, "frequency": 220.0, "options": {"freq2": 330.0, "noise": 0.12, "decay": 9.0, "amp": 0.22}},
	&"keepsake": {"duration": 0.72, "frequency": 523.0, "options": {"freq2": 784.0, "wobble": 3.0, "decay": 2.7, "amp": 0.20}},
	&"swing": {"duration": 0.15, "frequency": 205.0, "options": {"freq2": 615.0, "sweep": 1.8, "noise": 0.19, "decay": 18.0, "amp": 0.23}},
	&"dodge": {"duration": 0.23, "frequency": 280.0, "options": {"sweep": 1.35, "noise": 0.25, "decay": 12.0, "amp": 0.21}},
	&"memory_burst": {"duration": 0.75, "frequency": 196.0, "options": {"freq2": 784.0, "sweep": 0.8, "wobble": 2.5, "decay": 2.9, "amp": 0.27}},
	&"dialogue_open": {"duration": 0.30, "frequency": 330.0, "options": {"freq2": 495.0, "noise": 0.05, "decay": 7.0, "amp": 0.17}},
	&"dialogue_tick": {"duration": 0.08, "frequency": 620.0, "options": {"decay": 24.0, "amp": 0.11}},
	&"choice": {"duration": 0.40, "frequency": 440.0, "options": {"freq2": 660.0, "decay": 6.0, "amp": 0.20}},
	&"archive": {"duration": 0.46, "frequency": 262.0, "options": {"freq2": 523.0, "wobble": 1.2, "decay": 5.0, "amp": 0.19}},
	&"relay_restore": {"duration": 1.0, "frequency": 110.0, "options": {"freq2": 440.0, "sweep": 0.65, "wobble": 2.2, "decay": 2.1, "amp": 0.25}},
	&"finale": {"duration": 1.70, "frequency": 130.8, "options": {"freq2": 523.2, "wobble": 1.1, "decay": 1.2, "amp": 0.25}},
	&"ui_move": {"duration": 0.045, "frequency": 740.0, "options": {"decay": 45.0, "amp": 0.10}},
	&"ui_accept": {"duration": 0.13, "frequency": 392.0, "options": {"freq2": 587.0, "decay": 15.0, "amp": 0.16}},
	&"ui_back": {"duration": 0.12, "frequency": 330.0, "options": {"sweep": -0.35, "decay": 14.0, "amp": 0.14}},
	&"focus": {"duration": 0.10, "frequency": 880.0, "options": {"freq2": 440.0, "decay": 20.0, "amp": 0.10}},
	&"objective": {"duration": 0.32, "frequency": 349.0, "options": {"freq2": 523.0, "decay": 6.5, "amp": 0.17}},
	&"travel": {"duration": 0.70, "frequency": 92.0, "options": {"freq2": 368.0, "noise": 0.18, "sweep": 0.2, "decay": 3.1, "amp": 0.20}},
	&"map_open": {"duration": 0.24, "frequency": 247.0, "options": {"freq2": 370.0, "noise": 0.04, "decay": 8.0, "amp": 0.16}},
	&"settings_apply": {"duration": 0.30, "frequency": 440.0, "options": {"freq2": 659.0, "decay": 7.0, "amp": 0.16}},
	&"radio_static": {"duration": 0.42, "frequency": 140.0, "options": {"freq2": 560.0, "noise": 0.72, "wobble": 4.0, "decay": 4.5, "amp": 0.18}},
	&"step_grit": {"duration": 0.09, "frequency": 82.0, "options": {"freq2": 328.0, "noise": 0.82, "decay": 29.0, "amp": 0.16, "seed": 631}},
	&"step_metal": {"duration": 0.11, "frequency": 196.0, "options": {"freq2": 588.0, "noise": 0.42, "decay": 23.0, "amp": 0.15, "seed": 917}},
	&"audio_wake": {"duration": 0.24, "frequency": 440.0, "options": {"freq2": 660.0, "decay": 8.0, "amp": 0.18}},
	&"door_open": {"duration": 0.42, "frequency": 118.0, "options": {"freq2": 472.0, "noise": 0.34, "sweep": -0.18, "decay": 5.5, "amp": 0.24, "seed": 2801}},
	&"door_close": {"duration": 0.30, "frequency": 96.0, "options": {"freq2": 384.0, "noise": 0.28, "decay": 10.0, "amp": 0.25, "seed": 2802}},
	&"craft_success": {"duration": 0.72, "frequency": 294.0, "options": {"freq2": 588.0, "noise": 0.10, "decay": 4.3, "amp": 0.24, "seed": 6142}},
	&"craft_fail": {"duration": 0.20, "frequency": 174.0, "options": {"freq2": 130.5, "noise": 0.08, "sweep": -0.45, "decay": 12.0, "amp": 0.19}},
	&"danger_rise": {"duration": 0.84, "frequency": 146.8, "options": {"freq2": 587.2, "noise": 0.12, "wobble": 1.7, "decay": 2.6, "amp": 0.24, "seed": 441}},
}

const CUE_MIX := {
	&"ui_move": {"bus": &"UI", "gain_db": -2.0, "priority": 0, "cooldown_ms": 70},
	&"ui_accept": {"bus": &"UI", "gain_db": -0.5, "priority": 1, "cooldown_ms": 35},
	&"ui_back": {"bus": &"UI", "gain_db": -0.5, "priority": 1, "cooldown_ms": 35},
	&"focus": {"bus": &"UI", "gain_db": -2.0, "priority": 0, "cooldown_ms": 90},
	&"dialogue_tick": {"bus": &"UI", "gain_db": -1.0, "priority": 1, "cooldown_ms": 45},
	&"dialogue_open": {"bus": &"UI", "priority": 2, "cooldown_ms": 80},
	&"choice": {"bus": &"UI", "priority": 2, "cooldown_ms": 80},
	&"map_open": {"bus": &"UI", "priority": 1, "cooldown_ms": 80},
	&"archive": {"bus": &"UI", "priority": 1, "cooldown_ms": 80},
	&"settings_apply": {"bus": &"UI", "priority": 1, "cooldown_ms": 80},
	&"scan": {"priority": 2, "cooldown_ms": 120},
	&"signal_tick": {"priority": 2, "cooldown_ms": 55},
	&"echo_reveal": {"gain_db": 0.5, "priority": 4, "cooldown_ms": 180},
	&"echo_recover": {"gain_db": 0.5, "priority": 4, "cooldown_ms": 180},
	&"player_hurt": {"gain_db": 0.5, "priority": 4, "cooldown_ms": 90},
	&"door_open": {"priority": 3, "cooldown_ms": 160},
	&"door_close": {"priority": 3, "cooldown_ms": 160},
	&"craft_success": {"priority": 3, "cooldown_ms": 120},
	&"craft_fail": {"bus": &"UI", "priority": 2, "cooldown_ms": 100},
	&"danger_rise": {"gain_db": 0.5, "priority": 4, "cooldown_ms": 1400},
	&"finale": {"gain_db": 0.5, "priority": 5, "cooldown_ms": 500},
	&"audio_wake": {"bus": &"UI", "priority": 3, "cooldown_ms": 500},
}

const REGION_AMBIENCE := {
	"railhome": {"bed_hz": 55.0, "detail_hz": 196.0, "event_rate": 0.22, "bed_db": -24.0, "detail_db": -25.5, "seed": 1001},
	"cullbrook": {"bed_hz": 82.0, "detail_hz": 523.0, "event_rate": 0.17, "bed_db": -21.0, "detail_db": -24.0, "seed": 2003},
	"ashmere": {"bed_hz": 73.0, "detail_hz": 392.0, "event_rate": 0.31, "bed_db": -20.5, "detail_db": -24.0, "seed": 3001},
	"wrenfield": {"bed_hz": 98.0, "detail_hz": 294.0, "event_rate": 0.48, "bed_db": -21.5, "detail_db": -22.5, "seed": 4001},
	"tollard": {"bed_hz": 49.0, "detail_hz": 247.0, "event_rate": 0.63, "bed_db": -23.0, "detail_db": -21.5, "seed": 5003},
}

var _streams: Dictionary = {}
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_priorities: Array[int] = []
var _sfx_started_ms: Array[int] = []
var _last_cue_ms: Dictionary = {}
var _sfx_index := 0
var _music_players: Array[AudioStreamPlayer] = []
var _active_music := 0
var _tension: AudioStreamPlayer
var _ambience: AudioStreamPlayer
var _ambience_detail: AudioStreamPlayer
var _ambience_cache: Dictionary = {}
var _ambience_region := ""
var _music_cache: Dictionary = {}
var _current_region := ""
var _playing_region := ""
var _audio_unlocked := false
var _music_transition: Tween = null
var _start_requests: Dictionary = {}
var _mix_clock := 0.0
var _last_health := -1.0
var _last_prompt := ""
var _last_step_ms := 0
var _danger_latched := false
var _pending_travel_cue := false
var _score_build_region := ""
var _score_build_index := 0
var _score_build_count := 0
var _score_build_bytes := PackedByteArray()
var _score_build_profile: Dictionary = {}
var _score_build_rng := RandomNumberGenerator.new()
var _score_build_filtered_noise := 0.0
var _score_build_immediate := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_audio_routing()
	# Headless validation has no audio device and should never spend time
	# synthesizing streams it cannot play.
	if DisplayServer.get_name() == "headless":
		return
	_initialize_playback_graph()

	EventBus.scanner_pulsed.connect(func(_origin: Vector2, _radius: float) -> void: play(&"scan"))
	EventBus.scannable_pinged.connect(func(_position: Vector2) -> void: play(&"signal_tick", -3.0))
	EventBus.echo_revealed.connect(func(_data) -> void: play(&"echo_reveal"))
	EventBus.game_saved.connect(func() -> void: play(&"rest"))
	EventBus.travel_requested.connect(_on_travel_requested)
	EventBus.level_loaded.connect(_on_level_loaded)
	EventBus.player_health_changed.connect(_on_health_changed)
	EventBus.interaction_prompt_changed.connect(_on_prompt_changed)
	EventBus.campaign_progress_changed.connect(_on_campaign_progress)
	BaseUpgradeSystem.upgrade_built.connect(_on_upgrade_built)
	CraftingSystem.craft_completed.connect(_on_craft_completed)
	CraftingSystem.craft_rejected.connect(_on_craft_rejected)
	SettingsManager.settings_changed.connect(_on_setting_changed)
	get_tree().node_added.connect(_on_node_added)
	call_deferred("_wire_existing_ui", get_tree().root)
	call_deferred("_on_level_loaded")

	if not OS.has_feature("web"):
		unlock_audio()


func _initialize_playback_graph() -> void:
	# The manager is an autoload, but keeping graph creation idempotent protects
	# editor scene reloads and makes duplicate-player regressions easy to catch.
	if _playback_graph_ready():
		return
	if (
		not _sfx_players.is_empty()
		or not _music_players.is_empty()
		or is_instance_valid(_tension)
		or is_instance_valid(_ambience)
		or is_instance_valid(_ambience_detail)
	):
		push_error("AudioManager: playback graph is only partly initialized.")
		return

	_build_streams()
	for index in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.name = "SFX_%02d" % (index + 1)
		player.bus = &"SFX"
		add_child(player)
		_sfx_players.append(player)
		_sfx_priorities.append(-1)
		_sfx_started_ms.append(0)

	for index in MUSIC_PLAYER_COUNT:
		var music := AudioStreamPlayer.new()
		music.name = "Music_%s" % String.chr(65 + index)
		music.bus = &"Music"
		music.volume_db = -60.0
		add_child(music)
		_music_players.append(music)

	_tension = AudioStreamPlayer.new()
	_tension.name = "Tension"
	_tension.bus = &"Music"
	_tension.volume_db = -38.0
	_tension.stream = _build_tension_bed()
	add_child(_tension)

	_ambience = AudioStreamPlayer.new()
	_ambience.name = "AmbienceBed"
	_ambience.bus = &"Ambience"
	_ambience.volume_db = -60.0
	add_child(_ambience)

	_ambience_detail = AudioStreamPlayer.new()
	_ambience_detail.name = "AmbienceDetail"
	_ambience_detail.bus = &"Ambience"
	_ambience_detail.volume_db = -60.0
	add_child(_ambience_detail)


func _playback_graph_ready() -> bool:
	return (
		_sfx_players.size() == SFX_POOL_SIZE
		and _music_players.size() == MUSIC_PLAYER_COUNT
		and is_instance_valid(_tension)
		and is_instance_valid(_ambience)
		and is_instance_valid(_ambience_detail)
	)


func _exit_tree() -> void:
	_release_playback_graph(false)


func _process(delta: float) -> void:
	if not _audio_unlocked:
		return
	_advance_score_build()
	_mix_clock += delta
	if _mix_clock < 0.35:
		return
	_mix_clock = 0.0
	_update_tension_mix()


func _input(event: InputEvent) -> void:
	# Web audio contexts may only start from a user gesture. Keeping that unlock
	# here means non-UI gameplay input also recovers audio reliably.
	if _audio_unlocked or not OS.has_feature("web"):
		return
	if (
		(event is InputEventKey and (event as InputEventKey).pressed)
		or (event is InputEventMouseButton and (event as InputEventMouseButton).pressed)
		or (event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed)
		or (event is InputEventJoypadButton and (event as InputEventJoypadButton).pressed)
	):
		unlock_audio()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_IN and _audio_unlocked:
		call_deferred("_resume_continuous_audio")


func unlock_audio() -> void:
	if _audio_unlocked or DisplayServer.get_name() == "headless":
		return
	_activate_audio(_region_from_world())


func _activate_audio(region: String) -> void:
	if _audio_unlocked or not _playback_graph_ready():
		return
	_audio_unlocked = true
	_set_audio_region(region, true)
	_resume_continuous_audio()
	play(&"audio_wake", -1.0)


func _resume_continuous_audio() -> void:
	if not _audio_unlocked:
		return
	if _ambience != null and _ambience.stream != null and not _ambience.playing:
		_start_player(_ambience, &"ambience_bed")
	if _ambience_detail != null and _ambience_detail.stream != null and not _ambience_detail.playing:
		_start_player(_ambience_detail, &"ambience_detail")
	if _tension != null and _tension.stream != null and not _tension.playing:
		_start_player(_tension, &"tension")
	if not _playing_region.is_empty() and not _music_players.is_empty():
		var score := _music_players[_active_music]
		if score.stream != null and not score.playing:
			_start_player(score, &"music")


func _start_player(player: AudioStreamPlayer, channel: StringName) -> void:
	if player == null or player.stream == null:
		return
	_start_requests[channel] = int(_start_requests.get(channel, 0)) + 1
	# Dummy/headless drivers can retain WAV playback references until process
	# teardown. Production never takes this branch; contracts still verify that
	# every continuous stem received its start request.
	if DisplayServer.get_name() != "headless":
		player.play()


func play(sound: StringName, volume_db := 0.0, pitch := 1.0) -> void:
	if DisplayServer.get_name() == "headless":
		return
	if not _audio_unlocked:
		return
	var stream: AudioStream = _streams.get(sound)
	if stream == null or _sfx_players.is_empty():
		return
	var mix: Dictionary = CUE_MIX.get(sound, {})
	var now := Time.get_ticks_msec()
	var cooldown_ms := int(mix.get("cooldown_ms", 0))
	if cooldown_ms > 0 and now - int(_last_cue_ms.get(sound, -cooldown_ms)) < cooldown_ms:
		return
	_last_cue_ms[sound] = now
	var priority := int(mix.get("priority", 1))
	var player_index := _claim_sfx_player(priority, now)
	if player_index < 0:
		return
	var player := _sfx_players[player_index]
	player.stream = stream
	player.bus = StringName(mix.get("bus", &"SFX"))
	player.volume_db = clampf(
		SFX_GAIN_DB + float(mix.get("gain_db", 0.0))
			+ clampf(volume_db, CUE_CALL_MIN_DB, CUE_CALL_MAX_DB),
		-60.0,
		CUE_OUTPUT_MAX_DB,
	)
	player.pitch_scale = clampf(pitch, 0.55, 1.8)
	player.play()


func _claim_sfx_player(priority: int, now: int) -> int:
	for offset in _sfx_players.size():
		var index := (_sfx_index + offset) % _sfx_players.size()
		if not _sfx_players[index].playing:
			_sfx_index = (index + 1) % _sfx_players.size()
			_sfx_priorities[index] = priority
			_sfx_started_ms[index] = now
			return index
	var candidate := 0
	for index in range(1, _sfx_players.size()):
		if (
			_sfx_priorities[index] < _sfx_priorities[candidate]
			or (
				_sfx_priorities[index] == _sfx_priorities[candidate]
				and _sfx_started_ms[index] < _sfx_started_ms[candidate]
			)
		):
			candidate = index
	if priority < _sfx_priorities[candidate]:
		return -1
	_sfx_priorities[candidate] = priority
	_sfx_started_ms[candidate] = now
	_sfx_index = (candidate + 1) % _sfx_players.size()
	return candidate


func play_footstep(_world_position: Vector2, velocity: Vector2) -> void:
	if velocity.length_squared() < 64.0:
		return
	var now := Time.get_ticks_msec()
	if now - _last_step_ms < 235:
		return
	_last_step_ms = now
	var cue: StringName = &"step_metal" if _uses_metal_footsteps() else &"step_grit"
	play(cue, -8.0, randf_range(0.92, 1.08))


func _uses_metal_footsteps() -> bool:
	if _current_region == "railhome":
		return true
	var main := get_tree().get_first_node_in_group("main")
	if main == null or not main.has_method("get_current_level_path"):
		return false
	if not String(main.get_current_level_path()).ends_with("building_interior.tscn"):
		return false
	var theme := String(WorldState.get_flag(&"active_interior_theme", ""))
	return theme in ["utility", "bunker", "industrial", "workshop", "garage"]


func _on_level_loaded() -> void:
	_set_audio_region(_region_from_world())
	if _audio_unlocked:
		_resume_continuous_audio()
		if _pending_travel_cue:
			play(&"door_close", -1.0, 0.90 if _current_region == "railhome" else 1.0)
		_pending_travel_cue = false


func _set_audio_region(region: String, immediate := false) -> void:
	if region.is_empty():
		return
	_current_region = region
	_apply_region_ambience(region)
	if _audio_unlocked:
		_request_region_music(region, immediate)


func _on_travel_requested(_scene, _spawn: StringName) -> void:
	_pending_travel_cue = true
	play(&"door_open")
	play(&"travel", -4.0, 0.92 if _current_region == "railhome" else 1.0)


func _apply_region_ambience(region: String) -> void:
	if _ambience == null or _ambience_detail == null or region.is_empty():
		return
	if _ambience_region == region and _ambience.stream != null and _ambience_detail.stream != null:
		return
	var bed_key := region + "_bed"
	var detail_key := region + "_detail"
	if not _ambience_cache.has(bed_key):
		_ambience_cache[bed_key] = _build_region_ambience(region, false)
	if not _ambience_cache.has(detail_key):
		_ambience_cache[detail_key] = _build_region_ambience(region, true)
	_ambience.stop()
	_ambience_detail.stop()
	_ambience.stream = _ambience_cache[bed_key]
	_ambience_detail.stream = _ambience_cache[detail_key]
	_ambience_region = region
	var profile: Dictionary = _ambience_profile(region)
	_ambience.volume_db = float(profile.bed_db)
	_ambience_detail.volume_db = float(profile.detail_db)
	if _audio_unlocked:
		_start_player(_ambience, &"ambience_bed")
		_start_player(_ambience_detail, &"ambience_detail")


func _ambience_profile(region: String) -> Dictionary:
	return REGION_AMBIENCE.get(region, REGION_AMBIENCE["cullbrook"])


func _play_region_stream(region: String, immediate := false) -> void:
	if region == _playing_region and _music_players[_active_music].playing:
		return
	if not _music_cache.has(region) or not _music_audible():
		return
	_stop_music_transition()
	var next := 1 - _active_music
	var incoming := _music_players[next]
	var outgoing := _music_players[_active_music]
	incoming.stream = _music_cache[region]
	incoming.volume_db = -60.0
	if _audio_unlocked:
		_start_player(incoming, &"music")
	if immediate:
		outgoing.stop()
		incoming.volume_db = MUSIC_LEVEL_DB
		_active_music = next
		_playing_region = region
		return
	var transition := create_tween().set_parallel(true)
	_music_transition = transition
	transition.tween_property(outgoing, "volume_db", -60.0, MUSIC_FADE)
	transition.tween_property(incoming, "volume_db", MUSIC_LEVEL_DB, MUSIC_FADE)
	transition.chain().tween_callback(func() -> void:
		outgoing.stop()
		if _music_transition == transition:
			_music_transition = null
	)
	_active_music = next
	_playing_region = region


func _stop_music_transition() -> void:
	if _music_transition != null and _music_transition.is_valid():
		_music_transition.kill()
	_music_transition = null


func _request_region_music(region: String, immediate := false) -> void:
	if region.is_empty() or not _audio_unlocked or not _music_audible():
		_cancel_score_build()
		return
	if _music_cache.has(region):
		_play_region_stream(region, immediate)
		return
	if _score_build_region == region:
		_score_build_immediate = _score_build_immediate or immediate
		return
	_begin_score_build(region, immediate)


func _begin_score_build(region: String, immediate: bool) -> void:
	_score_build_region = region
	_score_build_index = 0
	_score_build_count = int(SCORE_DURATION * MIX_RATE)
	_score_build_bytes = PackedByteArray()
	_score_build_bytes.resize(_score_build_count * 2)
	_score_build_profile = _score_profile(region)
	_score_build_rng = RandomNumberGenerator.new()
	_score_build_rng.seed = hash(region) + 7117
	_score_build_filtered_noise = 0.0
	_score_build_immediate = immediate


func _advance_score_build() -> void:
	if _score_build_region.is_empty():
		return
	if not _music_audible():
		_cancel_score_build()
		return
	var end := mini(_score_build_index + SCORE_BUILD_CHUNK, _score_build_count)
	for i in range(_score_build_index, end):
		var t := float(i) / MIX_RATE
		var pace := float(_score_build_profile.pace)
		var phase := int(t / pace) % 4
		var semitones := float(_score_build_profile.steps[phase])
		var root := float(_score_build_profile.root) * pow(2.0, semitones / 12.0)
		var slow := 0.72 + 0.28 * sin(TAU * t / SCORE_DURATION - PI * 0.5)
		var pad := sin(TAU * root * t) * 0.23
		pad += sin(TAU * root * 1.5 * t + 0.7) * 0.12
		pad += sin(TAU * root * 2.0 * t + sin(t * 0.13)) * 0.055
		# Small upper partials keep the score audible through phone speakers without
		# turning the restrained low register into a bright synth lead.
		pad += sin(TAU * root * 4.0 * t + 0.35) * 0.032
		pad += sin(TAU * root * 6.0 * t + 1.1) * 0.016
		var beat_phase := fmod(t, pace * 0.5)
		var bell_env := exp(-beat_phase * 4.8)
		var bell := sin(TAU * root * 4.0 * t) * bell_env * float(_score_build_profile.bell)
		_score_build_filtered_noise = (
			_score_build_filtered_noise * 0.986
			+ _score_build_rng.randf_range(-1.0, 1.0) * 0.014
		)
		var texture := _score_build_filtered_noise * float(_score_build_profile.grit)
		var edge := _edge_fade(i, _score_build_count, int(0.4 * MIX_RATE))
		_write_sample(_score_build_bytes, i, (pad * slow + bell + texture) * edge * 0.48)
	_score_build_index = end
	if _score_build_index < _score_build_count:
		return
	var completed_region := _score_build_region
	var play_immediately := _score_build_immediate
	_music_cache[completed_region] = _wav(_score_build_bytes, _score_build_count, true)
	_cancel_score_build()
	if completed_region == _current_region:
		_play_region_stream(completed_region, play_immediately or _playing_region.is_empty())


func _cancel_score_build() -> void:
	_score_build_region = ""
	_score_build_index = 0
	_score_build_count = 0
	_score_build_bytes = PackedByteArray()
	_score_build_profile = {}
	_score_build_filtered_noise = 0.0
	_score_build_immediate = false


func _release_playback_graph(queue_players: bool) -> void:
	_stop_music_transition()
	_cancel_score_build()
	var players: Array[AudioStreamPlayer] = []
	players.append_array(_sfx_players)
	players.append_array(_music_players)
	for continuous in [_tension, _ambience, _ambience_detail]:
		if continuous is AudioStreamPlayer:
			players.append(continuous as AudioStreamPlayer)
	for player in players:
		if not is_instance_valid(player):
			continue
		player.stop()
		player.stream = null
		if queue_players and not player.is_queued_for_deletion():
			player.queue_free()
	_sfx_players.clear()
	_sfx_priorities.clear()
	_sfx_started_ms.clear()
	_music_players.clear()
	_tension = null
	_ambience = null
	_ambience_detail = null
	_streams.clear()
	_music_cache.clear()
	_ambience_cache.clear()
	_last_cue_ms.clear()
	_start_requests.clear()
	_audio_unlocked = false
	_current_region = ""
	_playing_region = ""
	_ambience_region = ""


func _score_profile(region: String) -> Dictionary:
	return {
		"railhome": {"root": 55.0, "steps": [0, 7, 5, 3], "pace": 3.8, "bell": 0.035, "grit": 0.018},
		"cullbrook": {"root": 49.0, "steps": [0, 3, -2, 5], "pace": 3.2, "bell": 0.05, "grit": 0.035},
		"ashmere": {"root": 43.65, "steps": [0, 5, 8, 3], "pace": 4.0, "bell": 0.065, "grit": 0.02},
		"wrenfield": {"root": 46.25, "steps": [0, 7, 10, 5], "pace": 2.6, "bell": 0.045, "grit": 0.055},
		"tollard": {"root": 41.2, "steps": [0, 1, 6, 3], "pace": 3.4, "bell": 0.085, "grit": 0.03},
	}.get(region, {"root": 49.0, "steps": [0, 3, -2, 5], "pace": 3.2, "bell": 0.05, "grit": 0.03})


func _music_audible() -> bool:
	return (
		SettingsManager.get_float("audio", "master", 0.86) > 0.001
		and SettingsManager.get_float("audio", "music", 0.64) > 0.001
	)


func _on_setting_changed(section: String, key: String, _value: Variant) -> void:
	if section != "audio" or key not in ["master", "music"]:
		return
	if _music_audible():
		_request_region_music(_current_region, _playing_region.is_empty())
	else:
		_cancel_score_build()


func _update_tension_mix() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var pressure := 0.0
	var main := get_tree().get_first_node_in_group("main")
	var night := main != null and main.has_method("is_night") and bool(main.is_night())
	if player != null:
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if enemy is Node2D and is_instance_valid(enemy):
				var distance := player.global_position.distance_to((enemy as Node2D).global_position)
				pressure = maxf(pressure, clampf(1.0 - (distance - 150.0) / 520.0, 0.0, 1.0))
	# After dark the danger stem never disappears completely: insects, distant
	# carrier knocks and the exchange's pulse sit under otherwise quiet roads.
	if night:
		pressure = maxf(pressure, 0.14)
	if pressure >= 0.48 and not _danger_latched:
		_danger_latched = true
		play(&"danger_rise")
	elif pressure <= 0.22:
		_danger_latched = false
	var target_db := lerpf(-40.0, -11.0, pressure)
	if _tension != null:
		_tension.volume_db = lerpf(_tension.volume_db, target_db, 0.16)
		_tension.pitch_scale = lerpf(0.88, 1.08, pressure)
	var score: AudioStreamPlayer = null
	if not _music_players.is_empty():
		score = _music_players[_active_music]
	if score != null:
		score.volume_db = lerpf(score.volume_db, lerpf(MUSIC_LEVEL_DB, MUSIC_DUCK_DB, pressure), 0.12)
		score.pitch_scale = lerpf(score.pitch_scale, 0.94 if night else 1.0, 0.08)
	var profile: Dictionary = _ambience_profile(_current_region)
	var night_lift := 2.0 if night else 0.0
	if _ambience != null:
		var bed_target := float(profile.bed_db) + night_lift - pressure * 2.5
		_ambience.volume_db = lerpf(_ambience.volume_db, bed_target, 0.08)
	if _ambience_detail != null:
		var detail_target := float(profile.detail_db) + night_lift * 0.75 + pressure * 0.8
		_ambience_detail.volume_db = lerpf(_ambience_detail.volume_db, detail_target, 0.08)


func _on_health_changed(current: float, _maximum: float) -> void:
	if _last_health >= 0.0 and current < _last_health - 0.1:
		play(&"player_hurt", 1.0, randf_range(0.93, 1.04))
	_last_health = current


func _on_prompt_changed(text: String) -> void:
	if _last_prompt.is_empty() and not text.is_empty():
		play(&"focus", -6.0)
	_last_prompt = text


func _on_campaign_progress() -> void:
	play(&"objective", -5.0)


func _on_upgrade_built(data) -> void:
	if data != null and data.id == &"route_beacon":
		play(&"beacon")
	else:
		play(&"build")


func _on_craft_completed(_recipe, craft_count: int) -> void:
	play(&"craft_success", 0.0, clampf(0.96 + float(craft_count - 1) * 0.035, 0.96, 1.12))


func _on_craft_rejected(_recipe_id: StringName, _code: StringName) -> void:
	play(&"craft_fail", -2.0)


func _on_node_added(node: Node) -> void:
	if node is Button:
		call_deferred("_wire_button", node)


func _wire_existing_ui(root: Node) -> void:
	if root == null:
		return
	if root is Button:
		_wire_button(root as Button)
	for child in root.get_children():
		_wire_existing_ui(child)


func _wire_button(button: Button) -> void:
	if not is_instance_valid(button) or button.has_meta(&"audio_wired"):
		return
	button.set_meta(&"audio_wired", true)
	button.mouse_entered.connect(func() -> void: play(&"ui_move", -8.0))
	button.focus_entered.connect(func() -> void: play(&"ui_move", -8.0))
	button.pressed.connect(func() -> void: play(&"ui_accept", -5.0))


func _region_from_world() -> String:
	var main := get_tree().get_first_node_in_group("main")
	var path := ""
	if main != null and main.has_method("get_current_level_path"):
		path = String(main.get_current_level_path())
	# Every enterable building shares one interior scene. Its return threshold
	# keeps the source map, so the local soundscape can remain continuous instead
	# of snapping back to Cullbrook behind an Ashmere or Tollard door.
	if path.ends_with("building_interior.tscn"):
		path = String(WorldState.get_flag(&"interior_return_scene", path))
	return _region_from_scene_path(path)


func _region_from_scene_path(path: String) -> String:
	if path.ends_with("railhome_base.tscn"): return "railhome"
	if path.ends_with("ashmere_verge.tscn"): return "ashmere"
	if path.ends_with("broadcast_fields.tscn"): return "wrenfield"
	if path.ends_with("choir_core.tscn"): return "tollard"
	return "cullbrook"


func _ensure_audio_routing() -> void:
	var routes := [
		{"name": "Music", "send": "Master"},
		{"name": "SFX", "send": "Master"},
		{"name": "Ambience", "send": "SFX"},
		{"name": "UI", "send": "SFX"},
	]
	for route in routes:
		var bus_name := String(route.name)
		var index := AudioServer.get_bus_index(bus_name)
		if index < 0:
			AudioServer.add_bus()
			index = AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus_name)
		AudioServer.set_bus_send(index, String(route.send))

	var master := AudioServer.get_bus_index("Master")
	if master < 0:
		return
	for effect_index in AudioServer.get_bus_effect_count(master):
		if AudioServer.get_bus_effect(master, effect_index) is AudioEffectLimiter:
			return
	var limiter := AudioEffectLimiter.new()
	limiter.ceiling_db = -1.0
	limiter.threshold_db = -5.0
	limiter.soft_clip_db = 2.0
	limiter.soft_clip_ratio = 10.0
	AudioServer.add_bus_effect(master, limiter)


func get_audio_runtime_report() -> Dictionary:
	var player_names: Array[String] = []
	var player_ids: Dictionary = {}
	var duplicate_player_references: Array[String] = []
	var audio_child_count := 0
	for child in get_children():
		if child is AudioStreamPlayer:
			audio_child_count += 1
			player_names.append(String(child.name))
			var instance_key := str(child.get_instance_id())
			if player_ids.has(instance_key):
				duplicate_player_references.append(String(child.name))
			player_ids[instance_key] = true

	var invalid_cue_streams: Array[String] = []
	for cue_id in REQUIRED_CUES:
		var stream := _streams.get(cue_id) as AudioStreamWAV
		if stream == null or stream.mix_rate <= 0 or stream.data.is_empty():
			invalid_cue_streams.append(String(cue_id))

	var bus_state: Dictionary = {}
	for bus_name in ["Master", "Music", "SFX", "Ambience", "UI"]:
		var index := AudioServer.get_bus_index(bus_name)
		if index < 0:
			continue
		bus_state[bus_name] = {
			"send": AudioServer.get_bus_send(index),
			"muted": AudioServer.is_bus_mute(index),
			"volume_db": AudioServer.get_bus_volume_db(index),
		}

	var active_score: AudioStreamPlayer = null
	if not _music_players.is_empty() and _active_music >= 0 and _active_music < _music_players.size():
		active_score = _music_players[_active_music]
	return {
		"graph_ready": _playback_graph_ready(),
		"audio_unlocked": _audio_unlocked,
		"expected_player_count": EXPECTED_PLAYER_COUNT,
		"audio_child_count": audio_child_count,
		"player_names": player_names,
		"unique_player_references": player_ids.size(),
		"duplicate_player_references": duplicate_player_references,
		"sfx_player_count": _sfx_players.size(),
		"music_player_count": _music_players.size(),
		"cue_stream_count": _streams.size(),
		"invalid_cue_streams": invalid_cue_streams,
		"current_region": _current_region,
		"ambience_region": _ambience_region,
		"playing_region": _playing_region,
		"ambience_bed_ready": _ambience != null and _ambience.stream != null,
		"ambience_detail_ready": _ambience_detail != null and _ambience_detail.stream != null,
		"ambience_bed_playing": _ambience != null and _ambience.playing,
		"ambience_detail_playing": _ambience_detail != null and _ambience_detail.playing,
		"tension_ready": _tension != null and _tension.stream != null,
		"tension_playing": _tension != null and _tension.playing,
		"music_stream_ready": active_score != null and active_score.stream != null,
		"music_playing": active_score != null and active_score.playing,
		"score_build_region": _score_build_region,
		"start_requests": _start_requests.duplicate(true),
		"bus_state": bus_state,
	}


func get_audio_smoke_report() -> Dictionary:
	var errors: Array[String] = []
	var max_theoretical_peak := 0.0
	var max_rendered_peak := 0.0
	var clipped_samples := 0
	var rendered_cues := 0
	var silent_cues: Array[String] = []
	for cue_id in REQUIRED_CUES:
		if not CUE_SPECS.has(cue_id):
			errors.append("missing cue spec: %s" % String(cue_id))
	for raw_id in CUE_SPECS:
		var cue_id := StringName(raw_id)
		var spec: Dictionary = CUE_SPECS[raw_id]
		var duration := float(spec.get("duration", 0.0))
		var frequency := float(spec.get("frequency", 0.0))
		var options: Dictionary = spec.get("options", {})
		var amplitude := float(options.get("amp", 0.28))
		var second_voice := 0.58 if float(options.get("freq2", 0.0)) > 0.0 else 0.0
		var noise := maxf(float(options.get("noise", 0.0)), 0.0)
		var theoretical_peak := amplitude * (1.0 + second_voice + noise)
		max_theoretical_peak = maxf(max_theoretical_peak, theoretical_peak)
		if duration < 0.03 or duration > 2.5:
			errors.append("cue duration outside contract: %s" % String(cue_id))
		if frequency < 35.0 or frequency > 6000.0:
			errors.append("cue frequency outside contract: %s" % String(cue_id))
		if amplitude <= 0.0 or theoretical_peak > SAFE_SYNTH_PEAK:
			errors.append("cue peak outside contract: %s" % String(cue_id))
		var rendered := _synth(duration, frequency, options.duplicate(true))
		var expected_bytes := int(duration * MIX_RATE) * 2
		if rendered.data.size() != expected_bytes:
			errors.append("cue PCM size mismatch: %s" % String(cue_id))
		else:
			rendered_cues += 1
		var cue_peak := 0.0
		for byte_index in range(0, rendered.data.size(), 2):
			var sample_value := int(rendered.data[byte_index]) | (int(rendered.data[byte_index + 1]) << 8)
			if sample_value >= 32768:
				sample_value -= 65536
			var magnitude := absi(sample_value)
			var normalized := float(magnitude) / 32767.0
			cue_peak = maxf(cue_peak, normalized)
			max_rendered_peak = maxf(max_rendered_peak, normalized)
			if magnitude >= 32767:
				clipped_samples += 1
		if cue_peak < 0.005:
			silent_cues.append(String(cue_id))
			errors.append("cue PCM is silent: %s" % String(cue_id))
		var mix: Dictionary = CUE_MIX.get(cue_id, {})
		var bus_name := String(mix.get("bus", &"SFX"))
		if AudioServer.get_bus_index(bus_name) < 0:
			errors.append("cue bus missing: %s -> %s" % [String(cue_id), bus_name])

	for region in REGION_AMBIENCE:
		var profile: Dictionary = REGION_AMBIENCE[region]
		for key in ["bed_db", "detail_db"]:
			var level := float(profile.get(key, -60.0))
			if level < -30.0 or level > -16.0:
				errors.append("ambience level outside contract: %s/%s" % [region, key])

	var buses: Dictionary = {}
	var bus_volumes: Dictionary = {}
	for bus_name in ["Master", "Music", "SFX", "Ambience", "UI"]:
		var index := AudioServer.get_bus_index(bus_name)
		if index < 0:
			errors.append("audio bus missing: " + bus_name)
			continue
		buses[bus_name] = AudioServer.get_bus_send(index)
		bus_volumes[bus_name] = AudioServer.get_bus_volume_db(index)

	var limiter_ready := false
	var master := AudioServer.get_bus_index("Master")
	if master >= 0:
		for effect_index in AudioServer.get_bus_effect_count(master):
			if AudioServer.get_bus_effect(master, effect_index) is AudioEffectLimiter:
				limiter_ready = true
				break
	if not limiter_ready:
		errors.append("master limiter missing")
	if CUE_OUTPUT_MAX_DB > -1.0 or CUE_OUTPUT_MAX_DB < -6.0:
		errors.append("cue output ceiling outside contract")
	if SFX_GAIN_DB > -2.0 or SFX_GAIN_DB < -12.0:
		errors.append("SFX base gain outside contract")
	if clipped_samples > 0:
		errors.append("procedural cue PCM contains clipped samples")

	var deterministic_spec: Dictionary = CUE_SPECS[&"radio_static"]
	var deterministic_a := _synth(
		float(deterministic_spec.duration),
		float(deterministic_spec.frequency),
		(deterministic_spec.options as Dictionary).duplicate(true),
	)
	var deterministic_b := _synth(
		float(deterministic_spec.duration),
		float(deterministic_spec.frequency),
		(deterministic_spec.options as Dictionary).duplicate(true),
	)
	var deterministic_noise := deterministic_a.data == deterministic_b.data
	if not deterministic_noise:
		errors.append("seeded procedural cue is not deterministic")

	return {
		"contract_errors": errors,
		"cue_count": CUE_SPECS.size(),
		"cue_ids": CUE_SPECS.keys(),
		"required_cue_count": REQUIRED_CUES.size(),
		"max_theoretical_peak": max_theoretical_peak,
		"max_rendered_peak": max_rendered_peak,
		"clipped_samples": clipped_samples,
		"silent_cues": silent_cues,
		"rendered_cues": rendered_cues,
		"deterministic_noise": deterministic_noise,
		"safe_synth_peak": SAFE_SYNTH_PEAK,
		"sfx_pool_size": SFX_POOL_SIZE,
		"sfx_gain_db": SFX_GAIN_DB,
		"cue_call_min_db": CUE_CALL_MIN_DB,
		"cue_call_max_db": CUE_CALL_MAX_DB,
		"cue_output_max_db": CUE_OUTPUT_MAX_DB,
		"music_level_db": MUSIC_LEVEL_DB,
		"music_duck_db": MUSIC_DUCK_DB,
		"ambience_regions": REGION_AMBIENCE.size(),
		"buses": buses,
		"bus_volumes": bus_volumes,
		"master_limiter": limiter_ready,
	}


func _build_streams() -> void:
	_streams.clear()
	for raw_id in CUE_SPECS:
		var cue_id := StringName(raw_id)
		var spec: Dictionary = CUE_SPECS[raw_id]
		_streams[cue_id] = _synth(
			float(spec.duration),
			float(spec.frequency),
			(spec.options as Dictionary).duplicate(true),
		)


func _synth(duration: float, frequency: float, options: Dictionary) -> AudioStreamWAV:
	var count := int(duration * MIX_RATE)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var second: float = options.get("freq2", 0.0)
	var sweep: float = options.get("sweep", 0.0)
	var wobble: float = options.get("wobble", 0.0)
	var noise: float = options.get("noise", 0.0)
	var decay: float = options.get("decay", 6.0)
	var attack: float = options.get("attack", 0.006)
	var amplitude: float = options.get("amp", 0.28)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(options.get("seed", 4242))
	for i in count:
		var t := float(i) / MIX_RATE
		var envelope := exp(-t * decay)
		if t < attack: envelope *= t / attack
		var drift := 1.0 + sweep * t
		var sample := sin(TAU * frequency * drift * t + sin(TAU * 5.0 * t) * wobble)
		if second > 0.0: sample += 0.58 * sin(TAU * second * drift * t)
		if noise > 0.0: sample += noise * rng.randf_range(-1.0, 1.0)
		_write_sample(bytes, i, sample * envelope * amplitude)
	return _wav(bytes, count, false)


func _build_tension_bed() -> AudioStreamWAV:
	var duration := 8.0
	var count := int(duration * MIX_RATE)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 80117
	var low_noise := 0.0
	for i in count:
		var t := float(i) / MIX_RATE
		low_noise = low_noise * 0.975 + rng.randf_range(-1.0, 1.0) * 0.025
		var throb := (sin(TAU * 1.45 * t) * 0.5 + 0.5)
		var pulse := sin(TAU * 73.4 * t) * pow(throb, 5.0) * 0.17
		var wire := sin(TAU * 311.0 * t + sin(t * 2.1) * 2.0) * 0.028
		var edge := _edge_fade(i, count, int(0.25 * MIX_RATE))
		_write_sample(bytes, i, (pulse + wire + low_noise * 0.09) * edge)
	return _wav(bytes, count, true)


func _build_region_ambience(region: String, detail: bool) -> AudioStreamWAV:
	var profile: Dictionary = _ambience_profile(region)
	var count := int(AMBIENCE_DURATION * MIX_RATE)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(profile.seed) + (97 if detail else 0)
	var low := 0.0
	var air := 0.0
	var bed_hz := float(profile.bed_hz)
	var detail_hz := float(profile.detail_hz)
	var event_rate := float(profile.event_rate)
	for i in count:
		var t := float(i) / MIX_RATE
		var raw := rng.randf_range(-1.0, 1.0)
		low = low * 0.972 + raw * 0.028
		air = air * 0.58 + raw * 0.42
		var swell := 0.62 + 0.38 * sin(TAU * (0.11 + event_rate * 0.04) * t)
		var sample: float
		if detail:
			var event_phase := maxf(sin(TAU * event_rate * t - 0.7), 0.0)
			var event_envelope := pow(event_phase, 18.0)
			var marker := sin(TAU * detail_hz * t) * event_envelope * 0.13
			var hardware_hum := sin(TAU * detail_hz * 0.5 * t + sin(t * 0.7)) * 0.028
			sample = marker + hardware_hum + air * 0.032 + low * 0.028
		else:
			var body := sin(TAU * bed_hz * t + sin(t * 0.21) * 0.8) * 0.036
			var phone_band := sin(TAU * bed_hz * 4.0 * t + 0.4) * 0.014
			sample = low * 0.19 * swell + air * 0.024 + body + phone_band
		var edge := _edge_fade(i, count, int(0.25 * MIX_RATE))
		_write_sample(bytes, i, sample * edge)
	return _wav(bytes, count, true)


func _wav(bytes: PackedByteArray, count: int, looped: bool) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = bytes
	if looped:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = count
	return stream


func _write_sample(bytes: PackedByteArray, index: int, sample: float) -> void:
	var value := int(clampf(sample, -1.0, 1.0) * 32767.0)
	bytes[index * 2] = value & 0xFF
	bytes[index * 2 + 1] = (value >> 8) & 0xFF


func _edge_fade(index: int, count: int, fade: int) -> float:
	if index < fade: return float(index) / fade
	if index > count - fade: return float(count - index) / fade
	return 1.0
