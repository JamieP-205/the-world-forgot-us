class_name QuestData
extends Resource
## Small authored contract shared by NPCs, campaign copy, and smoke tests.
## Runtime progress remains in WorldState so saves stay JSON-safe.

@export var id: StringName = &""
@export var title: String = "Field task"
@export var objective_verb: String = "Investigate"
@export var location: String = "Unknown"
@export_multiline var stakes: String = ""
@export var reward_summary: String = ""
