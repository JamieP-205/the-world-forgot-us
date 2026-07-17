extends Node
## Autoload: CraftedItemEffects
##
## Validates crafted-output behaviours, reports why an item can or cannot be
## used, and applies each use without ever losing an item on a rejected target.

signal effect_used(item_id: StringName, effect_kind: StringName, payload: Dictionary)
signal effect_rejected(item_id: StringName, code: StringName)
signal contextual_item_applied(item_id: StringName, target: Node)
signal receiver_stability_changed(strength: float, seconds_remaining: float)
signal ash_protection_changed(resistance: float, seconds_remaining: float)
signal field_effect_deployed(item_id: StringName, effect_kind: StringName, effect: Node2D)
signal field_pulse(effect_kind: StringName, position: Vector2, radius: float, affected_count: int)

const EFFECTS_DIR := "res://resources/item_effects"

const OK := &"ok"
const UNKNOWN_EFFECT := &"unknown_effect"
const NOT_OWNED := &"not_owned"
const NO_ACTOR := &"no_actor"
const NOT_NEEDED := &"not_needed"
const NEEDS_TARGET := &"needs_target"
const TARGET_REJECTED := &"target_rejected"
const ON_COOLDOWN := &"on_cooldown"
const INVENTORY_CHANGED := &"inventory_changed"
const APPLY_FAILED := &"apply_failed"

var _effects: Dictionary = {}
var _ordered_ids: Array[StringName] = []
var _validation_errors := PackedStringArray()
var _cooldown_until: Dictionary = {}
var _receiver_stability := 0.0
var _receiver_stability_until := 0
var _ash_resistance := 0.0
var _ash_protection_until := 0


func _ready() -> void:
	_load_effects()


func has_effect(item_id: StringName) -> bool:
	return _effects.has(item_id)


func get_definition(item_id: StringName) -> CraftedItemEffectData:
	return _effects.get(item_id)


func get_effect_item_ids() -> Array[StringName]:
	return _ordered_ids.duplicate()


func get_validation_errors() -> PackedStringArray:
	return _validation_errors.duplicate()


func validate_definition(data: CraftedItemEffectData) -> PackedStringArray:
	var errors := PackedStringArray()
	if data == null:
		errors.append("resource is not CraftedItemEffectData")
		return errors
	if data.item_id == &"" or not ItemDatabase.has_item(data.item_id):
		errors.append("item id is empty or unknown")
	if data.effect_kind == &"":
		errors.append("effect kind is empty")
	if data.action_label.strip_edges().is_empty():
		errors.append("action label is empty")
	if data.use_summary.strip_edges().is_empty():
		errors.append("use summary is empty")
	if data.consequence.strip_edges().is_empty():
		errors.append("consequence is empty")
	if _is_contextual(data.effect_kind) and data.target_group == &"":
		errors.append("contextual effect has no target group")
	return errors


func get_status(item_id: StringName, context: Dictionary = {}) -> Dictionary:
	var data := get_definition(item_id)
	if data == null:
		return _status(false, UNKNOWN_EFFECT, "No field use is defined for this item.")
	if InventorySystem.get_count(item_id) <= 0:
		return _status(false, NOT_OWNED, "Make or recover one before trying to use it.", data)
	var cooldown := get_cooldown_remaining(item_id)
	if cooldown > 0.0:
		var waiting := _status(false, ON_COOLDOWN, "The tool needs %.1f seconds before another reading." % cooldown, data)
		waiting["cooldown"] = cooldown
		return waiting

	var actor := _resolve_actor(context)
	if actor == null:
		return _status(false, NO_ACTOR, "No field operator is available.", data)
	if data.effect_kind == &"heal":
		if not actor.has_method("get_health") or not actor.has_method("set_health"):
			return _status(false, NO_ACTOR, "The field dressing needs a living operator.", data)
		var current := float(actor.call("get_health"))
		var maximum := float(context.get("max_health", 100.0))
		if actor.has_method("get_max_health"):
			maximum = float(actor.call("get_max_health"))
		if current >= maximum:
			return _status(false, NOT_NEEDED, "No wound needs binding.", data)
	if _is_contextual(data.effect_kind):
		var target := _resolve_target(data, actor, context)
		if target == null:
			return _status(false, NEEDS_TARGET, data.target_prompt, data)
		if not _target_accepts(target, item_id):
			return _status(false, TARGET_REJECTED, "That fitting cannot use this tool.", data)
		var ready_target := _status(true, OK, "Ready.", data)
		ready_target["target"] = target
		ready_target["actor"] = actor
		return ready_target

	var ready := _status(true, OK, "Ready.", data)
	ready["actor"] = actor
	return ready


