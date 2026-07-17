class_name CraftingOverlay
extends Control
## Player-facing crafting workbook. It presents every recipe, its knowledge
## gate, exact stock counts and authored field consequence from one model.

signal workbench_opened
signal workbench_closed

const READY_TONE := Color(0.16, 0.35, 0.29, 1.0)
const LOCKED_TONE := Color(0.30, 0.25, 0.20, 1.0)
const MATERIAL_TONE := Color(0.38, 0.25, 0.14, 1.0)
const PAPER_INK := Color(0.105, 0.095, 0.073, 1.0)
const FADED_INK := Color(0.31, 0.29, 0.23, 1.0)
const RED_PENCIL := Color(0.50, 0.18, 0.13, 1.0)

@onready var _surface: CraftingWorkbenchSurface = %WorkbenchSurface
@onready var _pages: BoxContainer = %Pages
@onready var _top_title: Label = $OuterMargin/RootLayout/TopStrip/Margin/Row/Title
@onready var _top_hint: Label = $OuterMargin/RootLayout/TopStrip/Margin/Row/Hint
@onready var _station_filter: OptionButton = %StationFilter
@onready var _recipe_count: Label = %RecipeCount
@onready var _recipe_list: VBoxContainer = %RecipeList
@onready var _output_icon: TextureRect = %OutputIcon
@onready var _output_title: Label = %OutputTitle
@onready var _output_stock: Label = %OutputStock
@onready var _description: Label = %Description
@onready var _use_summary: Label = %UseSummary
@onready var _consequence: Label = %Consequence
@onready var _ingredient_list: VBoxContainer = %IngredientList
@onready var _unlock_heading: Label = %UnlockHeading
@onready var _unlock_text: Label = %UnlockText
@onready var _craft_status: Label = %CraftStatus
@onready var _use_status: Label = %UseStatus
@onready var _craft_button: Button = %CraftButton
@onready var _use_button: Button = %UseButton
@onready var _close_button: Button = %CloseButton

var _model := CraftingUIModel.new()
var _rows: Array[Dictionary] = []
var _station_ids: Array[StringName] = []
var _selected_recipe_id: StringName = &""
var _recipe_buttons: Dictionary = {}
var _owns_input_lock := false
var _ui_scale := 1.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_close_button.pressed.connect(close_workbench)
	_craft_button.pressed.connect(_on_craft_pressed)
	_use_button.pressed.connect(_on_use_pressed)
	_station_filter.item_selected.connect(_on_station_selected)
	resized.connect(_update_layout)
	InventorySystem.inventory_changed.connect(_on_source_changed)
	ArchiveSystem.echo_recorded.connect(_on_echo_recorded)
	EventBus.campaign_progress_changed.connect(_on_source_changed)
	_build_station_filter()
	_update_layout()


func _exit_tree() -> void:
	if _owns_input_lock:
		_owns_input_lock = false
		GameManager.set_dialogue_active(false)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("craft"):
		if visible:
			close_workbench()
		elif not GameManager.is_input_locked():
			open_workbench()
		get_viewport().set_input_as_handled()
	elif visible and event.is_action_pressed("ui_cancel"):
		close_workbench()
		get_viewport().set_input_as_handled()


func open_workbench() -> void:
	if visible or GameManager.is_input_locked():
		return
	_refresh()
	visible = true
	_owns_input_lock = true
	GameManager.set_dialogue_active(true)
	var selected_button := _recipe_buttons.get(_selected_recipe_id) as Button
	if selected_button != null:
		selected_button.grab_focus()
	else:
		_close_button.grab_focus()
	workbench_opened.emit()


func close_workbench() -> void:
	if not visible:
		return
	visible = false
	if _owns_input_lock:
		_owns_input_lock = false
		GameManager.set_dialogue_active(false)
	workbench_closed.emit()


func get_visible_recipe_count() -> int:
	return _rows.size()


func get_selected_recipe_id() -> StringName:
	return _selected_recipe_id


func select_recipe(recipe_id: StringName) -> void:
	if not _recipe_buttons.has(recipe_id):
		return
	_selected_recipe_id = recipe_id
	_update_recipe_button_styles()
	_update_detail()


func refresh_for_test() -> void:
	_refresh()


