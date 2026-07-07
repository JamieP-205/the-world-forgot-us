class_name StorageBox
extends Interactable
## Simple Railhome storage manifest.
##
## There is no separate stash UI yet. For this demo the storage crate gives
## a clear, functional list of the supplies currently banked in the global
## inventory, which is the state that persists between world and base.


func interact(_player: Node2D) -> void:
	var items := InventorySystem.get_items()
	if items.is_empty():
		EventBus.notice_posted.emit(
			"Storage manifest: empty. Search the wasteland crates first.")
		return

	var parts: Array[String] = []
	for item_id in items:
		var data: ItemData = ItemDatabase.get_item(item_id)
		var label := data.display_name if data != null else String(item_id)
		parts.append("%s x%d" % [label, int(items[item_id])])

	EventBus.notice_posted.emit("Storage manifest: %s" % ", ".join(parts))