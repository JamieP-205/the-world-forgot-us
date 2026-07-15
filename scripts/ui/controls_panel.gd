extends Control
## Reusable controls + objective help overlay, shown from the main menu and
## the pause menu. Touch devices get a condensed two-thumb guide so the text
## remains readable through the expanded game canvas.

signal closed

@onready var _card: PanelContainer = $Card
@onready var _margin: MarginContainer = $Card/Margin
@onready var _grid: GridContainer = $Card/Margin/Box/Grid
@onready var _title: Label = $Card/Margin/Box/Header/Title
@onready var _dismiss_hint: Label = $Card/Margin/Box/Header/DismissHint
@onready var _callout: Label = $Card/Margin/Box/Callout/Margin/Hint
@onready var _back: Button = $Card/Margin/Box/Back

var _touch_ui := false

const MOBILE_HIDDEN_ROWS := [
	"BurstAction", "BurstKey", "RationAction", "RationKey",
	"ArchiveAction", "ArchiveKey", "PauseAction", "PauseKey",
	"MapAction", "MapKey",
]


func _ready() -> void:
	_touch_ui = _is_touch_device()
	_back.pressed.connect(func() -> void: closed.emit())
	get_viewport().size_changed.connect(_apply_responsive_layout)
	call_deferred("_apply_responsive_layout")


func _is_touch_device() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("web_android") \
		or OS.has_feature("web_ios") or DisplayServer.is_touchscreen_available()


func _physical_scale() -> float:
	var window_size := Vector2(DisplayServer.window_get_size())
	if window_size.x <= 1.0 or window_size.y <= 1.0 or size.x <= 1.0 or size.y <= 1.0:
		return 1.0
	return maxf(0.05, minf(window_size.x / size.x, window_size.y / size.y))


func _apply_responsive_layout() -> void:
	if not is_node_ready() or size.x <= 1.0 or size.y <= 1.0:
		return
	var window_size := Vector2(DisplayServer.window_get_size())
	var portrait := window_size.y > window_size.x

	if _touch_ui:
		_apply_touch_copy()
		var physical := _physical_scale()
		var requested_scale := clampf(0.92 / physical, 1.0, 2.85)
		var base_size := Vector2(620.0, 620.0) if portrait else Vector2(900.0, 520.0)
		var edge := 16.0 * requested_scale
		var card_scale := minf(
			requested_scale,
			(size.x - edge * 2.0) / base_size.x,
			(size.y - edge * 2.0) / base_size.y
		)
		card_scale = maxf(0.72, card_scale)
		_card.set_anchors_preset(Control.PRESET_TOP_LEFT)
		_card.pivot_offset = Vector2.ZERO
		_card.scale = Vector2.ONE * card_scale
		_card.size = base_size
		_card.position = Vector2(
			(size.x - base_size.x * card_scale) * 0.5,
			(size.y - base_size.y * card_scale) * 0.5
		)
		_grid.columns = 2 if portrait else 4
		_margin.add_theme_constant_override("margin_left", 20)
		_margin.add_theme_constant_override("margin_top", 20)
		_margin.add_theme_constant_override("margin_right", 20)
		_margin.add_theme_constant_override("margin_bottom", 18)
		_title.add_theme_font_size_override("font_size", 40 if portrait else 34)
		_dismiss_hint.add_theme_font_size_override("font_size", 15)
		_back.custom_minimum_size = Vector2(230.0, 62.0)
		_back.add_theme_font_size_override("font_size", 19)
		_set_grid_widths(118.0 if portrait else 122.0, 300.0 if portrait else 270.0, 19)
	else:
		_apply_desktop_copy()
		_card.set_anchors_preset(Control.PRESET_CENTER)
		_card.scale = Vector2.ONE
		_card.position = Vector2(size.x * 0.5 - 480.0, size.y * 0.5 - 286.0)
		_card.size = Vector2(960.0, 572.0)
		_grid.columns = 4
		_margin.add_theme_constant_override("margin_left", 42)
		_margin.add_theme_constant_override("margin_top", 32)
		_margin.add_theme_constant_override("margin_right", 42)
		_margin.add_theme_constant_override("margin_bottom", 30)
		_title.add_theme_font_size_override("font_size", 34)
		_dismiss_hint.add_theme_font_size_override("font_size", 11)
		_back.custom_minimum_size = Vector2(210.0, 42.0)
		_back.add_theme_font_size_override("font_size", 15)
		_set_grid_widths(130.0, 260.0, 14)


