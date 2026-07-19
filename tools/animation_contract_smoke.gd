extends Node
## Headless validation for the directional sprite/runtime contract.

const DIRECTIONS := ["down", "up", "left", "right"]
const STATES := ["idle", "walk", "attack", "hit", "death"]
const ENEMY_RESOURCES := {
	"hollow": "res://resources/spriteframes/enemy_hollow_directional_spriteframes.tres",
	"mimic_stalker": "res://resources/spriteframes/enemy_mimic_stalker_directional_spriteframes.tres",
	"relay_husk": "res://resources/spriteframes/enemy_relay_husk_directional_spriteframes.tres",
	"signal_leech": "res://resources/spriteframes/enemy_signal_leech_directional_spriteframes.tres",
	"static_wraith": "res://resources/spriteframes/enemy_static_wraith_directional_spriteframes.tres",
	"choir_warden": "res://resources/spriteframes/enemy_choir_warden_directional_spriteframes.tres",
}
const ENEMY_SCENES := {
	"hollow": "res://scenes/enemies/enemy_hollow.tscn",
	"mimic_stalker": "res://scenes/enemies/enemy_mimic_stalker.tscn",
	"relay_husk": "res://scenes/enemies/enemy_relay_husk.tscn",
	"signal_leech": "res://scenes/enemies/enemy_signal_leech.tscn",
	"static_wraith": "res://scenes/enemies/enemy_static_wraith.tscn",
}

