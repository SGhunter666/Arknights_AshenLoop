extends Control

const CARD_GALLERY_OVERLAY = preload("res://scripts/ui/card_gallery_overlay.gd")
const COMPENDIUM_OVERLAY = preload("res://scripts/ui/compendium_overlay.gd")
const TUNE_SUMMARY_PRESENTER = preload("res://scripts/ui/tune_summary_presenter.gd")

@onready var title_label: Label = $Title
@onready var detail_label: Label = $Margin/Root/DetailPanel/DetailMargin/DetailLabel
@onready var back_button: Button = $BackButton
@onready var cards_button: Button = $Margin/Root/TopRow/CardsEntry
@onready var modules_button: Button = $Margin/Root/TopRow/ModulesEntry
@onready var lab_button: Button = $Margin/Root/TopRow/LabEntry
@onready var monster_button: Button = $Margin/Root/TopRow/MonsterEntry
@onready var stats_button: Button = $Margin/Root/BottomRow/StatsEntry
@onready var glossary_button: Button = $Margin/Root/BottomRow/GlossaryEntry
@onready var history_button: Button = $Margin/Root/BottomRow/HistoryEntry

var card_db: Dictionary = {}
var module_db: Dictionary = {}
var enemy_db: Dictionary = {}

func _ready() -> void:
	card_db = Util.load_card_db()
	module_db = Util.load_module_db()
	enemy_db = Util.load_enemy_db()
	_apply_text()
	LocalizationManager.language_changed.connect(_apply_text)
	_select_entry("cards")

func _apply_text(_language_code: String = "") -> void:
	title_label.text = LocalizationManager.text("codex.title")
	back_button.text = LocalizationManager.text("codex.back")
	cards_button.text = "%s\n\n%s" % [
		LocalizationManager.text("codex.cards"),
		LocalizationManager.text("codex.cards_body")
	]
	modules_button.text = "%s\n\n%s" % [
		LocalizationManager.text("codex.modules"),
		LocalizationManager.text("codex.modules_body")
	]
	lab_button.text = "%s\n\n%s" % [
		LocalizationManager.text("codex.lab"),
		LocalizationManager.text("codex.lab_body")
	]
	monster_button.text = "%s\n\n%s" % [
		LocalizationManager.text("codex.monsters"),
		LocalizationManager.text("codex.monsters_body")
	]
	stats_button.text = "%s\n\n%s" % [
		LocalizationManager.text("codex.stats"),
		LocalizationManager.text("codex.stats_body")
	]
	glossary_button.text = "%s\n\n%s" % [
		LocalizationManager.text("codex.glossary"),
		LocalizationManager.text("codex.glossary_body")
	]
	history_button.text = "%s\n\n%s" % [
		LocalizationManager.text("codex.history"),
		LocalizationManager.text("codex.history_body")
	]

func _select_entry(entry_id: String) -> void:
	detail_label.text = LocalizationManager.text("codex.detail_%s" % entry_id)

func _on_back_pressed() -> void:
	SceneRouter.go_main_menu()

func _on_cards_pressed() -> void:
	_select_entry("cards")
	_open_card_archive()

func _on_modules_pressed() -> void:
	_select_entry("modules")
	_open_module_archive()

func _on_lab_pressed() -> void:
	_select_entry("lab")
	_open_lab_archive()

func _on_monsters_pressed() -> void:
	_select_entry("monsters")
	_open_enemy_archive()

func _on_stats_pressed() -> void:
	_select_entry("stats")
	_open_stats_archive()

func _on_history_pressed() -> void:
	_select_entry("history")
	_open_history_archive()

func _on_glossary_pressed() -> void:
	_select_entry("glossary")
	_open_glossary_archive()

func _open_card_archive() -> void:
	var cards: Array[CardData] = []
	var ids: Array[String] = []
	for raw_id in card_db.keys():
		ids.append(String(raw_id))
	ids.sort()
	for id in ids:
		var card: CardData = card_db[id] as CardData
		if card != null:
			cards.append(card)
	var overlay: CardGalleryOverlay = CARD_GALLERY_OVERLAY.new()
	overlay.setup(LocalizationManager.text("codex.cards"), cards)
	add_child(overlay)

