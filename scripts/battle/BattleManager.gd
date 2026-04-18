class_name BattleManager
extends Node

signal battle_started
signal turn_started(side: String)
signal hand_changed
signal cards_drawn(cards: Array[CardData], source: String)
signal enemy_intents_updated
signal battle_ended(victory: bool)
signal log_message(text: String)
signal state_changed

@export var player_character: CharacterData
@export var enemy_list: Array[EnemyData] = []

var player: UnitState
var enemies: Array[UnitState] = []
var enemy_datas: Array[EnemyData] = []
var deck: DeckController = DeckController.new()
var resolver: EffectResolver = EffectResolver.new(self)
var enemy_ai: EnemyAI = EnemyAI.new()
var turn_count: int = 0
var player_resource_max: int = 10
var card_db: Dictionary = {}
var module_db: Dictionary = {}
var hand_size: int = 5
var first_card_tax_pending: bool = false
var active_side: String = "player"
var auto_end_queued: bool = false
var battle_finished: bool = false
var RunManager = null
var LocalizationManager = null
var SfxManager = null
var SceneRouter = null
var SettingsManager = null

func _ready() -> void:
	_bind_dependencies()
	resolver.effect_resolved.connect(_on_effect_resolved)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		dispose_runtime_state()

func configure(char_data: CharacterData, enemies_for_battle: Array[EnemyData]) -> void:
	player_character = char_data
	enemy_list = enemies_for_battle
	start_battle()

func start_battle() -> void:
	_bind_dependencies()
	_load_databases()
	_setup_player()
	_setup_enemies()
	var node_seed: int = 0
	var active_node: MapNodeModel = RunManager.current_node()
	if active_node != null:
		node_seed = active_node.id.hash()
	deck.setup(RunManager.deck, card_db, RunManager.rng_seed + node_seed + RunManager.current_floor)
	turn_count = 0
	first_card_tax_pending = false
	battle_finished = false
	battle_started.emit()
	var actor_name: String = LocalizationManager.character_name(player_character.id, player_character.display_name)
	log_message.emit(LocalizationManager.text("battle.log.start", [actor_name]))
	start_player_turn()

func _bind_dependencies() -> void:
	var tree: SceneTree = null
	if is_inside_tree():
		tree = get_tree()
	if tree != null:
		if RunManager == null:
			RunManager = tree.root.get_node_or_null("RunManager")
		if LocalizationManager == null:
			LocalizationManager = tree.root.get_node_or_null("LocalizationManager")
		if SfxManager == null:
			SfxManager = tree.root.get_node_or_null("SfxManager")
		if SceneRouter == null:
			SceneRouter = tree.root.get_node_or_null("SceneRouter")
		if SettingsManager == null:
			SettingsManager = tree.root.get_node_or_null("SettingsManager")
	var main_loop := Engine.get_main_loop()
	if main_loop is SceneTree:
		var root_node: Node = (main_loop as SceneTree).root
		if RunManager == null:
			RunManager = root_node.get_node_or_null("RunManager")
		if LocalizationManager == null:
			LocalizationManager = root_node.get_node_or_null("LocalizationManager")
		if SfxManager == null:
			SfxManager = root_node.get_node_or_null("SfxManager")
		if SceneRouter == null:
			SceneRouter = root_node.get_node_or_null("SceneRouter")
		if SettingsManager == null:
			SettingsManager = root_node.get_node_or_null("SettingsManager")

func _load_databases() -> void:
	card_db = Util.load_card_db()
	module_db = Util.load_module_db()

func dispose_runtime_state() -> void:
	if resolver != null:
		if resolver.effect_resolved.is_connected(_on_effect_resolved):
			resolver.effect_resolved.disconnect(_on_effect_resolved)
		resolver.clear_runtime_refs()
	if enemy_ai != null:
		enemy_ai.RunManager = null
	if deck != null:
		deck.draw_pile.clear()
		deck.hand.clear()
		deck.discard_pile.clear()
		deck.exhaust_pile.clear()
		deck.next_tag_cost_delta.clear()
	card_db.clear()
	module_db.clear()
	enemies.clear()
	enemy_datas.clear()
	enemy_list.clear()
	player = null
	player_character = null
	RunManager = null
	LocalizationManager = null
	SfxManager = null
	SceneRouter = null
	SettingsManager = null

func _setup_player() -> void:
	player = UnitState.new()
	player.id = player_character.id
	player.display_name = player_character.display_name
	player.max_hp = RunManager.max_hp
	player.hp = RunManager.hp
	player.energy = player_character.starting_energy
	player.will = 0
	player_resource_max = player_character.resource_max
	player.max_ammo = player_character.resource_max if player_character.id == "exusiai" else 0
	if player_character.id == "exusiai" and _has_relic("ex_m07_spare_pouch"):
		player.max_ammo += 1
	player.ammo = player.max_ammo
	if _has_relic("crown_of_responsibility"):
		player_resource_max += 3
	player.meta["signal_booster_used_battle"] = false
	player.meta["echo_pin_used_battle"] = false
	player.meta["kaltsits_log_used_battle"] = false
	player.meta["rhodes_pin_used_battle"] = false
	player.meta["silent_bell_used_battle"] = false
	player.meta["delivery_badge_used_battle"] = false
	player.meta["red_dot_pendant_used_battle"] = false
	player.meta["storm_permit_used_battle"] = false
	player.meta["ashen_halo_used_battle"] = false
	player.meta["ashen_halo_prevent_tick_once"] = false
	player.meta["tune_channel_quickcast_used_battle"] = false
	player.meta["next_turn_hand_size"] = 5
	player.meta["started_with_extra_ammo"] = false

func _setup_enemies() -> void:
	enemies.clear()
	enemy_datas = enemy_list.duplicate()
	var bonus_hp: int = _enemy_hp_bonus_for_active_node()
	for ed in enemy_datas:
		var e: UnitState = UnitState.new()
		e.id = ed.id
		e.display_name = ed.display_name
		e.max_hp = ed.max_hp + bonus_hp
		e.hp = e.max_hp
		enemies.append(e)

func _enemy_hp_bonus_for_active_node() -> int:
	if RunManager == null:
		return 0
	var floor_index: int = int(RunManager.current_floor)
	if floor_index < 2 or floor_index > 3:
		return 0
	return 30 if floor_index == 2 else 50

