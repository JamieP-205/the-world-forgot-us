class_name EndingOverlay
extends Control
## Full-screen epilogue, credits, and replay handoff.

@onready var _title: Label = $Center/Panel/Margin/Content/Title
@onready var _subtitle: Label = $Center/Panel/Margin/Content/Subtitle
@onready var _body: RichTextLabel = $Center/Panel/Margin/Content/Body
@onready var _stats: Label = $Center/Panel/Margin/Content/Stats
@onready var _replay: Button = $Center/Panel/Margin/Content/Buttons/Replay
@onready var _continue: Button = $Center/Panel/Margin/Content/Buttons/Continue
@onready var _title_button: Button = $Center/Panel/Margin/Content/Buttons/TitleScreen
@onready var _panel: PanelContainer = $Center/Panel
@onready var _margin: MarginContainer = $Center/Panel/Margin
@onready var _content: VBoxContainer = $Center/Panel/Margin/Content
@onready var _buttons: BoxContainer = $Center/Panel/Margin/Content/Buttons
@onready var _credits: Label = $Center/Panel/Margin/Content/Credits
@onready var _eyebrow: Label = $Center/Panel/Margin/Content/Eyebrow


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	EventBus.ending_requested.connect(_show_ending)
	_continue.pressed.connect(_on_continue_aftermath)
	_replay.pressed.connect(_on_replay)
	_title_button.pressed.connect(_on_title_screen)
	get_viewport().size_changed.connect(_apply_responsive_layout)
	_apply_responsive_layout()


func _show_ending(payload: Dictionary) -> void:
	_title.text = _human_case(String(payload.get("title", "The end")))
	_subtitle.text = _human_case(String(payload.get("subtitle", "")))
	var aftermath := String(payload.get("aftermath", ""))
	_body.text = String(payload.get("body", "")) + ("\n\n" + aftermath if not aftermath.is_empty() else "")
	_continue.visible = not aftermath.is_empty()
	_stats.text = _human_case(String(payload.get("stats", "")))
	var accent: Color = payload.get("accent", Color(1.0, 0.72, 0.34, 1.0))
	_title.add_theme_color_override(
		"font_color", Color(0.47, 0.25, 0.08, 1.0).lerp(accent.darkened(0.42), 0.32))
	_body.scroll_to_line(0)
	visible = true
	(_continue if _continue.visible else _replay).grab_focus()


func _human_case(value: String) -> String:
	if value == value.to_upper():
		return value.to_lower().capitalize()
	return value


func apply_responsive_layout(
		viewport_size: Vector2,
		window_size: Vector2 = Vector2.ZERO,
	) -> void:
	_apply_responsive_layout(viewport_size, window_size)


func _apply_responsive_layout(
		size_override: Vector2 = Vector2.ZERO,
		window_override: Vector2 = Vector2.ZERO,
	) -> void:
	if not is_node_ready():
		return
	var view := size_override if size_override != Vector2.ZERO else get_viewport_rect().size
	var window_size := window_override if window_override != Vector2.ZERO else (
		Vector2(DisplayServer.window_get_size()) if size_override == Vector2.ZERO else view)
	var physical := _physical_scale(view, window_size)
	var ui_scale := clampf(0.92 / physical, 1.0, 3.2)
	var compact := window_size.x < 860.0 or window_size.y < 620.0
	var narrow := window_size.x < 560.0
	var shallow := window_size.y < 470.0
	_panel.custom_minimum_size = Vector2(
		clampf(
			view.x - (16.0 if compact else 80.0) * ui_scale,
			280.0 * ui_scale,
			880.0 * ui_scale,
		),
		clampf(
			view.y - (16.0 if compact else 64.0) * ui_scale,
			290.0 * ui_scale,
			680.0 * ui_scale,
		),
	)
	var edge := roundi((12.0 if compact else 42.0) * ui_scale)
	_margin.add_theme_constant_override("margin_left", edge)
	_margin.add_theme_constant_override("margin_right", edge)
	_margin.add_theme_constant_override("margin_top", roundi((10.0 if compact else 30.0) * ui_scale))
	_margin.add_theme_constant_override("margin_bottom", roundi((10.0 if compact else 28.0) * ui_scale))
	_content.add_theme_constant_override("separation", roundi((6.0 if compact else 10.0) * ui_scale))
	_title.add_theme_font_size_override("font_size", roundi((23.0 if compact else 36.0) * ui_scale))
	_subtitle.add_theme_font_size_override("font_size", roundi((14.0 if compact else 17.0) * ui_scale))
	_eyebrow.add_theme_font_size_override("font_size", roundi((9.0 if compact else 11.0) * ui_scale))
	_body.add_theme_font_size_override("normal_font_size", roundi((14.0 if compact else 17.0) * ui_scale))
	_body.custom_minimum_size.y = (
		66.0 if shallow else (104.0 if compact else 154.0)) * ui_scale
	_stats.add_theme_font_size_override("font_size", roundi((12.0 if compact else 14.0) * ui_scale))
	_credits.add_theme_font_size_override("font_size", roundi(11.0 * ui_scale))
	_credits.visible = not compact
	_buttons.vertical = narrow
	_buttons.add_theme_constant_override("separation", roundi((8.0 if compact else 14.0) * ui_scale))
	for button in [_continue, _replay, _title_button]:
		button.custom_minimum_size = Vector2(
			0.0 if narrow else (210.0 if compact else 250.0) * ui_scale,
			(48.0 if compact else 44.0) * ui_scale,
		)
		button.add_theme_font_size_override("font_size", roundi(14.0 * ui_scale))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL if narrow else Control.SIZE_SHRINK_CENTER


func _physical_scale(view: Vector2, window_size: Vector2) -> float:
	if view.x <= 1.0 or view.y <= 1.0 or window_size.x <= 1.0 or window_size.y <= 1.0:
		return 1.0
	return maxf(0.05, minf(window_size.x / view.x, window_size.y / view.y))


func _on_replay() -> void:
	GameManager.set_ending_active(false)
	SaveManager.clear_run_state()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func _on_continue_aftermath() -> void:
	WorldState.set_flag(&"route_aftermath_active")
	visible = false
	GameManager.set_ending_active(false)
	var main := get_tree().get_first_node_in_group("main")
	if main != null:
		if not EventBus.level_loaded.is_connected(_save_aftermath_arrival):
			EventBus.level_loaded.connect(_save_aftermath_arrival, CONNECT_ONE_SHOT)
	else:
		# Headless contracts have no persistent Main; keep their state snapshot
		# deterministic without arming a callback that can never arrive.
		SaveManager.save_game("")
	GameManager.travel_to(GameManager.BASE_SCENE_PATH, &"from_world")


func _save_aftermath_arrival() -> void:
	SaveManager.save_game("")


func _on_title_screen() -> void:
	GameManager.set_ending_active(false)
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
