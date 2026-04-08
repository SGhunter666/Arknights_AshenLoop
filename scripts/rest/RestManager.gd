class_name RestManager
extends RefCounted

const TUNE_LIBRARY = preload("res://scripts/core/tune_library.gd")

func recover() -> void:
	RunManager.heal(int(ceil(float(RunManager.max_hp) * 0.3)))

func tune_resonance() -> void:
	RunManager.add_tune("resonance_apply_plus_one")

func offered_tunes() -> Array[String]:
	var active_node: MapNodeModel = RunManager.current_node()
	var node_hash: int = active_node.id.hash() if active_node != null else 0
	var seed_value: int = RunManager.rng_seed + RunManager.current_floor * 211 + RunManager.deck.size() * 13 + node_hash
	return TUNE_LIBRARY.offer_tunes(seed_value, 3, RunManager.tunes)

func apply_tune(tune_id: String) -> bool:
	return RunManager.add_tune(tune_id)

func rewire(flag_id: String) -> void:
	RunManager.set_flag(flag_id, true)
