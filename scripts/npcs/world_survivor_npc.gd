class_name WorldSurvivorNPC
extends Interactable
## Persistent, route-aware survivor actor shared by field and Railhome scenes.
##
## This is deliberately not a quest-vendor loop. The first conversation asks
## for a material decision, that decision moves the actor, and later talks
## expose a character-specific service plus reactions to the chosen route.

const GRID_SIZE := 4
const WALK_FRAME_TIME := 0.17
const NPCServiceRulesScript = preload("res://scripts/narrative/npc_service_rules.gd")

@export var profile: WorldNPCProfile
@export var population_id: StringName = &""
@export_enum("home", "settlement", "presence") var location_mode: String = "home"
@export var schedule_home: Vector2 = Vector2.ZERO
@export var schedule_work: Vector2 = Vector2(58, -18)
@export var schedule_settled: Vector2 = Vector2(-36, 12)
@export var schedule_ignored: Vector2 = Vector2(92, 36)
@export var schedule_period: float = 11.0
@export var walk_speed: float = 42.0

@onready var _visual: Sprite2D = $Visual
@onready var _shadow: Polygon2D = $ContactShadow
@onready var _service_lamp: Polygon2D = $ServiceLamp

var _anchor_position := Vector2.ZERO
var _schedule_clock := 0.0
var _schedule_at_work := false
var _target_position := Vector2.ZERO
var _frame := 0
var _frame_clock := 0.0
var _facing_row := 0
var _dialogue_player: Node2D


func _ready() -> void:
	if profile == null:
		push_error("WorldSurvivorNPC '%s' has no profile." % name)
		visible = false
		monitorable = false
		return
	_anchor_position = position
	_schedule_clock = float(abs(String(profile.npc_id).hash()) % 700) / 100.0
	add_to_group("world_npcs")
	add_to_group("objective_targets")
	add_to_group("npc_services")
	set_meta("npc_id", profile.npc_id)
	set_meta("population_id", population_id)
	set_meta("service_id", profile.service_id)
	set_meta("story_reason", profile.story_reason)
	set_meta("sprite_atlas", profile.sprite_atlas.resource_path if profile.sprite_atlas != null else "")
	set_meta("silhouette_signature", profile.silhouette_signature)
	set_meta("schedule", "%s:%s" % [location_mode, profile.role])
	_apply_identity_visuals()
	_refresh_state(true)
	_update_schedule_target(true)
	EventBus.dialogue_finished.connect(_on_dialogue_finished)
	EventBus.campaign_progress_changed.connect(_on_campaign_progress_changed)
	EventBus.narrative_state_changed.connect(_on_narrative_state_changed)


func _process(delta: float) -> void:
	if profile == null:
		return
	_refresh_state(false)
	if not visible:
		return
	_schedule_clock += delta
	if schedule_period > 0.0 and _schedule_clock >= schedule_period:
		_schedule_clock = fmod(_schedule_clock, schedule_period)
		_schedule_at_work = not _schedule_at_work
		_update_schedule_target(false)
	var before := position
	position = position.move_toward(_target_position, walk_speed * delta)
	var movement := position - before
	_update_animation(movement, delta)


func is_available() -> bool:
	return visible and not GameManager.dialogue_active and not GameManager.ending_active


func get_prompt() -> String:
	if profile == null:
		return prompt
	if _is_ignored() and not _is_helped():
		return "One last word with %s" % profile.display_name
	if _is_helped():
		return "Ask %s about %s" % [profile.display_name, profile.service_name]
	return "Speak with %s" % profile.display_name


func interact(player: Node2D) -> void:
	if not is_available() or profile == null:
		return
	_dialogue_player = player
	GameManager.set_dialogue_active(true)
	EventBus.dialogue_requested.emit(get_dialogue_payload())


func get_dialogue_payload() -> Dictionary:
	if profile == null:
		return {}
	var lines: Array[String] = []
	var choices: Array[String] = []
	if _is_helped():
		lines.append(profile.greeting)
		lines.append_array(profile.helped_lines)
		lines.append_array(_route_reaction_lines())
		lines.append_array(profile.service_lines)
		choices = [profile.service_choice, "JUST TALK"]
	elif _is_ignored():
		lines.append(profile.greeting)
		lines.append_array(profile.ignored_lines)
		lines.append_array(_route_reaction_lines())
		choices = [profile.help_choice, "LET THE DECISION STAND"]
	else:
		lines.append(profile.greeting)
		lines.append_array(profile.intro_lines)
		lines.append_array(_route_reaction_lines())
		choices = [profile.help_choice, profile.ignore_choice]
	return {
		"id": profile.story_id(),
		"title": "%s / %s" % [profile.display_name.to_upper(), profile.role.to_upper()],
		"lines": lines,
		"choices": choices,
		"accent": profile.identity_accent,
	}


