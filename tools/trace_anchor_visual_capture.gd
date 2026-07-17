extends Node2D
## Renders the same ordinary object through every Trace Anchor light state.

const ANCHOR_SCENE := preload("res://scenes/world/memory_echo.tscn")
const TRACE_DATA := preload("res://resources/echoes/echo_last_signal.tres")
const OUTPUT_PATH := "res://builds/visual_qa/trace_anchor_stages.png"
const CAPTURE_SIZE := Vector2i(1280, 720)

var _archive_before: Array
var _dispositions_before: Dictionary
var _capture_viewport: SubViewport
var _stage_root: Node2D


func _ready() -> void:
	call_deferred("_capture")


func _capture() -> void:
	_archive_before = ArchiveSystem.get_recovered_ids()
	_dispositions_before = ArchiveSystem.get_dispositions()
	ArchiveSystem.restore([])
	GameManager.set_dialogue_active(false)
	_capture_viewport = SubViewport.new()
	_capture_viewport.name = "TraceCaptureViewport"
	_capture_viewport.size = CAPTURE_SIZE
	_capture_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_capture_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	_capture_viewport.transparent_bg = false
	_capture_viewport.disable_3d = true
	_capture_viewport.gui_disable_input = true
	add_child(_capture_viewport)
	_stage_root = Node2D.new()
	_stage_root.name = "Stage"
	_capture_viewport.add_child(_stage_root)
	_build_backdrop()

	var stages := [&"hidden", &"detected", &"focused", &"revealed"]
	var captions := [
		"Ordinary carrier\nNo emitted light",
		"Receiver catches the edge\n52 px local radius",
		"Noise resolves on the object\n86 px practical radius",
		"Object and residue align\n118 px lit radius",
	]
	for index in stages.size():
		var anchor := ANCHOR_SCENE.instantiate() as MemoryEcho
		anchor.name = "Capture_%s" % String(stages[index])
		anchor.echo_data = TRACE_DATA
		anchor.position = Vector2(174.0 + 310.0 * index, 380.0)
		_stage_root.add_child(anchor)
		anchor.call("_on_setting_changed", "accessibility", "reduced_effects", false)
		if index >= 1:
			anchor.detect_from(anchor.position + Vector2(-70, 0))
		if index >= 2:
			anchor.focus_trace(anchor.position + Vector2(-28, 0))
			(anchor.get_node("TraceAnchorOverlay") as TraceAnchorOverlay).close_overlay()
		if index >= 3:
			anchor.reveal_trace()
			(anchor.get_node("TraceAnchorOverlay") as TraceAnchorOverlay).close_overlay()
		_add_caption(index, String(stages[index]).to_upper(), captions[index])

	for frame in 6:
		await get_tree().process_frame
	await get_tree().create_timer(0.46).timeout
	var image := await _read_complete_frame()
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(OUTPUT_PATH.get_base_dir())
	)
	var error := FAILED if image == null else image.save_png(ProjectSettings.globalize_path(OUTPUT_PATH))
	ArchiveSystem.restore(_archive_before, _dispositions_before)
	GameManager.set_dialogue_active(false)
	_capture_viewport.free()
	_capture_viewport = null
	_stage_root = null
	await get_tree().process_frame
	if error != OK:
		push_error("TRACE ANCHOR VISUAL CAPTURE: %s" % error_string(error))
		get_tree().quit(1)
		return
	print("TRACE ANCHOR VISUAL CAPTURE: PASS -> %s" % ProjectSettings.globalize_path(OUTPUT_PATH))
	get_tree().quit(0)


func _read_complete_frame() -> Image:
	# Some Windows compatibility drivers briefly return a partially populated
	# offscreen texture while shader pipelines settle. Reject that readback by
	# checking the fixed title strip, then ask for another complete frame.
	for attempt in 6:
		for frame in 4:
			await get_tree().process_frame
		RenderingServer.force_draw(false)
		await RenderingServer.frame_post_draw
		var image := _capture_viewport.get_texture().get_image()
		if _frame_has_title(image):
			return image
		print("TRACE ANCHOR VISUAL CAPTURE: retrying incomplete frame %d" % (attempt + 1))
	return null


func _frame_has_title(image: Image) -> bool:
	if image == null or image.get_size() != CAPTURE_SIZE:
		return false
	var bright_samples := 0
	for y in range(28, 108, 4):
		for x in range(32, 660, 4):
			var pixel := image.get_pixel(x, y)
			if pixel.a >= 0.9 and pixel.get_luminance() >= 0.28:
				bright_samples += 1
	return bright_samples >= 24


func _build_backdrop() -> void:
	var tint := CanvasModulate.new()
	tint.color = Color(0.55, 0.58, 0.53)
	_stage_root.add_child(tint)
	var floor := Polygon2D.new()
	floor.name = "AshFloor"
	floor.z_index = -20
	floor.polygon = PackedVector2Array([
		Vector2.ZERO,
		Vector2(CAPTURE_SIZE.x, 0),
		Vector2(CAPTURE_SIZE.x, CAPTURE_SIZE.y),
		Vector2(0, CAPTURE_SIZE.y),
	])
	floor.color = Color(0.16, 0.18, 0.16)
	_stage_root.add_child(floor)
	for row in 8:
		var seam := Line2D.new()
		seam.z_index = -19
		seam.width = 2.0
		seam.default_color = Color(0.32, 0.34, 0.29, 0.26)
		var y := 144.0 + float(row) * 64.0
		seam.points = PackedVector2Array([Vector2(0, y), Vector2(CAPTURE_SIZE.x, y - 21.0)])
		_stage_root.add_child(seam)
	for column in 3:
		var divider := Line2D.new()
		divider.z_index = -18
		divider.width = 1.0
		divider.default_color = Color(0.64, 0.68, 0.57, 0.16)
		var x := 329.0 + float(column) * 310.0
		divider.points = PackedVector2Array([Vector2(x, 120), Vector2(x, 640)])
		_stage_root.add_child(divider)

	var ui := CanvasLayer.new()
	ui.name = "Captions"
	ui.layer = 5
	_stage_root.add_child(ui)
	var title := Label.new()
	title.position = Vector2(44, 32)
	title.text = "TRACE ANCHOR / LIGHTING PROGRESSION"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.88, 0.85, 0.72))
	ui.add_child(title)
	var subtitle := Label.new()
	subtitle.position = Vector2(46, 72)
	subtitle.text = "Fallen-mast receiver and folded photograph — physical evidence"
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.add_theme_color_override("font_color", Color(0.65, 0.7, 0.62))
	ui.add_child(subtitle)


func _add_caption(index: int, stage_name: String, body: String) -> void:
	var ui := _stage_root.get_node("Captions") as CanvasLayer
	var heading := Label.new()
	heading.position = Vector2(58.0 + 310.0 * index, 568.0)
	heading.size = Vector2(258, 30)
	heading.text = "%02d / %s" % [index, stage_name]
	heading.add_theme_font_size_override("font_size", 17)
	heading.add_theme_color_override("font_color", Color(0.85, 0.82, 0.68))
	ui.add_child(heading)
	var detail := Label.new()
	detail.position = Vector2(58.0 + 310.0 * index, 602.0)
	detail.size = Vector2(258, 70)
	detail.text = body
	detail.add_theme_font_size_override("font_size", 13)
	detail.add_theme_color_override("font_color", Color(0.66, 0.7, 0.63))
	ui.add_child(detail)
