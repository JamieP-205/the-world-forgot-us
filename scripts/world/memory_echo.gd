class_name MemoryEcho
extends Interactable
## An ordinary object carrying a recoverable trace.
##
## Scanner and interaction inputs move through Detect > Focus > Reveal >
## Verify/File. Filing changes the object's presentation but never removes it.

enum Stage { HIDDEN, DETECTED, FOCUSED, REVEALED, SPENT }

@export var echo_data: MemoryEchoData
@export var required_upgrade_id: StringName = &""
@export_multiline var required_upgrade_notice: String = "The carrier will not hold. Fit a stronger receiver coil, then try again."
@export_range(0.35, 1.0, 0.01) var hidden_alpha: float = 0.58
@export var focus_scan_distance: float = 105.0
@export var artifact_max_extent: float = 112.0
@export var authored_afterimage_max_extent: float = 280.0

var _stage := Stage.HIDDEN
var _blocked_pulse := false
var _last_scan_origin := Vector2.ZERO
var _idle_tween: Tween
var _light_tween: Tween
var _reduced_effects := false
var _light_radius := 0.0
var _afterimage_rest_position := Vector2(5.0, -3.0)

@onready var _artifact: Sprite2D = $Visual/Artifact
@onready var _edge_light: Sprite2D = $Visual/EdgeLight
@onready var _afterimage: Sprite2D = $Visual/Afterimage
@onready var _signal_dust: Sprite2D = $Visual/SignalDust
@onready var _recovery_burst: Sprite2D = $Visual/RecoveryBurst
@onready var _memory_light: PointLight2D = $Visual/MemoryLight
@onready var _scannable: Scannable = $Scannable
@onready var _overlay: TraceAnchorOverlay = $TraceAnchorOverlay


func _ready() -> void:
	# The receiver overlay pauses gameplay, but the object beneath it still has
	# to finish its light and alignment transitions.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_scannable.scanned.connect(_on_scanned)
	_overlay.advance_requested.connect(reveal_trace)
	_overlay.resolution_requested.connect(resolve_trace)
	_reduced_effects = SettingsManager.get_bool("accessibility", "reduced_effects")
	if not SettingsManager.settings_changed.is_connected(_on_setting_changed):
		SettingsManager.settings_changed.connect(_on_setting_changed)
	_apply_authored_artifact()
	if echo_data != null and ArchiveSystem.has_echo(echo_data.id):
		_stage = Stage.SPENT
		_scannable.remove_from_group("scannables")
		_apply_stage_visual(false)
		return
	_apply_stage_visual(false)


func is_available() -> bool:
	return _stage in [Stage.DETECTED, Stage.FOCUSED, Stage.REVEALED]


func get_prompt() -> String:
	match _stage:
		Stage.DETECTED:
			return "Tune receiver to %s" % _artifact_name()
		Stage.FOCUSED:
			return "Hold the signal on %s" % _artifact_name()
		Stage.REVEALED:
			return "Review the recovered memory"
	return ""


func interact(_player: Node2D) -> void:
	match _stage:
		Stage.DETECTED:
			focus_trace()
		Stage.FOCUSED:
			reveal_trace()
		Stage.REVEALED:
			_overlay.present_reveal(echo_data, _bearing_text(_last_scan_origin))


func detect_from(origin: Vector2) -> bool:
	if _stage != Stage.HIDDEN or _requires_upgrade():
		if _requires_upgrade():
			_show_blocked_signal()
		return false
	_last_scan_origin = origin
	_stage = Stage.DETECTED
	_apply_stage_visual(true)
	AudioManager.play(&"signal_tick", -7.0, 0.88)
	EventBus.notice_posted.emit(
		"Signal found: %s.\n%s\nMove closer and sweep again."
		% [_artifact_name(), _bearing_text(origin)])
	EventBus.camera_shake_requested.emit(0.7, 0.06)
	return true


