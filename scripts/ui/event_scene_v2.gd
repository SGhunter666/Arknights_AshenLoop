extends Control

const UI_MOTION = preload("res://scripts/core/ui_motion.gd")
const UI_THEME_KIT = preload("res://scripts/ui/ui_theme_kit.gd")

@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $Panel/Margin/VBox/Title
@onready var body_scroll: ScrollContainer = $Panel/Margin/VBox/BodyScroll
@onready var body_label: Label = $Panel/Margin/VBox/BodyScroll/Body
@onready var options_box: VBoxContainer = $Panel/Margin/VBox/Options

var event_db: Dictionary = {}
var event_data: EventData
var runner: EventRunner = EventRunner.new()
var option_buttons: Array[Button] = []

func _ready() -> void:
	_apply_ui_theme()
	LocalizationManager.language_changed.connect(_on_language_changed)
	event_db = Util.load_event_db()
	var node: MapNodeModel = RunManager.current_node()
	if node == null:
		SceneRouter.go_map()
		return
	event_data = event_db.get(String(node.metadata.get("event_id", "")), null)
	if event_data == null:
		title_label.text = LocalizationManager.text("event.empty_title")
		body_label.text = LocalizationManager.text("event.empty_body")
		return
	_apply_event_text()
	option_buttons.clear()
	for option in event_data.options:
		var button: Button = Button.new()
		button.text = _option_label(option)
		button.custom_minimum_size = Vector2(0, 64)
		UI_THEME_KIT.apply_stone_button(button, "paper", 24)
		UI_MOTION.wire_button_feedback(button, 1.02, 0.98, Color(1.0, 0.90, 0.68, 0.68), 5.0)
		button.pressed.connect(func(data: Dictionary = option) -> void:
			runner.apply_event_option(data)
			RunManager.pending_rewards = {
				"type": "event_reward",
				"text": LocalizationManager.event_result(String(data.get("result", ""))),
				"card_choices": Array(data.get("reward_cards", []))
			}
			RunManager.complete_current_node()
			SceneRouter.go_reward()
		)
		options_box.add_child(button)
		option_buttons.append(button)
	call_deferred("_play_intro_animation")

func _on_language_changed(_language_code: String) -> void:
	if event_data != null:
		_apply_event_text()
		_refresh_option_labels()

func _apply_event_text() -> void:
	var resolved_title: String = LocalizationManager.event_title(event_data.id, event_data.title).strip_edges()
	var resolved_body: String = LocalizationManager.event_body(event_data.id, event_data.body).strip_edges()
	title_label.text = resolved_title if not resolved_title.is_empty() else LocalizationManager.text("event.empty_title")
	body_label.text = resolved_body if not resolved_body.is_empty() else LocalizationManager.text("event.empty_body")
	body_scroll.scroll_vertical = 0

func _refresh_option_labels() -> void:
	if event_data == null:
		return
	for index in range(min(option_buttons.size(), event_data.options.size())):
		var button: Button = option_buttons[index]
		if button == null:
			continue
		button.text = _option_label(event_data.options[index])

func _option_label(option: Dictionary) -> String:
	if LocalizationManager.current_language == LocalizationManager.LANG_EN:
		return String(option.get("label", LocalizationManager.text("event.continue")))
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
	UI_THEME_KIT.apply_heading(title_label, 34, Color(0.18, 0.13, 0.08, 1.0))
	UI_THEME_KIT.apply_body(body_label, 20, Color(0.18, 0.16, 0.14, 0.98))

func _play_intro_animation() -> void:
	UI_MOTION.reveal(panel, 0.04, Vector2(0, 24), 0.30, Vector2(0.99, 0.99))
	var delay: float = 0.12
	for child in options_box.get_children():
		var control: Control = child as Control
		if control == null:
			continue
		UI_MOTION.reveal(control, delay, Vector2(-18, 0), 0.24, Vector2(0.99, 0.99))
		delay += 0.05
