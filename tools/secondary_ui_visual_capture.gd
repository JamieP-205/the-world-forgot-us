extends Control
## Optional rendered QA companion. It captures the secondary screens to
## user://secondary_ui_capture without changing saves or campaign state.

const CASES := [
	{"name": "menu", "path": "res://scenes/ui/main_menu.tscn"},
	{"name": "map", "path": "res://scenes/ui/map_screen.tscn"},
	{"name": "archive", "path": "res://scenes/ui/archive_overlay.tscn"},
	{"name": "ending", "path": "res://scenes/ui/ending_overlay.tscn"},
	{"name": "controls", "path": "res://scenes/ui/controls_panel.tscn"},
	{"name": "opening", "path": "res://scenes/ui/opening_cinematic.tscn"},
	{"name": "settings", "path": "res://scenes/ui/settings_panel.tscn"},
	{"name": "dialogue", "path": "res://scenes/ui/dialogue_overlay.tscn"},
]


func _ready() -> void:
	call_deferred("_capture_all")


func _capture_all() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://secondary_ui_capture"))
	for entry in CASES:
		var packed := load(entry.path) as PackedScene
		if packed == null:
			push_error("UI CAPTURE: could not load %s" % entry.path)
			get_tree().quit(1)
			return
		var screen := packed.instantiate() as Control
		add_child(screen)
		var view := get_viewport_rect().size
		_prepare_screen(String(entry.name), screen, view)
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var image := get_viewport().get_texture().get_image()
		var target := "user://secondary_ui_capture/%s_%dx%d.png" % [entry.name, roundi(view.x), roundi(view.y)]
		var error := image.save_png(target)
		if error != OK:
			push_error("UI CAPTURE: failed %s (%s)" % [target, error_string(error)])
			screen.free()
			get_tree().quit(1)
			return
		print("UI CAPTURE: %s -> %s" % [entry.name, ProjectSettings.globalize_path(target)])
		screen.free()
		await get_tree().process_frame
	print("SECONDARY_UI_VISUAL_CAPTURE: PASS")
	get_tree().quit(0)


func _prepare_screen(case_name: String, screen: Control, view: Vector2) -> void:
	var window_size := Vector2(DisplayServer.window_get_size())
	var phone_layout := minf(window_size.x, window_size.y) < 900.0 and window_size != Vector2(1280, 720)
	match case_name:
		"menu":
			if phone_layout:
				screen.set("_touch_ui", true)
				screen.call("_apply_responsive_layout")
			else:
				screen.apply_responsive_layout(view, 0)
		"map":
			screen.visible = true
			screen.apply_responsive_layout(view)
		"archive":
			screen.visible = true
			screen.call("_refresh")
			screen.apply_responsive_layout(view)
		"ending":
			screen.call("_show_ending", {
				"title": "The line we left",
				"subtitle": "A field record is never neutral.",
				"body": "Ellie left both versions beside the receiver. One named the people Tollard had edited out. The other named the frightened people who had helped it. At dawn, the first answer came from somewhere that should have been empty.",
				"stats": "10 traces filed  /  4 people brought home  /  the copy heard nothing",
				"accent": Color(0.73, 0.44, 0.18),
			})
			screen.apply_responsive_layout(view)
		"controls":
			screen.visible = true
			if phone_layout:
				screen.set("_touch_ui", true)
				screen.call("_apply_responsive_layout")
			else:
				screen.apply_responsive_layout(view, 0)
		"opening":
			screen.visible = true
			screen.set("_running", true)
			screen.call("_show_beat")
			if phone_layout:
				screen.set("_touch_ui", true)
				screen.call("_apply_responsive_layout")
			else:
				screen.apply_responsive_layout(view, 0)
		"settings":
			screen.visible = true
			screen.call("_sync")
			if phone_layout:
				screen.set("_touch_ui", true)
				screen.call("_apply_responsive_layout")
			else:
				screen.apply_responsive_layout(view, 0)
		"dialogue":
			if phone_layout:
				screen.set("_touch_ui", true)
			screen.call("_show_dialogue", {
				"id": &"ui_capture_dialogue",
				"title": "Maggie Vale  /  weak receiver line",
				"provenance": "Flooded cutting recorder · carrier identity unresolved",
				"lines": [
					"The first account says Tollard closed the cutting before the rain. " \
					+ "The second says we were still below it when the gates came down. " \
					+ "I have played both tapes until the oxide lifted, and the same breath " \
					+ "waits behind my own voice. If you file this, file the doubt with it. " \
					+ "The hinge report, flood roster and last carrier log disagree in three " \
					+ "different hands. None admits who held the gate lever.",
				],
				"choices": [
					"File both recordings together and name every contradiction.",
					"Keep the second account private until Imogen checks the gate ledger.",
					"Broadcast Maggie's warning now, before Tollard can answer it.",
					"Ask whose breath is hiding beneath the carrier tone.",
				],
				"accent": Color(0.31, 0.72, 0.69),
			})
			screen.call("_show_choices")
			if phone_layout:
				screen.call("_apply_responsive_layout")
			else:
				screen.apply_responsive_layout(view, 0)
