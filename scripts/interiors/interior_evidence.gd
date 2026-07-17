class_name InteriorEvidence
extends Interactable
## Physical evidence that can be read normally and cross-checked by Receiver.

@export var evidence_id: StringName = &""
@export var title: String = "FIELD EVIDENCE"
@export_multiline var observation: String = ""
@export_multiline var carrier_reading: String = ""
@export var scan_radius := 270.0

var _scanned := false
var _dialogue_open := false


func _ready() -> void:
	EventBus.scanner_pulsed.connect(_on_scanner_pulsed)
	EventBus.dialogue_finished.connect(_on_dialogue_finished)
	_scanned = WorldState.has_flag(_scan_flag())


func _exit_tree() -> void:
	if _dialogue_open:
		_dialogue_open = false
		GameManager.set_dialogue_active(false)


func get_prompt() -> String:
	return prompt if not WorldState.has_flag(_read_flag()) else "Review the evidence"


func interact(_player: Node2D) -> void:
	WorldState.set_flag(_read_flag())
	_dialogue_open = true
	GameManager.set_dialogue_active(true)
	var lines: Array[String] = [observation]
	if _scanned and not carrier_reading.is_empty():
		lines.append("RECEIVER CROSS-CHECK — %s" % carrier_reading)
	else:
		lines.append("The physical record is clear. A Receiver cross-check may show what the paper cannot.")
	EventBus.dialogue_requested.emit({
		"id": _story_id(),
		"title": title,
		"lines": lines,
		"choices": [],
		"accent": Color(0.88, 0.67, 0.32, 1.0),
	})


func _on_dialogue_finished(story_id: StringName, _choice_index: int) -> void:
	if not _dialogue_open or story_id != _story_id():
		return
	_dialogue_open = false
	GameManager.set_dialogue_active(false)
	if get_tree().get_first_node_in_group("main") != null:
		SaveManager.save_game("")


func _on_scanner_pulsed(origin: Vector2, radius: float) -> void:
	if _scanned or global_position.distance_to(origin) > minf(radius, scan_radius):
		return
	_scanned = true
	WorldState.set_flag(_scan_flag())
	EventBus.scannable_pinged.emit(global_position)
	AudioManager.play(&"echo_reveal", -5.0, 0.78)
	EventBus.notice_posted.emit(
		"Receiver cross-check added to %s." % title.to_lower())
	var visual := get_node_or_null("Visual") as Node2D
	if visual != null:
		var resting_scale := visual.scale
		var tween := create_tween().set_parallel(true)
		tween.tween_property(visual, "modulate", Color(0.72, 0.94, 0.88, 1.0), 0.18)
		tween.tween_property(visual, "scale", resting_scale * 1.08, 0.18)
		tween.chain().tween_property(visual, "scale", resting_scale, 0.22)


func _read_flag() -> StringName:
	return StringName("evidence_read_%s" % String(evidence_id))


func _scan_flag() -> StringName:
	return StringName("evidence_scanned_%s" % String(evidence_id))


func _story_id() -> StringName:
	return StringName("evidence_%s" % String(evidence_id))
