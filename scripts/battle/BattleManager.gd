class_name BattleManager
extends Node

signal battle_started
signal turn_started(side: String)
signal hand_changed
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

func _ready() -> void:
	resolver.effect_resolved.connect(_on_effect_resolved)

func configure(char_data: CharacterData, enemies_for_battle: Array[EnemyData]) -> void:
	player_character = char_data
	enemy_list = enemies_for_battle
	start_battle()

func start_battle() -> void:
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
	battle_started.emit()
	log_message.emit(LocalizationManager.text("battle.log.start"))
	start_player_turn()

func _load_databases() -> void:
	card_db = Util.load_card_db()
	module_db = Util.load_module_db()

func _setup_player() -> void:
	player = UnitState.new()
	player.id = player_character.id
	player.display_name = player_character.display_name
	player.max_hp = RunManager.max_hp
	player.hp = RunManager.hp
	player.energy = player_character.starting_energy
	player.will = 0
	player_resource_max = player_character.resource_max

func _setup_enemies() -> void:
	enemies.clear()
	enemy_datas = enemy_list.duplicate()
	for ed in enemy_datas:
		var e: UnitState = UnitState.new()
		e.id = ed.id
		e.display_name = ed.display_name
		e.max_hp = ed.max_hp
		e.hp = ed.max_hp
		enemies.append(e)

func start_player_turn() -> void:
	active_side = "player"
	turn_count += 1
	player.energy = player_character.starting_energy
	if RunManager.modules.has("reserve_battery") and turn_count == 1:
		player.energy += 1
	player.meta["support_played_this_turn"] = false
	player.meta["support_trigger_ready"] = false
	player.meta["cards_played_this_turn"] = 0
	player.meta["played_arts_this_turn"] = false
	_apply_start_of_turn_modules()
	deck.draw_cards(min(hand_size, max(0, hand_size - deck.hand.size())))
	_apply_draw_curse_penalties()
	turn_started.emit("player")
	_refresh_enemy_intents_if_needed()
	hand_changed.emit()
	state_changed.emit()
	_queue_auto_end_turn_check()

func end_player_turn() -> void:
	for card in deck.hand:
		if card.id == "hesitation":
			player.will = max(0, player.will - 1)
		elif card.id == "blast_countdown":
			player.lose_hp(8)
			log_message.emit(LocalizationManager.text("battle.log.countdown"))
	deck.discard_hand()
	_tick_status_decay(player)
	_resolve_enemy_turn()

func play_card(hand_index: int, target_index: int = 0) -> bool:
	var card: CardData = deck.play_from_hand(hand_index)
	if card == null:
		return false
	var actual_cost: int = deck.effective_cost(card)
	if first_card_tax_pending:
		actual_cost += 1
	if player.energy < actual_cost:
		deck.hand.insert(hand_index, card)
		return false

	player.energy -= actual_cost
	first_card_tax_pending = false
	player.meta["cards_played_this_turn"] = int(player.meta.get("cards_played_this_turn", 0)) + 1
	var target: UnitState = null
	if target_index >= 0 and target_index < enemies.size():
		target = enemies[target_index]
	elif not enemies.is_empty():
		target = enemies[0]

	if "Arts" in card.tags:
		player.meta["played_arts_this_turn"] = true
	_apply_passives_before_card(card)
	resolver.resolve_card(card, player, target)
	if card.exhausts or card.ethereal:
		deck.send_to_exhaust(card)
	else:
		deck.send_to_discard(card)
	_apply_rule_shift_after_card()
	_cleanup_dead_enemies()
	hand_changed.emit()
	state_changed.emit()

	if enemies.is_empty():
		_end_battle(true)
	else:
		_queue_auto_end_turn_check()
	return true

func _resolve_enemy_turn() -> void:
	active_side = "enemy"
	turn_started.emit("enemy")
	for i in range(enemies.size()):
		var e: UnitState = enemies[i]
		if e.is_dead():
			continue
		var ed: EnemyData = enemy_datas[i]
		var intent: Dictionary = enemy_ai.next_intent(e, ed, turn_count)
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
			_insert_curse_into_discard(String(intent.get("curse", "hesitation")))
			log_message.emit(LocalizationManager.text("battle.log.curse", [LocalizationManager.enemy_name(enemy.id, enemy.display_name)]))
		"shuffle_and_debuff":
			deck.shuffle_draw()
			player.apply_status("weak", 1)
			first_card_tax_pending = true
			log_message.emit(LocalizationManager.text("battle.log.disrupt", [LocalizationManager.enemy_name(enemy.id, enemy.display_name)]))
		"rule_shift":
			_apply_w_rule(String(intent.get("rule", "")))
		_:
			log_message.emit(LocalizationManager.text("battle.log.enemy_idle"))
	state_changed.emit()

func _apply_passives_before_card(card: CardData) -> void:
	if "Support" in card.tags:
		if not bool(player.meta.get("support_played_this_turn", false)):
			player.meta["support_trigger_ready"] = true
			log_message.emit(LocalizationManager.text("battle.log.leader_ready"))
		player.meta["support_played_this_turn"] = true
		if RunManager.modules.has("field_command_badge"):
			player.energy += 1
			RunManager.set_flag("used_field_command_badge", true)
	elif "Arts" in card.tags and bool(player.meta.get("support_trigger_ready", false)):
		pass
	if RunManager.modules.has("ashen_thread") and "Arts" in card.tags and bool(player.meta.get("after_self_damage", false)):
		var bonus: EffectData = EffectData.new()
		bonus.effect_type = "damage"
		bonus.amount = 3
		var target: UnitState = enemies[0] if not enemies.is_empty() else null
		resolver.resolve_effect(bonus, player, target, card)
		player.meta["after_self_damage"] = false

