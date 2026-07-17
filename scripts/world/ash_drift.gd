class_name AshDrift
extends Node2D
## Screen-local ash/dust drift. Authored side pockets can also carry a low,
## readable exposure cost; broad atmospheric drifts remain harmless.

@export var particle_count := 46
@export var area := Vector2(720, 420)
@export var drift := Vector2(-10, 7)
@export_range(0.0, 30.0, 0.5) var exposure_damage := 0.0
@export_range(0.5, 5.0, 0.1) var exposure_interval := 1.4

var _points: Array[Vector2] = []
var _speeds: Array[float] = []
var _exposure_clock := 0.0
var _was_inside := false
var _warning_given := false


func _ready() -> void:
	z_index = 100
	if exposure_damage > 0.0:
		add_to_group("ash_exposure_zones")
		set_meta("hazard_contract", "filtered-ash-pocket")
		set_meta("base_exposure_damage", exposure_damage)
	for i in particle_count:
		var x := fposmod(float(i * 97), area.x) - area.x * 0.5
		var y := fposmod(float(i * 53), area.y) - area.y * 0.5
		_points.append(Vector2(x, y))
		_speeds.append(0.45 + float(i % 5) * 0.16)


func _process(delta: float) -> void:
	for i in _points.size():
		var p := _points[i] + drift * _speeds[i] * delta
		if p.x < -area.x * 0.5:
			p.x = area.x * 0.5
		if p.y > area.y * 0.5:
			p.y = -area.y * 0.5
		_points[i] = p
	_update_exposure(delta)
	queue_redraw()


func _draw() -> void:
	for i in _points.size():
		var alpha := 0.18 + float(i % 3) * 0.05
		draw_circle(_points[i], 1.1 + float(i % 2) * 0.6, Color(0.72, 0.72, 0.66, alpha))


func calculate_exposure_damage() -> float:
	return exposure_damage * CraftedItemEffects.get_ash_damage_multiplier()


func _update_exposure(delta: float) -> void:
	if exposure_damage <= 0.0:
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null or not player.has_method("take_damage"):
		_was_inside = false
		_exposure_clock = 0.0
		return
	var local_position := to_local(player.global_position)
	var inside := absf(local_position.x) <= area.x * 0.5 \
		and absf(local_position.y) <= area.y * 0.5
	if inside and not _was_inside and not _warning_given:
		_warning_given = true
		EventBus.notice_posted.emit(
			"ASH POCKET - the air is abrasive here. A charcoal filter will cut the exposure, not remove it.")
	_was_inside = inside
	if not inside:
		_exposure_clock = 0.0
		return
	_exposure_clock += delta
	if _exposure_clock < exposure_interval:
		return
	_exposure_clock = fmod(_exposure_clock, exposure_interval)
	player.call("take_damage", calculate_exposure_damage())
