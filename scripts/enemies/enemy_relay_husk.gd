class_name EnemyRelayHusk
extends CharacterBody2D
## Relay Husk -- a scanner-gated boss. Its signal shield blocks melee until
## a Mnemoscope burst overloads it. Health thresholds accelerate the chase,
## shorten radial telegraphs, and increase the danger radius.

@export var detection_radius: float = 560.0
@export var contact_range: float = 43.0
@export var contact_damage: float = 16.0
@export var contact_cooldown: float = 1.0
@export var shield_down_duration: float = 6.0
@export var scan_stun_duration: float = 0.75
@export var persistent_id: StringName = &""

@onready var _health: HealthComponent = $HealthComponent
@onready var _collision_shape: CollisionShape2D = $CollisionShape2D
@onready var _visual: AnimatedSprite2D = $Visual
@onready var _shadow: Polygon2D = $ContactShadow

var _shield_active := true
var _shield_down_time := 0.0
var _scan_stun := 0.0
var _contact_cd := 0.0
var _radial_cd := 2.4
var _radial_charging := false
var _radial_elapsed := 0.0
var _blast_time := 0.0
var _blast_radius := 140.0
var _notice_cd := 0.0
var _anim_lock := 0.0
var _phase := 1
var _face := "down"
var _time := 0.0
var _dying := false


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
	_health.health_changed.connect(_on_health_changed)
	_health.died.connect(_on_died)
	EventBus.scanner_pulsed.connect(on_signal_burst)
	_visual.play(&"idle_down")


func _physics_process(delta: float) -> void:
	_time += delta
	_contact_cd = maxf(_contact_cd - delta, 0.0)
	_radial_cd = maxf(_radial_cd - delta, 0.0)
	_notice_cd = maxf(_notice_cd - delta, 0.0)
	_anim_lock = maxf(_anim_lock - delta, 0.0)
	_blast_time = maxf(_blast_time - delta, 0.0)
	_visual.position.y = sin(_time * 2.2) * 1.4

	if not _shield_active:
		_shield_down_time = maxf(_shield_down_time - delta, 0.0)
		if _shield_down_time <= 0.0 and not _dying:
			_reform_shield()
	_scan_stun = maxf(_scan_stun - delta, 0.0)
	queue_redraw()

	if _dying:
		velocity = Vector2.ZERO
		return

	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		velocity = Vector2.ZERO
		_update_anim()
		return

	if _radial_charging:
		velocity = Vector2.ZERO
		_radial_elapsed += delta
		if _radial_elapsed >= _telegraph_duration():
			_fire_radial(player)
		return

	if _scan_stun > 0.0:
		velocity = Vector2.ZERO
		_update_anim()
		return

	var to_player: Vector2 = player.global_position - global_position
	var distance := to_player.length()
	if _radial_cd <= 0.0 and distance <= _radial_trigger_distance():
		_start_radial_attack()
		return

	if distance <= contact_range:
		velocity = Vector2.ZERO
		if _contact_cd <= 0.0 and player.has_method("take_damage"):
			player.take_damage(_phase_contact_damage())
			_contact_cd = contact_cooldown
			_play_action(StringName("attack_" + _face), 0.34)
	elif distance <= detection_radius:
		velocity = to_player.normalized() * _phase_move_speed()
	else:
		velocity = Vector2.ZERO

	move_and_slide()
	_update_anim()


## Public scanner hook and EventBus listener. A pulse in range removes the
## shield for a fixed vulnerability window and briefly interrupts the boss.
func on_signal_burst(origin: Vector2, radius: float) -> void:
	if _dying or origin.distance_to(global_position) > radius:
		return
	var broke_shield := _shield_active
	_shield_active = false
	_shield_down_time = shield_down_duration
	_scan_stun = scan_stun_duration
	velocity = Vector2.ZERO
	EventBus.scannable_pinged.emit(global_position)
	EventBus.camera_shake_requested.emit(2.4, 0.17)
	_play_action(StringName("hit_" + _face), 0.34)
	if broke_shield:
		EventBus.notice_posted.emit(
			"RELAY SHIELD BROKEN — its amber core is exposed. Attack!")
	else:
		EventBus.notice_posted.emit("Relay shield overload extended.")
	queue_redraw()


