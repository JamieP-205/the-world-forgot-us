extends Control
## Image-led opening with a restrained dissolve and camera drift.

const STILLS := [
	"res://assets/processed/cinematic_rebuild/cin01_receiver_photo.png",
	"res://assets/processed/cinematic_rebuild/cin02_same_switch.png",
	"res://assets/processed/cinematic_rebuild/cin03_carriage_depot.png",
	"res://assets/processed/cinematic_rebuild/cin04_blank_night.png",
	"res://assets/processed/cinematic_rebuild/cin05_dead_cafe_phone.png",
	"res://assets/processed/cinematic_rebuild/cin06_other_ellie.png",
	"res://assets/processed/cinematic_rebuild/cin07_false_safe_print.png",
	"res://assets/processed/cinematic_rebuild/cin08_playable_choice.png",
]

var _current: TextureRect
var _incoming: TextureRect
var _veil: ColorRect
var _transition: Tween
var _beat := -1
var _elapsed := 0.0


func _ready() -> void:
	clip_contents = true
	_current = _make_layer("CurrentStill")
	_incoming = _make_layer("IncomingStill")
	_incoming.modulate.a = 0.0
	_veil = ColorRect.new()
	_veil.name = "RainVeil"
	_veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_veil.color = Color(0.025, 0.04, 0.038, 0.08)
	add_child(_veil)


func set_beat(index: int) -> void:
	var next_beat := clampi(index, 0, STILLS.size() - 1)
	var texture := load(STILLS[next_beat]) as Texture2D
	if texture == null:
		push_warning("Opening still missing: %s" % STILLS[next_beat])
		return
	_elapsed = 0.0
	if _beat < 0:
		_current.texture = texture
		_current.modulate = Color.WHITE
	else:
		# Rapid keyboard or controller advance can arrive before the dissolve
		# finishes. Commit that visible destination first so an old callback can
		# never clear the newer still or leave the illustration blank.
		if _transition != null and _transition.is_valid():
			_transition.kill()
		if _incoming.texture != null:
			_commit_incoming()
		_incoming.texture = texture
		_incoming.modulate = Color(1, 1, 1, 0)
		_incoming.scale = Vector2(1.025, 1.025)
		_transition = create_tween().set_parallel(true)
		_transition.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		_transition.tween_property(_incoming, "modulate:a", 1.0, 0.72)
		_transition.tween_property(_current, "modulate:a", 0.0, 0.72)
		_transition.chain().tween_callback(_commit_incoming)
	_beat = next_beat


func _process(delta: float) -> void:
	_elapsed += delta
	# The stills stay composed; this sub-pixel drift is enough to keep rain and
	# depth alive without turning a quiet image into a slideshow template.
	var direction := -1.0 if _beat % 2 == 0 else 1.0
	var drift := clampf(_elapsed / 9.0, 0.0, 1.0)
	_current.scale = Vector2.ONE * (1.018 + drift * 0.018)
	_current.position = Vector2(direction * drift * 9.0, -drift * 4.0)
	_veil.color.a = 0.065 + sin(_elapsed * 0.72) * 0.012


func _make_layer(node_name: String) -> TextureRect:
	var layer := TextureRect.new()
	layer.name = node_name
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	layer.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.pivot_offset = size * 0.5
	add_child(layer)
	return layer


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		if _current != null:
			_current.pivot_offset = size * 0.5
		if _incoming != null:
			_incoming.pivot_offset = size * 0.5


func _commit_incoming() -> void:
	if _incoming.texture == null:
		_transition = null
		return
	_current.texture = _incoming.texture
	_current.modulate = Color.WHITE
	_current.scale = _incoming.scale
	_incoming.texture = null
	_incoming.modulate.a = 0.0
	_transition = null
