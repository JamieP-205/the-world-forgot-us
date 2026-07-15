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

## Health restored by field supplies (F). Rations cover smaller wounds; the
## rarer clinic kit is kept for serious injuries when both are available.
@export var food_heal: float = 45.0
@export var medical_kit_heal: float = 75.0

## Fast evasive step with brief invulnerability.
@export var dodge_speed: float = 560.0
@export var dodge_duration: float = 0.18
@export var dodge_cooldown: float = 0.85

## Unlockable scanner-combat ability learned from Mara's recording.
@export var burst_radius: float = 155.0
@export var burst_damage: float = 24.0
@export var burst_cooldown: float = 7.0

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
var _dodge_time: float = 0.0
var _dodge_cd: float = 0.0
var _dodge_dir: Vector2 = Vector2.DOWN
var _burst_cd: float = 0.0
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
	_dodge_time = maxf(_dodge_time - delta, 0.0)
	_dodge_cd = maxf(_dodge_cd - delta, 0.0)
	_burst_cd = maxf(_burst_cd - delta, 0.0)
	_anim_lock = maxf(_anim_lock - delta, 0.0)
	_update_camera_shake(delta)
	_handle_movement(delta)
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
	if GameManager.is_input_locked():
		return
	if event.is_action_pressed("dodge"):
		_try_dodge()
	elif event.is_action_pressed("memory_burst"):
		_try_memory_burst()
	elif event.is_action_pressed("interact") and _current_interactable != null:
		_current_interactable.interact(self)
		# The interactable may have changed state, so refresh immediately.
		_update_current_interactable()
	elif event.is_action_pressed("attack"):
		_try_attack()
	elif event.is_action_pressed("consume"):
		_try_consume_healing()


## Uses one healing supply. A ration handles a wound it can cover; otherwise a
## first-aid kit takes priority so a badly hurt player gets the larger heal.
func _try_consume_healing() -> void:
	if _health.current_health >= _health.max_health:
		EventBus.notice_posted.emit("Already at full health. No supplies used.")
		return
	var has_food := InventorySystem.get_count(&"canned_food") > 0
	var has_kit := InventorySystem.get_count(&"medical_kit") > 0
	if not has_food and not has_kit:
		EventBus.notice_posted.emit("No healing supplies. Search cupboards and clinic stores.")
		return

	var missing_health := _health.max_health - _health.current_health
	if has_kit and (not has_food or missing_health > food_heal):
		_use_medical_kit()
	else:
		_use_ration()


## Kept as a compatibility shim for old smoke scripts that called the former
## private helper directly.
func _try_consume_food() -> void:
	_try_consume_healing()


func _use_medical_kit() -> void:
	if not InventorySystem.remove_item(&"medical_kit", 1):
		return
	var before := _health.current_health
	_health.heal(medical_kit_heal)
	var restored := roundi(_health.current_health - before)
	AudioManager.play(&"pickup", -4.0, 0.82)
	EventBus.notice_posted.emit(
		"You clean and dress the wound with a clinic first-aid kit. +%d health." % restored)


func _use_ration() -> void:
	if not InventorySystem.remove_item(&"canned_food", 1):
		return
	var before := _health.current_health
	_health.heal(food_heal)
	var restored := roundi(_health.current_health - before)
	AudioManager.play(&"eat")
	EventBus.notice_posted.emit("You force down a cold ration. +%d health." % restored)


func _handle_movement(_delta: float) -> void:
	if _dodge_time > 0.0:
		velocity = _dodge_dir * dodge_speed
		move_and_slide()
		_update_locomotion(true)
		return
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
	if _attack_cd > 0.0 or _dodge_time > 0.0:
		return
	_attack_cd = attack_cooldown
	AudioManager.play(&"swing", -3.0, randf_range(0.94, 1.06))
	_swing_visual.visible = true
	_swing_timer.start()
	_play_action(StringName("attack_" + _facing_dir()), 0.28)
	# Hit everything the hitbox currently overlaps that knows how to be hurt.
	for body in _attack_area.get_overlapping_bodies():
		if body.has_method("take_damage"):
			body.take_damage(attack_damage)


