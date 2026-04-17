class_name EnemyAI
extends RefCounted

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var RunManager = null

func _init(seed_value: int = 1):
	rng.seed = seed_value

func next_intent(enemy: UnitState, enemy_data: EnemyData, turn_index: int) -> Dictionary:
	match enemy_data.ai_profile:
		"basic":
			return _basic_intent(enemy_data, turn_index)
		"w_boss":
			if enemy_data.id == "ash_echo":
				return _ash_echo_intent(enemy, turn_index)
			return _w_intent(enemy, turn_index)
		"tank":
			return _tank_intent(enemy, enemy_data, turn_index)
		"debuffer":
			return _debuffer_intent(enemy, enemy_data, turn_index)
		"caster":
			return _caster_intent(enemy, enemy_data, turn_index)
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
	var phase_level: int = 1
	if enemy != null and enemy.hp > 0:
		if enemy.hp <= int(ceil(float(enemy.max_hp) * 0.25)):
			phase_level = 3
		elif enemy.hp <= int(ceil(float(enemy.max_hp) * 0.5)):
			phase_level = 2
	var intent: Dictionary = {}
	if phase_level >= 3:
		intent = _w_phase_three_intent(turn_index)
	elif phase_level >= 2:
		intent = _w_phase_two_intent(turn_index)
	else:
		intent = _w_phase_one_intent(turn_index)
	intent["phase_two"] = phase_level >= 2
	intent["phase_three"] = phase_level >= 3
	return _apply_w_deception(intent, phase_level, turn_index)

func _w_phase_one_intent(turn_index: int) -> Dictionary:
	var mod: int = turn_index % 6
	match mod:
		0:
			return {"type": "apply_curse", "curse": "blast_countdown", "value": 1, "label": "Plant Bomb"}
		1:
			return {"type": "attack", "value": 8, "label": "Explosive Volley"}
		2:
			return {"type": "shuffle_and_debuff", "value": 1, "label": "Mock and Disrupt"}
		3:
			return {"type": "apply_curse", "curse": "hesitation", "value": 1, "label": "Stage Jamming"}
		4:
			return {"type": "rule_shift", "rule": "first_card_tax", "label": "Ash Rule: First Card +1"}
		5:
			return {"type": "attack", "value": 10, "label": "Focused Demolition"}
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
			return {"type": "attack", "value": 8, "label": "Detonation Line"}
		4:
			return {"type": "apply_curse", "curse": "hesitation", "value": 1, "label": "Radio Static"}
		5:
			return {"type": "attack", "value": 6, "label": "Improvised Killzone"}
	return {"type": "attack", "value": 12, "label": "Attack 12"}

func _w_phase_three_intent(turn_index: int) -> Dictionary:
	var mod: int = turn_index % 6
	match mod:
		0:
			return {"type": "apply_curse", "curse": "blast_countdown", "value": 1, "label": "Mine Choir"}
		1:
			return {"type": "attack", "value": 9, "label": "Breach Burst"}
		2:
			return {"type": "shuffle_and_debuff", "value": 1, "label": "Signal Collapse"}
		3:
			return {"type": "attack", "value": 14, "label": "Carnival Fire"}
		4:
			return {"type": "apply_curse", "curse": "hesitation", "value": 1, "label": "Mocking Tax"}
		5:
			return {"type": "attack", "value": 6, "label": "Last Laugh"}
	return {"type": "attack", "value": 11, "label": "Attack 11"}

