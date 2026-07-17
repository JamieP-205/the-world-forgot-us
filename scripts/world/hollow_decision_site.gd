class_name HollowDecisionSite
extends Interactable
## A living Hollow caught between commands. The player chooses a policy here;
## it is not a coloured pickup or an abstract menu detached from the world.

@onready var _body: Sprite2D = $Body


func _ready() -> void:
	add_to_group("objective_targets")
	set_meta("story_id", &"wrenfield_recoverable_hollow")
	if _body.texture != null:
		var frame := _body.texture.get_size() / 4.0
		_body.region_rect = Rect2(Vector2.ZERO, frame)
	_refresh()
	EventBus.narrative_state_changed.connect(_on_narrative_state_changed)


func is_available() -> bool:
	return visible and CampaignSystem.can_interact(&"wrenfield_recoverable_hollow")


func get_prompt() -> String:
	return CampaignSystem.get_prompt(&"wrenfield_recoverable_hollow", "Approach the grounded Hollow")


func interact(_player: Node2D) -> void:
	CampaignSystem.request_interaction(&"wrenfield_recoverable_hollow")


func _refresh() -> void:
	var resolved := CampaignSystem.get_hollow_policy() != &"undecided"
	set_meta("resolved", resolved)
	_body.modulate = Color(0.72, 0.78, 0.76, 0.72) if resolved else Color.WHITE


func _on_narrative_state_changed(_snapshot: Dictionary) -> void:
	_refresh()
