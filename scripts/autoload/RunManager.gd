extends Node

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
	for charm_id in char_data.starter_charms:
		charms.append(String(charm_id))
	_apply_run_start_charms()
	story_flags.clear()
	pending_rewards.clear()
	last_run_summary.clear()
	pending_interfloor_rest = false
	run_won = false
	rng_seed = seed_value if seed_value != 0 else int(Time.get_unix_time_from_system())
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

func add_card(card_id: String) -> void:
	if card_id.is_empty():
		return
	deck.append(card_id)
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

func add_charm(charm_id: String) -> void:
	if not charm_id.is_empty() and not charms.has(charm_id):
		charms.append(charm_id)
	charms_changed.emit()
	run_updated.emit()
	save_run_snapshot()

func equip_charm(charm_id: String) -> void:
	if charm_id.is_empty():
		return
	if charms.has(charm_id):
		return
	if charms.size() >= 2:
		charms[0] = charm_id
	else:
		charms.append(charm_id)
	charms_changed.emit()
	run_updated.emit()
	save_run_snapshot()

func has_relic(relic_id: String) -> bool:
	return modules.has(relic_id) or charms.has(relic_id)

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
		if has_relic(module_id):
			total += 1
	return total

func has_active_run() -> bool:
	return character != null and current_floor > 0 and not has_flag("run_complete")

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
	charms = _string_array_from_variant(save_data.get("charms", []))
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