func _apply_start_of_turn_modules() -> void:
	if RunManager.modules.has("nearl_crest") and turn_count == 1:
		player.add_block(8)
	if RunManager.modules.has("field_medic_pack") and turn_count == 1:
		player.heal(4)

func _apply_draw_curse_penalties() -> void:
	for card in deck.hand:
		if card.id == "panic_static":
			first_card_tax_pending = true
			log_message.emit(LocalizationManager.text("battle.log.panic"))

func _refresh_enemy_intents_if_needed() -> void:
	for i in range(enemies.size()):
		var e: UnitState = enemies[i]
		e.intent = enemy_ai.next_intent(e, enemy_datas[i], turn_count)
	enemy_intents_updated.emit()

func _cleanup_dead_enemies() -> void:
	for i in range(enemies.size() - 1, -1, -1):
		if enemies[i].is_dead():
			RunManager.add_gold(enemy_datas[i].gold_reward)
			enemies.remove_at(i)
			enemy_datas.remove_at(i)

func _end_battle(victory: bool) -> void:
	RunManager.hp = player.hp
	battle_ended.emit(victory)
	if victory:
		var reward_gen: RewardGenerator = RewardGenerator.new(RunManager.rng_seed + turn_count)
		var active_node: MapNodeModel = RunManager.current_node()
		var is_elite_battle: bool = active_node != null and active_node.node_type == "elite"
		var card_choices: Array[String] = []
		var gold_reward: int = 20
		var reward_text: String = LocalizationManager.text("reward.body_default")
		var picks_allowed: int = 1
		if is_elite_battle:
			card_choices = reward_gen.elite_card_choices(
				Util.get_common_card_reward_pool(),
				Util.get_uncommon_card_reward_pool(),
				3
			)
			picks_allowed = reward_gen.elite_picks_allowed()
			gold_reward = 36
			reward_text = LocalizationManager.text(
				"reward.body_elite_double" if picks_allowed > 1 else "reward.body_elite"
			)
		else:
			card_choices = reward_gen.card_choices(Util.get_card_reward_pool(), 3)
		RunManager.complete_current_node()
		RunManager.pending_rewards = {
			"type": "battle_reward",
			"gold": gold_reward,
			"text": reward_text,
			"card_choices": card_choices,
			"picks_allowed": picks_allowed,
			"picked_ids": []
		}
		SceneRouter.go_reward()
	else:
		RunManager.last_run_summary = {
			"floor": RunManager.current_floor,
			"gold": RunManager.gold,
			"deck_size": RunManager.deck.size()
		}
		RunManager.record_run_result(RunManager.run_won)
		RunManager.clear_saved_run()
		SceneRouter.go_defeat()

func _insert_curse_into_discard(curse_id: String) -> void:
	if not card_db.has(curse_id):
		return
	deck.discard_pile.append(card_db[curse_id])

func _on_effect_resolved(effect_type: String, payload: Dictionary) -> void:
	match effect_type:
		"gain_will":
			log_message.emit(LocalizationManager.text("battle.log.will", [int(payload.get("amount", 0))]))
		"lose_hp":
			player.meta["after_self_damage"] = true
	state_changed.emit()

func resolve_targets(mode: String, main_target: UnitState) -> Array[UnitState]:
	match mode:
		"self":
			return [player]
		"enemy":
			return [main_target] if main_target != null else []
		"all_enemies":
			return enemies.duplicate()
		"random_enemy":
			if enemies.is_empty():
				return []
			return [enemies[randi() % enemies.size()]]
	return []

func fetch_support_from_draw_or_discard() -> void:
	for pile in [deck.draw_pile, deck.discard_pile]:
		for i in range(pile.size()):
			var card: CardData = pile[i]
			if "Support" in card.tags:
				deck.hand.append(card)
				pile.remove_at(i)
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
			hand_size = 4
			log_message.emit(LocalizationManager.text("battle.log.w_hand"))
		"first_card_tax":
			first_card_tax_pending = true
			log_message.emit(LocalizationManager.text("battle.log.w_tax"))
		_:
			log_message.emit(LocalizationManager.text("battle.log.w_shift"))

func _apply_rule_shift_after_card() -> void:
	if int(player.meta.get("cards_played_this_turn", 0)) >= 3 and not enemies.is_empty():
		for ed in enemy_datas:
			if ed.ai_profile == "w_boss":
				player.lose_hp(2)
				log_message.emit(LocalizationManager.text("battle.log.w_third"))
				break

func _tick_status_decay(unit: UnitState) -> void:
	for status_id in ["weak", "vulnerable"]:
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
	if not bool(SettingsManager.get_settings().get("auto_end_turn", false)):
		return
	if active_side != "player":
		return
	if player == null or player.is_dead() or enemies.is_empty():
		return
	if _has_playable_card():
		return
	log_message.emit(LocalizationManager.text("battle.log.auto_end"))
	end_player_turn()

func _has_playable_card() -> bool:
	for card in deck.hand:
		if card == null or card.card_type == "Curse":
			continue
		var actual_cost: int = deck.effective_cost(card)
		if first_card_tax_pending:
			actual_cost += 1
		if player.energy >= actual_cost:
			return true
	return false
