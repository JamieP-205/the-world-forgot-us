class_name Interactable
extends Area2D
## Base class for anything the player can interact with by pressing E.
##
## Interactables live on the interactable physics layer and are detected by
## the player's InteractionArea. Subclasses override interact() and, when
## the prompt depends on state, get_prompt().

## Text shown in the HUD prompt, e.g. "Search crate" -> "[E] Search crate".
@export var prompt: String = "Interact"

var _highlighted := false


## Whether the player can act on this right now. Override to gate on state
## -- e.g. a memory echo that must be scanned first, or a locked door that
## needs a key.
func is_available() -> bool:
	return true


## The prompt to display right now. Override when the prompt depends on
## state (e.g. an already-looted container shows "Empty").
func get_prompt() -> String:
	return prompt


func set_highlighted(active: bool) -> void:
	if _highlighted == active:
		return
	_highlighted = active
	modulate = Color(1.35, 1.25, 0.75, 1.0) if active else Color(1, 1, 1, 1)


## Called by the player when they press the interact key in range.
func interact(_player: Node2D) -> void:
	push_warning("Interactable '%s' has no interact() override." % name)