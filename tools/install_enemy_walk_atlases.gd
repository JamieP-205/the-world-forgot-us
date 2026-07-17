extends SceneTree
## Installs the production four-direction walk atlases without touching each
## enemy's authored combat timing or state-machine code.

const EDGES := [0, 313, 627, 940, 1254]
const DIRECTIONS := [&"down", &"up", &"left", &"right"]
const SPECS := [
	[&"hollow", "res://resources/spriteframes/enemy_hollow_directional_spriteframes.tres", "res://assets/processed/enemy_walk_rebuild/hollow_walk_4dir.png"],
	[&"mimic_stalker", "res://resources/spriteframes/enemy_mimic_stalker_directional_spriteframes.tres", "res://assets/processed/enemy_walk_rebuild/mimic_stalker_walk_4dir.png"],
	[&"signal_leech", "res://resources/spriteframes/enemy_signal_leech_directional_spriteframes.tres", "res://assets/processed/enemy_walk_rebuild/signal_leech_walk_4dir.png"],
	[&"relay_husk", "res://resources/spriteframes/enemy_relay_husk_directional_spriteframes.tres", "res://assets/processed/enemy_walk_rebuild/relay_husk_walk_4dir.png"],
	[&"static_wraith", "res://resources/spriteframes/enemy_static_wraith_directional_spriteframes.tres", "res://assets/processed/enemy_walk_rebuild/static_wraith_walk_4dir.png"],
	[&"choir_warden", "res://resources/spriteframes/enemy_choir_warden_directional_spriteframes.tres", "res://assets/processed/enemy_walk_rebuild/choir_warden_walk_4dir.png"],
]


func _init() -> void:
	var failed := false
	for raw_spec in SPECS:
		failed = not _install(raw_spec) or failed
	quit(1 if failed else 0)


func _install(spec: Array) -> bool:
	var owner: StringName = spec[0]
	var resource_path: String = spec[1]
	var texture_path: String = spec[2]
	var frames := load(resource_path) as SpriteFrames
	var atlas := load(texture_path) as Texture2D
	if frames == null or atlas == null:
		push_error("Walk atlas install failed for %s: missing resource or texture." % owner)
		return false
	if atlas.get_width() != 1254 or atlas.get_height() != 1254:
		push_error("Walk atlas install failed for %s: expected 1254x1254, got %dx%d." % [
			owner, atlas.get_width(), atlas.get_height()])
		return false

	for row in range(DIRECTIONS.size()):
		var direction: StringName = DIRECTIONS[row]
		var idle_name := StringName("idle_%s" % direction)
		var walk_name := StringName("walk_%s" % direction)
		var idle_speed := frames.get_animation_speed(idle_name) if frames.has_animation(idle_name) else 2.4
		var walk_speed := frames.get_animation_speed(walk_name) if frames.has_animation(walk_name) else 5.0
		_replace_animation(frames, idle_name, atlas, row, 1, idle_speed)
		# Two identical idle frames preserve the shared animation contract while
		# avoiding a false shuffle when the enemy is standing still.
		frames.add_frame(idle_name, _cell(atlas, row, 0))
		_replace_animation(frames, walk_name, atlas, row, 4, walk_speed)

	frames.set_meta(&"source_status", "production_four_direction_walk_atlas")
	frames.set_meta(&"walk_atlas", texture_path)
	frames.set_meta(&"walk_atlas_grid", Vector2i(4, 4))
	var error := ResourceSaver.save(frames, resource_path)
	if error != OK:
		push_error("Walk atlas save failed for %s: %s" % [owner, error_string(error)])
		return false
	print("WALK ATLAS INSTALLED: %s" % owner)
	return true


func _replace_animation(
		frames: SpriteFrames,
		animation: StringName,
		atlas: Texture2D,
		row: int,
		columns: int,
		speed: float
) -> void:
	if frames.has_animation(animation):
		frames.remove_animation(animation)
	frames.add_animation(animation)
	frames.set_animation_loop(animation, true)
	frames.set_animation_speed(animation, speed)
	for column in range(columns):
		frames.add_frame(animation, _cell(atlas, row, column))


func _cell(atlas: Texture2D, row: int, column: int) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = atlas
	texture.region = Rect2(
		EDGES[column], EDGES[row],
		EDGES[column + 1] - EDGES[column],
		EDGES[row + 1] - EDGES[row]
	)
	return texture