func get_state_name() -> StringName:
	if _is_helped():
		return &"helped"
	if _is_ignored():
		return &"ignored"
	return &"unresolved"


func get_route_reaction_signature() -> String:
	return "|".join(_route_reaction_lines())


func resolve_helped(persist: bool = true) -> void:
	if profile == null:
		return
	WorldState.set_flag(profile.helped_flag)
	WorldState.set_flag(profile.ignored_flag, false)
	WorldState.set_flag(profile.state_flag("decision"), "helped")
	_sync_narrative_decision(true)
	EventBus.notice_posted.emit("%s will bring %s to Railhome." % [profile.display_name, profile.service_name])
	_refresh_state(true)
	_update_schedule_target(true)
	if persist:
		_save_if_running()


func resolve_ignored(persist: bool = true) -> void:
	if profile == null:
		return
	WorldState.set_flag(profile.ignored_flag)
	WorldState.set_flag(profile.helped_flag, false)
	WorldState.set_flag(profile.state_flag("decision"), "ignored")
	_sync_narrative_decision(false)
	EventBus.notice_posted.emit("You leave %s at %s. Their %s will not be waiting at Railhome." % [
		profile.display_name, _location_label(), profile.service_name,
	])
	_refresh_state(true)
	_update_schedule_target(true)
	if persist:
		_save_if_running()


func use_service(player: Node2D = null, persist: bool = true) -> void:
	if profile == null or not _is_helped():
		return
	var service_player := player if player != null else _dialogue_player
	WorldState.set_flag(profile.service_flag)
	WorldState.set_flag(profile.state_flag("service_uses"), int(WorldState.get_flag(profile.state_flag("service_uses"), 0)) + 1)
	match profile.service_id:
		&"field_triage":
			if service_player != null and service_player.has_method("heal_full"):
				service_player.call("heal_full")
		&"carrier_forecast":
			WorldState.set_flag(&"npc_service_carrier_window", String(CampaignSystem.get_active_route_id()))
		&"witness_ledger":
			WorldState.set_flag(&"npc_service_evidence_confidence", CampaignSystem.get_evidence_confidence())
		&"grid_survey":
			WorldState.set_flag(&"npc_service_safe_grid_route", String(CampaignSystem.get_active_route_id()))
		&"coach_passages":
			WorldState.set_flag(&"npc_service_safe_passage", true)
		&"shelter_repair":
			WorldState.set_flag(&"railhome_recovery_bonus", 25)
		&"lockwork":
			WorldState.set_flag(&"mechanical_bypass_available", true)
		&"wire_warning":
			WorldState.set_flag(&"ambush_warning_active", true)
		&"field_defence":
			WorldState.set_flag(&"carrier_lure_defence_active", true)
			WorldState.set_flag(&"hollow_tracking_active", true)
		&"identity_checksum":
			WorldState.set_flag(&"identity_checksum", {
				"evidence_confidence": CampaignSystem.get_evidence_confidence(),
				"fed_traces": CampaignSystem.get_fed_trace_count(),
				"route_id": String(CampaignSystem.get_active_route_id()),
			})
	var consequence := NPCServiceRulesScript.effect_notice(profile.service_id)
	var notice := profile.service_notice
	if not consequence.is_empty():
		notice += "\n" + consequence
	EventBus.notice_posted.emit(notice)
	_refresh_state(true)
	if persist:
		_save_if_running()


func _on_dialogue_finished(story_id: StringName, choice_index: int) -> void:
	if profile == null or story_id != profile.story_id():
		return
	GameManager.set_dialogue_active(false)
	if choice_index < 0:
		return
	if _is_helped():
		if choice_index == 0:
			use_service(_dialogue_player)
	elif _is_ignored():
		if choice_index == 0:
			resolve_helped()
	elif choice_index == 0:
		resolve_helped()
	elif choice_index == 1:
		resolve_ignored()


func _is_helped() -> bool:
	if profile == null:
		return false
	if profile.helped_flag != &"" and WorldState.has_flag(profile.helped_flag):
		return true
	if profile.legacy_helped_flag != &"" and WorldState.has_flag(profile.legacy_helped_flag):
		return true
	var narrative_state := StringName(CampaignSystem.get_narrative_npc_state(_narrative_npc_id()))
	return narrative_state == &"rescued"


