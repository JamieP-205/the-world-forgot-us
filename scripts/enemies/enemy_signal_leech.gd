class_name EnemySignalLeech
extends CharacterBody2D
## Stationary ranged denial enemy. It locks a visible impact point, giving the
## player time to move; a receiver sweep jams the next shot entirely.

@export var detection_radius: float = 430.0
@export var shot_damage: float = 15.0
@export var shot_cooldown: float = 2.8
@export var telegraph_duration: float = 1.05
@export var impact_radius: float = 52.0
@export var jam_duration: float = 3.8
@export var persistent_id: StringName = &""
@export var settling_deceleration: float = 700.0
@export_range(0.0, 0.5, 0.01) var facing_hysteresis: float = 0.24

@onready var _health: HealthComponent = $HealthComponent
@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var _visual: AnimatedSprite2D = $Visual

var _cooldown := 0.8
var _charging := false
var _charge_time := 0.0
var _locked_target := Vector2.ZERO
var _jam_time := 0.0
var _impact_flash := 0.0
var _time := 0.0
var _dying := false
var _anim_lock := 0.0
var _face := "down"


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


func _physics_process(delta: float) -> void:
	_time += delta
	_cooldown = maxf(_cooldown - delta, 0.0)
	_jam_time = maxf(_jam_time - delta, 0.0)
	_impact_flash = maxf(_impact_flash - delta, 0.0)
	_anim_lock = maxf(_anim_lock - delta, 0.0)
	_visual.position.y = -3.0 + sin(_time * 2.5) * 1.5
	velocity = DirectionalAnimation.smooth_velocity(
		velocity, Vector2.ZERO, settling_deceleration, settling_deceleration, delta)
	move_and_slide()
	queue_redraw()
	if _dying:
		return
	if _jam_time > 0.0:
		_charging = false
		_charge_time = 0.0
		_update_anim()
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		_update_anim()
		return
	_face = DirectionalAnimation.select_direction(
		player.global_position - global_position, _face, facing_hysteresis)
	if _charging:
		_charge_time += delta
		if _charge_time >= telegraph_duration:
			_fire(player)
		return
	var active_radius := detection_radius * (1.22 if _is_night() else 1.0)
	if _cooldown <= 0.0 and global_position.distance_to(player.global_position) <= active_radius:
		_charging = true
		_charge_time = 0.0
		_locked_target = player.global_position
		_play_action(StringName("attack_" + _face), telegraph_duration)
		AudioManager.play(&"weak_signal", 0.0, 1.22)
	else:
		_update_anim()


func on_signal_burst(origin: Vector2, radius: float) -> void:
	if _dying or origin.distance_to(global_position) > radius:
		return
	var interrupted := _charging or _jam_time <= 0.0
	_charging = false
	_charge_time = 0.0
	_jam_time = jam_duration
	_cooldown = maxf(_cooldown, jam_duration * 0.75)
	_face = DirectionalAnimation.select_direction(
		origin - global_position, _face, facing_hysteresis)
	_play_action(StringName("hit_" + _face), 0.28)
	EventBus.scannable_pinged.emit(global_position)
	if interrupted:
		EventBus.notice_posted.emit("SIGNAL LEECH JAMMED - its targeting carrier has gone dark.")
	queue_redraw()


func take_damage(amount: float) -> void:
	if _dying or amount <= 0.0:
		return
	_health.take_damage(amount)
	if not _dying:
		AudioManager.play(&"hollow_hit")
		_play_action(StringName("hit_" + _face), 0.22)
		var tween := create_tween()
		tween.tween_property(_visual, "modulate", Color(1.5, 0.72, 0.38, 1), 0.07)
		tween.tween_property(_visual, "modulate", Color(0.78, 0.46, 0.32, 0.94), 0.19)


func _fire(player: Node2D) -> void:
	_charging = false
	_charge_time = 0.0
	_cooldown = shot_cooldown * (0.76 if _is_night() else 1.0)
	_impact_flash = 0.32
	_face = DirectionalAnimation.select_direction(
		_locked_target - global_position, _face, facing_hysteresis)
	_play_action(StringName("attack_" + _face), 0.24)
	if player != null and player.global_position.distance_to(_locked_target) <= impact_radius:
		if player.has_method("take_damage"):
			player.take_damage(shot_damage)
	AudioManager.play(&"hollow_hit", 0.0, 0.7)
	EventBus.camera_shake_requested.emit(3.5, 0.2)
	queue_redraw()


func _is_night() -> bool:
	var main := get_tree().get_first_node_in_group("main")
	return main != null and main.has_method("is_night") and bool(main.call("is_night"))


func _update_anim() -> void:
	if _dying or _anim_lock > 0.0:
		return
	DirectionalAnimation.play(_visual, StringName("idle_" + _face))


func _play_action(animation: StringName, lock: float) -> void:
	if DirectionalAnimation.play(_visual, animation):
		_anim_lock = maxf(lock, DirectionalAnimation.animation_duration(
			_visual.sprite_frames, animation, _visual.speed_scale))


func _on_animation_frame_changed() -> void:
	DirectionalAnimation.apply_registration(_visual)


func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(_time * 4.0)
	if _jam_time > 0.0:
		for i in range(3):
			var start := _time * (1.2 + i * 0.25) + i * 2.0
			draw_arc(Vector2.ZERO, 34.0 + i * 8.0, start, start + 0.85, 14,
				Color(0.34, 0.92, 0.9, 0.5 - i * 0.1), 2.0, true)
	elif _charging:
		var local_target := to_local(_locked_target)
		var progress := clampf(_charge_time / maxf(telegraph_duration, 0.01), 0.0, 1.0)
		draw_dashed_line(Vector2(0, -7), local_target, Color(1.0, 0.38, 0.16, 0.62), 3.0, 12.0)
		draw_circle(local_target, impact_radius, Color(0.92, 0.16, 0.06, 0.06 + progress * 0.12))
		draw_arc(local_target, impact_radius, 0.0, TAU, 48,
			Color(1.0, 0.4 + progress * 0.3, 0.16, 0.86), 3.0, true)
		draw_arc(local_target, lerpf(impact_radius, 7.0, progress), 0.0, TAU, 32,
			Color(1.0, 0.82, 0.32, 0.94), 3.0, true)
	if _impact_flash > 0.0:
		var local_impact := to_local(_locked_target)
		var p := 1.0 - _impact_flash / 0.32
		draw_circle(local_impact, lerpf(8.0, impact_radius, p),
			Color(1.0, 0.5, 0.18, (1.0 - p) * 0.18), false, 7.0, true)
	else:
		draw_circle(Vector2(0, -5), 25.0 + pulse * 4.0, Color(0.8, 0.26, 0.12, 0.08))


func _on_died() -> void:
	if _dying:
		return
	_dying = true
	WorldState.mark_defeated(persistent_id)
	remove_from_group("scannables")
	_collision.set_deferred("disabled", true)
	_play_action(StringName("death_" + _face), 0.58)
	AudioManager.play(&"hollow_death")
	EventBus.notice_posted.emit("Signal Leech silenced. The road is no longer under its sightline.")
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "modulate", Color(1.0, 0.42, 0.18, 0.0), 0.58)
	tween.tween_property(self, "scale", Vector2(1.45, 0.22), 0.58)
	tween.chain().tween_callback(Callable(self, "queue_free"))
