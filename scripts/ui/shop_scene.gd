extends Control

const REWARD_GENERATOR = preload("res://scripts/rewards/RewardGenerator.gd")
const TUNE_LIBRARY = preload("res://scripts/core/tune_library.gd")
const UI_MOTION = preload("res://scripts/core/ui_motion.gd")
const UI_THEME_KIT = preload("res://scripts/ui/ui_theme_kit.gd")

@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $Panel/Margin/VBox/Title
@onready var info_label: Label = $Panel/Margin/VBox/Info
@onready var vbox: VBoxContainer = $Panel/Margin/VBox
@onready var remove_button: Button = $Panel/Margin/VBox/RemoveCard
@onready var buy_module_button: Button = $Panel/Margin/VBox/BuyModule
@onready var continue_button: Button = $Panel/Margin/VBox/Continue

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var shop_refresh_count: int = 0
var reward_generator

func _ready() -> void:
	rng.seed = RunManager.rng_seed + RunManager.current_floor * 771 + RunManager.gold
	reward_generator = REWARD_GENERATOR.new(rng.seed + shop_refresh_count * 101)
	_apply_ui_theme()
	info_label.text = LocalizationManager.text("shop.info")
	remove_button.text = "Remove：移除第一张牌（75 金币）"
	buy_module_button.text = "Module：购买随机模块（90 金币）"
	_build_shop_buttons()
	call_deferred("_play_intro_animation")

func _build_shop_buttons() -> void:
	for child in vbox.get_children():
		if child.get_meta("dynamic_shop", false):
			child.queue_free()
	reward_generator = REWARD_GENERATOR.new(rng.seed + shop_refresh_count * 101)
	var reward_bias: Dictionary = RunManager.get_reward_bias_weights()
	for card_id in reward_generator.card_choices(Util.get_card_reward_pool(), 3, reward_bias):
		_add_shop_button("Card：%s（45 金币）" % _card_label(card_id), 45, func(id = card_id): RunManager.add_card(id, "shop"))
	for module_id in _pick_ids(Util.get_module_reward_pool(), 2):
		_add_shop_button("Module：%s（90 金币）" % module_id, 90, func(id = module_id): RunManager.add_module(id))
	var charm_pool: Array[String] = []
	for charm_id in Util.get_charm_reward_pool():
		if not RunManager.is_charm_owned(charm_id):
			charm_pool.append(charm_id)
	var charm_ids: Array[String] = _pick_ids(charm_pool if not charm_pool.is_empty() else Util.get_charm_reward_pool(), 1)
	if not charm_ids.is_empty():
		_add_shop_button("Charm：%s（80 金币）" % charm_ids[0], 80, func(id = charm_ids[0]): RunManager.add_charm(id))
	_add_shop_button("Upgrade：升级第一张可升级牌（60 金币）", 60, _upgrade_first_card)
	var tune_seed: int = rng.seed + shop_refresh_count * 499 + RunManager.deck.size() * 7 + RunManager.current_floor * 17
	for tune_id in RunManager.tune_offer(tune_seed, 3):
		_add_shop_button(
			"Tune：%s | %s（65 金币）" % [TUNE_LIBRARY.title(tune_id), TUNE_LIBRARY.short_text(tune_id)],
			65,
			func(id = tune_id): _buy_tune(id)
		)
	_add_shop_button("Rewire：每回合第一张 Arts +2（50 金币）", 50, func(): RunManager.set_flag("rewire_arts_bonus", true))
	_add_shop_button("Rewire：每战第一次 Support 抽 2（50 金币）", 50, func(): RunManager.set_flag("rewire_support_draw", true))
	_add_shop_button("Rewire：Overload 结算伤害 -1（50 金币）", 50, func(): RunManager.set_flag("rewire_overload_minus_one", true))
	_add_shop_button("Equip Charm：获得一个未拥有 Charm（80 金币）", 80, _equip_next_charm)
	_add_shop_button("Refresh：刷新商店（%d 金币）" % _refresh_price(), _refresh_price(), _refresh_shop)

