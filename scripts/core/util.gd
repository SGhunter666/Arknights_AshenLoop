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

static func load_charm_db() -> Dictionary:
	return _load_resource_dir("res://data/charms")

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

static func card_archetype(card_id: String) -> String:
	var overrides := {
		"echo_conduit": "will_burst",
		"focused_ray": "will_burst",
		"final_vector": "will_burst",
		"grand_equation": "will_burst",
		"ember_judgement": "will_burst",
		"field_command": "command_support",
		"tactical_briefing": "command_support",
		"rhodes_formation": "command_support",
		"command_overflow": "command_support",
		"voice_of_the_leader": "command_support",
		"resonance_mark": "resonance_combo",
		"echo_lattice": "resonance_combo",
		"chain_reaction": "resonance_combo",
		"absolute_resonance": "resonance_combo",
		"bloodline_casting": "overload_sacrifice",
		"desperate_focus": "overload_sacrifice",
		"controlled_overload": "overload_sacrifice",
		"black_ring_method": "overload_sacrifice",
		"ashes_to_ashes": "overload_sacrifice"
	}
	if overrides.has(card_id):
		return String(overrides[card_id])
	var card: CardData = load_card_db().get(card_id, null) as CardData
	if card == null:
		return "neutral"
	var tags: PackedStringArray = card.tags
	if tags.has("Overload"):
		return "overload_sacrifice"
	if tags.has("Support") or tags.has("Command") or tags.has("Tactic"):
		return "command_support"
	if tags.has("Resonance") or tags.has("Echo") or tags.has("Channel"):
		return "resonance_combo"
	if tags.has("Will") or tags.has("WillGain") or tags.has("WillSpend"):
		return "will_burst"
	return "neutral"

static func get_card_reward_pool() -> Array[String]:
	return [
		"tactical_reorder", "focus_pulse", "emergency_shield", "resonance_burst",
		"command_sync", "signal_relay", "guided_fire", "rescue_corridor",
		"discipline_note", "pulse_scan", "burn_will", "overclock_arts",
		"tactical_calm", "echo_conduit", "guard_pulse", "mental_tuning",
		"field_command", "resonance_mark", "focused_ray", "tactical_briefing",
		"bloodline_casting", "channel_pulse", "stabilize_line", "arc_sliver",
		"mind_pressure", "harmonic_cut", "pressure_wave", "echo_lattice",
		"resonant_insight", "crowned_resolve", "grand_equation", "final_vector",
		"overclock_casting", "measured_blast", "clear_intent", "phase_tap",
		"split_tone", "coordinated_strike", "rhodes_formation", "desperate_focus",
		"crisis_surge", "arc_collapse", "controlled_detonation", "thought_acceleration",
		"widened_spectrum", "tactical_network", "chain_reaction", "emergency_order",
		"dobermann_drill_order", "exusiai_cover_fire", "precise_break", "resonance_field",
		"prism_shatter", "medical_evac_route", "elite_coordination", "tactical_encirclement",
		"harmonic_spike", "reckless_invocation", "ace_last_stand", "black_ring_method",
		"survival_reflex", "will_transfusion", "mirrored_wave", "last_argument",
		"terminal_appeal", "ashes_to_ashes", "frequency_lock", "strategic_rotation",
		"forbidden_formula", "unstable_channel", "collapse_frequency", "feedback_loop",
		"blaze_forward_breach", "greythroat_suppression", "frostleaf_delay_field", "pain_for_power",
		"nerve_burn", "sealed_chimera", "zero_range_cast", "singing_fracture",
		"voice_of_the_team", "shared_burden", "forbidden_crown", "chimera_protocol",
		"the_cost_of_mercy", "resonance_harvest", "harmonic_dominion", "sevenfold_echo",
		"unified_battleplan", "controlled_overload", "voice_of_the_leader", "ashes_remember",
		"final_directive", "absolute_resonance", "landship_wide_order", "ember_judgement",
		"delayed_directive", "primed_arts", "twin_channel", "terminal_charge", "formation_hold", "echo_reserve",
		"command_overflow"
	]

