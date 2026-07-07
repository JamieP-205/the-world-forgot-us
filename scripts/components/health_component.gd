class_name HealthComponent
extends Node
## Reusable health pool. Attach as a child of anything that can be hurt --
## the player, enemies, and later destructible props or NPCs -- so the
## damage rules live in exactly one place.

signal health_changed(current: float, maximum: float)
signal died

@export var max_health: float = 100.0

var current_health: float


func _ready() -> void:
	current_health = max_health


func take_damage(amount: float) -> void:
	if amount <= 0.0 or current_health <= 0.0:
		return
	current_health = maxf(current_health - amount, 0.0)
	health_changed.emit(current_health, max_health)
	if current_health <= 0.0:
		died.emit()


func heal(amount: float) -> void:
	if amount <= 0.0 or current_health <= 0.0:
		return
	current_health = minf(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)


func set_current(amount: float) -> void:
	current_health = clampf(amount, 0.0, max_health)
	health_changed.emit(current_health, max_health)


## Restores to full (used on respawn and resting).
func reset() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)


func is_alive() -> bool:
	return current_health > 0.0