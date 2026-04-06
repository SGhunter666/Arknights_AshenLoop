extends Node

var failures: Array[String] = []

func _ready() -> void:
	var exit_code: int = await _run()
	get_tree().quit(exit_code)

func _run() -> int:
	var char_data: CharacterData = Util.load_character("amiya")
	if char_data == null:
		_fail("无法加载 Amiya 角色资源。")
		return 1

	RunManager.start_new_run(char_data, 67890)

	await _instantiate_scene("res://scenes/MainMenu.tscn")
	await _instantiate_scene("res://scenes/SinglePlayerScene.tscn")
	await _instantiate_scene("res://scenes/SettingsScene.tscn")
	await _instantiate_scene("res://scenes/EncyclopediaScene.tscn")
	await _instantiate_scene("res://scenes/QuitScene.tscn")
	await _instantiate_scene("res://scenes/DefeatScene.tscn")

	await _prepare_victory_state()
	await _instantiate_scene("res://scenes/VictoryScene.tscn")

	await _prepare_map_state()
	await _instantiate_scene("res://scenes/MapScene.tscn")

	await _prepare_battle_state()
	await _instantiate_scene("res://scenes/BattleScene.tscn")

	await _prepare_event_state()
	await _instantiate_scene("res://scenes/EventScene.tscn")

	await _prepare_reward_state()
	await _instantiate_scene("res://scenes/RewardScene.tscn")

	await _prepare_shop_state()
	await _instantiate_scene("res://scenes/ShopScene.tscn")

	await _prepare_rest_state()
	await _instantiate_scene("res://scenes/RestScene.tscn")

	if failures.is_empty():
		print("UI_SCENE_SMOKE_TEST_OK")
		return 0

	push_error("UI_SCENE_SMOKE_TEST_FAILED")
	for failure in failures:
		push_error(failure)
	return 1

func _instantiate_scene(path: String) -> void:
	var packed: PackedScene = load(path)
	if packed == null:
		_fail("无法加载场景：%s" % path)
		return
	var node: Node = packed.instantiate()
	if node == null:
		_fail("无法实例化场景：%s" % path)
		return
	add_child(node)
	await get_tree().process_frame
	await get_tree().process_frame
	if is_instance_valid(node):
		node.queue_free()
	await get_tree().process_frame

func _prepare_map_state() -> void:
	RunManager.current_node_id = ""
	RunManager.pending_rewards = {}
	RunManager.pending_interfloor_rest = false

func _prepare_battle_state() -> void:
	var battle_node: MapNodeModel = _find_or_build_node("battle")
	RunManager.current_node_id = battle_node.id
	RunManager.map_nodes = [battle_node]

func _prepare_event_state() -> void:
	var event_node: MapNodeModel = _find_or_build_node("event")
	RunManager.current_node_id = event_node.id
	RunManager.map_nodes = [event_node]

func _prepare_reward_state() -> void:
	RunManager.pending_rewards = {
		"type": "battle_reward",
		"text": "Smoke Test Reward",
		"card_choices": ["focus_pulse", "emergency_shield", "signal_relay"]
	}

func _prepare_shop_state() -> void:
	RunManager.current_node_id = _find_or_build_node("shop").id

func _prepare_rest_state() -> void:
	RunManager.current_node_id = _find_or_build_node("rest").id
	RunManager.pending_interfloor_rest = true

func _prepare_victory_state() -> void:
	RunManager.last_run_summary = {
		"floor": 3,
		"gold": 233,
		"deck_size": RunManager.deck.size(),
		"modules": RunManager.modules.size()
	}
	RunManager.set_flag("run_complete", true)

func _find_or_build_node(node_type: String) -> MapNodeModel:
	for node in RunManager.map_nodes:
		if node.node_type == node_type:
			return node
	var node: MapNodeModel = MapNodeModel.new()
	node.id = "smoke_%s" % node_type
	node.node_type = node_type
	node.floor_index = RunManager.current_floor
	node.row = 0
	node.lane = 0
	node.index = 0
	node.metadata = Util.generate_node_metadata(RunManager.current_floor, node_type, 0, RandomNumberGenerator.new())
	if node_type == "event":
		node.metadata["event_id"] = "temporary_ward"
	if node_type == "battle":
		node.metadata["enemy_ids"] = ["reunion_scout"]
	return node

func _fail(message: String) -> void:
	failures.append(message)
