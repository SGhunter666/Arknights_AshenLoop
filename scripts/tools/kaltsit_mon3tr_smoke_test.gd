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

	var kaltsit: CharacterData = Util.load_character("kaltsit", ResourceLoader.CACHE_MODE_IGNORE)
	var enemy_db: Dictionary = Util.load_enemy_db(ResourceLoader.CACHE_MODE_IGNORE)
	var enemy: EnemyData = enemy_db.get("reunion_scout", null) as EnemyData
	if kaltsit == null or enemy == null:
		_fail("缺少凯尔希角色或基础敌人资源。")
	else:
		_check_opening_state(run_manager, kaltsit, enemy)
		_check_mon3tr_repair_and_meltdown(run_manager, kaltsit, enemy)
		_check_mon3tr_card_damage(run_manager, kaltsit, enemy)

	if scene_router != null:
		scene_router.suppress_navigation = false
	if failures.is_empty():
		print("KALTSIT_MON3TR_SMOKE_TEST_OK")
		return 0
	push_error("KALTSIT_MON3TR_SMOKE_TEST_FAILED")
	for failure in failures:
		push_error(failure)
	return 1

func _check_opening_state(run_manager: Node, character: CharacterData, enemy: EnemyData) -> void:
	var manager: BattleManager = _new_manager(run_manager, character, enemy)
	if manager == null:
		return
	if manager.player.energy != 4:
		_fail("凯尔希开局能量应为 4，实际 %d。" % manager.player.energy)
	if manager.deck.hand.size() != 4:
		_fail("凯尔希开局抽牌应为 4，实际 %d。" % manager.deck.hand.size())
	if manager.mon3tr_integrity() != 7 or manager.mon3tr_max_integrity() != 10:
		_fail("凯尔希开局 Mon3tr 完整性应为 7/10，实际 %d/%d。" % [manager.mon3tr_integrity(), manager.mon3tr_max_integrity()])
	_free_manager(manager)

func _check_mon3tr_repair_and_meltdown(run_manager: Node, character: CharacterData, enemy: EnemyData) -> void:
	var manager: BattleManager = _new_manager(run_manager, character, enemy)
	if manager == null:
		return
	manager.player.meta["mon3tr_integrity"] = 7
	manager.player.meta["mon3tr_current_max_integrity"] = 10
	manager.repair_mon3tr(3, "smoke_full_repair")
	if not manager.is_mon3tr_meltdown():
		_fail("Mon3tr 修复到完整性上限后应进入融毁。")
	if manager.mon3tr_max_integrity() != 15:
		_fail("融毁中 Mon3tr 完整性上限应为 15，实际 %d。" % manager.mon3tr_max_integrity())

	manager.player.meta["mon3tr_in_meltdown"] = false
	manager.player.meta["mon3tr_current_max_integrity"] = 10
	manager.player.meta["mon3tr_integrity"] = 1
	manager.repair_mon3tr(9, "smoke_critical_repair")
	if manager.is_mon3tr_meltdown():
		_fail("Mon3tr 处于临界完整性时，即使修满也不应直接进入融毁。")

	manager.enter_kaltsit_meltdown()
	manager.player.meta["mon3tr_integrity"] = 6
	manager.damage_mon3tr(2, "smoke_exit")
	if manager.is_mon3tr_meltdown():
		_fail("融毁中完整性低于 5 后应退出融毁。")
	if manager.mon3tr_max_integrity() != 10:
		_fail("融毁退出后 Mon3tr 上限应回到 10，实际 %d。" % manager.mon3tr_max_integrity())
	_free_manager(manager)

func _check_mon3tr_card_damage(run_manager: Node, character: CharacterData, enemy: EnemyData) -> void:
	var manager: BattleManager = _new_manager(run_manager, character, enemy)
	if manager == null:
		return
	var card_db: Dictionary = Util.load_card_db(ResourceLoader.CACHE_MODE_IGNORE)
	var command_card: CardData = card_db.get("kaltsit_b05_mon3tr_command", null) as CardData
	if command_card == null:
		_fail("缺少凯尔希基础 Mon3tr 指令牌。")
		_free_manager(manager)
		return
	manager.deck.hand.clear()
	manager.deck.hand.append(command_card)
	manager.player.energy = command_card.cost
	var before_hp: int = manager.enemies[0].hp
	if not manager.play_card(0, 0):
		_fail("凯尔希 Mon3tr 指令牌应可正常打出。")
	elif manager.enemies[0].hp >= before_hp:
		_fail("凯尔希 Mon3tr 指令牌应造成伤害。")

	manager.enemies[0].hp = manager.enemies[0].max_hp
	manager.enemies[0].block = 20
	manager.enter_kaltsit_meltdown()
	before_hp = manager.enemies[0].hp
	manager.mon3tr_attack(manager.enemies[0], 8, command_card)
	if manager.enemies[0].hp >= before_hp:
		_fail("融毁中的 Mon3tr 伤害应无视护盾并造成生命伤害。")
	_free_manager(manager)

func _new_manager(run_manager: Node, character: CharacterData, enemy: EnemyData) -> BattleManager:
	run_manager.start_new_run(character, 5252)
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
