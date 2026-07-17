class_name BaseUpgradeStation
extends Interactable
## An interactable that builds one base upgrade.

@export var upgrade_data: BaseUpgradeData

@onready var _power_light: Polygon2D = $Visual/PowerLight
@onready var _radio_body: Polygon2D = $Visual/RadioBody
@onready var _dial: Polygon2D = $Visual/Dial
@onready var _signal_glow: Polygon2D = $Visual/SignalGlow
@onready var _desk_sprite: Sprite2D = $Visual/DeskSprite

var _built: bool = false
var _time := 0.0


func _ready() -> void:
	apply_built_state(upgrade_data != null and BaseUpgradeSystem.is_built(upgrade_data.id))


func _process(delta: float) -> void:
	if not _built:
		return
	_time += delta
	# Warm amber signal halo to match the lit desk sprite.
	_signal_glow.color = Color(1.0, 0.8, 0.45, 0.14 + sin(_time * 2.5) * 0.06)


## Only offer the prompt while there's still something to build.
func is_available() -> bool:
	return not _built


func get_prompt() -> String:
	if upgrade_data == null:
		return "Build upgrade"
	return "Build %s (%s)" % [_title(), _cost_text()]


func interact(_player: Node2D) -> void:
	if _built or upgrade_data == null:
		return

	if upgrade_data.required_echo_id != &"" \
			and not ArchiveSystem.has_echo(upgrade_data.required_echo_id):
		EventBus.notice_posted.emit(
			"The %s needs a memory you haven't recovered yet." % _title())
		return

	if not BaseUpgradeSystem.can_afford(upgrade_data):
		EventBus.notice_posted.emit(
			"Not enough materials for the %s. Needs: %s." % [_title(), _cost_text()])
		return

	if BaseUpgradeSystem.build(upgrade_data):
		_built = true
		_apply_built_visual()
		# The short receiver cue confirms the desk has taken the line.
		EventBus.notice_posted.emit(
			"%s built.\nA weak signal repeats: NORTH ROAD... ANOTHER VOICE..."
			% _title())


func _apply_built_visual() -> void:
	_desk_sprite.modulate = Color(1, 1, 1)
	_power_light.visible = true
	_power_light.color = Color(0.4, 1.0, 0.55)
	_radio_body.color = Color(0.2, 0.32, 0.32)
	_dial.color = Color(0.78, 1.0, 0.88)
	_signal_glow.visible = true


## Re-applies the desk state when a save is restored after the scene exists.
func apply_built_state(built: bool) -> void:
	_built = built
	if built:
		_apply_built_visual()
		return
	_desk_sprite.modulate = Color(0.5, 0.55, 0.62)
	_power_light.visible = false
	_signal_glow.visible = false


func _title() -> String:
	return upgrade_data.title if upgrade_data != null else "Upgrade"


## Human-readable cost, e.g. "3 Scrap, 1 Battery".
func _cost_text() -> String:
	if upgrade_data == null:
		return "materials"
	var parts: Array[String] = []
	for item_id in upgrade_data.cost:
		var amount := int(upgrade_data.cost[item_id])
		var data: ItemData = ItemDatabase.get_item(item_id)
		var name := data.display_name if data != null else String(item_id)
		parts.append("%d %s" % [amount, name])
	return ", ".join(parts)
