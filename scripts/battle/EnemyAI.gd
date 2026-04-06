class_name EnemyAI
extends RefCounted

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _init(seed_value: int = 1):
	rng.seed = seed_value

func next_intent(enemy: UnitState, enemy_data: EnemyData, turn_index: int) -> Dictionary:
	if enemy_data.ai_profile == "basic":
		return _basic_intent(enemy_data, turn_index)
	if enemy_data.ai_profile == "w_boss":
		return _w_intent(turn_index)
	return {"type": "attack", "value": 6, "label": "Attack 6"}

func _basic_intent(enemy_data: EnemyData, turn_index: int) -> Dictionary:
	if enemy_data.moves.is_empty():
		return {"type": "attack", "value": 6, "label": "Attack 6"}
	return enemy_data.moves[turn_index % enemy_data.moves.size()].duplicate(true)

func _w_intent(turn_index: int) -> Dictionary:
	var mod: int = turn_index % 6
	match mod:
		0:
			return {"type": "apply_curse", "curse": "blast_countdown", "value": 1, "label": "Plant Bomb"}
		1:
			return {"type": "attack", "value": 12, "label": "Explosive Volley"}
		2:
			return {"type": "shuffle_and_debuff", "value": 1, "label": "Mock and Disrupt"}
		3:
			return {"type": "rule_shift", "rule": "hand_limit_down", "label": "Ash Rule: Hand Limit -1"}
		4:
			return {"type": "rule_shift", "rule": "first_card_tax", "label": "Ash Rule: First Card +1"}
		5:
			return {"type": "attack", "value": 15, "label": "Focused Demolition"}
	return {"type": "attack", "value": 8, "label": "Attack 8"}
