extends Node

const REST_SEQUENCE := preload("res://scenes/ui/rest_sequence.tscn")


func _ready() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var sequence := REST_SEQUENCE.instantiate() as RestSequence
	get_tree().root.add_child(sequence)
	sequence.begin(true)
	await get_tree().create_timer(1.55, true, false, true).timeout
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var output := ProjectSettings.globalize_path(
		"res://builds/visual_qa/ui/rest_decode.png")
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	image.save_png(output)
	print("REST_SEQUENCE_VISUAL_CAPTURE: %s" % output)
	get_tree().quit(0)