func _build_station_filter() -> void:
	_station_filter.clear()
	_station_ids.clear()
	_station_filter.add_item("ALL METHODS")
	_station_ids.append(&"")
	var labels := {}
	for recipe in CraftingRecipeDatabase.get_recipes():
		labels[recipe.station_id] = recipe.station_label
	var ids: Array[StringName] = []
	ids.assign(labels.keys())
	ids.sort_custom(func(left: StringName, right: StringName) -> bool:
		return String(left) < String(right)
	)
	for station_id in ids:
		_station_filter.add_item(String(labels[station_id]).to_upper())
		_station_ids.append(station_id)


func _on_station_selected(_index: int) -> void:
	_refresh()


func _selected_station() -> StringName:
	var index := _station_filter.selected
	return _station_ids[index] if index >= 0 and index < _station_ids.size() else &""


func _refresh() -> void:
	_rows = _model.get_recipe_rows(_selected_station())
	_recipe_count.text = "%d METHODS / %d READY" % [
		_rows.size(),
		_rows.filter(func(row: Dictionary) -> bool: return bool(row.get("craftable", false))).size(),
	]
	for child in _recipe_list.get_children():
		child.queue_free()
	_recipe_buttons.clear()

	var selection_still_visible := false
	for row in _rows:
		var recipe_id: StringName = row["recipe_id"]
		selection_still_visible = selection_still_visible or recipe_id == _selected_recipe_id
		var button := Button.new()
		button.custom_minimum_size = Vector2(0.0, 58.0 * _ui_scale)
		button.add_theme_font_size_override("font_size", roundi(14.0 * _ui_scale))
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text = _recipe_button_text(row)
		button.tooltip_text = String(row["status_text"])
		button.focus_mode = Control.FOCUS_ALL
		button.pressed.connect(select_recipe.bind(recipe_id))
		_recipe_list.add_child(button)
		_recipe_buttons[recipe_id] = button
	if not selection_still_visible:
		_selected_recipe_id = StringName(_rows[0]["recipe_id"]) if not _rows.is_empty() else &""
	_update_recipe_button_styles()
	_update_detail()


func _recipe_button_text(row: Dictionary) -> String:
	var mark := "READY"
	match String(row.get("state", "")):
		"locked": mark = "RESEARCH"
		"materials": mark = "SUPPLIES"
		"full": mark = "KIT FULL"
	return "%s\n%s  /  %d OWNED" % [String(row["title"]).to_upper(), mark, int(row["output_owned"])]


func _update_recipe_button_styles() -> void:
	for recipe_id in _recipe_buttons:
		var button: Button = _recipe_buttons[recipe_id]
		var row: Dictionary = _row_for_id(StringName(recipe_id))
		var selected: bool = StringName(recipe_id) == _selected_recipe_id
		var tone: Color = READY_TONE if bool(row.get("craftable", false)) else LOCKED_TONE
		if String(row.get("state", "")) == "materials":
			tone = MATERIAL_TONE
		button.add_theme_color_override("font_color", Color(0.86, 0.81, 0.68, 1.0) if selected else Color(0.20, 0.18, 0.14, 1.0))
		button.add_theme_color_override("font_hover_color", Color(0.96, 0.88, 0.68, 1.0))
		button.add_theme_color_override("font_focus_color", Color(0.96, 0.88, 0.68, 1.0))
		button.add_theme_stylebox_override("normal", _recipe_style(tone, selected))
		button.add_theme_stylebox_override("hover", _recipe_style(tone.lightened(0.08), true))
		button.add_theme_stylebox_override("pressed", _recipe_style(tone.darkened(0.05), true))
		button.add_theme_stylebox_override("focus", _focus_style())


