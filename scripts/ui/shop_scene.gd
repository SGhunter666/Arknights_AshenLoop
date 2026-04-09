extends Control

const REWARD_GENERATOR = preload("res://scripts/rewards/RewardGenerator.gd")
const TUNE_LIBRARY = preload("res://scripts/core/tune_library.gd")
const UI_MOTION = preload("res://scripts/core/ui_motion.gd")
const UI_THEME_KIT = preload("res://scripts/ui/ui_theme_kit.gd")

@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $Panel/Margin/VBox/TopRow/Title
@onready var gold_chip: PanelContainer = $Panel/Margin/VBox/TopRow/GoldChip
@onready var gold_label: Label = $Panel/Margin/VBox/TopRow/GoldChip/GoldMargin/GoldLabel
@onready var info_label: Label = $Panel/Margin/VBox/Info
@onready var floor_chip: PanelContainer = $Panel/Margin/VBox/MetaRow/FloorChip
@onready var floor_chip_label: Label = $Panel/Margin/VBox/MetaRow/FloorChip/ChipMargin/ChipLabel
@onready var deck_chip: PanelContainer = $Panel/Margin/VBox/MetaRow/DeckChip
@onready var deck_chip_label: Label = $Panel/Margin/VBox/MetaRow/DeckChip/ChipMargin/ChipLabel
@onready var module_chip: PanelContainer = $Panel/Margin/VBox/MetaRow/ModuleChip
@onready var module_chip_label: Label = $Panel/Margin/VBox/MetaRow/ModuleChip/ChipMargin/ChipLabel
@onready var charm_chip: PanelContainer = $Panel/Margin/VBox/MetaRow/CharmChip
@onready var charm_chip_label: Label = $Panel/Margin/VBox/MetaRow/CharmChip/ChipMargin/ChipLabel
@onready var cards_filter_button: Button = $Panel/Margin/VBox/FilterRow/CardsFilter
@onready var modules_filter_button: Button = $Panel/Margin/VBox/FilterRow/ModulesFilter
@onready var charms_filter_button: Button = $Panel/Margin/VBox/FilterRow/CharmsFilter
@onready var services_filter_button: Button = $Panel/Margin/VBox/FilterRow/ServicesFilter
@onready var content_scroll: ScrollContainer = $Panel/Margin/VBox/ContentScroll
@onready var shop_list: GridContainer = $Panel/Margin/VBox/ContentScroll/ShopList
@onready var continue_button: Button = $Panel/Margin/VBox/Continue

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var shop_refresh_count: int = 0
var reward_generator
var card_db: Dictionary = {}
var module_db: Dictionary = {}
var charm_db: Dictionary = {}
var section_anchors: Dictionary = {}
var section_counts: Dictionary = {"cards": 0, "modules": 0, "charms": 0, "services": 0}
var active_filter_id: String = "cards"

func _ready() -> void:
	rng.seed = RunManager.rng_seed + RunManager.current_floor * 771 + RunManager.gold
	card_db = Util.load_card_db()
	module_db = Util.load_module_db()
	charm_db = Util.load_charm_db()
	reward_generator = REWARD_GENERATOR.new(rng.seed)
	_apply_ui_theme()
	_bind_signals()
	_refresh_static_text()
	info_label.text = LocalizationManager.text("shop.loading")
	call_deferred("_populate_shop")
	call_deferred("_play_intro_animation")

func _bind_signals() -> void:
	if not LocalizationManager.language_changed.is_connected(_refresh_static_text):
		LocalizationManager.language_changed.connect(_refresh_static_text)
	if not RunManager.gold_changed.is_connected(_on_gold_changed):
		RunManager.gold_changed.connect(_on_gold_changed)
	cards_filter_button.pressed.connect(func() -> void: _focus_section("cards"))
	modules_filter_button.pressed.connect(func() -> void: _focus_section("modules"))
	charms_filter_button.pressed.connect(func() -> void: _focus_section("charms"))
	services_filter_button.pressed.connect(func() -> void: _focus_section("services"))

