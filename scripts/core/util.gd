class_name Util
extends Object

static var _card_art_cache: Dictionary = {}

static func _load_resource_dir(path: String) -> Dictionary:
	var db: Dictionary = {}
	var dir: DirAccess = DirAccess.open(path)
	if dir == null:
		return db
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var full_path: String = path.path_join(file_name)
			var res: Resource = load(full_path)
			if res:
				var res_id: String = String(res.get("id"))
				if not res_id.is_empty():
					db[res_id] = res
		file_name = dir.get_next()
	dir.list_dir_end()
	return db

static func load_card_db() -> Dictionary:
	return _load_resource_dir("res://data/cards")

static func load_module_db() -> Dictionary:
	return _load_resource_dir("res://data/modules")

static func load_event_db() -> Dictionary:
	return _load_resource_dir("res://data/events")

static func load_enemy_db() -> Dictionary:
	return _load_resource_dir("res://data/enemies")

static func load_character(character_id: String = "amiya") -> CharacterData:
	var db: Dictionary = _load_resource_dir("res://data/characters")
	return db.get(character_id, null) as CharacterData

static func load_card_art(card_id: String) -> Texture2D:
	if _card_art_cache.has(card_id):
		return _card_art_cache[card_id] as Texture2D

	var direct_path: String = "res://assets/card_art/%s.png" % card_id
	var fallback_path: String = "res://assets/card_art/default_card.png"
	var texture: Texture2D = null

	if ResourceLoader.exists(direct_path):
		texture = load(direct_path) as Texture2D
	elif ResourceLoader.exists(fallback_path):
		texture = load(fallback_path) as Texture2D

	if texture != null:
		_card_art_cache[card_id] = texture

	return texture

static func get_card_reward_pool() -> Array[String]:
	return [
		"tactical_reorder", "focus_pulse", "emergency_shield", "resonance_burst",
		"command_sync", "signal_relay",
		"guided_fire", "rescue_corridor", "discipline_note", "pulse_scan",
		"burn_will", "overclock_arts", "tactical_calm", "echo_conduit"
	]

static func get_common_card_reward_pool() -> Array[String]:
	return [
		"tactical_reorder", "focus_pulse", "emergency_shield", "resonance_burst",
		"command_sync", "signal_relay", "guided_fire", "rescue_corridor",
		"discipline_note", "pulse_scan"
	]

static func get_uncommon_card_reward_pool() -> Array[String]:
	return [
		"burn_will", "overclock_arts", "tactical_calm", "echo_conduit"
	]

@warning_ignore("unused_parameter")
static func generate_node_metadata(floor_index: int, node_type: String, index: int, rng: RandomNumberGenerator = null) -> Dictionary:
	var data: Dictionary = {}
	var randomizer: RandomNumberGenerator = rng
	if randomizer == null:
		randomizer = RandomNumberGenerator.new()
		randomizer.randomize()
	match node_type:
		"battle":
			data["enemy_ids"] = get_random_battle_enemies(floor_index, randomizer)
		"elite":
			data["enemy_ids"] = get_random_elite_enemies(floor_index, randomizer)
		"boss":
			data["enemy_ids"] = get_boss_enemies(floor_index)
		"event", "story":
			var events: Array[String] = ["temporary_ward", "dobermann_inspection", "nearl_principle", "kaltsit_briefing", "ws_broadcast"]
			data["event_id"] = events[randomizer.randi_range(0, events.size() - 1)]
	return data

static func get_random_battle_enemies(floor_index: int, rng: RandomNumberGenerator) -> Array[String]:
	var pools := {
		1: [
			["reunion_scout"],
			["reunion_caster"],
			["reunion_scout", "reunion_scout"],
			["reunion_scout", "reunion_caster"]
		],
		2: [
			["riot_shieldbearer"],
			["crossbow_sniper"],
			["reunion_caster", "crossbow_sniper"],
			["riot_shieldbearer", "reunion_scout"]
		],
		3: [
			["crossbow_sniper", "reunion_caster"],
			["riot_shieldbearer", "crossbow_sniper"],
			["riot_shieldbearer", "reunion_caster"]
		],
		4: [
			["riot_shieldbearer", "crossbow_sniper"],
			["reunion_caster", "crossbow_sniper"],
			["riot_shieldbearer", "reunion_caster"]
		]
	}
	var options: Array = pools.get(floor_index, pools[1])
	var selected: Array = options[rng.randi_range(0, options.size() - 1)]
	var result: Array[String] = []
	for enemy_id in selected:
		result.append(String(enemy_id))
	return result

static func get_random_elite_enemies(floor_index: int, rng: RandomNumberGenerator) -> Array[String]:
	var pools := {
		1: [["field_captain"]],
		2: [["field_captain"], ["originium_channeler"]],
		3: [["originium_channeler"], ["field_captain"]],
		4: [["originium_channeler"]]
	}
	var options: Array = pools.get(floor_index, pools[1])
	var selected: Array = options[rng.randi_range(0, options.size() - 1)]
	var result: Array[String] = []
	for enemy_id in selected:
		result.append(String(enemy_id))
	return result

static func get_boss_enemies(floor_index: int) -> Array[String]:
	if floor_index == 1:
		return ["scout_chief"]
	if floor_index == 2:
		return ["lockdown_core"]
	if floor_index == 3:
		return ["w_boss"]
	return ["ash_echo"]
