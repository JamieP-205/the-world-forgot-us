class_name EnemyStaticWraith
extends CharacterBody2D
## Static Wraith -- an almost invisible ambusher that the trace receiver can
## force into the world. While phase-shrouded it only takes chip damage;
## a scanner pulse reveals and stuns it long enough for a focused attack.

@export var move_speed: float = 76.0
@export var movement_acceleration: float = 430.0
@export var movement_deceleration: float = 620.0
@export_range(0.0, 0.5, 0.01) var facing_hysteresis: float = 0.24
@export var detection_radius: float = 300.0
@export var attack_range: float = 28.0
@export var contact_damage: float = 11.0
@export var attack_cooldown: float = 1.15
@export var scan_stun_duration: float = 4.2
@export_range(0.0, 1.0, 0.01) var shrouded_damage_scale: float = 0.08

## Stable id for hand-placed persistence. Empty falls back to the node name.
@export var persistent_id: StringName = &""

@onready var _health: HealthComponent = $HealthComponent
@onready var _collision_shape: CollisionShape2D = $CollisionShape2D
@onready var _visual: AnimatedSprite2D = $Visual
@onready var _shadow: Polygon2D = $ContactShadow

var _attack_cd := 0.0
var _scan_stun := 0.0
var _notice_cd := 0.0
var _anim_lock := 0.0
var _time := 0.0
var _dying := false
var _face := "down"


func _ready() -> void:
	if persistent_id == &"":
		persistent_id = StringName(name)
	if WorldState.is_defeated(persistent_id):
		set_physics_process(false)
		hide()
		queue_free()
		return

	add_to_group("enemies")
	add_to_group("scannables")
	_health.died.connect(_on_died)
	EventBus.scanner_pulsed.connect(on_signal_burst)
	_visual.frame_changed.connect(_on_animation_frame_changed)
	DirectionalAnimation.play(_visual, &"idle_down")
	_apply_phase_visual(false)


func _physics_process(delta: float) -> void:
	_time += delta
	_attack_cd = maxf(_attack_cd - delta, 0.0)
	_notice_cd = maxf(_notice_cd - delta, 0.0)
	_anim_lock = maxf(_anim_lock - delta, 0.0)
	_visual.position.y = sin(_time * 2.8) * 2.5
	queue_redraw()

	if _dying:
		velocity = Vector2.ZERO
		return

	if _scan_stun > 0.0:
		_scan_stun = maxf(_scan_stun - delta, 0.0)
		velocity = Vector2.ZERO
		if _scan_stun <= 0.0:
			_apply_phase_visual(false)
		_update_anim()
		return

	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		velocity = DirectionalAnimation.smooth_velocity(
			velocity, Vector2.ZERO, movement_acceleration, movement_deceleration, delta)
		move_and_slide()
		_update_anim()
		return

	var to_player: Vector2 = player.global_position - global_position
	var distance := to_player.length()
	var target_velocity := Vector2.ZERO
	if distance <= attack_range:
		if _attack_cd <= 0.0 and player.has_method("take_damage"):
			player.take_damage(contact_damage)
			_attack_cd = attack_cooldown
			_play_action(StringName("attack_" + _face), 0.32)
	elif distance <= detection_radius:
		target_velocity = to_player.normalized() * move_speed

	velocity = DirectionalAnimation.smooth_velocity(
		velocity, target_velocity, movement_acceleration, movement_deceleration, delta)
	move_and_slide()
	_update_anim()


## Public scanner hook. It is also connected directly to
## EventBus.scanner_pulsed so the enemy works in any future map unchanged.
func on_signal_burst(origin: Vector2, radius: float) -> void:
	if _dying or origin.distance_to(global_position) > radius:
		return
	var was_shrouded := _scan_stun <= 0.0
	_scan_stun = scan_stun_duration
	velocity = Vector2.ZERO
	_apply_phase_visual(true)
	_play_action(StringName("hit_" + _face), 0.4)
	EventBus.scannable_pinged.emit(global_position)
	EventBus.camera_shake_requested.emit(1.5, 0.12)
	if was_shrouded:
		EventBus.notice_posted.emit(
			"STATIC WRAITH LOCKED — the scan has forced it solid. Strike now!")