func _refresh_static_text(_language_code: String = "") -> void:
	title_label.text = LocalizationManager.text("shop.title")
	continue_button.text = LocalizationManager.text("reward.continue")
	_refresh_gold_label()
	floor_chip_label.text = LocalizationManager.text("map.hud_floor", [RunManager.current_floor])
	deck_chip_label.text = LocalizationManager.text("map.hud_deck", [RunManager.deck.size()])
	module_chip_label.text = LocalizationManager.text("map.hud_modules", [RunManager.modules.size()])
	charm_chip_label.text = LocalizationManager.text("shop.charms_chip", [RunManager.charms.size()])
	_refresh_filter_text()
	if info_label.text.is_empty() or info_label.text == LocalizationManager.text("shop.loading"):
		info_label.text = LocalizationManager.text("shop.info")
	_refresh_filter_styles()

func _refresh_gold_label() -> void:
	gold_label.text = LocalizationManager.text("shop.gold_chip", [RunManager.gold])

func _on_gold_changed(_amount: int) -> void:
	_refresh_gold_label()

func _clear_shop_entries() -> void:
	for child in shop_list.get_children():
		child.queue_free()
	section_anchors.clear()
	section_counts = {"cards": 0, "modules": 0, "charms": 0, "services": 0}

func _populate_shop() -> void:
	_clear_shop_entries()
	content_scroll.scroll_vertical = 0
	reward_generator = REWARD_GENERATOR.new(rng.seed + shop_refresh_count * 101)
	var reward_bias: Dictionary = RunManager.get_reward_bias_weights()

	_add_section_header(LocalizationManager.text("shop.section_cards"), "cards")
	var card_choices: Array[String] = reward_generator.card_choices(Util.get_card_reward_pool(), 3, reward_bias)
	section_counts["cards"] = card_choices.size()
	for card_id in card_choices:
		_add_shop_entry(
			_card_label(card_id),
			_card_description(card_id),
			45,
			func(id = card_id): RunManager.add_card(id, "shop"),
			_card_image_path(card_id)
		)

	_add_section_header(LocalizationManager.text("shop.section_modules"), "modules")
	var module_choices: Array[String] = _pick_ids(Util.get_module_reward_pool(), 2)
	section_counts["modules"] = module_choices.size()
	for module_id in module_choices:
		_add_shop_entry(
			_module_label(module_id),
			_module_description(module_id),
			90,
			func(id = module_id): RunManager.add_module(id),
			Util.module_icon_path(module_id)
		)

	_add_section_header(LocalizationManager.text("shop.section_charms"), "charms")
	var charm_pool: Array[String] = []
	for charm_id in Util.get_charm_reward_pool():
		if not RunManager.is_charm_owned(charm_id):
			charm_pool.append(charm_id)
	var charm_ids: Array[String] = _pick_ids(charm_pool if not charm_pool.is_empty() else Util.get_charm_reward_pool(), 1)
	section_counts["charms"] = charm_ids.size()
	if not charm_ids.is_empty():
		var charm_id: String = charm_ids[0]
		_add_shop_entry(
			_charm_label(charm_id),
			_charm_description(charm_id),
			80,
			func(id = charm_id): RunManager.add_charm(id)
		)

	_add_section_header(LocalizationManager.text("shop.section_services"), "services")
	section_counts["services"] = 10
	_add_shop_entry(
		LocalizationManager.text("shop.service_remove_first_title"),
		LocalizationManager.text("shop.service_remove_first_desc"),
		75,
		_remove_first_card
	)
	_add_shop_entry(
		LocalizationManager.text("shop.service_upgrade_first_title"),
		LocalizationManager.text("shop.service_upgrade_first_desc"),
		60,
		_upgrade_first_card
	)

	var tune_seed: int = rng.seed + shop_refresh_count * 499 + RunManager.deck.size() * 7 + RunManager.current_floor * 17
	for tune_id in RunManager.tune_offer(tune_seed, 3):
		_add_shop_entry(
			LocalizationManager.text("shop.service_tune_title", [TUNE_LIBRARY.title(tune_id)]),
			TUNE_LIBRARY.description(tune_id),
			65,
			func(id = tune_id): _buy_tune(id)
		)

	_add_shop_entry(
		LocalizationManager.text("shop.service_rewire_arts_title"),
		LocalizationManager.text("shop.service_rewire_arts_desc"),
		50,
		func(): _set_shop_flag("rewire_arts_bonus", LocalizationManager.text("shop.rewire_arts_done"))
	)
	_add_shop_entry(
		LocalizationManager.text("shop.service_rewire_support_title"),
		LocalizationManager.text("shop.service_rewire_support_desc"),
		50,
		func(): _set_shop_flag("rewire_support_draw", LocalizationManager.text("shop.rewire_support_done"))
	)
	_add_shop_entry(
		LocalizationManager.text("shop.service_rewire_overload_title"),
		LocalizationManager.text("shop.service_rewire_overload_desc"),
		50,
		func(): _set_shop_flag("rewire_overload_minus_one", LocalizationManager.text("shop.rewire_overload_done"))
	)
	_add_shop_entry(
		LocalizationManager.text("shop.service_equip_charm_title"),
		LocalizationManager.text("shop.service_equip_charm_desc"),
		80,
		_equip_next_charm
	)
	_add_shop_entry(
		LocalizationManager.text("shop.service_refresh_title"),
		LocalizationManager.text("shop.service_refresh_desc"),
		_refresh_price(),
		_refresh_shop
	)

	if info_label.text == LocalizationManager.text("shop.loading"):
		info_label.text = LocalizationManager.text("shop.info")
	_refresh_filter_text()
	call_deferred("_focus_section", active_filter_id)

