class_name RestManager
extends RefCounted

func recover() -> void:
	RunManager.heal(int(ceil(float(RunManager.max_hp) * 0.3)))

func tune_resonance() -> void:
	RunManager.set_flag("tune_resonance_apply", true)

func rewire(flag_id: String) -> void:
	RunManager.set_flag(flag_id, true)