func _apply_w_deception(actual_intent: Dictionary, phase_level: int, turn_index: int) -> Dictionary:
	_bind_run_manager()
	var intent: Dictionary = actual_intent.duplicate(true)
	intent["display_type"] = intent.get("type", "attack")
	intent["display_value"] = intent.get("value", 0)
	intent["display_label"] = intent.get("label", "Unknown")
	if RunManager != null and RunManager.has_flag("w_intents_clear"):
		return intent
	var mod: int = turn_index % 6
	match String(intent.get("type", "attack")):
		"apply_curse":
			intent["display_type"] = "attack"
			intent["display_value"] = 7 if phase_level == 1 else (11 if phase_level == 2 else 14)
			intent["display_label"] = "Suppressing Fire"
		"shuffle_and_debuff":
			intent["display_type"] = "attack"
			intent["display_value"] = 8 if phase_level == 1 else (12 if phase_level == 2 else 15)
			intent["display_label"] = "Feint Barrage"
		"rule_shift":
			if mod == 3:
				intent["display_type"] = "apply_curse"
				intent["display_value"] = 0
				intent["display_label"] = "Static Interference"
			else:
				intent["display_type"] = "attack"
				intent["display_value"] = 10 if phase_level == 1 else (14 if phase_level == 2 else 17)
				intent["display_label"] = "Pressure Shot"
		"attack":
			if mod == 5:
				var reduction: int = 1 if phase_level == 1 else (2 if phase_level == 2 else 3)
				intent["display_value"] = max(1, int(intent.get("value", 0)) - reduction)
				intent["display_label"] = "Threaten and Laugh"
			elif phase_level >= 2:
				intent["display_value"] = max(1, int(intent.get("value", 0)) - 1)
	return intent

func _tank_intent(enemy: UnitState, enemy_data: EnemyData, turn_index: int) -> Dictionary:
	var base_damage: int = 6
	if not enemy_data.moves.is_empty():
		base_damage = int(enemy_data.moves[0].get("value", 6))
	var mod: int = turn_index % 4
	match mod:
		0:
			return {"type": "gain_block", "value": 10, "label": "Fortify"}
		1:
			var bonus: int = 3 if enemy.block > 0 else 0
			return {"type": "attack", "value": base_damage + bonus, "label": "Shielded Strike %d" % (base_damage + bonus)}
		2:
			return {"type": "attack", "value": base_damage, "label": "Heavy Swing %d" % base_damage}
		_:
			return {"type": "gain_block", "value": 6, "label": "Brace"}

func _debuffer_intent(enemy: UnitState, enemy_data: EnemyData, turn_index: int) -> Dictionary:
	var base_damage: int = 4
	if not enemy_data.moves.is_empty():
		base_damage = int(enemy_data.moves[0].get("value", 4))
	var mod: int = turn_index % 5
	match mod:
		0:
			return {"type": "apply_debuff", "status": "weak", "value": 2, "label": "Enfeeble"}
		1:
			return {"type": "apply_curse", "curse": "hesitation", "value": 1, "label": "Inject Doubt"}
		2:
			return {"type": "attack", "value": base_damage, "label": "Toxic Dart %d" % base_damage}
		3:
			return {"type": "apply_debuff", "status": "vulnerable", "value": 2, "label": "Expose Weakness"}
		_:
			return {"type": "shuffle_and_debuff", "value": 1, "label": "Disorienting Gas"}

func _caster_intent(enemy: UnitState, enemy_data: EnemyData, turn_index: int) -> Dictionary:
	var base_damage: int = 5
	if not enemy_data.moves.is_empty():
		base_damage = int(enemy_data.moves[0].get("value", 5))
	var charged: int = int(enemy.meta.get("charged_damage", 0))
	var mod: int = turn_index % 4
	match mod:
		0:
			return {"type": "charge", "value": base_damage * 2 + 4, "label": "Incantation"}
		1:
			if charged > 0:
				return {"type": "release", "value": 0, "label": "Unleash Arts %d" % charged}
			return {"type": "attack", "value": base_damage, "label": "Arts Bolt %d" % base_damage}
		2:
			return {"type": "attack", "value": base_damage + 2, "label": "Arcane Pulse %d" % (base_damage + 2)}
		_:
			return {"type": "charge", "value": base_damage + 6, "label": "Channel Power"}

func _bind_run_manager() -> void:
	if RunManager != null:
		return
	var main_loop := Engine.get_main_loop()
	if main_loop is SceneTree:
		RunManager = (main_loop as SceneTree).root.get_node_or_null("RunManager")