func _add_section_header(text: String, section_id: String = "") -> void:
	var panel := PanelContainer.new()
	panel.layout_mode = 2
	UI_THEME_KIT.apply_glass_panel(panel)
	shop_list.add_child(panel)
	if not section_id.is_empty():
		section_anchors[section_id] = panel

	var margin := MarginContainer.new()
	margin.layout_mode = 2
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var label := Label.new()
	label.layout_mode = 2
	UI_THEME_KIT.apply_heading(label, 22, Color(0.98, 0.95, 0.86, 1.0), Color(0.02, 0.03, 0.05, 0.74))
	label.text = text
	margin.add_child(label)
	_add_grid_spacer()

func _add_shop_entry(title: String, description: String, price: int, callback: Callable, image_path: String = "") -> void:
	var wrapper := PanelContainer.new()
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrapper.custom_minimum_size = Vector2(0, 132)
	UI_THEME_KIT.apply_glass_panel(wrapper)
	shop_list.add_child(wrapper)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 14)
	wrapper.add_child(margin)

	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 16)
	margin.add_child(row)

	if not image_path.is_empty() and ResourceLoader.exists(image_path):
		var portrait_frame := PanelContainer.new()
		portrait_frame.custom_minimum_size = Vector2(88, 88)
		var portrait_style := StyleBoxFlat.new()
		portrait_style.bg_color = Color(0.94, 0.97, 1.0, 0.10)
		portrait_style.border_color = Color(0.72, 0.92, 1.0, 0.68)
		portrait_style.border_width_left = 2
		portrait_style.border_width_top = 2
		portrait_style.border_width_right = 2
		portrait_style.border_width_bottom = 2
		portrait_style.corner_radius_top_left = 18
		portrait_style.corner_radius_top_right = 18
		portrait_style.corner_radius_bottom_right = 18
		portrait_style.corner_radius_bottom_left = 18
		portrait_frame.add_theme_stylebox_override("panel", portrait_style)
		row.add_child(portrait_frame)

		var portrait_margin := MarginContainer.new()
		portrait_margin.add_theme_constant_override("margin_left", 8)
		portrait_margin.add_theme_constant_override("margin_top", 8)
		portrait_margin.add_theme_constant_override("margin_right", 8)
		portrait_margin.add_theme_constant_override("margin_bottom", 8)
		portrait_frame.add_child(portrait_margin)

		var portrait := TextureRect.new()
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.custom_minimum_size = Vector2(72, 72)
		portrait.texture = load(image_path) as Texture2D
		portrait_margin.add_child(portrait)

	var text_column := VBoxContainer.new()
	text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_column.add_theme_constant_override("separation", 6)
	row.add_child(text_column)

	var title_label := Label.new()
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI_THEME_KIT.apply_heading(title_label, 20, Color(0.96, 0.95, 0.92, 1.0), Color(0.02, 0.03, 0.05, 0.72))
	title_label.text = title
	text_column.add_child(title_label)

	var desc_label := Label.new()
	desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI_THEME_KIT.apply_body(desc_label, 16, Color(0.90, 0.92, 0.96, 0.90))
	desc_label.text = description
	text_column.add_child(desc_label)

	var buy_button := Button.new()
	buy_button.custom_minimum_size = Vector2(152, 54)
	buy_button.text = LocalizationManager.text("shop.buy_action", [price])
	UI_THEME_KIT.apply_stone_button(buy_button, "paper", 18)
	UI_MOTION.wire_button_feedback(buy_button, 1.02, 0.98, Color(1.0, 0.88, 0.66, 0.70), 5.0)
	buy_button.disabled = RunManager.gold < price
	buy_button.tooltip_text = "%s\n%s" % [title, description]
	buy_button.pressed.connect(func() -> void:
		if RunManager.gold < price:
			info_label.text = LocalizationManager.text("shop.not_enough_gold")
			_refresh_gold_label()
			return
		RunManager.add_gold(-price)
		callback.call()
		buy_button.disabled = true
		_refresh_static_text()
	)
	row.add_child(buy_button)