func start_player_turn() -> void:
	active_side = "player"
	turn_count += 1
	player.energy = player_character.starting_energy
	player.burst_active = false
	hand_size = int(player.meta.get("next_turn_hand_size", 5))
	player.meta["next_turn_hand_size"] = 5
	if RunManager.modules.has("reserve_battery") and turn_count == 1:
		player.energy += 1
	player.meta["support_played_this_turn"] = false
	player.meta["played_support_this_turn"] = 0
	player.meta["support_trigger_ready"] = false
	player.meta["field_command_badge_used_turn"] = false
	player.meta["originium_fragment_used_turn"] = false
	player.meta["support_grid_used_turn"] = false
	player.meta["command_overflow_active"] = false
	player.meta["operators_thread_used_turn"] = false
	player.meta["duplicate_support_after_resolve"] = false
	player.meta["rewire_arts_bonus_used_turn"] = false
	player.meta["tune_will_arts_discount_used_turn"] = false
	player.meta["tune_overload_guard_used_turn"] = false
	player.meta["next_tag_damage_bonus"] = {}
	player.meta["cards_played_this_turn"] = 0
	player.meta["w_third_triggered_this_turn"] = false
	player.meta["played_arts_this_turn"] = false
	player.meta["gained_will_this_turn"] = false
	player.meta["lost_hp_this_turn"] = 0
	player.meta["no_block_this_turn"] = false
	player.meta["shared_burden_used"] = false
	player.meta["battleplan_support_cost_reduction"] = 0
	player.meta["battleplan_support_draw_bonus"] = 0
	player.meta["battleplan_first_support_pending"] = false
	player.meta["final_directive_active"] = false
	player.meta["luminous_guard_used_turn"] = false
	player.meta["cover_fire_lead_used_turn"] = false
	player.meta["cold_analysis_used_turn"] = false
	player.meta["first_ammo_spent_used_turn"] = false
	player.meta["played_shot_this_turn"] = 0
	player.meta["spent_ammo_this_turn"] = 0
	player.meta["restored_ammo_this_turn"] = 0
	player.meta["shot_damage_bonus_turn"] = 0
	player.meta["next_shot_damage_bonus"] = int(player.meta.get("next_shot_damage_bonus_persistent", 0))
	player.meta["next_shot_damage_bonus_charges"] = int(player.meta.get("next_shot_damage_bonus_charges_persistent", 0))
	player.meta["burst_shot_damage_bonus"] = 0
	player.meta["turn_shot_cost_reduction"] = int(player.meta.get("turn_shot_cost_reduction_persistent", 0))
	player.meta["next_shot_cost_reduction"] = int(player.meta.get("next_shot_cost_reduction_persistent", 0))
	player.meta["next_shot_cost_reduction_charges"] = int(player.meta.get("next_shot_cost_reduction_charges_persistent", 0))
	player.meta["marked_target_bonus_damage"] = int(player.meta.get("marked_target_bonus_damage_static", 0))
	player.meta["first_shot_vs_mark_bonus_pending"] = false
	player.meta["first_shot_vs_mark_bonus"] = int(player.meta.get("first_shot_vs_mark_bonus_static", 0))
	player.meta["headline_rhythm_triggers_turn"] = 0
	player.meta["fast_tempo_triggered_turn"] = false
	player.meta["ammo_refill_draw_first_used_turn"] = false
	player.meta["ammo_three_energy_used_turn"] = false
	player.meta["target_scope_used_turn"] = false
	player.meta["gunfire_cross_used_turn"] = false
	player.meta["hunter_clearance_used_turn"] = false
	player.meta["hunter_clearance_active_card"] = false
	player.meta["command_delay_active"] = false
	player.meta["overheated_bolt_active"] = false
	player.meta["fire_frenzy_active"] = false
	player.meta["fire_frenzy_bonus"] = 0
	for enemy in enemies:
		enemy.meta["took_support_damage_this_turn"] = false
	_apply_start_of_turn_modules()
	_resolve_reload_queue("next_turn_start")
	_resolve_pending_channels()
	if bool(player.meta.get("harmonic_dominion_active", false)):
		var random_enemy: UnitState = _first_living_enemy()
		if random_enemy != null:
			random_enemy.add_resonance(1)
	var bonus_draw_next_turn: int = int(player.meta.get("bonus_draw_next_turn", 0))
	var draw_count: int = max(0, hand_size + bonus_draw_next_turn)
	_draw_cards(draw_count, "turn_start")
	player.meta["bonus_draw_next_turn"] = 0
	_apply_draw_curse_penalties()
	turn_started.emit("player")
	_refresh_enemy_intents_if_needed()
	hand_changed.emit()
	state_changed.emit()
	_queue_auto_end_turn_check()

func end_player_turn() -> void:
	player.meta["command_overflow_active"] = false
	for i in range(deck.hand.size() - 1, -1, -1):
		var card: CardData = deck.hand[i]
		if card.id == "hesitation":
			player.will = max(0, player.will - 1)
		elif card.id == "blast_countdown":
			if SfxManager != null:
				SfxManager.play_explosion()
			player.lose_hp(8)
			log_message.emit(LocalizationManager.text("battle.log.countdown"))
		elif card.id == "burn":
			player.lose_hp(2)
			log_message.emit(LocalizationManager.text("battle.log.burn"))
		elif card.id == "overloaded_nerves":
			var overload_effect: EffectData = EffectData.new()
			overload_effect.effect_type = "gain_overload"
			overload_effect.amount = 1
			resolver.resolve_effect(overload_effect, player, player)
			player.meta["bonus_draw_next_turn"] = int(player.meta.get("bonus_draw_next_turn", 0)) + 1
			log_message.emit(LocalizationManager.text("battle.log.overloaded_nerves"))
			deck.send_to_exhaust(deck.hand.pop_at(i))
		elif card.id == "mental_noise":
			if not bool(player.meta.get("gained_will_this_turn", false)):
				player.meta["bonus_draw_next_turn"] = int(player.meta.get("bonus_draw_next_turn", 0)) - 1
			deck.send_to_exhaust(deck.hand.pop_at(i))
		elif card.id == "ashen_guilt":
			if int(player.meta.get("lost_hp_this_turn", 0)) > 0:
				player.lose_hp(1)
			deck.send_to_exhaust(deck.hand.pop_at(i))
	if bool(player.meta.get("forbidden_crown_active", false)):
		var crown_effect: EffectData = EffectData.new()
		crown_effect.effect_type = "gain_overload"
		crown_effect.amount = 1
		resolver.resolve_effect(crown_effect, player, player)
		log_message.emit(LocalizationManager.text("battle.log.forbidden_crown"))
	_resolve_turn_end_channels()
	if _has_relic("ex_m08_highspeed_loader") and player.ammo <= 1:
		var loader_before: int = player.ammo
		player.gain_ammo(2)
		var loader_restored: int = max(0, player.ammo - loader_before)
		if loader_restored > 0:
			_on_effect_resolved("gain_ammo", {"amount": loader_restored, "source": player})
			log_message.emit("高速装填器启动，恢复 %d 点弹药。" % loader_restored)
	_resolve_reload_queue("turn_end")
	player.burst_active = false
	if _has_relic("field_stabilizer") and player.energy > 0:
		player.add_block(player.energy)
	if _has_relic("crown_of_responsibility"):
		player.lose_hp(1)
	_on_overload_tick()
	if player.is_dead():
		_end_battle(false)
		return
	deck.discard_hand()
	_tick_status_decay(player)
	_resolve_enemy_turn()

