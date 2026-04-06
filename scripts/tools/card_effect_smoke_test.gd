extends Node

const BATTLE_MANAGER_SCRIPT := preload("res://scripts/battle/BattleManager.gd")
const EFFECT_RESOLVER_SCRIPT := preload("res://scripts/battle/EffectResolver.gd")
const DECK_CONTROLLER_SCRIPT := preload("res://scripts/battle/DeckController.gd")
const UNIT_STATE_SCRIPT := preload("res://scripts/battle/UnitState.gd")

var failures: Array[String] = []

class TestBattleStub:
	var deck = DECK_CONTROLLER_SCRIPT.new()
	var player: UnitState
	var enemies: Array[UnitState] = []
	var player_resource_max: int = 10
	var logs: Array[String] = []
	var last_peek_count: int = 0

	func resolve_targets(mode: String, main_target: UnitState) -> Array[UnitState]:
		match mode:
			"self":
				var result_self: Array[UnitState] = []
				if player != null:
					result_self.append(player)
				return result_self
			"enemy":
				var result_enemy: Array[UnitState] = []
				if main_target != null:
					result_enemy.append(main_target)
				return result_enemy
			"all_enemies":
				var result_all: Array[UnitState] = []
				for enemy in enemies:
					result_all.append(enemy)
				return result_all
			"random_enemy":
				var result_random: Array[UnitState] = []
				if not enemies.is_empty():
					result_random.append(enemies[0])
				return result_random
		var result_empty: Array[UnitState] = []
		return result_empty

	func fetch_support_from_draw_or_discard() -> void:
		for pile in [deck.draw_pile, deck.discard_pile]:
			for i in range(pile.size()):
				var card: CardData = pile[i]
				if "Support" in card.tags:
					deck.hand.append(card)
					pile.remove_at(i)
					return

	func peek_cards(count: int) -> void:
		last_peek_count = count

func _ready() -> void:
	var exit_code: int = _run()
	get_tree().quit(exit_code)

func _run() -> int:
	var card_db: Dictionary = Util.load_card_db()
	var char_data: CharacterData = Util.load_character("amiya")
	if char_data == null:
		_fail("无法加载 Amiya 角色资源。")
	if card_db.size() != 20:
		_fail("卡牌资源数量异常，预期 20，实际 %d。" % card_db.size())
	if char_data != null:
		RunManager.start_new_run(char_data, 12345)

	_run_project_boot_check()
	_run_card_resource_checks(card_db)
	_run_card_effect_checks(card_db)

	if failures.is_empty():
		print("CARD_SMOKE_TEST_OK")
		return 0

	push_error("CARD_SMOKE_TEST_FAILED")
	for failure in failures:
		push_error(failure)
	return 1

func _run_project_boot_check() -> void:
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	if main_scene == null:
		_fail("无法加载主场景 Main.tscn。")

func _run_card_resource_checks(card_db: Dictionary) -> void:
	var supported_effects: Dictionary = {
		"damage": true,
		"block": true,
		"draw": true,
		"gain_energy": true,
		"gain_will": true,
		"lose_hp": true,
		"apply_status": true,
		"weaken_enemy_team": true,
		"damage_all": true,
		"spend_all_will_damage": true,
		"fetch_support": true,
		"peek_draw": true,
		"gain_gold": true
	}
	for card_id in card_db.keys():
		var card: CardData = card_db[card_id]
		if card.card_type != "Curse" and card.effects.is_empty():
			_fail("%s 没有效果定义。" % card.id)
		for effect in card.effects:
			if not supported_effects.has(effect.effect_type):
				_fail("%s 使用了未支持的效果类型 %s。" % [card.id, effect.effect_type])
		var art: Texture2D = Util.load_card_art(card.id)
		if art == null:
			_fail("%s 缺少卡图资源。" % card.id)

