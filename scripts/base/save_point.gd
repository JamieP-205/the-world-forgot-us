class_name SavePoint
extends Interactable
## The bedroll -- the base's rest/save point.

const REST_SEQUENCE := preload("res://scenes/ui/rest_sequence.tscn")

var _resting := false


func interact(player: Node2D) -> void:
	if _resting:
		return
	_resting = true
	if player != null and player.has_method("heal_full"):
		player.heal_full()
	# This must be an explicit story flag. Merely having any old save does not
	# prove that the player rested after bringing the Radio Desk online.
	if BaseUpgradeSystem.is_built(&"radio_desk"):
		WorldState.set_flag(&"rested_after_radio")
	if DisplayServer.get_name() != "headless":
		GameManager.set_dialogue_active(true)
		var sequence := REST_SEQUENCE.instantiate() as RestSequence
		get_tree().root.add_child(sequence)
		sequence.begin(BaseUpgradeSystem.is_built(&"radio_desk"))
		await sequence.finished
		GameManager.set_dialogue_active(false)
	_complete_rest()


func _complete_rest() -> void:
	if SaveManager.save_game(""):
		var msg := "Morning in Carriage 317. Health restored; progress saved."
		if BaseUpgradeSystem.is_built(&"radio_desk"):
			msg += " Maggie's north-road tape is decoded."
		EventBus.notice_posted.emit(msg)
	else:
		EventBus.notice_posted.emit("Could not save progress.")
	_resting = false
