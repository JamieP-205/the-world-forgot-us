class_name LightingDirector
extends Node2D
## Runtime 2D lighting foundation.
##
## Install once under the persistent Main node with:
##     LightingDirector.install(self)
##
## The director remains scene-agnostic: it reacts to EventBus.level_loaded,
## discovers compatible sprites and static collision shapes, and attaches only
## runtime children. Existing scenes and imported diffuse textures are never
## mutated on disk.

const PROCESSED_ROOT := "res://assets/processed/"
const NORMAL_ROOT := "res://assets/processed/normals/"
const LIGHT_TEXTURE_SIZE := 128
const GENERATED_LIGHT_NAME := "__LightingPoint"
const PLAYER_LIGHT_NAME := "__LightingPlayerWarm"
const OCCLUDER_PREFIX := "__LightingOccluder_"
const NORMAL_META := &"lighting_normal_applied"
const LOW_EFFECTS_SETTING := "rendering/environment/ashland_low_effects"
const LIGHT_PRIORITY_META := &"lighting_priority"
const SHADOW_PRIORITY_META := &"lighting_shadow_priority"
const CAST_SHADOWS_META := &"lighting_cast_shadows"
const LIGHT_IGNORE_META := &"lighting_ignore"

@export var player_light_enabled := true
@export var player_light_radius := 118.0
@export var player_light_energy := 0.42
@export var max_level_lights := 10
@export var max_shadowed_level_lights := 1
@export var shadow_filter_smooth := 3.0

var _light_texture: ImageTexture
var _canvas_texture_cache: Dictionary = {}
var _sprite_frames_cache: Dictionary = {}
var _normal_pair_count := 0
var _polygon_normal_pair_count := 0
var _occluder_count := 0
var _level_light_count := 0
var _shadowed_level_light_count := 0
var _scanner_light_count := 0
var _low_effects_enabled := false


## Convenience integration API. Calling this repeatedly is idempotent.
static func install(host: Node) -> LightingDirector:
	if host == null:
		return null
	var existing := host.get_node_or_null(NodePath("LightingDirector"))
	if existing is LightingDirector:
		return existing as LightingDirector
	var director := LightingDirector.new()
	director.name = "LightingDirector"
	host.add_child(director)
	return director


func _ready() -> void:
	if not EventBus.level_loaded.is_connected(_on_level_loaded):
		EventBus.level_loaded.connect(_on_level_loaded)
	if not EventBus.scanner_pulsed.is_connected(_on_scanner_pulsed):
		EventBus.scanner_pulsed.connect(_on_scanner_pulsed)
	_configure_effect_quality()
	call_deferred("refresh")


func _on_level_loaded() -> void:
	# Main emits after the level has entered the tree. One deferred tick also
	# lets runtime-authored campaign maps finish adding their props and bodies.
	call_deferred("refresh")


## Rebuild/discover lighting for a level. `level_root` is optional so tests or
## custom scenes can opt in without needing Main.get_current_level().
func refresh(level_root: Node = null) -> void:
	_normal_pair_count = 0
	_polygon_normal_pair_count = 0
	_occluder_count = 0
	_level_light_count = 0
	_shadowed_level_light_count = 0

	var level := level_root if level_root != null else _find_level_root()
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		_apply_normal_maps(player)
		_ensure_player_light(player)
	if level != null:
		_apply_normal_maps(level)
		_generate_occluders(level)
		_generate_level_lights(level)


## Explicit light API for future authored content. Runtime heuristics already
## cover campaign glows/echoes, but groups or code can request exact placement.
func register_light(
		anchor: Node2D,
		tone: StringName = &"cyan",
		radius: float = 120.0,
		energy: float = 0.58,
		shadows: bool = true) -> PointLight2D:
	if anchor == null:
		return null
	var color := Color(0.46, 0.82, 0.88) if tone == &"cyan" \
		else Color(1.0, 0.78, 0.52)
	var node_name := "__LightingRegistered_%s" % String(tone)
	return _attach_light(anchor, node_name, color, radius, energy, shadows)


