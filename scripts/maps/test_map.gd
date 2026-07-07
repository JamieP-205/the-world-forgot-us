extends Node2D
## Content pass scene glue for the current hand-built demo map.

@onready var _mast_glow: Polygon2D = $RadioMast/RecoveredGlow
@onready var _spark_a: Polygon2D = $RadioMast/StaticSparkA
@onready var _spark_b: Polygon2D = $RadioMast/StaticSparkB
@onready var _spark_c: Polygon2D = $RadioMast/StaticSparkC

var _time := 0.0
var _recovered := false


func _ready() -> void:
	ArchiveSystem.echo_recorded.connect(_on_echo_recorded)
	if ArchiveSystem.has_echo(&"echo_last_signal"):
		_apply_mast_recovered()


func _process(delta: float) -> void:
	_time += delta
	var cold_alpha := 0.34 + sin(_time * 4.1) * 0.12
	if _recovered:
		var warm_alpha := 0.24 + sin(_time * 2.3) * 0.08
		_mast_glow.color = Color(1.0, 0.86, 0.42, warm_alpha)
	else:
		_spark_a.color.a = cold_alpha
		_spark_b.color.a = cold_alpha * 0.8
		_spark_c.color.a = cold_alpha * 0.65


func _on_echo_recorded(data: MemoryEchoData) -> void:
	if data != null and data.id == &"echo_last_signal":
		_apply_mast_recovered()


func _apply_mast_recovered() -> void:
	_recovered = true
	_mast_glow.visible = true
	_spark_a.color = Color(1.0, 0.86, 0.42, 0.75)
	_spark_b.color = Color(1.0, 0.86, 0.42, 0.65)
	_spark_c.color = Color(1.0, 0.86, 0.42, 0.55)
