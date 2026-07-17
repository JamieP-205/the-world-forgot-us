extends Control

signal closed

const REGION_INFO := [
	{"name": "CARRIAGE 317", "area": "railhome", "landmarks": ["Carriage 317 / shelter", "Mast road / east", "Keepsake shelf / berth"]},
	{"name": "CULLBROOK SERVICES", "area": "rustway", "landmarks": ["Carriage 317 / west", "Service yard / centre", "Mile lamp / east verge", "North-road mast / north-east"]},
	{"name": "ASHMERE ESTATE", "area": "ashmere", "landmarks": ["Maggie's workshop / west", "Bellwether school / north-west", "Clinic / south-east", "Wrenfield road / east"]},
	{"name": "WRENFIELD RELAY FIELD", "area": "broadcast", "landmarks": ["West cable house", "Public repeater / south-west", "East lay-by", "Tollard Exchange / north"]},
	{"name": "TOLLARD EXCHANGE", "area": "choir", "landmarks": ["Entry switchyard / south", "Records cage / west", "Cooling cells / east", "Incident control / north"]},
]

@onready var _plot = $Card/Margin/Layout/Body/MapColumn/Plot
@onready var _region: Label = $Card/Margin/Layout/Header/Region
@onready var _landmarks: Label = $Card/Margin/Layout/Body/Notes/Landmarks
@onready var _objective: Label = $Card/Margin/Layout/Body/Notes/Objective
@onready var _objective_location: Label = $Card/Margin/Layout/Body/Notes/ObjectiveLocation
@onready var _lead: Label = $Card/Margin/Layout/Body/Notes/Lead
@onready var _lead_location: Label = $Card/Margin/Layout/Body/Notes/LeadLocation
@onready var _back: Button = $Card/Margin/Layout/Back
@onready var _card: PanelContainer = $Card
@onready var _margin: MarginContainer = $Card/Margin
@onready var _header: BoxContainer = $Card/Margin/Layout/Header
@onready var _body: BoxContainer = $Card/Margin/Layout/Body
@onready var _map_column: VBoxContainer = $Card/Margin/Layout/Body/MapColumn
@onready var _notes: VBoxContainer = $Card/Margin/Layout/Body/Notes
@onready var _plot_control: Control = $Card/Margin/Layout/Body/MapColumn/Plot
@onready var _legend: Label = $Card/Margin/Layout/Body/MapColumn/Legend
@onready var _heading: Label = $Card/Margin/Layout/Header/Title/Heading
@onready var _eyebrow: Label = $Card/Margin/Layout/Header/Title/Eyebrow
@onready var _surface: FieldDocumentSurface = $Card/Surface
@onready var _landmark_header: Label = $Card/Margin/Layout/Body/Notes/LandmarkHeader
@onready var _objective_header: Label = $Card/Margin/Layout/Body/Notes/ObjectiveHeader
@onready var _lead_header: Label = $Card/Margin/Layout/Body/Notes/LeadHeader


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_back.pressed.connect(close_map)
	get_viewport().size_changed.connect(_apply_responsive_layout)
	_apply_responsive_layout()
	visible = false


func open_map() -> void:
	_refresh()
	visible = true
	_back.grab_focus()
	AudioManager.play(&"map_open")


func close_map() -> void:
	if not visible:
		return
	visible = false
	AudioManager.play(&"ui_back", -4.0)
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("map") or event.is_action_pressed("pause")):
		get_viewport().set_input_as_handled()
		close_map()


func _refresh() -> void:
	var index := _region_index()
	var reached := _furthest_region(index)
	var info: Dictionary = REGION_INFO[index]
	_region.text = _human_case(String(info.name))
	var landmark_lines := PackedStringArray()
	for landmark in Array(info.landmarks):
		landmark_lines.append("- " + String(landmark))
	_landmarks.text = "\n".join(landmark_lines)
	_plot.set_progress(index, reached)
	var objective := CampaignSystem.get_objective()
	_objective.text = String(objective.get("text", "Find a road that still agrees with its signs."))
	_objective_location.text = _human_case(String(objective.get("location", "Location unconfirmed")))
	var optional := CampaignSystem.get_optional_focus()
	if optional.is_empty():
		_lead.text = "No open local lead"
		_lead_location.text = "Sweep the area or check the field archive."
	else:
		_lead.text = String(optional.get("task", optional.get("label", "Field lead")))
		_lead_location.text = _human_case(String(optional.get("location", "Location unconfirmed")))


func _human_case(value: String) -> String:
	if value == value.to_upper():
		return value.to_lower().capitalize()
	return value


func apply_responsive_layout(
		viewport_size: Vector2,
		window_size: Vector2 = Vector2.ZERO,
	) -> void:
	_apply_responsive_layout(viewport_size, window_size)


