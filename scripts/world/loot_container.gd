class_name LootContainer
extends Interactable
## A one-shot lootable container (crate, locker, cupboard, car boot...).

const NPCServiceRulesScript = preload("res://scripts/narrative/npc_service_rules.gd")

## Item id -> quantity given when searched. Edit per-instance in the map.
@export var loot: Dictionary = {"scrap": 3}

## Prompt shown after the container has been emptied.
@export var empty_prompt: String = "Empty"

## Stable id for persistence. Empty defaults to the node name (unique in the
## demo), so searched state survives travel and save/load.
@export var persistent_id: StringName = &""

## Optional authored service contracts. Secured caches remain visible and
## explain the missing bypass; coach caches keep their ordinary loot but add
## the labelled parcel when Gwen's passage has been prepared.
@export var required_service_flag: StringName = &""
@export var locked_prompt: String = "Secured - a numbered mechanical bypass is required"
@export var service_bonus_flag: StringName = &""
@export var service_bonus: Dictionary = {}
@export var service_bonus_claim_flag: StringName = &""

var _opened := false

# Node2D so this works whether the Visual is the crate Sprite2D (scene) or
# a lightweight Polygon2D map fixture. Both support modulate.
@onready var _visual: Node2D = $Visual
@onready var _glint: Polygon2D = get_node_or_null("Glint")


func _ready() -> void:
	if persistent_id == &"":
		persistent_id = StringName(name)
	if required_service_flag != &"":
		add_to_group("craft_access_targets")
	# Already searched in a previous visit / earlier session: show it emptied
	# and give no loot again.
	if WorldState.is_opened(persistent_id):
		_opened = true
		_visual.modulate = Color(0.42, 0.45, 0.43)
		if _glint != null:
			_glint.visible = false
		return
	if _glint != null:
		_glint.visible = true
		var tween := create_tween().set_loops()
		tween.tween_property(_glint, "modulate:a", 0.18, 0.75)
		tween.tween_property(_glint, "modulate:a", 0.85, 0.75)


func get_prompt() -> String:
	if _opened:
		return empty_prompt
	if not _has_access():
		return locked_prompt
	return prompt


func interact(_player: Node2D) -> void:
	if _opened:
		EventBus.notice_posted.emit("Already searched.")
		return
	if not _has_access():
		EventBus.notice_posted.emit(
			"The drawer's automatic credential reader is live. Mara's numbered bypass or a hand-cut lock shim would open it without answering Tollard.")
		return
	var recovered := loot.duplicate()
	var grants_service_bonus := service_bonus_flag != &"" \
		and WorldState.has_flag(service_bonus_flag) \
		and (service_bonus_claim_flag == &"" or not WorldState.has_flag(service_bonus_claim_flag))
	if grants_service_bonus:
		for item_id in service_bonus:
			recovered[item_id] = int(recovered.get(item_id, 0)) + int(service_bonus[item_id])
	if not InventorySystem.add_items_atomic(recovered):
		EventBus.notice_posted.emit(
			"The field kit cannot hold everything in this cache. Make room and leave the remainder sealed.")
		return

	_opened = true
	WorldState.mark_opened(persistent_id)
	if grants_service_bonus and service_bonus_claim_flag != &"":
		WorldState.set_flag(service_bonus_claim_flag)

	var parts: Array[String] = []
	for item_id in recovered:
		var amount := int(recovered[item_id])
		var data: ItemData = ItemDatabase.get_item(item_id)
		var label := data.display_name if data != null else String(item_id)
		parts.append("+%d %s" % [amount, label])

	_visual.modulate = Color(0.42, 0.45, 0.43)
	if _glint != null:
		_glint.visible = false
	AudioManager.play(&"pickup")
	var source := "Gwen's blue-tagged coach parcel and the remaining supplies" \
		if grants_service_bonus else "Supplies"
	EventBus.notice_posted.emit(
		"%s recovered: %s. Inventory updated on the left." % [source, ", ".join(parts)])


func can_apply_crafted_item(item_id: StringName) -> bool:
	return item_id == &"lock_shim" and not _opened \
		and required_service_flag != &"" and not _has_access()


func apply_crafted_item(item_id: StringName, _payload: Dictionary) -> bool:
	if not can_apply_crafted_item(item_id):
		return false
	WorldState.set_flag(_crafted_bypass_flag())
	AudioManager.play(&"pickup", -5.0, 0.78)
	EventBus.notice_posted.emit(
		"The shim folds around the last pin. The secured drawer can now be opened by hand.")
	SaveManager.save_game("")
	return true


func _has_access() -> bool:
	return NPCServiceRulesScript.can_open_secured_cache(required_service_flag) \
		or WorldState.has_flag(_crafted_bypass_flag())


func _crafted_bypass_flag() -> StringName:
	return StringName("crafted_lock_bypass_%s" % persistent_id)