func focus_trace(origin: Vector2 = Vector2.INF) -> bool:
	if _stage != Stage.DETECTED:
		if _stage == Stage.FOCUSED:
			_overlay.present_focus(echo_data, _bearing_text(_last_scan_origin))
		return false
	if origin != Vector2.INF:
		_last_scan_origin = origin
	else:
		var player := get_tree().get_first_node_in_group("player") as Node2D
		if player != null:
			_last_scan_origin = player.global_position
	_stage = Stage.FOCUSED
	_apply_stage_visual(true)
	AudioManager.play(&"weak_signal", -8.0, 0.92)
	_overlay.present_focus(echo_data, _bearing_text(_last_scan_origin))
	return true


func reveal_trace() -> bool:
	if _stage != Stage.FOCUSED:
		return false
	_stage = Stage.REVEALED
	_apply_stage_visual(true)
	EventBus.echo_revealed.emit(echo_data)
	EventBus.notice_posted.emit(
		"Memory recovered from the object.\n%s"
		% (echo_data.evidence_label() if echo_data != null else "UNCLASSIFIED EVIDENCE"))
	EventBus.camera_shake_requested.emit(1.8, 0.11)
	_overlay.present_reveal(echo_data, _bearing_text(_last_scan_origin))
	return true


func resolve_trace(disposition: StringName) -> bool:
	if _stage != Stage.REVEALED or echo_data == null:
		return false
	disposition = ArchiveSystem.FED if disposition == ArchiveSystem.FED else ArchiveSystem.VERIFIED

	# Complete rewards and consequence state before the archive signal asks the
	# campaign to autosave, so a single save contains the whole transaction.
	if echo_data.keepsake_item != &"":
		InventorySystem.add_item(echo_data.keepsake_item, 1)
	if disposition == ArchiveSystem.FED and CampaignSystem.has_method("record_trace_fed"):
		CampaignSystem.call("record_trace_fed", echo_data.id, true, false)
	ArchiveSystem.record_echo(echo_data, disposition)

	_stage = Stage.SPENT
	_scannable.remove_from_group("scannables")
	_overlay.close_overlay()
	_apply_stage_visual(true)
	if disposition == ArchiveSystem.FED:
		AudioManager.play(&"weak_signal", -4.0, 0.74)
		EventBus.notice_posted.emit(
			"Sent without checking: %s.\n%s"
			% [_artifact_name(), echo_data.feed_warning])
	else:
		AudioManager.play(&"echo_recover")
		EventBus.notice_posted.emit(
			"Checked and filed: %s.\n%s"
			% [_artifact_name(), echo_data.verification_text])
	EventBus.camera_shake_requested.emit(1.6, 0.1)
	return true


func get_trace_stage() -> StringName:
	match _stage:
		Stage.HIDDEN: return &"hidden"
		Stage.DETECTED: return &"detected"
		Stage.FOCUSED: return &"focused"
		Stage.REVEALED: return &"revealed"
		Stage.SPENT: return &"spent"
	return &"hidden"


func get_trace_snapshot() -> Dictionary:
	var afterimage_material := _afterimage.material as ShaderMaterial
	var artifact_material := _artifact.material as ShaderMaterial
	return {
		"id": echo_data.id if echo_data != null else &"",
		"stage": get_trace_stage(),
		"artifact_visible": _artifact.visible and _artifact.modulate.a > 0.0,
		"afterimage_visible": _afterimage.visible and _afterimage.modulate.a > 0.0,
		"afterimage_shader": afterimage_material != null,
		"afterimage_alignment": float(afterimage_material.get_shader_parameter("alignment"))
			if afterimage_material != null else 0.0,
		"afterimage_motion": float(afterimage_material.get_shader_parameter("motion_strength"))
			if afterimage_material != null else 0.0,
		"artifact_shadow_lift": float(artifact_material.get_shader_parameter("shadow_lift"))
			if artifact_material != null else 0.0,
		"artifact_exposure": float(artifact_material.get_shader_parameter("exposure"))
			if artifact_material != null else 1.0,
		"artifact_extent": _sprite_extent(_artifact),
		"afterimage_extent": _sprite_extent(_afterimage),
		"light_enabled": _memory_light.enabled and _memory_light.energy > 0.001,
		"light_energy": _memory_light.energy,
		"light_radius": _light_radius,
		"light_color": _memory_light.color,
		"reduced_effects": _reduced_effects,
		"spent": _stage == Stage.SPENT,
		"disposition": ArchiveSystem.get_disposition(echo_data.id)
			if echo_data != null and ArchiveSystem.has_echo(echo_data.id) else &"",
	}


