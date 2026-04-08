extends Node

const TUNE_LIBRARY = preload("res://scripts/core/tune_library.gd")

signal run_started
signal run_updated
signal floor_changed(floor_index: int)
signal gold_changed(amount: int)
signal hp_changed(current: int, max_value: int)
signal modules_changed
signal charms_changed
signal deck_changed
signal map_changed

var character: CharacterData
var current_floor: int = 0
var current_node_id: String = ""
var gold: int = 99
var hp: int = 72
var max_hp: int = 72

var deck: Array[String] = []
var modules: Array[String] = []
var charms: Array[String] = []
var owned_charms: Array[String] = []
var tunes: Array[String] = []
var story_flags: Dictionary = {}
var map_nodes: Array[MapNodeModel] = []
var reachable_node_ids: Array[String] = []
var pending_rewards: Dictionary = {}
var rng_seed: int = 0
var last_run_summary: Dictionary = {}
var pending_interfloor_rest: bool = false
var run_won: bool = false

func start_new_run(char_data: CharacterData, seed_value: int = 0) -> void:
	character = char_data
	current_floor = 1
	current_node_id = ""
	gold = 99
	max_hp = char_data.max_hp
	hp = char_data.max_hp
	deck.clear()
	for card_id in char_data.starter_deck:
		deck.append(card_id)
	modules.clear()
	charms.clear()
	owned_charms.clear()
	tunes.clear()
	for charm_id in char_data.starter_charms:
		var normalized_charm: String = String(charm_id)
		if normalized_charm.is_empty():
			continue
		if not owned_charms.has(normalized_charm):
			owned_charms.append(normalized_charm)
		if not charms.has(normalized_charm) and charms.size() < max_charm_slots():
			charms.append(normalized_charm)
	_apply_run_start_charms()
	story_flags.clear()
	pending_rewards.clear()
	last_run_summary.clear()
	pending_interfloor_rest = false
	run_won = false
	rng_seed = seed_value if seed_value != 0 else int(Time.get_unix_time_from_system())
	story_flags["soft_focus_archetype"] = _seeded_soft_focus_archetype()
	story_flags["battle_reward_archetypes"] = []
	_generate_floor_map(current_floor)
	_record_run_started()
	run_started.emit()
	run_updated.emit()
	floor_changed.emit(current_floor)
	save_run_snapshot()

func abandon_run() -> void:
	character = null
	current_floor = 0
	current_node_id = ""
	gold = 99
	hp = 72
	max_hp = 72
	deck.clear()
	modules.clear()
	charms.clear()
	owned_charms.clear()
	tunes.clear()
	story_flags.clear()
	map_nodes.clear()
	reachable_node_ids.clear()
	pending_rewards.clear()
	last_run_summary.clear()
	pending_interfloor_rest = false
	run_won = false
	clear_saved_run()
	run_updated.emit()
	map_changed.emit()
	clear_saved_run()

func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)
	run_updated.emit()
	save_run_snapshot()

func lose_hp(amount: int) -> void:
	hp = max(0, hp - amount)
	hp_changed.emit(hp, max_hp)
	run_updated.emit()
	save_run_snapshot()

func heal(amount: int) -> void:
	hp = min(max_hp, hp + amount)
	hp_changed.emit(hp, max_hp)
	run_updated.emit()
	save_run_snapshot()

func heal_full() -> void:
	hp = max_hp
	hp_changed.emit(hp, max_hp)
	run_updated.emit()
	save_run_snapshot()

func add_card(card_id: String, source: String = "generic") -> void:
	if card_id.is_empty():
		return
	deck.append(card_id)
	_record_card_gain(card_id, source)
	deck_changed.emit()
	run_updated.emit()
	save_run_snapshot()

func remove_card(card_id: String) -> bool:
	var idx: int = deck.find(card_id)
	if idx == -1:
		return false
	deck.remove_at(idx)
	deck_changed.emit()
	run_updated.emit()
	save_run_snapshot()
	return true

func add_module(module_id: String) -> void:
	if not modules.has(module_id):
		modules.append(module_id)
	modules_changed.emit()
	run_updated.emit()
	save_run_snapshot()

