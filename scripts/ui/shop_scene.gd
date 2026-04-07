extends Control

@onready var info_label: Label = $Panel/Margin/VBox/Info
@onready var vbox: VBoxContainer = $Panel/Margin/VBox
@onready var remove_button: Button = $Panel/Margin/VBox/RemoveCard
@onready var buy_module_button: Button = $Panel/Margin/VBox/BuyModule
@onready var continue_button: Button = $Panel/Margin/VBox/Continue

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var shop_refresh_count: int = 0

func _ready() -> void:
	rng.seed = RunManager.rng_seed + RunManager.current_floor * 771 + RunManager.gold
	info_label.text = LocalizationManager.text("shop.info")
	remove_button.text = "Remove：移除第一张牌（75 金币）"
	buy_module_button.text = "Module：购买随机模块（90 金币）"
	_build_shop_buttons()

func _build_shop_buttons() -> void:
	for child in vbox.get_children():
		if child.get_meta("dynamic_shop", false):
			child.queue_free()
	for card_id in _pick_ids(Util.get_card_reward_pool(), 3):
		_add_shop_button("Card：%s（45 金币）" % _card_label(card_id), 45, func(id = card_id): RunManager.add_card(id))
	for module_id in _pick_ids(Util.get_module_reward_pool(), 2):
		_add_shop_button("Module：%s（90 金币）" % module_id, 90, func(id = module_id): RunManager.add_module(id))
	var charm_ids: Array[String] = _pick_ids(Util.get_charm_reward_pool(), 1)
	if not charm_ids.is_empty():
		_add_shop_button("Charm：%s（80 金币）" % charm_ids[0], 80, func(id = charm_ids[0]): RunManager.add_charm(id))
	_add_shop_button("Upgrade：升级第一张可升级牌（60 金币）", 60, _upgrade_first_card)
	_add_shop_button("Tune：本局共振施加 +1（65 金币）", 65, func(): RunManager.set_flag("tune_resonance_apply", true))
	_add_shop_button("Rewire：每回合第一张 Arts +2（50 金币）", 50, func(): RunManager.set_flag("rewire_arts_bonus", true))
	_add_shop_button("Refresh：刷新商店（%d 金币）" % _refresh_price(), _refresh_price(), _refresh_shop)

func _add_shop_button(label: String, price: int, callback: Callable) -> void:
	var button: Button = Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(0, 42)
	button.set_meta("dynamic_shop", true)
	button.pressed.connect(func() -> void:
		if RunManager.gold < price:
			info_label.text = "金币不足。"
			return
		RunManager.add_gold(-price)
		callback.call()
		button.disabled = true
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
			return

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
