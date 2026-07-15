extends Node
## Procedural score and sound direction. Every region has its own restrained
## harmonic language; a second stem rises when enemies close in. The approach
## keeps the download small while providing authored variation rather than a
## single endless drone.

const MIX_RATE := 22050
const SFX_POOL_SIZE := 12
const SFX_GAIN_DB := -7.0
const MUSIC_FADE := 1.8
const SCORE_DURATION := 16.0
const SCORE_BUILD_CHUNK := 4096

var _streams: Dictionary = {}
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_index := 0
var _music_players: Array[AudioStreamPlayer] = []
var _active_music := 0
var _tension: AudioStreamPlayer
var _ambience: AudioStreamPlayer
var _music_cache: Dictionary = {}
var _current_region := ""
var _playing_region := ""
var _audio_unlocked := false
var _mix_clock := 0.0
var _last_health := -1.0
var _last_prompt := ""
var _last_step_ms := 0
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
	# Headless validation has no audio device and should never spend time
	# synthesizing streams it cannot play.
	if DisplayServer.get_name() == "headless":
		return
	_build_streams()
	for _i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = &"SFX"
		add_child(player)
		_sfx_players.append(player)

	for _i in 2:
		var music := AudioStreamPlayer.new()
		music.bus = &"Music"
		music.volume_db = -60.0
		add_child(music)
		_music_players.append(music)

	_tension = AudioStreamPlayer.new()
	_tension.bus = &"Music"
	_tension.volume_db = -38.0
	_tension.stream = _build_tension_bed()
	add_child(_tension)

	_ambience = AudioStreamPlayer.new()
	_ambience.bus = &"SFX"
	_ambience.volume_db = -28.0
	_ambience.stream = _build_wind()
	add_child(_ambience)

	EventBus.scanner_pulsed.connect(func(_origin: Vector2, _radius: float) -> void: play(&"scan"))
	EventBus.scannable_pinged.connect(func(_position: Vector2) -> void: play(&"signal_tick", -3.0))
	EventBus.echo_revealed.connect(func(_data) -> void: play(&"echo_reveal"))
	EventBus.game_saved.connect(func() -> void: play(&"rest"))
	EventBus.level_loaded.connect(_on_level_loaded)
	EventBus.player_health_changed.connect(_on_health_changed)
	EventBus.interaction_prompt_changed.connect(_on_prompt_changed)
	EventBus.campaign_progress_changed.connect(_on_campaign_progress)
	BaseUpgradeSystem.upgrade_built.connect(_on_upgrade_built)
	SettingsManager.settings_changed.connect(_on_setting_changed)
	get_tree().node_added.connect(_on_node_added)
	call_deferred("_wire_existing_ui", get_tree().root)
	call_deferred("_on_level_loaded")

	if DisplayServer.get_name() != "headless" and not OS.has_feature("web"):
		unlock_audio()


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
	):
		unlock_audio()


func unlock_audio() -> void:
	if _audio_unlocked or DisplayServer.get_name() == "headless":
		return
	_audio_unlocked = true
	if not _ambience.playing:
		_ambience.play()
	if not _tension.playing:
		_tension.play()
	_current_region = _region_from_world()
	_request_region_music(_current_region, true)


func play(sound: StringName, volume_db := 0.0, pitch := 1.0) -> void:
	if DisplayServer.get_name() == "headless":
		return
	if not _audio_unlocked:
		return
	var stream: AudioStream = _streams.get(sound)
	if stream == null or _sfx_players.is_empty():
		return
	var player := _sfx_players[_sfx_index]
	_sfx_index = (_sfx_index + 1) % _sfx_players.size()
	player.stream = stream
	player.volume_db = SFX_GAIN_DB + volume_db
	player.pitch_scale = clampf(pitch, 0.55, 1.8)
	player.play()


func play_footstep(_world_position: Vector2, velocity: Vector2) -> void:
	if velocity.length_squared() < 64.0:
		return
	var now := Time.get_ticks_msec()
	if now - _last_step_ms < 235:
		return
	_last_step_ms = now
	var cue: StringName = &"step_metal" if _current_region == "railhome" else &"step_grit"
	play(cue, -8.0, randf_range(0.92, 1.08))


