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

@export var player_light_enabled := true
@export var player_light_radius := 155.0
@export var player_light_energy := 0.78
@export var max_level_lights := 18
@export var max_shadowed_level_lights := 7
@export var shadow_filter_smooth := 1.5

var _light_texture: ImageTexture
var _canvas_texture_cache: Dictionary = {}
var _sprite_frames_cache: Dictionary = {}
var _normal_pair_count := 0
var _occluder_count := 0
var _level_light_count := 0
var _scanner_light_count := 0


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
	call_deferred("refresh")


func _on_level_loaded() -> void:
	# Main emits after the level has entered the tree. One deferred tick also
	# lets runtime-authored campaign maps finish adding their props and bodies.
	call_deferred("refresh")


## Rebuild/discover lighting for a level. `level_root` is optional so tests or
## custom scenes can opt in without needing Main.get_current_level().
func refresh(level_root: Node = null) -> void:
	_normal_pair_count = 0
	_occluder_count = 0
	_level_light_count = 0

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
		radius: float = 135.0,
		energy: float = 0.9,
		shadows: bool = true) -> PointLight2D:
	if anchor == null:
		return null
	var color := Color(0.32, 0.92, 1.0) if tone == &"cyan" \
		else Color(1.0, 0.66, 0.28)
	var node_name := "__LightingRegistered_%s" % String(tone)
	return _attach_light(anchor, node_name, color, radius, energy, shadows)


## Public transient-light API; EventBus.scanner_pulsed calls it automatically.
func spawn_scanner_light(origin: Vector2, radius: float) -> PointLight2D:
	var light := PointLight2D.new()
	light.name = "__LightingScannerPulse"
	add_child(light)
	light.global_position = origin
	_configure_light(light, Color(0.28, 0.94, 1.0), radius, 2.15, true)
	var final_scale := light.texture_scale
	light.texture_scale = final_scale * 0.14
	_scanner_light_count += 1

	var tween := light.create_tween().set_parallel(true)
	tween.tween_property(light, "texture_scale", final_scale, 0.58)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(light, "energy", 0.0, 0.58)\
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(func() -> void:
		_scanner_light_count = maxi(_scanner_light_count - 1, 0)
		light.queue_free()
	)
	return light


func get_stats() -> Dictionary:
	return {
		"normal_pairs": _normal_pair_count,
		"occluders": _occluder_count,
		"level_lights": _level_light_count,
		"scanner_lights": _scanner_light_count,
		"canvas_cache": _canvas_texture_cache.size(),
		"animation_cache": _sprite_frames_cache.size(),
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


# --- Normal maps -----------------------------------------------------------

func _apply_normal_maps(root_node: Node) -> void:
	var stack: Array[Node] = [root_node]
	while not stack.is_empty():
		var current: Node = stack.pop_back()
		if current is Sprite2D:
			_upgrade_sprite(current as Sprite2D)
		elif current is AnimatedSprite2D:
			_upgrade_animated_sprite(current as AnimatedSprite2D)
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
	sprite.set_meta(NORMAL_META, true)


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
		var upgraded_atlas := _upgrade_texture(source_atlas.atlas)
		if upgraded_atlas == source_atlas.atlas:
			return texture
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
		Color(1.0, 0.66, 0.31),
		player_light_radius,
		player_light_energy,
		true
	)


func _generate_level_lights(root_node: Node) -> void:
	var shadowed := 0
	var stack: Array[Node] = [root_node]
	while not stack.is_empty() and _level_light_count < max_level_lights:
		var current: Node = stack.pop_back()
		if current is Node2D and not (current is PointLight2D) \
				and not (current is LightOccluder2D):
			var anchor := current as Node2D
			var profile := _light_profile(anchor)
			if not profile.is_empty():
				var cast_shadows := shadowed < max_shadowed_level_lights
				var attached := _attach_light(
					anchor,
					GENERATED_LIGHT_NAME,
					profile["color"],
					float(profile["radius"]),
					float(profile["energy"]),
					cast_shadows
				)
				if attached != null:
					_level_light_count += 1
					if cast_shadows:
						shadowed += 1
		for child in current.get_children():
			stack.append(child as Node)


func _light_profile(anchor: Node2D) -> Dictionary:
	var lower := String(anchor.name).to_lower()
	if lower.begins_with("__lighting"):
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

	var radius := 118.0
	var energy := 0.72
	if "glow" in lower:
		radius = 155.0
		energy = 0.82
	if "relay" in lower or "signal" in lower:
		radius = 168.0
		energy = 0.92
	if "echo" in lower or "wraith" in lower:
		radius = 112.0
		energy = 0.86
	if "warden" in lower:
		radius = 185.0
		energy = 1.05

	return {
		"color": Color(0.30, 0.91, 1.0) if cyan else Color(1.0, 0.62, 0.24),
		"radius": radius,
		"energy": energy,
	}


func _attach_light(
		anchor: Node2D,
		node_name: String,
		color: Color,
		radius: float,
		energy: float,
		shadows: bool) -> PointLight2D:
	var existing := anchor.get_node_or_null(NodePath(node_name))
	if existing is PointLight2D:
		return existing as PointLight2D
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
	light.height = maxf(radius * 0.52, 34.0)
	light.color = color
	light.energy = energy
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
	var max_distance := center.length()
	for y in LIGHT_TEXTURE_SIZE:
		for x in LIGHT_TEXTURE_SIZE:
			var distance := Vector2(x, y).distance_to(center) / max_distance
			var falloff := pow(clampf(1.0 - distance, 0.0, 1.0), 1.65)
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
	# CollisionShape2D children authored directly under StaticBody2D cover the
	# project's runtime obstacles and world bounds. Their local transform is
	# copied so rotation/scale/offset remain pixel-perfect with physics.
	for child in body.get_children():
		if not (child is CollisionShape2D):
			continue
		var collision := child as CollisionShape2D
		if collision.disabled or collision.shape == null:
			continue
		var points := _occluder_points(collision.shape)
		if points.is_empty():
			continue
		var occluder_name := OCCLUDER_PREFIX + str(collision.get_index())
		var existing := body.get_node_or_null(NodePath(occluder_name))
		if existing is LightOccluder2D:
			_occluder_count += 1
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
	return PackedVector2Array()
