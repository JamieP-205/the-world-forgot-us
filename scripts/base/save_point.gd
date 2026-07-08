class_name SavePoint
extends Interactable
## The bedroll -- the base's rest/save point.


func interact(player: Node2D) -> void:
	if player != null and player.has_method("heal_full"):
		player.heal_full()
	if SaveManager.save_game(""):
		var msg := "You sleep. For a while, nothing out there is trying to forget you."
		if BaseUpgradeSystem.is_built(&"radio_desk"):
			msg += " The Radio Desk hums warm through the carriage walls."
		msg += "\nRested. Progress saved."
		EventBus.notice_posted.emit(msg)
	else:
		EventBus.notice_posted.emit("Could not save progress.")