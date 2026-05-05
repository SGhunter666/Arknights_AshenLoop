#!/usr/bin/env python3
from __future__ import annotations

import re
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SPEC = ROOT / "tmp" / "kaltsit_spec.txt"
OUT = ROOT / "data" / "cards"


RARITY_BY_PREFIX = {
	"B": "Starter",
	"C": "Common",
	"U": "Uncommon",
	"R": "Rare",
	"L": "Legendary",
	"S": "Status",
}


def esc(value: str) -> str:
	return value.replace("\\", "\\\\").replace('"', '\\"')


def slugify(name: str) -> str:
	value = unicodedata.normalize("NFKD", name)
	value = value.replace("’", "").replace("'", "")
	value = re.sub(r"[^A-Za-z0-9]+", "_", value).strip("_").lower()
	return value or "card"


def numbers(text: str) -> list[int]:
	return [int(match.group(0)) for match in re.finditer(r"\d+", text)]


def tags_from_text(name: str, effect: str, card_type: str, rarity: str) -> list[str]:
	joined = f"{name} {effect}"
	tags: list[str] = []
	def add(tag: str) -> None:
		if tag not in tags:
			tags.append(tag)

	if card_type == "Attack":
		add("Scalpel")
	if rarity in ["Status", "Curse"]:
		add(rarity)
	if "Mon3tr" in joined:
		add("Mon3tr")
	if "Command" in joined or "指令" in joined:
		add("Command")
	if "Medical" in joined or "Heal" in joined or "Treatment" in joined or "Clinical" in joined or "Care" in joined or "Surgery" in joined or "Infusion" in joined:
		add("Medical")
	if "Heal" in joined or "治疗" in joined:
		add("Heal")
	if "Repair" in joined or "Integrity" in joined or "完整性" in joined:
		add("Repair")
	if "Meltdown" in joined or "融毁" in joined:
		add("Meltdown")
	if "Protocol" in joined or card_type == "Power":
		add("Protocol")
	if "Block" in joined:
		add("Block")
	if "Draw" in joined or "draw" in joined:
		add("Draw")
	if "all enemies" in joined:
		add("AOE")
	if "twice" in joined or "three times" in joined:
		add("MultiHit")
	if "overflow" in joined.lower():
		add("Overflow")
	if "Emergency" in joined or "Crisis" in joined:
		add("Emergency")
	return tags


def resource_id(code: str, en_name: str) -> str:
	prefix = code.split("_", 1)[1][0].lower()
	return f"kaltsit_{prefix}{code[-2:]}_{slugify(en_name)}"


def eff(effect_type: str, amount: int = 0, target: str = "enemy", amount_2: int = 0, status_id: str = "", tag: str = "", condition: str = "") -> dict:
	return {
		"effect_type": effect_type,
		"amount": amount,
		"amount_2": amount_2,
		"target": target,
		"status_id": status_id,
		"tag": tag,
		"condition": condition,
	}


def condition_for_text(text: str) -> str:
	parts: list[str] = []
	if re.search(r"Integrity\s*<=\s*2", text) or "Critical Integrity" in text:
		parts.append("mon3tr_integrity_lte:2")
	elif re.search(r"Integrity\s*<=\s*3", text):
		parts.append("mon3tr_integrity_lte:3")
	elif re.search(r"Integrity\s*<=\s*5", text):
		parts.append("mon3tr_integrity_lte:5")
	if re.search(r"Integrity\s*>=\s*8", text):
		parts.append("mon3tr_integrity_gte:8")
	if "HP <= 40%" in text:
		parts.append("player_hp_lte_percent:40")
	elif "HP <= 50%" in text:
		parts.append("player_hp_lte_percent:50")
	if "in Meltdown" in text or "Only usable in Meltdown" in text:
		parts.append("mon3tr_meltdown")
	if "Medical was played this turn" in text:
		parts.append("played_medical_this_turn_gte:1")
	if "Command" in text and "was drawn" not in text and "First Command" not in text and "next Command" not in text and "Command card" not in text and "played this turn" in text:
		parts.append("played_command_this_turn_gte:1")
	if "Mon3tr was repaired this turn" in text:
		parts.append("mon3tr_repaired_this_turn")
	if "HP was healed this turn" in text:
		parts.append("hp_healed_this_turn")
	if "hand size <= 2" in text:
		parts.append("hand_size_lte:2")
	return "&".join(parts)


