class_name RewardGenerator
extends RefCounted

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _init(seed_value: int = 1):
	rng.seed = seed_value

func card_choices(pool: Array[String], count: int = 3, archetype_weights: Dictionary = {}) -> Array[String]:
	return _weighted_unique_choices(pool, count, archetype_weights)

func elite_card_choices(common_pool: Array[String], uncommon_pool: Array[String], count: int = 3, archetype_weights: Dictionary = {}) -> Array[String]:
	var result: Array[String] = []
	var uncommon_copy: Array[String] = uncommon_pool.duplicate()
	var common_copy: Array[String] = common_pool.duplicate()
	var first_pick: String = _pick_weighted_card(uncommon_copy, archetype_weights, result)
	if not first_pick.is_empty():
		result.append(first_pick)
	var mixed_pool: Array[String] = []
	for card_id in uncommon_copy:
		mixed_pool.append(String(card_id))
	for card_id in common_copy:
		mixed_pool.append(String(card_id))
	while result.size() < count and not mixed_pool.is_empty():
		var next_id: String = _pick_weighted_card(mixed_pool, archetype_weights, result)
		if next_id.is_empty():
			break
		result.append(next_id)
	return result

func elite_picks_allowed() -> int:
	return 2 if rng.randf() < 0.42 else 1

func module_choice(pool: Array[String]) -> String:
	if pool.is_empty():
		return ""
	return pool[rng.randi_range(0, pool.size() - 1)]

func _weighted_unique_choices(pool: Array[String], count: int, archetype_weights: Dictionary) -> Array[String]:
	var available: Array[String] = pool.duplicate()
	var result: Array[String] = []
	while result.size() < count and not available.is_empty():
		var picked: String = _pick_weighted_card(available, archetype_weights, result)
		if picked.is_empty():
			break
		result.append(picked)
	return result

func _pick_weighted_card(pool: Array[String], archetype_weights: Dictionary, excluded: Array[String]) -> String:
	var available: Array[String] = []
	for entry in pool:
		var card_id: String = String(entry)
		if not excluded.has(card_id):
			available.append(card_id)
	if available.is_empty():
		return ""
	var total_weight: float = 0.0
	var weights: Array[float] = []
	for card_id in available:
		var archetype: String = Util.card_archetype(card_id)
		var weight: float = float(archetype_weights.get(archetype, 1.0))
		total_weight += max(0.05, weight)
		weights.append(max(0.05, weight))
	var roll: float = rng.randf() * total_weight
	for index in range(available.size()):
		roll -= weights[index]
		if roll <= 0.0:
			var selected: String = available[index]
			pool.erase(selected)
			return selected
	var fallback: String = available[available.size() - 1]
	pool.erase(fallback)
	return fallback