## Damage entry point used by player attacks.
func take_damage(amount: float) -> void:
	if _dying or amount <= 0.0:
		return
	if _shield_active:
		_shield_impact()
		if _notice_cd <= 0.0:
			_notice_cd = 1.0
			EventBus.notice_posted.emit(
				"The Relay shield rejects the blow. Break it with the Mnemoscope.")
		return
	_health.take_damage(amount)
	if not _dying:
		_flash_hurt()
		_play_action(StringName("hit_" + _face), 0.22)


func _start_radial_attack() -> void:
	_radial_charging = true
	_radial_elapsed = 0.0
	velocity = Vector2.ZERO
	_play_action(StringName("attack_" + _face), _telegraph_duration())
	EventBus.notice_posted.emit(
		"RELAY SURGE — clear the amber warning ring!")
	EventBus.camera_shake_requested.emit(1.2, 0.12)
	queue_redraw()


func _fire_radial(player: Node) -> void:
	var radius := _radial_range()
	_radial_charging = false
	_radial_elapsed = 0.0
	_radial_cd = _radial_cooldown()
	_blast_time = 0.34
	_blast_radius = radius
	if player != null and global_position.distance_to(player.global_position) <= radius:
		if player.has_method("take_damage"):
			player.take_damage(_radial_damage())
	AudioManager.play(&"hollow_hit")
	EventBus.camera_shake_requested.emit(4.0 + _phase, 0.24)
	queue_redraw()


func _reform_shield() -> void:
	_shield_active = true
	_shield_down_time = 0.0
	EventBus.notice_posted.emit("The Relay Husk's cyan shield knits itself back together.")
	queue_redraw()


func _shield_impact() -> void:
	AudioManager.play(&"hollow_hit")
	EventBus.camera_shake_requested.emit(0.9, 0.08)
	var tween := create_tween()
	tween.tween_property(_visual, "modulate", Color(0.35, 1.5, 1.75, 1.0), 0.07)
	tween.tween_property(_visual, "modulate", _phase_color(), 0.18)


func _flash_hurt() -> void:
	AudioManager.play(&"hollow_hit")
	_visual.modulate = Color(1.7, 0.48, 0.3, 1.0)
	var tween := create_tween()
	tween.tween_property(_visual, "modulate", _phase_color(), 0.24)


func _on_health_changed(current: float, maximum: float) -> void:
	if current <= 0.0 or maximum <= 0.0:
		return
	var ratio := current / maximum
	var next_phase := 3 if ratio <= 0.33 else (2 if ratio <= 0.66 else 1)
	if next_phase <= _phase:
		return
	_phase = next_phase
	_shield_active = true
	_shield_down_time = 0.0
	_scan_stun = 0.48
	_radial_cd = minf(_radial_cd, 1.25)
	_visual.modulate = _phase_color()
	EventBus.notice_posted.emit(
		"RELAY PHASE %d — shield restored; signal pressure rising." % _phase)
	EventBus.camera_shake_requested.emit(3.2, 0.24)
	queue_redraw()


func _phase_move_speed() -> float:
	return [0.0, 58.0, 76.0, 94.0][_phase]


func _phase_contact_damage() -> float:
	return contact_damage + float(_phase - 1) * 3.0


func _radial_range() -> float:
	return [0.0, 132.0, 158.0, 188.0][_phase]


func _radial_damage() -> float:
	return [0.0, 18.0, 23.0, 29.0][_phase]


func _radial_cooldown() -> float:
	return [0.0, 5.4, 4.25, 3.35][_phase]


func _telegraph_duration() -> float:
	return [0.0, 1.25, 1.05, 0.86][_phase]


func _radial_trigger_distance() -> float:
	return _radial_range() + 92.0


func _phase_color() -> Color:
	match _phase:
		2:
			return Color(0.65, 0.82, 0.66, 1.0)
		3:
			return Color(0.86, 0.55, 0.42, 1.0)
		_:
			return Color(0.48, 0.76, 0.72, 1.0)


func _update_anim() -> void:
	if _dying or _visual == null or _anim_lock > 0.0:
		return
	var moving := velocity.length() > 1.0
	if moving:
		_face = _dir_from(velocity)
	var wanted := StringName(("walk_" if moving else "idle_") + _face)
	if _visual.animation != wanted or not _visual.is_playing():
		_visual.play(wanted)


