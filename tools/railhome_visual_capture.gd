extends Node
## Renders the whole carriage at gameplay scale so fixture overlap, wall
## collision registration and accidental background duplication are visible.

const BASE_SCENE := preload("res://scenes/base/railhome_base.tscn")
const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const OUTPUT := "res://builds/visual_qa/railhome/carriage.png"


func _ready() -> void:
	call_deferred("_capture")


func _capture() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(
		"res://builds/visual_qa/railhome"))
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	add_child(viewport)

	var base := BASE_SCENE.instantiate()
	viewport.add_child(base)
	var player := PLAYER_SCENE.instantiate() as Player
	player.position = Vector2.ZERO
	viewport.add_child(player)
	var player_camera := player.get_node_or_null("Camera2D") as Camera2D
	if player_camera != null:
		player_camera.enabled = false

	var camera := Camera2D.new()
	camera.enabled = true
	camera.zoom = Vector2(0.94, 0.94)
	viewport.add_child(camera)
	for frame in 5:
		await get_tree().process_frame
	RenderingServer.force_draw(false)
	var image := viewport.get_texture().get_image()
	if image == null or image.save_png(ProjectSettings.globalize_path(OUTPUT)) != OK:
		push_error("RAILHOME VISUAL CAPTURE: FAIL")
		get_tree().quit(1)
		return
	print("RAILHOME VISUAL CAPTURE: PASS")
	get_tree().quit(0)
