extends Control

const UI_MOTION = preload("res://scripts/core/ui_motion.gd")
const UI_THEME_KIT = preload("res://scripts/ui/ui_theme_kit.gd")

@onready var panel: PanelContainer = $Panel
@onready var header_panel: PanelContainer = $Panel/Margin/VBox/HeaderPanel
@onready var eyebrow_label: Label = $Panel/Margin/VBox/HeaderPanel/HeaderMargin/HeaderVBox/Eyebrow
@onready var title_label: Label = $Panel/Margin/VBox/HeaderPanel/HeaderMargin/HeaderVBox/Title
@onready var info_panel: PanelContainer = $Panel/Margin/VBox/InfoPanel
@onready var body_scroll: ScrollContainer = $Panel/Margin/VBox/InfoPanel/InfoMargin/BodyScroll
@onready var body_label: Label = $Panel/Margin/VBox/InfoPanel/InfoMargin/BodyScroll/Body
@onready var content_scroll: ScrollContainer = $Panel/Margin/VBox/ContentScroll
@onready var options_box: VBoxContainer = $Panel/Margin/VBox/ContentScroll/Options
@onready var footer_panel: PanelContainer = $Panel/Margin/VBox/FooterPanel
@onready var footer_hint_label: Label = $Panel/Margin/VBox/FooterPanel/FooterMargin/FooterRow/FooterHint
@onready var confirm_button: Button = $Panel/Margin/VBox/FooterPanel/FooterMargin/FooterRow/Confirm

var event_db: Dictionary = {}
var event_data: EventData
var runner: EventRunner = EventRunner.new()
var option_buttons: Array[Button] = []
var selected_option_index: int = -1

func _ready() -> void:
	_apply_ui_theme()
	if not LocalizationManager.language_changed.is_connected(_on_language_changed):
		LocalizationManager.language_changed.connect(_on_language_changed)
	event_db = Util.load_event_db()
	var node: MapNodeModel = RunManager.current_node()
	if node == null:
		SceneRouter.go_map()
		return
	event_data = event_db.get(String(node.metadata.get("event_id", "")), null)
	if event_data == null:
		eyebrow_label.text = LocalizationManager.text("event.eyebrow")
		title_label.text = LocalizationManager.text("event.empty_title")
		body_label.text = LocalizationManager.text("event.empty_body")
		footer_hint_label.text = LocalizationManager.text("event.empty_footer")
		confirm_button.text = LocalizationManager.text("event.continue")
		confirm_button.disabled = false
		return
	_apply_event_text()
	_rebuild_options()
	confirm_button.pressed.connect(_confirm_selection)
	call_deferred("_play_intro_animation")

func _on_language_changed(_language_code: String) -> void:
	if event_data != null:
		_apply_event_text()
	_rebuild_options()
	_refresh_footer_state()

func _apply_event_text() -> void:
	var resolved_title: String = LocalizationManager.event_title(event_data.id, event_data.title).strip_edges()
	var resolved_body: String = LocalizationManager.event_body(event_data.id, event_data.body).strip_edges()
	eyebrow_label.text = LocalizationManager.text("event.eyebrow")
	title_label.text = resolved_title if not resolved_title.is_empty() else LocalizationManager.text("event.empty_title")
	body_label.text = resolved_body if not resolved_body.is_empty() else LocalizationManager.text("event.empty_body")
	body_scroll.scroll_vertical = 0
	content_scroll.scroll_vertical = 0