func _add_grid_spacer() -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 1)
	shop_list.add_child(spacer)

func _focus_section(section_id: String) -> void:
	active_filter_id = section_id
	_refresh_filter_styles()
	if not section_anchors.has(section_id):
		return
	var anchor: Control = section_anchors[section_id] as Control
	if anchor == null:
		return
	content_scroll.scroll_vertical = int(max(anchor.position.y - 12.0, 0.0))

func _pick_ids(pool: Array[String], count: int) -> Array[String]:
	var available: Array[String] = pool.duplicate()
	var result: Array[String] = []
	while result.size() < count and not available.is_empty():
		var index: int = rng.randi_range(0, available.size() - 1)
		result.append(available[index])
		available.remove_at(index)
	return result

func _card_label(card_id: String) -> String:
	var card: CardData = card_db.get(card_id, null) as CardData
	return LocalizationManager.card_name(card) if card != null else card_id

func _module_label(module_id: String) -> String:
	var module_data: ModuleData = module_db.get(module_id, null) as ModuleData
	return LocalizationManager.module_name(module_data) if module_data != null else module_id

func _charm_label(charm_id: String) -> String:
	var charm_data: CharmData = charm_db.get(charm_id, null) as CharmData
	return LocalizationManager.charm_name(charm_data) if charm_data != null else charm_id

func _card_description(card_id: String) -> String:
	var card: CardData = card_db.get(card_id, null) as CardData
	return LocalizationManager.card_description(card) if card != null else ""

func _card_image_path(card_id: String) -> String:
	var direct_path: String = "res://assets/card_art/%s.png" % card_id
	if ResourceLoader.exists(direct_path):
		return direct_path
	return ""

func _module_description(module_id: String) -> String:
	var module_data: ModuleData = module_db.get(module_id, null) as ModuleData
	return LocalizationManager.module_description(module_data) if module_data != null else ""

func _charm_description(charm_id: String) -> String:
	var charm_data: CharmData = charm_db.get(charm_id, null) as CharmData
	return LocalizationManager.charm_description(charm_data) if charm_data != null else ""

func _refresh_price() -> int:
	return [30, 50, 80][min(shop_refresh_count, 2)]

func _refresh_shop() -> void:
	shop_refresh_count += 1
	info_label.text = LocalizationManager.text("shop.refreshed")
	_populate_shop()

func _set_shop_flag(flag_name: String, message: String) -> void:
	RunManager.set_flag(flag_name, true)
	info_label.text = message

func _remove_first_card() -> void:
	if RunManager.deck.is_empty():
		info_label.text = LocalizationManager.text("shop.no_card_to_remove")
		return
	var card_id: String = String(RunManager.deck[0])
	var card: CardData = card_db.get(card_id, null) as CardData
	RunManager.remove_card(card_id)
	info_label.text = LocalizationManager.text("shop.removed_named", [_card_label(card_id) if card != null else card_id])

func _upgrade_first_card() -> void:
	for index in range(RunManager.deck.size()):
		var card: CardData = card_db.get(RunManager.deck[index], null) as CardData
		if card != null and not card.upgraded_id.is_empty() and card_db.has(card.upgraded_id):
			RunManager.deck[index] = card.upgraded_id
			RunManager.deck_changed.emit()
			RunManager.run_updated.emit()
			RunManager.save_run_snapshot()
			info_label.text = LocalizationManager.text("shop.upgraded_named", [LocalizationManager.card_name(card)])
			return
	info_label.text = LocalizationManager.text("shop.no_upgrade_target")