func use_item(item_id: StringName, context: Dictionary = {}) -> Dictionary:
	var status := get_status(item_id, context)
	if not bool(status.get("ok", false)):
		effect_rejected.emit(item_id, StringName(status.get("code", UNKNOWN_EFFECT)))
		return status
	var data: CraftedItemEffectData = status["definition"]
	if data.consumes_on_use and not InventorySystem.remove_items_atomic({item_id: 1}):
		var changed := _status(false, INVENTORY_CHANGED, "The item is no longer in the field kit.", data)
		effect_rejected.emit(item_id, INVENTORY_CHANGED)
		return changed

	var payload := _build_payload(data, status, context)
	if not _apply_effect(data, payload):
		if data.consumes_on_use and not InventorySystem.add_items_atomic({item_id: 1}):
			push_error("CraftedItemEffects: could not roll back rejected use of '%s'." % item_id)
		var failed := _status(false, APPLY_FAILED, "The item could not be applied here.", data)
		effect_rejected.emit(item_id, APPLY_FAILED)
		return failed

	if data.cooldown_seconds > 0.0:
		_cooldown_until[item_id] = Time.get_ticks_msec() + roundi(data.cooldown_seconds * 1000.0)
	effect_used.emit(item_id, data.effect_kind, payload)
	status["payload"] = payload
	status["reason"] = data.consequence
	return status


func get_cooldown_remaining(item_id: StringName) -> float:
	return maxf(float(int(_cooldown_until.get(item_id, 0)) - Time.get_ticks_msec()) / 1000.0, 0.0)


func get_receiver_stability() -> float:
	if Time.get_ticks_msec() >= _receiver_stability_until:
		return 0.0
	return _receiver_stability


func get_receiver_energy_cost_multiplier() -> float:
	return lerpf(1.0, 0.62, clampf(get_receiver_stability(), 0.0, 1.0))


func get_receiver_recharge_multiplier() -> float:
	return 1.0 + clampf(get_receiver_stability(), 0.0, 1.0) * 0.65


func get_ash_resistance() -> float:
	if Time.get_ticks_msec() >= _ash_protection_until:
		return 0.0
	return _ash_resistance


func get_ash_damage_multiplier() -> float:
	return 1.0 - clampf(get_ash_resistance(), 0.0, 0.9)


func report_field_pulse(kind: StringName, position: Vector2, pulse_radius: float, affected: int) -> void:
	field_pulse.emit(kind, position, pulse_radius, affected)


func clear_runtime_state() -> void:
	_cooldown_until.clear()
	_receiver_stability = 0.0
	_receiver_stability_until = 0
	_ash_resistance = 0.0
	_ash_protection_until = 0
	for effect in get_tree().get_nodes_in_group("crafted_field_effects"):
		if is_instance_valid(effect):
			effect.queue_free()


func _load_effects() -> void:
	_effects.clear()
	_ordered_ids.clear()
	_validation_errors.clear()
	var dir := DirAccess.open(EFFECTS_DIR)
	if dir == null:
		_validation_errors.append("Cannot open item-effect directory: %s" % EFFECTS_DIR)
		return
	var files := dir.get_files()
	files.sort()
	for file_name in files:
		var resource_name := file_name.trim_suffix(".remap")
		if not resource_name.ends_with(".tres"):
			continue
		var data := load("%s/%s" % [EFFECTS_DIR, resource_name]) as CraftedItemEffectData
		var errors := validate_definition(data)
		if not errors.is_empty():
			for error in errors:
				_validation_errors.append("%s: %s" % [resource_name, error])
			continue
		if _effects.has(data.item_id):
			_validation_errors.append("%s: duplicate item effect '%s'" % [resource_name, data.item_id])
			continue
		_effects[data.item_id] = data
	_ordered_ids.assign(_effects.keys())
	_ordered_ids.sort_custom(func(left: StringName, right: StringName) -> bool:
		return String(left) < String(right)
	)


func _build_payload(data: CraftedItemEffectData, status: Dictionary, context: Dictionary) -> Dictionary:
	var actor: Node = status.get("actor")
	var position := Vector2.ZERO
	if context.has("world_position"):
		position = context["world_position"]
	elif actor is Node2D:
		position = (actor as Node2D).global_position
	return {
		"item_id": data.item_id,
		"effect_kind": data.effect_kind,
		"actor": actor,
		"target": status.get("target"),
		"position": position,
		"values": data.values.duplicate(true),
	}


