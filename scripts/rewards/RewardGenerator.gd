class_name RewardGenerator
extends RefCounted

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _init(seed_value: int = 1):
	rng.seed = seed_value

func card_choices(pool: Array[String], count: int = 3) -> Array[String]:
	var copy: Array[String] = pool.duplicate()
	copy.shuffle()
	return copy.slice(0, min(count, copy.size()))

func elite_card_choices(common_pool: Array[String], uncommon_pool: Array[String], count: int = 3) -> Array[String]:
	var result: Array[String] = []
	var uncommon_copy: Array[String] = uncommon_pool.duplicate()
	var common_copy: Array[String] = common_pool.duplicate()
	uncommon_copy.shuffle()
	common_copy.shuffle()
	if not uncommon_copy.is_empty():
		result.append(String(uncommon_copy.pop_front()))
	var mixed_pool: Array[String] = []
	for card_id in uncommon_copy:
		mixed_pool.append(String(card_id))
	for card_id in common_copy:
		mixed_pool.append(String(card_id))
	mixed_pool.shuffle()
	while result.size() < count and not mixed_pool.is_empty():
		var next_id: String = String(mixed_pool.pop_front())
		if not result.has(next_id):
			result.append(next_id)
	return result

func elite_picks_allowed() -> int:
	return 2 if rng.randf() < 0.42 else 1

func module_choice(pool: Array[String]) -> String:
	if pool.is_empty():
		return ""
	return pool[rng.randi_range(0, pool.size() - 1)]
