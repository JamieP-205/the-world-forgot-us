class_name ScannerComponent
extends Node2D
## The trace receiver -- a fault-finding set rebuilt into a field scanner.

## How far the pulse reaches, in pixels.
@export var pulse_radius: float = 220.0

## Energy spent per pulse.
@export var energy_cost: float = 34.0

## Full energy pool.
@export var max_energy: float = 100.0

## Energy recovered per second.
@export var recharge_rate: float = 18.0

## Visual ring spawned on each pulse (cosmetic; frees itself).
@export var pulse_scene: PackedScene

var _energy: float
var _base_radius: float
var _base_recharge: float
var _coil := false


func _ready() -> void:
	_base_radius = pulse_radius
	_base_recharge = recharge_rate
	_apply_upgrades()
	_energy = max_energy
	EventBus.scanner_energy_changed.emit(_energy, max_energy)
	BaseUpgradeSystem.upgrade_built.connect(_on_upgrade_built)


## Applies the Scanner Coil upgrade (wider pulse, faster recharge) if built.
func _apply_upgrades() -> void:
	if _coil:
		return
	if BaseUpgradeSystem.is_built(&"scanner_coil"):
		_coil = true
		pulse_radius = _base_radius * 1.35
		recharge_rate = _base_recharge * 1.5


func _on_upgrade_built(data) -> void:
	if data != null and data.id == &"scanner_coil" and not _coil:
		_apply_upgrades()
		EventBus.notice_posted.emit(
			"Search coil fitted. The receiver reaches farther and cools faster.")


func _process(delta: float) -> void:
	if _energy < max_energy:
		var recharge_multiplier := CraftedItemEffects.get_receiver_recharge_multiplier()
		_energy = minf(_energy + recharge_rate * recharge_multiplier * delta, max_energy)
		EventBus.scanner_energy_changed.emit(_energy, max_energy)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("scan"):
		_try_pulse()


func _try_pulse() -> void:
	var effective_cost := energy_cost * CraftedItemEffects.get_receiver_energy_cost_multiplier() \
		* CampaignSystem.get_gameplay_value(&"scanner_energy")
	if _energy < effective_cost:
		EventBus.notice_posted.emit("The receiver coil is still cooling.")
		return
	var target := _nearest_scannable_in_range()
	var found := target != null
	_energy -= effective_cost
	EventBus.scanner_energy_changed.emit(_energy, max_energy)
	_spawn_pulse_visual()
	if found:
		var feedback_source := target
		if not feedback_source.has_method("get_scanner_feedback") and target.get_parent() != null:
			feedback_source = target.get_parent()
		if feedback_source.has_method("get_scanner_feedback"):
			var feedback: Dictionary = feedback_source.call("get_scanner_feedback", global_position)
			EventBus.notice_posted.emit(
				"RECEIVER CONTACT   %s\nNOISE   %s"
				% [feedback.get("bearing", "NEEDLE --"), feedback.get("noise", "unresolved carrier")])
		else:
			EventBus.notice_posted.emit("The receiver catches movement inside the sweep.")
	else:
		EventBus.notice_posted.emit("The sweep comes back clean.")
	EventBus.scanner_pulsed.emit(global_position, _effective_radius())


func _spawn_pulse_visual() -> void:
	if pulse_scene == null:
		return
	var pulse := pulse_scene.instantiate()
	get_tree().current_scene.add_child(pulse)
	pulse.global_position = global_position
	if pulse.has_method("start"):
		pulse.start(_effective_radius())


func _has_scannable_in_range() -> bool:
	return _nearest_scannable_in_range() != null


func _nearest_scannable_in_range() -> Node2D:
	var nearest_trace: Node2D
	var nearest_other: Node2D
	var trace_distance := INF
	var other_distance := INF
	for node in get_tree().get_nodes_in_group("scannables"):
		if not node is Node2D:
			continue
		var candidate := node as Node2D
		var distance := global_position.distance_to(candidate.global_position)
		if distance > _effective_radius():
			continue
		var feedback_source := candidate
		if not feedback_source.has_method("get_scanner_feedback") and candidate.get_parent() != null:
			feedback_source = candidate.get_parent()
		if feedback_source.has_method("get_scanner_feedback"):
			if distance < trace_distance:
				trace_distance = distance
				nearest_trace = candidate
		elif distance < other_distance:
			other_distance = distance
			nearest_other = candidate
	return nearest_trace if nearest_trace != null else nearest_other


func _effective_radius() -> float:
	return pulse_radius * CampaignSystem.get_gameplay_value(&"scan_range")