## Public transient-light API; EventBus.scanner_pulsed calls it automatically.
func spawn_scanner_light(origin: Vector2, radius: float) -> PointLight2D:
	# Scanner input can repeat while the previous wash is still fading. Keeping
	# only two washes prevents additive cyan from flattening the whole scene.
	if _scanner_light_count >= 2:
		return null
	var light := PointLight2D.new()
	light.name = "__LightingScannerPulse"
	add_child(light)
	light.global_position = origin
	_configure_light(light, Color(0.46, 0.86, 0.93), radius * 0.82, 0.92, false)
	var final_scale := light.texture_scale
	light.texture_scale = final_scale * 0.22
	_scanner_light_count += 1

	var tween := light.create_tween().set_parallel(true)
	tween.tween_property(light, "texture_scale", final_scale, 0.52)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(light, "energy", 0.0, 0.52)\
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(func() -> void:
		_scanner_light_count = maxi(_scanner_light_count - 1, 0)
		light.queue_free()
	)
	return light


func get_stats() -> Dictionary:
	return {
		"normal_pairs": _normal_pair_count,
		"polygon_normal_pairs": _polygon_normal_pair_count,
		"occluders": _occluder_count,
		"level_lights": _level_light_count,
		"shadowed_level_lights": _shadowed_level_light_count,
		"scanner_lights": _scanner_light_count,
		"canvas_cache": _canvas_texture_cache.size(),
		"animation_cache": _sprite_frames_cache.size(),
		"low_effects": _low_effects_enabled,
	}


func _on_scanner_pulsed(origin: Vector2, radius: float) -> void:
	spawn_scanner_light(origin, radius)


func _find_level_root() -> Node:
	var main := get_tree().get_first_node_in_group("main")
	if main != null and main.has_method("get_current_level"):
		var current: Variant = main.call("get_current_level")
		if current is Node:
			return current as Node
	var campaign_levels := get_tree().get_nodes_in_group("campaign_levels")
	if not campaign_levels.is_empty():
		return campaign_levels[0] as Node
	return null


func _configure_effect_quality() -> void:
	# Web builds default to a single screen sample. Desktop keeps the richer
	# three-sample wash. Projects can override either default without a UI or a
	# scene change by defining this ProjectSetting as a boolean.
	_low_effects_enabled = bool(ProjectSettings.get_setting(
		LOW_EFFECTS_SETTING,
		OS.has_feature("web")
	))
	var host := get_parent()
	if host == null:
		return
	var grade := host.get_node_or_null("ScreenGrade/Grade") as CanvasItem
	if grade == null or not (grade.material is ShaderMaterial):
		return
	(grade.material as ShaderMaterial).set_shader_parameter(
		"low_effects",
		_low_effects_enabled
	)


# --- Normal maps -----------------------------------------------------------

func _apply_normal_maps(root_node: Node) -> void:
	var stack: Array[Node] = [root_node]
	while not stack.is_empty():
		var current: Node = stack.pop_back()
		if current is Sprite2D:
			_upgrade_sprite(current as Sprite2D)
		elif current is AnimatedSprite2D:
			_upgrade_animated_sprite(current as AnimatedSprite2D)
		elif current is Polygon2D:
			_upgrade_polygon(current as Polygon2D)
		for child in current.get_children():
			stack.append(child as Node)


func _upgrade_sprite(sprite: Sprite2D) -> void:
	if sprite.texture == null:
		return
	if bool(sprite.get_meta(NORMAL_META, false)):
		if _texture_has_normal(sprite.texture):
			_normal_pair_count += 1
		return
	var upgraded := _upgrade_texture(sprite.texture)
	if upgraded != sprite.texture:
		sprite.texture = upgraded
		_normal_pair_count += 1
	elif _texture_has_normal(sprite.texture):
		_normal_pair_count += 1
	sprite.set_meta(NORMAL_META, true)