var _failures: Array[String] = []
var _checks := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_direction_policy()
	_check_enemy_resources()
	_check_player_resources()
	_check_scene_ownership()
	_check_registration_runtime()
	await get_tree().process_frame
	if _failures.is_empty():
		print("ANIMATION CONTRACT PASS (%d checks)" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures:
		push_error("ANIMATION CONTRACT: " + failure)
	print("ANIMATION CONTRACT FAIL (%d failures / %d checks)" % [_failures.size(), _checks])
	get_tree().quit(1)


func _check_direction_policy() -> void:
	_check(DirectionalAnimation.select_direction(Vector2(1.0, 0.98), "right", 0.18) == "right",
		"near diagonal retains horizontal facing")
	_check(DirectionalAnimation.select_direction(Vector2(0.98, 1.0), "down", 0.18) == "down",
		"near diagonal retains vertical facing")
	_check(DirectionalAnimation.select_direction(Vector2(0.4, -1.0), "right", 0.18) == "up",
		"dominant vertical input crosses hysteresis")
	_check(DirectionalAnimation.select_direction(Vector2(-1.0, 0.4), "down", 0.18) == "left",
		"dominant horizontal input crosses hysteresis")
	var accelerated := DirectionalAnimation.smooth_velocity(
		Vector2.ZERO, Vector2(220.0, 0.0), 1100.0, 1600.0, 1.0 / 60.0)
	_check(accelerated.x > 0.0 and accelerated.x < 220.0,
		"movement accelerates instead of snapping to maximum speed")
	var decelerated := DirectionalAnimation.smooth_velocity(
		Vector2(80.0, 0.0), Vector2.ZERO, 1100.0, 1600.0, 1.0 / 60.0)
	_check(decelerated.x > 0.0 and decelerated.x < 80.0,
		"movement decelerates instead of snapping to rest")


func _check_enemy_resources() -> void:
	var owners: Dictionary = {}
	var resource_ids: Dictionary = {}
	var timing_signatures: Dictionary = {}
	var walk_atlases: Dictionary = {}
	for expected_owner in ENEMY_RESOURCES:
		var path: String = ENEMY_RESOURCES[expected_owner]
		var frames := load(path) as SpriteFrames
		_check(frames != null, "%s SpriteFrames loads" % expected_owner)
		if frames == null:
			continue
		var owner := String(frames.get_meta(&"animation_owner", ""))
		_check(owner == expected_owner, "%s owns its SpriteFrames resource" % expected_owner)
		_check(not owners.has(owner), "%s animation owner is unique" % expected_owner)
		owners[owner] = true
		_check(not resource_ids.has(frames.get_instance_id()),
			"%s does not share a loaded SpriteFrames object" % expected_owner)
		resource_ids[frames.get_instance_id()] = true
		_check_registration_metadata(frames, expected_owner, STATES)
		_check_replacement_contract(frames, expected_owner, STATES)
		for state in STATES:
			for direction in DIRECTIONS:
				_check_animation(frames, state + "_" + direction, 4 if state == "walk" else 2, expected_owner)
		_check(String(frames.get_meta(&"source_status", "")) == "production_four_direction_walk_atlas",
			"%s has replaced its temporary directional walk source" % expected_owner)
		var atlas_path := String(frames.get_meta(&"walk_atlas", ""))
		_check(not atlas_path.is_empty(), "%s declares its installed walk atlas" % expected_owner)
		_check(not walk_atlases.has(atlas_path), "%s owns a distinct walk atlas" % expected_owner)
		walk_atlases[atlas_path] = true
		_check_walk_atlas(atlas_path, expected_owner)
		var timing: Variant = frames.get_meta(&"timing_profile", {})
		_check(timing is Dictionary and timing.size() == STATES.size(),
			"%s declares all state timings" % expected_owner)
		var signature := str(timing)
		_check(not timing_signatures.has(signature),
			"%s has a species-specific timing profile" % expected_owner)
		timing_signatures[signature] = true
		_check(frames.has_meta(&"silhouette_modulate"),
			"%s declares silhouette modulation" % expected_owner)
	_check(owners.size() == ENEMY_RESOURCES.size(), "all enemy animation owners are distinct")
	_check(walk_atlases.size() == ENEMY_RESOURCES.size(), "all enemy walk atlases are distinct")


func _check_walk_atlas(path: String, label: String) -> void:
	var texture := load(path) as Texture2D
	_check(texture != null, "%s walk atlas loads" % label)
	if texture == null:
		return
	_check(texture.get_width() == 1254 and texture.get_height() == 1254,
		"%s walk atlas keeps the registered 4x4 dimensions" % label)
	var image := texture.get_image()
	_check(image != null and not image.is_empty(), "%s walk atlas exposes image data" % label)
	if image != null and not image.is_empty():
		_check(image.get_pixel(5, 5).a <= 0.01,
			"%s walk atlas has genuine transparent padding" % label)


func _check_player_resources() -> void:
	var action_frames := load(
		"res://resources/spriteframes/player_painted_spriteframes.tres") as SpriteFrames
	var walk_frames := load(
		"res://resources/spriteframes/player_walk_v2_spriteframes.tres") as SpriteFrames
	_check(action_frames != null, "player action SpriteFrames loads")
	_check(walk_frames != null, "player walk SpriteFrames loads")
	if action_frames == null or walk_frames == null:
		return
	_check(action_frames != walk_frames, "player action and walk resources have unique ownership")
	_check_registration_metadata(action_frames, "player_actions", ["idle", "attack", "hit", "death"])
	_check_registration_metadata(walk_frames, "player_walk", ["walk"])
	for direction in DIRECTIONS:
		_check_animation(action_frames, "idle_" + direction, 1, "player")
		_check_animation(action_frames, "attack_" + direction, 1, "player")
		_check_animation(action_frames, "hit_" + direction, 1, "player")
		_check_animation(action_frames, "death_" + direction, 2, "player")
		_check_animation(walk_frames, "walk_" + direction, 4, "player")


func _check_scene_ownership() -> void:
	for expected_owner in ENEMY_SCENES:
		var packed := load(ENEMY_SCENES[expected_owner]) as PackedScene
		_check(packed != null, "%s scene loads" % expected_owner)
		if packed == null:
			continue
		var enemy := packed.instantiate()
		enemy.name = "AnimationContract_" + expected_owner
		enemy.set("persistent_id", StringName("animation_contract_" + expected_owner))
		add_child(enemy)
		var visual := enemy.get_node_or_null("Visual") as AnimatedSprite2D
		_check(visual != null, "%s scene exposes Visual" % expected_owner)
		if visual != null:
			_check(String(visual.sprite_frames.get_meta(&"animation_owner", "")) == expected_owner,
				"%s scene is wired to its own resource" % expected_owner)
			_check(float(enemy.get("facing_hysteresis")) > 0.0,
				"%s controller exposes facing hysteresis" % expected_owner)
		enemy.queue_free()

	var relay_scene := load(ENEMY_SCENES["relay_husk"]) as PackedScene
	var choir := relay_scene.instantiate()
	choir.name = "ChoirWarden"
	choir.set("persistent_id", &"animation_contract_choir_warden")
	add_child(choir)
	var choir_visual := choir.get_node("Visual") as AnimatedSprite2D
	_check(String(choir_visual.sprite_frames.get_meta(&"animation_owner", "")) == "choir_warden",
		"Choir Warden runtime identity selects its unique resource")
	choir.queue_free()

	var player_scene := load("res://scenes/player/player.tscn") as PackedScene
	var player := player_scene.instantiate()
	player.name = "AnimationContractPlayer"
	add_child(player)
	var player_visual := player.get_node("Visual") as AnimatedSprite2D
	var player_walk := player.get_node("WalkVisual") as AnimatedSprite2D
	_check(player_visual.sprite_frames != player_walk.sprite_frames,
		"player action and locomotion nodes do not share SpriteFrames")
	_check(float(player.get("movement_acceleration")) > player.move_speed,
		"player controller exposes tuned acceleration")
	_check(float(player.get("movement_deceleration")) > player.move_speed,
		"player controller exposes tuned deceleration")
	for direction in DIRECTIONS:
		player.set("_face", direction)
		player.call("_update_locomotion", true)
		_check(player_walk.visible and is_equal_approx(player_walk.self_modulate.a, 1.0),
			"player remains fully visible while walking %s" % direction)
		_check(not player_visual.visible and is_equal_approx(player_visual.self_modulate.a, 1.0),
			"action sheet resets cleanly while walking %s" % direction)
		_check(player_walk.animation == StringName("walk_" + direction),
			"walking %s selects the matching row" % direction)
		player.call("_update_locomotion", false)
		_check(player_visual.visible and is_equal_approx(player_visual.self_modulate.a, 1.0),
			"player remains fully visible when stopping from %s" % direction)
		_check(not player_walk.visible and is_equal_approx(player_walk.self_modulate.a, 1.0),
			"walk sheet resets cleanly when stopping from %s" % direction)
		_check(player_visual.animation == StringName("idle_" + direction),
			"idle after %s keeps the matching facing" % direction)
	player.queue_free()


func _check_registration_runtime() -> void:
	var sprite := AnimatedSprite2D.new()
	add_child(sprite)
	sprite.sprite_frames = load(
		"res://resources/spriteframes/player_walk_v2_spriteframes.tres") as SpriteFrames
	DirectionalAnimation.play(sprite, &"walk_right")
	sprite.frame = 3
	DirectionalAnimation.apply_registration(sprite)
	_check(sprite.offset.is_equal_approx(Vector2(65.5, -18.5)),
		"right walk final frame receives measured foot registration")
	DirectionalAnimation.play(sprite, &"walk_down", true)
	_check(sprite.frame == 3, "direction change preserves walk-cycle phase")
	DirectionalAnimation.apply_registration(sprite)
	_check(sprite.offset.is_equal_approx(Vector2(52.5, -74.0)),
		"down walk phase uses its own frame registration")

	sprite.sprite_frames = load(
		"res://resources/spriteframes/player_painted_spriteframes.tres") as SpriteFrames
	DirectionalAnimation.play(sprite, &"death_up")
	sprite.frame = 1
	DirectionalAnimation.apply_registration(sprite)
	_check(sprite.offset.is_equal_approx(Vector2(0.0, -161.0)),
		"player death frames retain the same planted-foot height")
	sprite.queue_free()


func _check_registration_metadata(
		frames: SpriteFrames,
		label: String,
		required_states: Array,
	) -> void:
	var pivot: Variant = frames.get_meta(&"foot_pivot_normalized", null)
	_check(pivot is Vector2, "%s declares a normalized foot pivot" % label)
	if pivot is Vector2:
		_check(pivot.x >= 0.0 and pivot.x <= 1.0 and pivot.y >= 0.75 and pivot.y <= 1.0,
			"%s foot pivot is in a plausible lower-silhouette range" % label)
	var registration: Variant = frames.get_meta(&"registration", null)
	_check(registration is Dictionary, "%s declares registration metadata" % label)
	if not registration is Dictionary:
		return
	_check(String(registration.get("anchor_space", "")) == "texture_pixels",
		"%s registration uses explicit texture-pixel space" % label)
	_check(registration.get("default_offset", null) is Vector2,
		"%s registration declares a default offset" % label)
	var directions: Variant = registration.get("direction_offsets", {})
	for direction in DIRECTIONS:
		_check(directions is Dictionary and directions.has(direction),
			"%s registers %s facing" % [label, direction])
	var state_offsets: Variant = registration.get("state_offsets", {})
	var animation_offsets: Variant = registration.get("animation_offsets", {})
	for state in required_states:
		var state_registered: bool = state_offsets is Dictionary and state_offsets.has(state)
		if not state_registered and animation_offsets is Dictionary:
			state_registered = animation_offsets.has(state + "_down")
		_check(state_registered, "%s registers %s state" % [label, state])


func _check_replacement_contract(
		frames: SpriteFrames,
		label: String,
		required_states: Array,
	) -> void:
	var contract: Variant = frames.get_meta(&"replacement_sheet_contract", null)
	_check(contract is Dictionary, "%s declares a replacement-sheet contract" % label)
	if not contract is Dictionary:
		return
	_check(contract.get("cell_size", Vector2i.ZERO) is Vector2i \
			and contract.get("cell_size", Vector2i.ZERO) != Vector2i.ZERO,
		"%s declares replacement cell size" % label)
	var directions: Variant = contract.get("directions", PackedStringArray())
	var states: Variant = contract.get("states", PackedStringArray())
	for direction in DIRECTIONS:
		_check(direction in directions, "%s replacement contract includes %s" % [label, direction])
	for state in required_states:
		_check(state in states, "%s replacement contract includes %s" % [label, state])
	_check(not String(contract.get("silhouette", "")).is_empty(),
		"%s replacement contract defines silhouette intent" % label)


func _check_animation(
		frames: SpriteFrames,
		animation: String,
		minimum_frames: int,
		label: String,
	) -> void:
	var key := StringName(animation)
	_check(frames.has_animation(key), "%s has %s" % [label, animation])
	if not frames.has_animation(key):
		return
	var count := frames.get_frame_count(key)
	_check(count >= minimum_frames,
		"%s %s has at least %d frame(s)" % [label, animation, minimum_frames])
	var speed := frames.get_animation_speed(key)
	_check(speed > 0.0 and not is_nan(speed) and not is_inf(speed),
		"%s %s has finite positive speed" % [label, animation])
	for frame_index in count:
		var duration := frames.get_frame_duration(key, frame_index)
		_check(duration > 0.0 and not is_nan(duration) and not is_inf(duration),
			"%s %s frame %d has finite positive duration" % [label, animation, frame_index])
		_check(frames.get_frame_texture(key, frame_index) != null,
			"%s %s frame %d has a texture" % [label, animation, frame_index])
	var seconds := DirectionalAnimation.animation_duration(frames, key)
	_check(seconds >= 0.05 and seconds <= 3.0,
		"%s %s duration is bounded" % [label, animation])


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
