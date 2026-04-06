extends Node

var failures: Array[String] = []

func _ready() -> void:
	var exit_code: int = _run()
	get_tree().quit(exit_code)

func _run() -> int:
	var char_data: CharacterData = Util.load_character("amiya")
	if char_data == null:
		_fail("无法加载 Amiya 角色资源。")
		return 1

	_test_floor_boss_mapping()
	_test_maps_have_no_rest_nodes(char_data)
	_test_interfloor_rest_and_victory_flow(char_data)
	_test_hidden_floor_flow(char_data)

	if failures.is_empty():
		print("RUN_FLOW_SMOKE_TEST_OK")
		return 0

	push_error("RUN_FLOW_SMOKE_TEST_FAILED")
	for failure in failures:
		push_error(failure)
	return 1

func _test_floor_boss_mapping() -> void:
	if Util.get_boss_enemies(1) != ["scout_chief"]:
		_fail("第 1 层 Boss 映射异常。")
	if Util.get_boss_enemies(2) != ["lockdown_core"]:
		_fail("第 2 层 Boss 映射异常。")
	if Util.get_boss_enemies(3) != ["w_boss"]:
		_fail("第 3 层 Boss 应为 W。")
	if Util.get_boss_enemies(4) != ["ash_echo"]:
		_fail("第 4 层 Boss 应为灰烬回响。")

func _test_maps_have_no_rest_nodes(char_data: CharacterData) -> void:
	RunManager.start_new_run(char_data, 2222)
	for floor_index in [1, 2, 3, 4]:
		RunManager.current_floor = floor_index
		RunManager._generate_floor_map(floor_index)
		for node in RunManager.map_nodes:
			if node.node_type == "rest":
				_fail("第 %d 层地图里不应再生成休整节点。" % floor_index)

func _test_interfloor_rest_and_victory_flow(char_data: CharacterData) -> void:
	RunManager.start_new_run(char_data, 3333)
	RunManager.current_floor = 1
	RunManager.pending_interfloor_rest = false
	RunManager.run_won = false
	RunManager.story_flags.erase("run_complete")
	RunManager._finish_floor()
	if RunManager.current_floor != 2:
		_fail("第 1 层结算后应进入第 2 层。")
	if not RunManager.should_take_interfloor_rest():
		_fail("第 1 层结算后应强制进入层间休整。")
	RunManager.hp = 12
	RunManager.heal_full()
	if RunManager.hp != RunManager.max_hp:
		_fail("层间休整应回满生命值。")
	RunManager.consume_interfloor_rest()
	if RunManager.should_take_interfloor_rest():
		_fail("层间休整消耗后不应继续保留。")

	RunManager.current_floor = 3
	RunManager.story_flags.clear()
	RunManager.pending_interfloor_rest = false
	RunManager.run_won = false
	RunManager._finish_floor()
	if not RunManager.has_flag("run_complete"):
		_fail("击败 W 且未进隐藏层时应直接标记通关。")
	if not RunManager.run_won:
		_fail("击败 W 后应标记为正式胜利。")

func _test_hidden_floor_flow(char_data: CharacterData) -> void:
	RunManager.start_new_run(char_data, 4444)
	RunManager.current_floor = 3
	RunManager.story_flags.clear()
	RunManager.story_flags["accept_burden_1"] = true
	RunManager.story_flags["accept_burden_2"] = true
	RunManager.pending_interfloor_rest = false
	RunManager.run_won = false
	RunManager._finish_floor()
	if RunManager.current_floor != 4:
		_fail("满足隐藏条件后，第 3 层结算应进入第 4 层。")
	if not RunManager.should_take_interfloor_rest():
		_fail("进入隐藏层前应先强制层间休整。")
	if not RunManager.run_won:
		_fail("进入隐藏层前也应保留已经击败 W 的正式胜利状态。")

func _fail(message: String) -> void:
	failures.append(message)