func play_card(hand_index: int, target_index: int = 0) -> bool:
	if battle_finished:
		return false
	var card: CardData = deck.play_from_hand(hand_index)
	if card == null:
		return false
	var counts_as_support: bool = _card_has_effective_tag(card, "Support")
	var counts_as_arts: bool = _card_has_effective_tag(card, "Arts")
	var counts_as_channel: bool = _card_has_effective_tag(card, "Channel")
	var counts_as_shot: bool = _card_has_effective_tag(card, "Shot")
	var actual_cost: int = current_card_cost(card)
	if player.energy < actual_cost:
		deck.hand.insert(hand_index, card)
		return false

	player.energy -= actual_cost
	first_card_tax_pending = false
	if counts_as_arts and RunManager.has_tune("will_arts_discount") and player.will >= 4:
		player.meta["tune_will_arts_discount_used_turn"] = true
	player.meta["cards_played_this_turn"] = int(player.meta.get("cards_played_this_turn", 0)) + 1
	var target: UnitState = null
	if target_index >= 0 and target_index < enemies.size():
		target = enemies[target_index]
	elif not enemies.is_empty():
		target = enemies[0]
	player.meta["hunter_clearance_active_card"] = counts_as_shot and target != null and target.mark > 0 and _has_relic("ex_m14_hunter_clearance") and not bool(player.meta.get("hunter_clearance_used_turn", false))

	if counts_as_arts:
		player.meta["played_arts_this_turn"] = true
	if counts_as_shot:
		player.meta["played_shot_this_turn"] = int(player.meta.get("played_shot_this_turn", 0)) + 1
	_apply_passives_before_card(card)
	resolver.resolve_card(card, player, target)
	if bool(player.meta.get("duplicate_support_after_resolve", false)):
		player.meta["duplicate_support_after_resolve"] = false
		resolver.resolve_card(card, player, target)
	if _has_relic("ex_m10_tempo_pedal") and int(player.meta.get("cards_played_this_turn", 0)) == 3:
		_draw_cards(1, "tempo_pedal")
	if counts_as_channel and _has_relic("kaltsits_log") and not bool(player.meta.get("kaltsits_log_used_battle", false)):
		_draw_cards(2, "kaltsits_log")
		player.meta["kaltsits_log_used_battle"] = true
	if counts_as_channel and RunManager.has_tune("channel_quickcast") and not bool(player.meta.get("tune_channel_quickcast_used_battle", false)):
		_draw_cards(1, "tune_channel_quickcast")
		player.gain_will(1, player_resource_max)
		player.meta["tune_channel_quickcast_used_battle"] = true
		log_message.emit("调律【预演快启】启动：首张 Channel 额外抽 1，并获得 1 点意志。")
	if card.exhausts or card.ethereal:
		deck.send_to_exhaust(card)
	else:
		deck.send_to_discard(card)
	_consume_post_play_bonuses(card)
	_apply_rule_shift_after_card()
	_cleanup_dead_enemies()
	hand_changed.emit()
	state_changed.emit()

	if enemies.is_empty():
		_end_battle(true)
	else:
		_queue_auto_end_turn_check()
	return true

func current_card_cost(card: CardData) -> int:
	if card == null:
		return 0
	var counts_as_support: bool = _card_has_effective_tag(card, "Support")
	var counts_as_arts: bool = _card_has_effective_tag(card, "Arts")
	var counts_as_shot: bool = _card_has_effective_tag(card, "Shot")
	var counts_as_reload: bool = "Reload" in card.tags
	var actual_cost: int = deck.effective_cost(card)
	if first_card_tax_pending:
		actual_cost += 1
	if counts_as_support:
		actual_cost = max(0, actual_cost - int(player.meta.get("battleplan_support_cost_reduction", 0)))
	if counts_as_arts and RunManager.has_tune("will_arts_discount") and player.will >= 4 and not bool(player.meta.get("tune_will_arts_discount_used_turn", false)):
		actual_cost = max(0, actual_cost - 1)
	if counts_as_reload and _has_relic("ex_h05_spare_mag") and player.ammo <= 0:
		actual_cost = max(0, actual_cost - 1)
	if counts_as_shot:
		actual_cost = max(0, actual_cost - int(player.meta.get("turn_shot_cost_reduction", 0)))
		actual_cost = max(0, actual_cost - int(player.meta.get("next_shot_cost_reduction", 0)))
	return actual_cost

func can_play_card(card: CardData) -> bool:
	if player == null or card == null:
		return false
	return player.energy >= current_card_cost(card)

func _resolve_enemy_turn() -> void:
	if battle_finished:
		return
	active_side = "enemy"
	turn_started.emit("enemy")
	for i in range(enemies.size()):
		var e: UnitState = enemies[i]
		if e.is_dead():
			continue
		var ed: EnemyData = enemy_datas[i]
		var intent: Dictionary = e.intent if not e.intent.is_empty() else enemy_ai.next_intent(e, ed, turn_count)
		e.intent = intent
		_execute_enemy_intent(e, intent)
		_tick_status_decay(e)
		if player.is_dead():
			_end_battle(false)
			return

	_cleanup_dead_enemies()
	if enemies.is_empty():
		_end_battle(true)
		return

	_decay_enemy_resonance()
	_decay_enemy_marks()
	start_player_turn()

func _execute_enemy_intent(enemy: UnitState, intent: Dictionary) -> void:
	match String(intent.get("type", "attack")):
		"attack":
			var dmg: int = int(intent.get("value", 6))
			var temp_effect: EffectData = EffectData.new()
			temp_effect.effect_type = "damage"
			temp_effect.amount = dmg
			resolver.resolve_effect(temp_effect, enemy, player)
		"apply_curse":
			var curse_count: int = max(1, int(intent.get("value", 1)))
			for _index in range(curse_count):
				_insert_curse_into_discard(String(intent.get("curse", "hesitation")))
			log_message.emit(LocalizationManager.text("battle.log.curse", [LocalizationManager.enemy_name(enemy.id, enemy.display_name)]))
		"shuffle_and_debuff":
			deck.shuffle_draw()
			if enemy == null or enemy.id != "w_boss":
				player.apply_status("weak", 1)
			if enemy == null or enemy.id != "w_boss":
				first_card_tax_pending = true
			log_message.emit(LocalizationManager.text("battle.log.disrupt", [LocalizationManager.enemy_name(enemy.id, enemy.display_name)]))
		"rule_shift":
			_apply_w_rule(String(intent.get("rule", "")))
		"gain_block":
			var block_amount: int = int(intent.get("value", 8))
			enemy.add_block(block_amount)
			log_message.emit(LocalizationManager.text("battle.log.enemy_block", [LocalizationManager.enemy_name(enemy.id, enemy.display_name), block_amount]))
		"apply_debuff":
			var debuff_id: String = String(intent.get("status", "weak"))
			var debuff_amount: int = max(1, int(intent.get("value", 1)))
			player.apply_status(debuff_id, debuff_amount)
			log_message.emit(LocalizationManager.text("battle.log.enemy_debuff", [LocalizationManager.enemy_name(enemy.id, enemy.display_name)]))
		"charge":
			enemy.meta["charged_damage"] = int(enemy.meta.get("charged_damage", 0)) + int(intent.get("value", 12))
			log_message.emit(LocalizationManager.text("battle.log.enemy_charge", [LocalizationManager.enemy_name(enemy.id, enemy.display_name)]))
		"release":
			var charged: int = int(enemy.meta.get("charged_damage", 0))
			if charged > 0:
				var temp_release: EffectData = EffectData.new()
				temp_release.effect_type = "damage"
				temp_release.amount = charged
				resolver.resolve_effect(temp_release, enemy, player)
				enemy.meta["charged_damage"] = 0
			log_message.emit(LocalizationManager.text("battle.log.enemy_release", [LocalizationManager.enemy_name(enemy.id, enemy.display_name), charged]))
		_:
			log_message.emit(LocalizationManager.text("battle.log.enemy_idle"))
	state_changed.emit()

