class_name EnemyMimicStalker
extends CharacterBody2D
## Mobile ambusher that circles outside melee range, telegraphs a committed
## lunge, then retreats. A receiver sweep exposes it and cancels the ambush.

const NPCServiceRulesScript = preload("res://scripts/narrative/npc_service_rules.gd")

enum State { DORMANT, STALK, WINDUP, LUNGE, RETREAT }

@export var detection_radius: float = 350.0
@export var orbit_radius: float = 132.0
@export var stalk_speed: float = 82.0
@export var lunge_speed: float = 315.0
@export var movement_acceleration: float = 540.0
@export var movement_deceleration: float = 780.0
@export var lunge_acceleration: float = 1900.0
@export_range(0.0, 0.5, 0.01) var facing_hysteresis: float = 0.22
@export var lunge_damage: float = 18.0
@export var lunge_cooldown: float = 3.4
@export var windup_duration: float = 0.72
@export var exposed_duration: float = 4.0
@export var persistent_id: StringName = &""

@onready var _health: HealthComponent = $HealthComponent
@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var _visual: AnimatedSprite2D = $Visual

var _state := State.DORMANT
var _state_time := 0.0
var _attack_cd := 1.2
var _exposed_time := 0.0
var _lunge_direction := Vector2.DOWN
var _hit_this_lunge := false
var _orbit_sign := 1.0
var _face := "down"
var _dying := false
var _anim_lock := 0.0


func _ready() -> void:
	if persistent_id == &"":
		persistent_id = StringName(name)
	if WorldState.is_defeated(persistent_id):
		queue_free()
		return
	add_to_group("enemies")
	add_to_group("scannables")
	_health.died.connect(_on_died)
	EventBus.scanner_pulsed.connect(on_signal_burst)
	_visual.frame_changed.connect(_on_animation_frame_changed)
	DirectionalAnimation.play(_visual, &"idle_down")
	_apply_visibility()


func _physics_process(delta: float) -> void:
	if _dying:
		velocity = Vector2.ZERO
		return
	_state_time += delta
	_attack_cd = maxf(_attack_cd - delta, 0.0)
	_exposed_time = maxf(_exposed_time - delta, 0.0)
	_anim_lock = maxf(_anim_lock - delta, 0.0)
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		velocity = DirectionalAnimation.smooth_velocity(
			velocity, Vector2.ZERO, movement_acceleration, movement_deceleration, delta)
		move_and_slide()
		_update_animation()
		return
	var to_player := player.global_position - global_position
	var distance := to_player.length()
	var night_factor := 1.18 if _is_night() else 1.0
	var target_velocity := Vector2.ZERO
	match _state:
		State.DORMANT:
			if distance <= detection_radius * night_factor:
				_change_state(State.STALK)
		State.STALK:
			var radial := to_player.normalized()
			var tangent := Vector2(-radial.y, radial.x) * _orbit_sign
			var correction := radial * clampf((distance - orbit_radius) / 70.0, -1.0, 1.0)
			target_velocity = (tangent + correction).normalized() * stalk_speed * night_factor
			if _attack_cd <= 0.0 and distance <= orbit_radius + 42.0:
				_lunge_direction = radial
				target_velocity = Vector2.ZERO
				_change_state(State.WINDUP)
		State.WINDUP:
			if _state_time >= get_effective_windup_duration():
				_hit_this_lunge = false
				_change_state(State.LUNGE)
		State.LUNGE:
			target_velocity = _lunge_direction * lunge_speed * night_factor
			if not _hit_this_lunge and distance <= 34.0 and player.has_method("take_damage"):
				player.take_damage(lunge_damage)
				_hit_this_lunge = true
			if _state_time >= 0.48:
				target_velocity = Vector2.ZERO
				_change_state(State.RETREAT)
		State.RETREAT:
			target_velocity = -to_player.normalized() * stalk_speed * 1.35
			if _state_time >= 0.78:
				_attack_cd = lunge_cooldown
				_orbit_sign *= -1.0
				target_velocity = Vector2.ZERO
				_change_state(State.STALK)
	var acceleration := lunge_acceleration if _state == State.LUNGE else movement_acceleration
	velocity = DirectionalAnimation.smooth_velocity(
		velocity, target_velocity, acceleration, movement_deceleration, delta)
	move_and_slide()
	_update_animation()
	_apply_visibility()
	queue_redraw()


