extends SceneTree
## Build the legacy fixture SpriteFrames resources for the player and Hollow from
## the top-down sheets in assets/processed/{player,hollow}_topdown/.
##
## Run headless:
##   Godot_v4.7 --headless --path <project> -s res://tools/build_spriteframes.gd
##
## Canonical rows: 0=down, 1=up, 2=left, 3=right. Cell 96x96. Regenerate any time
## the sheets change; this is a build tool, not shipped code.

const CELL := 96
const ROWS := {"down": 0, "up": 1, "left": 2, "right": 3}
const OUT_DIR := "res://resources/spriteframes"

# anim -> [sheet path, columns, loop, fps]
const PLAYER := {
	"idle":   ["res://assets/processed/player_topdown/player_idle.png", 4, true, 4.0],
	"walk":   ["res://assets/processed/player_topdown/player_walk.png", 6, true, 10.0],
	"attack": ["res://assets/processed/player_topdown/player_attack.png", 4, false, 14.0],
	"hurt":   ["res://assets/processed/player_topdown/player_hurt.png", 2, false, 8.0],
}
const HOLLOW := {
	"idle":   ["res://assets/processed/hollow_topdown/hollow_idle.png", 4, true, 3.0],
	"walk":   ["res://assets/processed/hollow_topdown/hollow_walk.png", 6, true, 8.0],
	"attack": ["res://assets/processed/hollow_topdown/hollow_attack.png", 4, false, 10.0],
	"hit":    ["res://assets/processed/hollow_topdown/hollow_hit.png", 2, false, 10.0],
	"death":  ["res://assets/processed/hollow_topdown/hollow_death.png", 6, false, 10.0],
}


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	_build(PLAYER, OUT_DIR + "/player_placeholder_spriteframes.tres")
	_build(HOLLOW, OUT_DIR + "/hollow_placeholder_spriteframes.tres")
	quit()


func _build(config: Dictionary, out_path: String) -> void:
	var sf := SpriteFrames.new()
	# Start clean: drop the implicit "default" animation.
	if sf.has_animation(&"default"):
		sf.remove_animation(&"default")

	for anim in config:
		var sheet_path: String = config[anim][0]
		var cols: int = config[anim][1]
		var loop: bool = config[anim][2]
		var fps: float = config[anim][3]
		var tex: Texture2D = load(sheet_path)
		if tex == null:
			push_error("Missing sheet: %s" % sheet_path)
			continue
		for dir in ROWS:
			var row: int = ROWS[dir]
			var name := StringName("%s_%s" % [anim, dir])
			sf.add_animation(name)
			sf.set_animation_loop(name, loop)
			sf.set_animation_speed(name, fps)
			for col in range(cols):
				var at := AtlasTexture.new()
				at.atlas = tex
				at.region = Rect2(col * CELL, row * CELL, CELL, CELL)
				sf.add_frame(name, at)

	var err := ResourceSaver.save(sf, out_path)
	if err == OK:
		print("wrote %s  (%d animations)" % [out_path, sf.get_animation_names().size()])
	else:
		push_error("save failed (%d): %s" % [err, out_path])