func _is_ignored() -> bool:
	if profile == null:
		return false
	if profile.ignored_flag != &"" and WorldState.has_flag(profile.ignored_flag):
		return true
	var narrative_state := StringName(CampaignSystem.get_narrative_npc_state(_narrative_npc_id()))
	return narrative_state in [&"left", &"estranged", &"dead"]


func _refresh_state(force: bool) -> void:
	var should_show := true
	if profile.relocates_to_railhome:
		if location_mode == "home":
			should_show = not _is_helped()
		elif location_mode == "settlement":
			should_show = _is_helped()
	visible = should_show
	monitorable = should_show
	if _shadow != null:
		_shadow.visible = should_show
	if _service_lamp != null:
		_service_lamp.visible = should_show and _is_helped()
		_service_lamp.color = profile.identity_accent if not WorldState.has_flag(profile.service_flag) else profile.identity_accent.lightened(0.3)
	if _visual != null:
		_visual.modulate = Color(0.52, 0.54, 0.55, 0.82) if _is_ignored() and not _is_helped() else Color.WHITE
	if force:
		set_meta("npc_state", get_state_name())
		set_meta("service_active", WorldState.has_flag(profile.service_flag))


func _update_schedule_target(snap: bool) -> void:
	var offset := schedule_home
	if _is_ignored() and not _is_helped():
		offset = schedule_ignored
	elif location_mode == "settlement":
		offset = schedule_work if _schedule_at_work else schedule_settled
	elif location_mode == "presence":
		offset = schedule_work if _schedule_at_work else schedule_home
	else:
		offset = schedule_work if _schedule_at_work else schedule_home
	_target_position = _anchor_position + offset
	if snap:
		position = _target_position
	set_meta("schedule_phase", "work" if _schedule_at_work else "rest")


func _route_reaction_lines() -> Array[String]:
	var lines: Array[String] = []
	if profile == null:
		return lines
	var state := CampaignSystem.get_narrative_state()
	var anchor := String(state.get("route_anchor", ""))
	var strategy := String(state.get("network_strategy", ""))
	if not anchor.is_empty():
		var anchor_line := String(profile.anchor_lines.get(anchor, ""))
		if not anchor_line.is_empty():
			lines.append(anchor_line)
	if not strategy.is_empty():
		var strategy_line := String(profile.strategy_lines.get(strategy, ""))
		if not strategy_line.is_empty():
			lines.append(strategy_line)
	return lines


func _apply_identity_visuals() -> void:
	_visual.texture = profile.sprite_atlas
	_visual.visible = profile.sprite_atlas != null
	_update_region()


func _update_animation(movement: Vector2, delta: float) -> void:
	if movement.length_squared() > 0.005:
		_facing_row = _row_for_direction(movement)
		_frame_clock += delta
		if _frame_clock >= WALK_FRAME_TIME:
			_frame_clock = 0.0
			_frame = (_frame + 1) % GRID_SIZE
	else:
		_frame_clock += delta
		if _frame_clock >= 0.72:
			_frame_clock = 0.0
			_frame = (_frame + 1) % GRID_SIZE
	_update_region()


func _row_for_direction(direction: Vector2) -> int:
	if absf(direction.x) > absf(direction.y):
		return 3 if direction.x > 0.0 else 2
	return 0 if direction.y >= 0.0 else 1


func _update_region() -> void:
	if _visual == null or _visual.texture == null:
		return
	var cell := _visual.texture.get_size() / float(GRID_SIZE)
	_visual.region_rect = Rect2(Vector2(_frame, _facing_row) * cell, cell)


func _location_label() -> String:
	return String(profile.home_region).replace("_", " ").capitalize()


func _narrative_npc_id() -> StringName:
	if profile == null:
		return &""
	return &"maggie_copy" if profile.npc_id == &"continuity" else profile.npc_id


func _sync_narrative_decision(helped: bool) -> void:
	var narrative_id := _narrative_npc_id()
	if narrative_id == &"":
		return
	if helped:
		if narrative_id == &"maggie_copy":
			CampaignSystem.set_narrative_npc_state(narrative_id, &"active", false)
		else:
			CampaignSystem.rescue_narrative_npc(narrative_id, false)
	else:
		CampaignSystem.set_narrative_npc_state(narrative_id, &"left", false)


func _save_if_running() -> void:
	if get_tree().get_first_node_in_group("main") != null:
		SaveManager.save_game("")


func _on_campaign_progress_changed() -> void:
	_refresh_state(true)
	_update_schedule_target(false)


func _on_narrative_state_changed(_snapshot: Dictionary) -> void:
	_refresh_state(true)
	_update_schedule_target(false)