func add_charm(charm_id: String, auto_equip_if_slot: bool = true) -> void:
	if charm_id.is_empty():
		return
	var changed: bool = false
	if not owned_charms.has(charm_id):
		owned_charms.append(charm_id)
		changed = true
	if auto_equip_if_slot and not charms.has(charm_id) and charms.size() < max_charm_slots():
		charms.append(charm_id)
		changed = true
	if not changed:
		return
	charms_changed.emit()
	run_updated.emit()
	save_run_snapshot()

func equip_charm(charm_id: String, slot_index: int = -1) -> bool:
	if charm_id.is_empty() or not owned_charms.has(charm_id):
		return false
	if slot_index < 0:
		if charms.has(charm_id):
			return true
		if charms.size() < max_charm_slots():
			charms.append(charm_id)
		elif not charms.is_empty():
			charms[0] = charm_id
		else:
			charms.append(charm_id)
	else:
		var target_slot: int = int(clamp(slot_index, 0, max_charm_slots() - 1))
		while charms.size() <= target_slot and charms.size() < max_charm_slots():
			charms.append("")
		var existing_slot: int = charms.find(charm_id)
		if existing_slot != -1 and existing_slot != target_slot:
			charms[existing_slot] = ""
		charms[target_slot] = charm_id
		charms = _compact_string_array(charms)
	charms_changed.emit()
	run_updated.emit()
	save_run_snapshot()
	return true

func add_tune(tune_id: String) -> bool:
	if tune_id.is_empty() or tunes.has(tune_id):
		return false
	tunes.append(tune_id)
	run_updated.emit()
	save_run_snapshot()
	return true

func has_tune(tune_id: String) -> bool:
	return tunes.has(tune_id)

func tune_offer(seed_value: int, count: int = 3) -> Array[String]:
	return TUNE_LIBRARY.offer_tunes(seed_value, count, tunes)

func tune_summary_lines() -> Array[String]:
	var lines: Array[String] = []
	for tune_id in tunes:
		lines.append("%s：%s" % [TUNE_LIBRARY.title(tune_id), TUNE_LIBRARY.short_text(tune_id)])
	return lines

func has_relic(relic_id: String) -> bool:
	return modules.has(relic_id) or charms.has(relic_id)

func is_charm_owned(charm_id: String) -> bool:
	return owned_charms.has(charm_id)

func is_charm_equipped(charm_id: String) -> bool:
	return charms.has(charm_id)

func max_charm_slots() -> int:
	return 2

func unequipped_owned_charms() -> Array[String]:
	var result: Array[String] = []
	for charm_id in owned_charms:
		if not charms.has(charm_id):
			result.append(charm_id)
	return result

func set_flag(flag_name: String, value = true) -> void:
	story_flags[flag_name] = value
	run_updated.emit()
	save_run_snapshot()

func has_flag(flag_name: String) -> bool:
	return bool(story_flags.get(flag_name, false))

func current_node() -> MapNodeModel:
	if current_node_id.is_empty():
		return null
	return get_node_by_id(current_node_id)

func clear_stale_node_selection() -> void:
	if current_node_id.is_empty():
		return
	# The map scene should never remain open while a node is actively selected.
	# If we returned here with a leftover selection, always clear it so routes
	# become clickable again instead of leaving the whole floor disabled.
	current_node_id = ""
	run_updated.emit()
	map_changed.emit()
	save_run_snapshot()

func get_node_by_id(node_id: String) -> MapNodeModel:
	for node in map_nodes:
		if node.id == node_id:
			return node
	return null

func select_node(node_id: String) -> bool:
	if not is_node_reachable(node_id):
		return false
	var node: MapNodeModel = get_node_by_id(node_id)
	if node == null or node.completed:
		return false
	current_node_id = node_id
	run_updated.emit()
	map_changed.emit()
	save_run_snapshot()
	return true

func complete_current_node() -> void:
	var node: MapNodeModel = current_node()
	if node == null:
		return
	node.completed = true
	current_node_id = ""
	if node.node_type == "boss":
		_finish_floor()
	else:
		reachable_node_ids = node.next_ids.duplicate()
	map_changed.emit()
	run_updated.emit()
	save_run_snapshot()

func is_node_reachable(node_id: String) -> bool:
	return current_node_id.is_empty() and reachable_node_ids.has(node_id)