func _update_detail() -> void:
	var row := _row_for_id(_selected_recipe_id)
	if row.is_empty():
		_output_title.text = "NO METHOD SELECTED"
		_output_icon.texture = null
		_craft_button.disabled = true
		_use_button.disabled = true
		return

	_output_title.text = String(row["output_name"]).to_upper()
	_output_stock.text = "%d / %d IN FIELD KIT" % [int(row["output_owned"]), int(row["output_stack_limit"])]
	_output_icon.texture = row["output_icon"]
	_description.text = String(row["description"])
	_use_summary.text = "FIELD USE\n%s" % String(row["use_summary"])
	_consequence.text = "COST / CONSEQUENCE\n%s" % String(row["consequence"])
	_craft_status.text = "METHOD STATUS / %s" % String(row["status_text"])
	_craft_button.text = "MAKE %d  /  %s" % [int(row["output_amount"]), String(row["station_label"]).to_upper()]
	_craft_button.disabled = not bool(row["craftable"])

	for child in _ingredient_list.get_children():
		child.queue_free()
	for ingredient in row["ingredients"]:
		_ingredient_list.add_child(_make_ingredient_row(ingredient))

	var missing_records: PackedStringArray = row["missing_records"]
	_unlock_heading.text = "FIELD NOTE / %s" % ("METHOD LEARNED" if String(row["state"]) != "locked" else "HOW TO LEARN IT")
	_unlock_text.text = String(row["unlock_note"])
	if not missing_records.is_empty():
		_unlock_text.text += "\nMissing record: %s" % ", ".join(missing_records)

	var use_status := CraftedItemEffects.get_status(StringName(row["output_item_id"]))
	_use_button.text = "%s  /  %s" % [
		String(row["use_action"]),
		"SPENT ON USE" if bool(row["consumes_on_use"]) else "REUSABLE",
	]
	_use_button.disabled = not bool(use_status.get("ok", false))
	_use_status.text = "FIELD KIT / %s" % String(use_status.get("reason", "No use status available."))


func _make_ingredient_row(ingredient: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0.0, 42.0 * _ui_scale)
	row.add_theme_constant_override("separation", roundi(10.0 * _ui_scale))
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(34.0, 34.0) * _ui_scale
	icon.texture = ingredient.get("icon")
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	var name_label := Label.new()
	name_label.text = String(ingredient["name"]).to_upper()
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_color_override("font_color", PAPER_INK)
	name_label.add_theme_font_size_override("font_size", roundi(13.0 * _ui_scale))
	row.add_child(name_label)
	var amount := Label.new()
	amount.text = "%d OWNED  /  %d NEEDED" % [int(ingredient["owned"]), int(ingredient["needed"])]
	amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	amount.add_theme_color_override("font_color", FADED_INK if bool(ingredient["enough"]) else RED_PENCIL)
	amount.add_theme_font_size_override("font_size", roundi(12.0 * _ui_scale))
	row.add_child(amount)
	return row


func _on_craft_pressed() -> void:
	var row := _row_for_id(_selected_recipe_id)
	if row.is_empty():
		return
	var result := CraftingSystem.craft(_selected_recipe_id, 1, StringName(row["station_id"]))
	EventBus.notice_posted.emit(String(result.get("reason", "The work could not be completed.")))
	_refresh()


func _on_use_pressed() -> void:
	var row := _row_for_id(_selected_recipe_id)
	if row.is_empty():
		return
	var result := CraftedItemEffects.use_item(StringName(row["output_item_id"]))
	EventBus.notice_posted.emit(String(result.get("reason", "The item could not be used here.")))
	_refresh()


func _on_source_changed() -> void:
	if visible:
		_refresh()


func _on_echo_recorded(_data: MemoryEchoData) -> void:
	_on_source_changed()


func _row_for_id(recipe_id: StringName) -> Dictionary:
	for row in _rows:
		if StringName(row["recipe_id"]) == recipe_id:
			return row
	return {}


func apply_responsive_layout(
		viewport_size: Vector2,
		window_size: Vector2 = Vector2.ZERO,
	) -> void:
	_update_layout(viewport_size, window_size)


func _update_layout(
		size_override: Vector2 = Vector2.ZERO,
		window_override: Vector2 = Vector2.ZERO,
	) -> void:
	if not is_node_ready():
		return
	var view := size_override if size_override != Vector2.ZERO else size
	var window_size := window_override if window_override != Vector2.ZERO \
		else Vector2(DisplayServer.window_get_size())
	var physical := _physical_scale(view, window_size)
	var next_scale := clampf(0.92 / physical, 1.0, 3.2)
	var scale_changed := not is_equal_approx(_ui_scale, next_scale)
	_ui_scale = next_scale
	var vertical := view.x < 880.0 or view.y > view.x * 1.08
	_pages.vertical = vertical
	_surface.set_vertical_pages(vertical)
	var phone_portrait := window_size.x < 560.0 and window_size.y > window_size.x
	_top_title.text = "FIELD WORKBENCH  /  REPAIR BOOK" if phone_portrait \
		else "FIELD WORKBENCH  /  ELLIE'S REPAIR BOOK"
	_top_hint.visible = not phone_portrait
	_close_button.text = "CLOSE" if phone_portrait else "CLOSE BOOK"
	_apply_physical_readability()
	if scale_changed and visible:
		call_deferred("_refresh")