func _apply_responsive_layout(
		size_override: Vector2 = Vector2.ZERO,
		window_override: Vector2 = Vector2.ZERO,
	) -> void:
	if not is_node_ready():
		return
	var view := size_override if size_override != Vector2.ZERO else get_viewport_rect().size
	var window_size := window_override if window_override != Vector2.ZERO else (
		Vector2(DisplayServer.window_get_size()) if size_override == Vector2.ZERO else view)
	var physical := _physical_scale(view, window_size)
	var ui_scale := clampf(0.92 / physical, 1.0, 3.2)
	var narrow := window_size.x < 760.0
	var shallow := window_size.y < 520.0
	var compact := narrow or shallow
	var portrait := window_size.y > window_size.x
	var edge := (10.0 if compact else 50.0) * ui_scale
	_card.custom_minimum_size = Vector2(
		clampf(view.x - edge * 2.0, 300.0 * ui_scale, 1090.0 * ui_scale),
		clampf(view.y - edge * 2.0, 300.0 * ui_scale, 700.0 * ui_scale),
	)
	var margin := roundi((13.0 if compact else 32.0) * ui_scale)
	_margin.add_theme_constant_override("margin_left", margin if compact else roundi(46.0 * ui_scale))
	_margin.add_theme_constant_override("margin_right", margin)
	_margin.add_theme_constant_override("margin_top", roundi((12.0 if compact else 26.0) * ui_scale))
	_margin.add_theme_constant_override("margin_bottom", roundi((12.0 if compact else 24.0) * ui_scale))
	_header.vertical = narrow and portrait
	_body.vertical = narrow and portrait
	_body.add_theme_constant_override("separation", roundi((8.0 if compact else 24.0) * ui_scale))
	_map_column.add_theme_constant_override("separation", roundi(8.0 * ui_scale))
	_notes.add_theme_constant_override("separation", roundi(7.0 * ui_scale))
	_map_column.custom_minimum_size = Vector2(0.0 if compact else 630.0, 0.0)
	_notes.custom_minimum_size = Vector2(
		0.0 if narrow else (220.0 if shallow else 330.0),
		0.0,
	)
	_plot_control.custom_minimum_size = Vector2(
		0.0 if compact else 630.0,
		(145.0 if narrow and portrait else (180.0 if shallow else 350.0)) * ui_scale,
	)
	_heading.add_theme_font_size_override("font_size", roundi((22.0 if compact else 30.0) * ui_scale))
	_eyebrow.add_theme_font_size_override("font_size", roundi((9.0 if compact else 11.0) * ui_scale))
	_region.add_theme_font_size_override("font_size", roundi((11.0 if compact else 14.0) * ui_scale))
	_region.custom_minimum_size.x = 0.0 if narrow and portrait else (150.0 if compact else 190.0)
	_region.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if narrow and portrait else HORIZONTAL_ALIGNMENT_RIGHT
	_region.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_landmark_header.add_theme_font_size_override("font_size", roundi(10.0 * ui_scale))
	_landmarks.add_theme_font_size_override("font_size", roundi(12.0 * ui_scale))
	_objective_header.add_theme_font_size_override("font_size", roundi(10.0 * ui_scale))
	_objective.add_theme_font_size_override("font_size", roundi(14.0 * ui_scale))
	_objective_location.add_theme_font_size_override("font_size", roundi(10.0 * ui_scale))
	_lead_header.add_theme_font_size_override("font_size", roundi(10.0 * ui_scale))
	_lead.add_theme_font_size_override("font_size", roundi(12.0 * ui_scale))
	_lead_location.add_theme_font_size_override("font_size", roundi(10.0 * ui_scale))
	_legend.add_theme_font_size_override("font_size", roundi(10.0 * ui_scale))
	_legend.visible = not shallow
	_landmarks.visible = not shallow
	_landmark_header.visible = not shallow
	$Card/Margin/Layout/Body/Notes/ObjectiveRule.visible = not shallow
	$Card/Margin/Layout/Body/Notes/LeadLocation.visible = not shallow
	_back.custom_minimum_size = Vector2(
		(176.0 if compact else 220.0) * ui_scale,
		maxf(48.0 * ui_scale, 44.0 / physical),
	)
	_back.add_theme_font_size_override("font_size", roundi(14.0 * ui_scale))
	if _plot.has_method("set_ui_scale"):
		_plot.set_ui_scale(ui_scale)
	_surface.show_receiver_rail = not compact
	_surface.queue_redraw()


func _physical_scale(view: Vector2, window_size: Vector2) -> float:
	if view.x <= 1.0 or view.y <= 1.0 or window_size.x <= 1.0 or window_size.y <= 1.0:
		return 1.0
	return maxf(0.05, minf(window_size.x / view.x, window_size.y / view.y))


func _region_index() -> int:
	var main := get_tree().get_first_node_in_group("main")
	var path := ""
	if main != null and main.has_method("get_current_level_path"):
		path = String(main.get_current_level_path())
	if path.ends_with("railhome_base.tscn"): return 0
	if path.ends_with("ashmere_verge.tscn"): return 2
	if path.ends_with("broadcast_fields.tscn"): return 3
	if path.ends_with("choir_core.tscn"): return 4
	return 1


func _furthest_region(current: int) -> int:
	if WorldState.has_flag(&"broadcast_opened") or CampaignSystem.get_restored_relay_count() > 0:
		return maxi(current, 3)
	if WorldState.has_flag(&"ashmere_opened") or WorldState.has_flag(&"mara_contacted"):
		return maxi(current, 2)
	return maxi(current, 1)