func get_rows() -> Array:
	var grouped: Dictionary = {}
	var row_indexes: Array[int] = []
	for node in map_nodes:
		if not grouped.has(node.row):
			grouped[node.row] = []
			row_indexes.append(node.row)
		var row_nodes: Array = grouped[node.row]
		row_nodes.append(node)
	row_indexes.sort()
	var rows: Array = []
	for row_index in row_indexes:
		var row_nodes: Array = grouped[row_index]
		row_nodes.sort_custom(func(a: MapNodeModel, b: MapNodeModel) -> bool:
			return a.lane < b.lane
		)
		rows.append(row_nodes)
	return rows

func _generate_floor_map(floor_index: int) -> void:
	map_nodes = MapGenerator.new(rng_seed + floor_index * 997 + deck.size() * 31 + modules.size() * 17).generate_floor(floor_index)
	reachable_node_ids.clear()
	current_node_id = ""
	var first_row: int = -1
	for node in map_nodes:
		if first_row == -1 or node.row < first_row:
			first_row = node.row
	for node in map_nodes:
		if node.row == first_row:
			reachable_node_ids.append(node.id)
	map_changed.emit()

func _finish_floor() -> void:
	if current_floor < 3:
		current_floor += 1
		_generate_floor_map(current_floor)
		pending_interfloor_rest = true
		floor_changed.emit(current_floor)
		save_run_snapshot()
		return
	if current_floor == 3 and _should_unlock_hidden_floor():
		run_won = true
		story_flags["run_won"] = true
		current_floor = 4
		_generate_floor_map(current_floor)
		pending_interfloor_rest = true
		floor_changed.emit(current_floor)
		save_run_snapshot()
		return
	if current_floor == 3:
		run_won = true
		story_flags["run_won"] = true
	set_flag("run_complete", true)
	reachable_node_ids.clear()
	clear_saved_run()

func should_take_interfloor_rest() -> bool:
	return pending_interfloor_rest

func consume_interfloor_rest() -> void:
	pending_interfloor_rest = false
	run_updated.emit()
	save_run_snapshot()

func _should_unlock_hidden_floor() -> bool:
	var score: int = 0
	if has_flag("accept_burden_1"):
		score += 1
	if has_flag("accept_burden_2"):
		score += 1
	if has_flag("accept_burden_3"):
		score += 1
	if has_flag("self_damage_rescue_4"):
		score += 1
	if _count_rhodes_modules() >= 3:
		score += 1
	if has_flag("spared_w"):
		score += 1
	return score >= 2

func _count_rhodes_modules() -> int:
	var tracked: Array[String] = ["rhodes_tactical_console", "field_command_badge", "ashen_thread", "rhodes_pin", "operators_thread"]
	var total: int = 0
	for module_id in tracked:
		if modules.has(module_id) or owned_charms.has(module_id) or charms.has(module_id):
			total += 1
	return total

func has_active_run() -> bool:
	return character != null and current_floor > 0 and not has_flag("run_complete")

func get_reward_bias_weights() -> Dictionary:
	var weights: Dictionary = {
		"will_burst": 1.0,
		"resonance_combo": 1.0,
		"command_support": 1.0,
		"overload_sacrifice": 1.0,
		"neutral": 1.0
	}
	var soft_focus: String = String(story_flags.get("soft_focus_archetype", ""))
	var recent_archetypes: Array[String] = _string_array_from_variant(story_flags.get("battle_reward_archetypes", []))
	if current_floor == 1 and not soft_focus.is_empty() and recent_archetypes.size() < 2 and weights.has(soft_focus):
		weights[soft_focus] = float(weights[soft_focus]) * 1.18
	if has_flag("doctor_ideal"):
		weights["command_support"] = float(weights["command_support"]) * 1.35
		weights["resonance_combo"] = float(weights["resonance_combo"]) * 1.10
	if has_flag("doctor_efficiency"):
		weights["will_burst"] = float(weights["will_burst"]) * 1.35
	if has_flag("doctor_burden"):
		weights["overload_sacrifice"] = float(weights["overload_sacrifice"]) * 1.35
		weights["will_burst"] = float(weights["will_burst"]) * 1.10
	if recent_archetypes.size() >= 2:
		var last_archetype: String = recent_archetypes[recent_archetypes.size() - 1]
		var prev_archetype: String = recent_archetypes[recent_archetypes.size() - 2]
		if last_archetype == prev_archetype and weights.has(last_archetype):
			weights[last_archetype] = float(weights[last_archetype]) * 1.25
	var deck_counts: Dictionary = _deck_archetype_counts()
	var dominant: String = ""
	var dominant_count: int = 0
	for archetype in deck_counts.keys():
		var count: int = int(deck_counts[archetype])
		if archetype == "neutral":
			continue
		if count > dominant_count:
			dominant = String(archetype)
			dominant_count = count
	if not dominant.is_empty() and dominant_count >= 3 and weights.has(dominant):
		weights[dominant] = float(weights[dominant]) * 1.15
	return weights