## Damage entry point used by the player's melee hitbox.
func take_damage(amount: float) -> void:
	if _dying or amount <= 0.0:
		return
	if _scan_stun <= 0.0:
		_health.take_damage(amount * shrouded_damage_scale)
		_flash(Color(0.36, 0.86, 0.94, 0.2))
		if _notice_cd <= 0.0 and not _dying:
			_notice_cd = 1.1
			EventBus.notice_posted.emit(
				"Your strike passes through static. Pin the Wraith with a scan.")
	else:
		_health.take_damage(amount)
		if not _dying:
			_flash(Color(0.72, 1.25, 1.35, 1.0))
			_play_action(StringName("hit_" + _face), 0.22)


func _apply_phase_visual(revealed: bool) -> void:
	if revealed:
		_visual.modulate = Color(0.42, 1.15, 1.3, 0.98)
		_shadow.color = Color(0.08, 0.45, 0.52, 0.34)
	else:
		_visual.modulate = Color(0.35, 0.9, 1.0, 0.075)
		_shadow.color = Color(0.02, 0.14, 0.17, 0.16)
	queue_redraw()


func _flash(color: Color) -> void:
	AudioManager.play(&"hollow_hit")
	_visual.modulate = color
	var target := Color(0.42, 1.15, 1.3, 0.98) if _scan_stun > 0.0 \
		else Color(0.35, 0.9, 1.0, 0.075)
	var tween := create_tween()
	tween.tween_property(_visual, "modulate", target, 0.2)


func _update_anim() -> void:
	if _dying or _visual == null or _anim_lock > 0.0:
		return
	var moving := velocity.length() > 1.0
	if moving:
		_face = DirectionalAnimation.select_direction(
			velocity, _face, facing_hysteresis)
	var wanted := StringName(("walk_" if moving else "idle_") + _face)
	DirectionalAnimation.play(_visual, wanted, moving)


func _play_action(animation: StringName, lock: float) -> void:
	if DirectionalAnimation.play(_visual, animation):
		_anim_lock = maxf(lock, DirectionalAnimation.animation_duration(
			_visual.sprite_frames, animation, _visual.speed_scale))


func _on_animation_frame_changed() -> void:
	DirectionalAnimation.apply_registration(_visual)


func _draw() -> void:
	if _dying:
		return
	var revealed := _scan_stun > 0.0
	var strength := 1.0 if revealed else 0.12
	var breathe := 0.5 + 0.5 * sin(_time * 4.6)
	var mist_color := Color(0.22, 0.9, 1.0, (0.12 + breathe * 0.08) * strength)
	draw_circle(Vector2(0, -7), 32.0 + breathe * 5.0, mist_color)
	for index in range(3):
		var radius := 37.0 + float(index) * 8.0 + sin(_time * (2.2 + index) + index) * 3.0
		var start := _time * (0.75 + index * 0.2) + index * 1.7
		draw_arc(Vector2(0, -7), radius, start, start + 1.65, 18,
			Color(0.48, 0.96, 1.0, (0.34 - index * 0.07) * strength),
			2.4 if revealed else 1.2, true)

	# Uneven lightning scratches keep the invisible enemy detectable without
	# giving away a full silhouette. During scan-stun they flare bright cyan.
	for index in range(4):
		var phase := _time * (6.0 + index) + index * 2.1
		var x := sin(phase) * (18.0 + index * 4.0)
		var y := -30.0 + float(index) * 16.0
		var points := PackedVector2Array([
			Vector2(x - 8.0, y),
			Vector2(x + 3.0, y + 5.0),
			Vector2(x - 2.0, y + 11.0),
			Vector2(x + 9.0, y + 17.0),
		])
		draw_polyline(points, Color(0.62, 1.0, 1.0, 0.72 * strength), 1.6, true)

	if revealed:
		var lock_progress := 1.0 - (_scan_stun / maxf(scan_stun_duration, 0.001))
		draw_arc(Vector2(0, -7), 52.0, -PI * 0.5,
			-PI * 0.5 + TAU * lock_progress, 48,
			Color(0.75, 1.0, 1.0, 0.9), 3.0, true)


func _on_died() -> void:
	if _dying:
		return
	_dying = true
	velocity = Vector2.ZERO
	WorldState.mark_defeated(persistent_id)
	remove_from_group("scannables")
	_collision_shape.set_deferred("disabled", true)
	_play_action(StringName("death_" + _face), 0.7)
	AudioManager.play(&"hollow_death")
	EventBus.notice_posted.emit("Static Wraith grounded and dispersed.")
	EventBus.camera_shake_requested.emit(2.7, 0.18)
	queue_redraw()
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "modulate", Color(0.45, 1.0, 1.0, 0.0), 0.62)
	tween.tween_property(self, "scale", Vector2(1.5, 0.25), 0.62)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(Callable(self, "queue_free"))
