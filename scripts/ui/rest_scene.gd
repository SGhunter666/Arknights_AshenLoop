extends Control

const TUNE_LIBRARY = preload("res://scripts/core/tune_library.gd")
const REST_MANAGER = preload("res://scripts/rest/RestManager.gd")
const UI_MOTION = preload("res://scripts/core/ui_motion.gd")
const UI_THEME_KIT = preload("res://scripts/ui/ui_theme_kit.gd")

@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $Panel/Margin/VBox/Title
@onready var info_label: Label = $Panel/Margin/VBox/Info
@onready var vbox: VBoxContainer = $Panel/Margin/VBox
@onready var continue_button: Button = $Panel/Margin/VBox/Continue

var service_used: bool = false
var rest_manager = REST_MANAGER.new()

func _ready() -> void:
	_apply_ui_theme()
	if RunManager.should_take_interfloor_rest():
		RunManager.heal_full()
		info_label.text = LocalizationManager.text("rest.interfloor_done")
	else:
		info_label.text = LocalizationManager.text("rest.choose_service")
		_build_rest_services()
		_append_tune_summary()
	call_deferred("_play_intro_animation")

func _build_rest_services() -> void:
	_add_service_button(LocalizationManager.text("rest.service_recover"), _recover)
	_add_service_button(LocalizationManager.text("rest.service_upgrade"), _upgrade_first_card)
	for tune_id in rest_manager.offered_tunes():
		_add_service_button(
			LocalizationManager.text("rest.service_tune", [TUNE_LIBRARY.title(tune_id), TUNE_LIBRARY.short_text(tune_id)]),
			func(id = tune_id) -> void:
				_apply_tune_choice(id)
		)
	_add_service_button(LocalizationManager.text("rest.service_rewire_arts"), func(): _rewire("rewire_arts_bonus", LocalizationManager.text("rest.done_rewire_arts")))
	_add_service_button(LocalizationManager.text("rest.service_rewire_support"), func(): _rewire("rewire_support_draw", LocalizationManager.text("rest.done_rewire_support")))
	_add_service_button(LocalizationManager.text("rest.service_rewire_overload"), func(): _rewire("rewire_overload_minus_one", LocalizationManager.text("rest.done_rewire_overload")))
	_add_service_button(LocalizationManager.text("rest.service_equip_charm"), _equip_next_charm)

func _add_service_button(label: String, callback: Callable) -> void:
	var button: Button = Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(0, 44)
	UI_THEME_KIT.apply_stone_button(button, "paper", 18)
	UI_MOTION.wire_button_feedback(button, 1.02, 0.98, Color(1.0, 0.88, 0.66, 0.70), 5.0)
	button.pressed.connect(func() -> void:
		if service_used:
			return
		callback.call()
		service_used = true
		_disable_service_buttons()
	)
	vbox.add_child(button)
	vbox.move_child(button, max(0, vbox.get_child_count() - 2))

func _disable_service_buttons() -> void:
	for child in vbox.get_children():
		var button := child as Button
		if button != null and button != continue_button:
			button.disabled = true

func _recover() -> void:
	RunManager.heal(int(ceil(float(RunManager.max_hp) * 0.3)))
	info_label.text = LocalizationManager.text("rest.done_recover")

func _upgrade_first_card() -> void:
	var card_db: Dictionary = Util.load_card_db()
	for index in range(RunManager.deck.size()):
		var card: CardData = card_db.get(RunManager.deck[index], null) as CardData
		if card != null and not card.upgraded_id.is_empty() and card_db.has(card.upgraded_id):
			RunManager.deck[index] = card.upgraded_id
			RunManager.deck_changed.emit()
			RunManager.run_updated.emit()
			RunManager.save_run_snapshot()
			info_label.text = LocalizationManager.text("rest.done_upgrade", [LocalizationManager.card_name(card)])
			return
	info_label.text = LocalizationManager.text("rest.done_upgrade_none")

func _apply_tune_choice(tune_id: String) -> void:
	if not rest_manager.apply_tune(tune_id):
		info_label.text = LocalizationManager.text("rest.done_tune_duplicate")
		return
	info_label.text = LocalizationManager.text("rest.done_tune", [TUNE_LIBRARY.title(tune_id), TUNE_LIBRARY.description(tune_id)])
	_append_tune_summary()

func _rewire(flag_id: String, message: String) -> void:
	RunManager.set_flag(flag_id, true)
	info_label.text = message

func _equip_next_charm() -> void:
	for charm_id in RunManager.unequipped_owned_charms():
		if RunManager.equip_charm(charm_id):
			info_label.text = LocalizationManager.text("rest.done_equip_charm", [LocalizationManager.charm_name_by_id(charm_id)])
			return
	for charm_id in Util.get_charm_reward_pool():
		if not RunManager.is_charm_owned(charm_id):
			RunManager.add_charm(charm_id, false)
			RunManager.equip_charm(charm_id)
			info_label.text = LocalizationManager.text("rest.done_equip_charm", [LocalizationManager.charm_name_by_id(charm_id)])
			return
	info_label.text = LocalizationManager.text("rest.done_equip_charm_full")

func _append_tune_summary() -> void:
	var lines: Array[String] = RunManager.tune_summary_lines()
	if lines.is_empty():
		return
	info_label.text += LocalizationManager.text("rest.current_tunes", ["\n".join(lines)])

func _on_continue_pressed() -> void:
	if RunManager.should_take_interfloor_rest():
		RunManager.consume_interfloor_rest()
	RunManager.complete_current_node()
	if RunManager.has_flag("run_complete"):
		SceneRouter.go_main_menu()
	else:
		SceneRouter.go_map()

func _apply_ui_theme() -> void:
	UI_THEME_KIT.apply_paper_panel(panel)
	UI_THEME_KIT.apply_heading(title_label, 30, Color(0.18, 0.13, 0.08, 1.0))
	UI_THEME_KIT.apply_body(info_label, 18, Color(0.18, 0.16, 0.14, 0.98))
	UI_THEME_KIT.apply_stone_button(continue_button, "paper", 24)
	UI_MOTION.wire_button_feedback(continue_button, 1.02, 0.98, Color(1.0, 0.88, 0.66, 0.70), 5.0)

func _play_intro_animation() -> void:
	UI_MOTION.reveal(panel, 0.04, Vector2(0, 24), 0.30, Vector2(0.99, 0.99))