func has_saved_run() -> bool:
	var profile: Dictionary = SaveManager.load_profile()
	return typeof(profile.get("run_save", null)) == TYPE_DICTIONARY

func saved_run_summary() -> Dictionary:
	var profile: Dictionary = SaveManager.load_profile()
	var save_data: Variant = profile.get("run_save", {})
	return save_data if typeof(save_data) == TYPE_DICTIONARY else {}

func save_run_snapshot() -> void:
	if not has_active_run():
		return
	SaveManager.update_profile({"run_save": _serialize_run()})

func clear_saved_run() -> void:
	var profile: Dictionary = SaveManager.load_profile()
	profile.erase("run_save")
	profile["run_save"] = null
	SaveManager.save_profile(profile)

func record_run_result(victory: bool) -> void:
	var profile: Dictionary = SaveManager.load_profile()
	var stats: Dictionary = profile.get("stats", {}) if typeof(profile.get("stats", {})) == TYPE_DICTIONARY else {}
	stats["runs_started"] = int(stats.get("runs_started", 0))
	stats["runs_won"] = int(stats.get("runs_won", 0)) + (1 if victory else 0)
	stats["runs_lost"] = int(stats.get("runs_lost", 0)) + (0 if victory else 1)
	stats["best_floor"] = max(int(stats.get("best_floor", 0)), current_floor)
	stats["total_gold_collected"] = int(stats.get("total_gold_collected", 0)) + gold
	profile["stats"] = stats

	var history: Array = profile.get("run_history", []) if typeof(profile.get("run_history", [])) == TYPE_ARRAY else []
	var record: Dictionary = {
		"character_id": character.id if character != null else "amiya",
		"floor": current_floor,
		"gold": gold,
		"deck_size": deck.size(),
		"modules": modules.size(),
		"result": "victory" if victory else "defeat",
		"timestamp": int(Time.get_unix_time_from_system())
	}
	history.insert(0, record)
	while history.size() > 8:
		history.pop_back()
	profile["run_history"] = history
	SaveManager.save_profile(profile)

func load_saved_run() -> bool:
	var save_data: Dictionary = saved_run_summary()
	if save_data.is_empty():
		return false
	var char_id: String = String(save_data.get("character_id", ""))
	var char_data: CharacterData = Util.load_character(char_id)
	if char_data == null:
		return false
	character = char_data
	current_floor = int(save_data.get("current_floor", 1))
	current_node_id = String(save_data.get("current_node_id", ""))
	gold = int(save_data.get("gold", 99))
	hp = int(save_data.get("hp", char_data.max_hp))
	max_hp = int(save_data.get("max_hp", char_data.max_hp))
	deck = _string_array_from_variant(save_data.get("deck", []))
	modules = _string_array_from_variant(save_data.get("modules", []))
	var loaded_equipped_charms: Array[String] = _string_array_from_variant(save_data.get("charms", []))
	owned_charms = _string_array_from_variant(save_data.get("owned_charms", loaded_equipped_charms))
	charms.clear()
	for charm_id in loaded_equipped_charms:
		if owned_charms.has(charm_id) and not charms.has(charm_id) and charms.size() < max_charm_slots():
			charms.append(charm_id)
	tunes = _string_array_from_variant(save_data.get("tunes", []))
	reachable_node_ids = _string_array_from_variant(save_data.get("reachable_node_ids", []))
	pending_rewards = save_data.get("pending_rewards", {}) if typeof(save_data.get("pending_rewards", {})) == TYPE_DICTIONARY else {}
	last_run_summary = save_data.get("last_run_summary", {}) if typeof(save_data.get("last_run_summary", {})) == TYPE_DICTIONARY else {}
	story_flags = save_data.get("story_flags", {}) if typeof(save_data.get("story_flags", {})) == TYPE_DICTIONARY else {}
	rng_seed = int(save_data.get("rng_seed", int(Time.get_unix_time_from_system())))
	pending_interfloor_rest = bool(save_data.get("pending_interfloor_rest", false))
	run_won = bool(save_data.get("run_won", false))
	map_nodes = []
	for node_data_variant in save_data.get("map_nodes", []):
		if typeof(node_data_variant) != TYPE_DICTIONARY:
			continue
		var node_data: Dictionary = node_data_variant
		var node: MapNodeModel = MapNodeModel.new()
		node.id = String(node_data.get("id", ""))
		node.node_type = String(node_data.get("node_type", "battle"))
		node.floor_index = int(node_data.get("floor_index", current_floor))
		node.index = int(node_data.get("index", 0))
		node.row = int(node_data.get("row", 0))
		node.lane = int(node_data.get("lane", 0))
		node.next_ids = _string_array_from_variant(node_data.get("next_ids", []))
		node.completed = bool(node_data.get("completed", false))
		node.metadata = node_data.get("metadata", {}) if typeof(node_data.get("metadata", {})) == TYPE_DICTIONARY else {}
		map_nodes.append(node)
	run_started.emit()
	run_updated.emit()
	floor_changed.emit(current_floor)
	map_changed.emit()
	return true

