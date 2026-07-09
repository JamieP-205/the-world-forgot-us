class_name Player
extends CharacterBody2D
## Top-down player controller.
##
## Handles WASD movement, facing direction, interaction with nearby
## Interactables, and a simple directional melee attack. Health lives in a
## child HealthComponent; enemies damage the player through take_damage().

## Movement speed in pixels per second.
@export var move_speed: float = 220.0

## Damage dealt per melee swing.
@export var attack_damage: float = 34.0

## Minimum seconds between swings.
@export var attack_cooldown: float = 0.35

## How far in front of the player the melee hitbox sits.
@export var attack_offset: float = 24.0

## Seconds of invulnerability after taking a hit (stops instant multi-hits).
@export var hurt_invuln_time: float = 0.5

## The direction the player is currently facing. Drives the melee swing and,
## later, the scanner cone and thrown items.
var facing: Vector2 = Vector2.DOWN

## All interactables currently inside the interaction area.
var _nearby_interactables: Array[Interactable] = []

## The interactable the player would use if they pressed "interact" now.
var _current_interactable: Interactable = null

## Last prompt string sent to the HUD (so we only emit on change).
var _last_prompt: String = ""

var _attack_cd: float = 0.0
var _invuln: float = 0.0
var _shake_time: float = 0.0
var _shake_duration: float = 0.0
var _shake_strength: float = 0.0

## Seconds during which a one-shot animation (attack/hurt) keeps priority over
## the idle/walk locomotion animation. Purely visual.
var _anim_lock: float = 0.0

@onready var _visual: AnimatedSprite2D = $Visual
@onready var _facing_indicator: Polygon2D = $FacingIndicator
@onready var _interaction_area: Area2D = $InteractionArea
@onready var _health: HealthComponent = $HealthComponent
@onready var _attack_area: Area2D = $AttackArea
@onready var _swing_visual: Polygon2D = $SwingVisual
@onready var _swing_timer: Timer = $SwingTimer
@onready var _camera: Camera2D = $Camera2D


func _ready() -> void:
	add_to_group("player")
	_interaction_area.area_entered.connect(_on_interactable_entered)
	_interaction_area.area_exited.connect(_on_interactable_exited)
	_facing_indicator.rotation = facing.angle()

	_health.health_changed.connect(_on_health_changed)
	_health.died.connect(_on_died)
	EventBus.camera_shake_requested.connect(_on_camera_shake_requested)
	_swing_timer.timeout.connect(func() -> void: _swing_visual.visible = false)
	_swing_visual.visible = false
	_visual.play(&"idle_down")

	# Push the starting health to the HUD now that listeners are wired up.
	EventBus.player_health_changed.emit(_health.current_health, _health.max_health)


func _physics_process(delta: float) -> void:
	_attack_cd = maxf(_attack_cd - delta, 0.0)
	_invuln = maxf(_invuln - delta, 0.0)
	_anim_lock = maxf(_anim_lock - delta, 0.0)
	_update_camera_shake(delta)
	_handle_movement()
	_update_attack_transform()
	_update_current_interactable()


## Maps the continuous facing vector to one of the four sprite directions.
func _facing_dir() -> String:
	if absf(facing.x) > absf(facing.y):
		return "right" if facing.x > 0.0 else "left"
	return "down" if facing.y >= 0.0 else "up"


## Plays a one-shot animation (attack/hurt) and holds it for `lock` seconds so
## locomotion doesn't immediately override it. Guards against missing anims.
func _play_action(anim: StringName, lock: float) -> void:
	if _visual.sprite_frames != null and _visual.sprite_frames.has_animation(anim):
		_visual.play(anim)
		_anim_lock = lock


## Chooses idle vs walk for the current facing, unless a one-shot is playing.
func _update_locomotion(moving: bool) -> void:
	if _anim_lock > 0.0:
		return
	var want := StringName(("walk_" if moving else "idle_") + _facing_dir())
	if _visual.animation != want or not _visual.is_playing():
		_visual.play(want)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and _current_interactable != null:
		_current_interactable.interact(self)
		# The interactable may have changed state, so refresh immediately.
		_update_current_interactable()
	elif event.is_action_pressed("attack"):
		_try_attack()


func _handle_movement() -> void:
	var input_dir: Vector2 = Input.get_vector(
		"move_left", "move_right", "move_up", "move_down"
	)
	velocity = input_dir * move_speed
	move_and_slide()

	if input_dir != Vector2.ZERO:
		facing = input_dir.normalized()
		_facing_indicator.rotation = facing.angle()
	_update_locomotion(input_dir != Vector2.ZERO)


