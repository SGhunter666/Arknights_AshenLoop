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
