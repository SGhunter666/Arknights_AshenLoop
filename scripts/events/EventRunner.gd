class_name EventRunner
extends RefCounted

func apply_event_option(option: Dictionary) -> void:
	for effect in option.get("effects", []):
		_apply_effect(effect)

func _apply_effect(effect: Dictionary) -> void:
	match String(effect.get("type", "")):
		"gain_gold", "add_gold":
			RunManager.add_gold(int(effect.get("amount", 0)))
		"lose_gold":
			RunManager.add_gold(-int(effect.get("amount", 0)))
		"lose_hp":
			RunManager.lose_hp(int(effect.get("amount", 0)))
		"heal":
			RunManager.heal(int(effect.get("amount", 0)))
		"heal_percent":
			RunManager.heal(int(ceil(float(RunManager.max_hp) * float(effect.get("amount", 0)) / 100.0)))
		"add_card":
			_add_card_if_known(String(effect.get("card_id", "")))
		"add_card_reward":
			_add_card_if_known(String(effect.get("card_id", "")))
		"remove_card", "remove_selected_card":
			var card_id: String = String(effect.get("card_id", ""))
			if card_id.is_empty() and not RunManager.deck.is_empty():
				card_id = RunManager.deck[0]
			RunManager.remove_card(card_id)
		"upgrade_random_card", "upgrade_selected_card":
			_upgrade_first_available_card()
		"add_module":
			RunManager.add_module(String(effect.get("module_id", "")))
		"add_charm":
			RunManager.add_charm(String(effect.get("charm_id", "")))
		"set_flag", "gain_story_flag":
			RunManager.set_flag(String(effect.get("flag", "")), true)
		"apply_run_modifier":
			RunManager.set_flag(String(effect.get("modifier_id", "")), true)
		"next_floor_enemy_hp":
			RunManager.set_flag("enemy_hp_bonus_%d" % RunManager.current_floor, int(effect.get("amount", 0)))
		_:
			push_warning("Unknown event effect: %s" % String(effect.get("type", "")))

func _add_card_if_known(card_id: String) -> void:
	if card_id.is_empty():
		return
	if not Util.load_card_db().has(card_id):
		push_warning("Event tried to add unknown card: %s" % card_id)
		return
	RunManager.add_card(card_id)

func _upgrade_first_available_card() -> void:
	var card_db: Dictionary = Util.load_card_db()
	for index in range(RunManager.deck.size()):
		var card_id: String = RunManager.deck[index]
		var card: CardData = card_db.get(card_id, null) as CardData
		if card != null and not card.upgraded_id.is_empty() and card_db.has(card.upgraded_id):
			RunManager.deck[index] = card.upgraded_id
			RunManager.deck_changed.emit()
			RunManager.run_updated.emit()
			RunManager.save_run_snapshot()
			return
