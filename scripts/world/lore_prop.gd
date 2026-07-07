class_name LoreProp
extends Interactable
## Small readable/scannable world detail.
##
## Used for atmospheric props only. It posts a short notice when interacted
## with, and can optionally react to a child Scannable node.

@export_multiline var notice: String = ""
@export_multiline var scanned_notice: String = ""

var _scanned := false


func _ready() -> void:
	var scannable := get_node_or_null("Scannable")
	if scannable is Scannable:
		(scannable as Scannable).scanned.connect(_on_scanned)


func interact(_player: Node2D) -> void:
	if not notice.is_empty():
		EventBus.notice_posted.emit(notice)


func _on_scanned() -> void:
	if _scanned:
		return
	_scanned = true
	var text := scanned_notice if not scanned_notice.is_empty() else notice
	if not text.is_empty():
		EventBus.notice_posted.emit(text)
