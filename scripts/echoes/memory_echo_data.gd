class_name MemoryEchoData
extends Resource
## Authored evidence carried by an ordinary physical trace anchor.
##
## The anchor object, receiver signature, contradiction, and filing test live
## with the record so every trace follows the same Detect > Focus > Reveal >
## Verify/File interaction without falling back to a generic collectible prop.

## Unique id, used by the ArchiveSystem to de-duplicate.
@export var id: StringName

## Short name shown in prompts and the archive, e.g. "The Last Broadcast".
@export var title: String = ""

## Archive category: People / Places / Objects / Broadcasts / Factions /
## Personal Memories / Unresolved Echoes.
@export var category: String = "Places"

## Memory quality: Static / Fragment / Clear Echo / Restored Memory.
@export var quality: String = "Clear Echo"

## Ordinary object shown in the world. The afterimage may be a separately
## authored spatial residue; when omitted the object itself is offset and
## ghosted without any synthetic collectible symbol.
@export var artifact_texture: Texture2D
@export var afterimage_texture: Texture2D
@export var artifact_name: String = "Unlabelled object"
@export var artifact_semantics: StringName = &"unlabelled_object"

## Receiver-facing evidence contract.
@export_enum("physical", "witness", "system") var evidence_class: String = "physical"
@export_range(0, 100, 1) var confidence: int = 50
@export var signal_profile: String = "broadband residue"
@export_multiline var observation_text: String = "No stable observation recorded."
@export_multiline var contradiction_text: String = "No contradiction logged."
@export_multiline var verification_text: String = "Cross-check against a second source before filing."
@export_multiline var feed_warning: String = "Feeding this trace gives the copied voice another private pattern."

## Teaser shown the moment the scanner reveals the echo.
@export_multiline var hint: String = "A memory stirs here."

## The memory itself, shown when the echo is recovered.
@export_multiline var memory_text: String = ""

## Optional item id (see resources/items/) granted on recovery. Empty for
## none. This is where the keepsake / "meaningful junk" tie-in lives.
@export var keepsake_item: StringName = &""


func confidence_label() -> String:
	if confidence >= 85:
		return "CORROBORATED"
	if confidence >= 65:
		return "SUPPORTED"
	if confidence >= 40:
		return "CONTESTED"
	return "UNSTABLE"


func evidence_label() -> String:
	return "%s EVIDENCE  /  %s %d%%" % [
		evidence_class.to_upper(), confidence_label(), confidence]


func has_complete_trace_contract() -> bool:
	return (
		id != &""
		and artifact_texture != null
		and not artifact_name.strip_edges().is_empty()
		and artifact_semantics != &""
		and evidence_class in ["physical", "witness", "system"]
		and not signal_profile.strip_edges().is_empty()
		and not observation_text.strip_edges().is_empty()
		and not contradiction_text.strip_edges().is_empty()
		and not verification_text.strip_edges().is_empty()
		and not feed_warning.strip_edges().is_empty()
	)