func _apply_effect(data: CraftedItemEffectData, payload: Dictionary) -> bool:
	var actor: Node = payload.get("actor")
	match data.effect_kind:
		&"heal":
			var before := float(actor.call("get_health"))
			actor.call("set_health", before + float(data.values.get("heal", 28.0)))
			payload["health_restored"] = maxf(float(actor.call("get_health")) - before, 0.0)
			return float(payload["health_restored"]) > 0.0
		&"access", &"bridge", &"repair":
			var target: Node = payload.get("target")
			if target == null or not target.has_method("apply_crafted_item"):
				return false
			var result: Variant = target.call("apply_crafted_item", data.item_id, payload)
			if typeof(result) == TYPE_BOOL and not bool(result):
				return false
			contextual_item_applied.emit(data.item_id, target)
			return true
		&"receiver_stability":
			var strength := clampf(float(data.values.get("stability", 0.25)), 0.0, 1.0)
			var duration := maxf(float(data.values.get("duration", 120.0)), 1.0)
			_receiver_stability = maxf(get_receiver_stability(), strength)
			_receiver_stability_until = maxi(_receiver_stability_until, Time.get_ticks_msec() + roundi(duration * 1000.0))
			receiver_stability_changed.emit(_receiver_stability, get_receiver_stability_remaining())
			return true
		&"ash_protection":
			var resistance := clampf(float(data.values.get("resistance", 0.6)), 0.0, 0.9)
			var duration := maxf(float(data.values.get("duration", 180.0)), 1.0)
			_ash_resistance = maxf(get_ash_resistance(), resistance)
			_ash_protection_until = maxi(_ash_protection_until, Time.get_ticks_msec() + roundi(duration * 1000.0))
			ash_protection_changed.emit(_ash_resistance, get_ash_protection_remaining())
			return true
		&"relay_test":
			var position: Vector2 = payload["position"]
			var radius := float(data.values.get("radius", 260.0))
			EventBus.scanner_pulsed.emit(position, radius)
			report_field_pulse(&"relay_test", position, radius, 0)
			return true
		&"signal_decoy", &"flare", &"tripwire_alarm", &"carrier_grounder":
			return _spawn_field_effect(data, payload)
	return false


func get_receiver_stability_remaining() -> float:
	return maxf(float(_receiver_stability_until - Time.get_ticks_msec()) / 1000.0, 0.0)


func get_ash_protection_remaining() -> float:
	return maxf(float(_ash_protection_until - Time.get_ticks_msec()) / 1000.0, 0.0)


func _spawn_field_effect(data: CraftedItemEffectData, payload: Dictionary) -> bool:
	var parent: Node = null
	var main := get_tree().get_first_node_in_group("main")
	if main != null and main.has_method("get_current_level"):
		parent = main.call("get_current_level") as Node
	# Tool scenes and isolated test harnesses do not own Main's level holder.
	# In the game, every deployment belongs to the swappable map so travel
	# removes it before it can pulse actors at matching coordinates elsewhere.
	if parent == null:
		parent = get_tree().current_scene
	if parent == null:
		return false
	var effect := CraftedFieldEffect.new()
	effect.configure(data)
	parent.add_child(effect)
	effect.global_position = payload["position"]
	field_effect_deployed.emit(data.item_id, data.effect_kind, effect)
	payload["field_effect"] = effect
	return true


func _resolve_actor(context: Dictionary) -> Node:
	var supplied: Variant = context.get("player")
	if supplied is Node and is_instance_valid(supplied):
		return supplied
	return get_tree().get_first_node_in_group("player")


func _resolve_target(data: CraftedItemEffectData, actor: Node, context: Dictionary) -> Node:
	var supplied: Variant = context.get("target")
	if supplied is Node and is_instance_valid(supplied):
		return supplied
	if data.target_group == &"" or not actor is Node2D:
		return null
	var maximum := float(data.values.get("range", 96.0))
	var nearest: Node = null
	var nearest_distance := INF
	for candidate in get_tree().get_nodes_in_group(data.target_group):
		if not candidate is Node2D or not is_instance_valid(candidate):
			continue
		# Nearby cabinets can be complete, already bridged, or the wrong kind of
		# fitting. Auto-target the closest usable one instead of letting an
		# ineligible foreground object mask a valid target just behind it.
		if not _target_accepts(candidate, data.item_id):
			continue
		var distance := (actor as Node2D).global_position.distance_to((candidate as Node2D).global_position)
		if distance <= maximum and distance < nearest_distance:
			nearest = candidate
			nearest_distance = distance
	return nearest


func _target_accepts(target: Node, item_id: StringName) -> bool:
	if not target.has_method("can_apply_crafted_item") or not target.has_method("apply_crafted_item"):
		return false
	return bool(target.call("can_apply_crafted_item", item_id))


func _is_contextual(kind: StringName) -> bool:
	return kind in [&"access", &"bridge", &"repair"]


func _status(ok: bool, code: StringName, reason: String, data: CraftedItemEffectData = null) -> Dictionary:
	return {
		"ok": ok,
		"code": code,
		"reason": reason,
		"definition": data,
		"item_id": data.item_id if data != null else &"",
	}
