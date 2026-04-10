class_name MapGenerator
extends RefCounted

const FLOOR_RULES := {
	1: {"rows": 7, "lanes": 5, "min_nodes": 2, "max_nodes": 3},
	2: {"rows": 7, "lanes": 5, "min_nodes": 2, "max_nodes": 4},
	3: {"rows": 7, "lanes": 6, "min_nodes": 2, "max_nodes": 4},
	4: {"rows": 4, "lanes": 4, "min_nodes": 2, "max_nodes": 3}
}

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _init(seed_value: int = 1) -> void:
	rng.seed = seed_value

func generate_floor(floor_index: int) -> Array[MapNodeModel]:
	var config: Dictionary = FLOOR_RULES.get(floor_index, FLOOR_RULES[1])
	var row_count: int = int(config.get("rows", 7))
	var lane_count: int = int(config.get("lanes", 3))
	var min_nodes: int = int(config.get("min_nodes", 2))
	var max_nodes: int = int(config.get("max_nodes", 3))
	var nodes: Array[MapNodeModel] = []
	var rows: Array = []
	var battle_generation_state: Dictionary = {
		"battle_count": 0,
		"test_counts": {},
		"recent_primary_tests": []
	}
	var flat_index: int = 0
	for row_index in range(row_count):
		var row_nodes: Array = []
		var lane_slots: Array[int] = _lane_slots_for_row(row_index, row_count, lane_count, min_nodes, max_nodes)
		var row_types: Array = _generate_row_types(floor_index, row_index, row_count, lane_slots.size())
		for lane_index in range(row_types.size()):
			var node: MapNodeModel = MapNodeModel.new()
			node.floor_index = floor_index
			node.index = flat_index
			node.row = row_index
			node.lane = lane_slots[lane_index]
			node.node_type = String(row_types[lane_index])
			node.id = "f%s_r%s_l%s" % [floor_index, row_index, node.lane]
			node.metadata = Util.generate_node_metadata(floor_index, node.node_type, flat_index, rng, battle_generation_state)
			row_nodes.append(node)
			nodes.append(node)
			flat_index += 1
		rows.append(row_nodes)
	for row_index in range(rows.size() - 1):
		var current_row: Array = rows[row_index]
		var next_row: Array = rows[row_index + 1]
		for node in current_row:
			node.next_ids = _build_links(node, next_row)
		_ensure_incoming_links(current_row, next_row)
	return nodes

func _lane_slots_for_row(row_index: int, row_count: int, lane_count: int, min_nodes: int, max_nodes: int) -> Array[int]:
	if row_index == row_count - 1:
		return [int(floor(float(lane_count - 1) * 0.5))]
	var node_count: int = rng.randi_range(min_nodes, max_nodes)
	if row_index == 0:
		node_count = max(2, min(node_count, 3))
	if row_index == row_count - 2:
		node_count = max(2, min(node_count, 3))
	node_count = min(node_count, lane_count)
	var lane_candidates: Array[int] = []
	for lane_index in range(lane_count):
		lane_candidates.append(lane_index)
	lane_candidates.shuffle()
	var picked: Array[int] = []
	while picked.size() < node_count and not lane_candidates.is_empty():
		picked.append(lane_candidates.pop_front())
	picked.sort()
	return picked

func _generate_row_types(floor_index: int, row_index: int, row_count: int, lane_count: int) -> Array[String]:
	if row_index == row_count - 1:
		var boss_row: Array[String] = []
		boss_row.append("boss")
		return boss_row
	var pool: Array = _pool_for_row(floor_index, row_index, row_count)
	var row_types: Array[String] = []
	for _lane_index in range(lane_count):
		row_types.append(String(pool[rng.randi_range(0, pool.size() - 1)]))
	_ensure_row_variety(row_types, pool)
	return row_types

func _pool_for_row(floor_index: int, row_index: int, row_count: int) -> Array[String]:
	var pool: Array[String] = []
	if row_index == 0:
		pool.append("battle")
		pool.append("battle")
		pool.append("battle")
		return pool
	if row_index == 1:
		pool.append("battle")
		pool.append("battle")
		pool.append("event")
		return pool
	if row_index == row_count - 2:
		pool.append("battle")
		pool.append("story")
		pool.append("event")
		return pool
	match floor_index:
		1:
			pool.append("battle")
			pool.append("event")
			pool.append("elite")
			pool.append("rest")
			return pool
		2:
			pool.append("battle")
			pool.append("event")
			pool.append("shop")
			pool.append("elite")
			pool.append("rest")
			return pool
		3:
			pool.append("battle")
			pool.append("event")
			pool.append("shop")
			pool.append("elite")
			pool.append("story")
			pool.append("rest")
			return pool
		4:
			pool.append("story")
			pool.append("event")
			pool.append("elite")
			pool.append("battle")
			return pool
	pool.append("battle")
	pool.append("event")
	return pool

func _ensure_row_variety(row_types: Array[String], pool: Array[String]) -> void:
	var has_non_battle: bool = false
	for row_type in row_types:
		if String(row_type) != "battle":
			has_non_battle = true
			break
	if not has_non_battle:
		var special_pool: Array = []
		for option in pool:
			if String(option) != "battle":
				special_pool.append(option)
		if not special_pool.is_empty():
			row_types[rng.randi_range(0, row_types.size() - 1)] = String(special_pool[rng.randi_range(0, special_pool.size() - 1)])

func _build_links(node: MapNodeModel, next_row: Array) -> Array[String]:
	var links: Array[String] = []
	if next_row.is_empty():
		return links
	if next_row.size() == 1:
		links.append(next_row[0].id)
		return links
	var sorted_next: Array = next_row.duplicate()
	sorted_next.sort_custom(func(a: MapNodeModel, b: MapNodeModel) -> bool:
		var a_dist: int = abs(a.lane - node.lane)
		var b_dist: int = abs(b.lane - node.lane)
		if a_dist == b_dist:
			return a.lane < b.lane
		return a_dist < b_dist
	)
	links.append((sorted_next[0] as MapNodeModel).id)
	if sorted_next.size() > 1:
		var secondary: MapNodeModel = sorted_next[1] as MapNodeModel
		if abs(secondary.lane - node.lane) <= 2 or rng.randf() < 0.35:
			links.append(secondary.id)
	return links

func _ensure_incoming_links(current_row: Array, next_row: Array) -> void:
	for next_node_variant in next_row:
		var next_node: MapNodeModel = next_node_variant
		var has_incoming: bool = false
		for current_node_variant in current_row:
			var current_node: MapNodeModel = current_node_variant
			if current_node.next_ids.has(next_node.id):
				has_incoming = true
				break
		if has_incoming:
			continue
		var closest_current: MapNodeModel = null
		var closest_distance: int = 999999
		for current_node_variant in current_row:
			var current_node: MapNodeModel = current_node_variant
			var lane_distance: int = abs(current_node.lane - next_node.lane)
			if lane_distance < closest_distance:
				closest_distance = lane_distance
				closest_current = current_node
		if closest_current != null and not closest_current.next_ids.has(next_node.id):
			closest_current.next_ids.append(next_node.id)
