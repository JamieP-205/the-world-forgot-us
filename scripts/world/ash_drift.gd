extends Node2D
## Lightweight screen-local ash/dust drift.

@export var particle_count := 46
@export var area := Vector2(720, 420)
@export var drift := Vector2(-10, 7)

var _points: Array[Vector2] = []
var _speeds: Array[float] = []


func _ready() -> void:
	z_index = 100
	for i in particle_count:
		var x := fposmod(float(i * 97), area.x) - area.x * 0.5
		var y := fposmod(float(i * 53), area.y) - area.y * 0.5
		_points.append(Vector2(x, y))
		_speeds.append(0.45 + float(i % 5) * 0.16)


func _process(delta: float) -> void:
	for i in _points.size():
		var p := _points[i] + drift * _speeds[i] * delta
		if p.x < -area.x * 0.5:
			p.x = area.x * 0.5
		if p.y > area.y * 0.5:
			p.y = -area.y * 0.5
		_points[i] = p
	queue_redraw()


func _draw() -> void:
	for i in _points.size():
		var alpha := 0.18 + float(i % 3) * 0.05
		draw_circle(_points[i], 1.1 + float(i % 2) * 0.6, Color(0.72, 0.72, 0.66, alpha))
