class_name BaseUpgradeData
extends Resource
## Data definition for one base upgrade (design bible §10.2).
##
## Authored as .tres in resources/upgrades/. Costs are materials; an
## optional required_echo_id ties the upgrade to a recovered memory --
## the bible's rule that memories unlock base upgrades (e.g. the Radio
## Desk needs a broadcast memory).

## Unique id, used by BaseUpgradeSystem to track built state.
@export var id: StringName

## Name shown in prompts and notices, e.g. "Radio Desk".
@export var title: String = ""

## What the upgrade does (shown when built).
@export_multiline var description: String = ""

## Material cost: item id -> amount (item ids from resources/items/).
@export var cost: Dictionary = {}

## Optional gate: a MemoryEchoData id that must be recovered first. Empty
## for no memory requirement.
@export var required_echo_id: StringName = &""
