extends Node
## Renders every enterable interior without requiring a campaign save. Run with
## a real renderer (not --headless); output under builds/ is not exported.

const INTERIOR_SCENE := preload("res://scenes/interiors/building_interior.tscn")
const BuildingCatalog = preload("res://scripts/world/building_catalog.gd")
const OUTPUT_DIR := "res://builds/visual_qa/interiors"
const CAPTURE_SIZE := Vector2i(1280, 720)

var _failed := false


func _ready() -> void:
	call_deferred("_capture_all")


func _capture_all() -> void:
	var world_before := WorldState.get_state()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	for building_value in BuildingCatalog.BUILDINGS:
		await _capture(StringName(building_value))
	WorldState.restore(world_before)
	if _failed:
		push_error("INTERIOR IDENTITY VISUAL CAPTURE: FAIL")
		get_tree().quit(1)
		return
	print("INTERIOR IDENTITY VISUAL CAPTURE: PASS (19 buildings)")
	get_tree().quit(0)


func _capture(building_id: StringName) -> void:
	WorldState.set_flag(&"active_interior_id", String(building_id))
	var viewport := SubViewport.new()
	viewport.name = "Capture_%s" % String(building_id)
	viewport.size = CAPTURE_SIZE
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	add_child(viewport)

	var interior := INTERIOR_SCENE.instantiate() as BuildingInterior
	viewport.add_child(interior)
	var camera := Camera2D.new()
	camera.name = "CaptureCamera"
	camera.enabled = true
	var rooms := int(BuildingCatalog.get_building(building_id).get("rooms", 1))
	var width := 420.0 * float(rooms) + 100.0
	var framing := minf(1160.0 / (width + 100.0), 620.0 / 600.0)
	camera.zoom = Vector2.ONE * framing
	interior.add_child(camera)

	for frame in 4:
		await get_tree().process_frame
	RenderingServer.force_draw(false)
	var image := viewport.get_texture().get_image()
	if image == null:
		_failed = true
		push_error("Could not read rendered interior capture %s" % building_id)
		viewport.queue_free()
		await get_tree().process_frame
		return
	var path := "%s/%s.png" % [OUTPUT_DIR, String(building_id)]
	var error := image.save_png(ProjectSettings.globalize_path(path))
	if error != OK:
		_failed = true
		push_error("Could not save interior capture %s: %s" % [building_id, error_string(error)])
	viewport.queue_free()
	await get_tree().process_frame
