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


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_back.pressed.connect(close_map)
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
	_region.text = String(info.name)
	var landmark_lines := PackedStringArray()
	for landmark in Array(info.landmarks):
		landmark_lines.append("- " + String(landmark))
	_landmarks.text = "\n".join(landmark_lines)
	_plot.set_progress(index, reached)
	var objective := CampaignSystem.get_objective()
	_objective.text = String(objective.get("text", "Find a road that still agrees with its signs."))
	_objective_location.text = String(objective.get("location", "LOCATION UNCONFIRMED"))
	var optional := CampaignSystem.get_optional_focus()
	if optional.is_empty():
		_lead.text = "No open local lead"
		_lead_location.text = "Sweep the area or check the field archive."
	else:
		_lead.text = String(optional.get("task", optional.get("label", "Field lead")))
		_lead_location.text = String(optional.get("location", "LOCATION UNCONFIRMED"))


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
