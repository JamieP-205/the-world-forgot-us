extends Node
## Headless contract for the object-based Trace Anchor workflow.

const TRACE_PATHS := [
	"res://resources/echoes/echo_last_signal.tres",
	"res://resources/echoes/echo_sun_lid.tres",
	"res://resources/echoes/echo_mara_repair.tres",
	"res://resources/echoes/echo_clinic_triage.tres",
	"res://resources/echoes/echo_bus_ledger.tres",
	"res://resources/echoes/echo_names_wall.tres",
	"res://resources/echoes/echo_relay_warning.tres",
	"res://resources/echoes/echo_driver_call.tres",
	"res://resources/echoes/echo_first_tone.tres",
	"res://resources/echoes/echo_maggie_final.tres",
]
const FORBIDDEN_RUNTIME_PATHS := [
	"res://scripts/echoes/memory_echo_data.gd",
	"res://scripts/world/memory_echo.gd",
	"res://scenes/world/memory_echo.tscn",
	"res://scripts/ui/trace_anchor_overlay.gd",
	"res://scenes/ui/trace_anchor_overlay.tscn",
	"res://scripts/scanner/scanner_pulse.gd",
	"res://scenes/scanner/scanner_pulse.tscn",
]
const PHONE_PORTRAIT := Vector2(390, 844)
const PHONE_PORTRAIT_LOGICAL := Vector2(1280, 2769.2308)
const PHONE_LANDSCAPE := Vector2(844, 390)
const PHONE_LANDSCAPE_LOGICAL := Vector2(1558.1538, 720)