func _on_level_loaded() -> void:
	var region := _region_from_world()
	_current_region = region
	if _audio_unlocked:
		_request_region_music(region)
		play(&"travel", -2.0, 0.92 if region == "railhome" else 1.0)
	if _ambience != null:
		_ambience.volume_db = -33.0 if region == "railhome" else -27.0
		_ambience.pitch_scale = {
			"railhome": 0.76, "cullbrook": 0.93, "ashmere": 0.82,
			"wrenfield": 1.06, "tollard": 0.69,
		}.get(region, 0.9)


func _play_region_stream(region: String, immediate := false) -> void:
	if region == _playing_region and _music_players[_active_music].playing:
		return
	if not _music_cache.has(region) or not _music_audible():
		return
	var next := 1 - _active_music
	var incoming := _music_players[next]
	var outgoing := _music_players[_active_music]
	incoming.stream = _music_cache[region]
	incoming.volume_db = -60.0
	if _audio_unlocked:
		incoming.play()
	if immediate:
		outgoing.stop()
		incoming.volume_db = -18.0
		_active_music = next
		_playing_region = region
		return
	var tween := create_tween().set_parallel(true)
	tween.tween_property(outgoing, "volume_db", -60.0, MUSIC_FADE)
	tween.tween_property(incoming, "volume_db", -18.0, MUSIC_FADE)
	tween.chain().tween_callback(outgoing.stop)
	_active_music = next
	_playing_region = region


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
	var target_db := lerpf(-42.0, -13.0, pressure)
	_tension.volume_db = lerpf(_tension.volume_db, target_db, 0.16)
	_tension.pitch_scale = lerpf(0.88, 1.08, pressure)
	var score := _music_players[_active_music]
	if score != null:
		score.volume_db = lerpf(score.volume_db, lerpf(-18.0, -23.0, pressure), 0.12)
		score.pitch_scale = lerpf(score.pitch_scale, 0.94 if night else 1.0, 0.08)
	if _ambience != null:
		var region_trim := -33.0 if _current_region == "railhome" else -27.0
		_ambience.volume_db = lerpf(_ambience.volume_db, region_trim + (2.5 if night else 0.0), 0.08)


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
	if path.ends_with("railhome_base.tscn"): return "railhome"
	if path.ends_with("ashmere_verge.tscn"): return "ashmere"
	if path.ends_with("broadcast_fields.tscn"): return "wrenfield"
	if path.ends_with("choir_core.tscn"): return "tollard"
	return "cullbrook"


