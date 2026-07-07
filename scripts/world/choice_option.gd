class_name ChoiceOption
extends Interactable
## One option in a small either/or cache. Taking any option under the same
## parent locks the others -- a light "you can't take both" decision built
## only from the existing inventory + interaction systems (no economy, no
## new UI). Put two of these under a plain Node2D "cache" parent.

@export var take_prompt: String = "Take"

## Resource reward: item id -> amount.
@export var loot: Dictionary = {}

## Optional keepsake id granted in addition to (or instead of) loot.
@export var keepsake_item: StringName = &""

## Line shown when this option is taken.
@export_multiline var take_notice: String = ""

var _locked := false

@onready var _visual: Node2D = get_node_or_null("Visual")


func is_available() -> bool:
	return not _locked


func get_prompt() -> String:
	return take_prompt


func set_locked(value: bool) -> void:
	_locked = value
	if _visual != null and value:
		_visual.modulate = Color(0.4, 0.42, 0.4)  # dimmed = the road not taken


func interact(_player: Node2D) -> void:
	if _locked:
		return

	var parts: Array[String] = []
	for item_id in loot:
		var amount := int(loot[item_id])
		InventorySystem.add_item(item_id, amount)
		var data: ItemData = ItemDatabase.get_item(item_id)
		var nm := data.display_name if data != null else String(item_id)
		parts.append("+%d %s" % [amount, nm])
	if keepsake_item != &"":
		InventorySystem.add_item(keepsake_item, 1)
		var kd: ItemData = ItemDatabase.get_item(keepsake_item)
		parts.append("+%s" % (kd.display_name if kd != null else String(keepsake_item)))

	var msg := take_notice
	if not parts.is_empty():
		msg += "\n(%s)" % ", ".join(parts)
	EventBus.notice_posted.emit(msg)

	# Lock every option under this cache (including self) -- one choice only.
	for c in get_parent().get_children():
		if c is ChoiceOption:
			c.set_locked(true)