func _run_card_effect_checks(card_db: Dictionary) -> void:
	_check_direct_damage(card_db["arts_bolt"], 6)
	_check_block(card_db["barrier_formula"], 5)
	_check_draw_and_will(card_db["mind_alignment"], 2, 1)
	_check_conditional_will(card_db["tactical_reorder"])
	_check_damage(card_db["focus_pulse"], 7)
	_check_focus_pulse_bonus(card_db["focus_pulse"])
	_check_block(card_db["emergency_shield"], 9)
	_check_damage(card_db["resonance_burst"], 12)
	_check_resonance_burst_bonus(card_db["resonance_burst"])
	_check_energy(card_db["command_sync"], 1)
	_check_fetch_support(card_db["signal_relay"])
	_check_double_damage(card_db["guided_fire"], 10)
	_check_block_and_gold(card_db["rescue_corridor"], 6, 10)
	_check_draw_and_will(card_db["discipline_note"], 1, 1)
	_check_peek(card_db["pulse_scan"], 3)
	_check_self_damage_and_will(card_db["burn_will"], 4, 3)
	_check_self_damage_and_enemy_damage(card_db["overclock_arts"], 16, 3)
	_check_draw_and_team_weak(card_db["tactical_calm"], 2, 1)
	_check_echo_conduit(card_db["echo_conduit"])
	_check_curse_passthrough(card_db["hesitation"])
	_check_curse_passthrough(card_db["panic_static"])
	_check_curse_passthrough(card_db["blast_countdown"])

func _new_stub() -> Dictionary:
	var stub := TestBattleStub.new()
	var player: UnitState = UNIT_STATE_SCRIPT.new()
	player.id = "amiya"
	player.display_name = "Amiya"
	player.max_hp = 72
	player.hp = 72
	player.energy = 3
	stub.player = player
	var enemy: UnitState = UNIT_STATE_SCRIPT.new()
	enemy.id = "dummy"
	enemy.display_name = "Dummy"
	enemy.max_hp = 100
	enemy.hp = 100
	stub.enemies = [enemy]
	var resolver: EffectResolver = EFFECT_RESOLVER_SCRIPT.new(stub)
	return {"stub": stub, "player": player, "enemy": enemy, "resolver": resolver}

func _check_direct_damage(card: CardData, expected: int) -> void:
	_check_damage(card, expected)

func _check_damage(card: CardData, expected: int) -> void:
	var ctx: Dictionary = _new_stub()
	var resolver: EffectResolver = ctx["resolver"]
	var player: UnitState = ctx["player"]
	var enemy: UnitState = ctx["enemy"]
	resolver.resolve_card(card, player, enemy)
	var dealt: int = 100 - enemy.hp
	if dealt != expected:
		_fail("%s 伤害异常，预期 %d，实际 %d。" % [card.id, expected, dealt])

func _check_double_damage(card: CardData, expected_total: int) -> void:
	_check_damage(card, expected_total)

func _check_block(card: CardData, expected: int) -> void:
	var ctx: Dictionary = _new_stub()
	var resolver: EffectResolver = ctx["resolver"]
	var player: UnitState = ctx["player"]
	var enemy: UnitState = ctx["enemy"]
	resolver.resolve_card(card, player, enemy)
	if player.block != expected:
		_fail("%s 护盾异常，预期 %d，实际 %d。" % [card.id, expected, player.block])

func _check_draw_and_will(card: CardData, expected_draw: int, expected_will: int) -> void:
	var ctx: Dictionary = _new_stub()
	var stub: TestBattleStub = ctx["stub"]
	var resolver: EffectResolver = ctx["resolver"]
	var player: UnitState = ctx["player"]
	var enemy: UnitState = ctx["enemy"]
	_seed_draw_pile(stub.deck, [card, card, card, card])
	resolver.resolve_card(card, player, enemy)
	if player.will != expected_will:
		_fail("%s 意志异常，预期 %d，实际 %d。" % [card.id, expected_will, player.will])
	if stub.deck.hand.size() != expected_draw:
		_fail("%s 抽牌异常，预期 %d，实际 %d。" % [card.id, expected_draw, stub.deck.hand.size()])