func _build_streams() -> void:
	_streams[&"pickup"] = _synth(0.15, 523.0, {"freq2": 784.0, "decay": 15.0, "amp": 0.27})
	_streams[&"scan"] = _synth(0.42, 294.0, {"sweep": 1.25, "wobble": 0.55, "decay": 4.7, "amp": 0.22})
	_streams[&"signal_tick"] = _synth(0.09, 1175.0, {"freq2": 880.0, "decay": 28.0, "amp": 0.16})
	_streams[&"weak_signal"] = _synth(0.52, 185.0, {"freq2": 277.5, "sweep": -0.22, "noise": 0.14, "decay": 4.0, "amp": 0.22})
	_streams[&"echo_reveal"] = _synth(0.86, 659.0, {"freq2": 988.0, "wobble": 8.0, "decay": 2.4, "amp": 0.23})
	_streams[&"echo_recover"] = _synth(0.95, 392.0, {"freq2": 659.0, "wobble": 1.6, "decay": 2.1, "amp": 0.25})
	_streams[&"hollow_hit"] = _synth(0.14, 147.0, {"noise": 0.54, "decay": 21.0, "amp": 0.28})
	_streams[&"hollow_death"] = _synth(0.58, 349.0, {"sweep": -0.68, "noise": 0.22, "decay": 5.1, "amp": 0.24})
	_streams[&"player_hurt"] = _synth(0.26, 104.0, {"freq2": 156.0, "noise": 0.42, "decay": 10.0, "amp": 0.3})
	_streams[&"build"] = _synth(0.61, 330.0, {"freq2": 494.0, "decay": 3.4, "amp": 0.27})
	_streams[&"beacon"] = _synth(0.48, 392.0, {"freq2": 587.0, "decay": 5.0, "amp": 0.23})
	_streams[&"rest"] = _synth(0.62, 262.0, {"freq2": 349.0, "decay": 3.5, "amp": 0.21})
	_streams[&"ending"] = _synth(0.9, 110.0, {"freq2": 165.0, "wobble": 3.0, "noise": 0.06, "decay": 2.1, "amp": 0.25})
	_streams[&"eat"] = _synth(0.25, 220.0, {"freq2": 165.0, "noise": 0.12, "decay": 9.0, "amp": 0.22})
	_streams[&"keepsake"] = _synth(0.72, 523.0, {"freq2": 784.0, "wobble": 3.0, "decay": 2.7, "amp": 0.2})
	_streams[&"swing"] = _synth(0.15, 205.0, {"sweep": 1.8, "noise": 0.19, "decay": 18.0, "amp": 0.23})
	_streams[&"dodge"] = _synth(0.23, 280.0, {"sweep": 1.35, "noise": 0.25, "decay": 12.0, "amp": 0.21})
	_streams[&"memory_burst"] = _synth(0.75, 196.0, {"freq2": 784.0, "sweep": 0.8, "wobble": 2.5, "decay": 2.9, "amp": 0.27})
	_streams[&"dialogue_open"] = _synth(0.3, 330.0, {"freq2": 495.0, "noise": 0.05, "decay": 7.0, "amp": 0.17})
	_streams[&"dialogue_tick"] = _synth(0.08, 620.0, {"decay": 24.0, "amp": 0.11})
	_streams[&"choice"] = _synth(0.4, 440.0, {"freq2": 660.0, "decay": 6.0, "amp": 0.2})
	_streams[&"archive"] = _synth(0.46, 262.0, {"freq2": 523.0, "wobble": 1.2, "decay": 5.0, "amp": 0.19})
	_streams[&"relay_restore"] = _synth(1.0, 110.0, {"freq2": 440.0, "sweep": 0.65, "wobble": 2.2, "decay": 2.1, "amp": 0.25})
	_streams[&"finale"] = _synth(1.7, 130.8, {"freq2": 392.0, "wobble": 1.1, "decay": 1.2, "amp": 0.25})
	_streams[&"ui_move"] = _synth(0.045, 740.0, {"decay": 45.0, "amp": 0.1})
	_streams[&"ui_accept"] = _synth(0.13, 392.0, {"freq2": 587.0, "decay": 15.0, "amp": 0.16})
	_streams[&"ui_back"] = _synth(0.12, 330.0, {"sweep": -0.35, "decay": 14.0, "amp": 0.14})
	_streams[&"focus"] = _synth(0.1, 880.0, {"freq2": 440.0, "decay": 20.0, "amp": 0.1})
	_streams[&"objective"] = _synth(0.32, 349.0, {"freq2": 523.0, "decay": 6.5, "amp": 0.17})
	_streams[&"travel"] = _synth(0.7, 92.0, {"freq2": 138.0, "noise": 0.18, "sweep": 0.2, "decay": 3.1, "amp": 0.2})
	_streams[&"map_open"] = _synth(0.24, 247.0, {"freq2": 370.0, "noise": 0.04, "decay": 8.0, "amp": 0.16})
	_streams[&"settings_apply"] = _synth(0.3, 440.0, {"freq2": 659.0, "decay": 7.0, "amp": 0.16})
	_streams[&"radio_static"] = _synth(0.42, 140.0, {"noise": 0.72, "wobble": 4.0, "decay": 4.5, "amp": 0.18})
	_streams[&"step_grit"] = _synth(0.09, 82.0, {"noise": 0.82, "decay": 29.0, "amp": 0.16, "seed": 631})
	_streams[&"step_metal"] = _synth(0.11, 196.0, {"freq2": 294.0, "noise": 0.42, "decay": 23.0, "amp": 0.15, "seed": 917})


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


func _build_wind() -> AudioStreamWAV:
	var duration := 6.0
	var count := int(duration * MIX_RATE)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 9911
	var low := 0.0
	for i in count:
		var t := float(i) / MIX_RATE
		low = low * 0.965 + rng.randf_range(-1.0, 1.0) * 0.035
		var swell := 0.58 + 0.42 * sin(TAU * 0.14 * t)
		var edge := _edge_fade(i, count, int(0.25 * MIX_RATE))
		_write_sample(bytes, i, low * 0.26 * swell * edge)
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
