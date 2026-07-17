class_name DirectionalAnimation
extends RefCounted
## Shared four-direction animation policy.
##
## Direction changes use axis hysteresis so a near-diagonal input cannot flap
## between two rows every frame. SpriteFrames resources also carry their own
## registration metadata; applying it here keeps the character's planted foot
## on the CharacterBody2D origin when source crops have different dimensions.

const DIRECTIONS: PackedStringArray = ["down", "up", "left", "right"]
const STATES: PackedStringArray = ["idle", "walk", "attack", "hit", "death"]


static func select_direction(
		motion: Vector2,
		current: String = "down",
		hysteresis: float = 0.18,
		deadzone: float = 0.01,
	) -> String:
	if motion.length_squared() <= deadzone * deadzone:
		return current if current in DIRECTIONS else "down"

	var x := absf(motion.x)
	var y := absf(motion.y)
	var margin := 1.0 + maxf(hysteresis, 0.0)
	var horizontal := current == "left" or current == "right"
	if horizontal:
		if y > x * margin:
			return "down" if motion.y >= 0.0 else "up"
		return "right" if motion.x >= 0.0 else "left"
	if x > y * margin:
		return "right" if motion.x >= 0.0 else "left"
	return "down" if motion.y >= 0.0 else "up"


static func smooth_velocity(
		current: Vector2,
		target: Vector2,
		acceleration: float,
		deceleration: float,
		delta: float,
	) -> Vector2:
	var changing_direction := current.length_squared() > 0.01 \
		and target.length_squared() > 0.01 and current.dot(target) < 0.0
	var rate := deceleration if target.is_zero_approx() or changing_direction else acceleration
	return current.move_toward(target, maxf(rate, 0.0) * maxf(delta, 0.0))


static func animation_name(state: String, face: String) -> StringName:
	var safe_state := state if state in STATES else "idle"
	var safe_face := face if face in DIRECTIONS else "down"
	return StringName(safe_state + "_" + safe_face)


static func animation_duration(
		frames: SpriteFrames,
		animation: StringName,
		speed_scale: float = 1.0,
	) -> float:
	if frames == null or not frames.has_animation(animation):
		return 0.0
	var speed := absf(frames.get_animation_speed(animation) * speed_scale)
	if speed <= 0.001:
		return 0.0
	var duration := 0.0
	for frame_index in frames.get_frame_count(animation):
		duration += frames.get_frame_duration(animation, frame_index) / speed
	return duration


static func play(
		sprite: AnimatedSprite2D,
		animation: StringName,
		preserve_phase: bool = false,
	) -> bool:
	if sprite == null or sprite.sprite_frames == null \
			or not sprite.sprite_frames.has_animation(animation):
		return false
	if sprite.animation == animation and sprite.is_playing():
		apply_registration(sprite)
		return true

	var old_count := sprite.sprite_frames.get_frame_count(sprite.animation) \
		if sprite.sprite_frames.has_animation(sprite.animation) else 0
	var old_phase := float(sprite.frame) / float(maxi(old_count, 1))
	sprite.play(animation)
	if preserve_phase:
		var new_count := sprite.sprite_frames.get_frame_count(animation)
		sprite.frame = clampi(floori(old_phase * float(new_count)), 0, maxi(new_count - 1, 0))
	apply_registration(sprite)
	return true


static func apply_registration(sprite: AnimatedSprite2D) -> void:
	if sprite == null or sprite.sprite_frames == null:
		return
	var frames := sprite.sprite_frames
	var animation_key := String(sprite.animation)
	var offset := sprite.offset
	var registration: Variant = frames.get_meta(&"registration") \
		if frames.has_meta(&"registration") else null
	if registration is Dictionary:
		var data := registration as Dictionary
		offset = _as_vector2(data.get("default_offset", offset), offset)
		var animation_offsets: Variant = data.get("animation_offsets", {})
		if animation_offsets is Dictionary and animation_offsets.has(animation_key):
			offset = _as_vector2(animation_offsets[animation_key], offset)
		else:
			var parts := animation_key.split("_", false, 1)
			if parts.size() == 2:
				var state_offsets: Variant = data.get("state_offsets", {})
				var direction_offsets: Variant = data.get("direction_offsets", {})
				if state_offsets is Dictionary:
					offset += _as_vector2(state_offsets.get(parts[0], Vector2.ZERO), Vector2.ZERO)
				if direction_offsets is Dictionary:
					offset += _as_vector2(direction_offsets.get(parts[1], Vector2.ZERO), Vector2.ZERO)

		var frame_offsets: Variant = data.get("frame_offsets", {})
		if frame_offsets is Dictionary and frame_offsets.has(animation_key):
			var offsets: Variant = frame_offsets[animation_key]
			if offsets is Array and sprite.frame < offsets.size():
				offset += _as_vector2(offsets[sprite.frame], Vector2.ZERO)
			elif offsets is PackedVector2Array and sprite.frame < offsets.size():
				offset += offsets[sprite.frame]
	sprite.offset = offset


static func _as_vector2(value: Variant, fallback: Vector2) -> Vector2:
	return value as Vector2 if value is Vector2 else fallback
