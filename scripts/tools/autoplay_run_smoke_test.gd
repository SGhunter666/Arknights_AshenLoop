extends Node

const BATTLE_MANAGER_SCRIPT := preload("res://scripts/battle/BattleManager.gd")

var failures: Array[String] = []
var enemy_db: Dictionary = {}
var char_data: CharacterData

func _ready() -> void:
	var exit_code: int = await _run()
	get_tree().quit(exit_code)

func _run() -> int:
	char_data = Util.load_character("amiya")
	enemy_db = Util.load_enemy_db()
	if char_data == null:
		_fail("无法加载 Amiya 角色资源。")
		return 1
	SceneRouter.suppress_navigation = true
	print("AUTOPLAY_RUN_SMOKE_TEST_START")

	await _run_normal_route()
	await _run_hidden_route()
	SceneRouter.suppress_navigation = false

	if failures.is_empty():
		print("AUTOPLAY_RUN_SMOKE_TEST_OK")
		return 0

	push_error("AUTOPLAY_RUN_SMOKE_TEST_FAILED")
	for failure in failures:
		push_error(failure)
	return 1

func _run_normal_route() -> void:
	print("AUTOPLAY_ROUTE_NORMAL_START")
	RunManager.start_new_run(char_data, 5555)
	for floor_index in [1, 2, 3]:
		print("AUTOPLAY_NORMAL_FLOOR_%d" % floor_index)
		if not await _play_standard_floor(floor_index):
			_fail("普通路线在第 %d 层未能完成。" % floor_index)
			return
	if not RunManager.run_won:
		_fail("普通路线击败 W 后没有标记胜利。")
	if not RunManager.has_flag("run_complete"):
		_fail("普通路线击败 W 后应直接结束本局。")

func _run_hidden_route() -> void:
	print("AUTOPLAY_ROUTE_HIDDEN_START")
	RunManager.start_new_run(char_data, 7777)
	RunManager.set_flag("accept_burden_1", true)
	RunManager.set_flag("accept_burden_2", true)
	for floor_index in [1, 2, 3, 4]:
		print("AUTOPLAY_HIDDEN_FLOOR_%d" % floor_index)
		if not await _play_standard_floor(floor_index):
			_fail("隐藏路线在第 %d 层未能完成。" % floor_index)
			return
	if not RunManager.run_won:
		_fail("隐藏路线打完 W 后应保留胜利标记。")
	if not RunManager.has_flag("run_complete"):
		_fail("隐藏路线打完第 4 层隐藏 Boss 后应结束本局。")

func _play_standard_floor(floor_index: int) -> bool:
	if RunManager.current_floor != floor_index:
		RunManager.current_floor = floor_index

	var battle_pool: Array[String] = Util.get_random_battle_enemies(floor_index, _rng_for_floor(floor_index))
	if not await _play_battle_node("battle", floor_index, battle_pool):
		return false
	_claim_first_reward()

	var boss_pool: Array[String] = Util.get_boss_enemies(floor_index)
	if not await _play_battle_node("boss", floor_index, boss_pool):
		return false
	_claim_first_reward()
	if RunManager.should_take_interfloor_rest():
		RunManager.heal_full()
		RunManager.consume_interfloor_rest()
	return true

func _play_battle_node(node_type: String, floor_index: int, enemy_ids: Array[String]) -> bool:
	var node: MapNodeModel = MapNodeModel.new()
	node.id = "autoplay_%s_f%d_%d" % [node_type, floor_index, Time.get_ticks_msec()]
	node.node_type = node_type
	node.floor_index = floor_index
	node.index = 0
	node.row = 0
	node.lane = 0
	node.metadata = {"enemy_ids": enemy_ids}
	RunManager.map_nodes = [node]
	RunManager.current_node_id = node.id

	var manager: BattleManager = BATTLE_MANAGER_SCRIPT.new()
	add_child(manager)
	var enemy_resources: Array[EnemyData] = []
	for enemy_id in enemy_ids:
		if enemy_db.has(enemy_id):
			enemy_resources.append(enemy_db[enemy_id] as EnemyData)

	print("AUTOPLAY_BATTLE_START_%s_F%d_%s" % [node_type, floor_index, ",".join(enemy_ids)])
	manager.battle_ended.connect(func(victory: bool) -> void:
		print("AUTOPLAY_BATTLE_END_%s_F%d_%s" % [node_type, floor_index, "WIN" if victory else "LOSE"])
	)
	manager.configure(char_data, enemy_resources)

	var safety_turns: int = 0
	while manager.player != null and not manager.player.is_dead() and not manager.enemies.is_empty() and safety_turns < 200:
		if manager.player != null and not manager.enemies.is_empty():
			if not _play_best_available_card(manager):
				manager.end_player_turn()
		await get_tree().process_frame
		safety_turns += 1

	var player_alive: bool = manager.player != null and not manager.player.is_dead()
	var enemies_left: bool = not manager.enemies.is_empty()
	if is_instance_valid(manager):
		manager.queue_free()
	await get_tree().process_frame

	if player_alive and enemies_left:
		_fail("%s 第 %d 层战斗出现卡死或超时。" % [node_type, floor_index])
		return false
	return player_alive and not enemies_left