func _upgrade_polygon(polygon: Polygon2D) -> void:
	if polygon.texture == null:
		return
	if bool(polygon.get_meta(NORMAL_META, false)):
		if _texture_has_normal(polygon.texture):
			_normal_pair_count += 1
			_polygon_normal_pair_count += 1
		return
	var upgraded := _upgrade_texture(polygon.texture)
	if upgraded != polygon.texture:
		polygon.texture = upgraded
		_normal_pair_count += 1
		_polygon_normal_pair_count += 1
	elif _texture_has_normal(polygon.texture):
		_normal_pair_count += 1
		_polygon_normal_pair_count += 1
	polygon.set_meta(NORMAL_META, true)


func _upgrade_animated_sprite(sprite: AnimatedSprite2D) -> void:
	if sprite.sprite_frames == null:
		return
	if bool(sprite.get_meta(NORMAL_META, false)):
		if _sprite_frames_have_normal(sprite.sprite_frames):
			_normal_pair_count += 1
		return
	var source := sprite.sprite_frames
	var cache_key := source.get_instance_id()
	if _sprite_frames_cache.has(cache_key):
		_assign_sprite_frames(sprite, _sprite_frames_cache[cache_key] as SpriteFrames)
		_normal_pair_count += 1
		sprite.set_meta(NORMAL_META, true)
		return

	var upgraded := SpriteFrames.new()
	upgraded.resource_name = source.resource_name
	for meta_name in source.get_meta_list():
		upgraded.set_meta(meta_name, source.get_meta(meta_name))
	for default_animation in upgraded.get_animation_names():
		upgraded.remove_animation(default_animation)
	var changed := false
	for animation in source.get_animation_names():
		upgraded.add_animation(animation)
		upgraded.set_animation_loop(animation, source.get_animation_loop(animation))
		upgraded.set_animation_speed(animation, source.get_animation_speed(animation))
		for frame_index in source.get_frame_count(animation):
			var original := source.get_frame_texture(animation, frame_index)
			var replacement := _upgrade_texture(original)
			changed = changed or replacement != original
			upgraded.add_frame(
				animation,
				replacement,
				source.get_frame_duration(animation, frame_index)
			)

	if changed:
		_sprite_frames_cache[cache_key] = upgraded
		_assign_sprite_frames(sprite, upgraded)
		_normal_pair_count += 1
	sprite.set_meta(NORMAL_META, true)


func _assign_sprite_frames(sprite: AnimatedSprite2D, frames: SpriteFrames) -> void:
	var current_animation := sprite.animation
	var current_frame := sprite.frame
	var current_progress := sprite.frame_progress
	var was_playing := sprite.is_playing()
	sprite.sprite_frames = frames
	if frames.has_animation(current_animation):
		sprite.animation = current_animation
		sprite.frame = mini(current_frame, maxi(frames.get_frame_count(current_animation) - 1, 0))
		sprite.frame_progress = clampf(current_progress, 0.0, 1.0)
		if was_playing:
			sprite.play()


func _sprite_frames_have_normal(frames: SpriteFrames) -> bool:
	for animation in frames.get_animation_names():
		for frame_index in frames.get_frame_count(animation):
			if _texture_has_normal(frames.get_frame_texture(animation, frame_index)):
				return true
	return false


func _texture_has_normal(texture: Texture2D) -> bool:
	if texture is CanvasTexture:
		return (texture as CanvasTexture).normal_texture != null
	if texture is AtlasTexture:
		return _texture_has_normal((texture as AtlasTexture).atlas)
	return false


