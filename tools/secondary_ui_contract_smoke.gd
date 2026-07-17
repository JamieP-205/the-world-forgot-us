extends Node
## Contract for the physical secondary UI and its supported layouts.

const SCENES := {
	"menu": "res://scenes/ui/main_menu.tscn",
	"map": "res://scenes/ui/map_screen.tscn",
	"archive": "res://scenes/ui/archive_overlay.tscn",
	"ending": "res://scenes/ui/ending_overlay.tscn",
	"controls": "res://scenes/ui/controls_panel.tscn",
	"opening": "res://scenes/ui/opening_cinematic.tscn",
	"settings": "res://scenes/ui/settings_panel.tscn",
	"dialogue": "res://scenes/ui/dialogue_overlay.tscn",
}
const TARGET_SOURCES := [
	"res://scenes/ui/main_menu.tscn",
	"res://scripts/ui/main_menu.gd",
	"res://scenes/ui/map_screen.tscn",
	"res://scripts/ui/map_screen.gd",
	"res://scripts/ui/map_plot.gd",
	"res://scenes/ui/archive_overlay.tscn",
	"res://scripts/ui/archive_overlay.gd",
	"res://scenes/ui/ending_overlay.tscn",
	"res://scripts/ui/ending_overlay.gd",
	"res://scenes/ui/controls_panel.tscn",
	"res://scripts/ui/controls_panel.gd",
	"res://scenes/ui/opening_cinematic.tscn",
	"res://scripts/ui/opening_cinematic.gd",
	"res://scenes/ui/settings_panel.tscn",
	"res://scripts/ui/settings_panel.gd",
	"res://scenes/ui/dialogue_overlay.tscn",
	"res://scripts/ui/dialogue_overlay.gd",
	"res://scripts/ui/dialogue_surface.gd",
	"res://scripts/ui/field_document_surface.gd",
]
const DESKTOP := Vector2(1280, 720)
const PHONE_PORTRAIT := Vector2(390, 844)
const PHONE_LANDSCAPE := Vector2(844, 390)
const PHONE_PORTRAIT_LOGICAL := Vector2(1280, 2769.2308)
const PHONE_LANDSCAPE_LOGICAL := Vector2(1558.1538, 720)