func _set_grid_widths(action_width: float, key_width: float, font_size: int) -> void:
	for child in _grid.get_children():
		if not child is Label:
			continue
		var label := child as Label
		var is_key := String(label.name).ends_with("Key")
		label.custom_minimum_size = Vector2(key_width if is_key else action_width, 44.0 if _touch_ui else 36.0)
		label.add_theme_font_size_override("font_size", font_size)


func _set_mobile_rows_visible(visible: bool) -> void:
	for node_name in MOBILE_HIDDEN_ROWS:
		var node := _grid.get_node_or_null(node_name)
		if node != null:
			node.visible = visible


func _apply_touch_copy() -> void:
	_set_mobile_rows_visible(false)
	$Card/Margin/Box/Eyebrow.text = "CARRIAGE 317 FIELD MANUAL  /  TOUCH ISSUE"
	_title.text = "PHONE FIELD GUIDE"
	_dismiss_hint.text = "TAP RETURN TO CLOSE"
	$Card/Margin/Box/Grid/MoveAction.text = "MOVE"
	$Card/Margin/Box/Grid/MoveKey.text = "DRAG LOWER-LEFT"
	$Card/Margin/Box/Grid/InteractAction.text = "ACTIONS"
	$Card/Margin/Box/Grid/InteractKey.text = "USE / HIT / SCAN / DODGE"
	$Card/Margin/Box/Grid/ScanAction.text = "FIELD TOOLS"
	$Card/Margin/Box/Grid/ScanKey.text = "HEAL / BURST"
	$Card/Margin/Box/Grid/AttackAction.text = "RECORDS"
	$Card/Margin/Box/Grid/AttackKey.text = "MAP / LOG"
	$Card/Margin/Box/Grid/DodgeAction.text = "SYSTEM"
	$Card/Margin/Box/Grid/DodgeKey.text = "HELP / MENU"
	_callout.text = "TWO-THUMB LAYOUT  /  Drag anywhere in the lower-left field to move. The right cluster handles the road. HELP reopens the quick guide. Dialogue and menus use their own large on-screen buttons."


func _apply_desktop_copy() -> void:
	_set_mobile_rows_visible(true)
	$Card/Margin/Box/Eyebrow.text = "CARRIAGE 317 FIELD MANUAL  /  ISSUE 04"
	_title.text = "FIELD GUIDE"
	_dismiss_hint.text = "SELECT RETURN TO CLOSE"
	$Card/Margin/Box/Grid/MoveAction.text = "MOVE"
	$Card/Margin/Box/Grid/MoveKey.text = "WASD  /  ARROW KEYS"
	$Card/Margin/Box/Grid/InteractAction.text = "INTERACT"
	$Card/Margin/Box/Grid/InteractKey.text = "E"
	$Card/Margin/Box/Grid/ScanAction.text = "SCAN / REVEAL"
	$Card/Margin/Box/Grid/ScanKey.text = "Q  /  RIGHT MOUSE"
	$Card/Margin/Box/Grid/AttackAction.text = "MELEE"
	$Card/Margin/Box/Grid/AttackKey.text = "J  /  LEFT MOUSE"
	$Card/Margin/Box/Grid/DodgeAction.text = "DODGE"
	$Card/Margin/Box/Grid/DodgeKey.text = "SPACE"
	$Card/Margin/Box/Grid/BurstKey.text = "R  /  UNLOCKS IN ACT II"
	$Card/Margin/Box/Grid/RationKey.text = "F"
	$Card/Margin/Box/Grid/ArchiveKey.text = "I"
	$Card/Margin/Box/Grid/PauseKey.text = "ESC"
	$Card/Margin/Box/Grid/MapKey.text = "M"
	_callout.text = "TRACE RECEIVER  /  Sweeps expose hidden recordings and carrier Bleeds, and can overload insulated relay suits. Complete field records open safer choices at Tollard."
