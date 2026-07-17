extends Node
## Adversarial sequence-break contract.
##
## The campaign's road gates must never open, and no ending must resolve, unless
## the full prerequisite chain is satisfied -- including when a forged choice
## index is passed straight into story completion. complete_game_smoke drives
## the happy path; this contract guards the negative space. Run with an isolated
## APPDATA directory:
## godot --headless --path <project> --scene res://tools/progression_gate_smoke.tscn

var _failures: Array[String] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_run")


func _run() -> void:
	_check_gates_stay_closed_when_unmet()
	_check_forged_choice_index_cannot_open_gates()
	_check_secret_ending_locked_on_clean_slate()
	_check_gate_opens_when_prerequisites_met()

	SaveManager.clear_run_state()

	if _failures.is_empty():
		print("PROGRESSION_GATE_SMOKE: PASS")
		get_tree().quit(0)
	else:
		for failure in _failures:
			push_error("PROGRESSION_GATE_SMOKE: " + failure)
		print("PROGRESSION_GATE_SMOKE: FAIL (%d)" % _failures.size())
		get_tree().quit(1)


## From a clean run, completing a gate story must not open the next area or
## resolve an ending, because none of the prerequisites are satisfied.
func _check_gates_stay_closed_when_unmet() -> void:
	SaveManager.clear_run_state()
	CampaignSystem.call("_complete_story", &"north_signal", 0)
	_check(not WorldState.has_flag(&"ashmere_opened"),
		"north signal cannot open Ashmere without the radio desk and rest")
	CampaignSystem.call("_complete_story", &"ashmere_gate", 0)
	_check(not WorldState.has_flag(&"broadcast_opened"),
		"Ashmere gate cannot open the Wrenfield road with its prerequisites unmet")
	CampaignSystem.call("_complete_story", &"broadcast_core_gate", 0)
	_check(not WorldState.has_flag(&"choir_opened"),
		"Tollard gate cannot open before the relays, boss, proof, policy and second route job")
	CampaignSystem.call("_complete_story", &"choir_final_console", 0)
	_check(not WorldState.has_flag(&"ending_complete"),
		"final console cannot resolve an ending before the Custodian is down")


## A forged or out-of-range choice index must not substitute for the missing
## prerequisites and force a gate open.
func _check_forged_choice_index_cannot_open_gates() -> void:
	SaveManager.clear_run_state()
	for forged in [-1, 1, 2, 99]:
		CampaignSystem.call("_complete_story", &"ashmere_gate", forged)
		CampaignSystem.call("_complete_story", &"broadcast_core_gate", forged)
		CampaignSystem.call("_complete_story", &"choir_final_console", forged)
	_check(not WorldState.has_flag(&"broadcast_opened"),
		"a forged choice index cannot open the Wrenfield road")
	_check(not WorldState.has_flag(&"choir_opened"),
		"a forged choice index cannot open Tollard")
	_check(not WorldState.has_flag(&"ending_complete"),
		"a forged choice index cannot resolve an ending")


func _check_secret_ending_locked_on_clean_slate() -> void:
	SaveManager.clear_run_state()
	_check(not bool(CampaignSystem.call("_secret_ending_unlocked")),
		"the secret ending stays locked on a clean run")


## Positive control: the first road gate must still open once its own
## prerequisites hold, so the negative checks above are not vacuously true.
func _check_gate_opens_when_prerequisites_met() -> void:
	SaveManager.clear_run_state()
	BaseUpgradeSystem.restore([&"radio_desk"])
	WorldState.set_flag(&"rested_after_radio")
	CampaignSystem.call("_complete_story", &"north_signal", 0)
	_check(WorldState.has_flag(&"ashmere_opened"),
		"north signal opens Ashmere once the radio desk is built and Ellie has rested")


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
