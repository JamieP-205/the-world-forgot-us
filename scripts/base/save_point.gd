class_name SavePoint
extends Interactable
## The bedroll -- the base's rest/save point.


func interact(player: Node2D) -> void:
	if player != null and player.has_method("heal_full"):
		player.heal_full()
	if SaveManager.save_game(""):
		EventBus.notice_posted.emit("Rested. Progress saved.")
	else:
		EventBus.notice_posted.emit("Could not save progress.")