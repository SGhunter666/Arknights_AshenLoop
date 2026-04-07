class_name UnitState
extends RefCounted

var id: String = ""
var display_name: String = ""
var max_hp: int = 1
var hp: int = 1
var block: int = 0
var energy: int = 0
var will: int = 0
var resonance: int = 0
var overload: int = 0
var echo_percent: int = 0
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

func add_resonance(value: int, max_resonance: int = 9) -> void:
	resonance = clamp(resonance + max(0, value), 0, max_resonance)

func consume_resonance(value: int) -> int:
	var spent: int = min(value, resonance)
	resonance -= spent
	return spent

func gain_overload(value: int) -> void:
	overload = max(0, overload + max(0, value))

func reduce_overload(value: int) -> void:
	overload = max(0, overload - max(0, value))

func clear_echo() -> void:
	echo_percent = 0

func apply_status(status_id: String, amount: int) -> void:
	statuses[status_id] = int(statuses.get(status_id, 0)) + amount

func clear_status(status_id: String) -> void:
	statuses.erase(status_id)
