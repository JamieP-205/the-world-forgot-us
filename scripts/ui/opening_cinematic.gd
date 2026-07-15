extends Control

signal finished

const BEATS := [
	{"stamp": "14 OCTOBER / 18 YEARS LATER", "title": "BLANK NIGHT ENDED. THE WARNING DID NOT.", "body": "The roads emptied. The network kept practising our voices.", "duration": 3.8},
	{"stamp": "CARRIAGE 317 / 02:16", "title": "ELLIE WAKES TO MAGGIE'S VOICE.", "body": "\"Fourteen B. You used to write it backwards.\"\nThe receiver on the table is unplugged.", "duration": 6.3},
	{"stamp": "A38 EVACUATION ROUTE / ARCHIVE IMAGE", "title": "ON BLANK NIGHT, EVERY SIGN CHANGED ITS MIND.", "body": "North. South. Shelter. Exchange. Thousands followed instructions that could not all be true.", "duration": 6.0},
	{"stamp": "FOUND BENEATH ELLIE'S BEDROLL", "title": "ELLIE - DO NOT ANSWER ME", "body": "A tape in Maggie Ward's handwriting. Recorded before Maggie disappeared.", "duration": 5.7},
	{"stamp": "TOLLARD EXCHANGE / 02:17", "title": "SOMETHING ON THE OLD CARRIER WAKES.", "body": "It knows the house number. It knows Maggie's voice. It has waited eighteen years to be heard.", "duration": 6.2},
	{"stamp": "CULLBROOK SERVICES / FIRST LIGHT", "title": "PROVE WHAT SPOKE.", "body": "Find the north-road tape. Compare the voice. Do not answer until you know.", "duration": 5.0},
]

@onready var _canvas = $Illustration
@onready var _stamp: Label = $TextPlate/Margin/Copy/Stamp
@onready var _title: Label = $TextPlate/Margin/Copy/Title
@onready var _body: Label = $TextPlate/Margin/Copy/Body
@onready var _progress: ProgressBar = $TextPlate/Margin/Copy/Footer/Progress
@onready var _next: Button = $TextPlate/Margin/Copy/Footer/Next

var _index := 0
var _elapsed := 0.0
var _running := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_next.pressed.connect(_advance)
	visible = false


func begin() -> void:
	if _running or WorldState.has_flag(&"intro_seen") or DisplayServer.get_name() == "headless":
		return
	_running = true
	_index = 0
	_elapsed = 0.0
	visible = true
	GameManager.set_dialogue_active(true)
	_show_beat()
	_next.grab_focus()
	AudioManager.play(&"radio_static", -2.0)


func _process(delta: float) -> void:
	if not _running:
		return
	_elapsed += delta
	var duration := float(BEATS[_index].duration)
	_progress.value = clampf(_elapsed / duration * 100.0, 0.0, 100.0)
	if _elapsed >= duration:
		_advance()


func _unhandled_input(event: InputEvent) -> void:
	if not _running:
		return
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_finish()
	elif event.is_action_pressed("interact") or event is InputEventKey and event.pressed and event.physical_keycode == KEY_SPACE:
		get_viewport().set_input_as_handled()
		_advance()


func _advance() -> void:
	if not _running:
		return
	_index += 1
	_elapsed = 0.0
	if _index >= BEATS.size():
		_finish()
		return
	_show_beat()
	AudioManager.play(&"radio_static", -8.0, 0.82 + _index * 0.035)


func _show_beat() -> void:
	var beat: Dictionary = BEATS[_index]
	_canvas.set_beat(_index)
	_stamp.text = String(beat.stamp)
	_title.text = String(beat.title)
	_body.text = String(beat.body)
	_progress.value = 0.0
	_next.text = "CONTINUE" if _index < BEATS.size() - 1 else "ENTER CULLBROOK"


func _finish() -> void:
	_running = false
	visible = false
	WorldState.set_flag(&"intro_seen")
	WorldState.set_flag(&"intro_pending", false)
	GameManager.set_dialogue_active(false)
	SaveManager.save_game("")
	AudioManager.play(&"objective")
	finished.emit()
