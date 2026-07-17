class_name BaseUpgradeBench
extends Interactable
## Shared Railhome bench behaviour for upgrades represented by physical props.
##
## Unlike BaseUpgradeStation (which drives the Radio Desk's bespoke visuals),
## this one just builds any BaseUpgradeData with a material cost, shows the cost
## in its prompt, gives a payoff notice, and optionally reveals a linked node
## (e.g. a warm glow) when built. Built state persists via BaseUpgradeSystem.

@export var upgrade_data: BaseUpgradeData
@export_multiline var payoff_notice: String = ""
## Optional node (relative path) to make visible once built.
@export var reveal_on_build: NodePath
## Dim tint while unbuilt, restored to white when built.
@export var unbuilt_tint: Color = Color(0.55, 0.6, 0.66)

@onready var _visual: Node2D = get_node_or_null("Visual")

var _built := false


func _ready() -> void:
	apply_built_state(upgrade_data != null and BaseUpgradeSystem.is_built(upgrade_data.id))


func is_available() -> bool:
	return not _built


func get_prompt() -> String:
	if upgrade_data == null:
		return "Build upgrade"
	return "Build %s (%s)" % [_title(), _cost_text()]


func interact(_player: Node2D) -> void:
	if _built or upgrade_data == null:
		return
	if not BaseUpgradeSystem.can_afford(upgrade_data):
		EventBus.notice_posted.emit(
			"Not enough materials for the %s. Needs: %s." % [_title(), _cost_text()])
		return
	if BaseUpgradeSystem.build(upgrade_data):
		_built = true
		_apply_built()
		# BaseUpgradeSystem.upgrade_built -> AudioManager plays the build sound.
		EventBus.notice_posted.emit(
			payoff_notice if payoff_notice != "" else "%s built." % _title())
		EventBus.camera_shake_requested.emit(1.4, 0.1)


func _apply_built() -> void:
	if _visual != null:
		_visual.visible = true
		_visual.modulate = Color(1, 1, 1)
	if reveal_on_build != NodePath(""):
		var n := get_node_or_null(reveal_on_build)
		if n != null:
			n.visible = true


## Keeps an already-instanced shelter in step with save restoration and
## preview state. The durable source of truth remains BaseUpgradeSystem.
func apply_built_state(built: bool) -> void:
	_built = built
	if _visual != null:
		_visual.visible = true
		_visual.modulate = Color.WHITE if built else unbuilt_tint
	if reveal_on_build != NodePath(""):
		var revealed := get_node_or_null(reveal_on_build)
		if revealed != null:
			revealed.visible = built


func _title() -> String:
	return upgrade_data.title if upgrade_data != null else "Upgrade"


func _cost_text() -> String:
	if upgrade_data == null:
		return "materials"
	var parts: Array[String] = []
	for item_id in upgrade_data.cost:
		var amount := int(upgrade_data.cost[item_id])
		var data: ItemData = ItemDatabase.get_item(item_id)
		var nm := data.display_name if data != null else String(item_id)
		parts.append("%d %s" % [amount, nm])
	return ", ".join(parts)