func get_scanner_feedback(origin: Vector2) -> Dictionary:
	return {
		"bearing": _bearing_text(origin),
		"distance": roundi(origin.distance_to(global_position)),
		"noise": _signal_profile(),
		"stage": get_trace_stage(),
	}


func _on_scanned(origin: Vector2) -> void:
	if _stage == Stage.SPENT:
		return
	if _requires_upgrade():
		_show_blocked_signal()
		return
	match _stage:
		Stage.HIDDEN:
			detect_from(origin)
		Stage.DETECTED:
			_last_scan_origin = origin
			if origin.distance_to(global_position) <= focus_scan_distance:
				focus_trace(origin)
			else:
				EventBus.notice_posted.emit(
					"Signal found, but it is too weak here.\n%s\nMove closer and sweep again."
					% _bearing_text(origin))
		Stage.FOCUSED:
			_last_scan_origin = origin
			reveal_trace()
		Stage.REVEALED:
			_last_scan_origin = origin
			_overlay.present_reveal(echo_data, _bearing_text(origin))


func _apply_authored_artifact() -> void:
	var artifact_texture := echo_data.artifact_texture if echo_data != null else null
	var afterimage_texture := echo_data.afterimage_texture if echo_data != null else null
	_artifact.texture = artifact_texture
	_edge_light.texture = artifact_texture
	_afterimage.texture = afterimage_texture if afterimage_texture != null else artifact_texture
	_fit_sprite(_artifact, artifact_max_extent)
	_edge_light.scale = _artifact.scale * 1.035
	var has_authored_afterimage := afterimage_texture != null
	_fit_sprite(
		_afterimage,
		authored_afterimage_max_extent if has_authored_afterimage else artifact_max_extent * 1.08,
	)
	_afterimage_rest_position = Vector2(4.0, -18.0) if has_authored_afterimage else Vector2(5.0, -3.0)
	_afterimage.position = _afterimage_rest_position
	var material := _afterimage.material as ShaderMaterial
	if material != null:
		material.set_shader_parameter("trace_tone", _evidence_light_color())


func _fit_sprite(sprite: Sprite2D, max_extent: float) -> void:
	if sprite.texture == null:
		sprite.visible = false
		return
	var size := sprite.texture.get_size()
	var largest := maxf(size.x, size.y)
	var scale_factor := max_extent / largest if largest > 0.0 else 1.0
	sprite.scale = Vector2.ONE * scale_factor


func _sprite_extent(sprite: Sprite2D) -> float:
	if sprite.texture == null:
		return 0.0
	var size := sprite.texture.get_size() * sprite.scale.abs()
	return maxf(size.x, size.y)