func _rebuild_options() -> void:
	for child in options_box.get_children():
		child.queue_free()
	option_buttons.clear()
	if event_data == null:
		return
	selected_option_index = clamp(selected_option_index, -1, event_data.options.size() - 1)
	for index in range(event_data.options.size()):
		var option: Dictionary = event_data.options[index]
		var button: Button = Button.new()
		var option_text: String = _option_label(option)
		var preview_text: String = _option_preview(option)
		button.text = option_text if preview_text.is_empty() else "%s\n%s" % [option_text, preview_text]
		button.tooltip_text = "%s\n%s" % [LocalizationManager.event_result_for_event(event_data.id, String(_character_option_value(option, "result", ""))).strip_edges(), preview_text]
		button.custom_minimum_size = Vector2(0, 94)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UI_THEME_KIT.apply_stone_button(button, "paper", 22)
		button.add_theme_font_size_override("font_size", 20)
		UI_MOTION.wire_button_feedback(button, 1.02, 0.98, Color(1.0, 0.90, 0.68, 0.68), 5.0)
		button.pressed.connect(func(option_index: int = index) -> void:
			selected_option_index = option_index
			SfxManager.play_ui_click()
			_refresh_option_button_states()
			_refresh_footer_state()
		)
		options_box.add_child(button)
		option_buttons.append(button)
	_refresh_option_button_states()
	_refresh_footer_state()

func _refresh_option_button_states() -> void:
	for index in range(option_buttons.size()):
		var button: Button = option_buttons[index]
		if button == null:
			continue
		var selected: bool = index == selected_option_index
		UI_THEME_KIT.apply_stone_button(button, "stone" if selected else "paper", 22)
		button.modulate = Color(1, 1, 1, 1) if selected else Color(1, 1, 1, 0.96)

func _refresh_footer_state() -> void:
	if event_data == null:
		confirm_button.text = LocalizationManager.text("event.continue")
		confirm_button.disabled = false
		return
	if selected_option_index >= 0 and selected_option_index < event_data.options.size():
		var option: Dictionary = event_data.options[selected_option_index]
		footer_hint_label.text = LocalizationManager.text("event.selected_hint", [_option_label(option)])
		confirm_button.text = LocalizationManager.text("event.confirm")
		confirm_button.disabled = false
	else:
		footer_hint_label.text = LocalizationManager.text("event.choose_option")
		confirm_button.text = LocalizationManager.text("event.confirm")
		confirm_button.disabled = true

func _confirm_selection() -> void:
	if event_data == null:
		RunManager.complete_current_node()
		SceneRouter.go_map()
		return
	if selected_option_index < 0 or selected_option_index >= event_data.options.size():
		return
	var option: Dictionary = event_data.options[selected_option_index]
	RunManager.begin_save_batch()
	var summary_entries: Array[Dictionary] = runner.apply_event_option(option)
	var character_id: String = RunManager.character.id if RunManager.character != null else "amiya"
	var raw_reward_cards: Array = Array(_character_option_value(option, "reward_cards", []))
	var filtered_reward_cards: Array[String] = Util.normalize_character_card_choices(
		raw_reward_cards,
		character_id,
		raw_reward_cards.size(),
		RunManager.rng_seed + RunManager.current_floor * 97 + selected_option_index,
		RunManager.get_reward_bias_weights()
	)
	RunManager.set_pending_rewards({
		"type": "event_reward",
		"text": LocalizationManager.event_result_for_event(event_data.id, String(_character_option_value(option, "result", ""))),
		"card_choices": filtered_reward_cards,
		"summary_entries": summary_entries
	})
	RunManager.complete_current_node()
	RunManager.end_save_batch()
	SceneRouter.go_reward()

func _option_label(option: Dictionary) -> String:
	if LocalizationManager.current_language == LocalizationManager.LANG_EN:
		return String(option.get("label", LocalizationManager.text("event.continue")))
	var character_label: String = LocalizationManager.event_option_label(event_data.id if event_data != null else "", String(option.get("label", "")))
	if character_label != String(option.get("label", "")):
		return character_label
	var mapping := {
		"Spend 20 Gold to stabilize the ward": "花费 20 金币稳定病房",
		"Split resources evenly": "平均分配资源",
		"Reserve medicine for the frontline": "把药物留给前线",
		"Accept the drill and cut dead weight": "接受训练并精简卡组",
		"Push for offensive adaptation": "要求更激进的战术适配",
		"Stand down and move on": "保持沉默，继续前进",
		"Stand with Nearl": "支持临光",
		"Prioritize the operation": "优先任务目标",
		"Take the middle road": "选择折中路线",
		"Request route intelligence": "请求路线情报",
		"Take the calm line": "采取冷静方案",
		"Trade tempo for a rarer support": "用节奏换取更稀有的支援",
		"Trace the signal and force the clash": "追踪信号并强行交战",
		"Decode the pattern": "解析爆破模式",
		"Walk away": "转身离开"
	}
	return String(mapping.get(String(option.get("label", "")), String(option.get("label", LocalizationManager.text("event.continue")))))

