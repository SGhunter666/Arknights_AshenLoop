extends SceneTree

func _initialize() -> void:
	print("EVENT_REWARD_CHARACTER_FILTER_SMOKE_TEST_START")
	var checked_count: int = 0
	var reward_sets: Array[Dictionary] = _read_event_reward_card_sets()
	for character_id in ["amiya", "exusiai"]:
		for reward_set in reward_sets:
			var raw_cards: Array = reward_set.get("cards", [])
			if raw_cards.is_empty():
				continue
			var filtered_cards: Array[String] = Util.normalize_character_card_choices(
				raw_cards,
				character_id,
				raw_cards.size(),
				1701 + checked_count,
				{}
			)
			checked_count += 1
			for card_id in filtered_cards:
				if not Util.is_card_available_to_character(card_id, character_id):
					_fail("%s 事件奖励混入了非本角色牌：%s -> %s" % [character_id, String(reward_set.get("event", "")), card_id])
	print("EVENT_REWARD_CHARACTER_FILTER_SMOKE_TEST_OK checked=%d" % checked_count)
	quit(0)

func _read_event_reward_card_sets() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var dir: DirAccess = DirAccess.open("res://data/events")
	if dir == null:
		_fail("无法打开事件目录。")
		return result
	var regex := RegEx.new()
	regex.compile("\"reward_cards\": PackedStringArray\\(([^)]*)\\)")
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while not file_name.is_empty():
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var path: String = "res://data/events/%s" % file_name
			var file := FileAccess.open(path, FileAccess.READ)
			if file != null:
				var text: String = file.get_as_text()
				for match_result in regex.search_all(text):
					var cards: Array = []
					var raw: String = match_result.get_string(1)
					for part in raw.split(",", false):
						var card_id: String = String(part).strip_edges().trim_prefix("\"").trim_suffix("\"")
						if not card_id.is_empty():
							cards.append(card_id)
					result.append({"event": file_name.trim_suffix(".tres"), "cards": cards})
		file_name = dir.get_next()
	dir.list_dir_end()
	return result

func _fail(message: String) -> void:
	push_error(message)
	print("EVENT_REWARD_CHARACTER_FILTER_SMOKE_TEST_FAIL: %s" % message)
	quit(1)
