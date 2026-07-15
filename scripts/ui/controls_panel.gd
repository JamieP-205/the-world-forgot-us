extends Control
## Reusable controls + objective help overlay, shown from the main menu and
## the pause menu. Emits `closed` when the player dismisses it so the parent
## can restore its own UI.

signal closed

@onready var _card: PanelContainer = $Card
@onready var _grid: GridContainer = $Card/Margin/Box/Grid
@onready var _dismiss_hint: Label = $Card/Margin/Box/Header/DismissHint
@onready var _callout: Label = $Card/Margin/Box/Callout/Margin/Hint
@onready var _back: Button = $Card/Margin/Box/Back

var _touch_ui := false


func _ready() -> void:
	_touch_ui = _is_touch_device()
	_back.pressed.connect(func() -> void: closed.emit())
	get_viewport().size_changed.connect(_apply_responsive_layout)
	call_deferred("_apply_responsive_layout")


func _is_touch_device() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("web_android") \
		or OS.has_feature("web_ios") or DisplayServer.is_touchscreen_available()


func _apply_responsive_layout() -> void:
	if not is_node_ready() or size.x <= 1.0 or size.y <= 1.0:
		return
	var window_size := Vector2(DisplayServer.window_get_size())
	var portrait := window_size.y > window_size.x

	if _touch_ui:
		_apply_touch_copy()
		var width := minf(size.x - 32.0, 680.0 if portrait else 960.0)
		var height := minf(size.y - 32.0, 690.0 if portrait else 572.0)
		_card.position = Vector2((size.x - width) * 0.5, (size.y - height) * 0.5)
		_card.size = Vector2(width, height)
		_grid.columns = 2 if portrait else 4
		_back.custom_minimum_size = Vector2(230.0, 52.0)
		_set_grid_widths(122.0 if portrait else 130.0, 220.0 if portrait else 260.0)
	else:
		_apply_desktop_copy()
		_card.position = Vector2(size.x * 0.5 - 480.0, size.y * 0.5 - 286.0)
		_card.size = Vector2(960.0, 572.0)
		_grid.columns = 4
		_back.custom_minimum_size = Vector2(210.0, 42.0)
		_set_grid_widths(130.0, 260.0)


func _set_grid_widths(action_width: float, key_width: float) -> void:
	for child in _grid.get_children():
		if not child is Label:
			continue
		var label := child as Label
		label.custom_minimum_size = Vector2(key_width if label.name.ends_with("Key") else action_width, 40.0 if _touch_ui else 36.0)


func _apply_touch_copy() -> void:
	$Card/Margin/Box/Eyebrow.text = "CARRIAGE 317 FIELD MANUAL  /  TOUCH ISSUE"
	$Card/Margin/Box/Header/Title.text = "PHONE FIELD GUIDE"
	_dismiss_hint.text = "TAP RETURN TO CLOSE"
	$Card/Margin/Box/Grid/MoveKey.text = "DRAG LOWER-LEFT"
	$Card/Margin/Box/Grid/InteractKey.text = "USE"
	$Card/Margin/Box/Grid/ScanKey.text = "SCAN"
	$Card/Margin/Box/Grid/AttackKey.text = "HIT"
	$Card/Margin/Box/Grid/DodgeKey.text = "DODGE"
	$Card/Margin/Box/Grid/BurstKey.text = "BURST  /  ACT II"
	$Card/Margin/Box/Grid/RationKey.text = "HEAL"
	$Card/Margin/Box/Grid/ArchiveKey.text = "LOG"
	$Card/Margin/Box/Grid/PauseKey.text = "MENU"
	$Card/Margin/Box/Grid/MapKey.text = "MAP"
	_callout.text = "TWO-THUMB LAYOUT  /  Drag in the lower-left to move. USE, HIT, SCAN and DODGE sit on the right. HELP reopens the quick touch guide. Dialogue and menus use their own large on-screen buttons."


func _apply_desktop_copy() -> void:
	$Card/Margin/Box/Eyebrow.text = "CARRIAGE 317 FIELD MANUAL  /  ISSUE 04"
	$Card/Margin/Box/Header/Title.text = "FIELD GUIDE"
	_dismiss_hint.text = "SELECT RETURN TO CLOSE"
	$Card/Margin/Box/Grid/MoveKey.text = "WASD  /  ARROW KEYS"
	$Card/Margin/Box/Grid/InteractKey.text = "E"
	$Card/Margin/Box/Grid/ScanKey.text = "Q  /  RIGHT MOUSE"
	$Card/Margin/Box/Grid/AttackKey.text = "J  /  LEFT MOUSE"
	$Card/Margin/Box/Grid/DodgeKey.text = "SPACE"
	$Card/Margin/Box/Grid/BurstKey.text = "R  /  UNLOCKS IN ACT II"
	$Card/Margin/Box/Grid/RationKey.text = "F"
	$Card/Margin/Box/Grid/ArchiveKey.text = "I"
	$Card/Margin/Box/Grid/PauseKey.text = "ESC"
	$Card/Margin/Box/Grid/MapKey.text = "M"
	_callout.text = "TRACE RECEIVER  /  Sweeps expose hidden recordings and carrier Bleeds, and can overload insulated relay suits. Complete field records open safer choices at Tollard."