func _apply_physical_readability() -> void:
	var workbook_theme := theme
	if workbook_theme != null:
		workbook_theme.set_font_size("font_size", "Button", roundi(14.0 * _ui_scale))
		workbook_theme.set_font_size("font_size", "Label", roundi(14.0 * _ui_scale))
		workbook_theme.set_font_size("font_size", "OptionButton", roundi(13.0 * _ui_scale))
	_scale_explicit_fonts(self)

	var spacing_scale := clampf(sqrt(_ui_scale), 1.0, 1.8)
	$OuterMargin/RootLayout.add_theme_constant_override("separation", roundi(14.0 * spacing_scale))
	$OuterMargin/RootLayout/TopStrip.custom_minimum_size.y = 48.0 * _ui_scale
	$OuterMargin/RootLayout/TopStrip/Margin.add_theme_constant_override(
		"margin_left", roundi(15.0 * spacing_scale))
	$OuterMargin/RootLayout/TopStrip/Margin.add_theme_constant_override(
		"margin_right", roundi(9.0 * spacing_scale))
	$OuterMargin/RootLayout/TopStrip/Margin.add_theme_constant_override(
		"margin_top", roundi(7.0 * spacing_scale))
	$OuterMargin/RootLayout/TopStrip/Margin.add_theme_constant_override(
		"margin_bottom", roundi(7.0 * spacing_scale))
	_close_button.custom_minimum_size = Vector2(106.0 * spacing_scale, 44.0 * _ui_scale)
	_station_filter.custom_minimum_size = Vector2(190.0, 44.0 * _ui_scale)
	_craft_button.custom_minimum_size.y = 54.0 * _ui_scale
	_use_button.custom_minimum_size.y = 54.0 * _ui_scale
	_output_icon.custom_minimum_size = Vector2(66.0, 66.0) * spacing_scale
	$OuterMargin/RootLayout/PageScroll/Pages.add_theme_constant_override(
		"separation", roundi(22.0 * spacing_scale))
	_apply_page_margins(
		$OuterMargin/RootLayout/PageScroll/Pages/MethodsPage/Margin,
		Vector4(28.0, 25.0, 24.0, 22.0) * spacing_scale,
	)
	_apply_page_margins(
		$OuterMargin/RootLayout/PageScroll/Pages/DetailPage/Margin,
		Vector4(27.0, 23.0, 27.0, 22.0) * spacing_scale,
	)
	for button in _recipe_buttons.values():
		if button is Button:
			(button as Button).custom_minimum_size.y = 58.0 * _ui_scale


func _scale_explicit_fonts(node: Node) -> void:
	if node is Control:
		var control := node as Control
		if control.has_theme_font_size_override("font_size"):
			if not control.has_meta(&"crafting_base_font_size"):
				control.set_meta(&"crafting_base_font_size", control.get_theme_font_size("font_size"))
			var base_size := int(control.get_meta(&"crafting_base_font_size"))
			control.add_theme_font_size_override("font_size", roundi(base_size * _ui_scale))
	for child in node.get_children():
		_scale_explicit_fonts(child)


func _apply_page_margins(container: MarginContainer, values: Vector4) -> void:
	container.add_theme_constant_override("margin_left", roundi(values.x))
	container.add_theme_constant_override("margin_top", roundi(values.y))
	container.add_theme_constant_override("margin_right", roundi(values.z))
	container.add_theme_constant_override("margin_bottom", roundi(values.w))


func _physical_scale(view: Vector2, window_size: Vector2) -> float:
	if view.x <= 1.0 or view.y <= 1.0 or window_size.x <= 1.0 or window_size.y <= 1.0:
		return 1.0
	return maxf(0.05, minf(window_size.x / view.x, window_size.y / view.y))


func _recipe_style(tone: Color, selected: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = tone if selected else Color(0.78, 0.72, 0.58, 0.72)
	style.border_width_left = 5 if selected else 2
	style.border_width_bottom = 1
	style.border_color = Color(0.52, 0.26, 0.13, 0.9) if selected else Color(0.30, 0.27, 0.20, 0.42)
	style.content_margin_left = 14.0
	style.content_margin_top = 7.0
	style.content_margin_right = 10.0
	style.content_margin_bottom = 7.0
	return style


func _focus_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.38, 0.72, 0.69, 0.95)
	return style
