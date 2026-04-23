extends SceneTree

const BATTLE_MANAGER_SCRIPT := preload("res://scripts/battle/BattleManager.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_start")

func _start() -> void:
	var exit_code: int = _run()
	await _flush_teardown()
	quit(exit_code)

func _run() -> int:
	var run_manager: Node = root.get_node_or_null("RunManager")
	var scene_router: Node = root.get_node_or_null("SceneRouter")
	if run_manager == null:
		_fail("无法访问 RunManager。")
		return 1
	if scene_router != null:
		scene_router.suppress_navigation = true

	var amiya: CharacterData = Util.load_character("amiya", ResourceLoader.CACHE_MODE_IGNORE)
	var exusiai: CharacterData = Util.load_character("exusiai", ResourceLoader.CACHE_MODE_IGNORE)
	var enemy_db: Dictionary = Util.load_enemy_db(ResourceLoader.CACHE_MODE_IGNORE)
	var enemy: EnemyData = enemy_db.get("reunion_scout", null) as EnemyData
	if amiya == null or exusiai == null or enemy == null:
		_fail("缺少角色或基础敌人资源。")
	else:
		_check_character_opening(run_manager, amiya, enemy, 3, 5)
		_check_character_opening(run_manager, exusiai, enemy, 5, 7)
		_check_exusiai_hand_overflow(run_manager, exusiai, enemy)
		_check_exusiai_ui_enemy_targeting()

	if scene_router != null:
		scene_router.suppress_navigation = false
	if failures.is_empty():
		print("EXUSIAI_RESOURCE_SMOKE_TEST_OK")
		return 0
	push_error("EXUSIAI_RESOURCE_SMOKE_TEST_FAILED")
	for failure in failures:
		push_error(failure)
	return 1

func _check_character_opening(run_manager: Node, character: CharacterData, enemy: EnemyData, expected_energy: int, expected_hand: int) -> void:
	var manager: BattleManager = _new_manager(run_manager, character, enemy)
	if manager == null:
		return
	if manager.player.energy != expected_energy:
		_fail("%s 开局能量应为 %d，实际 %d。" % [character.id, expected_energy, manager.player.energy])
	if manager.deck.hand.size() != expected_hand:
		_fail("%s 开局抽牌应为 %d，实际 %d。" % [character.id, expected_hand, manager.deck.hand.size()])
	_free_manager(manager)

func _check_exusiai_hand_overflow(run_manager: Node, character: CharacterData, enemy: EnemyData) -> void:
	var manager: BattleManager = _new_manager(run_manager, character, enemy)
	if manager == null:
		return
	var card_db: Dictionary = Util.load_card_db(ResourceLoader.CACHE_MODE_IGNORE)
	var filler: CardData = card_db.get("ex_b01_burst_shot", null) as CardData
	if filler == null:
		_fail("缺少能天使基础射击牌，无法测试手牌溢出。")
		_free_manager(manager)
		return
	while manager.deck.draw_pile.size() < 5:
		manager.deck.draw_pile.append(filler)
	var discard_before: int = manager.deck.discard_pile.size()
	var drawn: Array[CardData] = manager._draw_cards(5, "resource_smoke_test")
	if manager.deck.hand.size() != 10:
		_fail("手牌上限应锁定为 10，实际 %d。" % manager.deck.hand.size())
	if drawn.size() != 3:
		_fail("7 张手牌时再抽 5，应只有 3 张进入手牌，实际 %d。" % drawn.size())
	if manager.deck.discard_pile.size() < discard_before + 2:
		_fail("手牌溢出的新牌应进入弃牌堆。")
	_free_manager(manager)

func _check_exusiai_ui_enemy_targeting() -> void:
	var card_db: Dictionary = Util.load_card_db(ResourceLoader.CACHE_MODE_IGNORE)
	var battle_scene_packed: PackedScene = load("res://scenes/BattleScene.tscn")
	if battle_scene_packed == null:
		_fail("无法加载战斗场景，不能测试能天使拖拽目标判定。")
		return
	var battle_scene: Control = battle_scene_packed.instantiate() as Control
	if battle_scene == null:
		_fail("无法实例化战斗场景，不能测试能天使拖拽目标判定。")
		return
	var expected_enemy_target_ids: Array[String] = [
		"ex_b04_target_ping",
		"ex_c09_red_dot_lock",
		"ex_c14_tagged_signal",
		"ex_b10_trajectory_fix",
		"ex_c11_alternating_aim"
	]
	for card_id in expected_enemy_target_ids:
		var card: CardData = card_db.get(card_id, null) as CardData
		if card == null:
			_fail("缺少能天使目标牌资源：%s。" % card_id)
			continue
		if not bool(battle_scene.call("_card_targets_enemy", card)):
			_fail("%s 指向敌人，但战斗 UI 没有进入拖拽瞄准模式。" % card_id)
	var self_only_ids: Array[String] = [
		"ex_b03_quick_reload",
		"ex_b06_burst_entry",
		"ex_c02_reserve_magazine"
	]
	for card_id in self_only_ids:
		var card: CardData = card_db.get(card_id, null) as CardData
		if card == null:
			_fail("缺少能天使自用牌资源：%s。" % card_id)
			continue
		if bool(battle_scene.call("_card_targets_enemy", card)):
			_fail("%s 是自用牌，但战斗 UI 错误要求拖拽敌人。" % card_id)
	battle_scene.free()

func _new_manager(run_manager: Node, character: CharacterData, enemy: EnemyData) -> BattleManager:
	run_manager.start_new_run(character, 4242)
	var manager: BattleManager = BATTLE_MANAGER_SCRIPT.new()
	root.add_child(manager)
	manager.configure(character, [enemy])
	return manager

func _free_manager(manager: BattleManager) -> void:
	if manager == null:
		return
	manager.dispose_runtime_state()
	manager.free()

func _flush_teardown() -> void:
	for _i in range(4):
		await process_frame

func _fail(message: String) -> void:
	failures.append(message)