func _upgrade_texture(texture: Texture2D) -> Texture2D:
	if texture == null or texture is CanvasTexture:
		return texture
	if texture is AtlasTexture:
		var source_atlas := texture as AtlasTexture
		var atlas_cache_key := _atlas_cache_key(source_atlas)
		if _canvas_texture_cache.has(atlas_cache_key):
			return _canvas_texture_cache[atlas_cache_key] as Texture2D
		var upgraded_atlas := _upgrade_texture(source_atlas.atlas)
		if upgraded_atlas == source_atlas.atlas:
			return texture
		# CanvasTexture must remain outermost so the renderer sees its normal
		# channel. Cropping a CanvasTexture inside an AtlasTexture can preserve
		# the diffuse pixels while silently dropping normal lighting.
		if upgraded_atlas is CanvasTexture:
			var upgraded_canvas := upgraded_atlas as CanvasTexture
			if upgraded_canvas.diffuse_texture == null or upgraded_canvas.normal_texture == null:
				return texture
			var diffuse_region := _copy_atlas_region(
				source_atlas,
				upgraded_canvas.diffuse_texture
			)
			var normal_region := _copy_atlas_region(
				source_atlas,
				upgraded_canvas.normal_texture
			)
			var region_canvas := CanvasTexture.new()
			region_canvas.diffuse_texture = diffuse_region
			region_canvas.normal_texture = normal_region
			_canvas_texture_cache[atlas_cache_key] = region_canvas
			return region_canvas
		var atlas_copy := AtlasTexture.new()
		atlas_copy.atlas = upgraded_atlas
		atlas_copy.region = source_atlas.region
		atlas_copy.margin = source_atlas.margin
		atlas_copy.filter_clip = source_atlas.filter_clip
		return atlas_copy

	var diffuse_path := texture.resource_path
	if diffuse_path.is_empty():
		return texture
	if _canvas_texture_cache.has(diffuse_path):
		return _canvas_texture_cache[diffuse_path] as Texture2D
	var normal_path := _normal_path_for(diffuse_path)
	if normal_path.is_empty() or not ResourceLoader.exists(normal_path):
		return texture
	var normal := load(normal_path) as Texture2D
	if normal == null:
		return texture
	var canvas := CanvasTexture.new()
	canvas.diffuse_texture = texture
	canvas.normal_texture = normal
	_canvas_texture_cache[diffuse_path] = canvas
	return canvas


func _copy_atlas_region(source: AtlasTexture, atlas: Texture2D) -> AtlasTexture:
	var copy := AtlasTexture.new()
	copy.atlas = atlas
	copy.region = source.region
	copy.margin = source.margin
	copy.filter_clip = source.filter_clip
	return copy


func _atlas_cache_key(texture: AtlasTexture) -> String:
	var atlas_path := ""
	if texture.atlas != null:
		atlas_path = texture.atlas.resource_path
	return "atlas|%s|%s|%s|%s" % [
		atlas_path,
		str(texture.region),
		str(texture.margin),
		str(texture.filter_clip),
	]


func _normal_path_for(diffuse_path: String) -> String:
	if not diffuse_path.begins_with(PROCESSED_ROOT) \
			or diffuse_path.begins_with(NORMAL_ROOT):
		return ""
	var relative := diffuse_path.trim_prefix(PROCESSED_ROOT)
	var extension := relative.get_extension()
	if extension.is_empty():
		return ""
	return NORMAL_ROOT + relative.get_basename() + "_normal.png"


# --- Point lights ----------------------------------------------------------

func _ensure_player_light(player: Node) -> void:
	if not player_light_enabled or not (player is Node2D):
		return
	var player_2d := player as Node2D
	var existing := player_2d.get_node_or_null(NodePath(PLAYER_LIGHT_NAME))
	if existing is PointLight2D:
		return
	var light := PointLight2D.new()
	light.name = PLAYER_LIGHT_NAME
	player_2d.add_child(light)
	light.position = Vector2(0, -5)
	_configure_light(
		light,
		Color(1.0, 0.80, 0.57),
		player_light_radius,
		player_light_energy,
		true
	)