func _apply_passives_before_card(card: CardData) -> void:
	var counts_as_support: bool = _card_has_effective_tag(card, "Support")
	var counts_as_arts: bool = _card_has_effective_tag(card, "Arts")
	var counts_as_shot: bool = _card_has_effective_tag(card, "Shot")
	var has_amiya_passive: bool = player_character != null and player_character.passive_id == "leader_of_rhodes"
	var has_nearl_passive: bool = player_character != null and player_character.passive_id == "luminous_guard"
	var has_kaltsit_passive: bool = player_character != null and player_character.passive_id == "cold_analysis"
	var is_attack_card: bool = card != null and card.card_type == "Attack"
	var has_block_effect: bool = false
	if card != null:
		for effect in card.effects:
			if effect != null and effect.effect_type == "gain_block":
				has_block_effect = true
				break
	if counts_as_arts and _has_relic("originium_fragment") and not bool(player.meta.get("originium_fragment_used_turn", false)):
		var arts_bonus: Dictionary = player.meta.get("next_tag_damage_bonus", {})
		arts_bonus["Arts"] = int(arts_bonus.get("Arts", 0)) + 2
		player.meta["next_tag_damage_bonus"] = arts_bonus
		player.meta["originium_fragment_used_turn"] = true
	if counts_as_arts and RunManager.has_flag("rewire_arts_bonus") and not bool(player.meta.get("rewire_arts_bonus_used_turn", false)):
		var rewire_bonus: Dictionary = player.meta.get("next_tag_damage_bonus", {})
		rewire_bonus["Arts"] = int(rewire_bonus.get("Arts", 0)) + 2
		player.meta["next_tag_damage_bonus"] = rewire_bonus
		player.meta["rewire_arts_bonus_used_turn"] = true
	if counts_as_arts and _has_relic("pain_converter") and int(player.meta.get("pain_converter_bonus", 0)) > 0:
		var pain_bonus: Dictionary = player.meta.get("next_tag_damage_bonus", {})
		pain_bonus["Arts"] = int(pain_bonus.get("Arts", 0)) + int(player.meta.get("pain_converter_bonus", 0))
		player.meta["next_tag_damage_bonus"] = pain_bonus
		player.meta["pain_converter_bonus"] = 0
	if has_nearl_passive and has_block_effect and not bool(player.meta.get("luminous_guard_used_turn", false)):
		player.add_block(4)
		player.meta["luminous_guard_used_turn"] = true
		log_message.emit(LocalizationManager.text("battle.log.luminous_guard"))
	if has_kaltsit_passive and (counts_as_support or _card_has_effective_tag(card, "Channel")) and not bool(player.meta.get("cold_analysis_used_turn", false)):
		_draw_cards(1, "cold_analysis")
		player.meta["cold_analysis_used_turn"] = true
		log_message.emit(LocalizationManager.text("battle.log.cold_analysis"))
	if counts_as_shot and bool(player.meta.get("first_shot_vs_mark_bonus_pending", false)):
		player.meta["first_shot_vs_mark_bonus_pending"] = false
	if counts_as_support:
		var support_count_before: int = int(player.meta.get("played_support_this_turn", 0))
		var support_count: int = support_count_before + 1
		var support_counted: bool = true
		if bool(player.meta.get("command_delay_active", false)) and support_count_before == 0:
			player.meta["command_delay_active"] = false
			support_count = support_count_before
			support_counted = false
		else:
			player.meta["played_support_this_turn"] = support_count
			player.meta["played_support_this_battle"] = int(player.meta.get("played_support_this_battle", 0)) + 1
		if bool(player.meta.get("elite_coordination_active", false)):
			var elite_bonus: Dictionary = player.meta.get("next_tag_damage_bonus", {})
			elite_bonus["Arts"] = int(elite_bonus.get("Arts", 0)) + 2
			player.meta["next_tag_damage_bonus"] = elite_bonus
		if bool(player.meta.get("rhodes_formation_active", false)):
			player.add_block(3)
			log_message.emit(LocalizationManager.text("battle.log.rhodes_formation"))
		if bool(player.meta.get("battleplan_first_support_pending", false)) and support_count_before == 0:
			_draw_cards(int(player.meta.get("battleplan_support_draw_bonus", 2)), "battleplan_support")
			player.meta["battleplan_first_support_pending"] = false
		if support_count == 1 and support_counted and has_amiya_passive:
			player.meta["support_trigger_ready"] = true
			var next_bonus: Dictionary = player.meta.get("next_tag_damage_bonus", {})
			next_bonus["Arts"] = int(next_bonus.get("Arts", 0)) + 2
			player.meta["next_tag_damage_bonus"] = next_bonus
			log_message.emit(LocalizationManager.text("battle.log.leader_ready"))
			if RunManager.modules.has("signal_booster") and not bool(player.meta.get("signal_booster_used_battle", false)):
				_draw_cards(1, "signal_booster")
				player.meta["signal_booster_used_battle"] = true
				log_message.emit(LocalizationManager.text("battle.log.signal_booster"))
			if bool(player.meta.get("tactical_network_active", false)):
				player.energy += 1
				log_message.emit(LocalizationManager.text("battle.log.tactical_network"))
			if RunManager.modules.has("field_command_badge") and not bool(player.meta.get("field_command_badge_used_turn", false)):
				player.energy += 1
				player.meta["field_command_badge_used_turn"] = true
				RunManager.set_flag("used_field_command_badge", true)
				log_message.emit(LocalizationManager.text("battle.log.field_command_badge"))
			if _has_relic("rhodes_pin") and not bool(player.meta.get("rhodes_pin_used_battle", false)):
				player.energy += 1
				player.meta["rhodes_pin_used_battle"] = true
			if _has_relic("ex_h04_delivery_badge") and not bool(player.meta.get("delivery_badge_used_battle", false)):
				player.meta["delivery_badge_used_battle"] = true
				_draw_cards(1, "delivery_badge")
			if RunManager.has_tune("support_echo_seed"):
				player.echo_percent = max(player.echo_percent, 50)
				log_message.emit("调律【指挥回响】启动：下一张 Arts 获得 Echo 50%。")
			if _has_relic("support_grid") and not bool(player.meta.get("support_grid_used_turn", false)):
				player.meta["duplicate_support_after_resolve"] = true
				player.meta["support_grid_used_turn"] = true
			if bool(player.meta.get("command_overflow_active", false)):
				player.meta["duplicate_support_after_resolve"] = true
			if _has_relic("ex_m05_penguin_invoice"):
				player.add_block(1)
				player.gain_ammo(1)
			if bool(player.meta.get("formation_hold_active", false)):
				var queue: Array = player.meta.get("channel_queue", [])
				queue.append({
					"type": "block",
					"timing": "next_turn_start",
					"block": int(player.meta.get("formation_hold_block", 3))
				})
				player.meta["channel_queue"] = queue
			var support_draw_trigger: int = int(player.meta.get("support_draw_trigger", 0))
			if support_draw_trigger > 0:
				_draw_cards(support_draw_trigger, "support_trigger")
				player.meta["support_draw_trigger"] = 0
		if support_counted and support_count == 2 and _has_relic("operators_thread") and not bool(player.meta.get("operators_thread_used_turn", false)):
			deck.next_card_cost_delta -= 1
			player.meta["operators_thread_used_turn"] = true
		if bool(player.meta.get("voice_of_the_team_active", false)) and support_counted and support_count % 2 == 0:
			_add_temporary_arts_to_hand(0, false)
		var support_count_battle: int = int(player.meta.get("played_support_this_battle", 0))
		if bool(player.meta.get("voice_of_the_leader_active", false)) and support_counted and support_count_battle > 0 and support_count_battle % 2 == 0:
			_add_temporary_arts_to_hand(0, true)
		player.meta["support_played_this_turn"] = true
	elif counts_as_arts and bool(player.meta.get("support_trigger_ready", false)):
		pass
	if RunManager.modules.has("ashen_thread") and counts_as_arts and bool(player.meta.get("after_self_damage", false)):
		var bonus: EffectData = EffectData.new()
		bonus.effect_type = "damage"
		bonus.amount = 3
		var target: UnitState = enemies[0] if not enemies.is_empty() else null
		resolver.resolve_effect(bonus, player, target, card)
		player.meta["after_self_damage"] = false