func _option_preview(option: Dictionary) -> String:
	var parts: Array[String] = []
	var effects: Array = Array(_character_option_value(option, "effects", []))
	for effect in effects:
		var text_value: String = _effect_preview(effect)
		if not text_value.is_empty() and not parts.has(text_value):
			parts.append(text_value)
	var reward_cards: Array = Array(_character_option_value(option, "reward_cards", []))
	if not reward_cards.is_empty():
		parts.append("奖励卡牌 x%d" % reward_cards.size())
	if parts.is_empty():
		return ""
	if parts.size() > 4:
		parts = parts.slice(0, 4)
		parts.append("...")
	return "效果：" + " / ".join(parts)

func _effect_preview(effect: Dictionary) -> String:
	match String(effect.get("type", "")):
		"gain_gold", "add_gold":
			return "金币 +%d" % int(effect.get("amount", 0))
		"lose_gold":
			return "金币 -%d" % int(effect.get("amount", 0))
		"lose_hp":
			return "生命 -%d" % int(effect.get("amount", 0))
		"heal":
			return "治疗 %d" % int(effect.get("amount", 0))
		"heal_percent":
			return "治疗 %d%%" % int(effect.get("amount", 0))
		"add_card", "add_card_reward":
			return "加入卡牌：%s" % _card_name(String(_character_effect_value(effect, "card_id", "")))
		"remove_card", "remove_selected_card":
			return "移除卡牌"
		"upgrade_random_card", "upgrade_selected_card":
			return "升级卡牌"
		"add_module":
			return "获得模块：%s" % _module_name(String(_character_effect_value(effect, "module_id", "")))
		"add_charm":
			return "获得护符：%s" % _charm_name(String(_character_effect_value(effect, "charm_id", "")))
		"set_flag", "gain_story_flag", "apply_run_modifier":
			return _flag_preview(String(_character_effect_value(effect, "flag", _character_effect_value(effect, "modifier_id", ""))))
		"next_floor_enemy_hp":
			return "敌人生命 +%d" % int(effect.get("amount", 0))
	return ""

func _flag_preview(flag_name: String) -> String:
	match flag_name:
		"next_floor_fewer_events":
			return "下一层事件减少"
		"soft_start_next_battle":
			return "下场开局更稳"
		"doctor_ideal":
			return "后续偏治疗/支援"
		"doctor_efficiency":
			return "后续偏爆发/稀有"
		"doctor_burden":
			return "后续偏高风险"
		"accept_burden_1", "accept_burden_2", "accept_burden_3":
			return "隐藏路线进度"
		"floor_first_support_double":
			return "本层首张支援触发两次"
		"double_next_reward":
			return "下一份奖励翻倍"
		"next_battle_enemy_strength":
			return "下一场敌人强化"
		"preview_two_nodes":
			return "地图额外预览"
		"next_battle_start_will_3":
			return "下场开局意志 +3"
		"next_battle_start_energy_1":
			return "下场开局能量 +1"
		"channel_upgrade_credit":
			return "后续引导强化机会"
		"legendary_offer_next_reward":
			return "下一奖励稀有度提升"
		"double_elite_reward":
			return "本层精英奖励翻倍"
		"support_upgrade_credit":
			return "后续支援强化机会"
		"tune_resonance_pending":
			return "后续调律偏层数"
		"tune_cost_pending":
			return "后续调律偏减费"
		"avoided_fissure":
			return "避开污染风险"
		"energy_potion_2":
			return "获得能量补给"
		"rest_upgrade_credit":
			return "休整升级机会"
		"evacuation_kind":
			return "撤离路线：保护"
		"evacuation_efficient":
			return "撤离路线：效率"
		"evacuation_split":
			return "撤离路线：分队"
		"w_intents_clear":
			return "W 意图可见"
		"lost_hidden_progress":
			return "隐藏路线受损"
	if flag_name.begins_with("enemy_hp_bonus_"):
		return "后续敌人强化"
	return "后续变化"

