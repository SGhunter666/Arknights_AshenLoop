extends Control

@onready var title_label: Label = $Panel/Margin/VBox/Title
@onready var body_label: Label = $Panel/Margin/VBox/Body
@onready var options_box: VBoxContainer = $Panel/Margin/VBox/Options

var event_db: Dictionary = {}
var event_data: EventData
var runner: EventRunner = EventRunner.new()

func _ready() -> void:
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
	for option in event_data.options:
		var button: Button = Button.new()
		button.text = _option_label(option)
		button.custom_minimum_size = Vector2(0, 64)
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

func _on_language_changed(_language_code: String) -> void:
	if event_data != null:
		_apply_event_text()

func _apply_event_text() -> void:
	title_label.text = LocalizationManager.event_title(event_data.id, event_data.title)
	body_label.text = LocalizationManager.event_body(event_data.id, event_data.body)

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
	return String(mapping.get(String(option.get("label", "")), LocalizationManager.text("event.continue")))
