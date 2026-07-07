class_name PlaceholderInteractable
extends Interactable
## A stand-in for a system that isn't built yet (bedroll, storage crate,
## radio desk...). Interacting posts a short notice to the HUD so base
## props feel alive and clearly signpost what's coming, without pretending
## to do something they can't. Replace with the real interactable later.

## Message shown when the player interacts.
@export_multiline var notice: String = "Not built yet."


func interact(_player: Node2D) -> void:
	if not notice.is_empty():
		EventBus.notice_posted.emit(notice)
