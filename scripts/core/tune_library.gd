class_name TuneLibrary
extends RefCounted

const TUNES: Dictionary = {
	"resonance_apply_plus_one": {
		"title": "共振棱线",
		"short": "施加共振额外 +1",
		"description": "你施加 Resonance 时额外 +1。适合共振铺场和引爆流。",
		"archetype": "resonance_combo",
		"accent": "#71d7ff",
	},
	"support_echo_seed": {
		"title": "指挥回响",
		"short": "首张 Support 赋予 Echo",
		"description": "每回合第一张 Support 结算后，获得 Echo 50%，用于下一张 Arts。",
		"archetype": "command_support",
		"accent": "#f3b36d",
	},
	"will_arts_discount": {
		"title": "意志聚焦",
		"short": "Will >= 4 时首张 Arts -1 费",
		"description": "若当前 Will 至少为 4，本回合第一张 Arts 牌费用 -1。",
		"archetype": "will_burst",
		"accent": "#95a2ff",
	},
	"overload_guard_matrix": {
		"title": "负荷护矩",
		"short": "首层 Overload 转为护盾",
		"description": "每回合第一次获得 Overload 时，立刻获得 6 点护盾。",
		"archetype": "overload_sacrifice",
		"accent": "#ff8d63",
	},
	"channel_quickcast": {
		"title": "预演快启",
		"short": "首张 Channel 抽 1 并 +1 Will",
		"description": "每场战斗第一次打出 Channel 后，立刻抽 1 并获得 1 Will。",
		"archetype": "will_burst",
		"accent": "#7bd9d2",
	},
	"echo_guard_lattice": {
		"title": "回响护格",
		"short": "获得 Echo 时追加护盾",
		"description": "每次获得 Echo 时，立刻获得 5 点护盾。",
		"archetype": "resonance_combo",
		"accent": "#b8f1ff",
	},
}

static func all_tunes() -> Dictionary:
	return TUNES.duplicate(true)

static func data(tune_id: String) -> Dictionary:
	return (TUNES.get(tune_id, {}) as Dictionary).duplicate(true)

static func title(tune_id: String) -> String:
	return String(TUNES.get(tune_id, {}).get("title", tune_id))

static func short_text(tune_id: String) -> String:
	return String(TUNES.get(tune_id, {}).get("short", ""))

static func description(tune_id: String) -> String:
	return String(TUNES.get(tune_id, {}).get("description", ""))

static func archetype(tune_id: String) -> String:
	return String(TUNES.get(tune_id, {}).get("archetype", "neutral"))

static func accent(tune_id: String) -> Color:
	return Color(String(TUNES.get(tune_id, {}).get("accent", "#ffffff")))

static func available_tune_ids(excluded: Array[String] = []) -> Array[String]:
	var result: Array[String] = []
	var tune_ids: Array[String] = []
	for tune_id in TUNES.keys():
		tune_ids.append(String(tune_id))
	tune_ids.sort()
	for tune_id in tune_ids:
		if excluded.has(tune_id):
			continue
		result.append(tune_id)
	return result

static func offer_tunes(seed_value: int, count: int = 3, excluded: Array[String] = []) -> Array[String]:
	var available: Array[String] = available_tune_ids(excluded)
	if available.is_empty():
		return []
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value if seed_value != 0 else 1
	var result: Array[String] = []
	while result.size() < count and not available.is_empty():
		var index: int = rng.randi_range(0, available.size() - 1)
		result.append(available[index])
		available.remove_at(index)
	return result
