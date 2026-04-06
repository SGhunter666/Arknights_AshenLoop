class_name UnitState
extends RefCounted

var id: String = ""
var display_name: String = ""
var max_hp: int = 1
var hp: int = 1
var block: int = 0
var energy: int = 0
var will: int = 0
var intent: Dictionary = {}
var statuses: Dictionary = {}
var meta: Dictionary = {}

func is_dead() -> bool:
	return hp <= 0

func add_block(value: int) -> void:
	block += max(0, value)

func lose_hp(value: int) -> void:
	hp = max(0, hp - max(0, value))

func heal(value: int) -> void:
	hp = min(max_hp, hp + max(0, value))

func gain_will(value: int, max_will: int = 10) -> void:
	will = clamp(will + value, 0, max_will)

func spend_will(value: int) -> int:
	var spent: int = min(value, will)
	will -= spent
	return spent

func apply_status(status_id: String, amount: int) -> void:
	statuses[status_id] = int(statuses.get(status_id, 0)) + amount

func clear_status(status_id: String) -> void:
	statuses.erase(status_id)
