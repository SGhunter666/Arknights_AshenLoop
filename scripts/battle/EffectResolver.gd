class_name EffectResolver
extends RefCounted

signal effect_resolved(effect_type: String, payload: Dictionary)

var battle_manager

func _init(owner = null):
	battle_manager = owner

func resolve_card(card: CardData, source: UnitState, target: UnitState = null) -> void:
	for effect in card.effects:
		if not _passes_condition(effect, source):
			continue
		resolve_effect(effect, source, target, card)

func resolve_effect(effect: EffectData, source: UnitState, target: UnitState, card: CardData = null) -> void:
	match effect.effect_type:
		"damage":
			_resolve_damage(effect, source, target, card)
		"block":
			var resolved_targets: Array[UnitState] = battle_manager.resolve_targets(effect.target, target)
			for t in resolved_targets:
				t.add_block(effect.amount)
			effect_resolved.emit("block", {"amount": effect.amount})
		"draw":
			battle_manager.deck.draw_cards(effect.amount)
			effect_resolved.emit("draw", {"amount": effect.amount})
		"gain_energy":
			source.energy += effect.amount
			effect_resolved.emit("gain_energy", {"amount": effect.amount})
		"gain_will":
			source.gain_will(effect.amount, battle_manager.player_resource_max)
			effect_resolved.emit("gain_will", {"amount": effect.amount})
		"lose_hp":
			source.lose_hp(effect.amount)
			effect_resolved.emit("lose_hp", {"amount": effect.amount})
		"apply_status":
			var targets: Array[UnitState] = battle_manager.resolve_targets(effect.target, target)
			for t in targets:
				t.apply_status(effect.status_id, effect.amount)
			effect_resolved.emit("apply_status", {"status_id": effect.status_id, "amount": effect.amount})
		"weaken_enemy_team":
			for e in battle_manager.enemies:
				e.apply_status("weak", effect.amount)
			effect_resolved.emit("team_debuff", {"amount": effect.amount})
		"damage_all":
			for e in battle_manager.enemies:
				_deal_damage(source, e, effect.amount, true, card)
		"spend_all_will_damage":
			var spent: int = source.spend_will(source.will)
			if target:
				_deal_damage(source, target, spent * effect.amount, true, card)
		"fetch_support":
			battle_manager.fetch_support_from_draw_or_discard()
		"peek_draw":
			battle_manager.peek_cards(effect.amount)
		"gain_gold":
			RunManager.add_gold(effect.amount)
			effect_resolved.emit("gain_gold", {"amount": effect.amount})
		_:
			push_warning("Unknown effect type: %s" % effect.effect_type)

func _resolve_damage(effect: EffectData, source: UnitState, target: UnitState, card: CardData = null) -> void:
	if target == null:
		return
	_deal_damage(source, target, effect.amount, true, card)

func preview_damage(source: UnitState, target: UnitState, amount: int, card: CardData = null, affected_by_block: bool = true) -> Dictionary:
	return _compute_damage_preview(source, target, amount, affected_by_block, card)

func _deal_damage(source: UnitState, target: UnitState, amount: int, affected_by_block: bool, card: CardData = null) -> void:
	var preview: Dictionary = _compute_damage_preview(source, target, amount, affected_by_block, card)
	var absorbed: int = int(preview.get("absorbed", 0))
	var final_damage: int = int(preview.get("damage_after_block", 0))

	if affected_by_block and absorbed > 0:
		target.block = max(0, target.block - absorbed)

	if final_damage > 0:
		target.lose_hp(final_damage)

	effect_resolved.emit("damage", {
		"source": source,
		"target": target,
		"amount": final_damage
	})

func _compute_damage_preview(source: UnitState, target: UnitState, amount: int, affected_by_block: bool, card: CardData = null) -> Dictionary:
	var final_damage: int = max(0, amount)
	if card and "Arts" in card.tags and bool(source.meta.get("support_trigger_ready", false)):
		final_damage += 2
	if card:
		final_damage += _card_bonus_damage(card, source)
	if int(source.statuses.get("strength", 0)) > 0:
		final_damage += int(source.statuses["strength"])
	if int(source.statuses.get("weak", 0)) > 0:
		final_damage = int(floor(final_damage * 0.75))
	if int(target.statuses.get("vulnerable", 0)) > 0:
		final_damage = int(ceil(final_damage * 1.5))

	var damage_before_block: int = final_damage
	var absorbed: int = 0
	if affected_by_block and target.block > 0:
		absorbed = min(target.block, final_damage)
		final_damage -= absorbed

	return {
		"damage_before_block": damage_before_block,
		"absorbed": absorbed,
		"damage_after_block": final_damage
	}

func _card_bonus_damage(card: CardData, source: UnitState) -> int:
	match card.id:
		"echo_conduit":
			return min(source.will, 6)
		"resonance_burst":
			return 4 if source.will >= 4 else 0
		"focus_pulse":
			return 3 if bool(source.meta.get("support_played_this_turn", false)) else 0
		_:
			return 0

func _passes_condition(effect: EffectData, source: UnitState) -> bool:
	match effect.condition:
		"":
			return true
		"played_arts":
			return bool(source.meta.get("played_arts_this_turn", false))
	return true