func _is_night() -> bool:
	var main := get_tree().get_first_node_in_group("main")
	return main != null and main.has_method("is_night") and bool(main.call("is_night"))


func on_signal_burst(origin: Vector2, radius: float) -> void:
	if _dying or origin.distance_to(global_position) > radius:
		return
	_exposed_time = exposed_duration
	_attack_cd = maxf(_attack_cd, 1.4)
	_change_state(State.STALK)
	velocity = Vector2.ZERO
	_play_action(StringName("hit_" + _face), 0.32)
	EventBus.scannable_pinged.emit(global_position)
	EventBus.notice_posted.emit("MIMIC EXPOSED - its copied road-noise has collapsed.")


func take_damage(amount: float) -> void:
	if _dying or amount <= 0.0:
		return
	var scale := 1.0 if _exposed_time > 0.0 or _state != State.DORMANT else 0.25
	_health.take_damage(amount * scale)
	if not _dying:
		AudioManager.play(&"hollow_hit")
		_play_action(StringName("hit_" + _face), 0.22)


func _change_state(next: State) -> void:
	_state = next
	_state_time = 0.0
	if next == State.WINDUP:
		_face = DirectionalAnimation.select_direction(
			_lunge_direction, _face, facing_hysteresis)
		_play_action(StringName("attack_" + _face), get_effective_windup_duration())
		AudioManager.play(&"weak_signal", 0.0, 0.72)
		EventBus.camera_shake_requested.emit(0.8, 0.08)
	elif next == State.RETREAT:
		_anim_lock = 0.0


func _apply_visibility() -> void:
	var alpha := 1.0
	if _exposed_time <= 0.0:
		alpha = 0.18 if _state == State.DORMANT else 0.58
		alpha = NPCServiceRulesScript.mimic_visibility_alpha(
			_state == State.DORMANT, alpha)
	_visual.modulate = Color(0.74, 0.76, 0.71, alpha)


func get_effective_windup_duration() -> float:
	return NPCServiceRulesScript.mimic_windup_duration(windup_duration)


func _update_animation() -> void:
	if _visual == null or _anim_lock > 0.0:
		return
	var moving := velocity.length() > 1.0
	if moving:
		_face = DirectionalAnimation.select_direction(
			velocity, _face, facing_hysteresis)
	var prefix := "attack_" if _state in [State.WINDUP, State.LUNGE] else ("walk_" if velocity.length() > 1.0 else "idle_")
	var wanted := StringName(prefix + _face)
	DirectionalAnimation.play(_visual, wanted, moving)


func _play_action(animation: StringName, lock: float) -> void:
	if DirectionalAnimation.play(_visual, animation):
		_anim_lock = maxf(lock, DirectionalAnimation.animation_duration(
			_visual.sprite_frames, animation, _visual.speed_scale))


func _on_animation_frame_changed() -> void:
	DirectionalAnimation.apply_registration(_visual)


func _draw() -> void:
	if _state == State.WINDUP:
		var progress := clampf(_state_time / get_effective_windup_duration(), 0.0, 1.0)
		var end := _lunge_direction * 155.0
		draw_dashed_line(Vector2.ZERO, end, Color(0.94, 0.34, 0.86, 0.85), 4.0, 11.0)
		draw_circle(end, 16.0 + progress * 8.0, Color(0.9, 0.24, 0.72, 0.08 + progress * 0.1))
	if _exposed_time > 0.0:
		draw_arc(Vector2(0, -7), 42.0, 0.0, TAU, 40, Color(0.48, 0.94, 1.0, 0.72), 2.5, true)


func _on_died() -> void:
	if _dying:
		return
	_dying = true
	WorldState.mark_defeated(persistent_id)
	remove_from_group("scannables")
	_collision.set_deferred("disabled", true)
	_play_action(StringName("death_" + _face), 0.62)
	AudioManager.play(&"hollow_death")
	EventBus.notice_posted.emit("Mimic Stalker unmade. The false footsteps stop.")
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "modulate", Color(0.7, 0.38, 0.9, 0.0), 0.62)
	tween.tween_property(self, "scale", Vector2(0.3, 1.55), 0.62)
	tween.chain().tween_callback(Callable(self, "queue_free"))