static func get_common_card_reward_pool() -> Array[String]:
	return [
		"tactical_reorder", "focus_pulse", "emergency_shield", "resonance_burst",
		"command_sync", "signal_relay", "guided_fire", "rescue_corridor",
		"discipline_note", "pulse_scan", "guard_pulse", "mental_tuning",
		"field_command", "resonance_mark", "focused_ray", "tactical_briefing",
		"stabilize_line", "arc_sliver", "mind_pressure", "harmonic_cut",
		"pressure_wave", "echo_lattice", "resonant_insight", "overclock_casting",
		"measured_blast", "clear_intent", "phase_tap", "split_tone",
		"coordinated_strike", "desperate_focus", "crisis_surge", "thought_acceleration",
		"chain_reaction", "emergency_order", "dobermann_drill_order", "exusiai_cover_fire",
		"medical_evac_route", "harmonic_spike", "reckless_invocation",
		"frequency_lock", "strategic_rotation", "forbidden_formula", "unstable_channel",
		"nerve_burn", "sealed_chimera", "resonance_harvest", "unified_battleplan",
		"sevenfold_echo", "controlled_overload", "delayed_directive", "primed_arts",
		"twin_channel", "terminal_charge", "echo_reserve"
	]

static func get_uncommon_card_reward_pool() -> Array[String]:
	return [
		"burn_will", "overclock_arts", "tactical_calm", "echo_conduit",
		"bloodline_casting", "channel_pulse", "crowned_resolve",
		"grand_equation", "final_vector", "rhodes_formation",
		"arc_collapse", "controlled_detonation", "widened_spectrum",
		"tactical_network", "precise_break", "resonance_field",
		"prism_shatter", "elite_coordination", "tactical_encirclement",
		"ace_last_stand", "black_ring_method", "survival_reflex",
		"will_transfusion", "mirrored_wave", "last_argument",
		"terminal_appeal", "ashes_to_ashes", "collapse_frequency", "feedback_loop",
		"blaze_forward_breach", "greythroat_suppression", "frostleaf_delay_field",
		"pain_for_power", "zero_range_cast", "singing_fracture", "voice_of_the_team",
		"shared_burden", "forbidden_crown", "chimera_protocol", "the_cost_of_mercy",
		"harmonic_dominion", "voice_of_the_leader", "ashes_remember", "final_directive",
		"absolute_resonance", "landship_wide_order", "ember_judgement", "formation_hold", "command_overflow"
	]

static func get_module_reward_pool() -> Array[String]:
	return [
		"recorder_of_resolve",
		"signal_booster",
		"originium_fragment",
		"field_stabilizer",
		"field_medic_pack",
		"echo_pin",
		"reserve_battery",
		"nearl_crest",
		"kaltsits_log",
		"dobermann_manual",
		"resonance_prism",
		"rhodes_tactical_console",
		"field_command_badge",
		"worn_terminal",
		"support_grid",
		"pain_converter",
		"resonance_anchor",
		"ashen_thread",
		"crown_of_responsibility",
		"ashen_halo"
	]

static func get_charm_reward_pool() -> Array[String]:
	return [
		"rabbit_emblem",
		"rhodes_pin",
		"broken_horn_token",
		"silent_bell",
		"sterile_strap",
		"burnt_paper_charm",
		"operators_thread",
		"embershard"
	]

@warning_ignore("unused_parameter")
static func generate_node_metadata(floor_index: int, node_type: String, index: int, rng: RandomNumberGenerator = null, battle_generation_state: Dictionary = {}) -> Dictionary:
	var data: Dictionary = {}
	var randomizer: RandomNumberGenerator = rng
	if randomizer == null:
		randomizer = RandomNumberGenerator.new()
		randomizer.randomize()
	match node_type:
		"battle":
			var template: Dictionary = pick_battle_template(floor_index, randomizer, battle_generation_state)
			data["enemy_ids"] = template.get("enemy_ids", [])
			data["encounter_tests"] = template.get("tests", [])
			data["encounter_primary_test"] = String(template.get("primary_test", ""))
		"elite":
			data["enemy_ids"] = get_random_elite_enemies(floor_index, randomizer)
		"boss":
			data["enemy_ids"] = get_boss_enemies(floor_index, randomizer)
		"event", "story":
			var events: Array[String] = [
				"temporary_ward", "dobermann_inspection", "nearl_principle", "kaltsit_briefing", "ws_broadcast",
				"tactical_debrief", "medical_supply_crate", "originium_fissure", "withdrawal_dispute",
				"old_operation_record", "operator_assembly", "mental_fluctuation", "broken_comms",
				"overloaded_supply", "kaltsit_silent_assessment", "originium_echo_corridor",
				"emergency_command_chain", "nameless_operator_letter", "midnight_maintenance",
				"footprints_on_ashes", "doctor_question"
			]
			data["event_id"] = events[randomizer.randi_range(0, events.size() - 1)]
	return data

