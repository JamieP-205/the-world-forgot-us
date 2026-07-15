class_name SavePoint
extends Interactable
## The bedroll -- the base's rest/save point.


func interact(player: Node2D) -> void:
	if player != null and player.has_method("heal_full"):
		player.heal_full()
	# This must be an explicit story flag. Merely having any old save does not
	# prove that the player rested after bringing the Radio Desk online.
	if BaseUpgradeSystem.is_built(&"radio_desk"):
		WorldState.set_flag(&"rested_after_radio")
	if SaveManager.save_game(""):
		var msg := "You sleep in your boots. Rain ticks against the carriage roof."
		if BaseUpgradeSystem.is_built(&"radio_desk"):
			msg += " The shortwave set murmurs through the carriage wall."
		msg += "\nRested. Progress saved."
		EventBus.notice_posted.emit(msg)
	else:
		EventBus.notice_posted.emit("Could not save progress.")
