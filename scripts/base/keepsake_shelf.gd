class_name KeepsakeShelf
extends Interactable
## The Railhome Memory Shelf: gives the keepsake items (lunchbox, locket, photo)
## a purpose. Visiting it recognises whatever keepsakes you're carrying and warms
## the base the first time. Keepsakes are not consumed -- they're remembered.

const KEEPSAKES := {
	&"child_lunchbox": "the child's lunchbox",
	&"tin_locket": "the tin locket",
	&"old_photo": "the folded photograph",
}


func get_prompt() -> String:
	return "Tend the memory shelf"


func interact(_player: Node2D) -> void:
	var found: Array[String] = []
	for id in KEEPSAKES:
		if InventorySystem.get_count(id) > 0:
			found.append(KEEPSAKES[id])

	if found.is_empty():
		EventBus.notice_posted.emit(
			"The shelf is bare. There are clean outlines where somebody's things used to sit.")
		return

	AudioManager.play(&"keepsake")
	var first_time := not WorldState.is_opened(&"keepsake_shelf_used")
	WorldState.mark_opened(&"keepsake_shelf_used")

	var line := "On the memory shelf you set down %s." % _join(found)
	if first_time:
		line += "\nCarriage 317 looks less borrowed now."
	EventBus.notice_posted.emit(line)


func _join(parts: Array[String]) -> String:
	if parts.size() == 1:
		return parts[0]
	if parts.size() == 2:
		return "%s and %s" % [parts[0], parts[1]]
	var head := parts.slice(0, parts.size() - 1)
	return "%s, and %s" % [", ".join(head), parts[parts.size() - 1]]
