extends Node
## Autoload: AudioManager
##
## Dependency-free procedural sound feedback plus a quiet ambient bed. There are
## no audio asset files to import or ship. Headless runs skip continuous beds.

const MIX_RATE := 22050
const POOL_SIZE := 8
const MASTER_DB := -9.0

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _ambient: AudioStreamPlayer = null
var _drone: AudioStreamPlayer = null
var _audio_unlocked := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_streams()
	for _i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = &"Master"
		add_child(p)
		_players.append(p)

	_ambient = AudioStreamPlayer.new()
	_ambient.bus = &"Master"
	_ambient.stream = _build_wind()
	add_child(_ambient)
	_ambient.finished.connect(_replay_ambient)

	_drone = AudioStreamPlayer.new()
	_drone.bus = &"Master"
	_drone.stream = _build_drone()
	add_child(_drone)
	_drone.finished.connect(_replay_drone)

	EventBus.scanner_pulsed.connect(_on_scanner_pulsed)
	EventBus.echo_revealed.connect(_on_echo_revealed)
	EventBus.game_saved.connect(_on_game_saved)
	EventBus.level_loaded.connect(_update_environment_mix)
	BaseUpgradeSystem.upgrade_built.connect(_on_upgrade_built)
	_update_environment_mix()

	# Browsers require a user gesture before audio playback. Desktop starts
	# immediately; MainMenu calls unlock_audio() on the first press/click.
	if DisplayServer.get_name() != "headless" and not OS.has_feature("web"):
		unlock_audio()


func unlock_audio() -> void:
	if _audio_unlocked or DisplayServer.get_name() == "headless":
		return
	_audio_unlocked = true
	if _ambient != null and not _ambient.playing:
		_ambient.play()
	if _drone != null and not _drone.playing:
		_drone.play()


func _replay_ambient() -> void:
	if _ambient != null and is_inside_tree() and _audio_unlocked:
		_ambient.play()


func _replay_drone() -> void:
	if _drone != null and is_inside_tree() and _audio_unlocked:
		_drone.play()


func _update_environment_mix() -> void:
	var at_base := false
	var main := get_tree().get_first_node_in_group("main")
	if main != null and main.has_method("get_current_level_path"):
		at_base = main.get_current_level_path() == GameManager.BASE_SCENE_PATH
	if _ambient != null:
		_ambient.volume_db = -32.0 if at_base else -25.0
	if _drone != null:
		_drone.volume_db = -35.0 if at_base else -30.0
		_drone.pitch_scale = 0.82 if at_base else 1.0


func _exit_tree() -> void:
	if _ambient != null:
		if _ambient.finished.is_connected(_replay_ambient):
			_ambient.finished.disconnect(_replay_ambient)
		_ambient.stop()
		_ambient.stream = null
	if _drone != null:
		if _drone.finished.is_connected(_replay_drone):
			_drone.finished.disconnect(_replay_drone)
		_drone.stop()
		_drone.stream = null
	for p in _players:
		p.stop()
		p.stream = null
	_streams.clear()