func _card_name(card_id: String) -> String:
	var card: CardData = Util.load_card_db().get(card_id, null) as CardData
	return LocalizationManager.card_name(card) if card != null else card_id

func _module_name(module_id: String) -> String:
	var module_data: ModuleData = Util.load_module_db().get(module_id, null) as ModuleData
	return LocalizationManager.module_name(module_data) if module_data != null else module_id

func _charm_name(charm_id: String) -> String:
	var charm_data: CharmData = Util.load_charm_db().get(charm_id, null) as CharmData
	return charm_data.display_name if charm_data != null else charm_id

func _apply_ui_theme() -> void:
	UI_THEME_KIT.apply_paper_panel(panel)
	UI_THEME_KIT.apply_glass_panel(header_panel)
	UI_THEME_KIT.apply_page_section_panel(info_panel)
	UI_THEME_KIT.apply_page_section_panel(footer_panel)
	UI_THEME_KIT.apply_heading(eyebrow_label, 15, Color(0.95, 0.86, 0.58, 0.96), Color(0.07, 0.06, 0.05, 0.66))
	UI_THEME_KIT.apply_glass_heading(title_label, 34)
	UI_THEME_KIT.apply_glass_body(body_label, 20)
	UI_THEME_KIT.apply_glass_hint(footer_hint_label, 18)
	UI_THEME_KIT.apply_stone_button(confirm_button, "paper", 22)
	UI_MOTION.wire_button_feedback(confirm_button, 1.02, 0.98, Color(1.0, 0.90, 0.68, 0.68), 5.0)

func _play_intro_animation() -> void:
	UI_MOTION.reveal(panel, 0.04, Vector2(0, 24), 0.30, Vector2(0.99, 0.99))
	var delay: float = 0.12
	for child in options_box.get_children():
		var control: Control = child as Control
		if control == null:
			continue
		UI_MOTION.reveal(control, delay, Vector2(-18, 0), 0.24, Vector2(0.99, 0.99))
		delay += 0.05
	UI_MOTION.reveal(confirm_button, 0.16, Vector2(0, 14), 0.22, Vector2(0.99, 0.99))

func _character_option_value(option: Dictionary, key: String, default_value: Variant = null) -> Variant:
	var character_id: String = RunManager.character.id if RunManager.character != null else "amiya"
	var direct_key: String = "%s_%s" % [key, character_id]
	if option.has(direct_key):
		return option.get(direct_key, default_value)
	var mapping_key: String = "%s_by_character" % key
	if option.has(mapping_key):
		var mapping: Dictionary = option.get(mapping_key, {})
		if mapping.has(character_id):
			return mapping[character_id]
	return option.get(key, default_value)

func _character_effect_value(effect: Dictionary, key: String, default_value: Variant = null) -> Variant:
	var character_id: String = RunManager.character.id if RunManager.character != null else "amiya"
	var direct_key: String = "%s_%s" % [key, character_id]
	if effect.has(direct_key):
		return effect.get(direct_key, default_value)
	var mapping_key: String = "%s_by_character" % key
	if effect.has(mapping_key):
		var mapping: Dictionary = effect.get(mapping_key, {})
		if mapping.has(character_id):
			return mapping[character_id]
	return effect.get(key, default_value)
