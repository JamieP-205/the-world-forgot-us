class_name EndingOverlay
extends Control
## Full-screen epilogue, credits, and replay handoff.

@onready var _title: Label = $Center/Panel/Margin/Content/Title
@onready var _subtitle: Label = $Center/Panel/Margin/Content/Subtitle
@onready var _body: Label = $Center/Panel/Margin/Content/Body
@onready var _stats: Label = $Center/Panel/Margin/Content/Stats
@onready var _replay: Button = $Center/Panel/Margin/Content/Buttons/Replay
@onready var _title_button: Button = $Center/Panel/Margin/Content/Buttons/TitleScreen


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	EventBus.ending_requested.connect(_show_ending)
	_replay.pressed.connect(_on_replay)
	_title_button.pressed.connect(_on_title_screen)


func _show_ending(payload: Dictionary) -> void:
	_title.text = String(payload.get("title", "THE END"))
	_subtitle.text = String(payload.get("subtitle", ""))
	_body.text = String(payload.get("body", ""))
	_stats.text = String(payload.get("stats", ""))
	var accent: Color = payload.get("accent", Color(1.0, 0.72, 0.34, 1.0))
	_title.add_theme_color_override("font_color", accent)
	visible = true
	_replay.grab_focus()


func _on_replay() -> void:
	GameManager.set_ending_active(false)
	SaveManager.clear_run_state()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _on_title_screen() -> void:
	GameManager.set_ending_active(false)
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
