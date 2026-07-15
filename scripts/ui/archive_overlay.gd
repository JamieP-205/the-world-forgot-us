class_name ArchiveOverlay
extends Control
## In-game field archive: recovered traces, repair progress, and controls.

@onready var _content: RichTextLabel = $Center/Panel/Margin/Layout/Content
@onready var _count: Label = $Center/Panel/Margin/Layout/HeaderRow/Count
@onready var _close: Button = $Center/Panel/Margin/Layout/Footer/Close


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_close.pressed.connect(close_archive)


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
	_count.text = "%d %s CATALOGUED" % [
		recovered.size(), "TRACE" if recovered.size() == 1 else "TRACES"]
	var objective := CampaignSystem.get_objective()
	lines.append("[color=#d9aa5b][font_size=12]PRIMARY ROUTE[/font_size][/color]")
	lines.append("[color=#ded8c2][font_size=18]%s[/font_size][/color]" % _safe_bbcode(objective.get("text", "Find a way forward.")))
	lines.append("[color=#579b9a][font_size=11]%s[/font_size][/color]" % _safe_bbcode(objective.get("location", "NO VERIFIED LOCATION")))
	lines.append("[color=#b98b49]%s[/color]" % _safe_bbcode(objective.get("progress", "")))
	lines.append("")
	lines.append("[color=#d9aa5b][font_size=12]RECORDED TRACES[/font_size][/color]")
	if recovered.is_empty():
		lines.append("[color=#729e9c][font_size=12]NO FAULT TRACES CATALOGUED[/font_size][/color]")
		lines.append("")
		lines.append("Use a receiver sweep with [color=#e8b35c]Q[/color] near blue interference, then catalogue the trace with [color=#e8b35c]E[/color].")
	for echo in recovered:
		lines.append("[color=#d8c49a][font_size=20]%s[/font_size][/color]" % _safe_bbcode(echo.title.to_upper()))
		lines.append("[color=#579b9a][font_size=11]%s  /  %s[/font_size][/color]" % [
			_safe_bbcode(String(echo.category).to_upper()),
			_safe_bbcode(String(echo.quality).to_upper()),
		])
		lines.append("")
		lines.append(_safe_bbcode(echo.memory_text))
		lines.append("")
		lines.append("[color=#344a47]--------------------------------------------------------[/color]")
		lines.append("")
	lines.append("[color=#d9aa5b][font_size=12]FIELD WORK[/font_size][/color]")
	lines.append("Wrenfield lines reset  [color=#75c4c2]%d / 3[/color]" % CampaignSystem.get_restored_relay_count())
	lines.append("Receiver discharge  %s" % (
		"[color=#75c4c2]ONLINE  /  R[/color]"
		if WorldState.has_flag(&"memory_burst_unlocked")
		else "[color=#6a6c64]LOCKED[/color]"))
	lines.append("")
	lines.append("[color=#d9aa5b][font_size=12]OPTIONAL THREADS[/font_size][/color]")
	for entry in CampaignSystem.get_optional_progress():
		var state := String(entry.get("state", "open"))
		var color := "#8b8d82"
		var marker := "·"
		if state == "complete":
			color = "#75c4c2"
			marker = "+"
		elif state == "closed":
			color = "#b08b68"
			marker = "-"
		lines.append("%s [color=#c9c5b5]%s[/color]" % [
			marker,
			_safe_bbcode(entry.get("task", entry.get("label", "Optional lead"))),
		])
		lines.append("   [color=#579b9a]%s[/color]" % _safe_bbcode(entry.get("location", "LOCATION UNKNOWN")))
		lines.append("   [color=%s]%s[/color]" % [
			color,
			_safe_bbcode(entry.get("progress", entry.get("status", "OPEN"))),
		])
		lines.append("")
	lines.append("")
	lines.append("[color=#d9aa5b][font_size=12]FIELD CONTROLS[/font_size][/color]")
	lines.append("WASD move  /  E interact  /  J or left-click strike")
	lines.append("Q sweep  /  Space dodge  /  F supplies  /  I close archive")
	_content.text = "\n".join(lines)
	_content.scroll_to_line(0)


func _safe_bbcode(value: Variant) -> String:
	return String(value).replace("[", "[lb]")
