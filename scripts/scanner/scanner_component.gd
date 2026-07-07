class_name ScannerComponent
extends Node2D
## The Mnemoscope -- the player's memory scanner.

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


func _ready() -> void:
	_energy = max_energy
	EventBus.scanner_energy_changed.emit(_energy, max_energy)


func _process(delta: float) -> void:
	if _energy < max_energy:
		_energy = minf(_energy + recharge_rate * delta, max_energy)
		EventBus.scanner_energy_changed.emit(_energy, max_energy)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("scan"):
		_try_pulse()


func _try_pulse() -> void:
	if _energy < energy_cost:
		EventBus.notice_posted.emit("The Mnemoscope needs to recharge.")
		return
	var found := _has_scannable_in_range()
	_energy -= energy_cost
	EventBus.scanner_energy_changed.emit(_energy, max_energy)
	_spawn_pulse_visual()
	if found:
		EventBus.notice_posted.emit("Mnemoscope pulse found a signal. Follow the cyan shimmer.")
	else:
		EventBus.notice_posted.emit("Mnemoscope pulse fades. No echo nearby.")
	EventBus.scanner_pulsed.emit(global_position, pulse_radius)


func _spawn_pulse_visual() -> void:
	if pulse_scene == null:
		return
	var pulse := pulse_scene.instantiate()
	get_tree().current_scene.add_child(pulse)
	pulse.global_position = global_position
	if pulse.has_method("start"):
		pulse.start(pulse_radius)


func _has_scannable_in_range() -> bool:
	for node in get_tree().get_nodes_in_group("scannables"):
		if node is Node2D and global_position.distance_to((node as Node2D).global_position) <= pulse_radius:
			return true
	return false
