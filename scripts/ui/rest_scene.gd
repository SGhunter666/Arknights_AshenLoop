extends Control

@onready var info_label: Label = $Panel/Margin/VBox/Info
@onready var vbox: VBoxContainer = $Panel/Margin/VBox
@onready var continue_button: Button = $Panel/Margin/VBox/Continue

var service_used: bool = false

func _ready() -> void:
	if RunManager.should_take_interfloor_rest():
		RunManager.heal_full()
		info_label.text = "层间休整完成：生命值已完全恢复。"
	else:
		info_label.text = "选择一项休整服务，然后继续行动。"
		_build_rest_services()

func _build_rest_services() -> void:
	_add_service_button("Recover：回复 30% 最大生命", _recover)
	_add_service_button("Upgrade：升级第一张可升级牌", _upgrade_first_card)
	_add_service_button("Tune：本局共振施加 +1", _tune_resonance)
	_add_service_button("Rewire：每回合第一张 Arts +2 伤害", func(): _rewire("rewire_arts_bonus", "已选择临时战术：每回合第一张 Arts +2 伤害。"))
	_add_service_button("Rewire：每战第一次 Support 抽 2", func(): _rewire("rewire_support_draw", "已选择临时战术：每战第一次 Support 抽 2。"))
	_add_service_button("Rewire：Overload 结算伤害 -1", func(): _rewire("rewire_overload_minus_one", "已选择临时战术：Overload 结算伤害 -1。"))
	_add_service_button("Equip Charm：获得一个未拥有 Charm", _equip_next_charm)

func _add_service_button(label: String, callback: Callable) -> void:
	var button: Button = Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(0, 44)
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
	info_label.text = "已回复 30% 最大生命。"

func _upgrade_first_card() -> void:
	var card_db: Dictionary = Util.load_card_db()
	for index in range(RunManager.deck.size()):
		var card: CardData = card_db.get(RunManager.deck[index], null) as CardData
		if card != null and not card.upgraded_id.is_empty() and card_db.has(card.upgraded_id):
			RunManager.deck[index] = card.upgraded_id
			RunManager.deck_changed.emit()
			RunManager.run_updated.emit()
			RunManager.save_run_snapshot()
			info_label.text = "已升级：%s。" % LocalizationManager.card_name(card)
			return
	info_label.text = "没有找到可升级的牌。"

func _tune_resonance() -> void:
	RunManager.set_flag("tune_resonance_apply", true)
	info_label.text = "调律完成：本局施加 Resonance 时额外 +1。"

func _rewire(flag_id: String, message: String) -> void:
	RunManager.set_flag(flag_id, true)
	info_label.text = message

func _equip_next_charm() -> void:
	for charm_id in Util.get_charm_reward_pool():
		if not RunManager.charms.has(charm_id):
			RunManager.add_charm(charm_id)
			info_label.text = "已装备 Charm：%s。" % charm_id
			return
	info_label.text = "所有 Charm 都已经拥有。"

func _on_continue_pressed() -> void:
	if RunManager.should_take_interfloor_rest():
		RunManager.consume_interfloor_rest()
	RunManager.complete_current_node()
	if RunManager.has_flag("run_complete"):
		SceneRouter.go_main_menu()
	else:
		SceneRouter.go_map()
