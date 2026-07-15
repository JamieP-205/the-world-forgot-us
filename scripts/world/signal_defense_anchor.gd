class_name SignalDefenseAnchor
extends CampaignInteractable
## Authored hold-the-line encounter. Dialogue starts it; waves are local,
## persistent enemies and completion is reported back to CampaignSystem.

const LEECH_SCENE := preload("res://scenes/enemies/enemy_signal_leech.tscn")
const STALKER_SCENE := preload("res://scenes/enemies/enemy_mimic_stalker.tscn")
const HOLLOW_SCENE := preload("res://scenes/enemies/enemy_hollow.tscn")

@export var task_id: StringName = &"east_relay_defense"
@export var started_flag: StringName = &"east_relay_defense_started"
@export var completed_flag: StringName = &"east_relay_defense_complete"
@export var seconds_between_waves: float = 2.4

var _active_wave: Array[Node] = []
var _wave_index := 0
var _between_time := 0.0
var _running := false


func _ready() -> void:
	super()
	add_to_group("defense_anchors")
	if story_id == &"":
		story_id = &"broadcast_defense_anchor"
	if WorldState.has_flag(started_flag) and not WorldState.has_flag(completed_flag):
		_begin_defense()


func _process(delta: float) -> void:
	super(delta)
	if not _running and WorldState.has_flag(started_flag) and not WorldState.has_flag(completed_flag):
		_begin_defense()
	if not _running:
		return
	_active_wave = _active_wave.filter(func(enemy: Node) -> bool: return is_instance_valid(enemy) and not enemy.is_queued_for_deletion())
	if not _active_wave.is_empty():
		return
	_between_time -= delta
	if _between_time > 0.0:
		return
	if _wave_index >= _total_waves():
		_running = false
		CampaignSystem.report_field_task(task_id)
		return
	_spawn_wave(_wave_index)
	_wave_index += 1
	_between_time = seconds_between_waves


func _begin_defense() -> void:
	_running = true
	_wave_index = 0
	_between_time = 0.35
	_active_wave.clear()
	EventBus.notice_posted.emit("EAST LINE HOLD - keep the clinic carrier alive through the surge.")


func _total_waves() -> int:
	# Rafi can physically join the field operation if the player asked him to.
	return 2 if WorldState.has_flag(&"rafi_field_defense") else 3


func _spawn_wave(index: int) -> void:
	var markers := $SpawnMarkers.get_children()
	if markers.is_empty():
		push_warning("SignalDefenseAnchor has no SpawnMarkers children.")
		CampaignSystem.report_field_task(task_id)
		_running = false
		return
	var pattern: Array[PackedScene]
	match index:
		0: pattern = [STALKER_SCENE, HOLLOW_SCENE]
		1: pattern = [LEECH_SCENE, STALKER_SCENE]
		_: pattern = [LEECH_SCENE, STALKER_SCENE, HOLLOW_SCENE]
	for slot in pattern.size():
		var packed := pattern[slot]
		var enemy := packed.instantiate()
		enemy.name = "EastDefense_%d_%d" % [index + 1, slot + 1]
		enemy.set("persistent_id", StringName(enemy.name))
		get_parent().add_child(enemy)
		var marker := markers[slot % markers.size()] as Node2D
		enemy.global_position = marker.global_position
		_active_wave.append(enemy)
	AudioManager.play(&"weak_signal", 0.0, 0.75 + index * 0.12)
	EventBus.notice_posted.emit("Carrier surge %d / %d incoming." % [index + 1, _total_waves()])
