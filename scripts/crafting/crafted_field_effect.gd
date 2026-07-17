class_name CraftedFieldEffect
extends Node2D
## Temporary world effect deployed by a crafted decoy, flare, alarm or
## carrier grounder. It uses existing enemy groups and collision-aware motion,
## so maps do not need bespoke hookups.

var effect_kind: StringName = &""
var source_item_id: StringName = &""
var radius := 180.0
var duration := 10.0
var pulse_interval := 1.0
var values: Dictionary = {}

var _elapsed := 0.0
var _pulse_clock := 0.0
var _alarm_reported := false
var _light: PointLight2D


func configure(data: CraftedItemEffectData) -> void:
	effect_kind = data.effect_kind
	source_item_id = data.item_id
	values = data.values.duplicate(true)
	radius = float(values.get("radius", radius))
	duration = float(values.get("duration", duration))
	pulse_interval = maxf(float(values.get("pulse_interval", pulse_interval)), 0.15)


func _ready() -> void:
	add_to_group("crafted_field_effects")
	_pulse_clock = 0.0
	if effect_kind == &"flare":
		_build_flare_light()
	queue_redraw()


func _physics_process(delta: float) -> void:
	_elapsed += delta
	_pulse_clock -= delta
	if _pulse_clock <= 0.0:
		_pulse_clock = pulse_interval
		_apply_pulse()
	if _light != null:
		_light.energy = maxf(0.0, 1.25 * (1.0 - _elapsed / maxf(duration, 0.01)))
	queue_redraw()
	if _elapsed >= duration:
		queue_free()


func _apply_pulse() -> void:
	var affected := 0
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if not candidate is Node2D or not is_instance_valid(candidate):
			continue
		var enemy := candidate as Node2D
		var distance := global_position.distance_to(enemy.global_position)
		if distance > radius:
			continue
		affected += 1
		if effect_kind == &"signal_decoy":
			_move_body(enemy, enemy.global_position.direction_to(global_position), float(values.get("pull", 7.0)))
		elif effect_kind == &"flare":
			_move_body(enemy, global_position.direction_to(enemy.global_position), float(values.get("fear_push", 9.0)))
		elif effect_kind == &"carrier_grounder" and enemy.is_in_group("scannables") \
				and enemy.has_method("take_damage"):
			enemy.call("take_damage", float(values.get("carrier_damage", 7.0)))

	if effect_kind in [&"signal_decoy", &"carrier_grounder"]:
		EventBus.scanner_pulsed.emit(global_position, radius)
	elif effect_kind == &"tripwire_alarm" and affected > 0 and not _alarm_reported:
		_alarm_reported = true
		EventBus.notice_posted.emit("TRIPWIRE / movement on the camp perimeter.")
		EventBus.camera_shake_requested.emit(1.2, 0.08)
	CraftedItemEffects.report_field_pulse(effect_kind, global_position, radius, affected)


func _move_body(enemy: Node2D, direction: Vector2, distance: float) -> void:
	if not enemy is CharacterBody2D or direction == Vector2.ZERO or distance <= 0.0:
		return
	(enemy as CharacterBody2D).move_and_collide(direction.normalized() * distance)


func _build_flare_light() -> void:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1.0, 0.72, 0.32, 0.92))
	gradient.set_color(1, Color(0.28, 0.04, 0.01, 0.0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 192
	texture.height = 192
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	_light = PointLight2D.new()
	_light.texture = texture
	_light.texture_scale = radius / 96.0
	_light.energy = 1.25
	_light.color = Color(1.0, 0.63, 0.28)
	add_child(_light)


func _draw() -> void:
	var life := clampf(1.0 - _elapsed / maxf(duration, 0.01), 0.0, 1.0)
	var pulse := 0.82 + sin(_elapsed * 5.0) * 0.12
	var tone := Color(0.34, 0.88, 0.86, 0.62)
	if effect_kind == &"flare":
		tone = Color(1.0, 0.55, 0.20, 0.78)
	elif effect_kind == &"tripwire_alarm":
		tone = Color(0.95, 0.72, 0.30, 0.66)
	elif effect_kind == &"carrier_grounder":
		tone = Color(0.42, 0.76, 1.0, 0.68)
	draw_circle(Vector2.ZERO, 9.0 * pulse, Color(tone.r, tone.g, tone.b, tone.a * life))
	draw_arc(Vector2.ZERO, radius * 0.18 * pulse, 0.0, TAU, 40, Color(tone.r, tone.g, tone.b, tone.a * 0.58 * life), 2.0)
	if effect_kind == &"tripwire_alarm":
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 72, Color(tone.r, tone.g, tone.b, 0.14 * life), 1.0)
