extends Node
## Visual proof that the production runtime selects four distinct player walk
## rows and that enemies keep their own silhouette for locomotion and hit.

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const OUTPUT := "res://builds/visual_qa/animation/directional.png"
const DIRECTIONS := ["down", "up", "left", "right"]
const ENEMIES := [
	["Hollow", "res://scenes/enemies/enemy_hollow.tscn"],
	["Mimic Stalker", "res://scenes/enemies/enemy_mimic_stalker.tscn"],
	["Signal Leech", "res://scenes/enemies/enemy_signal_leech.tscn"],
]


func _ready() -> void:
	call_deferred("_capture")


func _capture() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(
		"res://builds/visual_qa/animation"))
	var viewport := SubViewport.new()
	viewport.size = Vector2i(960, 650)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	add_child(viewport)

	var background := ColorRect.new()
	background.color = Color(0.035, 0.04, 0.038, 1.0)
	background.size = viewport.size
	viewport.add_child(background)

	for index in DIRECTIONS.size():
		var player := PLAYER_SCENE.instantiate() as Player
		player.position = Vector2(150 + index * 220, 190)
		viewport.add_child(player)
		var camera := player.get_node_or_null("Camera2D") as Camera2D
		if camera != null:
			camera.enabled = false
		player.set("_face", DIRECTIONS[index])
		player.call("_update_locomotion", true)
		var walk := player.get_node("WalkVisual") as AnimatedSprite2D
		walk.pause()
		walk.frame = 1
		DirectionalAnimation.apply_registration(walk)
		_add_label(viewport, DIRECTIONS[index].capitalize(), Vector2(116 + index * 220, 242))

	for enemy_index in ENEMIES.size():
		var enemy_brief := ENEMIES[enemy_index] as Array
		var packed := load(String(enemy_brief[1])) as PackedScene
		for state_index in 3:
			var enemy := packed.instantiate()
			enemy.set("persistent_id", StringName("visual_%d_%d" % [enemy_index, state_index]))
			enemy.position = Vector2(150 + state_index * 300, 350 + enemy_index * 92)
			viewport.add_child(enemy)
			enemy.process_mode = Node.PROCESS_MODE_DISABLED
			var visual := enemy.get_node("Visual") as AnimatedSprite2D
			var animation: String = ["walk_down", "attack_down", "hit_down"][state_index]
			DirectionalAnimation.play(visual, StringName(animation))
			visual.pause()
			visual.frame = mini(1, visual.sprite_frames.get_frame_count(animation) - 1)
			DirectionalAnimation.apply_registration(visual)
			_add_label(
				viewport,
				"%s / %s" % [String(enemy_brief[0]), ["walk", "attack", "hit"][state_index]],
				Vector2(72 + state_index * 300, 392 + enemy_index * 92))

	for frame in 4:
		await get_tree().process_frame
	RenderingServer.force_draw(false)
	var image := viewport.get_texture().get_image()
	if image == null or image.save_png(ProjectSettings.globalize_path(OUTPUT)) != OK:
		push_error("DIRECTIONAL VISUAL CAPTURE: FAIL")
		get_tree().quit(1)
		return
	print("DIRECTIONAL VISUAL CAPTURE: PASS")
	get_tree().quit(0)


func _add_label(viewport: SubViewport, copy: String, position_value: Vector2) -> void:
	var label := Label.new()
	label.position = position_value
	label.text = copy
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color(0.74, 0.76, 0.69))
	viewport.add_child(label)