func _try_dodge() -> void:
	if _dodge_cd > 0.0 or _dodge_time > 0.0:
		return
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	_dodge_dir = input_dir.normalized() if input_dir != Vector2.ZERO else facing.normalized()
	if _dodge_dir == Vector2.ZERO:
		_dodge_dir = Vector2.DOWN
	facing = _dodge_dir
	_dodge_time = dodge_duration
	_dodge_cd = dodge_cooldown
	_invuln = maxf(_invuln, dodge_duration + 0.08)
	_anim_lock = dodge_duration
	AudioManager.play(&"dodge", -1.0, randf_range(0.96, 1.04))
	_spawn_motion_echo()
	EventBus.camera_shake_requested.emit(0.8, 0.08)


func _try_memory_burst() -> void:
	if not WorldState.has_flag(&"memory_burst_unlocked"):
		EventBus.notice_posted.emit("The receiver cannot discharge safely yet. Find Maggie's bench at Ashmere.")
		return
	if _burst_cd > 0.0:
		EventBus.notice_posted.emit("Receiver discharge recharging: %.1fs" % _burst_cd)
		return
	_burst_cd = burst_cooldown
	AudioManager.play(&"memory_burst")
	EventBus.signal_burst_used.emit(global_position, burst_radius)
	EventBus.camera_shake_requested.emit(3.0, 0.2)
	_spawn_burst_visual()
	var hits := 0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy is Node2D:
			continue
		if global_position.distance_to((enemy as Node2D).global_position) > burst_radius:
			continue
		if enemy.has_method("on_signal_burst"):
			enemy.on_signal_burst(global_position, burst_radius)
		if enemy.has_method("take_damage"):
			enemy.take_damage(burst_damage)
			hits += 1
	EventBus.notice_posted.emit(
		"Receiver discharge overloads %d signal%s." % [hits, "" if hits == 1 else "s"]
	)


func _spawn_motion_echo() -> void:
	if _visual.sprite_frames == null:
		return
	var texture := _visual.sprite_frames.get_frame_texture(_visual.animation, _visual.frame)
	if texture == null:
		return
	var echo := Sprite2D.new()
	echo.texture = texture
	echo.global_position = global_position + _visual.position
	echo.scale = _visual.scale
	echo.modulate = Color(0.42, 0.92, 0.96, 0.48)
	echo.z_index = -1
	get_parent().add_child(echo)
	var tween := echo.create_tween().set_parallel(true)
	tween.tween_property(echo, "global_position", echo.global_position - _dodge_dir * 34.0, 0.24)
	tween.tween_property(echo, "modulate:a", 0.0, 0.24)
	tween.tween_property(echo, "scale", echo.scale * 0.82, 0.24)
	tween.chain().tween_callback(echo.queue_free)


func _spawn_burst_visual() -> void:
	var ring := Line2D.new()
	ring.name = "MemoryBurstRing"
	ring.width = 5.0
	ring.default_color = Color(0.38, 0.92, 0.96, 0.92)
	ring.closed = true
	for i in 49:
		var angle := TAU * float(i) / 48.0
		ring.add_point(Vector2.from_angle(angle) * 22.0)
	add_child(ring)
	ring.scale = Vector2(0.25, 0.25)
	var target_scale := Vector2.ONE * (burst_radius / 22.0)
	var tween := ring.create_tween().set_parallel(true)
	tween.tween_property(ring, "scale", target_scale, 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(ring, "modulate:a", 0.0, 0.42)
	tween.chain().tween_callback(ring.queue_free)


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


func get_dodge_cooldown_ratio() -> float:
	return _dodge_cd / maxf(dodge_cooldown, 0.001)


func get_burst_cooldown_ratio() -> float:
	return _burst_cd / maxf(burst_cooldown, 0.001)


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
