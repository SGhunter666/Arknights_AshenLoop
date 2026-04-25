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
		button.text = _option_label(option)
		button.tooltip_text = String(option.get("result", "")).strip_edges()
		button.custom_minimum_size = Vector2(0, 72)
		UI_THEME_KIT.apply_stone_button(button, "paper", 22)
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