static func pick_battle_template(floor_index: int, rng: RandomNumberGenerator, state: Dictionary) -> Dictionary:
	var templates: Array = get_battle_templates(floor_index)
	if templates.is_empty():
		return {"enemy_ids": get_random_battle_enemies(floor_index, rng), "tests": PackedStringArray(), "primary_test": ""}
	var targets := {
		"rear_threat": 0.30,
		"aoe": 0.25,
		"armor": 0.20
	}
	var battle_count: int = int(state.get("battle_count", 0))
	var test_counts: Dictionary = state.get("test_counts", {})
	var recent_primary: Array[String] = []
	for entry in state.get("recent_primary_tests", []):
		recent_primary.append(String(entry))
	var weighted_templates: Array[Dictionary] = []
	var total_weight: float = 0.0
	for template in templates:
		var weight: float = float(template.get("weight", 1.0))
		var tests: Array = template.get("tests", [])
		var primary_test: String = String(template.get("primary_test", ""))
		if recent_primary.size() >= 2 and recent_primary[recent_primary.size() - 1] == primary_test and recent_primary[recent_primary.size() - 2] == primary_test:
			weight *= 0.05
		for test_name_variant in tests:
			var test_name: String = String(test_name_variant)
			if targets.has(test_name):
				var current_ratio: float = float(int(test_counts.get(test_name, 0))) / max(1.0, float(max(1, battle_count)))
				if current_ratio < float(targets[test_name]):
					weight *= 1.45
				elif current_ratio > float(targets[test_name]) + 0.10:
					weight *= 0.82
		if floor_index == 1 and tests.has("aoe"):
			weight *= 1.15
		total_weight += weight
		weighted_templates.append({"template": template, "weight": weight})
	var roll: float = rng.randf() * max(total_weight, 0.001)
	var chosen: Dictionary = templates[0]
	for entry in weighted_templates:
		roll -= float(entry.get("weight", 1.0))
		if roll <= 0.0:
			chosen = entry.get("template", chosen)
			break
	state["battle_count"] = battle_count + 1
	for test_name_variant in chosen.get("tests", []):
		var test_name: String = String(test_name_variant)
		test_counts[test_name] = int(test_counts.get(test_name, 0)) + 1
	state["test_counts"] = test_counts
	recent_primary.append(String(chosen.get("primary_test", "")))
	while recent_primary.size() > 2:
		recent_primary.pop_front()
	state["recent_primary_tests"] = recent_primary
	return chosen

static func get_battle_templates(floor_index: int) -> Array:
	var templates := {
		1: [
			{"enemy_ids": ["reunion_scout"], "tests": ["tempo"], "primary_test": "tempo", "weight": 0.8},
			{"enemy_ids": ["reunion_caster"], "tests": ["rear_threat", "point_kill"], "primary_test": "rear_threat", "weight": 1.0},
			{"enemy_ids": ["reunion_bladefighter"], "tests": ["tempo"], "primary_test": "tempo", "weight": 0.8},
			{"enemy_ids": ["molotov_thrower"], "tests": ["rear_threat", "attrition"], "primary_test": "rear_threat", "weight": 1.0},
			{"enemy_ids": ["originium_slug", "originium_slug", "blazing_originium_slug"], "tests": ["aoe", "kill_order"], "primary_test": "aoe", "weight": 1.2},
			{"enemy_ids": ["slug_broodmother", "originium_slug", "originium_slug"], "tests": ["aoe", "point_kill"], "primary_test": "aoe", "weight": 1.15},
			{"enemy_ids": ["riot_shieldbearer", "originium_slug", "originium_slug", "originium_slug"], "tests": ["armor", "aoe"], "primary_test": "armor", "weight": 1.1},
			{"enemy_ids": ["reunion_scout", "reunion_caster"], "tests": ["rear_threat"], "primary_test": "rear_threat", "weight": 1.0},
			{"enemy_ids": ["stone_throwing_rioter", "originium_slug_alpha"], "tests": ["armor"], "primary_test": "armor", "weight": 0.9}
		],
		2: [
			{"enemy_ids": ["riot_shieldbearer", "crossbow_sniper"], "tests": ["armor", "rear_threat"], "primary_test": "armor", "weight": 1.1},
			{"enemy_ids": ["reunion_medic", "reunion_caster"], "tests": ["rear_threat", "point_kill"], "primary_test": "rear_threat", "weight": 1.1},
			{"enemy_ids": ["demolition_runner", "reunion_scout"], "tests": ["burst", "point_kill"], "primary_test": "burst", "weight": 0.95},
			{"enemy_ids": ["drone_support_unit", "drone_support_unit", "crossbow_sniper"], "tests": ["aoe", "rear_threat"], "primary_test": "aoe", "weight": 1.15},
			{"enemy_ids": ["acid_originium_slug", "originium_slug_alpha", "originium_slug"], "tests": ["aoe", "armor"], "primary_test": "aoe", "weight": 1.1},
			{"enemy_ids": ["infected_fanatic", "mortar_crossbow_operator"], "tests": ["burst", "rear_threat"], "primary_test": "burst", "weight": 1.0}
		],
		3: [
			{"enemy_ids": ["crossbow_sniper", "reunion_bugler"], "tests": ["rear_threat", "tempo"], "primary_test": "rear_threat", "weight": 1.05},
			{"enemy_ids": ["originium_porter", "originium_pollutant"], "tests": ["attrition", "tempo"], "primary_test": "attrition", "weight": 1.0},
			{"enemy_ids": ["alley_arsonist", "disguised_scout"], "tests": ["tempo", "attrition"], "primary_test": "tempo", "weight": 0.95},
			{"enemy_ids": ["blazing_originium_slug", "originium_slug", "originium_slug_alpha"], "tests": ["aoe", "kill_order"], "primary_test": "aoe", "weight": 1.1},
			{"enemy_ids": ["slug_broodmother", "acid_originium_slug", "originium_slug"], "tests": ["aoe", "point_kill"], "primary_test": "aoe", "weight": 1.12},
			{"enemy_ids": ["riot_shieldbearer", "frostbite_stalker"], "tests": ["armor", "tempo"], "primary_test": "armor", "weight": 1.0}
		],
		4: [
			{"enemy_ids": ["originium_channeler", "originium_pollutant"], "tests": ["tempo", "rear_threat"], "primary_test": "tempo", "weight": 1.0},
			{"enemy_ids": ["blazing_originium_slug", "slug_broodmother", "originium_slug"], "tests": ["aoe", "kill_order"], "primary_test": "aoe", "weight": 1.15},
			{"enemy_ids": ["riot_shieldbearer", "crossbow_sniper"], "tests": ["armor", "rear_threat"], "primary_test": "armor", "weight": 1.05}
		]
	}
	return templates.get(floor_index, templates[1])