func play(sound: StringName, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if DisplayServer.get_name() == "headless":
		return
	# A click/key press that triggers a cue is itself a valid Web audio gesture.
	if not _audio_unlocked and DisplayServer.get_name() != "headless":
		unlock_audio()
	var stream: AudioStream = _streams.get(sound)
	if stream == null:
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = stream
	p.volume_db = MASTER_DB + volume_db
	p.pitch_scale = pitch
	p.play()


func _on_scanner_pulsed(_origin: Vector2, _radius: float) -> void:
	play(&"scan")


func _on_echo_revealed(_data) -> void:
	play(&"echo_reveal")


func _on_game_saved() -> void:
	play(&"rest")


func _on_upgrade_built(data) -> void:
	if data != null and data.id == &"route_beacon":
		play(&"beacon")
	elif data != null and data.id == &"scanner_coil":
		play(&"build", 1.0, 1.05)
	else:
		play(&"build")


func _build_streams() -> void:
	_streams[&"pickup"] = _synth(0.16, 520.0, {"freq2": 780.0, "decay": 14.0, "amp": 0.30})
	_streams[&"scan"] = _synth(0.38, 300.0, {"sweep": 1.3, "wobble": 0.5, "decay": 4.8, "amp": 0.23})
	_streams[&"weak_signal"] = _synth(0.48, 190.0, {"freq2": 285.0, "sweep": -0.25, "noise": 0.12, "decay": 4.0, "amp": 0.24})
	_streams[&"echo_reveal"] = _synth(0.82, 660.0, {"freq2": 990.0, "wobble": 9.0, "decay": 2.4, "amp": 0.25})
	_streams[&"echo_recover"] = _synth(0.9, 392.0, {"freq2": 660.0, "wobble": 1.5, "decay": 2.2, "amp": 0.27})
	_streams[&"hollow_hit"] = _synth(0.12, 150.0, {"noise": 0.5, "decay": 22.0, "amp": 0.30})
	_streams[&"hollow_death"] = _synth(0.52, 360.0, {"sweep": -0.7, "noise": 0.18, "decay": 5.4, "amp": 0.25})
	_streams[&"build"] = _synth(0.58, 330.0, {"freq2": 494.0, "decay": 3.6, "amp": 0.28})
	_streams[&"beacon"] = _synth(0.35, 392.0, {"decay": 6.0, "amp": 0.24})
	_streams[&"rest"] = _synth(0.58, 262.0, {"freq2": 349.0, "decay": 3.6, "amp": 0.23})
	_streams[&"ending"] = _synth(0.8, 110.0, {"freq2": 165.0, "wobble": 3.0, "noise": 0.06, "decay": 2.3, "amp": 0.27})
	_streams[&"eat"] = _synth(0.24, 220.0, {"freq2": 165.0, "noise": 0.12, "decay": 9.0, "amp": 0.24})
	_streams[&"keepsake"] = _synth(0.68, 523.0, {"freq2": 784.0, "wobble": 3.0, "decay": 2.8, "amp": 0.21})
	_streams[&"swing"] = _synth(0.14, 205.0, {"sweep": 1.8, "noise": 0.16, "decay": 18.0, "amp": 0.24})
	_streams[&"dodge"] = _synth(0.22, 280.0, {"sweep": 1.4, "noise": 0.22, "decay": 12.0, "amp": 0.22})
	_streams[&"memory_burst"] = _synth(0.72, 196.0, {"freq2": 784.0, "sweep": 0.8, "wobble": 2.5, "decay": 3.0, "amp": 0.29})
	_streams[&"dialogue_open"] = _synth(0.28, 330.0, {"freq2": 495.0, "noise": 0.05, "decay": 7.0, "amp": 0.18})
	_streams[&"dialogue_tick"] = _synth(0.08, 620.0, {"decay": 24.0, "amp": 0.12})
	_streams[&"choice"] = _synth(0.38, 440.0, {"freq2": 660.0, "decay": 6.0, "amp": 0.22})
	_streams[&"archive"] = _synth(0.44, 262.0, {"freq2": 523.0, "wobble": 1.2, "decay": 5.0, "amp": 0.20})
	_streams[&"relay_restore"] = _synth(0.95, 110.0, {"freq2": 440.0, "sweep": 0.65, "wobble": 2.2, "decay": 2.2, "amp": 0.27})
	_streams[&"finale"] = _synth(1.65, 130.8, {"freq2": 392.0, "wobble": 1.1, "decay": 1.25, "amp": 0.27})


func _synth(dur: float, freq: float, opts: Dictionary) -> AudioStreamWAV:
	var n := int(dur * MIX_RATE)
	var bytes := PackedByteArray()
	bytes.resize(n * 2)

	var freq2: float = opts.get("freq2", 0.0)
	var sweep: float = opts.get("sweep", 0.0)
	var wobble: float = opts.get("wobble", 0.0)
	var noise: float = opts.get("noise", 0.0)
	var decay: float = opts.get("decay", 6.0)
	var attack: float = opts.get("attack", 0.006)
	var amp: float = opts.get("amp", 0.28)

	var rng := RandomNumberGenerator.new()
	rng.seed = int(opts.get("seed", 4242))

	for i in n:
		var t := float(i) / MIX_RATE
		var env := exp(-t * decay)
		if t < attack:
			env *= t / attack
		var drift := 1.0 + sweep * t
		var vib := sin(TAU * 5.0 * t) * wobble
		var s := sin(TAU * freq * drift * t + vib)
		if freq2 > 0.0:
			s += 0.6 * sin(TAU * freq2 * drift * t)
		if noise > 0.0:
			s += noise * rng.randf_range(-1.0, 1.0)
		var v := clampf(s * env * amp, -1.0, 1.0)
		var iv := int(v * 32767.0)
		bytes[i * 2] = iv & 0xFF
		bytes[i * 2 + 1] = (iv >> 8) & 0xFF

	var st := AudioStreamWAV.new()
	st.format = AudioStreamWAV.FORMAT_16_BITS
	st.mix_rate = MIX_RATE
	st.stereo = false
	st.loop_mode = AudioStreamWAV.LOOP_DISABLED
	st.data = bytes
	return st


func _build_wind() -> AudioStreamWAV:
	var dur := 3.0
	var n := int(dur * MIX_RATE)
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 9911
	var lp := 0.0
	var fade := int(0.12 * MIX_RATE)
	for i in n:
		var t := float(i) / MIX_RATE
		lp = lp * 0.96 + rng.randf_range(-1.0, 1.0) * 0.04
		var swell := 0.6 + 0.4 * sin(TAU * 0.14 * t)
		var edge := _edge_fade(i, n, fade)
		var v := clampf(lp * 3.4 * swell * edge, -1.0, 1.0)
		var iv := int(v * 32767.0)
		bytes[i * 2] = iv & 0xFF
		bytes[i * 2 + 1] = (iv >> 8) & 0xFF

	var st := AudioStreamWAV.new()
	st.format = AudioStreamWAV.FORMAT_16_BITS
	st.mix_rate = MIX_RATE
	st.stereo = false
	st.loop_mode = AudioStreamWAV.LOOP_DISABLED
	st.data = bytes
	return st


func _build_drone() -> AudioStreamWAV:
	var dur := 5.0
	var n := int(dur * MIX_RATE)
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 14011
	var lp := 0.0
	var fade := int(0.25 * MIX_RATE)
	for i in n:
		var t := float(i) / MIX_RATE
		lp = lp * 0.985 + rng.randf_range(-1.0, 1.0) * 0.015
		var base := sin(TAU * 55.0 * t) * 0.34
		var fifth := sin(TAU * 82.5 * t + sin(TAU * 0.07 * t) * 0.8) * 0.22
		var high := sin(TAU * 146.0 * t) * 0.06
		var swell := 0.68 + 0.32 * sin(TAU * 0.045 * t)
		var edge := _edge_fade(i, n, fade)
		var v := clampf((base + fifth + high + lp * 0.8) * swell * edge * 0.32, -1.0, 1.0)
		var iv := int(v * 32767.0)
		bytes[i * 2] = iv & 0xFF
		bytes[i * 2 + 1] = (iv >> 8) & 0xFF

	var st := AudioStreamWAV.new()
	st.format = AudioStreamWAV.FORMAT_16_BITS
	st.mix_rate = MIX_RATE
	st.stereo = false
	st.loop_mode = AudioStreamWAV.LOOP_DISABLED
	st.data = bytes
	return st


func _edge_fade(i: int, n: int, fade: int) -> float:
	if i < fade:
		return float(i) / fade
	if i > n - fade:
		return float(n - i) / fade
	return 1.0