var _failures: Array[String] = []
var _checks := 0
var _archive_before: Array
var _dispositions_before: Dictionary
var _narrative_before: Dictionary
var _inventory_before: Dictionary
var _world_before: Dictionary
var _upgrades_before: Array
var _save_existed := false
var _save_bytes := PackedByteArray()


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_capture_state()
	_check_resource_contracts()
	_check_legacy_language_removed()
	await _check_semantic_lighting()
	await _check_verified_flow()
	await _check_fed_flow_and_save_roundtrip()
	_check_restore_is_idempotent()
	_restore_state()
	if _failures.is_empty():
		print("TRACE ANCHOR CONTRACT PASS (%d checks)" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures:
		push_error("TRACE ANCHOR CONTRACT: " + failure)
	print("TRACE ANCHOR CONTRACT FAIL (%d failures / %d checks)" % [_failures.size(), _checks])
	get_tree().quit(1)


func _check_resource_contracts() -> void:
	var ids: Dictionary = {}
	var semantics: Dictionary = {}
	var artifact_paths: Dictionary = {}
	var evidence_classes: Dictionary = {}
	var semantic_signatures: Dictionary = {}
	_check(TRACE_PATHS.size() == 10, "exactly ten trace resources are in contract")
	for path in TRACE_PATHS:
		var data := load(path) as MemoryEchoData
		_check(data != null, "%s loads" % path.get_file())
		if data == null:
			continue
		_check(data.has_complete_trace_contract(), "%s has a complete evidence contract" % data.id)
		_check(not ids.has(data.id), "%s id is unique" % data.id)
		ids[data.id] = true
		_check(not semantics.has(data.artifact_semantics), "%s object semantics are unique" % data.id)
		semantics[data.artifact_semantics] = true
		var artifact_path := data.artifact_texture.resource_path
		_check(not artifact_paths.has(artifact_path), "%s uses a distinct ordinary-object texture" % data.id)
		artifact_paths[artifact_path] = true
		_check("memory_echo_core" not in artifact_path.to_lower(), "%s does not use the legacy collectible" % data.id)
		_check(data.confidence >= 1 and data.confidence <= 100, "%s confidence is bounded" % data.id)
		evidence_classes[data.evidence_class] = true
		var signature := "%s|%s|%s" % [
			data.artifact_name, data.contradiction_text, data.verification_text]
		_check(not semantic_signatures.has(signature), "%s evidence wording is object-specific" % data.id)
		semantic_signatures[signature] = true
		_check(data.evidence_label().contains("EVIDENCE"), "%s exposes evidence class and confidence" % data.id)
	_check(ids.size() == 10, "all ten ids are distinct")
	_check(semantics.size() == 10, "all ten artifacts have distinct semantics")
	_check(artifact_paths.size() == 10, "all ten artifacts have distinct textures")
	for evidence_class in ["physical", "witness", "system"]:
		_check(evidence_classes.has(evidence_class), "%s evidence is represented" % evidence_class)

	var opening := load(TRACE_PATHS[0]) as MemoryEchoData
	_check(opening.artifact_texture.resource_path ==
		"res://assets/processed/trace_anchors/trace_last_signal.png",
		"opening anchor uses the generated ordinary-object asset")
	_check(opening.afterimage_texture != null and opening.afterimage_texture.resource_path ==
		"res://assets/processed/trace_anchors/trace_last_signal_afterimage.png",
		"opening anchor uses its generated spatial afterimage")


func _check_legacy_language_removed() -> void:
	var forbidden := RegEx.new()
	forbidden.compile("(?i)\\b(crystal|gem|hex)\\b")
	var paths := FORBIDDEN_RUNTIME_PATHS.duplicate()
	paths.append_array(TRACE_PATHS)
	for path in paths:
		var text := _read_text(path)
		_check(forbidden.search(text) == null, "%s has no gem-language residue" % path.get_file())
		_check("memory_echo_core.png" not in text, "%s has no legacy collectible dependency" % path.get_file())
	var scene_text := _read_text("res://scenes/world/memory_echo.tscn")
	_check("Halo" not in scene_text and "Polygon2D" not in scene_text,
		"trace scene has no halo or procedural polygon")
	_check("PointLight2D" in scene_text and "MemoryLight" in scene_text,
		"trace scene carries a real object-local 2D light")
	_check("metadata/lighting_ignore = true" in scene_text,
		"authored trace light opts out of heuristic duplicate-light generation")
	_check("GradientTexture2D" in scene_text and "shadow_enabled = false" in scene_text,
		"trace light uses a soft Web-safe falloff without per-anchor shadows")
	_check("shader_type canvas_item" in scene_text and "texture(TEXTURE" in scene_text,
		"Reveal afterimage samples the authored object through a restrained shader")
	_check("Shader_artifact_detail" in scene_text and "shadow_lift" in scene_text,
		"carrier material can reveal dark object detail without a synthetic shape")
	_check("motion_strength" in scene_text and "alignment" in scene_text,
		"afterimage shader exposes quality and alignment controls")
	var lighting_text := _read_text("res://scripts/visual/lighting_director.gd")
	_check("LIGHT_IGNORE_META" in lighting_text and "_has_authored_light_owner" in lighting_text,
		"lighting director honours authored light ownership")
	var pulse_text := _read_text("res://scripts/scanner/scanner_pulse.gd")
	_check("draw_arc" not in pulse_text and "draw_circle" not in pulse_text,
		"scanner feedback uses authored pulse textures")


func _check_semantic_lighting() -> void:
	ArchiveSystem.restore([])
	var sample_paths := [TRACE_PATHS[1], TRACE_PATHS[7], TRACE_PATHS[8]]
	var colors: Array[Color] = []
	for index in sample_paths.size():
		var data := load(sample_paths[index]) as MemoryEchoData
		var anchor := _spawn_anchor(data, "SemanticLight%d" % index)
		anchor.call("_on_setting_changed", "accessibility", "reduced_effects", false)
		anchor.detect_from(anchor.global_position + Vector2(-50, 0))
		await get_tree().create_timer(0.32).timeout
		var snapshot: Dictionary = anchor.get_trace_snapshot()
		colors.append(snapshot.get("light_color", Color.BLACK) as Color)
		_check(bool(snapshot.get("light_enabled", false)),
			"%s evidence switches on a physical PointLight2D at Detect" % data.evidence_class)
		_check(float(snapshot.get("light_radius", 0.0)) >= 50.0,
			"%s evidence Detect light has a bounded local radius" % data.evidence_class)
		anchor.queue_free()
		await get_tree().process_frame
	_check(colors.size() == 3, "physical, witness and system lighting samples load")
	if colors.size() == 3:
		_check(_color_distance(colors[0], colors[1]) > 0.04,
			"physical and witness evidence have distinct restrained light tones")
		_check(_color_distance(colors[1], colors[2]) > 0.04,
			"witness and system evidence have distinct restrained light tones")


func _check_verified_flow() -> void:
	ArchiveSystem.restore([])
	CampaignSystem.clear_narrative_state(false)
	InventorySystem.set_items({})
	var data := load(TRACE_PATHS[0]) as MemoryEchoData
	var anchor := _spawn_anchor(data, "VerifiedAnchor")
	var opening_artifact := anchor.get_node("Visual/Artifact") as Sprite2D
	var memory_light := anchor.get_node("Visual/MemoryLight") as PointLight2D
	_check(anchor.get_trace_stage() == &"hidden", "new anchor starts hidden")
	_check(opening_artifact.visible and opening_artifact.modulate.a >= 0.5,
		"ordinary physical object remains readable before detection")
	_check(memory_light != null and not memory_light.enabled and memory_light.energy <= 0.001,
		"hidden object has no synthetic glow before the receiver finds it")
	_check(memory_light.texture is GradientTexture2D and not memory_light.shadow_enabled,
		"anchor uses a real soft light with its mobile-safe shadow path disabled")
	var feedback: Dictionary = anchor.get_scanner_feedback(anchor.global_position + Vector2(-80, 0))
	_check("NEEDLE E" in String(feedback.get("bearing", "")), "scanner feedback carries directional needle")
	_check(String(feedback.get("noise", "")) == data.signal_profile,
		"scanner feedback carries object-specific noise")

	_check(anchor.detect_from(anchor.global_position + Vector2(-80, 0)), "Detect stage accepts first sweep")
	_check(anchor.get_trace_stage() == &"detected", "stage advances to Detect")
	await get_tree().create_timer(0.32).timeout
	var detected_snapshot: Dictionary = anchor.get_trace_snapshot()
	_check(bool(detected_snapshot.get("light_enabled", false)),
		"Detect raises a small pool of real 2D light from the object")
	_check(float(detected_snapshot.get("light_energy", 0.0)) >= 0.42
		and float(detected_snapshot.get("light_energy", 0.0)) <= 0.48,
		"Detect lighting is readable without flattening the scene")
	_check(float(detected_snapshot.get("light_radius", 0.0)) >= 48.0
		and float(detected_snapshot.get("light_radius", 0.0)) <= 58.0,
		"Detect light stays close to the physical carrier")
	_check(not bool(detected_snapshot.get("afterimage_visible", true)),
		"Detect does not reveal the memory layer early")
	_check(float(detected_snapshot.get("artifact_shadow_lift", 0.0)) >= 0.5
		and float(detected_snapshot.get("artifact_exposure", 0.0)) >= 1.45,
		"Detect lifts authored carrier detail above near-black night values")
	_check(anchor.focus_trace(anchor.global_position + Vector2(-30, 0)), "Focus stage accepts close receiver")
	_check(anchor.get_trace_stage() == &"focused", "stage advances to Focus")
	await get_tree().create_timer(0.32).timeout
	var focused_snapshot: Dictionary = anchor.get_trace_snapshot()
	_check(float(focused_snapshot.get("light_energy", 0.0))
		> float(detected_snapshot.get("light_energy", 0.0)),
		"Focus materially strengthens object-local illumination (%.3f > %.3f)" % [
			float(focused_snapshot.get("light_energy", 0.0)),
			float(detected_snapshot.get("light_energy", 0.0)),
		])
	_check(float(focused_snapshot.get("light_radius", 0.0))
		> float(detected_snapshot.get("light_radius", 0.0)),
		"Focus expands the light pool without showing a coloured card")
	_check(not bool(focused_snapshot.get("afterimage_visible", true)),
		"Focus keeps the spatial residue withheld")
	_check(float(focused_snapshot.get("artifact_shadow_lift", 0.0))
		> float(detected_snapshot.get("artifact_shadow_lift", 0.0))
		and float(focused_snapshot.get("artifact_exposure", 0.0))
		> float(detected_snapshot.get("artifact_exposure", 0.0)),
		"Focus exposes more physical-object detail than Detect")
	anchor.call("_on_setting_changed", "accessibility", "reduced_effects", false)
	var full_effects_snapshot: Dictionary = anchor.get_trace_snapshot()
	anchor.call("_on_setting_changed", "accessibility", "reduced_effects", true)
	var reduced_snapshot: Dictionary = anchor.get_trace_snapshot()
	_check(float(reduced_snapshot.get("light_energy", 0.0))
		< float(full_effects_snapshot.get("light_energy", 0.0)),
		"reduced effects lowers PointLight2D energy")
	_check(float(reduced_snapshot.get("light_radius", 0.0))
		< float(full_effects_snapshot.get("light_radius", 0.0)),
		"reduced effects lowers the light fill radius")
	_check(is_zero_approx(float(reduced_snapshot.get("afterimage_motion", 1.0))),
		"reduced effects freezes shader motion")
	_check(not (anchor.get_node("Visual/SignalDust") as Sprite2D).visible,
		"reduced effects removes nonessential signal dust")
	anchor.call("_on_setting_changed", "accessibility", "reduced_effects", false)
	var director := LightingDirector.new()
	director.name = "TraceLightingContractDirector"
	add_child(director)
	director.refresh(anchor)
	_check(anchor.find_child("__LightingPoint", true, false) == null,
		"authored anchor subtree does not receive a duplicate heuristic light")
	director.queue_free()
	var overlay := anchor.get_node("TraceAnchorOverlay") as TraceAnchorOverlay
	_check(overlay.is_open() and overlay.get_presented_stage() == &"focus",
		"receiver-paper overlay presents Focus")
	overlay.apply_responsive_layout(Vector2(430, 760))
	_check(overlay.is_compact_layout() and overlay.get_choice_columns() == 1,
		"trace controls stack for a narrow mobile viewport")
	overlay.apply_responsive_layout(PHONE_PORTRAIT_LOGICAL, PHONE_PORTRAIT)
	var physical_scale := PHONE_PORTRAIT.x / PHONE_PORTRAIT_LOGICAL.x
	var shell := overlay.get_node("Root/Center/ReceiverShell") as PanelContainer
	var readout := overlay.get_node(
		"Root/Center/ReceiverShell/Margin/Layout/Paper/Readout") as RichTextLabel
	_check(overlay.is_compact_layout() and overlay.get_choice_columns() == 1,
		"canvas-expanded portrait trace controls still stack")
	_check(shell.custom_minimum_size.x * physical_scale <= PHONE_PORTRAIT.x + 1.0
		and shell.custom_minimum_size.y * physical_scale <= PHONE_PORTRAIT.y + 1.0,
		"canvas-expanded trace receiver stays inside the physical screen")
	_check(float(readout.get_theme_font_size("normal_font_size")) * physical_scale >= 13.0,
		"portrait Trace Anchor evidence remains physically legible")
	overlay.apply_responsive_layout(PHONE_LANDSCAPE_LOGICAL, PHONE_LANDSCAPE)
	physical_scale = PHONE_LANDSCAPE.y / PHONE_LANDSCAPE_LOGICAL.y
	_check(overlay.is_compact_layout() and overlay.get_choice_columns() == 2,
		"shallow landscape trace controls use two short columns")
	_check(shell.custom_minimum_size.x * physical_scale <= PHONE_LANDSCAPE.x + 1.0
		and shell.custom_minimum_size.y * physical_scale <= PHONE_LANDSCAPE.y + 1.0,
		"canvas-expanded landscape trace receiver stays inside the physical screen")
	for button_path in [
		"Root/Center/ReceiverShell/Margin/Layout/Controls/Primary",
		"Root/Center/ReceiverShell/Margin/Layout/Controls/Choices/Verify",
		"Root/Center/ReceiverShell/Margin/Layout/Controls/Choices/Feed",
		"Root/Center/ReceiverShell/Margin/Layout/Controls/Close",
	]:
		var trace_button := overlay.get_node(button_path) as Button
		_check(trace_button.custom_minimum_size.y * physical_scale >= 44.0,
			"landscape trace control %s keeps a 44 physical px target" % trace_button.name)
	_check(anchor.reveal_trace(), "Reveal stage resolves the spatial layer")
	_check(anchor.get_trace_stage() == &"revealed", "stage advances to Reveal")
	_check(overlay.get_presented_stage() == &"reveal", "overlay presents evidence after Reveal")
	await get_tree().create_timer(0.38).timeout
	var revealed_snapshot: Dictionary = anchor.get_trace_snapshot()
	_check(bool(revealed_snapshot.get("afterimage_visible", false)),
		"Reveal shows a spatial afterimage")
	_check(bool(revealed_snapshot.get("afterimage_shader", false))
		and float(revealed_snapshot.get("afterimage_alignment", 0.0)) >= 0.9,
		"Reveal aligns the authored afterimage through its object shader")
	_check(float(revealed_snapshot.get("afterimage_extent", 0.0)) >= 270.0
		and float(revealed_snapshot.get("artifact_extent", 999.0)) <= 116.0,
		"authored spatial residue expands beyond its ordinary carrier")
	_check(float(revealed_snapshot.get("light_energy", 0.0))
		> float(focused_snapshot.get("light_energy", 0.0)),
		"Reveal reaches the strongest meaningful light state")
	_check(float(revealed_snapshot.get("light_radius", 0.0)) >= 110.0,
		"Reveal illuminates nearby ground while remaining locally bounded")

	var inventory_seen_during_signal := [false]
	var observer := func(recorded: MemoryEchoData) -> void:
		if recorded != null and recorded.id == data.id:
			inventory_seen_during_signal[0] = InventorySystem.get_count(data.keepsake_item) == 1
	ArchiveSystem.echo_recorded.connect(observer)
	var fed_before := CampaignSystem.get_fed_trace_count()
	_check(anchor.resolve_trace(ArchiveSystem.VERIFIED), "Verify/File choice resolves")
	ArchiveSystem.echo_recorded.disconnect(observer)
	_check(inventory_seen_during_signal[0], "keepsake exists before archive autosave signal")
	_check(ArchiveSystem.has_echo(data.id), "verified record enters archive")
	_check(ArchiveSystem.get_disposition(data.id) == ArchiveSystem.VERIFIED,
		"verified disposition is retained")
	_check(CampaignSystem.get_fed_trace_count() == fed_before,
		"Verify/File does not raise fed-trace consequence")
	_check(anchor.get_trace_stage() == &"spent", "filed anchor enters spent state")
	await get_tree().create_timer(0.32).timeout
	var spent_snapshot: Dictionary = anchor.get_trace_snapshot()
	_check(bool(spent_snapshot.get("artifact_visible", false)),
		"physical object remains visible after filing")
	_check(float(spent_snapshot.get("light_energy", 1.0))
		< float(detected_snapshot.get("light_energy", 0.0)),
		"filed object releases its practical light")
	_check(not bool(spent_snapshot.get("light_enabled", true)),
		"spent anchors stop paying a live-light cost")
	_check(not anchor.resolve_trace(ArchiveSystem.FED), "resolved anchor cannot be filed twice")
	anchor.queue_free()
	await get_tree().process_frame

	var restored := _spawn_anchor(data, "RestoredSpentAnchor")
	_check(restored.get_trace_stage() == &"spent", "re-instanced filed anchor restores spent state")
	_check(bool(restored.get_trace_snapshot().get("artifact_visible", false)),
		"re-instanced spent object remains visible")
	restored.queue_free()
	await get_tree().process_frame


func _check_fed_flow_and_save_roundtrip() -> void:
	ArchiveSystem.restore([])
	CampaignSystem.clear_narrative_state(false)
	InventorySystem.set_items({})
	var data := load(TRACE_PATHS[1]) as MemoryEchoData
	var anchor := _spawn_anchor(data, "FedAnchor")
	anchor.detect_from(anchor.global_position + Vector2(60, 0))
	anchor.focus_trace(anchor.global_position + Vector2(20, 0))
	anchor.reveal_trace()
	var before := CampaignSystem.get_fed_trace_count()
	_check(anchor.resolve_trace(ArchiveSystem.FED), "Feed choice resolves")
	_check(CampaignSystem.get_fed_trace_count() == before + 1,
		"feeding raises the narrative fed-trace axis exactly once")
	_check(ArchiveSystem.get_disposition(data.id) == ArchiveSystem.FED,
		"fed disposition enters archive")
	_check(anchor.get_trace_stage() == &"spent", "fed object also remains as a spent anchor")

	_check(SaveManager.SAVE_VERSION == 4, "save schema versions trace decisions")
	_check(SaveManager.save_game(""), "save writes trace state")
	var file := FileAccess.open(SaveManager.SAVE_PATH, FileAccess.READ)
	_check(file != null, "trace save can be read")
	var saved: Variant = {}
	if file != null:
		saved = JSON.parse_string(file.get_as_text())
		file.close()
	_check(typeof(saved) == TYPE_DICTIONARY, "trace save is valid JSON")
	if typeof(saved) == TYPE_DICTIONARY:
		var dispositions: Dictionary = saved.get("archive_dispositions", {})
		_check(dispositions.get(String(data.id), "") == "fed",
			"save stores the Feed decision")
		var narrative: Dictionary = saved.get("narrative", {})
		_check(Array(narrative.get("fed_trace_ids", [])).has(String(data.id)),
			"save stores the fed-trace consequence")
		ArchiveSystem.restore([])
		CampaignSystem.clear_narrative_state(false)
		ArchiveSystem.restore(saved.get("archive", []), dispositions)
		CampaignSystem.restore_narrative_state(narrative, int(saved.get("version", 0)))
		_check(ArchiveSystem.has_echo(data.id) and
			ArchiveSystem.get_disposition(data.id) == ArchiveSystem.FED,
			"serialized archive decision round-trips")
		_check(CampaignSystem.get_fed_trace_count() == before + 1,
			"serialized consequence axis round-trips")
	anchor.queue_free()
	await get_tree().process_frame


func _check_restore_is_idempotent() -> void:
	var signal_count := [0]
	var observer := func(_data: MemoryEchoData) -> void: signal_count[0] += 1
	ArchiveSystem.echo_recorded.connect(observer)
	ArchiveSystem.restore(
		["echo_last_signal", "echo_last_signal", "echo_sun_lid"],
		{"echo_last_signal": "verified", "echo_sun_lid": "fed"},
	)
	ArchiveSystem.echo_recorded.disconnect(observer)
	_check(ArchiveSystem.get_count() == 2, "restore de-duplicates trace ids")
	_check(signal_count[0] == 0, "restore does not replay recovery consequences")
	_check(ArchiveSystem.get_disposition(&"echo_sun_lid") == ArchiveSystem.FED,
		"restore retains per-trace disposition")
	ArchiveSystem.restore(["echo_last_signal"])
	_check(ArchiveSystem.get_disposition(&"echo_last_signal") == ArchiveSystem.VERIFIED,
		"legacy id-array saves migrate to verified disposition")

	var archive_scene := load("res://scenes/ui/archive_overlay.tscn") as PackedScene
	var archive_overlay := archive_scene.instantiate() as ArchiveOverlay
	add_child(archive_overlay)
	archive_overlay.call("_refresh")
	var content := archive_overlay.get_node(
		"Center/Panel/Margin/Layout/Content") as RichTextLabel
	var archive_text := content.text.to_lower()
	_check("fallen-mast receiver" in archive_text and "contradiction" in archive_text,
		"archive renders object and evidence metadata")
	archive_overlay.call("_apply_responsive_layout", Vector2(430, 760))
	var hint := archive_overlay.get_node(
		"Center/Panel/Margin/Layout/Footer/Hint") as Label
	_check(not hint.visible, "archive removes secondary footer copy on narrow mobile view")
	archive_overlay.queue_free()


func _spawn_anchor(data: MemoryEchoData, node_name: String) -> MemoryEcho:
	var scene := load("res://scenes/world/memory_echo.tscn") as PackedScene
	var anchor := scene.instantiate() as MemoryEcho
	anchor.name = node_name
	anchor.echo_data = data
	add_child(anchor)
	return anchor


func _capture_state() -> void:
	_archive_before = ArchiveSystem.get_recovered_ids()
	_dispositions_before = ArchiveSystem.get_dispositions()
	_narrative_before = CampaignSystem.get_narrative_state()
	_inventory_before = InventorySystem.get_items()
	_world_before = WorldState.get_state()
	_upgrades_before = BaseUpgradeSystem.get_built_ids()
	_save_existed = SaveManager.has_save()
	if _save_existed:
		_save_bytes = FileAccess.get_file_as_bytes(SaveManager.SAVE_PATH)


func _restore_state() -> void:
	GameManager.set_dialogue_active(false)
	ArchiveSystem.restore(_archive_before, _dispositions_before)
	CampaignSystem.restore_narrative_state(_narrative_before, SaveManager.SAVE_VERSION)
	InventorySystem.set_items(_inventory_before)
	WorldState.restore(_world_before)
	BaseUpgradeSystem.restore(_upgrades_before)
	if _save_existed:
		var file := FileAccess.open(SaveManager.SAVE_PATH, FileAccess.WRITE)
		if file != null:
			file.store_buffer(_save_bytes)
			file.close()
	else:
		SaveManager.delete_save()


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)


func _color_distance(a: Color, b: Color) -> float:
	return Vector3(a.r, a.g, a.b).distance_to(Vector3(b.r, b.g, b.b))