func _apply_stage_visual(animated: bool) -> void:
	_stop_idle_tween()
	_artifact.visible = _artifact.texture != null
	_edge_light.visible = _edge_light.texture != null and _stage != Stage.HIDDEN
	_afterimage.visible = _afterimage.texture != null and _stage == Stage.REVEALED
	_signal_dust.visible = not _reduced_effects and _stage in [Stage.FOCUSED, Stage.REVEALED]
	_recovery_burst.visible = false

	var artifact_color := Color(0.66, 0.64, 0.57, hidden_alpha)
	var edge_color := Color(0.55, 0.76, 0.69, 0.0)
	var afterimage_color := Color(0.55, 0.72, 0.66, 0.0)
	var dust_color := Color(0.55, 0.72, 0.65, 0.0)
	var light_energy := 0.0
	var light_radius := 0.0
	var afterimage_alignment := 0.0
	var artifact_shadow_lift := 0.04
	var artifact_exposure := 0.72
	match _stage:
		Stage.DETECTED:
			artifact_color = Color(1.0, 0.96, 0.86, 0.95)
			edge_color = Color(0.72, 0.82, 0.72, 0.28)
			light_energy = 0.65
			light_radius = 68.0
			artifact_shadow_lift = 0.52
			artifact_exposure = 1.58
		Stage.FOCUSED:
			artifact_color = Color(1.0, 0.98, 0.9, 1.0)
			edge_color = Color(0.72, 0.84, 0.74, 0.38)
			dust_color = Color(0.62, 0.78, 0.68, 0.16)
			light_energy = 1.02
			light_radius = 108.0
			afterimage_alignment = 0.38
			artifact_shadow_lift = 0.64
			artifact_exposure = 1.78
		Stage.REVEALED:
			artifact_color = Color(1.0, 0.98, 0.9, 1.0)
			edge_color = Color(0.72, 0.84, 0.74, 0.30)
			afterimage_color = Color(0.92, 0.94, 0.88, 0.86)
			dust_color = Color(0.62, 0.78, 0.68, 0.20)
			light_energy = 1.38
			light_radius = 142.0
			afterimage_alignment = 0.92
			artifact_shadow_lift = 0.68
			artifact_exposure = 1.74
		Stage.SPENT:
			artifact_color = Color(0.58, 0.56, 0.49, 0.74)
			edge_color = Color(0.46, 0.53, 0.47, 0.045)
			afterimage_alignment = 1.0
			artifact_shadow_lift = 0.08
			artifact_exposure = 0.78

	if _reduced_effects:
		light_energy *= 0.68
		light_radius *= 0.82
	_configure_memory_light(light_energy, light_radius, animated)
	_configure_afterimage(afterimage_alignment)
	_configure_artifact_material(artifact_shadow_lift, artifact_exposure)

	if not animated:
		_artifact.modulate = artifact_color
		_edge_light.modulate = edge_color
		_afterimage.modulate = afterimage_color
		_signal_dust.modulate = dust_color
		return
	if _stage == Stage.REVEALED and _afterimage.visible and _afterimage.modulate.a <= 0.0:
		# Give the aligned layer a readable first frame before its restrained
		# fade reaches the authored target opacity.
		_afterimage.modulate.a = 0.035
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_artifact, "modulate", artifact_color, 0.24)
	tween.tween_property(_edge_light, "modulate", edge_color, 0.24)
	tween.tween_property(_afterimage, "modulate", afterimage_color, 0.34)
	tween.tween_property(_signal_dust, "modulate", dust_color, 0.34)
	if _stage == Stage.REVEALED:
		_afterimage.position = _afterimage_rest_position + Vector2(9.0, -5.0)
		tween.tween_property(_afterimage, "position", _afterimage_rest_position, 0.42)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if _stage == Stage.SPENT:
		_play_spent_burst()
	elif _stage in [Stage.DETECTED, Stage.FOCUSED, Stage.REVEALED]:
		_idle_tween = create_tween().set_loops()
		_idle_tween.tween_property(_edge_light, "modulate:a", edge_color.a * 0.62, 0.9)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_idle_tween.tween_property(_edge_light, "modulate:a", edge_color.a, 0.9)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _play_spent_burst() -> void:
	if _reduced_effects:
		return
	_recovery_burst.visible = true
	_recovery_burst.modulate = Color(0.68, 0.7, 0.55, 0.22)
	_recovery_burst.scale = Vector2(0.075, 0.075)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_recovery_burst, "scale", Vector2(0.13, 0.13), 0.42)
	tween.tween_property(_recovery_burst, "modulate:a", 0.0, 0.46)
	tween.chain().tween_callback(func() -> void: _recovery_burst.visible = false)


