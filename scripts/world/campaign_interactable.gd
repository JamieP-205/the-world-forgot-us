class_name CampaignInteractable
extends Interactable
## Story terminal / gate shared by the authored campaign maps.

@export var story_id: StringName = &""
@export var accent: Color = Color(0.38, 0.90, 0.94, 1.0)

@onready var _core: Polygon2D = $Visual/Core
@onready var _ring: Polygon2D = $Visual/Ring

var _time := 0.0


func _ready() -> void:
	add_to_group("objective_targets")
	# Runtime-authored campaign maps and the HUD resolve targets through stable
	# metadata; keep it in sync with the exported story id for every scene.
	set_meta("story_id", story_id)
	if _core != null:
		_core.color = accent
	if _ring != null:
		_ring.color = Color(accent, 0.42)


func _process(delta: float) -> void:
	_time += delta
	if _ring != null:
		_ring.rotation = _time * 0.42
		_ring.scale = Vector2.ONE * (1.0 + sin(_time * 2.6) * 0.07)
	if _core != null:
		_core.modulate.a = 0.72 + sin(_time * 3.4) * 0.24


func is_available() -> bool:
	return CampaignSystem.can_interact(story_id)


func get_prompt() -> String:
	return CampaignSystem.get_prompt(story_id, prompt)


func interact(_player: Node2D) -> void:
	CampaignSystem.request_interaction(story_id)