func _play_best_available_card(manager: BattleManager) -> bool:
	var best_index: int = -1
	var best_score: int = -9999
	var best_target_index: int = 0
	for i in range(manager.deck.hand.size()):
		var card: CardData = manager.deck.hand[i]
		if card.card_type == "Curse" and card.id != "blast_countdown":
			continue
		var actual_cost: int = manager.deck.effective_cost(card)
		if manager.first_card_tax_pending:
			actual_cost += 1
		if actual_cost > manager.player.energy:
			continue
		var target_index: int = _choose_target_index(manager, card)
		var score: int = _card_priority(manager, card, target_index)
		if score > best_score:
			best_score = score
			best_index = i
			best_target_index = target_index
	if best_index == -1:
		return false
	return manager.play_card(best_index, best_target_index)

func _card_priority(manager: BattleManager, card: CardData, target_index: int) -> int:
	var incoming: int = _incoming_damage(manager)
	var player_hp_total: int = manager.player.hp + manager.player.block
	var under_pressure: bool = incoming >= player_hp_total - 4 or manager.player.hp <= 22
	var can_trigger_support_buff: bool = "Support" in card.tags and _has_other_arts_in_hand(manager, card)
	var target: UnitState = manager.enemies[target_index] if target_index >= 0 and target_index < manager.enemies.size() else null
	var lethal_bonus: int = 0
	if target != null and _estimated_damage(manager, card) >= target.hp + target.block:
		lethal_bonus = 200

	match card.id:
		"blast_countdown":
			return 1000
		"emergency_shield", "barrier_formula":
			return 240 if under_pressure else 40
		"tactical_calm":
			return 230 if incoming > 0 else 120
		"command_sync":
			return 200 if can_trigger_support_buff else 55
		"signal_relay":
			return 170 if _has_support_in_discard_or_draw(manager) else 35
		"burn_will":
			return 145 if manager.player.hp > 28 and manager.player.will <= 6 else 20
		"mind_alignment", "discipline_note", "tactical_reorder":
			return 150 if manager.player.energy <= 1 else 110
		"overclock_arts", "resonance_burst", "echo_conduit", "focus_pulse", "guided_fire", "arts_bolt":
			return 160 + lethal_bonus + _estimated_damage(manager, card)
		"rescue_corridor":
			return 120 if under_pressure else 75

	if "Support" in card.tags:
		return 150 if can_trigger_support_buff else 60
	if "Arts" in card.tags:
		return 140 + lethal_bonus + _estimated_damage(manager, card)
	if card.card_type == "Attack":
		return 100 + lethal_bonus + _estimated_damage(manager, card)
	if card.card_type == "Skill":
		return 80
	return 10

func _choose_target_index(manager: BattleManager, card: CardData) -> int:
	var best_index: int = 0
	var best_hp: int = 99999
	var expected: int = _estimated_damage(manager, card)
	for i in range(manager.enemies.size()):
		var enemy: UnitState = manager.enemies[i]
		var effective_hp: int = enemy.hp + enemy.block
		if expected >= effective_hp:
			return i
		if effective_hp < best_hp:
			best_hp = effective_hp
			best_index = i
	return best_index

func _estimated_damage(manager: BattleManager, card: CardData) -> int:
	var amount: int = 0
	for effect in card.effects:
		if String(effect.effect_type) == "damage":
			amount += int(effect.amount)
	if card.id == "echo_conduit":
		amount += min(manager.player.will, 6)
	if "Arts" in card.tags and bool(manager.player.meta.get("support_trigger_ready", false)):
		amount += 2
	if card.id == "guided_fire":
		amount = 10
	return amount

func _incoming_damage(manager: BattleManager) -> int:
	var total: int = 0
	for enemy in manager.enemies:
		if typeof(enemy.intent) == TYPE_DICTIONARY and String(enemy.intent.get("type", "")) == "attack":
			total += int(enemy.intent.get("value", 0))
	return total

func _has_other_arts_in_hand(manager: BattleManager, current_card: CardData) -> bool:
	for card in manager.deck.hand:
		if card == current_card:
			continue
		if "Arts" in card.tags:
			return true
	return false

func _has_support_in_discard_or_draw(manager: BattleManager) -> bool:
	for pile in [manager.deck.draw_pile, manager.deck.discard_pile]:
		for card in pile:
			if "Support" in card.tags:
				return true
	return false

func _claim_first_reward() -> void:
	var reward: Dictionary = RunManager.pending_rewards
	var choices_variant: Variant = reward.get("card_choices", [])
	if typeof(choices_variant) == TYPE_ARRAY and not (choices_variant as Array).is_empty():
		var first_card_id: String = _choose_reward_card_id(choices_variant as Array)
		if not first_card_id.is_empty():
			RunManager.add_card(first_card_id)
	RunManager.pending_rewards = {}

func _choose_reward_card_id(choices: Array) -> String:
	var best_id: String = ""
	var best_score: int = -9999
	var card_db: Dictionary = Util.load_card_db()
	for raw_id in choices:
		var card_id: String = String(raw_id)
		var card: CardData = card_db.get(card_id, null) as CardData
		if card == null:
			continue
		var score: int = 0
		match card.id:
			"emergency_shield", "tactical_calm":
				score = 220
			"command_sync", "signal_relay":
				score = 200
			"echo_conduit", "resonance_burst", "focus_pulse":
				score = 180
			"mind_alignment", "discipline_note", "tactical_reorder":
				score = 150
			_:
				score = 100 + card.cost
		if score > best_score:
			best_score = score
			best_id = card_id
	return best_id

func _rng_for_floor(floor_index: int) -> RandomNumberGenerator:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = RunManager.rng_seed + floor_index * 97
	return rng

func _fail(message: String) -> void:
	failures.append(message)
