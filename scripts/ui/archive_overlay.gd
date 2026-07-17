class_name ArchiveOverlay
extends Control
## In-game field archive: recovered traces, repair progress, and controls.

@onready var _content: RichTextLabel = $Center/Panel/Margin/Layout/Content
@onready var _count: Label = $Center/Panel/Margin/Layout/HeaderRow/Count
@onready var _close: Button = $Center/Panel/Margin/Layout/Footer/Close
@onready var _panel: PanelContainer = $Center/Panel
@onready var _margin: MarginContainer = $Center/Panel/Margin
@onready var _header: Label = $Center/Panel/Margin/Layout/HeaderRow/Header
@onready var _footer_hint: Label = $Center/Panel/Margin/Layout/Footer/Hint
@onready var _header_row: BoxContainer = $Center/Panel/Margin/Layout/HeaderRow

var _text_scale := 1.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_close.pressed.connect(close_archive)
	get_viewport().size_changed.connect(_apply_responsive_layout)
	_apply_responsive_layout()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("archive"):
		return
	if visible:
		close_archive()
	elif not GameManager.is_input_locked():
		open_archive()
	get_viewport().set_input_as_handled()


func open_archive() -> void:
	_refresh()
	visible = true
	GameManager.set_dialogue_active(true)
	_close.grab_focus()
	AudioManager.play(&"archive")


func close_archive() -> void:
	if not visible:
		return
	visible = false
	GameManager.set_dialogue_active(false)


func _refresh() -> void:
	var lines: Array[String] = []
	var recovered := ArchiveSystem.get_recovered()
	_count.text = "%d field %s" % [
		recovered.size(), "trace" if recovered.size() == 1 else "traces"]
	var objective := CampaignSystem.get_objective()
	lines.append("[color=#704017][font_size=%d]Primary route[/font_size][/color]" % _font_size(12))
	lines.append("[color=#17201e][font_size=%d]%s[/font_size][/color]" % [
		_font_size(18), _safe_bbcode(objective.get("text", "Find a way forward."))])
	lines.append("[color=#20504b][font_size=%d]%s[/font_size][/color]" % [
		_font_size(11), _safe_bbcode(objective.get("location", "No verified location"))])
	lines.append("[color=#67451e]%s[/color]" % _safe_bbcode(objective.get("progress", "")))
	lines.append("")
	lines.append("[color=#704017][font_size=%d]Recorded traces[/font_size][/color]" % _font_size(12))
	if recovered.is_empty():
		lines.append("[color=#28534f][font_size=%d]No fault traces catalogued[/font_size][/color]" % _font_size(12))
		lines.append("")
		lines.append("Use a receiver sweep with [color=#704017]Q[/color] near blue interference, then catalogue the trace with [color=#704017]E[/color].")
	for echo in recovered:
		lines.append("[color=#17201e][font_size=%d]%s[/font_size][/color]" % [
			_font_size(20), _safe_bbcode(echo.title)])
		var disposition := ArchiveSystem.get_disposition(echo.id)
		var handling := "Fed to the copy  /  unverified" if disposition == ArchiveSystem.FED \
			else "Verified  /  filed"
		var handling_color := "#753b24" if disposition == ArchiveSystem.FED else "#1d5a4d"
		lines.append("[color=#20504b][font_size=%d]%s  /  %s[/font_size][/color]" % [
			_font_size(11),
			_safe_bbcode(String(echo.category).capitalize()),
			_safe_bbcode(String(echo.quality).capitalize()),
		])
		lines.append("[color=%s][font_size=%d]%s[/font_size][/color]" % [
			handling_color, _font_size(11), handling])
		lines.append("[color=#4b4738]%s[/color]" % _safe_bbcode(echo.artifact_name))
		lines.append("[color=#23554f]%s[/color]" % _safe_bbcode(echo.evidence_label()))
		lines.append("")
		lines.append("[color=#4f4631]Observation[/color]  %s" % _safe_bbcode(echo.observation_text))
		lines.append("[color=#713a24]Contradiction[/color]  %s" % _safe_bbcode(echo.contradiction_text))
		lines.append("[color=#28544a]Filing test[/color]  %s" % _safe_bbcode(echo.verification_text))
		lines.append("")
		lines.append(_safe_bbcode(echo.memory_text))
		lines.append("")
		lines.append("[color=#4d5144]--------------------------------------------------------[/color]")
		lines.append("")
	lines.append("[color=#704017][font_size=%d]Field work[/font_size][/color]" % _font_size(12))
	lines.append("Wrenfield lines reset  [color=#1d5a4d]%d / 3[/color]" % CampaignSystem.get_restored_relay_count())
	lines.append("Receiver discharge  %s" % (
		"[color=#1d5a4d]Online  /  R[/color]"
		if WorldState.has_flag(&"memory_burst_unlocked")
		else "[color=#54574b]Locked[/color]"))
	lines.append("")
	lines.append("[color=#704017][font_size=%d]Optional threads[/font_size][/color]" % _font_size(12))
	for entry in CampaignSystem.get_optional_progress():
		var state := String(entry.get("state", "open"))
		var color := "#4d5148"
		var marker := ">"
		if state == "complete":
			color = "#1d5a4d"
			marker = "+"
		elif state == "closed":
			color = "#70492d"
			marker = "-"
		lines.append("%s [color=#242b28]%s[/color]" % [
			marker,
			_safe_bbcode(entry.get("task", entry.get("label", "Optional lead"))),
		])
		lines.append("   [color=#20504b]%s[/color]" % _safe_bbcode(entry.get("location", "Location unknown")))
		lines.append("   [color=%s]%s[/color]" % [
			color,
			_safe_bbcode(entry.get("progress", entry.get("status", "Open"))),
		])
		lines.append("")
	lines.append("")
	lines.append("[color=#704017][font_size=%d]Field controls[/font_size][/color]" % _font_size(12))
	lines.append("WASD move  /  E interact  /  J or left-click strike  /  C make")
	lines.append("Q sweep  /  Space dodge  /  F supplies  /  I close archive")
	_content.text = "\n".join(lines)
	_content.scroll_to_line(0)


