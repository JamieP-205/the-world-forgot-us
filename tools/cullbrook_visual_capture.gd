extends Node
## Rendered QA for the opening route. This is deliberately wider than the
## player's camera so misplaced structures, duplicate doors and scale errors
## are visible in one review pass. Run with a real renderer (not --headless).

const MAP_SCENE := preload("res://scenes/maps/test_map.tscn")
const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const OUTPUT_DIR := "res://builds/visual_qa/cullbrook"
const CAPTURE_SIZE := Vector2i(1280, 720)

const VIEWS := {
	"railhome_approach": Vector2(-560, 250),
	"service_forecourt": Vector2(30, -20),
	"east_service_yard": Vector2(650, 280),
}

var _failed := false


func _ready() -> void:
	call_deferred("_capture_all")


func _capture_all() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var viewport := SubViewport.new()
	viewport.size = CAPTURE_SIZE
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	add_child(viewport)

	var map := MAP_SCENE.instantiate() as Node2D
	viewport.add_child(map)
	var player := PLAYER_SCENE.instantiate() as Player
	player.name = "VisualQAPlayer"
	player.position = Vector2(-690, 415)
	viewport.add_child(player)
	var player_camera := player.get_node_or_null("Camera2D") as Camera2D
	if player_camera != null:
		player_camera.enabled = false

	var camera := Camera2D.new()
	camera.enabled = true
	camera.zoom = Vector2(1.35, 1.35)
	viewport.add_child(camera)
	for frame in 4:
		await get_tree().process_frame

	for view_name in VIEWS:
		camera.position = VIEWS[view_name]
		player.position = VIEWS[view_name] + Vector2(-45, 90)
		for frame in 3:
			await get_tree().process_frame
		RenderingServer.force_draw(false)
		var image := viewport.get_texture().get_image()
		var path := "%s/%s.png" % [OUTPUT_DIR, view_name]
		if image == null or image.save_png(ProjectSettings.globalize_path(path)) != OK:
			_failed = true
			push_error("Could not save Cullbrook capture %s" % view_name)

	viewport.queue_free()
	await get_tree().process_frame
	if _failed:
		push_error("CULLBROOK VISUAL CAPTURE: FAIL")
		get_tree().quit(1)
		return
	print("CULLBROOK VISUAL CAPTURE: PASS (3 views)")
	get_tree().quit(0)
