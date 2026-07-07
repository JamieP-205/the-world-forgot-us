class_name EnemyHollow
extends CharacterBody2D
## The Hollow -- a slow, pale survivor-shaped threat.

@export var move_speed: float = 62.0
@export var detection_radius: float = 235.0
@export var attack_range: float = 30.0
@export var contact_damage: float = 8.0
@export var attack_cooldown: float = 1.2

@onready var _health: HealthComponent = $HealthComponent
@onready var _hit_spark: Polygon2D = $HitSpark
@onready var _collision_shape: CollisionShape2D = $CollisionShape2D

var _attack_cd: float = 0.0
var _dying := false


func _ready() -> void:
	add_to_group("enemies")
	_health.died.connect(_on_died)
	_hit_spark.visible = false


func _physics_process(delta: float) -> void:
	if _dying:
		velocity = Vector2.ZERO
		return
	_attack_cd = maxf(_attack_cd - delta, 0.0)

	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		velocity = Vector2.ZERO
		return

	var to_player: Vector2 = player.global_position - global_position
	var dist := to_player.length()

	if dist <= attack_range:
		velocity = Vector2.ZERO
		if _attack_cd <= 0.0 and player.has_method("take_damage"):
			player.take_damage(contact_damage)
			_attack_cd = attack_cooldown
	elif dist <= detection_radius:
		velocity = to_player.normalized() * move_speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()


## Damage entry point, called by the player's melee hitbox.
func take_damage(amount: float) -> void:
	if _dying:
		return
	_health.take_damage(amount)
	if not _dying:
		_flash()


func _flash() -> void:
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
	_collision_shape.set_deferred("disabled", true)
	EventBus.notice_posted.emit("Hollow dispersed.")
	EventBus.camera_shake_requested.emit(2.2, 0.12)
	_hit_spark.visible = true
	_hit_spark.scale = Vector2(2.0, 2.0)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate", Color(0.7, 0.95, 0.9, 0.0), 0.45)
	tween.tween_property(_hit_spark, "scale", Vector2(0.1, 0.1), 0.35)
	tween.chain().tween_callback(Callable(self, "queue_free"))