static func get_random_battle_enemies(floor_index: int, rng: RandomNumberGenerator) -> Array[String]:
	var pools := {
		1: [
			["reunion_scout"],
			["reunion_caster"],
			["reunion_bladefighter"],
			["stone_throwing_rioter"],
			["molotov_thrower"],
			["originium_slug"],
			["originium_slug_alpha"]
		],
		2: [
			["riot_shieldbearer"],
			["crossbow_sniper"],
			["reunion_caster"],
			["demolition_runner"],
			["reunion_medic"],
			["mortar_crossbow_operator"],
			["infected_fanatic"],
			["drone_support_unit"],
			["acid_originium_slug"]
		],
		3: [
			["crossbow_sniper"],
			["riot_shieldbearer"],
			["originium_porter"],
			["alley_arsonist"],
			["disguised_scout"],
			["reunion_bugler"],
			["frostbite_stalker"],
			["originium_pollutant"],
			["blazing_originium_slug"],
			["slug_broodmother"]
		],
		4: [
			["riot_shieldbearer"],
			["crossbow_sniper"],
			["originium_channeler"],
			["originium_pollutant"],
			["blazing_originium_slug"],
			["slug_broodmother"]
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
		1: [["field_captain"], ["barricade_heavy_leader"], ["execution_demolitionist"]],
		2: [["field_captain"], ["originium_channeler"], ["hunter_sniper_officer"], ["formation_caster"], ["slug_hive_colossus"]],
		3: [["originium_channeler"], ["field_captain"], ["frenzied_smasher"], ["snowfield_ambush_captain"], ["formation_caster"]],
		4: [["originium_channeler"], ["slug_hive_colossus"], ["frenzied_smasher"]]
	}
	var options: Array = pools.get(floor_index, pools[1])
	var selected: Array = options[rng.randi_range(0, options.size() - 1)]
	var result: Array[String] = []
	for enemy_id in selected:
		result.append(String(enemy_id))
	return result

static func get_boss_enemies(floor_index: int, rng: RandomNumberGenerator = null) -> Array[String]:
	var randomizer: RandomNumberGenerator = rng
	if randomizer == null:
		randomizer = RandomNumberGenerator.new()
		randomizer.randomize()
	var result: Array[String] = []
	if floor_index == 1:
		var floor_one_options: Array[String] = ["scout_chief", "reunion_assault_commander"]
		result.append(floor_one_options[randomizer.randi_range(0, floor_one_options.size() - 1)])
		return result
	if floor_index == 2:
		var floor_two_options: Array[String] = ["lockdown_core", "chernobog_suppression_convoy", "originium_aberration_cluster"]
		result.append(floor_two_options[randomizer.randi_range(0, floor_two_options.size() - 1)])
		return result
	if floor_index == 3:
		result.append("w_boss")
		return result
	result.append("ash_echo")
	return result