func _generate_level_lights(root_node: Node) -> void:
	var candidates: Array[Dictionary] = []
	var stack: Array[Node] = [root_node]
	while not stack.is_empty():
		var current: Node = stack.pop_back()
		if current is Node2D and not (current is PointLight2D) and not (current is LightOccluder2D):
			var anchor := current as Node2D
			var profile := _light_profile(anchor)
			if not profile.is_empty():
				candidates.append({
					"anchor": anchor,
					"profile": profile,
					"path": String(root_node.get_path_to(anchor)),
					"priority": _light_priority(anchor),
					"shadow_priority": _shadow_priority(anchor),
				})
		for child in current.get_children():
			stack.append(child as Node)

	# Scene sibling order must not decide which practical light casts shadows.
	candidates.sort_custom(_light_candidate_before)
	var selected: Array[Dictionary] = []
	var selected_positions: Array[Vector2] = []
	for candidate in candidates:
		if selected.size() >= max_level_lights:
			break
		var anchor := candidate["anchor"] as Node2D
		var separated := true
		for position in selected_positions:
			if anchor.global_position.distance_to(position) < 104.0:
				separated = false
				break
		if not separated:
			continue
		selected.append(candidate)
		selected_positions.append(anchor.global_position)

	var shadow_ranked := selected.duplicate()
	shadow_ranked.sort_custom(_shadow_candidate_before)
	var shadow_anchors: Array[Node2D] = []
	for candidate in shadow_ranked:
		if shadow_anchors.size() >= max_shadowed_level_lights:
			break
		var profile := candidate["profile"] as Dictionary
		if bool(profile.get("shadow_eligible", false)):
			shadow_anchors.append(candidate["anchor"] as Node2D)
	_shadowed_level_light_count = shadow_anchors.size()

	for candidate in selected:
		var anchor := candidate["anchor"] as Node2D
		var profile := candidate["profile"] as Dictionary
		var attached := _attach_light(
			anchor,
			GENERATED_LIGHT_NAME,
			profile["color"],
			float(profile["radius"]),
			float(profile["energy"]),
			anchor in shadow_anchors
		)
		if attached != null:
			_suppress_legacy_light_card(anchor)
			_level_light_count += 1


func _suppress_legacy_light_card(anchor: Node2D) -> void:
	# Older authored scenes painted illumination as a translucent Polygon2D.
	# Even when the polygon was nominally round, its hard edge read as a square
	# colour card around the prop once the global grade became darker. Keep the
	# anchor alive for the real soft PointLight2D child, but make only its baked
	# fill transparent. Children do not inherit Polygon2D.color alpha.
	if not (anchor is Polygon2D):
		return
	var lower := String(anchor.name).to_lower()
	if not ("glow" in lower or "halo" in lower or "pool" in lower):
		return
	var polygon := anchor as Polygon2D
	if not polygon.has_meta("lighting_original_alpha"):
		polygon.set_meta("lighting_original_alpha", polygon.color.a)
	polygon.color.a = 0.0


func _light_candidate_before(a: Dictionary, b: Dictionary) -> bool:
	var a_priority := float(a.get("priority", 0.0))
	var b_priority := float(b.get("priority", 0.0))
	if not is_equal_approx(a_priority, b_priority):
		return a_priority > b_priority
	return String(a.get("path", "")) < String(b.get("path", ""))


func _shadow_candidate_before(a: Dictionary, b: Dictionary) -> bool:
	var a_priority := float(a.get("shadow_priority", 0.0))
	var b_priority := float(b.get("shadow_priority", 0.0))
	if not is_equal_approx(a_priority, b_priority):
		return a_priority > b_priority
	return String(a.get("path", "")) < String(b.get("path", ""))


