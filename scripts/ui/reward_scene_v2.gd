extends Control

const CARD_DISPLAY_FACTORY = preload("res://scripts/ui/card_display_factory.gd")
const UI_MOTION = preload("res://scripts/core/ui_motion.gd")
const UI_THEME_KIT = preload("res://scripts/ui/ui_theme_kit.gd")

@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $Panel/Margin/VBox/Title
@onready var body_scroll: ScrollContainer = $Panel/Margin/VBox/BodyScroll
@onready var body_label: Label = $Panel/Margin/VBox/BodyScroll/Body
@onready var cards_box: HBoxContainer = $Panel/Margin/VBox/Cards
@onready var continue_button: Button = $Panel/Margin/VBox/Continue

var card_db: Dictionary = {}

func _ready() -> void:
	card_db = Util.load_card_db()
	_apply_ui_theme()
	LocalizationManager.language_changed.connect(_render)
	_render()
	continue_button.pressed.connect(_on_continue)
	call_deferred("_play_intro_animation")

func _render(_language_code: String = "") -> void:
	var reward: Dictionary = RunManager.pending_rewards
	var picks_allowed: int = int(reward.get("picks_allowed", 1))
	var picked_ids: Array = reward.get("picked_ids", [])
	var picks_used: int = picked_ids.size()
	var picks_remaining: int = max(0, picks_allowed - picks_used)
	title_label.text = LocalizationManager.text("reward.title").strip_edges()
	var body_text: String = String(reward.get("text", LocalizationManager.text("reward.body_default")))
	var module_id: String = String(reward.get("module_id", ""))
	if not module_id.is_empty():
		var module_db: Dictionary = Util.load_module_db()
		if module_db.has(module_id):
			var module_data: ModuleData = module_db[module_id] as ModuleData
			if module_data != null:
				body_text += "\n" + LocalizationManager.text("reward.module_bonus", [LocalizationManager.module_name(module_data)])
	if not reward.is_empty() and picks_allowed > 1:
		body_text += "\n" + LocalizationManager.text("reward.pick_remaining", [picks_remaining, picks_allowed])
	body_label.text = body_text.strip_edges()
	body_scroll.scroll_vertical = 0
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
			true,
			CARD_DISPLAY_FACTORY.has_upgrade_visual(card)
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
			RunManager.add_card(id, "battle_reward" if String(inner_reward.get("type", "")) == "battle_reward" else "event_reward")
			inner_picked_ids.append(id)
			inner_reward["picked_ids"] = inner_picked_ids
			RunManager.pending_rewards = inner_reward
			_render()
		)
		cards_box.add_child(button)
	var can_finish: bool = reward.is_empty() or picks_remaining <= 0
	continue_button.text = LocalizationManager.text("reward.continue") if can_finish else LocalizationManager.text("reward.skip")

func _on_continue() -> void:
	var reward: Dictionary = RunManager.pending_rewards
	var module_id: String = String(reward.get("module_id", ""))
	if not module_id.is_empty():
		RunManager.add_module(module_id)
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

func _apply_ui_theme() -> void:
	UI_THEME_KIT.apply_paper_panel(panel)
	UI_THEME_KIT.apply_heading(title_label, 34, Color(0.18, 0.13, 0.08, 1.0))
	UI_THEME_KIT.apply_body(body_label, 20, Color(0.18, 0.16, 0.14, 0.98))
	UI_THEME_KIT.apply_stone_button(continue_button, "paper", 24)
	UI_MOTION.wire_button_feedback(continue_button, 1.02, 0.98, Color(1.0, 0.88, 0.64, 0.72), 5.0)

func _play_intro_animation() -> void:
	UI_MOTION.reveal(panel, 0.04, Vector2(0, 24), 0.30, Vector2(0.99, 0.99))
	UI_MOTION.reveal(continue_button, 0.14, Vector2(0, 16), 0.24, Vector2(0.99, 0.99))
