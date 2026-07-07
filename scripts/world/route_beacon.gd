class_name RouteBeacon
extends Interactable
## A dead roadside beacon the player can power with a little salvage.
##
## Reuses BaseUpgradeSystem for persistence (so a powered beacon stays lit
## after travelling or loading) -- no new build system. Powering it
## completes the optional "roadside beacon" objective and lights the road
## back toward the Railhome.

@export var upgrade_data: BaseUpgradeData

@onready var _lamp: Sprite2D = $Lamp
@onready var _glow: Polygon2D = $Glow

var _powered := false


func _ready() -> void:
	if upgrade_data != null and BaseUpgradeSystem.is_built(upgrade_data.id):
		_apply_powered()
	else:
		_lamp.modulate = Color(0.42, 0.45, 0.5)  # cold / dead
		_glow.visible = false


func is_available() -> bool:
	return not _powered


func get_prompt() -> String:
	return "Power the roadside beacon"


func interact(_player: Node2D) -> void:
	if _powered or upgrade_data == null:
		return
	if not BaseUpgradeSystem.can_afford(upgrade_data):
		EventBus.notice_posted.emit("The beacon is dead. It needs %s to power it." % _cost_text())
		return
	if BaseUpgradeSystem.build(upgrade_data):
		_apply_powered()
		EventBus.notice_posted.emit(
			"The roadside beacon hums to life.\nAmber light points the way back to the Railhome.")
		EventBus.camera_shake_requested.emit(1.5, 0.1)


func _apply_powered() -> void:
	_powered = true
	_lamp.modulate = Color(1, 1, 1)
	_glow.visible = true


func _cost_text() -> String:
	var parts: Array[String] = []
	for item_id in upgrade_data.cost:
		var amount := int(upgrade_data.cost[item_id])
		var data: ItemData = ItemDatabase.get_item(item_id)
		var nm := data.display_name if data != null else String(item_id)
		parts.append("%d %s" % [amount, nm])
	return ", ".join(parts)
