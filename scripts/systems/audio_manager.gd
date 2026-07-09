extends Node
## Autoload: AudioManager
##
## Lightweight, dependency-free sound feedback. Every sound is a short PCM tone
## synthesised in memory at startup -- there are no audio asset files to import
## or ship. Sounds play through a small pool of AudioStreamPlayers, either in
## response to EventBus signals (scan, echo reveal, rest, upgrades) or via
## direct AudioManager.play() calls from gameplay scripts (pickup, echo
## recover, Hollow hit/death, ending hook).
##
## Headless-safe: with the dummy audio driver, play() is a harmless no-op, so
## `--headless` validation is unaffected. Keep the palette small and quiet;
## this is feedback, not a soundtrack.

const MIX_RATE := 22050
const POOL_SIZE := 8
## Global trim so the whole set stays present but non-annoying.
const MASTER_DB := -9.0

var _streams: Dictionary = {}          # StringName -> AudioStreamWAV
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _ambient: AudioStreamPlayer = null


func _ready() -> void:
	# Keep short sounds audible even across a pause toggle.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_streams()
	for _i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = &"Master"
		add_child(p)
		_players.append(p)

	# Low, continuous wasteland wind so the world never feels dead-silent.
	_ambient = AudioStreamPlayer.new()
	_ambient.bus = &"Master"
	_ambient.stream = _build_wind()
	_ambient.volume_db = -25.0
	add_child(_ambient)
	# Re-arm on finish instead of a server-held loop (cleaner teardown).
	_ambient.finished.connect(_replay_ambient)
	# Only run the continuous ambient when there's a real output (windowed game).
	# Headless has no audio device, so skipping it keeps --headless teardown clean.
	if DisplayServer.get_name() != "headless":
		_ambient.play()

	# Event-driven hooks (systems that already emit a signal for the moment).
	EventBus.scanner_pulsed.connect(_on_scanner_pulsed)
	EventBus.echo_revealed.connect(_on_echo_revealed)
	EventBus.game_saved.connect(_on_game_saved)
	BaseUpgradeSystem.upgrade_built.connect(_on_upgrade_built)


func _replay_ambient() -> void:
	if _ambient != null and is_inside_tree():
		_ambient.play()


## Release every generated stream before teardown so nothing is held by the
## audio server at exit (avoids leaked-instance warnings on quit).
func _exit_tree() -> void:
	if _ambient != null:
		if _ambient.finished.is_connected(_replay_ambient):
			_ambient.finished.disconnect(_replay_ambient)
		_ambient.stop()
		_ambient.stream = null
	for p in _players:
		p.stop()
		p.stream = null
	_streams.clear()


## Play a pre-built sound by name. Unknown names are ignored. `volume_db` is an
## offset on top of MASTER_DB; `pitch` lets callers add slight variation.
func play(sound: StringName, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	var stream: AudioStream = _streams.get(sound)
	if stream == null:
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = stream
	p.volume_db = MASTER_DB + volume_db
	p.pitch_scale = pitch
	p.play()


# --- Event handlers ---------------------------------------------------------

func _on_scanner_pulsed(_origin: Vector2, _radius: float) -> void:
	play(&"scan")


func _on_echo_revealed(_data) -> void:
	play(&"echo_reveal")


func _on_game_saved() -> void:
	play(&"rest")


func _on_upgrade_built(data) -> void:
	# Route Beacon gets a softer, smaller confirmation than the Radio Desk.
	if data != null and data.id == &"route_beacon":
		play(&"beacon")
	else:
		play(&"build")


# --- Sound bank -------------------------------------------------------------

func _build_streams() -> void:
	# Bright, friendly pickup blip.
	_streams[&"pickup"] = _synth(0.16, 520.0, {"freq2": 780.0, "decay": 14.0, "amp": 0.30})
	# Airy cyan sweep for a scanner pulse.
	_streams[&"scan"] = _synth(0.34, 300.0, {"sweep": 1.4, "wobble": 0.4, "decay": 5.0, "amp": 0.22})
	# Shimmering reveal when a hidden echo tears free.
	_streams[&"echo_reveal"] = _synth(0.5, 660.0, {"freq2": 990.0, "wobble": 8.0, "decay": 3.5, "amp": 0.24})
	# Warm, resolving glow when the echo is recovered.
	_streams[&"echo_recover"] = _synth(0.6, 440.0, {"freq2": 660.0, "decay": 3.0, "amp": 0.26})
	# Dull noisy thud when a Hollow is struck.
	_streams[&"hollow_hit"] = _synth(0.12, 150.0, {"noise": 0.5, "decay": 22.0, "amp": 0.30})
	# Airy descending dissolve as a Hollow disperses.
	_streams[&"hollow_death"] = _synth(0.45, 380.0, {"sweep": -0.6, "noise": 0.15, "decay": 6.0, "amp": 0.24})
	# Confident warm two-tone for the Radio Desk coming online.
	_streams[&"build"] = _synth(0.5, 330.0, {"freq2": 494.0, "decay": 4.0, "amp": 0.27})
	# Softer single warm note for the optional Route Beacon.
	_streams[&"beacon"] = _synth(0.35, 392.0, {"decay": 6.0, "amp": 0.24})
	# Gentle low chord for resting / saving at the bedroll.
	_streams[&"rest"] = _synth(0.5, 262.0, {"freq2": 349.0, "decay": 4.0, "amp": 0.22})
	# Low, wrong, ominous tone for the ending hook from the north.
	_streams[&"ending"] = _synth(0.7, 110.0, {"freq2": 165.0, "wobble": 3.0, "noise": 0.06, "decay": 2.5, "amp": 0.26})
	# Soft dull "gulp" for eating a ration.
	_streams[&"eat"] = _synth(0.24, 220.0, {"freq2": 165.0, "noise": 0.12, "decay": 9.0, "amp": 0.24})
	# Gentle warm chime for storing/recognising a keepsake.
	_streams[&"keepsake"] = _synth(0.6, 523.0, {"freq2": 784.0, "wobble": 3.0, "decay": 3.0, "amp": 0.2})


## Synthesise one short mono 16-bit tone into an AudioStreamWAV.
## opts keys (all optional): freq2 (added harmonic Hz), sweep (frequency drift
## factor over the sound), wobble (vibrato depth), noise (0..1 white noise mix),
## decay (exponential falloff rate), attack (fade-in seconds), amp (0..1),
## seed (noise RNG seed).
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


## A seamless low wind bed: low-passed noise with a slow swell. Looped forever
## by the ambient player. Edges are faded so the loop point doesn't click.
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
		lp = lp * 0.96 + rng.randf_range(-1.0, 1.0) * 0.04  # low-pass -> rumble
		var swell := 0.6 + 0.4 * sin(TAU * 0.14 * t)
		var edge := 1.0
		if i < fade:
			edge = float(i) / fade
		elif i > n - fade:
			edge = float(n - i) / fade
		var v := clampf(lp * 3.4 * swell * edge, -1.0, 1.0)
		var iv := int(v * 32767.0)
		bytes[i * 2] = iv & 0xFF
		bytes[i * 2 + 1] = (iv >> 8) & 0xFF

	var st := AudioStreamWAV.new()
	st.format = AudioStreamWAV.FORMAT_16_BITS
	st.mix_rate = MIX_RATE
	st.stereo = false
	# Non-looping: the player re-arms on `finished` so nothing is server-held.
	st.loop_mode = AudioStreamWAV.LOOP_DISABLED
	st.data = bytes
	return st