func _add_shop_button(label: String, price: int, callback: Callable) -> void:
	var button: Button = Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(0, 42)
	button.set_meta("dynamic_shop", true)
	UI_THEME_KIT.apply_stone_button(button, "paper", 18)
	UI_MOTION.wire_button_feedback(button, 1.02, 0.98, Color(1.0, 0.88, 0.66, 0.70), 5.0)
	button.pressed.connect(func() -> void:
		if RunManager.gold < price:
			info_label.text = "金币不足。"
			return
		var previous_info: String = info_label.text
		RunManager.add_gold(-price)
		callback.call()
		button.disabled = true
		if info_label.text == previous_info:
			info_label.text = "已购买：%s" % label
	)
	vbox.add_child(button)
	vbox.move_child(button, max(0, vbox.get_child_count() - 2))

func _pick_ids(pool: Array[String], count: int) -> Array[String]:
	var available: Array[String] = pool.duplicate()
	var result: Array[String] = []
	while result.size() < count and not available.is_empty():
		var index: int = rng.randi_range(0, available.size() - 1)
		result.append(available[index])
		available.remove_at(index)
	return result

func _card_label(card_id: String) -> String:
	var card: CardData = Util.load_card_db().get(card_id, null) as CardData
	return LocalizationManager.card_name(card) if card != null else card_id

func _refresh_price() -> int:
	return [30, 50, 80][min(shop_refresh_count, 2)]

func _refresh_shop() -> void:
	shop_refresh_count += 1
	_build_shop_buttons()

func _upgrade_first_card() -> void:
	var card_db: Dictionary = Util.load_card_db()
	for index in range(RunManager.deck.size()):
		var card: CardData = card_db.get(RunManager.deck[index], null) as CardData
		if card != null and not card.upgraded_id.is_empty() and card_db.has(card.upgraded_id):
			RunManager.deck[index] = card.upgraded_id
			RunManager.deck_changed.emit()
			RunManager.run_updated.emit()
			RunManager.save_run_snapshot()
			info_label.text = "已升级：%s" % LocalizationManager.card_name(card)
			return
	info_label.text = "没有找到可升级的牌。"

func _buy_tune(tune_id: String) -> void:
	if not RunManager.add_tune(tune_id):
		info_label.text = "这个调律已经掌握过了。"
		return
	info_label.text = "已购入调律：%s\n%s" % [TUNE_LIBRARY.title(tune_id), TUNE_LIBRARY.description(tune_id)]

func _equip_next_charm() -> void:
	for charm_id in RunManager.unequipped_owned_charms():
		if RunManager.equip_charm(charm_id):
			info_label.text = "已装备 Charm：%s" % charm_id
			return
	for charm_id in Util.get_charm_reward_pool():
		if not RunManager.is_charm_owned(charm_id):
			RunManager.add_charm(charm_id, false)
			RunManager.equip_charm(charm_id)
			info_label.text = "已装备 Charm：%s" % charm_id
			return
	info_label.text = "所有 Charm 都已经拥有。"

func _on_remove_card_pressed() -> void:
	if RunManager.gold >= 75 and not RunManager.deck.is_empty():
		RunManager.add_gold(-75)
		RunManager.remove_card(RunManager.deck[0])
		info_label.text = LocalizationManager.text("shop.removed")

func _on_buy_module_pressed() -> void:
	if RunManager.gold >= 90:
		RunManager.add_gold(-90)
		var module_id: String = _pick_ids(Util.get_module_reward_pool(), 1)[0]
		RunManager.add_module(module_id)
		info_label.text = LocalizationManager.text("shop.bought")

func _on_continue_pressed() -> void:
	RunManager.complete_current_node()
	if RunManager.has_flag("run_complete"):
		SceneRouter.go_main_menu()
	else:
		SceneRouter.go_map()

func _apply_ui_theme() -> void:
	UI_THEME_KIT.apply_paper_panel(panel)
	UI_THEME_KIT.apply_heading(title_label, 30, Color(0.18, 0.13, 0.08, 1.0))
	UI_THEME_KIT.apply_body(info_label, 18, Color(0.18, 0.16, 0.14, 0.98))
	for button in [remove_button, buy_module_button, continue_button]:
		UI_THEME_KIT.apply_stone_button(button, "paper", 20 if button != continue_button else 24)
		UI_MOTION.wire_button_feedback(button, 1.02, 0.98, Color(1.0, 0.88, 0.66, 0.70), 5.0)

func _play_intro_animation() -> void:
	UI_MOTION.reveal(panel, 0.04, Vector2(0, 24), 0.30, Vector2(0.99, 0.99))
