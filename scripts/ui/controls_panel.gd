extends Control
## Reusable controls + objective help overlay, shown from the main menu and
## the pause menu. Emits `closed` when the player dismisses it so the parent
## can restore its own UI.

signal closed


func _ready() -> void:
	($Box/Back as Button).pressed.connect(func() -> void: closed.emit())
