extends Node
## Wide rendered review for the generated campaign regions. It catches
## material cards, prop-scale architecture and disconnected route geometry.
## Run with a real renderer (not --headless).

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const OUTPUT_DIR := "res://builds/visual_qa/campaign_maps"
const CAPTURE_SIZE := Vector2i(1280, 720)
const MAPS := {
	"ashmere_verge": preload("res://scenes/maps/ashmere_verge.tscn"),
	"broadcast_fields": preload("res://scenes/maps/broadcast_fields.tscn"),
	"choir_core": preload("res://scenes/maps/choir_core.tscn"),
}

var _failed := false


func _ready() -> void:
	call_deferred("_capture_all")


func _capture_all() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	for map_name in MAPS:
		await _capture_map(map_name, MAPS[map_name] as PackedScene)
	if _failed:
		push_error("CAMPAIGN MAPS VISUAL CAPTURE: FAIL")
		get_tree().quit(1)
		return
	print("CAMPAIGN MAPS VISUAL CAPTURE: PASS (3 regions)")
	get_tree().quit(0)


func _capture_map(map_name: String, packed: PackedScene) -> void:
	var viewport := SubViewport.new()
	viewport.size = CAPTURE_SIZE
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	add_child(viewport)
	var map := packed.instantiate() as Node2D
	viewport.add_child(map)
	var player := PLAYER_SCENE.instantiate() as Player
	player.position = Vector2(0, 90)
	viewport.add_child(player)
	var player_camera := player.get_node_or_null("Camera2D") as Camera2D
	if player_camera != null:
		player_camera.enabled = false
	var camera := Camera2D.new()
	camera.enabled = true
	camera.position = Vector2.ZERO
	camera.zoom = Vector2(0.72, 0.72)
	viewport.add_child(camera)
	for frame in 5:
		await get_tree().process_frame
	RenderingServer.force_draw(false)
	var image := viewport.get_texture().get_image()
	var path := "%s/%s.png" % [OUTPUT_DIR, map_name]
	if image == null or image.save_png(ProjectSettings.globalize_path(path)) != OK:
		_failed = true
		push_error("Could not save campaign capture %s" % map_name)
	viewport.queue_free()
	await get_tree().process_frame