func _safe_bbcode(value: Variant) -> String:
	return String(value).replace("[", "[lb]")


func _font_size(base_size: int) -> int:
	return maxi(base_size, roundi(float(base_size) * _text_scale))


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
	var viewport_size := size_override if size_override != Vector2.ZERO else get_viewport_rect().size
	var window_size := window_override if window_override != Vector2.ZERO else (
		Vector2(DisplayServer.window_get_size()) if size_override == Vector2.ZERO else viewport_size)
	var physical := _physical_scale(viewport_size, window_size)
	var ui_scale := clampf(0.92 / physical, 1.0, 3.2)
	var compact := window_size.x < 860.0 or window_size.y < 620.0
	var narrow := window_size.x < 560.0
	_panel.custom_minimum_size = Vector2(
		clampf(
			viewport_size.x - (16.0 if compact else 80.0) * ui_scale,
			280.0 * ui_scale,
			1040.0 * ui_scale,
		),
		clampf(
			viewport_size.y - (16.0 if compact else 64.0) * ui_scale,
			286.0 * ui_scale,
			700.0 * ui_scale,
		),
	)
	var edge := roundi((12.0 if compact else 38.0) * ui_scale)
	var left_edge := roundi((24.0 if compact else 38.0) * ui_scale)
	_margin.add_theme_constant_override("margin_left", left_edge)
	_margin.add_theme_constant_override("margin_right", edge)
	_margin.add_theme_constant_override("margin_top", roundi((14.0 if compact else 28.0) * ui_scale))
	_margin.add_theme_constant_override("margin_bottom", roundi((14.0 if compact else 26.0) * ui_scale))
	_header.add_theme_font_size_override("font_size", roundi((19.0 if compact else 31.0) * ui_scale))
	_header_row.vertical = narrow
	_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if narrow else HORIZONTAL_ALIGNMENT_RIGHT
	_count.add_theme_font_size_override("font_size", roundi(12.0 * ui_scale))
	_content.add_theme_font_size_override("normal_font_size", roundi((13.0 if compact else 15.0) * ui_scale))
	_close.custom_minimum_size = Vector2((164.0 if compact else 230.0) * ui_scale, 48.0 * ui_scale)
	_close.add_theme_font_size_override("font_size", roundi(15.0 * ui_scale))
	_footer_hint.add_theme_font_size_override("font_size", roundi(11.0 * ui_scale))
	_footer_hint.visible = not compact
	var scale_changed := not is_equal_approx(_text_scale, ui_scale)
	_text_scale = ui_scale
	if scale_changed and visible:
		_refresh()


func _physical_scale(view: Vector2, window_size: Vector2) -> float:
	if view.x <= 1.0 or view.y <= 1.0 or window_size.x <= 1.0 or window_size.y <= 1.0:
		return 1.0
	return maxf(0.05, minf(window_size.x / view.x, window_size.y / view.y))