func _dir_from(direction: Vector2) -> String:
	if absf(direction.x) > absf(direction.y):
		return "right" if direction.x > 0.0 else "left"
	return "down" if direction.y >= 0.0 else "up"


func _play_action(animation: StringName, lock: float) -> void:
	if _visual.sprite_frames != null and _visual.sprite_frames.has_animation(animation):
		_visual.play(animation)
		_anim_lock = lock


func _draw() -> void:
	if _dying:
		return
	var pulse := 0.5 + 0.5 * sin(_time * (3.2 + _phase * 0.35))

	# Shield language: complete rotating cyan rings mean protected; broken arcs
	# and an amber core mean the melee vulnerability window is open.
	if _shield_active:
		draw_circle(Vector2(0, -8), 47.0 + pulse * 4.0,
			Color(0.12, 0.72, 0.9, 0.08 + pulse * 0.05))
		for index in range(3):
			var radius := 50.0 + index * 8.0
			var spin := _time * (0.8 + index * 0.28) * (-1.0 if index == 1 else 1.0)
			draw_arc(Vector2(0, -8), radius, spin, spin + PI * 1.45, 36,
				Color(0.35, 0.92, 1.0, 0.72 - index * 0.14), 3.0, true)
	else:
		for index in range(4):
			var radius := 52.0 + index * 4.0
			var angle := index * PI * 0.5 + sin(_time * 2.5 + index) * 0.18
			draw_arc(Vector2(0, -8), radius, angle, angle + 0.52, 10,
				Color(0.4, 0.9, 1.0, 0.28), 2.0, true)
		var exposed_alpha := 0.32 + pulse * 0.2
		draw_circle(Vector2(0, -10), 19.0 + pulse * 3.0,
			Color(1.0, 0.5, 0.16, exposed_alpha))

	# Radial attack: the final danger boundary stays fixed while a second ring
	# contracts to the boss. When the rings meet, damage resolves immediately.
	if _radial_charging:
		var duration := maxf(_telegraph_duration(), 0.001)
		var progress := clampf(_radial_elapsed / duration, 0.0, 1.0)
		var danger_radius := _radial_range()
		var countdown_radius := lerpf(danger_radius, 18.0, progress)
		var warning := Color(1.0, 0.3 + progress * 0.2, 0.08, 0.82)
		draw_circle(Vector2.ZERO, danger_radius, Color(0.9, 0.12, 0.04, 0.055 + progress * 0.09))
		draw_arc(Vector2.ZERO, danger_radius, 0.0, TAU, 72, warning, 4.0, true)
		draw_arc(Vector2.ZERO, countdown_radius, 0.0, TAU, 72,
			Color(1.0, 0.76, 0.18, 0.92), 5.0, true)

	if _blast_time > 0.0:
		var blast_progress := 1.0 - (_blast_time / 0.34)
		var blast_ring := lerpf(22.0, _blast_radius, blast_progress)
		draw_circle(Vector2.ZERO, blast_ring,
			Color(1.0, 0.36, 0.1, (1.0 - blast_progress) * 0.11), false, 7.0, true)
		draw_arc(Vector2.ZERO, blast_ring, 0.0, TAU, 72,
			Color(1.0, 0.72, 0.25, 1.0 - blast_progress), 6.0, true)


func _on_died() -> void:
	if _dying:
		return
	_dying = true
	velocity = Vector2.ZERO
	_radial_charging = false
	WorldState.mark_defeated(persistent_id)
	remove_from_group("scannables")
	_collision_shape.set_deferred("disabled", true)
	_play_action(StringName("death_" + _face), 0.8)
	AudioManager.play(&"hollow_death")
	EventBus.notice_posted.emit("Relay Husk severed. The dead channel falls silent.")
	EventBus.camera_shake_requested.emit(6.0, 0.42)
	queue_redraw()
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "modulate", Color(0.9, 0.45, 0.22, 0.0), 0.85)
	tween.tween_property(self, "scale", Vector2(1.8, 0.35), 0.85)\
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(Callable(self, "queue_free"))
