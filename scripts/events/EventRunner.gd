class_name EventRunner
extends RefCounted

func apply_event_option(option: Dictionary) -> void:
	for effect in option.get("effects", []):
		_apply_effect(effect)

func _apply_effect(effect: Dictionary) -> void:
	match String(effect.get("type", "")):
		"gain_gold":
			RunManager.add_gold(int(effect.get("amount", 0)))
		"lose_gold":
			RunManager.add_gold(-int(effect.get("amount", 0)))
		"lose_hp":
			RunManager.lose_hp(int(effect.get("amount", 0)))
		"heal":
			RunManager.heal(int(effect.get("amount", 0)))
		"add_card":
			RunManager.add_card(String(effect.get("card_id", "")))
		"remove_card":
			RunManager.remove_card(String(effect.get("card_id", "")))
		"add_module":
			RunManager.add_module(String(effect.get("module_id", "")))
		"set_flag":
			RunManager.set_flag(String(effect.get("flag", "")), true)
		"next_floor_enemy_hp":
			RunManager.set_flag("enemy_hp_bonus_%d" % RunManager.current_floor, int(effect.get("amount", 0)))
		_:
			push_warning("Unknown event effect: %s" % String(effect.get("type", "")))
