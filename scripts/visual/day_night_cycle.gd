class_name DayNightCycle
extends Node
## Persistent, region-aware day/night grading for the campaign.
##
## The cycle lives under Main, so travelling never resets the sky. It grades the
## world with CanvasModulate, nudges the ink-wash shader, and raises practical
## lamps after dusk. The darkest palette is deliberately lifted enough that
## routes, enemies, and objective props remain readable on ordinary monitors.

signal phase_changed(phase_name: StringName, phase: float)

@export_range(90.0, 1200.0, 1.0) var cycle_duration_seconds := 420.0
@export_range(0.0, 1.0, 0.001) var start_phase := 0.18
@export var cycle_enabled := true
@export var world_tint_path := NodePath("../WorldTint")
@export var screen_grade_path := NodePath("../ScreenGrade/Grade")

var phase := 0.18
var _region := &"cullbrook"
var _last_phase_name := &""
var _world_tint: CanvasModulate
var _grade: ColorRect


func _ready() -> void:
	phase = wrapf(start_phase, 0.0, 1.0)
	cycle_enabled = SettingsManager.get_bool("gameplay", "day_night_cycle", true)
	_world_tint = get_node_or_null(world_tint_path) as CanvasModulate
	_grade = get_node_or_null(screen_grade_path) as ColorRect
	_apply_grade()


func _process(delta: float) -> void:
	if cycle_enabled and cycle_duration_seconds > 0.0:
		phase = wrapf(phase + delta / cycle_duration_seconds, 0.0, 1.0)
	_apply_grade()


func configure_level(scene_path: String) -> void:
	if scene_path == GameManager.BASE_SCENE_PATH:
		_region = &"railhome"
	elif scene_path.ends_with("ashmere_verge.tscn"):
		_region = &"ashmere"
	elif scene_path.ends_with("broadcast_fields.tscn"):
		_region = &"broadcast"
	elif scene_path.ends_with("choir_core.tscn"):
		_region = &"choir"
	else:
		_region = &"cullbrook"
	_apply_grade()


func set_phase(value: float) -> void:
	phase = wrapf(value, 0.0, 1.0)
	_apply_grade()


func get_phase_name() -> StringName:
	if phase < 0.10 or phase >= 0.92:
		return &"night"
	if phase < 0.22:
		return &"dawn"
	if phase < 0.58:
		return &"day"
	if phase < 0.72:
		return &"dusk"
	return &"night"


func is_night() -> bool:
	return phase >= 0.72 or phase < 0.10


func get_night_factor() -> float:
	# Noon is 0, midnight is 1, with a long readable shoulder at twilight.
	var sun_height := sin((phase - 0.25) * TAU)
	return 1.0 - smoothstep(-0.78, -0.08, sun_height)


func _apply_grade() -> void:
	var night := get_night_factor()
	var dusk := _dusk_factor()
	var dawn := _dawn_factor()
	var palette := _region_palette(_region)
	var day_color := palette["day"] as Color
	var night_color := palette["night"] as Color
	var dusk_color := palette["dusk"] as Color
	var dawn_color := palette["dawn"] as Color
	var tint := day_color.lerp(night_color, night)
	tint = tint.lerp(dusk_color, dusk * 0.48)
	tint = tint.lerp(dawn_color, dawn * 0.34)
	if _region == &"railhome":
		# Carriage 317 is a warm refuge, but the windowless interior still
		# breathes with the hour through its practical lamps.
		tint = day_color.lerp(night_color, night * 0.42)
	if _world_tint != null:
		_world_tint.color = tint

	if _grade != null and _grade.material is ShaderMaterial:
		var material := _grade.material as ShaderMaterial
		material.set_shader_parameter("night_factor", night)
		material.set_shader_parameter("dusk_factor", dusk)
		material.set_shader_parameter("dawn_factor", dawn)
		material.set_shader_parameter("region_tone", palette["tone"] as Color)

	# LightingDirector tags only genuine PointLight2D lamps, so legacy polygon
	# glows are never amplified into the coloured cards this pass replaces.
	for node in get_tree().get_nodes_in_group("day_night_practical"):
		if not (node is PointLight2D):
			continue
		var light := node as PointLight2D
		var base_energy := float(light.get_meta("day_night_base_energy", light.energy))
		light.energy = base_energy * lerpf(0.72, 1.42, night)

	var phase_name := get_phase_name()
	if phase_name != _last_phase_name:
		_last_phase_name = phase_name
		phase_changed.emit(phase_name, phase)


func _dusk_factor() -> float:
	return smoothstep(0.55, 0.65, phase) * (1.0 - smoothstep(0.69, 0.78, phase))


func _dawn_factor() -> float:
	return smoothstep(0.06, 0.14, phase) * (1.0 - smoothstep(0.19, 0.28, phase))


func _region_palette(region: StringName) -> Dictionary:
	match region:
		&"railhome":
			return {
				"day": Color(0.96, 0.85, 0.70, 1.0),
				"dawn": Color(1.0, 0.78, 0.58, 1.0),
				"dusk": Color(0.90, 0.64, 0.50, 1.0),
				"night": Color(0.70, 0.64, 0.61, 1.0),
				"tone": Color(0.82, 0.61, 0.43, 1.0),
			}
		&"ashmere":
			return {
				"day": Color(0.86, 0.89, 0.81, 1.0),
				"dawn": Color(0.93, 0.79, 0.64, 1.0),
				"dusk": Color(0.77, 0.60, 0.53, 1.0),
				"night": Color(0.52, 0.61, 0.67, 1.0),
				"tone": Color(0.52, 0.63, 0.56, 1.0),
			}
		&"broadcast":
			return {
				"day": Color(0.80, 0.86, 0.84, 1.0),
				"dawn": Color(0.90, 0.76, 0.63, 1.0),
				"dusk": Color(0.70, 0.56, 0.62, 1.0),
				"night": Color(0.47, 0.58, 0.68, 1.0),
				"tone": Color(0.42, 0.61, 0.64, 1.0),
			}
		&"choir":
			return {
				"day": Color(0.75, 0.82, 0.82, 1.0),
				"dawn": Color(0.84, 0.72, 0.64, 1.0),
				"dusk": Color(0.64, 0.53, 0.64, 1.0),
				"night": Color(0.43, 0.53, 0.65, 1.0),
				"tone": Color(0.37, 0.55, 0.61, 1.0),
			}
		_:
			return {
				"day": Color(0.88, 0.91, 0.86, 1.0),
				"dawn": Color(0.96, 0.81, 0.65, 1.0),
				"dusk": Color(0.79, 0.62, 0.56, 1.0),
				"night": Color(0.54, 0.63, 0.69, 1.0),
				"tone": Color(0.50, 0.61, 0.56, 1.0),
			}
