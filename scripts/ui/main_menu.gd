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

var _wash_time := 0.0
var _redraw_accum := 0.0

@onready var _continue_btn: Button = $Box/Continue
@onready var _box: VBoxContainer = $Box
@onready var _controls_panel: Control = $ControlsPanel
@onready var _settings_panel: Control = $SettingsPanel
@onready var _confirm: ConfirmationDialog = $NewGameConfirm


func _ready() -> void:
	# Make sure a returned-from-pause state never leaves the tree paused.
	get_tree().paused = false
	# Keep punctuation deterministic across Web font/encoding pipelines.
	$QuotePanel/Margin/Content/Quote.text = "\"Take the tuning plate off.\nIf it doesn't say 14B,\nswitch the set off and walk.\""
	$QuotePanel/Margin/Content/Attribution.text = "- MAGGIE WARD  /  FAULT TAPE 06"
	$Footer.text = "JAMIE PARR  /  GODOT 4.7  /  HEADPHONES RECOMMENDED"

	_continue_btn.disabled = not SaveManager.has_save()
	_continue_btn.pressed.connect(_on_continue)
	$Box/NewGame.pressed.connect(_on_new_game)
	$Box/Controls.pressed.connect(_on_controls)
	$Box/Settings.pressed.connect(_on_settings)
	$Box/Credits.pressed.connect(func() -> void: $CreditsDialog.popup_centered())
	$Box/Quit.pressed.connect(_on_quit_or_fullscreen)
	if OS.has_feature("web"):
		$Box/Quit.text = "Fullscreen"

	_controls_panel.visible = false
	_controls_panel.closed.connect(_on_controls_closed)
	_settings_panel.visible = false
	_settings_panel.closed.connect(_on_settings_closed)
	_confirm.confirmed.connect(_do_new_game)

	if not _continue_btn.disabled:
		_continue_btn.grab_focus()
	else:
		$Box/NewGame.grab_focus()
	queue_redraw()


func _process(delta: float) -> void:
	# A very slow procedural title tableau keeps the front end alive without
	# introducing a video or a heavyweight menu scene. Twenty redraws per second
	# is visually smooth at this speed and avoids wasting WebGL fill-rate.
	_wash_time += delta
	_redraw_accum += delta
	if _redraw_accum >= 0.05:
		_redraw_accum = 0.0
		queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w <= 1.0 or h <= 1.0:
		return

	# Layered ink-wash sky. The hard-edged translucent bands echo the game's
	# screen-printed textures and remain legible at every browser aspect ratio.
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.025, 0.031, 0.03, 1.0))
	for band in 7:
		var y := h * (0.08 + float(band) * 0.085)
		var alpha := 0.035 + float(band % 3) * 0.012
		draw_colored_polygon(PackedVector2Array([
			Vector2(0.0, y - 32.0),
			Vector2(w, y + 18.0 + sin(_wash_time * 0.08 + band) * 4.0),
			Vector2(w, y + 76.0),
			Vector2(0.0, y + 44.0),
		]), Color(0.32, 0.35, 0.31, alpha))

	# A bruised amber sun caught behind the ash.
	var sun := Vector2(w * 0.77, h * 0.24)
	for ring in range(6, 0, -1):
		draw_circle(sun, 30.0 + ring * 24.0,
			Color(0.68, 0.39, 0.14, 0.012 + (6 - ring) * 0.006))
	draw_circle(sun, 29.0, Color(0.81, 0.52, 0.22, 0.34))
	draw_circle(sun + Vector2(-4.0, 3.0), 24.0, Color(0.13, 0.15, 0.13, 0.42))

	# Distant ashland silhouettes.
	draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, h * 0.57), Vector2(w * 0.09, h * 0.49),
		Vector2(w * 0.18, h * 0.55), Vector2(w * 0.29, h * 0.45),
		Vector2(w * 0.41, h * 0.54), Vector2(w * 0.53, h * 0.47),
		Vector2(w * 0.65, h * 0.56), Vector2(w * 0.78, h * 0.44),
		Vector2(w * 0.9, h * 0.53), Vector2(w, h * 0.47),
		Vector2(w, h), Vector2(0.0, h),
	]), Color(0.055, 0.065, 0.059, 0.97))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, h * 0.7), Vector2(w * 0.12, h * 0.61),
		Vector2(w * 0.25, h * 0.66), Vector2(w * 0.37, h * 0.58),
		Vector2(w * 0.54, h * 0.67), Vector2(w * 0.71, h * 0.58),
		Vector2(w * 0.83, h * 0.64), Vector2(w, h * 0.57),
		Vector2(w, h), Vector2(0.0, h),
	]), Color(0.035, 0.043, 0.039, 1.0))

	# The broken relay line gives the empty landscape a recognisable motif.
	for pole_x in [0.52, 0.67, 0.82, 0.95]:
		var pole_ratio: float = float(pole_x)
		var px: float = w * pole_ratio
		var ground: float = h * (0.64 - (pole_ratio - 0.52) * 0.07)
		var pole_h: float = h * (0.15 - (pole_ratio - 0.52) * 0.07)
		draw_line(Vector2(px, ground), Vector2(px, ground - pole_h),
			Color(0.12, 0.13, 0.115, 0.92), 3.0, true)
		draw_line(Vector2(px - 13.0, ground - pole_h + 8.0),
			Vector2(px + 13.0, ground - pole_h + 8.0),
			Color(0.12, 0.13, 0.115, 0.92), 2.0, true)

	# A restrained cyan memory distortion is the only saturated cool element.
	var echo := Vector2(w * 0.83, h * 0.59)
	for arc_index in 4:
		var pulse := sin(_wash_time * 0.55 + arc_index * 0.9) * 2.0
		draw_arc(echo, 18.0 + arc_index * 15.0 + pulse, -2.55, 0.52, 38,
			Color(0.27, 0.82, 0.83, 0.24 - arc_index * 0.035), 1.4, true)

	# Slow ash flecks: deterministic, subtle, and intentionally sparse.
	for mote in 18:
		var mx := fmod(float(mote * 97) + _wash_time * (2.0 + mote % 4), w + 80.0) - 40.0
		var my := fmod(float(mote * 53) + sin(_wash_time * 0.19 + mote) * 18.0, h * 0.72)
		var mote_alpha := 0.1 + float(mote % 3) * 0.035
		draw_circle(Vector2(mx, my), 1.0 + float(mote % 2),
			Color(0.65, 0.62, 0.52, mote_alpha))


func _input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventMouseButton:
		if event.pressed:
			AudioManager.unlock_audio()


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
	WorldState.set_flag(&"intro_pending")
	_start_game()


func _start_game() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_controls() -> void:
	_box.visible = false
	_controls_panel.visible = true


func _on_controls_closed() -> void:
	_controls_panel.visible = false
	_box.visible = true


func _on_settings() -> void:
	_box.visible = false
	_settings_panel.open_panel()


func _on_settings_closed() -> void:
	_settings_panel.visible = false
	_box.visible = true


func _on_quit_or_fullscreen() -> void:
	AudioManager.unlock_audio()
	if OS.has_feature("web"):
		var mode := DisplayServer.window_get_mode()
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_WINDOWED
			if mode == DisplayServer.WINDOW_MODE_FULLSCREEN
			else DisplayServer.WINDOW_MODE_FULLSCREEN
		)
	else:
		get_tree().quit()
