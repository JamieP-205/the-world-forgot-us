class_name TraceAnchorOverlay
extends CanvasLayer
## Receiver-paper inspection surface for one trace anchor.

signal advance_requested
signal resolution_requested(disposition: StringName)
signal dismissed

@onready var _root: Control = $Root
@onready var _shell: PanelContainer = $Root/Center/ReceiverShell
@onready var _margin: MarginContainer = $Root/Center/ReceiverShell/Margin
@onready var _stage_label: Label = $Root/Center/ReceiverShell/Margin/Layout/Stage
@onready var _title: Label = $Root/Center/ReceiverShell/Margin/Layout/Header/Artifact
@onready var _bearing: Label = $Root/Center/ReceiverShell/Margin/Layout/Header/Bearing
@onready var _readout: RichTextLabel = $Root/Center/ReceiverShell/Margin/Layout/Paper/Readout
@onready var _noise: Label = $Root/Center/ReceiverShell/Margin/Layout/Noise
@onready var _primary: Button = $Root/Center/ReceiverShell/Margin/Layout/Controls/Primary
@onready var _choices: GridContainer = $Root/Center/ReceiverShell/Margin/Layout/Controls/Choices
@onready var _verify: Button = $Root/Center/ReceiverShell/Margin/Layout/Controls/Choices/Verify
@onready var _feed: Button = $Root/Center/ReceiverShell/Margin/Layout/Controls/Choices/Feed
@onready var _close: Button = $Root/Center/ReceiverShell/Margin/Layout/Controls/Close
@onready var _eyebrow: Label = $Root/Center/ReceiverShell/Margin/Layout/Eyebrow
@onready var _layout: VBoxContainer = $Root/Center/ReceiverShell/Margin/Layout
@onready var _header: BoxContainer = $Root/Center/ReceiverShell/Margin/Layout/Header
@onready var _controls: VBoxContainer = $Root/Center/ReceiverShell/Margin/Layout/Controls

var _data: MemoryEchoData
var _stage: StringName = &"hidden"
var _bearing_text := "NEEDLE --"
var _compact := false
var _text_scale := 1.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root.visible = false
	_primary.pressed.connect(func() -> void: advance_requested.emit())
	_verify.pressed.connect(func() -> void: resolution_requested.emit(ArchiveSystem.VERIFIED))
	_feed.pressed.connect(func() -> void: resolution_requested.emit(ArchiveSystem.FED))
	_close.pressed.connect(close_overlay)
	get_viewport().size_changed.connect(apply_responsive_layout)
	apply_responsive_layout()


func present_focus(data: MemoryEchoData, bearing_text: String) -> void:
	_data = data
	_stage = &"focus"
	_bearing_text = bearing_text
	_open_modal()
	_stage_label.text = "02  /  FOCUS"
	_title.text = data.artifact_name.to_upper() if data != null else "UNLABELLED OBJECT"
	_bearing.text = bearing_text
	_noise.text = _noise_meter(data.signal_profile if data != null else "broadband residue")
	_primary.visible = true
	_primary.text = "RESOLVE SPATIAL LAYER"
	_choices.visible = false
	_readout.text = _focus_text(data)
	_primary.grab_focus()


func present_reveal(data: MemoryEchoData, bearing_text: String) -> void:
	_data = data
	_stage = &"reveal"
	_bearing_text = bearing_text
	_open_modal()
	_stage_label.text = "03  /  REVEAL"
	_title.text = data.artifact_name.to_upper() if data != null else "UNLABELLED OBJECT"
	_bearing.text = bearing_text
	_noise.text = "CARRIER HELD  | | | |     OBJECT + AFTERIMAGE ALIGNED"
	_primary.visible = false
	_choices.visible = true
	_readout.text = _reveal_text(data)
	_verify.grab_focus()


func close_overlay() -> void:
	if not _root.visible:
		return
	_root.visible = false
	GameManager.set_dialogue_active(false)
	dismissed.emit()


func is_open() -> bool:
	return _root.visible


func get_presented_stage() -> StringName:
	return _stage


func is_compact_layout() -> bool:
	return _compact


func get_choice_columns() -> int:
	return _choices.columns


