extends Control
## First-launch main menu. Start flow for the demo test build.
##
## Continue  - load the existing save (disabled if none).
## New Game  - clear the save + all run state and start fresh (confirmed if
##             a save exists, so progress isn't wiped by accident).
## Controls  - show the shared controls/help panel.
## Quit      - close the game.
##
## The game itself lives in scenes/main.tscn; running that scene directly
## still works during development (Main auto-continues from a save or starts
## the world), so this menu doesn't break the dev workflow.

const GAME_SCENE := "res://scenes/main.tscn"

@onready var _continue_btn: Button = $Box/Continue
@onready var _box: VBoxContainer = $Box
@onready var _controls_panel: Control = $ControlsPanel
@onready var _confirm: ConfirmationDialog = $NewGameConfirm


func _ready() -> void:
	# Make sure a returned-from-pause state never leaves the tree paused.
	get_tree().paused = false

	_continue_btn.disabled = not SaveManager.has_save()
	_continue_btn.pressed.connect(_on_continue)
	$Box/NewGame.pressed.connect(_on_new_game)
	$Box/Controls.pressed.connect(_on_controls)
	$Box/Quit.pressed.connect(func() -> void: get_tree().quit())

	_controls_panel.visible = false
	_controls_panel.closed.connect(_on_controls_closed)
	_confirm.confirmed.connect(_do_new_game)

	if not _continue_btn.disabled:
		_continue_btn.grab_focus()
	else:
		$Box/NewGame.grab_focus()


func _on_continue() -> void:
	if SaveManager.has_save():
		_start_game()


func _on_new_game() -> void:
	if SaveManager.has_save():
		_confirm.popup_centered()
	else:
		_do_new_game()


func _do_new_game() -> void:
	SaveManager.clear_run_state()
	_start_game()


func _start_game() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_controls() -> void:
	_box.visible = false
	_controls_panel.visible = true


func _on_controls_closed() -> void:
	_controls_panel.visible = false
	_box.visible = true
