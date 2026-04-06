class_name MapGenerator
extends RefCounted

const FLOOR_RULES := {
	1: {"rows": 7, "lanes": 3},
	2: {"rows": 7, "lanes": 3},
	3: {"rows": 7, "lanes": 3},
	4: {"rows": 4, "lanes": 3}
}

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _init(seed_value: int = 1) -> void:
	rng.seed = seed_value

func generate_floor(floor_index: int) -> Array[MapNodeModel]:
	var config: Dictionary = FLOOR_RULES.get(floor_index, FLOOR_RULES[1])
	var row_count: int = int(config.get("rows", 7))
	var lane_count: int = int(config.get("lanes", 3))
	var nodes: Array[MapNodeModel] = []
	var rows: Array = []
	var flat_index: int = 0
	for row_index in range(row_count):
		var row_nodes: Array = []
		var row_types: Array = _generate_row_types(floor_index, row_index, row_count, lane_count)
		for lane_index in range(row_types.size()):
			var node: MapNodeModel = MapNodeModel.new()
			node.floor_index = floor_index
			node.index = flat_index
			node.row = row_index
			node.lane = lane_index
			node.node_type = String(row_types[lane_index])
			node.id = "f%s_r%s_l%s" % [floor_index, row_index, lane_index]
			node.metadata = Util.generate_node_metadata(floor_index, node.node_type, flat_index, rng)
			row_nodes.append(node)
			nodes.append(node)
			flat_index += 1
		rows.append(row_nodes)
	for row_index in range(rows.size() - 1):
		var current_row: Array = rows[row_index]
		var next_row: Array = rows[row_index + 1]
		for node in current_row:
			node.next_ids = _build_links(node, next_row)
	return nodes

func _generate_row_types(floor_index: int, row_index: int, row_count: int, lane_count: int) -> Array:
	if row_index == row_count - 1:
		return ["boss"]
	var pool: Array = _pool_for_row(floor_index, row_index, row_count)
	var row_types: Array = []
	for _lane_index in range(lane_count):
		row_types.append(String(pool[rng.randi_range(0, pool.size() - 1)]))
	_ensure_row_variety(row_types, pool)
	return row_types

func _pool_for_row(floor_index: int, row_index: int, row_count: int) -> Array:
	if row_index == 0:
		return ["battle", "battle", "battle"]
	if row_index == 1:
		return ["battle", "battle", "event"]
	if row_index == row_count - 2:
		return ["battle", "story", "event"]
	match floor_index:
		1:
			return ["battle", "event", "elite"]
		2:
			return ["battle", "event", "shop", "elite"]
		3:
			return ["battle", "event", "shop", "elite", "story"]
		4:
			return ["story", "event", "elite", "battle"]
	return ["battle", "event"]

func _ensure_row_variety(row_types: Array, pool: Array) -> void:
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
	for next_node in next_row:
		if abs(next_node.lane - node.lane) <= 1:
			links.append(next_node.id)
	if links.is_empty():
		links.append(next_row[min(node.lane, next_row.size() - 1)].id)
	return links