func _serialize_run() -> Dictionary:
	var serialized_nodes: Array[Dictionary] = []
	for node in map_nodes:
		serialized_nodes.append({
			"id": node.id,
			"node_type": node.node_type,
			"floor_index": node.floor_index,
			"index": node.index,
			"row": node.row,
			"lane": node.lane,
			"next_ids": node.next_ids.duplicate(),
			"completed": node.completed,
			"metadata": node.metadata.duplicate(true)
		})
	return {
		"character_id": character.id,
		"current_floor": current_floor,
		"current_node_id": current_node_id,
		"gold": gold,
		"hp": hp,
		"max_hp": max_hp,
		"deck": deck.duplicate(),
		"modules": modules.duplicate(),
		"charms": charms.duplicate(),
		"owned_charms": owned_charms.duplicate(),
		"tunes": tunes.duplicate(),
		"story_flags": story_flags.duplicate(true),
		"map_nodes": serialized_nodes,
		"reachable_node_ids": reachable_node_ids.duplicate(),
		"pending_rewards": pending_rewards.duplicate(true),
		"rng_seed": rng_seed,
		"last_run_summary": last_run_summary.duplicate(true),
		"pending_interfloor_rest": pending_interfloor_rest,
		"run_won": run_won
	}

func _apply_run_start_charms() -> void:
	if charms.has("rabbit_emblem"):
		deck.append("mental_tuning")

func _record_run_started() -> void:
	var profile: Dictionary = SaveManager.load_profile()
	var stats: Dictionary = profile.get("stats", {}) if typeof(profile.get("stats", {})) == TYPE_DICTIONARY else {}
	stats["runs_started"] = int(stats.get("runs_started", 0)) + 1
	profile["stats"] = stats
	SaveManager.save_profile(profile)

func _string_array_from_variant(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if typeof(value) != TYPE_ARRAY:
		return result
	for item in value:
		result.append(String(item))
	return result

func _record_card_gain(card_id: String, source: String) -> void:
	if source != "battle_reward":
		return
	var archetype: String = Util.card_archetype(card_id)
	if archetype == "neutral":
		return
	var recent_archetypes: Array[String] = _string_array_from_variant(story_flags.get("battle_reward_archetypes", []))
	recent_archetypes.append(archetype)
	while recent_archetypes.size() > 4:
		recent_archetypes.pop_front()
	story_flags["battle_reward_archetypes"] = recent_archetypes

func _deck_archetype_counts() -> Dictionary:
	var counts: Dictionary = {
		"will_burst": 0,
		"resonance_combo": 0,
		"command_support": 0,
		"overload_sacrifice": 0,
		"neutral": 0
	}
	for card_id in deck:
		var archetype: String = Util.card_archetype(String(card_id))
		counts[archetype] = int(counts.get(archetype, 0)) + 1
	return counts

func _seeded_soft_focus_archetype() -> String:
	var options: Array[String] = ["will_burst", "resonance_combo", "command_support", "overload_sacrifice"]
	if options.is_empty():
		return ""
	return options[abs(rng_seed) % options.size()]

func _compact_string_array(values: Array[String]) -> Array[String]:
	var result: Array[String] = []
	for value in values:
		if not value.is_empty() and not result.has(value):
			result.append(value)
	return result
