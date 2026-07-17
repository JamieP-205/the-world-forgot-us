class_name SurvivorNPC
extends Interactable
## Authored survivor who can converse, then physically follow the player.
## The atlas is a four-by-four sheet: down, up, left, right rows.

@export var story_id: StringName = &""
@export var survivor_name: String = "Survivor"
@export var quest_data: QuestData
@export var follow_flag: StringName = &""
@export var resolved_flag: StringName = &""
@export var visible_if_flag: StringName = &""
@export var hidden_if_flag: StringName = &""
@export var follow_speed: float = 118.0
@export var desired_distance: float = 76.0
@export var catch_up_distance: float = 390.0
@export var world_profile: WorldNPCProfile

@onready var _visual: Sprite2D = $Visual
@onready var _shadow: Polygon2D = $ContactShadow

const GRID_SIZE := 4
var _frame := 0
var _frame_time := 0.0
var _facing_row := 0
var _last_position := Vector2.ZERO


func _ready() -> void:
	add_to_group("quest_npcs")
	add_to_group("objective_targets")
	set_meta("story_id", story_id)
	if world_profile != null:
		add_to_group("world_npcs")
		set_meta("npc_id", world_profile.npc_id)
		set_meta("service_id", world_profile.service_id)
		set_meta("story_reason", world_profile.story_reason)
		set_meta("sprite_atlas", world_profile.sprite_atlas.resource_path if world_profile.sprite_atlas != null else "")
		set_meta("silhouette_signature", world_profile.silhouette_signature)
		if world_profile.sprite_atlas != null:
			_visual.texture = world_profile.sprite_atlas
		_visual.modulate = Color.WHITE
	_last_position = global_position
	_refresh_visibility()
	_update_region()


func _physics_process(delta: float) -> void:
	_refresh_visibility()
	if not visible:
		return
	var movement := Vector2.ZERO
	if _is_following():
		var player := get_tree().get_first_node_in_group("player") as Node2D
		if player != null:
			var offset := player.global_position - global_position
			if offset.length() > catch_up_distance:
				global_position = player.global_position - offset.normalized() * desired_distance
			elif offset.length() > desired_distance:
				movement = offset.normalized() * follow_speed * delta
				global_position += movement
	if movement.length_squared() > 0.01:
		_facing_row = _row_for_direction(movement)
		_frame_time += delta
		if _frame_time >= 0.18:
			_frame_time = 0.0
			_frame = (_frame + 1) % GRID_SIZE
	else:
		_frame_time += delta
		if _frame_time >= 0.7:
			_frame_time = 0.0
			_frame = (_frame + 1) % GRID_SIZE
	_update_region()
	_last_position = global_position


func is_available() -> bool:
	return visible and CampaignSystem.can_interact(story_id)


func get_prompt() -> String:
	return CampaignSystem.get_prompt(story_id, "Talk to %s" % survivor_name)


func interact(_player: Node2D) -> void:
	CampaignSystem.request_interaction(story_id)


func _is_following() -> bool:
	return (
		follow_flag != &""
		and WorldState.has_flag(follow_flag)
		and (resolved_flag == &"" or not WorldState.has_flag(resolved_flag))
	)


func _refresh_visibility() -> void:
	var should_show := true
	if visible_if_flag != &"" and not WorldState.has_flag(visible_if_flag):
		should_show = false
	if hidden_if_flag != &"" and WorldState.has_flag(hidden_if_flag):
		should_show = false
	visible = should_show
	monitorable = should_show
	if _shadow != null:
		_shadow.visible = should_show


func _row_for_direction(direction: Vector2) -> int:
	if absf(direction.x) > absf(direction.y):
		return 3 if direction.x > 0.0 else 2
	return 0 if direction.y >= 0.0 else 1


func _update_region() -> void:
	if _visual == null or _visual.texture == null:
		return
	var size := _visual.texture.get_size()
	var cell := size / float(GRID_SIZE)
	_visual.region_rect = Rect2(Vector2(_frame, _facing_row) * cell, cell)


func get_world_npc_id() -> StringName:
	return world_profile.npc_id if world_profile != null else &""