func _card_has_effective_tag(card: CardData, tag: String) -> bool:
	if card == null:
		return false
	if tag in card.tags:
		return true
	if bool(player.meta.get("final_directive_active", false)):
		var shares_directive_type: bool = "Support" in card.tags or "Arts" in card.tags or "Tactic" in card.tags
		if shares_directive_type and tag in ["Support", "Arts", "Tactic"]:
			return true
	return false

func _apply_start_of_turn_modules() -> void:
	if _has_relic("recorder_of_resolve") and turn_count == 1:
		player.gain_will(1, player_resource_max)
	if player_character != null and player_character.id == "exusiai":
		if turn_count == 1 and _has_relic("ex_h02_fast_sling"):
			player.gain_ammo(1)
		if turn_count == 1 and _has_relic("ex_m01_racing_magazine"):
			player.gain_ammo(1)
	if RunManager.modules.has("nearl_crest") and turn_count == 1:
		player.add_block(8)
	if RunManager.modules.has("field_medic_pack") and turn_count == 1:
		player.heal(4)
	if RunManager.has_flag("rewire_support_draw") and turn_count == 1:
		_draw_cards(2, "rewire_support_draw")

func _resolve_pending_channels() -> void:
	var queue: Array = player.meta.get("channel_queue", [])
	if queue.is_empty():
		return
	player.meta["channel_queue"] = []
	for entry in queue:
		if String(entry.get("timing", "next_turn_start")) != "next_turn_start":
			var remaining: Array = player.meta.get("channel_queue", [])
			remaining.append(entry)
			player.meta["channel_queue"] = remaining
			continue
		if String(entry.get("type", "")) == "will_draw":
			var gained_will: int = int(entry.get("will", 0))
			var gained_draw: int = int(entry.get("draw", 0))
			player.gain_will(gained_will, player_resource_max)
			if gained_draw > 0:
				_draw_cards(gained_draw, "channel_will_draw")
			log_message.emit(LocalizationManager.text("battle.log.channel_resolve", [gained_will, gained_draw]))
		elif String(entry.get("type", "")) == "support_draw_cost":
			var support_draw: int = int(entry.get("draw", 0))
			if support_draw > 0:
				_draw_cards(support_draw, "channel_support_draw")
			deck.next_tag_cost_delta["Support"] = int(deck.next_tag_cost_delta.get("Support", 0)) + int(entry.get("cost_delta", 0))
		elif String(entry.get("type", "")) == "arts_bonus":
			var bonus_map: Dictionary = player.meta.get("next_tag_damage_bonus", {})
			bonus_map["Arts"] = int(bonus_map.get("Arts", 0)) + int(entry.get("damage", 0))
			player.meta["next_tag_damage_bonus"] = bonus_map
		elif String(entry.get("type", "")) == "echo":
			player.echo_percent = max(player.echo_percent, int(entry.get("percent", 0)))
		elif String(entry.get("type", "")) == "block":
			player.add_block(int(entry.get("block", 0)))
		elif String(entry.get("type", "")) == "damage_will":
			var target: UnitState = entry.get("target", null) as UnitState
			if target == null or target.is_dead():
				target = enemies[0] if not enemies.is_empty() else null
			var damage_amount: int = int(entry.get("damage", 0))
			var will_amount: int = int(entry.get("will", 0))
			player.gain_will(will_amount, player_resource_max)
			if target != null and damage_amount > 0:
				var temp_effect: EffectData = EffectData.new()
				temp_effect.effect_type = "damage"
				temp_effect.amount = damage_amount
				resolver.resolve_effect(temp_effect, player, target)
			log_message.emit(LocalizationManager.text("battle.log.channel_damage_will", [damage_amount, will_amount]))

func _resolve_turn_end_channels() -> void:
	var queue: Array = player.meta.get("channel_queue", [])
	if queue.is_empty():
		return
	var remaining_queue: Array = []
	for entry in queue:
		if String(entry.get("timing", "next_turn_start")) != "turn_end":
			remaining_queue.append(entry)
			continue
		var target: UnitState = entry.get("target", null) as UnitState
		if target == null or target.is_dead():
			target = enemies[0] if not enemies.is_empty() else null
		var damage_amount: int = int(entry.get("damage", 0))
		if target != null and damage_amount > 0:
			var temp_effect: EffectData = EffectData.new()
			temp_effect.effect_type = "damage"
			temp_effect.amount = damage_amount
			resolver.resolve_effect(temp_effect, player, target)
	player.meta["channel_queue"] = remaining_queue

func _resolve_reload_queue(timing: String) -> void:
	if player.reload_queue.is_empty():
		return
	var remaining_queue: Array[Dictionary] = []
	for entry in player.reload_queue:
		if String(entry.get("timing", "turn_end")) != timing:
			remaining_queue.append(entry)
			continue
		var before_ammo: int = player.ammo
		if bool(entry.get("fill", false)):
			player.fill_ammo()
		else:
			player.gain_ammo(int(entry.get("amount", 0)))
		var restored: int = max(0, player.ammo - before_ammo)
		if restored > 0:
			_on_effect_resolved("gain_ammo", {"amount": restored, "source": player})
			log_message.emit("装填完成，恢复 %d 点弹药。" % restored)
	player.reload_queue = remaining_queue

func _on_overload_tick() -> void:
	if player.overload <= 0:
		return
	var tick_damage: int = player.overload
	if bool(player.meta.get("ashen_halo_prevent_tick_once", false)):
		tick_damage = 0
		player.meta["ashen_halo_prevent_tick_once"] = false
	if bool(player.meta.get("controlled_overload_active", false)):
		tick_damage = int(floor(float(tick_damage) * 0.5))
	if RunManager.has_flag("rewire_overload_minus_one"):
		tick_damage = max(0, tick_damage - 1)
	if tick_damage > 0:
		player.lose_hp(tick_damage)
		player.meta["lost_hp_this_turn"] = int(player.meta.get("lost_hp_this_turn", 0)) + tick_damage
		player.meta["lost_hp_this_battle"] = int(player.meta.get("lost_hp_this_battle", 0)) + tick_damage
	if _has_relic("broken_horn_token"):
		player.add_block(4)
	player.reduce_overload(2)

func _decay_enemy_resonance() -> void:
	if _has_relic("resonance_anchor") or bool(player.meta.get("harmonic_dominion_active", false)):
		return
	for enemy in enemies:
		enemy.resonance = max(0, enemy.resonance - 1)

func _decay_enemy_marks() -> void:
	if bool(player.meta.get("mark_decay_locked", false)):
		return
	for enemy in enemies:
		if enemy == null or enemy.is_dead():
			continue
		enemy.mark = max(0, enemy.mark - 1)

func _apply_draw_curse_penalties() -> void:
	for i in range(deck.hand.size() - 1, -1, -1):
		var card: CardData = deck.hand[i]
		if card.id == "panic_static":
			first_card_tax_pending = true
			log_message.emit(LocalizationManager.text("battle.log.panic"))
		elif card.id == "command_delay":
			player.meta["command_delay_active"] = true
			deck.send_to_exhaust(deck.hand.pop_at(i))
		elif card.id == "shattered_focus":
			player.will = max(0, player.will - 1)
			deck.send_to_exhaust(deck.hand.pop_at(i))

func _refresh_enemy_intents_if_needed() -> void:
	for i in range(enemies.size()):
		var e: UnitState = enemies[i]
		e.intent = enemy_ai.next_intent(e, enemy_datas[i], turn_count)
	enemy_intents_updated.emit()