func _open_module_archive() -> void:
	var entries: Array[Dictionary] = [
		{
			"title": LocalizationManager.text("codex.modules_title"),
			"body": LocalizationManager.text("codex.module_count", [module_db.size()]),
			"accent": Color(0.72, 0.92, 1.0, 0.76),
			"display_mode": "grid"
		}
	]
	var ids: Array[String] = []
	for raw_id in module_db.keys():
		ids.append(String(raw_id))
	ids.sort()
	for id in ids:
		var module_data: ModuleData = module_db[id] as ModuleData
		if module_data == null:
			continue
		entries.append({
			"title": LocalizationManager.module_name(module_data),
			"subtitle": LocalizationManager.text("codex.module_rarity", [LocalizationManager.rarity_name(module_data.rarity)]),
			"body": LocalizationManager.module_description(module_data),
			"accent": _module_accent(module_data.rarity),
			"display_mode": "grid"
		})
	_open_compendium(LocalizationManager.text("codex.modules_title"), entries)

func _open_enemy_archive() -> void:
	var entries: Array[Dictionary] = []
	var ids: Array[String] = []
	for raw_id in enemy_db.keys():
		ids.append(String(raw_id))
	ids.sort()
	for id in ids:
		var enemy_data: EnemyData = enemy_db[id] as EnemyData
		if enemy_data == null:
			continue
		var move_labels: Array[String] = []
		for move_variant in enemy_data.moves:
			if typeof(move_variant) != TYPE_DICTIONARY:
				continue
			var move: Dictionary = move_variant
			move_labels.append(LocalizationManager.intent_label(String(move.get("label", "Unknown"))))
		var tags: Array[String] = []
		for raw_tag in enemy_data.tags:
			tags.append(LocalizationManager.enemy_tag_name(String(raw_tag)))
		var subtitle: String = "%s   |   %s" % [
			LocalizationManager.text("codex.enemy_hp", [enemy_data.max_hp]),
			LocalizationManager.text("codex.enemy_gold", [enemy_data.gold_reward])
		]
		var body_lines: Array[String] = []
		if not tags.is_empty():
			body_lines.append(LocalizationManager.text("codex.enemy_tags", [", ".join(tags)]))
		body_lines.append(LocalizationManager.text("codex.enemy_ai", [LocalizationManager.ai_profile_name(enemy_data.ai_profile)]))
		if not move_labels.is_empty():
			body_lines.append(LocalizationManager.text("codex.enemy_moves", [", ".join(move_labels)]))
		entries.append({
			"title": LocalizationManager.enemy_name(enemy_data.id, enemy_data.display_name),
			"subtitle": subtitle,
			"body": "\n".join(body_lines),
			"accent": _enemy_accent(enemy_data),
			"image_path": _enemy_archive_image_path(enemy_data.id),
			"display_mode": "grid"
		})
	_open_compendium(LocalizationManager.text("codex.monsters_title"), entries)


func _enemy_archive_image_path(enemy_id: String) -> String:
	var direct_path: String = "res://assets/enemy_portraits/%s.png" % enemy_id
	if FileAccess.file_exists(ProjectSettings.globalize_path(direct_path)):
		return direct_path
	match enemy_id:
		"reunion_scout":
			return "res://assets/enemy_portraits/reunion_scout.png"
		"reunion_caster":
			return "res://assets/enemy_portraits/reunion_caster.png"
		"riot_shieldbearer":
			return "res://assets/enemy_portraits/riot_shieldbearer.png"
		"crossbow_sniper":
			return "res://assets/enemy_portraits/crossbow_sniper.png"
		"field_captain":
			return "res://assets/enemy_portraits/field_captain.png"
		"originium_channeler":
			return "res://assets/enemy_portraits/originium_channeler.png"
		"scout_chief":
			return "res://assets/enemy_portraits/scout_chief.png"
		"lockdown_core":
			return "res://assets/enemy_portraits/lockdown_core.png"
		"w_boss":
			return "res://assets/enemy_portraits/w_boss.png"
		"ash_echo":
			return "res://assets/enemy_portraits/ash_echo.png"
	return ""

func _open_lab_archive() -> void:
	var profile: Dictionary = SaveManager.load_profile()
	var history: Array = profile.get("run_history", []) if typeof(profile.get("run_history", [])) == TYPE_ARRAY else []
	var entries: Array[Dictionary] = [
		{
			"title": LocalizationManager.text("codex.lab_entry_supply_title"),
			"body": LocalizationManager.text("codex.lab_entry_supply_body"),
			"accent": Color(0.72, 0.92, 1.0, 0.72),
			"display_mode": "grid"
		},
		{
			"title": LocalizationManager.text("codex.lab_entry_alchemy_title"),
			"body": LocalizationManager.text("codex.lab_entry_alchemy_body"),
			"accent": Color(0.86, 0.78, 1.0, 0.72),
			"display_mode": "grid"
		},
		{
			"title": LocalizationManager.text("codex.lab_entry_progress_title"),
			"body": LocalizationManager.text("codex.lab_entry_progress_body"),
			"accent": Color(0.98, 0.88, 0.62, 0.72),
			"display_mode": "grid"
		},
		{
			"title": LocalizationManager.text("codex.lab_entry_archive_title"),
			"body": LocalizationManager.text("codex.lab_entry_archive_body", [
				card_db.size(),
				module_db.size(),
				enemy_db.size(),
				history.size()
			]),
			"accent": Color(0.82, 0.92, 0.74, 0.72),
			"display_mode": "grid"
		}
	]
	_open_compendium(LocalizationManager.text("codex.lab_title"), entries)