func _check_conditional_will(card: CardData) -> void:
	var ctx1: Dictionary = _new_stub()
	var stub1: TestBattleStub = ctx1["stub"]
	var resolver1: EffectResolver = ctx1["resolver"]
	var player1: UnitState = ctx1["player"]
	var enemy1: UnitState = ctx1["enemy"]
	_seed_draw_pile(stub1.deck, [card, card, card])
	resolver1.resolve_card(card, player1, enemy1)
	if player1.will != 0:
		_fail("%s 在未打出术式时不应获得意志。" % card.id)
	var ctx2: Dictionary = _new_stub()
	var stub2: TestBattleStub = ctx2["stub"]
	var resolver2: EffectResolver = ctx2["resolver"]
	var player2: UnitState = ctx2["player"]
	var enemy2: UnitState = ctx2["enemy"]
	_seed_draw_pile(stub2.deck, [card, card, card])
	player2.meta["played_arts_this_turn"] = true
	resolver2.resolve_card(card, player2, enemy2)
	if player2.will != 1:
		_fail("%s 在打出术式后应获得 1 点意志。" % card.id)

func _check_energy(card: CardData, expected_gain: int) -> void:
	var ctx: Dictionary = _new_stub()
	var resolver: EffectResolver = ctx["resolver"]
	var player: UnitState = ctx["player"]
	var enemy: UnitState = ctx["enemy"]
	var before: int = player.energy
	resolver.resolve_card(card, player, enemy)
	if player.energy != before + expected_gain:
		_fail("%s 能量异常，预期 %+d，实际 %+d。" % [card.id, expected_gain, player.energy - before])

func _check_fetch_support(card: CardData) -> void:
	var ctx: Dictionary = _new_stub()
	var stub: TestBattleStub = ctx["stub"]
	var resolver: EffectResolver = ctx["resolver"]
	var player: UnitState = ctx["player"]
	var enemy: UnitState = ctx["enemy"]
	var card_db: Dictionary = Util.load_card_db()
	_seed_draw_pile(stub.deck, [card_db["focus_pulse"], card_db["arts_bolt"]])
	_seed_discard_pile(stub.deck, [card_db["command_sync"]])
	resolver.resolve_card(card, player, enemy)
	if stub.deck.hand.is_empty() or stub.deck.hand[0].id != "command_sync":
		_fail("%s 没有成功取回支援牌。" % card.id)

func _check_block_and_gold(card: CardData, expected_block: int, expected_gold_gain: int) -> void:
	var ctx: Dictionary = _new_stub()
	var resolver: EffectResolver = ctx["resolver"]
	var player: UnitState = ctx["player"]
	var enemy: UnitState = ctx["enemy"]
	var before_gold: int = RunManager.gold
	resolver.resolve_card(card, player, enemy)
	if player.block != expected_block:
		_fail("%s 护盾异常，预期 %d，实际 %d。" % [card.id, expected_block, player.block])
	if RunManager.gold - before_gold != expected_gold_gain:
		_fail("%s 金币异常，预期 %+d，实际 %+d。" % [card.id, expected_gold_gain, RunManager.gold - before_gold])

func _check_peek(card: CardData, expected: int) -> void:
	var ctx: Dictionary = _new_stub()
	var resolver: EffectResolver = ctx["resolver"]
	var player: UnitState = ctx["player"]
	var enemy: UnitState = ctx["enemy"]
	var stub: TestBattleStub = ctx["stub"]
	resolver.resolve_card(card, player, enemy)
	if int(stub.last_peek_count) != expected:
		_fail("%s 预览抽牌数异常，预期 %d，实际 %d。" % [card.id, expected, int(stub.last_peek_count)])

func _check_self_damage_and_will(card: CardData, hp_loss: int, will_gain: int) -> void:
	var ctx: Dictionary = _new_stub()
	var resolver: EffectResolver = ctx["resolver"]
	var player: UnitState = ctx["player"]
	var enemy: UnitState = ctx["enemy"]
	resolver.resolve_card(card, player, enemy)
	if player.hp != 72 - hp_loss:
		_fail("%s 自伤异常，预期损失 %d，实际损失 %d。" % [card.id, hp_loss, 72 - player.hp])
	if player.will != will_gain:
		_fail("%s 意志异常，预期 %d，实际 %d。" % [card.id, will_gain, player.will])