func _cleanup_dead_enemies() -> void:
	for i in range(enemies.size() - 1, -1, -1):
		if enemies[i].is_dead():
			if player_character != null and player_character.id == "exusiai" and player.burst_active:
				if bool(player.meta.get("chain_trigger_active", false)):
					player.gain_ammo(1)
				if bool(player.meta.get("endless_chain_active", false)):
					deck.next_card_cost_delta -= 1
				if bool(player.meta.get("burst_kill_draw_active", false)):
					_draw_cards(1, "burst_kill_draw")
			RunManager.add_gold(enemy_datas[i].gold_reward)
			enemies.remove_at(i)
			enemy_datas.remove_at(i)

func _end_battle(victory: bool) -> void:
	if battle_finished:
		return
	battle_finished = true
	RunManager.hp = player.hp
	battle_ended.emit(victory)
	if victory:
		var reward_gen: RewardGenerator = RewardGenerator.new(RunManager.rng_seed + turn_count)
		var reward_bias: Dictionary = RunManager.get_reward_bias_weights()
		var active_node: MapNodeModel = RunManager.current_node()
		var is_elite_battle: bool = active_node != null and active_node.node_type == "elite"
		var is_boss_battle: bool = active_node != null and active_node.node_type == "boss"
		var card_choices: Array[String] = []
		var gold_reward: int = 20
		var reward_text: String = LocalizationManager.text("reward.body_default")
		var picks_allowed: int = 1
		var module_reward_id: String = ""
		if is_elite_battle:
			card_choices = reward_gen.elite_card_choices(
				Util.get_normal_battle_reward_pool(player_character.id),
				Util.get_uncommon_card_reward_pool(player_character.id),
				3,
				reward_bias
			)
			picks_allowed = reward_gen.elite_picks_allowed()
			gold_reward = 36
			reward_text = LocalizationManager.text(
				"reward.body_elite_double" if picks_allowed > 1 else "reward.body_elite"
			)
			if reward_gen.rng.randf() < 0.55:
				module_reward_id = reward_gen.module_choice(Util.get_module_reward_pool(player_character.id), RunManager.modules)
		elif is_boss_battle:
			card_choices = reward_gen.elite_card_choices(
				Util.get_normal_battle_reward_pool(player_character.id),
				Util.get_uncommon_card_reward_pool(player_character.id),
				3,
				reward_bias
			)
			picks_allowed = 2
			gold_reward = 48
			reward_text = LocalizationManager.text("reward.body_elite_double")
			module_reward_id = reward_gen.module_choice(Util.get_module_reward_pool(player_character.id), RunManager.modules)
		else:
			card_choices = reward_gen.card_choices(Util.get_normal_battle_reward_pool(player_character.id), 3, reward_bias)
		RunManager.complete_current_node()
		RunManager.set_pending_rewards({
			"type": "battle_reward",
			"gold": gold_reward,
			"text": reward_text,
			"card_choices": card_choices,
			"picks_allowed": picks_allowed,
			"picked_ids": [],
			"module_id": module_reward_id
		})
		if SceneRouter != null:
			SceneRouter.go_reward()
	else:
		_finish_failed_run(RunManager.run_won)

func abandon_battle() -> void:
	if battle_finished:
		return
	battle_finished = true
	if player != null:
		RunManager.hp = player.hp
	battle_ended.emit(false)
	_finish_failed_run(false)

func _finish_failed_run(victory_for_stats: bool) -> void:
	RunManager.set_last_run_summary({
		"floor": RunManager.current_floor,
		"gold": RunManager.gold,
		"deck_size": RunManager.deck.size()
	})
	var summary: Dictionary = RunManager.last_run_summary.duplicate(true)
	RunManager.record_run_result(victory_for_stats)
	RunManager.abandon_run()
	RunManager.set_last_run_summary(summary)
	if SceneRouter != null:
		SceneRouter.go_defeat()

func _insert_curse_into_discard(curse_id: String) -> void:
	if not card_db.has(curse_id):
		return
	deck.discard_pile.append(card_db[curse_id])

