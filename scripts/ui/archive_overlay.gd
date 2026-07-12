class_name ArchiveOverlay
extends Control
## In-game archive: recovered memories, campaign progress, and controls.

@onready var _content: Label = $Center/Panel/Margin/Layout/Scroll/Content
@onready var _close: Button = $Center/Panel/Margin/Layout/Close


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
	var lines: Array[String] = [
		"RECOVERED MEMORY ARCHIVE",
		"",
	]
	var recovered := ArchiveSystem.get_recovered()
	if recovered.is_empty():
		lines.append("No echoes recovered. Use Q near cyan disturbances.")
	for echo in recovered:
		lines.append("%s  |  %s  |  %s" % [echo.title, echo.category, echo.quality])
		lines.append(echo.memory_text)
		lines.append("")
	lines.append("CAMPAIGN")
	lines.append("Relays restored: %d / 3" % CampaignSystem.get_restored_relay_count())
	lines.append("Memory Burst: %s" % ("ONLINE [R]" if WorldState.has_flag(&"memory_burst_unlocked") else "LOCKED"))
	lines.append("")
	lines.append("FIELD CONTROLS")
	lines.append("WASD / Arrows move   |   E interact   |   J / Left-click melee")
	lines.append("Q / Right-click scan   |   Space dodge   |   R Memory Burst")
	lines.append("F eat ration   |   I archive   |   Esc pause")
	_content.text = "\n".join(lines)