func _light_priority(anchor: Node2D) -> float:
	if anchor.has_meta(LIGHT_PRIORITY_META):
		return float(anchor.get_meta(LIGHT_PRIORITY_META))
	var lower := String(anchor.name).to_lower()
	var priority := 100.0
	if anchor.is_in_group("lighting_hero"):
		priority += 1000.0
	if "lantern" in lower:
		priority += 500.0
	elif "mnemoscope" in lower or "console" in lower or "radio" in lower:
		priority += 400.0
	elif "relay" in lower or "signal" in lower or "firsttone" in lower:
		priority += 300.0
	elif "echo" in lower or "warden" in lower:
		priority += 200.0
	elif "glow" in lower:
		priority += 100.0
	return priority


func _shadow_priority(anchor: Node2D) -> float:
	if anchor.has_meta(SHADOW_PRIORITY_META):
		return float(anchor.get_meta(SHADOW_PRIORITY_META))
	var lower := String(anchor.name).to_lower()
	var priority := _light_priority(anchor)
	if anchor.is_in_group("lighting_shadow_hero"):
		priority += 2000.0
	if "lantern" in lower:
		priority += 700.0
	elif "console" in lower or "radio" in lower:
		priority += 350.0
	return priority


func _light_profile(anchor: Node2D) -> Dictionary:
	var lower := String(anchor.name).to_lower()
	if lower.begins_with("__lighting") \
			or _has_authored_light_owner(anchor) \
			or not anchor.is_visible_in_tree():
		return {}

	var explicit_cyan := anchor.is_in_group("lighting_cyan")
	var explicit_amber := anchor.is_in_group("lighting_amber")
	var has_light_name := (
		"glow" in lower
		or "echo" in lower
		or "relay" in lower
		or "signal" in lower
		or "radio" in lower
		or "lantern" in lower
		or "console" in lower
		or "mnemoscope" in lower
		or "wraith" in lower
		or "warden" in lower
		or "firsttone" in lower
	)
	if not explicit_cyan and not explicit_amber and not has_light_name:
		return {}

	var cyan := explicit_cyan or (
		"echo" in lower
		or "relay" in lower
		or "signal" in lower
		or "wraith" in lower
		or "warden" in lower
		or "mnemoscope" in lower
		or "firsttone" in lower
	)
	if anchor is Polygon2D and not explicit_cyan and not explicit_amber:
		var tint := (anchor as Polygon2D).color
		if tint.b > tint.r * 1.08 and tint.g > tint.r:
			cyan = true
		elif tint.r > tint.b * 1.12:
			cyan = false
	if explicit_amber or "lantern" in lower:
		cyan = false

	var radius := 102.0
	var energy := 0.38
	if "glow" in lower:
		radius = 132.0
		energy = 0.43
	if "relay" in lower or "signal" in lower:
		radius = 145.0
		energy = 0.50
	if "echo" in lower or "wraith" in lower:
		radius = 96.0
		energy = 0.46
	if "warden" in lower:
		radius = 154.0
		energy = 0.56

	var shadow_preferred := (
		not cyan
		and (
			explicit_amber
			or "lantern" in lower
			or "console" in lower
			or "radio" in lower
			or "glow" in lower
		)
	)
	var shadow_eligible := bool(anchor.get_meta(
		CAST_SHADOWS_META,
		shadow_preferred
	))

	return {
		"color": Color(0.45, 0.82, 0.88) if cyan else Color(1.0, 0.77, 0.50),
		"radius": radius,
		"energy": energy,
		"shadow_eligible": shadow_eligible,
	}


func _has_authored_light_owner(anchor: Node2D) -> bool:
	var current: Node = anchor
	while current != null:
		if bool(current.get_meta(LIGHT_IGNORE_META, false)):
			return true
		current = current.get_parent()
	return false


func _attach_light(
		anchor: Node2D,
		node_name: String,
		color: Color,
		radius: float,
		energy: float,
		shadows: bool) -> PointLight2D:
	var existing := anchor.get_node_or_null(NodePath(node_name))
	if existing is PointLight2D:
		var existing_light := existing as PointLight2D
		_configure_light(existing_light, color, radius, energy, shadows)
		return existing_light
	var light := PointLight2D.new()
	light.name = node_name
	anchor.add_child(light)
	light.position = Vector2.ZERO
	_configure_light(light, color, radius, energy, shadows)
	return light