# --- Combat -----------------------------------------------------------------

## Keeps the melee hitbox and swing arc pinned in front of the player so
## they always match the current facing direction.
func _update_attack_transform() -> void:
	var offset := facing * attack_offset
	_attack_area.position = offset
	_swing_visual.position = offset
	_swing_visual.rotation = facing.angle()


func _try_attack() -> void:
	if _attack_cd > 0.0:
		return
	_attack_cd = attack_cooldown
	_swing_visual.visible = true
	_swing_timer.start()
	_play_action(StringName("attack_" + _facing_dir()), 0.28)
	# Hit everything the hitbox currently overlaps that knows how to be hurt.
	for body in _attack_area.get_overlapping_bodies():
		if body.has_method("take_damage"):
			body.take_damage(attack_damage)


## Damage entry point so attackers never touch the HealthComponent directly.
func take_damage(amount: float) -> void:
	if _invuln > 0.0 or not _health.is_alive():
		return
	_health.take_damage(amount)
	_invuln = hurt_invuln_time
	_flash_hurt()
	_play_action(StringName("hurt_" + _facing_dir()), 0.24)


func _flash_hurt() -> void:
	_visual.modulate = Color(1.0, 0.4, 0.4)
	var tween := create_tween()
	tween.tween_property(_visual, "modulate", Color(1, 1, 1), 0.3)


func _on_camera_shake_requested(strength: float, duration: float) -> void:
	_shake_strength = maxf(_shake_strength, strength)
	_shake_duration = maxf(_shake_duration, duration)
	_shake_time = _shake_duration


func _update_camera_shake(delta: float) -> void:
	if _shake_time <= 0.0:
		_camera.offset = Vector2.ZERO
		return
	_shake_time = maxf(_shake_time - delta, 0.0)
	var t := _shake_time / maxf(_shake_duration, 0.001)
	var jitter := Vector2(
		sin(Time.get_ticks_msec() * 0.071),
		cos(Time.get_ticks_msec() * 0.083)
	)
	_camera.offset = jitter * _shake_strength * t


func _on_health_changed(current: float, maximum: float) -> void:
	EventBus.player_health_changed.emit(current, maximum)


func _on_died() -> void:
	EventBus.player_died.emit()
	# "Wake at the base": heal to full here; GameManager handles the trip
	# home in response to player_died.
	_health.reset()
	_invuln = hurt_invuln_time


func get_health() -> float:
	return _health.current_health


func set_health(amount: float) -> void:
	_health.set_current(amount)


func heal_full() -> void:
	_health.reset()
	_invuln = 0.0


# --- Interaction ------------------------------------------------------------

## Picks the nearest interactable in range and updates the HUD prompt.
## Also prunes freed interactables -- after a level swap the list can hold
## references to nodes that were destroyed without firing area_exited.
func _update_current_interactable() -> void:
	var nearest: Interactable = null
	var nearest_dist: float = INF
	var still_valid: Array[Interactable] = []
	for interactable in _nearby_interactables:
		if not is_instance_valid(interactable):
			continue
		still_valid.append(interactable)
		if not interactable.is_available():
			continue
		var dist := global_position.distance_squared_to(interactable.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = interactable
	_nearby_interactables = still_valid
	_set_current_interactable(nearest)
	_push_prompt()


func _set_current_interactable(next: Interactable) -> void:
	if next == _current_interactable:
		return
	if _current_interactable != null and is_instance_valid(_current_interactable):
		_current_interactable.set_highlighted(false)
	_current_interactable = next
	if _current_interactable != null:
		_current_interactable.set_highlighted(true)


## Sends the interaction prompt to the HUD, but only when it changes.
func _push_prompt() -> void:
	var prompt := ""
	if _current_interactable != null:
		prompt = "[E]  %s" % _current_interactable.get_prompt()
	if prompt != _last_prompt:
		_last_prompt = prompt
		EventBus.interaction_prompt_changed.emit(prompt)


func _on_interactable_entered(area: Area2D) -> void:
	if area is Interactable:
		_nearby_interactables.append(area as Interactable)


func _on_interactable_exited(area: Area2D) -> void:
	if area == _current_interactable:
		_current_interactable.set_highlighted(false)
	_nearby_interactables.erase(area)
