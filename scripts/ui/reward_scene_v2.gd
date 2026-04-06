extends Control

const CARD_DISPLAY_FACTORY = preload("res://scripts/ui/card_display_factory.gd")

@onready var title_label: Label = $Panel/Margin/VBox/Title
@onready var body_label: Label = $Panel/Margin/VBox/Body
@onready var cards_box: HBoxContainer = $Panel/Margin/VBox/Cards
@onready var continue_button: Button = $Panel/Margin/VBox/Continue

var card_db: Dictionary = {}

func _ready() -> void:
	card_db = Util.load_card_db()
	LocalizationManager.language_changed.connect(_render)
	_render()
	continue_button.pressed.connect(_on_continue)

func _render(_language_code: String = "") -> void:
	var reward: Dictionary = RunManager.pending_rewards
	var picks_allowed: int = int(reward.get("picks_allowed", 1))
	var picked_ids: Array = reward.get("picked_ids", [])
	var picks_used: int = picked_ids.size()
	var picks_remaining: int = max(0, picks_allowed - picks_used)
	title_label.text = LocalizationManager.text("reward.title")
	var body_text: String = String(reward.get("text", LocalizationManager.text("reward.body_default")))
	if not reward.is_empty() and picks_allowed > 1:
		body_text += "\n" + LocalizationManager.text("reward.pick_remaining", [picks_remaining, picks_allowed])
	body_label.text = body_text
	for child in cards_box.get_children():
		child.queue_free()
	for card_id in reward.get("card_choices", []):
		if not card_db.has(card_id):
			continue
		var card: CardData = card_db[card_id]
		var button: Button = CARD_DISPLAY_FACTORY.create_card_button(
			card,
			LocalizationManager.card_name(card),
			LocalizationManager.card_description(card),
			card.cost,
			Util.load_card_art(card.id),
			Vector2(220, 318),
			true
		)
		var already_picked: bool = picked_ids.has(card_id)
		button.disabled = already_picked or picks_remaining <= 0
		button.modulate = Color(0.72, 0.76, 0.84, 0.82) if already_picked else Color(1, 1, 1, 1)
		button.pressed.connect(func(id: String = card_id) -> void:
			var inner_reward: Dictionary = RunManager.pending_rewards
			var inner_picked_ids: Array = inner_reward.get("picked_ids", [])
			var inner_picks_allowed: int = int(inner_reward.get("picks_allowed", 1))
			if inner_picked_ids.has(id) or inner_picked_ids.size() >= inner_picks_allowed:
				return
			RunManager.add_card(id)
			inner_picked_ids.append(id)
			inner_reward["picked_ids"] = inner_picked_ids
			RunManager.pending_rewards = inner_reward
			_render()
		)
		cards_box.add_child(button)
	var can_finish: bool = reward.is_empty() or picks_remaining <= 0
	continue_button.text = LocalizationManager.text("reward.continue") if can_finish else LocalizationManager.text("reward.skip")

func _on_continue() -> void:
	RunManager.pending_rewards = {}
	if RunManager.has_flag("run_complete"):
		RunManager.last_run_summary = {
			"floor": RunManager.current_floor,
			"gold": RunManager.gold,
			"deck_size": RunManager.deck.size(),
			"modules": RunManager.modules.size()
		}
		RunManager.record_run_result(true)
		RunManager.clear_saved_run()
		SceneRouter.go_victory()
	elif RunManager.should_take_interfloor_rest():
		SceneRouter.go_rest()
	else:
		SceneRouter.go_map()
