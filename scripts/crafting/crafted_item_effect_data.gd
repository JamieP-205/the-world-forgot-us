class_name CraftedItemEffectData
extends Resource
## Player-facing behaviour attached to one crafted output.

@export var item_id: StringName = &""
@export var effect_kind: StringName = &""
@export var action_label := "USE"
@export_multiline var use_summary := ""
@export_multiline var consequence := ""
@export var consumes_on_use := true
@export_range(0.0, 300.0, 0.1) var cooldown_seconds := 0.0

## Contextual tools discover nearby nodes through this group. Compatible
## targets implement can_apply_crafted_item() and apply_crafted_item().
@export var target_group: StringName = &""
@export var target_prompt := ""

## Effect-specific, numeric tuning data such as heal, radius and duration.
@export var values: Dictionary = {}
