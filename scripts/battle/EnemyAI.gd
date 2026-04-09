class_name EnemyAI
extends RefCounted

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _init(seed_value: int = 1):
	rng.seed = seed_value

func next_intent(enemy: UnitState, enemy_data: EnemyData, turn_index: int) -> Dictionary:
	if enemy_data.ai_profile == "basic":
		return _basic_intent(enemy_data, turn_index)
	if enemy_data.ai_profile == "w_boss":
		if enemy_data.id == "ash_echo":
			return _ash_echo_intent(enemy, turn_index)
		return _w_intent(enemy, turn_index)
	return {"type": "attack", "value": 6, "label": "Attack 6"}

func _basic_intent(enemy_data: EnemyData, turn_index: int) -> Dictionary:
	if enemy_data.moves.is_empty():
		return {"type": "attack", "value": 6, "label": "Attack 6"}
	return enemy_data.moves[turn_index % enemy_data.moves.size()].duplicate(true)

func _ash_echo_intent(enemy: UnitState, turn_index: int) -> Dictionary:
	var phase_two: bool = enemy != null and enemy.hp > 0 and enemy.hp <= int(ceil(float(enemy.max_hp) * 0.35))
	match turn_index % 4:
		0:
			return {"type": "attack", "value": 8 if not phase_two else 10, "label": "Echo Sever", "phase_two": phase_two}
		1:
			return {"type": "attack", "value": 7 if not phase_two else 9, "label": "Ash Pulse", "phase_two": phase_two}
		2:
			if phase_two:
				return {"type": "apply_curse", "curse": "hesitation", "value": 1, "label": "Afterimage Static", "phase_two": true}
			return {"type": "shuffle_and_debuff", "value": 1, "label": "Memory Distort", "phase_two": false}
		_:
			return {"type": "attack", "value": 10 if not phase_two else 11, "label": "Judgement Arc", "phase_two": phase_two}

func _w_intent(enemy: UnitState, turn_index: int) -> Dictionary:
	var phase_two: bool = enemy != null and enemy.hp > 0 and enemy.hp <= int(ceil(float(enemy.max_hp) * 0.5))
	var intent: Dictionary = {}
	if phase_two:
		intent = _w_phase_two_intent(turn_index)
	else:
		intent = _w_phase_one_intent(turn_index)
	intent["phase_two"] = phase_two
	return _apply_w_deception(intent, phase_two, turn_index)

func _w_phase_one_intent(turn_index: int) -> Dictionary:
	var mod: int = turn_index % 6
	match mod:
		0:
			return {"type": "apply_curse", "curse": "blast_countdown", "value": 1, "label": "Plant Bomb"}
		1:
			return {"type": "attack", "value": 9, "label": "Explosive Volley"}
		2:
			return {"type": "shuffle_and_debuff", "value": 1, "label": "Mock and Disrupt"}
		3:
			return {"type": "rule_shift", "rule": "hand_limit_down", "label": "Ash Rule: Hand Limit -1"}
		4:
			return {"type": "rule_shift", "rule": "first_card_tax", "label": "Ash Rule: First Card +1"}
		5:
			return {"type": "attack", "value": 11, "label": "Focused Demolition"}
	return {"type": "attack", "value": 8, "label": "Attack 8"}

func _w_phase_two_intent(turn_index: int) -> Dictionary:
	var mod: int = turn_index % 6
	match mod:
		0:
			return {"type": "apply_curse", "curse": "blast_countdown", "value": 1, "label": "Prime Charge"}
		1:
			return {"type": "attack", "value": 12, "label": "Shrapnel Sweep"}
		2:
			return {"type": "shuffle_and_debuff", "value": 1, "label": "Stage Sabotage"}
		3:
			return {"type": "attack", "value": 14, "label": "Detonation Line"}
		4:
			return {"type": "rule_shift", "rule": "first_card_tax", "label": "Ash Rule: First Card +1"}
		5:
			return {"type": "attack", "value": 11, "label": "Improvised Killzone"}
	return {"type": "attack", "value": 10, "label": "Attack 10"}

func _apply_w_deception(actual_intent: Dictionary, phase_two: bool, turn_index: int) -> Dictionary:
	var intent: Dictionary = actual_intent.duplicate(true)
	intent["display_type"] = intent.get("type", "attack")
	intent["display_value"] = intent.get("value", 0)
	intent["display_label"] = intent.get("label", "Unknown")
	if RunManager.has_flag("w_intents_clear"):
		return intent
	var mod: int = turn_index % 6
	match String(intent.get("type", "attack")):
		"apply_curse":
			intent["display_type"] = "attack"
			intent["display_value"] = 7 if not phase_two else 11
			intent["display_label"] = "Suppressing Fire"
		"shuffle_and_debuff":
			intent["display_type"] = "attack"
			intent["display_value"] = 8 if not phase_two else 12
			intent["display_label"] = "Feint Barrage"
		"rule_shift":
			if mod == 3:
				intent["display_type"] = "apply_curse"
				intent["display_value"] = 0
				intent["display_label"] = "Static Interference"
			else:
				intent["display_type"] = "attack"
				intent["display_value"] = 10 if not phase_two else 14
				intent["display_label"] = "Pressure Shot"
		"attack":
			if mod == 5:
				intent["display_value"] = max(1, int(intent.get("value", 0)) - (1 if not phase_two else 2))
				intent["display_label"] = "Threaten and Laugh"
			elif phase_two:
				intent["display_value"] = max(1, int(intent.get("value", 0)) - 1)
	return intent
