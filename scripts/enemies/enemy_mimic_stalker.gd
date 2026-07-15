class_name EnemyMimicStalker
extends CharacterBody2D
## Mobile ambusher that circles outside melee range, telegraphs a committed
## lunge, then retreats. A receiver sweep exposes it and cancels the ambush.

enum State { DORMANT, STALK, WINDUP, LUNGE, RETREAT }

@export var detection_radius: float = 350.0
@export var orbit_radius: float = 132.0
@export var stalk_speed: float = 82.0
@export var lunge_speed: float = 315.0
@export var lunge_damage: float = 18.0
@export var lunge_cooldown: float = 3.4
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
	_apply_visibility()


func _physics_process(delta: float) -> void:
	if _dying:
		velocity = Vector2.ZERO
		return
	_state_time += delta
	_attack_cd = maxf(_attack_cd - delta, 0.0)
	_exposed_time = maxf(_exposed_time - delta, 0.0)
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		velocity = Vector2.ZERO
		return
	var to_player := player.global_position - global_position
	var distance := to_player.length()
	var night_factor := 1.18 if _is_night() else 1.0
	match _state:
		State.DORMANT:
			velocity = Vector2.ZERO
			if distance <= detection_radius * night_factor:
				_change_state(State.STALK)
		State.STALK:
			var radial := to_player.normalized()
			var tangent := Vector2(-radial.y, radial.x) * _orbit_sign
			var correction := radial * clampf((distance - orbit_radius) / 70.0, -1.0, 1.0)
			velocity = (tangent + correction).normalized() * stalk_speed * night_factor
			if _attack_cd <= 0.0 and distance <= orbit_radius + 42.0:
				_lunge_direction = radial
				_change_state(State.WINDUP)
		State.WINDUP:
			velocity = Vector2.ZERO
			if _state_time >= 0.72:
				_hit_this_lunge = false
				_change_state(State.LUNGE)
		State.LUNGE:
			velocity = _lunge_direction * lunge_speed * night_factor
			if not _hit_this_lunge and distance <= 34.0 and player.has_method("take_damage"):
				player.take_damage(lunge_damage)
				_hit_this_lunge = true
			if _state_time >= 0.48:
				_change_state(State.RETREAT)
		State.RETREAT:
			velocity = -to_player.normalized() * stalk_speed * 1.35
			if _state_time >= 0.78:
				_attack_cd = lunge_cooldown
				_orbit_sign *= -1.0
				_change_state(State.STALK)
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
	_visual.play(StringName("hit_" + _face))
	EventBus.scannable_pinged.emit(global_position)
	EventBus.notice_posted.emit("MIMIC EXPOSED - its copied road-noise has collapsed.")


func take_damage(amount: float) -> void:
	if _dying or amount <= 0.0:
		return
	var scale := 1.0 if _exposed_time > 0.0 or _state != State.DORMANT else 0.25
	_health.take_damage(amount * scale)
	if not _dying:
		AudioManager.play(&"hollow_hit")
		_visual.play(StringName("hit_" + _face))


func _change_state(next: State) -> void:
	_state = next
	_state_time = 0.0
	if next == State.WINDUP:
		AudioManager.play(&"weak_signal", 0.0, 0.72)
		EventBus.camera_shake_requested.emit(0.8, 0.08)


func _apply_visibility() -> void:
	var alpha := 1.0
	if _exposed_time <= 0.0:
		alpha = 0.18 if _state == State.DORMANT else 0.58
	_visual.modulate = Color(0.74, 0.48, 0.82, alpha)


func _update_animation() -> void:
	if _visual == null:
		return
	if velocity.length() > 1.0:
		_face = _dir_from(velocity)
	var prefix := "attack_" if _state in [State.WINDUP, State.LUNGE] else ("walk_" if velocity.length() > 1.0 else "idle_")
	var wanted := StringName(prefix + _face)
	if _visual.animation != wanted or not _visual.is_playing():
		_visual.play(wanted)


func _dir_from(direction: Vector2) -> String:
	if absf(direction.x) > absf(direction.y):
		return "right" if direction.x > 0.0 else "left"
	return "down" if direction.y >= 0.0 else "up"


func _draw() -> void:
	if _state == State.WINDUP:
		var progress := clampf(_state_time / 0.72, 0.0, 1.0)
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
	_visual.play(StringName("death_" + _face))
	AudioManager.play(&"hollow_death")
	EventBus.notice_posted.emit("Mimic Stalker unmade. The false footsteps stop.")
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "modulate", Color(0.7, 0.38, 0.9, 0.0), 0.62)
	tween.tween_property(self, "scale", Vector2(0.3, 1.55), 0.62)
	tween.chain().tween_callback(Callable(self, "queue_free"))