func _configure_light(
		light: PointLight2D,
		color: Color,
		radius: float,
		energy: float,
		shadows: bool) -> void:
	light.texture = _get_light_texture()
	light.texture_scale = maxf(radius * 2.0 / float(LIGHT_TEXTURE_SIZE), 0.05)
	# A higher virtual lamp keeps normal relief broad and painterly instead of
	# embossing every sprite edge into a metallic-looking ridge.
	light.height = maxf(radius * 0.78, 48.0)
	light.color = color
	light.set_meta("day_night_base_energy", energy)
	if not light.is_in_group("day_night_practical"):
		light.add_to_group("day_night_practical")
	var main := get_tree().get_first_node_in_group("main")
	var night_factor := 0.0
	if main != null and main.has_method("is_night") and bool(main.call("is_night")):
		night_factor = 1.0
	light.energy = energy * lerpf(0.72, 1.42, night_factor)
	light.shadow_enabled = shadows
	light.shadow_filter = Light2D.SHADOW_FILTER_PCF5
	light.shadow_filter_smooth = shadow_filter_smooth
	light.shadow_item_cull_mask = 1


func _get_light_texture() -> ImageTexture:
	if _light_texture != null:
		return _light_texture
	var image := Image.create(
		LIGHT_TEXTURE_SIZE,
		LIGHT_TEXTURE_SIZE,
		false,
		Image.FORMAT_RGBA8
	)
	var center := Vector2(LIGHT_TEXTURE_SIZE - 1, LIGHT_TEXTURE_SIZE - 1) * 0.5
	# Normalize to the nearest edge, not the corner. The previous corner-based
	# radius left visible energy on the texture's square edges, which read as a
	# giant polygon when several lights overlapped.
	var max_distance := center.x
	for y in LIGHT_TEXTURE_SIZE:
		for x in LIGHT_TEXTURE_SIZE:
			var distance := Vector2(x, y).distance_to(center) / max_distance
			var linear := clampf(1.0 - distance, 0.0, 1.0)
			var falloff := smoothstep(0.0, 1.0, linear)
			falloff = pow(falloff, 1.22)
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, falloff))
	_light_texture = ImageTexture.create_from_image(image)
	return _light_texture


# --- Shadow occluders ------------------------------------------------------

func _generate_occluders(root_node: Node) -> void:
	var stack: Array[Node] = [root_node]
	while not stack.is_empty():
		var current: Node = stack.pop_back()
		if current is StaticBody2D:
			_add_body_occluders(current as StaticBody2D)
		for child in current.get_children():
			stack.append(child as Node)


func _add_body_occluders(body: StaticBody2D) -> void:
	# Shadow casting is structural, not a mirror of physics collision. Loot
	# crates contain a nested SolidBody, while exits and interactables may also
	# grow blocking children at runtime; all of those make implausibly large
	# trapezoids when lit from nearby. Limit occlusion to authored buildings and
	# substantial world masses.
	if not _body_is_structural(body):
		return
	# Direct children preserve authored transforms while avoiding trigger
	# volumes elsewhere in the subtree.
	for child in body.get_children():
		if not (child is CollisionShape2D):
			continue
		var collision := child as CollisionShape2D
		if collision.disabled or collision.shape == null:
			continue
		if not _shape_is_structural(collision.shape):
			continue
		var points := _occluder_points(collision.shape)
		if points.is_empty():
			continue
		var occluder_name := OCCLUDER_PREFIX + str(collision.get_index())
		var existing := body.get_node_or_null(NodePath(occluder_name))
		if existing is LightOccluder2D:
			_occluder_count += 1
			_suppress_baked_footprint(body)
			continue

		var polygon := OccluderPolygon2D.new()
		polygon.polygon = points
		polygon.closed = true
		polygon.cull_mode = OccluderPolygon2D.CULL_DISABLED
		var occluder := LightOccluder2D.new()
		occluder.name = occluder_name
		occluder.occluder = polygon
		occluder.occluder_light_mask = 1
		body.add_child(occluder)
		occluder.transform = collision.transform
		_occluder_count += 1
		_suppress_baked_footprint(body)


