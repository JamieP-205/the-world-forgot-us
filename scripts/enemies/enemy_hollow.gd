class_name EnemyHollow
extends CharacterBody2D
## The Hollow -- a slow, pale survivor-shaped threat.

const NPCServiceRulesScript = preload("res://scripts/narrative/npc_service_rules.gd")

@export var move_speed: float = 62.0
@export var movement_acceleration: float = 360.0
@export var movement_deceleration: float = 520.0
@export_range(0.0, 0.5, 0.01) var facing_hysteresis: float = 0.2
@export var detection_radius: float = 235.0
@export var attack_range: float = 30.0
@export var contact_damage: float = 8.0
@export var attack_cooldown: float = 1.2

## Stable id for persistence (hand-placed enemies only). Empty defaults to
## the node name. A defeated enemy stays gone across travel and save/load.
@export var persistent_id: StringName = &""

@onready var _health: HealthComponent = $HealthComponent
@onready var _hit_spark: Polygon2D = $HitSpark
@onready var _collision_shape: CollisionShape2D = $CollisionShape2D
@onready var _visual: AnimatedSprite2D = $Visual

var _attack_cd: float = 0.0
var _dying := false
## Current sprite facing ("down"/"up"/"left"/"right") and one-shot anim hold.
var _face := "down"
var _anim_lock: float = 0.0
var _service_tracking := false


func _ready() -> void:
	if persistent_id == &"":
		persistent_id = StringName(name)
	# Already defeated in a previous visit / earlier session: don't respawn.
	if WorldState.is_defeated(persistent_id):
		set_physics_process(false)
		hide()
		queue_free()
		return
	add_to_group("enemies")
	_health.died.connect(_on_died)
	_hit_spark.visible = false
	if _visual != null:
		_visual.frame_changed.connect(_on_animation_frame_changed)
		DirectionalAnimation.play(_visual, &"idle_down")
	_refresh_service_tracking()


func _physics_process(delta: float) -> void:
	if _dying:
		velocity = Vector2.ZERO
		return
	_refresh_service_tracking()
	_attack_cd = maxf(_attack_cd - delta, 0.0)
	_anim_lock = maxf(_anim_lock - delta, 0.0)

	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		velocity = DirectionalAnimation.smooth_velocity(
			velocity, Vector2.ZERO, movement_acceleration, movement_deceleration, delta)
		move_and_slide()
		_update_anim()
		return

	var to_player: Vector2 = player.global_position - global_position
	var dist := to_player.length()

	var target_velocity := Vector2.ZERO
	if dist <= attack_range:
		if _attack_cd <= 0.0 and player.has_method("take_damage"):
			_play_action(StringName("attack_" + _face), 0.34)
			player.take_damage(get_effective_contact_damage())
			_attack_cd = attack_cooldown
	elif dist <= get_effective_detection_radius():
		target_velocity = to_player.normalized() * move_speed

	velocity = DirectionalAnimation.smooth_velocity(
		velocity, target_velocity, movement_acceleration, movement_deceleration, delta)
	move_and_slide()
	_update_anim()


func get_effective_detection_radius() -> float:
	return NPCServiceRulesScript.hollow_detection_radius(detection_radius)


func get_effective_contact_damage() -> float:
	return NPCServiceRulesScript.hollow_contact_damage(contact_damage)


func get_scanner_feedback(origin: Vector2) -> Dictionary:
	var offset := global_position - origin
	var raw_bearing := roundi(rad_to_deg(offset.angle()) + 90.0)
	var bearing := ((raw_bearing % 360) + 360) % 360
	return {
		"bearing": "%03d DEG / %dm" % [bearing, roundi(offset.length() / 10.0)],
		"noise": "Nia's grounded lure / moving Hollow carrier",
	}


func on_service_scanner_pulse(origin: Vector2, radius: float) -> void:
	if not _service_tracking or origin.distance_to(global_position) > radius:
		return
	EventBus.scannable_pinged.emit(global_position)


func _refresh_service_tracking() -> void:
	var should_track := NPCServiceRulesScript.hollow_tracking_active()
	if should_track == _service_tracking:
		return
	_service_tracking = should_track
	if should_track:
		add_to_group("scannables")
		if not EventBus.scanner_pulsed.is_connected(on_service_scanner_pulse):
			EventBus.scanner_pulsed.connect(on_service_scanner_pulse)
	else:
		remove_from_group("scannables")
		if EventBus.scanner_pulsed.is_connected(on_service_scanner_pulse):
			EventBus.scanner_pulsed.disconnect(on_service_scanner_pulse)


## Cosmetic locomotion: idle vs shamble in the movement direction. Never runs
## while dying, and yields to a one-shot (hit) animation.
func _update_anim() -> void:
	if _dying or _visual == null or _anim_lock > 0.0:
		return
	var moving := velocity.length() > 1.0
	if moving:
		_face = DirectionalAnimation.select_direction(
			velocity, _face, facing_hysteresis)
	var want := StringName(("walk_" if moving else "idle_") + _face)
	DirectionalAnimation.play(_visual, want, moving)


func _play_action(anim: StringName, lock: float) -> void:
	if DirectionalAnimation.play(_visual, anim):
		_anim_lock = maxf(lock, DirectionalAnimation.animation_duration(
			_visual.sprite_frames, anim, _visual.speed_scale))


func _on_animation_frame_changed() -> void:
	DirectionalAnimation.apply_registration(_visual)


## Damage entry point, called by the player's melee hitbox.
func take_damage(amount: float) -> void:
	if _dying:
		return
	_health.take_damage(amount)
	if not _dying:
		_flash()


func _flash() -> void:
	AudioManager.play(&"hollow_hit")
	_play_action(StringName("hit_" + _face), 0.2)
	modulate = Color(1.6, 0.7, 0.7)
	_hit_spark.visible = true
	_hit_spark.scale = Vector2(1.6, 1.6)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate", Color(1, 1, 1), 0.25)
	tween.tween_property(_hit_spark, "scale", Vector2(0.25, 0.25), 0.18)
	tween.chain().tween_callback(func() -> void: _hit_spark.visible = false)


func _on_died() -> void:
	_dying = true
	if _service_tracking:
		remove_from_group("scannables")
		if EventBus.scanner_pulsed.is_connected(on_service_scanner_pulse):
			EventBus.scanner_pulsed.disconnect(on_service_scanner_pulse)
	_play_action(StringName("death_" + _face), 0.45)
	WorldState.mark_defeated(persistent_id)
	_collision_shape.set_deferred("disabled", true)
	AudioManager.play(&"hollow_death")
	EventBus.notice_posted.emit("Hollow dispersed.")
	EventBus.camera_shake_requested.emit(2.2, 0.12)
	_hit_spark.visible = true
	_hit_spark.scale = Vector2(2.0, 2.0)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate", Color(0.7, 0.95, 0.9, 0.0), 0.45)
	tween.tween_property(_hit_spark, "scale", Vector2(0.1, 0.1), 0.35)
	tween.chain().tween_callback(Callable(self, "queue_free"))