var _failures: Array[String] = []
var _checks := 0
var _instances: Dictionary = {}


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_sources()
	await _instantiate_screens()
	if _instances.size() == SCENES.size():
		_check_shared_contract()
		await _check_menu()
		_check_map()
		_check_archive()
		_check_ending()
		_check_controls()
		await _check_opening()
		await _check_settings()
		await _check_dialogue()
	for instance in _instances.values():
		if is_instance_valid(instance):
			instance.free()
	await get_tree().process_frame
	if _failures.is_empty():
		print("SECONDARY_UI_CONTRACT: PASS (%d checks)" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures:
		push_error("SECONDARY_UI_CONTRACT: " + failure)
	print("SECONDARY_UI_CONTRACT: FAIL (%d failures / %d checks)" % [_failures.size(), _checks])
	get_tree().quit(1)


func _check_sources() -> void:
	for path in TARGET_SOURCES:
		_check(ResourceLoader.exists(path), "%s exists" % path.get_file())
		var text := _read_text(path)
		_check(not text.is_empty(), "%s is readable" % path.get_file())
		_check("Â" not in text and "â€" not in text, "%s has no encoding debris" % path.get_file())
	var surface_source := _read_text("res://scripts/ui/field_document_surface.gd")
	for physical_detail in ["clipboard", "paper", "tape", "receiver", "fold"]:
		_check(physical_detail in surface_source.to_lower(), "shared surface draws %s detail" % physical_detail)
	var dialogue_surface := _read_text("res://scripts/ui/dialogue_surface.gd").to_lower()
	for physical_detail in ["receiver", "paper", "tape", "screw", "meter"]:
		_check(physical_detail in dialogue_surface, "dialogue surface draws %s detail" % physical_detail)
	var web_shell := _read_text("res://web/shell.html")
	_check('id="retry-button"' in web_shell and 'retryButton.addEventListener("click", start)' in web_shell,
		"browser launch failure keeps a working retry control")


func _instantiate_screens() -> void:
	for key in SCENES:
		var packed := load(SCENES[key]) as PackedScene
		_check(packed != null, "%s scene loads" % key)
		if packed == null:
			continue
		var instance := packed.instantiate() as Control
		_check(instance != null, "%s scene instantiates" % key)
		if instance == null:
			continue
		_instances[key] = instance
		add_child(instance)
	await get_tree().process_frame
	await get_tree().process_frame


func _check_shared_contract() -> void:
	for key in _instances:
		var screen := _instances[key] as Control
		_check(is_equal_approx(screen.anchor_right, 1.0), "%s anchors to the right edge" % key)
		_check(is_equal_approx(screen.anchor_bottom, 1.0), "%s anchors to the bottom edge" % key)
	var surfaces := [
		_instances.menu.get_node("MenuSheet"),
		_instances.menu.get_node("QuotePanel/Surface"),
		_instances.map.get_node("Card/Surface"),
		_instances.archive.get_node("Center/Panel/Surface"),
		_instances.ending.get_node("Center/Panel/Surface"),
		_instances.controls.get_node("Card/Surface"),
		_instances.settings.get_node("Card/Surface"),
	]
	for surface in surfaces:
		_check(surface is FieldDocumentSurface, "%s uses the physical document renderer" % surface.get_path())
		_check(surface.mouse_filter == Control.MOUSE_FILTER_IGNORE, "%s cannot block input" % surface.get_path())


func _check_menu() -> void:
	var menu: Control = _instances.menu
	menu.apply_responsive_layout(DESKTOP, 0)
	var menu_box := menu.get_node("Box") as GridContainer
	_check(menu_box.columns == 1, "desktop menu keeps one deliberate reading column")
	_check(_buttons_are_human(menu_box), "menu actions use authored sentence case")
	menu.apply_responsive_layout(PHONE_PORTRAIT, 1)
	await get_tree().process_frame
	_check(menu_box.columns == 1, "portrait menu keeps one thumb-readable column")
	_check(_rect_inside(menu_box.position, menu_box.size, PHONE_PORTRAIT), "portrait menu remains inside 390 x 844")
	var sheet := menu.get_node("MenuSheet") as Control
	_check(_rect_inside(sheet.position, sheet.size, PHONE_PORTRAIT), "portrait title sheet remains on screen")
	for child in menu_box.get_children():
		if child is Button:
			_check((child as Button).custom_minimum_size.y >= 44.0, "%s keeps a 44 px portrait target" % child.name)
	menu.apply_responsive_layout(PHONE_LANDSCAPE, 1)
	await get_tree().process_frame
	_check(menu_box.columns == 2, "landscape phone menu uses two short columns")
	_check(_rect_inside(menu_box.position, menu_box.size, PHONE_LANDSCAPE), "landscape menu remains inside 844 x 390")
	menu.apply_responsive_layout(PHONE_PORTRAIT_LOGICAL, 1, PHONE_PORTRAIT)
	await get_tree().process_frame
	for child in menu_box.get_children():
		if child is Button:
			_check(_physical_control_height(child, PHONE_PORTRAIT_LOGICAL, PHONE_PORTRAIT) >= 44.0,
				"%s keeps a 44 physical px canvas-expanded portrait target" % child.name)
	menu.apply_responsive_layout(PHONE_LANDSCAPE_LOGICAL, 1, PHONE_LANDSCAPE)
	await get_tree().process_frame
	for child in menu_box.get_children():
		if child is Button:
			_check(_physical_control_height(child, PHONE_LANDSCAPE_LOGICAL, PHONE_LANDSCAPE) >= 44.0,
				"%s keeps a 44 physical px canvas-expanded landscape target" % child.name)
	menu.apply_responsive_layout(DESKTOP, 0)


func _check_map() -> void:
	var map: Control = _instances.map
	var card := map.get_node("Card") as PanelContainer
	var body := map.get_node("Card/Margin/Layout/Body") as BoxContainer
	map.apply_responsive_layout(PHONE_PORTRAIT)
	_check(body.vertical, "portrait map stacks drawing and pencil notes")
	_check(card.custom_minimum_size.x <= PHONE_PORTRAIT.x and card.custom_minimum_size.y <= PHONE_PORTRAIT.y,
		"portrait map card fits its viewport")
	map.apply_responsive_layout(PHONE_LANDSCAPE)
	_check(not body.vertical, "landscape map keeps the drawing beside its notes")
	_check(card.custom_minimum_size.x <= PHONE_LANDSCAPE.x and card.custom_minimum_size.y <= PHONE_LANDSCAPE.y,
		"landscape map card fits its viewport")
	var objective := map.get_node("Card/Margin/Layout/Body/Notes/Objective") as Label
	_check(objective.autowrap_mode != TextServer.AUTOWRAP_OFF, "map objective wraps safely")
	_check((map.get_node("Card/Margin/Layout/Back") as Button).custom_minimum_size.y >= 40.0, "fold-map control remains reachable")
	map.apply_responsive_layout(PHONE_PORTRAIT_LOGICAL, PHONE_PORTRAIT)
	_check(body.vertical, "canvas-expanded portrait map still stacks its notes")
	_check(_physical_size_fits(card.custom_minimum_size, PHONE_PORTRAIT_LOGICAL, PHONE_PORTRAIT),
		"canvas-expanded portrait map stays inside the physical screen")
	_check(_physical_font_size(objective, "font_size", PHONE_PORTRAIT_LOGICAL, PHONE_PORTRAIT) >= 12.0,
		"portrait map objective remains at least 12 physical pixels")
	_check(_physical_control_height(map.get_node("Card/Margin/Layout/Back"), PHONE_PORTRAIT_LOGICAL, PHONE_PORTRAIT) >= 44.0,
		"canvas-expanded portrait map close target remains 44 physical pixels")
	map.apply_responsive_layout(PHONE_LANDSCAPE_LOGICAL, PHONE_LANDSCAPE)
	_check(not body.vertical, "canvas-expanded landscape map keeps side-by-side flow")
	_check(_physical_size_fits(card.custom_minimum_size, PHONE_LANDSCAPE_LOGICAL, PHONE_LANDSCAPE),
		"canvas-expanded landscape map stays inside the physical screen")
	_check(_physical_control_height(map.get_node("Card/Margin/Layout/Back"), PHONE_LANDSCAPE_LOGICAL, PHONE_LANDSCAPE) >= 44.0,
		"canvas-expanded landscape map close target remains 44 physical pixels")
	map.apply_responsive_layout(DESKTOP)


func _check_archive() -> void:
	var archive: Control = _instances.archive
	var panel := archive.get_node("Center/Panel") as PanelContainer
	archive.apply_responsive_layout(PHONE_PORTRAIT)
	_check((archive.get_node("Center/Panel/Margin/Layout/HeaderRow") as BoxContainer).vertical,
		"portrait archive stacks title and trace count")
	_check(panel.custom_minimum_size.x <= PHONE_PORTRAIT.x and panel.custom_minimum_size.y <= PHONE_PORTRAIT.y,
		"portrait archive fits its viewport")
	var content := archive.get_node("Center/Panel/Margin/Layout/Content") as RichTextLabel
	_check(content.scroll_active, "long archive records remain scrollable")
	var close := archive.get_node("Center/Panel/Margin/Layout/Footer/Close") as Button
	_check(close.custom_minimum_size.y >= 44.0 and close.focus_mode != Control.FOCUS_NONE,
		"archive close control is touch- and keyboard-reachable")
	archive.apply_responsive_layout(PHONE_PORTRAIT_LOGICAL, PHONE_PORTRAIT)
	_check((archive.get_node("Center/Panel/Margin/Layout/HeaderRow") as BoxContainer).vertical,
		"canvas-expanded portrait archive still stacks its heading")
	_check(_physical_size_fits(panel.custom_minimum_size, PHONE_PORTRAIT_LOGICAL, PHONE_PORTRAIT),
		"canvas-expanded portrait archive stays inside the physical screen")
	_check(_physical_font_size(content, "normal_font_size", PHONE_PORTRAIT_LOGICAL, PHONE_PORTRAIT) >= 11.5,
		"portrait archive body remains physically legible")
	archive.apply_responsive_layout(DESKTOP)


func _check_ending() -> void:
	var ending: Control = _instances.ending
	ending.call("_show_ending", {
		"title": "THE LINE WE LEFT",
		"subtitle": "A field record is never neutral.",
		"body": "Ellie kept both versions beside the receiver. " .repeat(22),
		"stats": "TEN TRACES FILED",
		"aftermath": "Return to Railhome and revisit the changed roads.",
		"accent": Color(0.76, 0.46, 0.18),
	})
	ending.apply_responsive_layout(PHONE_PORTRAIT)
	var panel := ending.get_node("Center/Panel") as PanelContainer
	var body := ending.get_node("Center/Panel/Margin/Content/Body") as RichTextLabel
	var buttons := ending.get_node("Center/Panel/Margin/Content/Buttons") as BoxContainer
	_check(panel.custom_minimum_size.x <= PHONE_PORTRAIT.x and panel.custom_minimum_size.y <= PHONE_PORTRAIT.y,
		"portrait ending fits its viewport")
	_check(body.scroll_active and not body.fit_content, "long epilogues scroll instead of overflowing")
	_check(buttons.vertical, "portrait ending actions stack")
	_check(_buttons_are_human(buttons), "ending actions use authored sentence case")
	_check((ending.get_node("Center/Panel/Margin/Content/Buttons/Continue") as Button).visible,
		"route ending offers an explorable aftermath")
	ending.apply_responsive_layout(PHONE_LANDSCAPE)
	_check(not buttons.vertical, "landscape ending actions share one row")
	ending.apply_responsive_layout(PHONE_PORTRAIT_LOGICAL, PHONE_PORTRAIT)
	_check(buttons.vertical, "canvas-expanded portrait ending stacks its actions")
	_check(_physical_size_fits(panel.custom_minimum_size, PHONE_PORTRAIT_LOGICAL, PHONE_PORTRAIT),
		"canvas-expanded portrait ending stays inside the physical screen")
	_check(_physical_font_size(body, "normal_font_size", PHONE_PORTRAIT_LOGICAL, PHONE_PORTRAIT) >= 12.0,
		"portrait ending copy remains at least 12 physical pixels")
	ending.apply_responsive_layout(DESKTOP)


func _check_controls() -> void:
	var controls: Control = _instances.controls
	controls.apply_responsive_layout(PHONE_PORTRAIT, 1)
	var card := controls.get_node("Card") as PanelContainer
	var grid := controls.get_node("Card/Margin/Box/Grid") as GridContainer
	_check(_rect_inside(card.position, card.size * card.scale, PHONE_PORTRAIT),
		"portrait field guide remains on screen (pos %s, size %s, scale %s, min card/margin/box/header/grid %s/%s/%s/%s/%s)" % [
			card.position, card.size, card.scale, card.get_combined_minimum_size(),
			controls.get_node("Card/Margin").get_combined_minimum_size(),
			controls.get_node("Card/Margin/Box").get_combined_minimum_size(),
			controls.get_node("Card/Margin/Box/Header").get_combined_minimum_size(),
			grid.get_combined_minimum_size(),
		])
	_check(grid.columns == 2, "portrait field guide keeps action/key pairs together")
	_check(not controls.get_node("Card/Margin/Box/Grid/CraftAction").visible,
		"touch guide routes crafting through the field kit instead of a dead key")
	var callout := controls.get_node("Card/Margin/Box/Callout/Margin/Hint") as Label
	_check(callout.autowrap_mode != TextServer.AUTOWRAP_OFF, "receiver note wraps safely")
	var back := controls.get_node("Card/Margin/Box/Back") as Button
	_check(back.custom_minimum_size.y >= 44.0 and back.focus_mode != Control.FOCUS_NONE,
		"guide return control is touch- and keyboard-reachable")
	controls.apply_responsive_layout(PHONE_LANDSCAPE, 1)
	_check(_rect_inside(card.position, card.size * card.scale, PHONE_LANDSCAPE),
		"landscape field guide remains on screen (pos %s, size %s, scale %s)" % [card.position, card.size, card.scale])
	controls.apply_responsive_layout(DESKTOP, 0)
	_check(controls.get_node("Card/Margin/Box/Grid/CraftAction").visible,
		"desktop guide documents the crafting notebook")
	_check("C" in (controls.get_node("Card/Margin/Box/Grid/CraftKey") as Label).text,
		"desktop guide gives crafting its real key")


func _check_opening() -> void:
	var opening: Control = _instances.opening
	var plate := opening.get_node("TextPlate") as PanelContainer
	var title := opening.get_node("TextPlate/Margin/Copy/Title") as Label
	var body := opening.get_node("TextPlate/Margin/Copy/Body") as Label
	var skip := opening.get_node("TextPlate/Margin/Copy/Footer/Skip") as Button
	var next := opening.get_node("TextPlate/Margin/Copy/Footer/Next") as Button
	opening.apply_responsive_layout(PHONE_PORTRAIT_LOGICAL, 1, PHONE_PORTRAIT)
	await get_tree().process_frame
	_check(_physical_rect_inside(plate, PHONE_PORTRAIT_LOGICAL, PHONE_PORTRAIT),
		"canvas-expanded portrait opening card stays on the physical screen")
	_check(_scaled_physical_height(skip, plate, PHONE_PORTRAIT_LOGICAL, PHONE_PORTRAIT) >= 44.0,
		"portrait cinematic skip target remains at least 44 physical pixels")
	_check(_scaled_physical_height(next, plate, PHONE_PORTRAIT_LOGICAL, PHONE_PORTRAIT) >= 44.0,
		"portrait cinematic next target remains at least 44 physical pixels")
	_check(_scaled_physical_font_size(title, plate, "font_size", PHONE_PORTRAIT_LOGICAL, PHONE_PORTRAIT) >= 20.0,
		"portrait cinematic heading remains physically legible")
	_check(_scaled_physical_font_size(body, plate, "font_size", PHONE_PORTRAIT_LOGICAL, PHONE_PORTRAIT) >= 14.0,
		"portrait cinematic body remains physically legible")
	opening.apply_responsive_layout(PHONE_LANDSCAPE_LOGICAL, 1, PHONE_LANDSCAPE)
	await get_tree().process_frame
	_check(_physical_rect_inside(plate, PHONE_LANDSCAPE_LOGICAL, PHONE_LANDSCAPE),
		"canvas-expanded landscape opening card stays on the physical screen")
	_check(_scaled_physical_height(skip, plate, PHONE_LANDSCAPE_LOGICAL, PHONE_LANDSCAPE) >= 44.0,
		"landscape cinematic skip target remains at least 44 physical pixels")
	_check(_scaled_physical_height(next, plate, PHONE_LANDSCAPE_LOGICAL, PHONE_LANDSCAPE) >= 44.0,
		"landscape cinematic next target remains at least 44 physical pixels")
	_check(_scaled_physical_font_size(body, plate, "font_size", PHONE_LANDSCAPE_LOGICAL, PHONE_LANDSCAPE) >= 13.5,
		"landscape cinematic copy remains physically legible")
	_check(skip.focus_mode != Control.FOCUS_NONE and next.focus_mode != Control.FOCUS_NONE,
		"cinematic skip and next remain keyboard-reachable")
	var canvas := opening.get_node("Illustration") as Control
	canvas.call("set_beat", 0)
	canvas.call("set_beat", 1)
	canvas.call("set_beat", 2)
	await get_tree().create_timer(0.78, true, false, true).timeout
	var current_still := canvas.get_node("CurrentStill") as TextureRect
	var incoming_still := canvas.get_node("IncomingStill") as TextureRect
	_check(current_still.texture == load("res://assets/processed/cinematic_rebuild/cin03_carriage_depot.png")
		and incoming_still.texture == null,
		"rapid cinematic advance settles on the newest illustration without a blank race")
	opening.set("_running", true)
	opening.set("_index", 0)
	opening.set("_last_touch_msec", -1000)
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	touch.position = Vector2(100.0, 100.0)
	opening.call("_input", touch)
	var first_index := int(opening.get("_index"))
	opening.call("_input", touch)
	_check(first_index == 1 and int(opening.get("_index")) == 1,
		"tap-to-advance moves one beat and debounces the duplicate touch")
	opening.set("_running", false)
	opening.apply_responsive_layout(DESKTOP, 0)


func _check_settings() -> void:
	var settings: Control = _instances.settings
	var card := settings.get_node("Card") as PanelContainer
	var back := settings.get_node("Card/Margin/Layout/Actions/Back") as Button
	var reset := settings.get_node("Card/Margin/Layout/Actions/Reset") as Button
	var checks: Array[Control] = [
		settings.find_child("Fullscreen", true, false),
		settings.find_child("VSync", true, false),
		settings.find_child("ReducedEffects", true, false),
		settings.find_child("HighContrast", true, false),
		settings.find_child("DayNight", true, false),
		settings.find_child("PreciseBearings", true, false),
	]
	var sliders: Array[Control] = [
		settings.get("_master"), settings.get("_music"),
		settings.get("_sfx"), settings.get("_shake"),
	]
	settings.apply_responsive_layout(PHONE_PORTRAIT_LOGICAL, 1, PHONE_PORTRAIT)
	await get_tree().process_frame
	var scroll := settings.find_child("SettingsScroll", true, false) as ScrollContainer
	_check(scroll != null and scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO,
		"portrait settings place the long form in a vertical scroller")
	_check(settings.find_child("MobileColumns", true, false) != null,
		"portrait settings reflow audio and access controls into one reading column")
	_check(_physical_rect_inside(card, PHONE_PORTRAIT_LOGICAL, PHONE_PORTRAIT),
		"canvas-expanded portrait settings card stays on the physical screen")
	for control in checks + sliders + [back, reset]:
		_check(_scaled_physical_height(control, card, PHONE_PORTRAIT_LOGICAL, PHONE_PORTRAIT) >= 44.0,
			"portrait settings keeps %s at least 44 physical pixels tall" % control.name)
		_check(control.focus_mode != Control.FOCUS_NONE,
			"portrait settings keeps %s focus-reachable" % control.name)
	for check in checks:
		_check(_scaled_physical_font_size(check, card, "font_size", PHONE_PORTRAIT_LOGICAL, PHONE_PORTRAIT) >= 14.0,
			"portrait settings keeps %s text physically legible" % check.name)
	settings.apply_responsive_layout(PHONE_LANDSCAPE_LOGICAL, 1, PHONE_LANDSCAPE)
	await get_tree().process_frame
	_check(settings.find_child("MobileColumns", true, false) == null,
		"landscape settings reflow into two shorter columns")
	_check(_physical_rect_inside(card, PHONE_LANDSCAPE_LOGICAL, PHONE_LANDSCAPE),
		"canvas-expanded landscape settings card stays on the physical screen")
	for control in checks + sliders + [back, reset]:
		_check(_scaled_physical_height(control, card, PHONE_LANDSCAPE_LOGICAL, PHONE_LANDSCAPE) >= 44.0,
			"landscape settings keeps %s at least 44 physical pixels tall" % control.name)
	for check in checks:
		_check(_scaled_physical_font_size(check, card, "font_size", PHONE_LANDSCAPE_LOGICAL, PHONE_LANDSCAPE) >= 14.0,
			"landscape settings keeps %s text physically legible" % check.name)
	_check(back.focus_mode != Control.FOCUS_NONE and reset.focus_mode != Control.FOCUS_NONE,
		"settings actions remain keyboard- and controller-reachable")
	settings.apply_responsive_layout(DESKTOP, 0)


func _check_dialogue() -> void:
	var dialogue: Control = _instances.dialogue
	dialogue.call("_show_dialogue", {
		"id": &"touch_debounce_dialogue",
		"title": "Maggie Vale  /  bench receiver",
		"lines": ["First page.", "Second page.", "Third page."],
		"choices": [],
	})
	dialogue.set("_touch_ui", true)
	dialogue.set("_accept_after_msec", 0)
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	touch.position = Vector2(100.0, 100.0)
	dialogue.call("_input", touch)
	var first_index := int(dialogue.get("_line_index"))
	dialogue.call("_on_continue_pressed")
	_check(first_index == 1 and int(dialogue.get("_line_index")) == 1,
		"one touchscreen gesture cannot advance two dialogue pages")
	dialogue.call("_finish", -1)
	dialogue.call("_show_dialogue", {
		"id": &"ui_stress_dialogue",
		"title": "Maggie Vale  /  weak receiver line",
		"provenance": "Flooded cutting recorder · carrier identity unresolved",
		"lines": [
			"The first account says Tollard closed the cutting before the rain. " \
			+ "The second says we were still below it when the gates came down. " \
			+ "I have played both tapes until the oxide lifted, and the same breath " \
			+ "waits behind my own voice. If you file this, file the doubt with it. " \
			+ "The hinge report, the flood roster, and the last carrier log disagree " \
			+ "in three different hands. None of them admits who held the gate lever. " \
			+ "That omission may be fear, or it may be the thing copying our fear. " \
			+ "Rafi heard the same pause at Bellwether. Imogen marked it against the " \
			+ "shift ledger. Nia says the buried voice is learning when we choose to " \
			+ "stay quiet. Read those notes before you decide which version survives.",
		],
		"choices": [
			"File both recordings together and name every contradiction.",
			"Keep the second account private until Imogen checks the gate ledger.",
			"Broadcast Maggie's warning now, before Tollard can answer it.",
			"Ask whose breath is hiding beneath the carrier tone.",
		],
		"accent": Color(0.31, 0.72, 0.69),
	})
	dialogue.call("_show_choices")
	await get_tree().process_frame
	dialogue.apply_responsive_layout(DESKTOP, 0)
	await get_tree().process_frame
	_check_dialogue_geometry(dialogue, DESKTOP, DESKTOP, "desktop", 2)
	dialogue.apply_responsive_layout(PHONE_PORTRAIT_LOGICAL, 1, PHONE_PORTRAIT)
	await get_tree().process_frame
	_check_dialogue_geometry(
		dialogue, PHONE_PORTRAIT_LOGICAL, PHONE_PORTRAIT, "portrait", 1
	)
	dialogue.apply_responsive_layout(PHONE_LANDSCAPE_LOGICAL, 1, PHONE_LANDSCAPE)
	await get_tree().process_frame
	_check_dialogue_geometry(
		dialogue, PHONE_LANDSCAPE_LOGICAL, PHONE_LANDSCAPE, "landscape", 2
	)
	_check((dialogue.get_node("Panel/Surface") as Control).mouse_filter == Control.MOUSE_FILTER_IGNORE,
		"dialogue receiver surface cannot block replies")
	dialogue.call("_finish", -1)
	dialogue.apply_responsive_layout(DESKTOP, 0)


func _check_dialogue_geometry(
		dialogue: Control,
		logical_view: Vector2,
		physical_view: Vector2,
		layout_name: String,
		expected_columns: int,
	) -> void:
	var panel := dialogue.get_node("Panel") as PanelContainer
	var body := dialogue.get_node("Panel/Margin/Content/Body") as RichTextLabel
	var choices := dialogue.get_node("Panel/Margin/Content/Choices") as GridContainer
	var footer := dialogue.get_node("Panel/Margin/Content/Footer") as HBoxContainer
	_check(_physical_rect_inside(panel, logical_view, physical_view),
		"%s dialogue receiver stays on the physical screen (pos %s, size %s, scale %s, min %s)" \
		% [layout_name, panel.position, panel.size, panel.scale, panel.get_combined_minimum_size()])
	_check(body.scroll_active and not body.fit_content,
		"%s long dialogue stays in a scrollable transcript window" % layout_name)
	_check(body.get_theme_stylebox("normal").content_margin_top >= 4.0,
		"%s transcript keeps its first line clear of the paper edge" % layout_name)
	_check(choices.columns == expected_columns,
		"%s dialogue uses %d reply column(s)" % [layout_name, expected_columns])
	_check(body.global_position.y + body.size.y <= choices.global_position.y + 1.0,
		"%s dialogue copy does not overlap its replies" % layout_name)
	_check(choices.global_position.y + choices.size.y <= footer.global_position.y + 1.0,
		"%s replies do not overlap the dialogue footer" % layout_name)
	var scrollbar := body.get_v_scroll_bar()
	_check(scrollbar.max_value > scrollbar.page,
		"%s long dialogue remains reviewable instead of being cropped (scroll %s / %s, body %s)" \
		% [layout_name, scrollbar.max_value, scrollbar.page, body.size])
	for child in choices.get_children():
		if child is not Button:
			continue
		var button := child as Button
		_check(_scaled_physical_height(button, panel, logical_view, physical_view) >= 44.0,
			"%s reply %s keeps a 44 physical pixel target" % [layout_name, button.name])
		_check(button.autowrap_mode != TextServer.AUTOWRAP_OFF,
			"%s reply %s wraps long copy" % [layout_name, button.name])
		_check(button.focus_mode != Control.FOCUS_NONE,
			"%s reply %s remains keyboard- and controller-reachable" % [layout_name, button.name])


func _buttons_are_human(parent: Node) -> bool:
	for child in parent.get_children():
		if child is Button:
			var copy := (child as Button).text.strip_edges()
			if copy.length() > 2 and copy == copy.to_upper():
				return false
	return true


func _rect_inside(position: Vector2, rect_size: Vector2, view: Vector2) -> bool:
	return position.x >= -1.0 and position.y >= -1.0 \
		and position.x + rect_size.x <= view.x + 1.0 \
		and position.y + rect_size.y <= view.y + 1.0


func _physical_size_fits(logical_size: Vector2, logical_view: Vector2, physical_view: Vector2) -> bool:
	var scale := minf(physical_view.x / logical_view.x, physical_view.y / logical_view.y)
	return logical_size.x * scale <= physical_view.x + 1.0 \
		and logical_size.y * scale <= physical_view.y + 1.0


func _physical_font_size(
		control: Control,
		theme_name: StringName,
		logical_view: Vector2,
		physical_view: Vector2,
	) -> float:
	var scale := minf(physical_view.x / logical_view.x, physical_view.y / logical_view.y)
	return float(control.get_theme_font_size(theme_name)) * scale


func _physical_control_height(control: Control, logical_view: Vector2, physical_view: Vector2) -> float:
	var scale := minf(physical_view.x / logical_view.x, physical_view.y / logical_view.y)
	return control.custom_minimum_size.y * scale


func _physical_rect_inside(
		control: Control,
		logical_view: Vector2,
		physical_view: Vector2,
	) -> bool:
	var canvas_scale := minf(physical_view.x / logical_view.x, physical_view.y / logical_view.y)
	return _rect_inside(
		control.position * canvas_scale,
		control.size * control.scale * canvas_scale,
		physical_view
	)


func _scaled_physical_height(
		control: Control,
		scaled_parent: Control,
		logical_view: Vector2,
		physical_view: Vector2,
	) -> float:
	var canvas_scale := minf(physical_view.x / logical_view.x, physical_view.y / logical_view.y)
	return control.custom_minimum_size.y * scaled_parent.scale.y * canvas_scale


func _scaled_physical_font_size(
		control: Control,
		scaled_parent: Control,
		theme_name: StringName,
		logical_view: Vector2,
		physical_view: Vector2,
	) -> float:
	var canvas_scale := minf(physical_view.x / logical_view.x, physical_view.y / logical_view.y)
	return float(control.get_theme_font_size(theme_name)) * scaled_parent.scale.y * canvas_scale


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