func _open_stats_archive() -> void:
	var profile: Dictionary = SaveManager.load_profile()
	var stats: Dictionary = profile.get("stats", {}) if typeof(profile.get("stats", {})) == TYPE_DICTIONARY else {}
	var runs_started: int = int(stats.get("runs_started", 0))
	var runs_won: int = int(stats.get("runs_won", 0))
	var win_rate: int = int(round((float(runs_won) / float(runs_started)) * 100.0)) if runs_started > 0 else 0
	var entries: Array[Dictionary] = [
		{
			"title": LocalizationManager.text("single.amiya_header"),
			"subtitle": LocalizationManager.text("single.amiya_stats"),
			"body": "\n".join([
				LocalizationManager.text("codex.stats_runs", [runs_started]),
				LocalizationManager.text("codex.stats_wins", [runs_won]),
				LocalizationManager.text("codex.stats_losses", [int(stats.get("runs_lost", 0))]),
				LocalizationManager.text("codex.stats_best_floor", [int(stats.get("best_floor", 0))]),
				LocalizationManager.text("codex.stats_total_gold", [int(stats.get("total_gold_collected", 0))]),
				LocalizationManager.text("codex.stats_winrate", [win_rate])
			]),
			"accent": Color(0.72, 0.90, 1.0, 0.82)
		}
	]
	var active_run_text: String
	if RunManager.has_saved_run():
		var save_data: Dictionary = RunManager.saved_run_summary()
		var active_lines: Array[String] = [
			LocalizationManager.text("codex.stats_active_run", [
			int(save_data.get("current_floor", 1)),
			int(save_data.get("hp", 0)),
			int(save_data.get("max_hp", 0)),
			int(save_data.get("gold", 0))
			]),
			LocalizationManager.text("codex.stats_deck_modules", [
				_save_array_size(save_data.get("deck", [])),
				_save_array_size(save_data.get("modules", []))
			])
		]
		active_run_text = "\n".join(active_lines)
	else:
		active_run_text = LocalizationManager.text("codex.stats_no_active_run")
	entries.append({
		"title": LocalizationManager.text("single.resume"),
		"body": active_run_text,
		"accent": Color(0.95, 0.82, 0.62, 0.72)
	})
	entries.append(TUNE_SUMMARY_PRESENTER.current_summary_entry())
	_open_compendium(LocalizationManager.text("codex.stats_title"), entries)

func _open_history_archive() -> void:
	var profile: Dictionary = SaveManager.load_profile()
	var history: Array = profile.get("run_history", []) if typeof(profile.get("run_history", [])) == TYPE_ARRAY else []
	var entries: Array[Dictionary] = []
	for history_variant in history:
		if typeof(history_variant) != TYPE_DICTIONARY:
			continue
		var item: Dictionary = history_variant
		var result_key: String = "codex.history_victory" if String(item.get("result", "defeat")) == "victory" else "codex.history_defeat"
		var result_text: String = LocalizationManager.text(result_key)
		entries.append({
			"title": LocalizationManager.text("codex.history_entry", [
				result_text,
				int(item.get("floor", 0)),
				int(item.get("gold", 0)),
				int(item.get("deck_size", 0)),
				int(item.get("modules", 0))
			]),
			"subtitle": _format_history_timestamp(int(item.get("timestamp", 0))),
			"body": LocalizationManager.text("codex.history_record_body", [
				LocalizationManager.text("single.amiya_header"),
				result_text,
				int(item.get("floor", 0)),
				int(item.get("gold", 0)),
				int(item.get("deck_size", 0)),
				int(item.get("modules", 0))
			]),
			"accent": Color(0.92, 0.84, 0.66, 0.72) if String(item.get("result", "defeat")) == "victory" else Color(0.92, 0.62, 0.62, 0.72)
		})
	_open_compendium(LocalizationManager.text("codex.history_title"), entries)