func _on_effect_resolved(effect_type: String, payload: Dictionary) -> void:
	match effect_type:
		"gain_will":
			player.meta["gained_will_this_turn"] = true
			log_message.emit(LocalizationManager.text("battle.log.will", [int(payload.get("amount", 0))]))
			if bool(player.meta.get("crowned_resolve_active", false)):
				player.add_block(1)
				log_message.emit(LocalizationManager.text("battle.log.crowned_resolve"))
		"gain_ammo":
			var restored_ammo: int = int(payload.get("amount", 0))
			if restored_ammo > 0:
				player.meta["restored_ammo_this_turn"] = int(player.meta.get("restored_ammo_this_turn", 0)) + restored_ammo
				if bool(player.meta.get("fast_tempo_active", false)) and not bool(player.meta.get("fast_tempo_triggered_turn", false)):
					player.meta["fast_tempo_triggered_turn"] = true
					_draw_cards(1, "fast_tempo")
				if (_has_relic("ex_m03_fast_feeder") or bool(player.meta.get("ammo_refill_draw_first", false))) and not bool(player.meta.get("ammo_refill_draw_first_used_turn", false)):
					player.meta["ammo_refill_draw_first_used_turn"] = true
					_draw_cards(1, "ammo_refill_draw_first")
		"consume_ammo":
			var spent_ammo: int = int(payload.get("amount", 0))
			if spent_ammo > 0:
				player.meta["spent_ammo_this_turn"] = int(player.meta.get("spent_ammo_this_turn", 0)) + spent_ammo
				if _has_relic("ex_m16_heaven_circuit"):
					var spent_total: int = int(player.meta.get("spent_ammo_this_turn", 0))
					var thresholds_before: int = int(floor(float(spent_total - spent_ammo) / 3.0))
					var thresholds_after: int = int(floor(float(spent_total) / 3.0))
					var energy_gain: int = max(0, thresholds_after - thresholds_before)
					if energy_gain > 0:
						player.energy += energy_gain
				if player_character != null and player_character.passive_id == "angel_of_bullets" and not bool(player.meta.get("first_ammo_spent_used_turn", false)):
					player.meta["first_ammo_spent_used_turn"] = true
					player.meta["shot_damage_bonus_turn"] = int(player.meta.get("shot_damage_bonus_turn", 0)) + 1
					if player.burst_active:
						_draw_cards(1, "angel_of_bullets")
				if bool(player.meta.get("ammo_three_energy_active", false)) and int(player.meta.get("spent_ammo_this_turn", 0)) >= 3 and not bool(player.meta.get("ammo_three_energy_used_turn", false)):
					player.meta["ammo_three_energy_used_turn"] = true
					player.energy += 1
				if bool(player.meta.get("overheated_bolt_active", false)):
					player.lose_hp(1)
		"enter_burst":
			player.burst_active = true
			if _has_relic("ex_m11_storm_permit") and not bool(player.meta.get("storm_permit_used_battle", false)):
				player.meta["storm_permit_used_battle"] = true
				player.gain_ammo(2)
			if _has_relic("ex_h08_angel_shard"):
				_add_temporary_shot_to_hand(0, false)
			if bool(player.meta.get("burst_entry_draw", false)):
				_draw_cards(int(player.meta.get("burst_entry_draw", 0)), "burst_entry_draw")
			if bool(player.meta.get("burst_entry_ammo_once", false)) and not bool(player.meta.get("burst_entry_ammo_once_used_battle", false)):
				player.meta["burst_entry_ammo_once_used_battle"] = true
				player.gain_ammo(int(player.meta.get("burst_entry_ammo_once", 0)))
			if bool(player.meta.get("burst_entry_shot_bonus", false)):
				player.meta["burst_shot_damage_bonus"] = int(player.meta.get("burst_shot_damage_bonus", 0)) + int(player.meta.get("burst_entry_shot_bonus", 0))
		"apply_mark":
			if _has_relic("ex_m04_target_scope") and not bool(player.meta.get("target_scope_used_turn", false)):
				player.meta["target_scope_used_turn"] = true
				for target_variant in payload.get("targets", []):
					var marked_target: UnitState = target_variant as UnitState
					if marked_target != null:
						marked_target.add_mark(1)
			if _has_relic("ex_h03_red_dot_pendant") and not bool(player.meta.get("red_dot_pendant_used_battle", false)):
				player.meta["red_dot_pendant_used_battle"] = true
				for target_variant in payload.get("targets", []):
					var first_mark_target: UnitState = target_variant as UnitState
					if first_mark_target != null:
						first_mark_target.add_mark(2)
		"gain_overload":
			if _has_relic("ashen_halo") and not bool(player.meta.get("ashen_halo_used_battle", false)):
				player.meta["ashen_halo_used_battle"] = true
				player.meta["ashen_halo_prevent_tick_once"] = true
				_draw_cards(2, "ashen_halo")
			if RunManager.has_tune("overload_guard_matrix") and not bool(player.meta.get("tune_overload_guard_used_turn", false)):
				player.add_block(6)
				player.meta["tune_overload_guard_used_turn"] = true
				log_message.emit("调律【负荷护矩】启动：第一次过载转化为 6 点护盾。")
			if bool(player.meta.get("sealed_chimera_active", false)):
				player.gain_will(1, player_resource_max)
				log_message.emit(LocalizationManager.text("battle.log.sealed_chimera"))
		"lose_hp":
			player.meta["after_self_damage"] = true
			player.meta["lost_hp_this_turn"] = int(player.meta.get("lost_hp_this_turn", 0)) + int(payload.get("amount", 0))
			player.meta["lost_hp_this_battle"] = int(player.meta.get("lost_hp_this_battle", 0)) + int(payload.get("amount", 0))
			if bool(player.meta.get("shared_burden_active", false)) and not bool(player.meta.get("shared_burden_used", false)):
				player.meta["shared_burden_used"] = true
				_draw_cards(1, "shared_burden")
				player.gain_will(1, player_resource_max)
				log_message.emit(LocalizationManager.text("battle.log.shared_burden"))
			if _has_relic("pain_converter") and int(payload.get("amount", 0)) > 0:
				player.meta["pain_converter_bonus"] = int(player.meta.get("pain_converter_bonus", 0)) + 1
		"gain_echo", "set_echo_charges":
			if _has_relic("echo_pin") and not bool(player.meta.get("echo_pin_used_battle", false)):
				player.meta["echo_pin_used_battle"] = true
				_draw_cards(1, "echo_pin")
			if RunManager.has_tune("echo_guard_lattice"):
				player.add_block(5)
				log_message.emit("调律【回响护格】启动：获得 Echo 时追加 5 点护盾。")
		"set_meta_flag":
			var flag_id: String = String(payload.get("flag", ""))
			if not flag_id.is_empty():
				player.meta[flag_id] = true
		"set_meta_value":
			var meta_key: String = String(payload.get("key", ""))
			if not meta_key.is_empty():
				player.meta[meta_key] = int(payload.get("value", 0))
		"damage_per_target_resonance_consume_all", "damage_from_will_and_target_resonance", "damage_resonant_all_consume":
			if bool(player.meta.get("absolute_resonance_active", false)) and int(payload.get("layers", 0)) > 0:
				player.echo_percent = max(player.echo_percent, 50)
			if _has_relic("resonance_prism") and int(payload.get("layers", 0)) > 0:
				_discount_first_hand_card()
		"damage":
			var damage_target: UnitState = payload.get("target", null) as UnitState
			var damage_source: UnitState = payload.get("source", null) as UnitState
			if player_character != null and player_character.id == "exusiai" and damage_source == player and damage_target != null and damage_target.mark > 0:
				if bool(player.meta.get("headline_rhythm_active", false)) and int(player.meta.get("headline_rhythm_triggers_turn", 0)) < int(player.meta.get("headline_rhythm_limit", 1)):
					player.meta["headline_rhythm_triggers_turn"] = int(player.meta.get("headline_rhythm_triggers_turn", 0)) + 1
					_draw_cards(1, "headline_rhythm")
			_check_w_phase_transition(payload.get("target", null) as UnitState)
	state_changed.emit()

func _consume_post_play_bonuses(card: CardData) -> void:
	if card == null:
		return
	if bool(player.meta.get("dobermann_drill_ready", false)) and (card.card_type == "Attack" or _card_has_effective_tag(card, "Arts")):
		player.meta["dobermann_drill_ready"] = false
	if _card_has_effective_tag(card, "Arts"):
		player.meta["support_trigger_ready"] = false
		var bonus_map: Dictionary = player.meta.get("next_tag_damage_bonus", {})
		bonus_map.erase("Arts")
		player.meta["next_tag_damage_bonus"] = bonus_map
	if _card_has_effective_tag(card, "Shot"):
		if bool(player.meta.get("hunter_clearance_active_card", false)):
			player.meta["hunter_clearance_active_card"] = false
			player.meta["hunter_clearance_used_turn"] = true
		if int(player.meta.get("next_shot_damage_bonus_charges", 0)) > 0:
			player.meta["next_shot_damage_bonus_charges"] = max(0, int(player.meta.get("next_shot_damage_bonus_charges", 0)) - 1)
			if int(player.meta.get("next_shot_damage_bonus_charges", 0)) <= 0:
				player.meta["next_shot_damage_bonus"] = 0
		if int(player.meta.get("next_shot_cost_reduction_charges", 0)) > 0:
			player.meta["next_shot_cost_reduction_charges"] = max(0, int(player.meta.get("next_shot_cost_reduction_charges", 0)) - 1)
			if int(player.meta.get("next_shot_cost_reduction_charges", 0)) <= 0:
				player.meta["next_shot_cost_reduction"] = 0
	if "MultiHit" in card.tags and _has_relic("ex_h06_gunfire_cross") and not bool(player.meta.get("gunfire_cross_used_turn", false)):
		player.meta["gunfire_cross_used_turn"] = true
	if player.echo_percent > 0:
		var echo_charges: int = int(player.meta.get("echo_charges", 0))
		if echo_charges > 0:
			echo_charges -= 1
			player.meta["echo_charges"] = echo_charges
			if echo_charges <= 0:
				player.clear_echo()
		else:
			player.clear_echo()
	deck.consume_tag_cost_delta(card)

func _draw_cards(count: int, source: String = "generic") -> Array[CardData]:
	var empty_result: Array[CardData] = []
	if count <= 0:
		return empty_result
	var drawn: Array[CardData] = deck.draw_cards(count)
	if not drawn.is_empty():
		cards_drawn.emit(drawn, source)
	return drawn

func _add_temporary_arts_to_hand(cost_value: int, upgraded: bool) -> void:
	var pool: Array[String] = [
		"arts_bolt",
		"focused_ray",
		"arc_sliver",
		"measured_blast",
		"echo_conduit",
		"resonance_burst"
	]
	var available: Array[String] = []
	for card_id in pool:
		if card_db.has(card_id):
			available.append(card_id)
	if available.is_empty():
		return
	var seed_source: int = turn_count + int(player.meta.get("played_support_this_turn", 0)) + deck.hand.size()
	var chosen_id: String = available[seed_source % available.size()]
	var generated_card: CardData = (card_db[chosen_id] as CardData).duplicate(true)
	if upgraded and not generated_card.upgraded_id.is_empty() and card_db.has(generated_card.upgraded_id):
		generated_card = (card_db[generated_card.upgraded_id] as CardData).duplicate(true)
	if upgraded:
		generated_card.set_meta("upgraded_visual", true)
	generated_card.cost = cost_value
	generated_card.exhausts = true
	deck.add_to_hand(generated_card)
	log_message.emit(LocalizationManager.text("battle.log.voice_of_the_team", [LocalizationManager.card_name(generated_card)]))
	hand_changed.emit()