func _suppress_baked_footprint(body: StaticBody2D) -> void:
	# Procedural campaign buildings have a soft fallback footprint for scenes
	# without live lighting. Once a real occluder exists, drawing both produces
	# an opaque double shadow. Only exact opt-in names/metadata are suppressed;
	# authored contact shadows such as vehicle undersides remain untouched.
	for child in body.get_children():
		if not (child is CanvasItem):
			continue
		var lower := String(child.name).to_lower()
		if lower == "footprintshadow" or bool(child.get_meta("lighting_baked_shadow", false)):
			(child as CanvasItem).visible = false


func _body_is_structural(body: StaticBody2D) -> bool:
	# Any StaticBody nested under an interaction trigger is implementation
	# detail (not level architecture), most notably LootContainer/SolidBody.
	var ancestor := body.get_parent()
	while ancestor != null:
		if ancestor is Area2D:
			return false
		ancestor = ancestor.get_parent()

	var lower := String(body.name).to_lower()
	for fragment in ["solidbody", "loot", "crate", "cache", "exit", "trigger", "beacon"]:
		if fragment in lower:
			return false

	# Collision-only nodes are invisible map bounds; small visible bodies are
	# props. A qualifying body must have both a visible authored representation
	# and at least one building-scale collision shape.
	var has_visible_geometry := false
	for child in body.get_children():
		if child is CollisionShape2D or child is LightOccluder2D:
			continue
		if child is CanvasItem and (child as CanvasItem).visible:
			has_visible_geometry = true
			break
	if not has_visible_geometry:
		return false
	for child in body.get_children():
		if child is CollisionShape2D:
			var collision := child as CollisionShape2D
			if not collision.disabled and _shape_is_structural(collision.shape):
				return true
	return false


func _shape_is_structural(shape: Shape2D) -> bool:
	if shape is RectangleShape2D:
		var size := (shape as RectangleShape2D).size
		# Both dimensions matter: thin walls/canopies project the longest and
		# hardest wedges, despite covering very little visible mass.
		return minf(size.x, size.y) >= 60.0 and maxf(size.x, size.y) >= 145.0
	if shape is CircleShape2D:
		return (shape as CircleShape2D).radius >= 72.0
	if shape is ConvexPolygonShape2D:
		var points := (shape as ConvexPolygonShape2D).points
		if points.size() < 3:
			return false
		var bounds := Rect2(points[0], Vector2.ZERO)
		for point in points:
			bounds = bounds.expand(point)
		return minf(bounds.size.x, bounds.size.y) >= 60.0 \
			and maxf(bounds.size.x, bounds.size.y) >= 145.0
	return false


func _occluder_points(shape: Shape2D) -> PackedVector2Array:
	if shape is RectangleShape2D:
		var half := (shape as RectangleShape2D).size * 0.5
		return PackedVector2Array([
			Vector2(-half.x, -half.y),
			Vector2(half.x, -half.y),
			Vector2(half.x, half.y),
			Vector2(-half.x, half.y),
		])
	if shape is CircleShape2D:
		var radius := (shape as CircleShape2D).radius
		var points := PackedVector2Array()
		for index in 24:
			var angle := TAU * float(index) / 24.0
			points.append(Vector2(cos(angle), sin(angle)) * radius)
		return points
	if shape is ConvexPolygonShape2D:
		return (shape as ConvexPolygonShape2D).points
	return PackedVector2Array()