func _check_self_damage_and_enemy_damage(card: CardData, expected_damage: int, hp_loss: int) -> void:
	var ctx: Dictionary = _new_stub()
	var resolver: EffectResolver = ctx["resolver"]
	var player: UnitState = ctx["player"]
	var enemy: UnitState = ctx["enemy"]
	resolver.resolve_card(card, player, enemy)
	var dealt: int = 100 - enemy.hp
	if dealt != expected_damage:
		_fail("%s 伤害异常，预期 %d，实际 %d。" % [card.id, expected_damage, dealt])
	if player.hp != 72 - hp_loss:
		_fail("%s 自伤异常，预期损失 %d，实际损失 %d。" % [card.id, hp_loss, 72 - player.hp])

func _check_draw_and_team_weak(card: CardData, expected_draw: int, expected_weak: int) -> void:
	var ctx: Dictionary = _new_stub()
	var stub: TestBattleStub = ctx["stub"]
	var resolver: EffectResolver = ctx["resolver"]
	var player: UnitState = ctx["player"]
	var enemy: UnitState = ctx["enemy"]
	_seed_draw_pile(stub.deck, [card, card, card, card])
	resolver.resolve_card(card, player, enemy)
	if stub.deck.hand.size() != expected_draw:
		_fail("%s 抽牌异常，预期 %d，实际 %d。" % [card.id, expected_draw, stub.deck.hand.size()])
	if int(enemy.statuses.get("weak", 0)) != expected_weak:
		_fail("%s 虚弱异常，预期 %d，实际 %d。" % [card.id, expected_weak, int(enemy.statuses.get("weak", 0))])

func _check_echo_conduit(card: CardData) -> void:
	var ctx: Dictionary = _new_stub()
	var resolver: EffectResolver = ctx["resolver"]
	var player: UnitState = ctx["player"]
	var enemy: UnitState = ctx["enemy"]
	player.will = 4
	resolver.resolve_card(card, player, enemy)
	var dealt: int = 100 - enemy.hp
	if dealt != 14:
		_fail("%s 在 4 点意志时应造成 14 伤害，实际 %d。" % [card.id, dealt])

func _check_focus_pulse_bonus(card: CardData) -> void:
	var ctx: Dictionary = _new_stub()
	var resolver: EffectResolver = ctx["resolver"]
	var player: UnitState = ctx["player"]
	var enemy: UnitState = ctx["enemy"]
	player.meta["support_played_this_turn"] = true
	resolver.resolve_card(card, player, enemy)
	var dealt: int = 100 - enemy.hp
	if dealt != 10:
		_fail("%s 在本回合打出过支援后应造成 10 伤害，实际 %d。" % [card.id, dealt])

func _check_resonance_burst_bonus(card: CardData) -> void:
	var ctx: Dictionary = _new_stub()
	var resolver: EffectResolver = ctx["resolver"]
	var player: UnitState = ctx["player"]
	var enemy: UnitState = ctx["enemy"]
	player.will = 4
	resolver.resolve_card(card, player, enemy)
	var dealt: int = 100 - enemy.hp
	if dealt != 16:
		_fail("%s 在 4 点意志时应造成 16 伤害，实际 %d。" % [card.id, dealt])

func _check_curse_passthrough(card: CardData) -> void:
	if card == null:
		_fail("存在无法加载的诅咒卡。")

func _fail(message: String) -> void:
	failures.append(message)

func _seed_draw_pile(deck: DeckController, cards: Array) -> void:
	deck.draw_pile.clear()
	for card in cards:
		deck.draw_pile.append(card)

func _seed_discard_pile(deck: DeckController, cards: Array) -> void:
	deck.discard_pile.clear()
	for card in cards:
		deck.discard_pile.append(card)