func _open_glossary_archive() -> void:
	var entries: Array[Dictionary] = [
		{
			"title": LocalizationManager.text("codex.term_will_title"),
			"body": LocalizationManager.text("codex.term_will_body"),
			"accent": Color(0.72, 0.90, 1.0, 0.82)
		},
		{
			"title": LocalizationManager.text("codex.term_arts_title"),
			"body": LocalizationManager.text("codex.term_arts_body"),
			"accent": Color(0.82, 0.86, 1.0, 0.80)
		},
		{
			"title": LocalizationManager.text("codex.term_resonance_title"),
			"body": LocalizationManager.text("codex.term_resonance_body"),
			"accent": Color(0.72, 0.96, 1.0, 0.80)
		},
		{
			"title": LocalizationManager.text("codex.term_echo_title"),
			"body": LocalizationManager.text("codex.term_echo_body"),
			"accent": Color(0.76, 0.86, 1.0, 0.80)
		},
		{
			"title": LocalizationManager.text("codex.term_support_title"),
			"body": LocalizationManager.text("codex.term_support_body"),
			"accent": Color(0.74, 0.94, 0.98, 0.80)
		},
		{
			"title": LocalizationManager.text("codex.term_energy_title"),
			"body": LocalizationManager.text("codex.term_energy_body"),
			"accent": Color(0.98, 0.88, 0.64, 0.80)
		},
		{
			"title": LocalizationManager.text("codex.term_block_title"),
			"body": LocalizationManager.text("codex.term_block_body"),
			"accent": Color(0.80, 0.92, 1.0, 0.80)
		},
		{
			"title": LocalizationManager.text("codex.term_weak_title"),
			"body": LocalizationManager.text("codex.term_weak_body"),
			"accent": Color(0.92, 0.78, 0.62, 0.80)
		},
		{
			"title": LocalizationManager.text("codex.term_strength_title"),
			"body": LocalizationManager.text("codex.term_strength_body"),
			"accent": Color(1.0, 0.72, 0.52, 0.80)
		},
		{
			"title": LocalizationManager.text("codex.term_slow_title"),
			"body": LocalizationManager.text("codex.term_slow_body"),
			"accent": Color(0.76, 0.92, 1.0, 0.80)
		},
		{
			"title": LocalizationManager.text("codex.term_vulnerable_title"),
			"body": LocalizationManager.text("codex.term_vulnerable_body"),
			"accent": Color(0.98, 0.74, 0.62, 0.80)
		},
		{
			"title": LocalizationManager.text("codex.term_curse_title"),
			"body": LocalizationManager.text("codex.term_curse_body"),
			"accent": Color(0.90, 0.72, 0.98, 0.80)
		},
		{
			"title": LocalizationManager.text("codex.term_rescue_title"),
			"body": LocalizationManager.text("codex.term_rescue_body"),
			"accent": Color(0.82, 0.96, 0.78, 0.80)
		},
		{
			"title": LocalizationManager.text("codex.term_overload_title"),
			"body": LocalizationManager.text("codex.term_overload_body"),
			"accent": Color(0.98, 0.74, 0.74, 0.80)
		},
		{
			"title": LocalizationManager.text("codex.term_strain_title"),
			"body": LocalizationManager.text("codex.term_strain_body"),
			"accent": Color(0.98, 0.70, 0.70, 0.82)
		},
		{
			"title": LocalizationManager.text("codex.term_exhaust_title"),
			"body": LocalizationManager.text("codex.term_exhaust_body"),
			"accent": Color(0.90, 0.86, 0.70, 0.80)
		},
		{
			"title": LocalizationManager.text("codex.term_ethereal_title"),
			"body": LocalizationManager.text("codex.term_ethereal_body"),
			"accent": Color(0.84, 0.80, 0.98, 0.80)
		}
	]
	_open_compendium(LocalizationManager.text("codex.glossary_title"), entries)

func _open_compendium(title_text: String, entries: Array[Dictionary]) -> void:
	var overlay: CompendiumOverlay = COMPENDIUM_OVERLAY.new()
	overlay.setup(title_text, entries)
	add_child(overlay)

func _module_accent(rarity: String) -> Color:
	match rarity:
		"Rare":
			return Color(0.96, 0.82, 0.58, 0.82)
		"Elite":
			return Color(0.88, 0.78, 1.0, 0.82)
		_:
			return Color(0.72, 0.92, 1.0, 0.82)

func _enemy_accent(enemy_data: EnemyData) -> Color:
	if "Boss" in enemy_data.tags:
		return Color(0.98, 0.72, 0.62, 0.82)
	if "Elite" in enemy_data.tags:
		return Color(0.92, 0.82, 0.58, 0.82)
	return Color(0.72, 0.92, 1.0, 0.82)

func _format_history_timestamp(unix_time: int) -> String:
	if unix_time <= 0:
		return ""
	return Time.get_datetime_string_from_unix_time(unix_time, true)

func _save_array_size(value: Variant) -> int:
	if typeof(value) != TYPE_ARRAY:
		return 0
	var array_value: Array = value
	return array_value.size()