func _add_temporary_shot_to_hand(cost_value: int, upgraded: bool) -> void:
	var pool: Array[String] = [
		"ex_b01_burst_shot",
		"ex_b05_crossfire_ping",
		"ex_c01_double_tap_burst",
		"ex_c14_hail_entry",
		"ex_r02_precision_suppression"
	]
	var available: Array[String] = []
	for card_id in pool:
		if card_db.has(card_id):
			available.append(card_id)
	if available.is_empty():
		return
	var seed_source: int = turn_count + int(player.meta.get("played_shot_this_turn", 0)) + deck.hand.size() + player.ammo
	var chosen_id: String = available[seed_source % available.size()]
	var generated_card: CardData = (card_db[chosen_id] as CardData).duplicate(true)
	if upgraded and not generated_card.upgraded_id.is_empty() and card_db.has(generated_card.upgraded_id):
		generated_card = (card_db[generated_card.upgraded_id] as CardData).duplicate(true)
	if upgraded:
		generated_card.set_meta("upgraded_visual", true)
	generated_card.cost = cost_value
	generated_card.exhausts = true
	deck.add_to_hand(generated_card)
	log_message.emit("天使碎片送来一张临时火力牌：%s。" % LocalizationManager.card_name(generated_card))
	hand_changed.emit()

func _first_living_enemy() -> UnitState:
	for enemy in enemies:
		if enemy != null and not enemy.is_dead():
			return enemy
	return null

func _discount_first_hand_card() -> void:
	if deck.hand.is_empty():
		return
	var discounted_card: CardData = deck.hand[0].duplicate(true)
	discounted_card.cost = max(0, discounted_card.cost - 1)
	deck.hand[0] = discounted_card
	hand_changed.emit()

func _has_relic(relic_id: String) -> bool:
	return RunManager.has_relic(relic_id)

func resolve_targets(mode: String, main_target: UnitState) -> Array[UnitState]:
	var result: Array[UnitState] = []
	match mode:
		"self":
			if player != null:
				result.append(player)
			return result
		"enemy":
			if main_target != null:
				result.append(main_target)
			return result
		"all_enemies":
			for enemy in enemies:
				result.append(enemy)
			return result
		"random_enemy":
			if enemies.is_empty():
				return result
			result.append(enemies[randi() % enemies.size()])
			return result
	return result

func fetch_support_from_draw_or_discard() -> void:
	for pile in [deck.draw_pile, deck.discard_pile]:
		for i in range(pile.size()):
			var card: CardData = pile[i]
			if "Support" in card.tags:
				deck.hand.append(card)
				pile.remove_at(i)
				hand_changed.emit()
				return

func fetch_support_from_discard() -> void:
	for i in range(deck.discard_pile.size()):
		var card: CardData = deck.discard_pile[i]
		if "Support" in card.tags:
			deck.hand.append(card)
			deck.discard_pile.remove_at(i)
			hand_changed.emit()
			return

func peek_cards(count: int) -> void:
	var preview: Array[String] = []
	for i in range(min(count, deck.draw_pile.size())):
		preview.append(LocalizationManager.card_name(deck.draw_pile[deck.draw_pile.size() - 1 - i]))
	log_message.emit(LocalizationManager.text("battle.log.scan", [", ".join(preview)]))

func _apply_w_rule(rule_id: String) -> void:
	match rule_id:
		"hand_limit_down":
			player.meta["next_turn_hand_size"] = 4
			log_message.emit(LocalizationManager.text("battle.log.w_hand"))
		"first_card_tax":
			first_card_tax_pending = true
			log_message.emit(LocalizationManager.text("battle.log.w_tax"))
		_:
			log_message.emit(LocalizationManager.text("battle.log.w_shift"))

func _apply_rule_shift_after_card() -> void:
	if enemies.is_empty():
		return
	if int(player.meta.get("cards_played_this_turn", 0)) != 3:
		return
	if bool(player.meta.get("w_third_triggered_this_turn", false)):
		return
	for i in range(min(enemies.size(), enemy_datas.size())):
		var enemy: UnitState = enemies[i]
		var ed: EnemyData = enemy_datas[i]
		if enemy == null or enemy.is_dead():
			continue
		if ed.ai_profile == "w_boss":
			var phase_three_threshold: int = int(ceil(float(enemy.max_hp) * 0.15))
			var phase_three_active: bool = enemy.hp <= phase_three_threshold or bool(enemy.intent.get("phase_three", false))
			if not phase_three_active:
				continue
			var backlash: int = 1
			player.lose_hp(backlash)
			player.meta["w_third_triggered_this_turn"] = true
			log_message.emit(LocalizationManager.text("battle.log.w_third", [backlash]))
			break

func _check_w_phase_transition(target_unit: UnitState) -> void:
	if target_unit == null or target_unit.is_dead():
		return
	var enemy_index: int = enemies.find(target_unit)
	if enemy_index == -1 or enemy_index >= enemy_datas.size():
		return
	if enemy_datas[enemy_index].id != "w_boss":
		return
	var phase_three_threshold: int = int(ceil(float(target_unit.max_hp) * 0.25))
	if target_unit.hp <= phase_three_threshold and not bool(target_unit.meta.get("w_phase_three_announced", false)):
		target_unit.meta["w_phase_three_announced"] = true
		log_message.emit("W 彻底摊牌了。她开始同时压速度、炸药和假动作。")
		_refresh_enemy_intents_if_needed()
		return
	var phase_two_threshold: int = int(ceil(float(target_unit.max_hp) * 0.5))
	if target_unit.hp <= phase_two_threshold and not bool(target_unit.meta.get("w_phase_two_announced", false)):
		target_unit.meta["w_phase_two_announced"] = true
		log_message.emit("W 开始认真起来了。她的节奏更快，假动作也更多。")
		_refresh_enemy_intents_if_needed()

func _tick_status_decay(unit: UnitState) -> void:
	for status_id in ["weak", "vulnerable", "slow"]:
		if int(unit.statuses.get(status_id, 0)) > 0:
			unit.statuses[status_id] = int(unit.statuses[status_id]) - 1
			if int(unit.statuses[status_id]) <= 0:
				unit.clear_status(status_id)

func _queue_auto_end_turn_check() -> void:
	if auto_end_queued:
		return
	auto_end_queued = true
	call_deferred("_auto_end_turn_if_needed")

func _auto_end_turn_if_needed() -> void:
	auto_end_queued = false
	if SettingsManager == null or not bool(SettingsManager.get_settings().get("auto_end_turn", false)):
		return
	if active_side != "player":
		return
	if player == null or player.is_dead() or enemies.is_empty():
		return
	if _has_playable_card():
		return
	log_message.emit(LocalizationManager.text("battle.log.auto_end"))
	if SfxManager != null:
		SfxManager.play_end_turn()
	end_player_turn()

func _has_playable_card() -> bool:
	for card in deck.hand:
		if card == null or card.card_type == "Curse":
			continue
		var actual_cost: int = current_card_cost(card)
		if player.energy >= actual_cost:
			return true
	return false
