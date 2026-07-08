class_name LootContainer
extends Interactable
## A one-shot lootable container (crate, locker, cupboard, car boot...).

## Item id -> quantity given when searched. Edit per-instance in the map.
@export var loot: Dictionary = {"scrap": 3}

## Prompt shown after the container has been emptied.
@export var empty_prompt: String = "Empty"

## Stable id for persistence. Empty defaults to the node name (unique in the
## demo), so searched state survives travel and save/load.
@export var persistent_id: StringName = &""

var _opened := false

# Node2D so this works whether the Visual is the crate Sprite2D (scene) or
# a Polygon2D placeholder (map-local containers). Both support modulate.
@onready var _visual: Node2D = $Visual
@onready var _glint: Polygon2D = get_node_or_null("Glint")


func _ready() -> void:
	if persistent_id == &"":
		persistent_id = StringName(name)
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
	return empty_prompt if _opened else prompt


func interact(_player: Node2D) -> void:
	if _opened:
		EventBus.notice_posted.emit("Already searched.")
		return
	_opened = true
	WorldState.mark_opened(persistent_id)

	var parts: Array[String] = []
	for item_id in loot:
		var amount := int(loot[item_id])
		InventorySystem.add_item(item_id, amount)
		var data: ItemData = ItemDatabase.get_item(item_id)
		var label := data.display_name if data != null else String(item_id)
		parts.append("+%d %s" % [amount, label])

	_visual.modulate = Color(0.42, 0.45, 0.43)
	if _glint != null:
		_glint.visible = false
	EventBus.notice_posted.emit(
		"Supplies recovered: %s. Inventory updated on the left." % ", ".join(parts))