def effects_from_text(text: str) -> tuple[list[dict], list[dict]]:
	base: list[dict] = []
	conditional: list[dict] = []
	condition = condition_for_text(text)
	nums = numbers(text)

	def target_list() -> list[dict]:
		return conditional if condition else base

	if "take 2 damage" in text or "Drawn: take 2 damage" in text:
		base.append(eff("lose_hp", 2, "self"))
	elif "First Command this turn costs +1" in text:
		base.append(eff("set_next_tag_cost_delta", 1, "self", tag="Command"))
	elif "First Medical this turn has effect -3" in text:
		base.append(eff("set_mon3tr_repair_bonus", -3, "self"))
	elif "Next Mon3tr attack this turn deals -4" in text:
		base.append(eff("set_mon3tr_next_attack_bonus", -4, "self"))
	elif "Draw 1 fewer card" in text:
		base.append(eff("set_meta_value", -1, "self", status_id="next_turn_hand_size"))
	elif "Ethical Echo" in text:
		base.append(eff("lose_hp", 1, "self", condition="hp_healed_this_turn"))

	if "Repair Mon3tr to max" in text or "repair to 10" in text:
		base.append(eff("repair_mon3tr_to_max", 0, "self"))

	if "Enter Meltdown directly" in text or "enter Meltdown" in text or "enter Meltdown;" in text:
		target_list().append(eff("enter_kaltsit_meltdown", 0, "self"))

	if "base max Integrity +" in text:
		base.append(eff("set_mon3tr_max_bonus", nums[-1] if nums else 2, "self"))
	elif "Meltdown max Integrity becomes" in text:
		base.append(eff("set_meta_value", nums[0] if nums else 18, "self", status_id="mon3tr_meltdown_max_override"))
	elif "Mon3tr max Integrity becomes" in text:
		base.append(eff("set_meta_value", nums[0] if nums else 20, "self", status_id="mon3tr_meltdown_max_override"))

	if "Turn-start Mon3tr auto repair +" in text or "Mon3tr turn-start auto repair +" in text:
		base.append(eff("set_mon3tr_auto_repair_bonus", nums[-1] if nums else 1, "self"))
	if "Mon3tr damage +" in text:
		base.append(eff("set_mon3tr_attack_bonus", nums[-1] if nums else 3, "self"))
	if "Next Command" in text and "deals +" in text:
		base.append(eff("set_next_tag_damage_bonus", nums[-1] if nums else 4, "self", tag="Command"))
	if "Next Mon3tr attack triggers twice" in text:
		base.append(eff("set_mon3tr_next_attack_multiplier", nums[-1] if nums else 150, "self"))
	if "Next two Command" in text:
		base.append(eff("set_next_tag_damage_bonus", nums[-1] if nums else 2, "self", tag="Command"))
	if "Critical Integrity no longer reduces Mon3tr damage" in text:
		base.append(eff("set_mon3tr_low_integrity_no_penalty", 1, "self"))
	if "Integrity loss this turn is reduced" in text:
		base.append(eff("set_integrity_loss_reduction", nums[-1] if nums else 2, "self"))
	if "First Integrity loss each turn repairs" in text:
		base.append(eff("set_mon3tr_reactive_repair", nums[-1] if nums else 1, "self"))
	if "Meltdown exits at Integrity < 3" in text:
		base.append(eff("set_meta_value", 3, "self", status_id="mon3tr_meltdown_exit_threshold"))

	heal_match = re.search(r"Heal\s+(\d+)", text)
	if heal_match:
		heal_amount = int(heal_match.group(1))
		if "otherwise gain" in text or "otherwise heal" in text:
			base.append(eff("heal_if_low_else_block", heal_amount, "self", amount_2=50 if "50%" in text else 40))
		else:
			base.append(eff("heal_or_block_if_full" if "full HP" in text else "heal", heal_amount, "self", amount_2=heal_amount))

	if "gain Block equal to half" in text and heal_match:
		base.append(eff("block", max(1, int(heal_match.group(1)) // 2), "self"))
	else:
		block_match = re.search(r"gain\s+(\d+)\s+Block", text, re.IGNORECASE)
		if block_match:
			base.append(eff("block", int(block_match.group(1)), "self"))
		elif re.search(r"Gain\s+(\d+)\s+Block", text):
			base.append(eff("block", int(re.search(r"Gain\s+(\d+)\s+Block", text).group(1)), "self"))

	repair_match = re.search(r"[Rr]epair(?: Mon3tr)?\s+(\d+)", text)
	if repair_match:
		base.append(eff("repair_mon3tr", int(repair_match.group(1)), "self"))
	elif "repairs Mon3tr 1" in text:
		base.append(eff("repair_mon3tr", 1, "self"))

	if "Mon3tr loses" in text:
		loss = int(re.search(r"Mon3tr loses\s+(\d+)", text).group(1))
		base.append(eff("damage_mon3tr", loss, "self"))

	draw_match = re.search(r"Draw\s+(\d+)", text)
	if draw_match:
		if "Medical or Command" in text or "drawn card is Medical or Command" in text:
			base.append(eff("draw_discount_medical_command", int(draw_match.group(1)), "self", amount_2=1))
		else:
			base.append(eff("draw", int(draw_match.group(1)), "self"))
	elif "draw 1" in text:
		target_list().append(eff("draw", 1, "self"))

	if "gain 1 Energy" in text:
		target_list().append(eff("gain_energy", 1, "self"))

	if "Mon3tr deals" in text:
		damage_all = "all enemies" in text
		hits = 1
		if "twice" in text:
			hits = 2
		elif "three times" in text:
			hits = 3
		damage_number = 0
		damage_match = re.search(r"Mon3tr deals\s+(\d+)", text)
		if damage_match:
			damage_number = int(damage_match.group(1))
		elif "equal to current Integrity" in text:
			base.append(eff("mon3tr_damage_by_integrity", 0, "enemy"))
		if damage_number > 0:
			target_list().append(eff("mon3tr_damage_all" if damage_all else "mon3tr_damage", damage_number, "all_enemies" if damage_all else "enemy", amount_2=hits))

	if "Kal’tsit deals" in text or "Kal'tsit deals" in text:
		damage_match = re.search(r"Kal[’']tsit deals\s+(\d+)", text)
		if damage_match:
			base.append(eff("damage", int(damage_match.group(1)), "enemy"))
	if text.startswith("Deal "):
		damage_match = re.search(r"Deal\s+(\d+)", text)
		if damage_match:
			base.append(eff("damage", int(damage_match.group(1)), "enemy"))

	if "Lose" in text and "HP" in text:
		loss_match = re.search(r"Lose\s+(\d+)\s+HP", text)
		if loss_match:
			base.append(eff("lose_hp", int(loss_match.group(1)), "self"))

	if not base and conditional:
		base = conditional
		conditional = []
	if not base and not conditional:
		base.append(eff("set_meta_flag", 1, "self", status_id="kaltsit_" + slugify(text)[:32]))
	return base, conditional


def upgraded_effect_text(base_text: str, upgrade_text: str) -> str:
	if not upgrade_text:
		return base_text
	if "cost 0" in upgrade_text:
		return base_text
	replacements = numbers(upgrade_text)
	if not replacements:
		return base_text
	index = 0
	def repl(match: re.Match[str]) -> str:
		nonlocal index
		if index >= len(replacements):
			return match.group(0)
		value = str(replacements[index])
		index += 1
		return value
	return re.sub(r"\d+", repl, base_text)


BASIC = [
	("KS_B01", "Surgical Strike", "手术切击", 1, "Attack", ["Scalpel"], "造成 6 点伤害。融毁中凯尔希攻击牌伤害 +50%。", [eff("damage", 6, "enemy")], "造成 8 点伤害。融毁中凯尔希攻击牌伤害 +50%。", [eff("damage", 8, "enemy")]),
	("KS_B02", "Tactical Guard", "战术护持", 1, "Skill", ["Block", "Medical", "Repair"], "获得 5 护盾，修复 Mon3tr 1 点完整性。", [eff("block", 5, "self"), eff("repair_mon3tr", 1, "self")], "获得 7 护盾，修复 Mon3tr 2 点完整性。", [eff("block", 7, "self"), eff("repair_mon3tr", 2, "self")]),
	("KS_B03", "Field Treatment", "现场治疗", 1, "Skill", ["Medical", "Heal"], "治疗 5 点生命；若生命已满，改为获得 5 护盾。", [eff("heal_or_block_if_full", 5, "self", amount_2=5)], "治疗 7 点生命；若生命已满，改为获得 7 护盾。", [eff("heal_or_block_if_full", 7, "self", amount_2=7)]),
	("KS_B04", "Structure Repair", "结构修复", 1, "Skill", ["Medical", "Repair"], "修复 Mon3tr 3 点完整性。", [eff("repair_mon3tr", 3, "self")], "修复 Mon3tr 5 点完整性。", [eff("repair_mon3tr", 5, "self")]),
	("KS_B05", "Mon3tr Command", "Mon3tr 指令", 1, "Skill", ["Command", "Mon3tr"], "Mon3tr 对目标造成 8 点伤害。", [eff("mon3tr_damage", 8, "enemy")], "Mon3tr 对目标造成 11 点伤害。", [eff("mon3tr_damage", 11, "enemy")]),
	("KS_B06", "Defensive Intercept", "防线拦截", 1, "Skill", ["Command", "Block", "Mon3tr"], "获得 6 护盾。Mon3tr 失去 1 完整性并造成 6 点伤害。", [eff("block", 6, "self"), eff("damage_mon3tr", 1, "self"), eff("mon3tr_damage", 6, "enemy")], "获得 8 护盾。Mon3tr 失去 1 完整性并造成 8 点伤害。", [eff("block", 8, "self"), eff("damage_mon3tr", 1, "self"), eff("mon3tr_damage", 8, "enemy")]),
	("KS_B07", "Clinical Scheduling", "临床调度", 1, "Skill", ["Draw", "Medical"], "抽 2 张牌；首张抽到的 Medical 或 Command 本回合费用 -1。", [eff("draw_discount_medical_command", 2, "self", amount_2=1)], "抽 3 张牌；首张抽到的 Medical 或 Command 本回合费用 -1。", [eff("draw_discount_medical_command", 3, "self", amount_2=1)]),
	("KS_B08", "Vital Injection", "维生注射", 0, "Skill", ["Medical", "Repair", "Heal"], "治疗 2 点生命，修复 Mon3tr 1 点完整性。", [eff("heal", 2, "self"), eff("repair_mon3tr", 1, "self")], "治疗 3 点生命，修复 Mon3tr 2 点完整性。", [eff("heal", 3, "self"), eff("repair_mon3tr", 2, "self")]),
	("KS_B09", "Integrity Calibration", "完整性校准", 1, "Skill", ["Repair", "Meltdown"], "修复 Mon3tr 2 点完整性；若因此达到完整性上限，抽 1。", [eff("repair_mon3tr_draw_if_reaches_max", 2, "self", amount_2=1)], "修复 Mon3tr 3 点完整性；若因此达到完整性上限，抽 1。", [eff("repair_mon3tr_draw_if_reaches_max", 3, "self", amount_2=1)]),
	("KS_B10", "Protocol Start", "协议启动", 1, "Power", ["Protocol", "Medical"], "能力。每回合第一次修复 Mon3tr 后，获得 2 护盾。", [eff("set_protocol_start", 2, "self")], "能力。每回合第一次修复 Mon3tr 后，获得 3 护盾并抽 1。", [eff("set_protocol_start", 3, "self", amount_2=1)]),
]


def parse_extra_cards() -> list[dict]:
	if not SPEC.exists():
		return []
	text = SPEC.read_text(encoding="utf-8")
	card_lines: list[dict] = []
	pattern = re.compile(r"^(KS_[CURLS]\d{2})\s+([^/]+?)\s*/\s*([^—]+?)\s+—\s+(.+)$")
	for raw in text.splitlines():
		line = raw.strip()
		match = pattern.match(line)
		if not match:
			continue
		code, en_name, cn_name, rest = match.groups()
		en_name = en_name.strip()
		cn_name = cn_name.strip()
		cost_match = re.search(r"(\d+)\s+cost", rest)
		cost = int(cost_match.group(1)) if cost_match else 1
		effect_text = rest.split("—", 1)[1].strip() if "—" in rest else rest
		upgrade = ""
		if "Upgrade:" in effect_text:
			effect_text, upgrade = effect_text.split("Upgrade:", 1)
			effect_text = effect_text.strip().rstrip(".")
			upgrade = upgrade.strip().rstrip(".")
		prefix = code.split("_", 1)[1][0]
		rarity = RARITY_BY_PREFIX.get(prefix, "Common")
		card_type = "Power" if "Power" in rest else "Attack" if effect_text.startswith("Deal ") or "Kal’tsit deals" in effect_text else "Skill"
		if rarity == "Status":
			card_type = "Curse" if "Burden" in en_name or "Interference" in en_name or "Fatigue" in en_name or "Echo" in en_name else "Status"
		card_id = resource_id(code, en_name)
		card_lines.append({
			"code": code,
			"id": card_id,
			"en": en_name,
			"cn": cn_name,
			"cost": cost,
			"type": card_type,
			"rarity": rarity if card_type != "Curse" else "Curse",
			"effect": effect_text,
			"upgrade": upgrade,
			"tags": tags_from_text(en_name, effect_text, card_type, rarity if card_type != "Curse" else "Curse"),
		})
	return card_lines


def effect_block(effect: dict, index: int) -> str:
	lines = [
		f'[sub_resource type="Resource" id="{index}"]',
		'script = ExtResource("2")',
		f'effect_type = "{esc(effect["effect_type"])}"',
		f'amount = {int(effect.get("amount", 0))}',
		f'amount_2 = {int(effect.get("amount_2", 0))}',
		f'target = "{esc(effect.get("target", "enemy"))}"',
	]
	if effect.get("status_id"):
		lines.append(f'status_id = "{esc(effect["status_id"])}"')
	if effect.get("tag"):
		lines.append(f'tag = "{esc(effect["tag"])}"')
	if effect.get("condition"):
		lines.append(f'condition = "{esc(effect["condition"])}"')
	return "\n".join(lines)


def write_card(card_id: str, name: str, cost: int, card_type: str, tags: list[str], desc: str, rarity: str, effects: list[dict], conditional: list[dict], upgraded_id: str = "", exhausts: bool = False) -> None:
	all_effects = effects + conditional
	load_steps = 3 + len(all_effects)
	blocks: list[str] = [
		f'[gd_resource type="Resource" script_class="CardData" load_steps={load_steps} format=3]',
		"",
		'[ext_resource type="Script" path="res://scripts/data/CardData.gd" id="1"]',
		'[ext_resource type="Script" path="res://scripts/data/EffectData.gd" id="2"]',
		"",
	]
	for index, effect in enumerate(all_effects, 1):
		blocks.append(effect_block(effect, index))
		blocks.append("")
	effect_refs = ", ".join(f'SubResource("{i}")' for i in range(1, len(effects) + 1))
	cond_refs = ", ".join(f'SubResource("{i}")' for i in range(len(effects) + 1, len(all_effects) + 1))
	blocks.extend([
		"[resource]",
		'script = ExtResource("1")',
		f'id = "{esc(card_id)}"',
		f'display_name = "{esc(name)}"',
		f'cost = {cost}',
		f'card_type = "{esc(card_type)}"',
		'tags = PackedStringArray(' + ",".join(f'"{esc(tag)}"' for tag in tags) + ')',
		f'description = "{esc(desc)}"',
		f'rarity = "{esc(rarity)}"',
		f'exhausts = {"true" if exhausts else "false"}',
		f'upgraded_id = "{esc(upgraded_id)}"',
		f'effects = [{effect_refs}]',
		f'conditional_effects = [{cond_refs}]',
	])
	(OUT / f"{card_id}.tres").write_text("\n".join(blocks) + "\n", encoding="utf-8")


def main() -> None:
	OUT.mkdir(parents=True, exist_ok=True)
	for code, en, cn, cost, card_type, tags, desc, effects, upgraded_desc, upgraded_effects in BASIC:
		card_id = resource_id(code, en)
		plus_id = f"{card_id}_plus"
		write_card(card_id, cn, cost, card_type, tags, desc, "Starter", effects, [], plus_id)
		write_card(plus_id, cn + "+", cost, card_type, tags, upgraded_desc, "Starter", upgraded_effects, [], "", False)
	for card in parse_extra_cards():
		base_effects, conditional_effects = effects_from_text(card["effect"])
		base_desc = card["effect"].replace("Mon3tr deals", "Mon3tr 造成").replace("Heal", "治疗").replace("Repair", "修复")
		plus_id = f'{card["id"]}_plus'
		exhausts = "Exhaust" in card["effect"] or card["rarity"] in ["Status", "Curse"]
		write_card(card["id"], card["cn"], card["cost"], card["type"], card["tags"], base_desc, card["rarity"], base_effects, conditional_effects, plus_id if card["upgrade"] else "", exhausts)
		if card["upgrade"]:
			upgraded_text = upgraded_effect_text(card["effect"], card["upgrade"])
			plus_effects, plus_conditional = effects_from_text(upgraded_text)
			plus_cost = 0 if "cost 0" in card["upgrade"] else card["cost"]
			plus_desc = ("升级：" + card["upgrade"]).replace("Mon3tr deals", "Mon3tr 造成").replace("Heal", "治疗").replace("Repair", "修复")
			write_card(plus_id, card["cn"] + "+", plus_cost, card["type"], card["tags"], plus_desc, card["rarity"], plus_effects, plus_conditional, "", exhausts)


if __name__ == "__main__":
	main()