func _buy_tune(tune_id: String) -> void:
	if not RunManager.add_tune(tune_id):
		info_label.text = LocalizationManager.text("shop.tune_owned")
		return
	info_label.text = LocalizationManager.text("shop.tune_bought", [TUNE_LIBRARY.title(tune_id), TUNE_LIBRARY.description(tune_id)])

func _equip_next_charm() -> void:
	for charm_id in RunManager.unequipped_owned_charms():
		if RunManager.equip_charm(charm_id):
			info_label.text = LocalizationManager.text("shop.charm_equipped", [_charm_label(charm_id)])
			return
	for charm_id in Util.get_charm_reward_pool():
		if not RunManager.is_charm_owned(charm_id):
			RunManager.add_charm(charm_id, false)
			RunManager.equip_charm(charm_id)
			info_label.text = LocalizationManager.text("shop.charm_equipped", [_charm_label(charm_id)])
			return
	info_label.text = LocalizationManager.text("shop.all_charms_owned")

func _on_continue_pressed() -> void:
	RunManager.complete_current_node()
	if RunManager.has_flag("run_complete"):
		SceneRouter.go_main_menu()
	else:
		SceneRouter.go_map()

func _apply_ui_theme() -> void:
	UI_THEME_KIT.apply_paper_panel(panel)
	UI_THEME_KIT.apply_heading(title_label, 30, Color(0.18, 0.13, 0.08, 1.0))
	UI_THEME_KIT.apply_glass_panel(gold_chip)
	UI_THEME_KIT.apply_heading(gold_label, 20, Color(0.98, 0.95, 0.86, 1.0), Color(0.06, 0.05, 0.04, 0.76))
	UI_THEME_KIT.apply_body(info_label, 18, Color(0.18, 0.16, 0.14, 0.98))
	for chip_panel in [floor_chip, deck_chip, module_chip, charm_chip]:
		UI_THEME_KIT.apply_glass_panel(chip_panel)
	for chip_label in [floor_chip_label, deck_chip_label, module_chip_label, charm_chip_label]:
		UI_THEME_KIT.apply_numeric(chip_label, 16, Color(0.98, 0.95, 0.86, 1.0), Color(0.06, 0.05, 0.04, 0.76))
	for filter_button in [cards_filter_button, modules_filter_button, charms_filter_button, services_filter_button]:
		UI_MOTION.wire_button_feedback(filter_button, 1.02, 0.98, Color(1.0, 0.88, 0.66, 0.70), 5.0)
	UI_THEME_KIT.apply_stone_button(continue_button, "paper", 24)
	UI_MOTION.wire_button_feedback(continue_button, 1.02, 0.98, Color(1.0, 0.88, 0.66, 0.70), 5.0)
	_refresh_filter_styles()

func _refresh_filter_styles() -> void:
	var button_map := {
		"cards": cards_filter_button,
		"modules": modules_filter_button,
		"charms": charms_filter_button,
		"services": services_filter_button
	}
	for key in button_map.keys():
		var button: Button = button_map[key] as Button
		UI_THEME_KIT.apply_stone_button(button, "paper" if key == active_filter_id else "ghost", 18)

func _refresh_filter_text() -> void:
	cards_filter_button.text = "%s · %d" % [LocalizationManager.text("shop.filter_cards"), int(section_counts.get("cards", 0))]
	modules_filter_button.text = "%s · %d" % [LocalizationManager.text("shop.filter_modules"), int(section_counts.get("modules", 0))]
	charms_filter_button.text = "%s · %d" % [LocalizationManager.text("shop.filter_charms"), int(section_counts.get("charms", 0))]
	services_filter_button.text = "%s · %d" % [LocalizationManager.text("shop.filter_services"), int(section_counts.get("services", 0))]

func _play_intro_animation() -> void:
	UI_MOTION.reveal(panel, 0.04, Vector2(0, 24), 0.28, Vector2(0.99, 0.99))
	UI_MOTION.reveal(continue_button, 0.14, Vector2(0, 16), 0.22, Vector2(0.99, 0.99))