func apply_responsive_layout(
		size_override: Vector2 = Vector2.ZERO,
		window_override: Vector2 = Vector2.ZERO,
	) -> void:
	if not is_node_ready():
		return
	var viewport_size := size_override if size_override != Vector2.ZERO else get_viewport().get_visible_rect().size
	var window_size := window_override if window_override != Vector2.ZERO else (
		Vector2(DisplayServer.window_get_size()) if size_override == Vector2.ZERO else viewport_size)
	var physical := _physical_scale(viewport_size, window_size)
	var ui_scale := clampf(0.92 / physical, 1.0, 3.2)
	_compact = window_size.x < 760.0 or window_size.y < 560.0
	var narrow := window_size.x < 560.0
	var shallow := window_size.y < 480.0
	_shell.custom_minimum_size = Vector2(
		clampf(
			viewport_size.x - (24.0 if _compact else 80.0) * ui_scale,
			304.0 * ui_scale,
			780.0 * ui_scale,
		),
		clampf(
			viewport_size.y - (16.0 if shallow else (24.0 if _compact else 72.0)) * ui_scale,
			(330.0 if shallow else 430.0) * ui_scale,
			680.0 * ui_scale,
		),
	)
	var edge := roundi((14.0 if _compact else 28.0) * ui_scale)
	_margin.add_theme_constant_override("margin_left", edge)
	_margin.add_theme_constant_override("margin_right", edge)
	_margin.add_theme_constant_override("margin_top", roundi((14.0 if _compact else 22.0) * ui_scale))
	_margin.add_theme_constant_override("margin_bottom", roundi((14.0 if _compact else 22.0) * ui_scale))
	_layout.add_theme_constant_override("separation", roundi(9.0 * ui_scale))
	_header.add_theme_constant_override("separation", roundi(14.0 * ui_scale))
	_header.vertical = narrow and not shallow
	_bearing.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if narrow else HORIZONTAL_ALIGNMENT_RIGHT
	_controls.add_theme_constant_override("separation", roundi(8.0 * ui_scale))
	_choices.add_theme_constant_override("h_separation", roundi(8.0 * ui_scale))
	_choices.add_theme_constant_override("v_separation", roundi(8.0 * ui_scale))
	_choices.columns = 2 if shallow else (1 if _compact else 2)
	_eyebrow.add_theme_font_size_override("font_size", roundi(11.0 * ui_scale))
	_stage_label.add_theme_font_size_override("font_size", roundi(15.0 * ui_scale))
	_title.add_theme_font_size_override("font_size", roundi(22.0 * ui_scale))
	_bearing.add_theme_font_size_override("font_size", roundi(13.0 * ui_scale))
	_readout.add_theme_font_size_override("normal_font_size", roundi(15.0 * ui_scale))
	_noise.add_theme_font_size_override("font_size", roundi(11.0 * ui_scale))
	for button in [_primary, _verify, _feed, _close]:
		button.custom_minimum_size.y = (54.0 if _compact else 48.0) * ui_scale
		button.add_theme_font_size_override("font_size", roundi(14.0 * ui_scale))
	var scale_changed := not is_equal_approx(_text_scale, ui_scale)
	_text_scale = ui_scale
	if scale_changed and _root.visible:
		_readout.text = _focus_text(_data) if _stage == &"focus" else _reveal_text(_data)
		_readout.scroll_to_line(0)


func _physical_scale(view: Vector2, window_size: Vector2) -> float:
	if view.x <= 1.0 or view.y <= 1.0 or window_size.x <= 1.0 or window_size.y <= 1.0:
		return 1.0
	return maxf(0.05, minf(window_size.x / view.x, window_size.y / view.y))


func _font_size(base_size: int) -> int:
	return maxi(base_size, roundi(float(base_size) * _text_scale))


func _open_modal() -> void:
	_root.visible = true
	GameManager.set_dialogue_active(true)
	apply_responsive_layout()
	AudioManager.play(&"archive", -6.0, 0.84)


func _unhandled_input(event: InputEvent) -> void:
	if not _root.visible:
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		close_overlay()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact") and _primary.visible:
		advance_requested.emit()
		get_viewport().set_input_as_handled()


func _exit_tree() -> void:
	if is_instance_valid(_root) and _root.visible:
		GameManager.set_dialogue_active(false)


func _focus_text(data: MemoryEchoData) -> String:
	if data == null:
		return "[color=#302d25]No paper record is loaded.[/color]"
	return (
		"[color=#494235][font_size=%d]DETECT[/font_size][/color]\n" % _font_size(12)
		+ "[color=#1e211d][font_size=%d]%s[/font_size][/color]\n\n" % [
			_font_size(18), _safe(data.hint)]
		+ "[color=#494235]RECEIVER NOISE[/color]  %s\n\n" % _safe(data.signal_profile)
		+ "The object edge is stable. Hold the carrier long enough to separate its present position from the recorded afterimage."
	)


func _reveal_text(data: MemoryEchoData) -> String:
	if data == null:
		return "[color=#302d25]No evidence resolved.[/color]"
	return (
		"[color=#355c56][font_size=%d]%s[/font_size][/color]\n\n" % [
			_font_size(13), _safe(data.evidence_label())]
		+ "[color=#494235]OBSERVATION[/color]\n%s\n\n" % _safe(data.observation_text)
		+ "[color=#744f3d]CONTRADICTION[/color]\n%s\n\n" % _safe(data.contradiction_text)
		+ "[color=#355c56]FILING TEST[/color]\n%s\n\n" % _safe(data.verification_text)
		+ "[color=#744f3d]FEED RISK[/color]\n%s" % _safe(data.feed_warning)
	)


func _noise_meter(profile: String) -> String:
	var bars := "| . || . |"
	if profile.length() % 3 == 0:
		bars = "|| . | . ||"
	elif profile.length() % 2 == 0:
		bars = "| || . || ."
	return "NOISE  %s     %s" % [bars, profile.to_upper()]


func _safe(value: Variant) -> String:
	return String(value).replace("[", "[lb]")