func _stop_idle_tween() -> void:
	if _idle_tween != null and _idle_tween.is_valid():
		_idle_tween.kill()
	_idle_tween = null


func _configure_memory_light(energy: float, radius: float, animated: bool) -> void:
	if _light_tween != null and _light_tween.is_valid():
		_light_tween.kill()
	_light_tween = null
	_light_radius = radius
	_memory_light.color = _evidence_light_color()
	_memory_light.texture_scale = maxf(radius * 2.0 / 192.0, 0.05)
	_memory_light.height = maxf(radius * 0.68, 42.0)
	_memory_light.set_meta("day_night_base_energy", energy)
	if not _memory_light.is_in_group("day_night_practical"):
		_memory_light.add_to_group("day_night_practical")
	if not animated:
		_memory_light.enabled = energy > 0.001
		_memory_light.energy = energy
		return
	var start_energy := _memory_light.energy
	_memory_light.enabled = energy > 0.001 or start_energy > 0.001
	if energy > start_energy and start_energy <= 0.001:
		_memory_light.energy = minf(energy * 0.28, 0.08)
	_light_tween = create_tween().set_parallel(true)
	_light_tween.tween_property(_memory_light, "energy", energy, 0.3)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if energy <= 0.001:
		_light_tween.finished.connect(func() -> void: _memory_light.enabled = false)


func _configure_afterimage(alignment: float) -> void:
	var material := _afterimage.material as ShaderMaterial
	if material == null:
		return
	material.set_shader_parameter("alignment", alignment)
	material.set_shader_parameter("motion_strength", 0.0 if _reduced_effects else 1.0)
	material.set_shader_parameter("trace_tone", _evidence_light_color())


func _configure_artifact_material(shadow_lift: float, exposure: float) -> void:
	var material := _artifact.material as ShaderMaterial
	if material == null:
		return
	material.set_shader_parameter("shadow_lift", shadow_lift)
	material.set_shader_parameter("exposure", exposure)


func _evidence_light_color() -> Color:
	if echo_data == null:
		return Color(0.54, 0.74, 0.66)
	match echo_data.evidence_class:
		"witness":
			return Color(0.52, 0.74, 0.66)
		"system":
			return Color(0.45, 0.66, 0.74)
	return Color(0.69, 0.78, 0.58)


func _on_setting_changed(section: String, key: String, value: Variant) -> void:
	if section != "accessibility" or key != "reduced_effects":
		return
	_reduced_effects = bool(value)
	_apply_stage_visual(false)


func _requires_upgrade() -> bool:
	return required_upgrade_id != &"" and not BaseUpgradeSystem.is_built(required_upgrade_id)


func _show_blocked_signal() -> void:
	AudioManager.play(&"weak_signal", -5.0, 0.78)
	EventBus.notice_posted.emit(required_upgrade_notice)
	EventBus.camera_shake_requested.emit(0.8, 0.05)
	if _blocked_pulse:
		return
	_blocked_pulse = true
	var tween := create_tween()
	tween.tween_property(_artifact, "modulate:a", 0.18, 0.1)
	tween.tween_property(_artifact, "modulate:a", hidden_alpha, 0.28)
	tween.tween_callback(func() -> void: _blocked_pulse = false)


func _bearing_text(origin: Vector2) -> String:
	if origin == Vector2.INF:
		return "NEEDLE -- / RANGE --"
	var offset := global_position - origin
	if offset.is_zero_approx():
		return "NEEDLE HERE / RANGE 000"
	var degrees := fposmod(rad_to_deg(atan2(offset.x, -offset.y)), 360.0)
	var names := ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
	var index := int(round(degrees / 45.0)) % names.size()
	return "NEEDLE %s / %03d DEG / RANGE %03d" % [
		names[index], roundi(degrees), roundi(offset.length())]


func _artifact_name() -> String:
	return echo_data.artifact_name if echo_data != null else "unlabelled object"


func _signal_profile() -> String:
	return echo_data.signal_profile if echo_data != null else "broadband residue"
