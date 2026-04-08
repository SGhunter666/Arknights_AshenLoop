extends Control

const SETTINGS_TILE: Texture2D = preload("res://assets/ui_icons/settings_tile.svg")
const PLAYER_ACTOR_TEXTURE: Texture2D = preload("res://人物选择页面的角色壁纸.png")
const UI_MOTION = preload("res://scripts/core/ui_motion.gd")
const CARD_DISPLAY_FACTORY = preload("res://scripts/ui/card_display_factory.gd")
const CARD_GALLERY_OVERLAY = preload("res://scripts/ui/card_gallery_overlay.gd")
const COMBAT_ACTOR_VIEW = preload("res://scripts/ui/combat_actor_view.gd")
const BATTLE_ABANDON_OVERLAY = preload("res://scripts/ui/battle_abandon_overlay.gd")
const ENEMY_VISUAL_RESOLVER = preload("res://scripts/ui/enemy_visual_resolver.gd")
const TUNE_SUMMARY_PRESENTER = preload("res://scripts/ui/tune_summary_presenter.gd")
const UI_THEME_KIT = preload("res://scripts/ui/ui_theme_kit.gd")

@onready var manager: BattleManager = $BattleManager
@onready var background_image: TextureRect = $BackgroundImage
@onready var shade: ColorRect = $Shade
@onready var hud_row: HBoxContainer = $TopHUD/HudMargin/HudRow
@onready var health_chip: Label = $TopHUD/HudMargin/HudRow/HealthChip
@onready var gold_chip: Label = $TopHUD/HudMargin/HudRow/GoldChip
@onready var deck_chip: Button = $TopHUD/HudMargin/HudRow/DeckChip
@onready var discard_chip: Button = $TopHUD/HudMargin/HudRow/DiscardChip
@onready var floor_chip: Label = $TopHUD/HudMargin/HudRow/FloorChip
@onready var turn_chip: Label = $TopHUD/HudMargin/HudRow/TurnChip
@onready var combat_info: Label = $TopHUD/HudMargin/HudRow/CombatInfo
@onready var settings_button: Button = $SettingsButton
@onready var player_actor_stage: Control = $Arena/PlayerActorStage
@onready var player_frame: PanelContainer = $Arena/PlayerFrame
@onready var player_stats: Label = $Arena/PlayerFrame/PlayerStats
@onready var enemy_actor_stage: HBoxContainer = $Arena/EnemyActorStage
@onready var enemy_container: HBoxContainer = $Arena/EnemyContainer
@onready var enemy_intent_frame: PanelContainer = $Arena/EnemyIntentFrame
@onready var enemy_intent_label: Label = $Arena/EnemyIntentFrame/EnemyIntentLabel
@onready var energy_panel: PanelContainer = $BottomHUD/EnergyPanel
@onready var energy_icon: Label = $BottomHUD/EnergyPanel/EnergyIcon
@onready var energy_label: Label = $BottomHUD/EnergyPanel/EnergyLabel
@onready var hand_dock: PanelContainer = $BottomHUD/HandDock
@onready var hand_scroll: Control = $BottomHUD/HandDock/HandMargin/HandScroll
@onready var hand_container: Control = $BottomHUD/HandDock/HandMargin/HandScroll/HandContainer
@onready var log_frame: PanelContainer = $BottomHUD/LogFrame
@onready var log_label: RichTextLabel = $BottomHUD/LogFrame/LogLabel
@onready var end_turn_button: Button = $BottomHUD/EndTurnButton

var abandon_overlay
var enemy_visual_resolver = ENEMY_VISUAL_RESOLVER.new()
var selected_target_index: int = 0
var player_actor_view: CombatActorView
var enemy_actor_views: Array[CombatActorView] = []
var hovered_hand_card: Button = null
var hand_card_tweens: Dictionary = {}
var hand_interaction_locked: bool = false
var aimed_card_index: int = -1
var aimed_card: CardData = null
var aimed_card_button: Button = null
var pending_draw_animation_cards: Array[CardData] = []
var current_ui_scale: float = 1.0
var end_turn_warning_label: Label
var aim_hint_label: Label
var aim_line: Line2D
var aim_reticle: Panel
var battlefield_shake_tweens: Dictionary = {}
var w_phase_fx_seen: Dictionary = {}
var tune_button: Button

func _ready() -> void:
	MusicManager.stop_menu_bgm()
	MusicManager.play_battle_bgm(_is_boss_battle_from_node())
	_ensure_tune_button()
	_embed_settings_icon()
	_attach_settings_feedback()
	_setup_abandon_overlay()
	_apply_ui_theme()
	_style_energy_orb()
	_ensure_end_turn_warning_label()
	_ensure_aim_hint_label()
	_ensure_aim_line()
	_apply_battle_ui_scale()
	player_frame.visible = false
	enemy_container.visible = false
	enemy_intent_frame.visible = false
	_apply_static_text()
	LocalizationManager.language_changed.connect(_on_language_changed)
	manager.resolver.effect_resolved.connect(_on_battle_effect_resolved)
	manager.turn_started.connect(_on_turn_started)
	manager.cards_drawn.connect(_on_cards_drawn)
	settings_button.pressed.connect(func() -> void:
		_press_settings()
	)
	deck_chip.pressed.connect(_open_draw_pile_overlay)
	discard_chip.pressed.connect(_open_discard_pile_overlay)
	manager.hand_changed.connect(_refresh_hand)
	manager.enemy_intents_updated.connect(_refresh_enemies)
	manager.state_changed.connect(_refresh_state)
	manager.log_message.connect(_append_log)
	manager.battle_ended.connect(_on_battle_ended)
	end_turn_button.pressed.connect(func() -> void:
		manager.end_player_turn()
	)
	var enemies: Array[EnemyData] = _build_enemy_list()
	if RunManager.character == null or enemies.is_empty():
		log_label.text = "[color=#ffb3b3]%s[/color]" % LocalizationManager.text("battle.invalid_state")
		call_deferred("_return_from_invalid_state")
		return
	manager.configure(RunManager.character, enemies)
	_setup_actor_views()
	_refresh_state()
	hand_scroll.resized.connect(func() -> void:
		_layout_hand_fan(false)
	)
	set_process(true)
	call_deferred("_play_intro_animation")

func _return_from_invalid_state() -> void:
	if RunManager.has_active_run():
		SceneRouter.go_map()
	else:
		SceneRouter.go_main_menu()

func _on_language_changed(_language_code: String) -> void:
	_apply_static_text()
	_refresh_state()

func _apply_static_text() -> void:
	end_turn_button.text = LocalizationManager.text("battle.end_turn")
	settings_button.text = ""
	settings_button.tooltip_text = LocalizationManager.text("main.settings")
	if tune_button != null:
		tune_button.tooltip_text = TUNE_SUMMARY_PRESENTER.hud_tooltip()
	if abandon_overlay != null:
		abandon_overlay.refresh_text()
	deck_chip.tooltip_text = LocalizationManager.text("battle.inspect_draw")
	discard_chip.tooltip_text = LocalizationManager.text("battle.inspect_discard")

func _build_enemy_list() -> Array[EnemyData]:
	var node: MapNodeModel = RunManager.current_node()
	var db: Dictionary = Util.load_enemy_db()
	var result: Array[EnemyData] = []
	if node == null:
		return result
	for enemy_id in node.metadata.get("enemy_ids", []):
		if db.has(enemy_id):
			result.append(db[enemy_id])
	return result

func _refresh_state() -> void:
	_refresh_hand()
	_refresh_enemies()
	_refresh_actor_views()
	if manager.player != null:
		health_chip.text = LocalizationManager.text("battle.hud_hp", [manager.player.hp, manager.player.max_hp])
		gold_chip.text = LocalizationManager.text("battle.hud_gold", [RunManager.gold])
		deck_chip.text = LocalizationManager.text("battle.hud_draw", [manager.deck.draw_pile.size()])
		discard_chip.text = LocalizationManager.text("battle.hud_discard", [manager.deck.discard_pile.size()])
		floor_chip.text = LocalizationManager.text("battle.hud_floor", [RunManager.current_floor])
		turn_chip.text = ""
		if tune_button != null:
			tune_button.text = TUNE_SUMMARY_PRESENTER.hud_text()
			tune_button.tooltip_text = TUNE_SUMMARY_PRESENTER.hud_tooltip()
		_refresh_combat_info()
		energy_label.text = str(manager.player.energy)
	_update_end_turn_warning()
	_update_aim_hint()

func _refresh_hand() -> void:
	_clear_aim_mode(true)
	hovered_hand_card = null
	hand_card_tweens.clear()
	for child in hand_container.get_children():
		child.queue_free()
	for i in range(manager.deck.hand.size()):
		var card: CardData = manager.deck.hand[i]
		var button: Button = CARD_DISPLAY_FACTORY.create_card_button(
			card,
			LocalizationManager.card_name(card),
			LocalizationManager.card_description(card),
			manager.deck.effective_cost(card),
			Util.load_card_art(card.id),
			_hand_card_size(),
			true,
			CARD_DISPLAY_FACTORY.has_upgrade_visual(card)
		)
		button.disabled = _is_card_unplayable(card)
		button.modulate = _card_color(card, button.disabled)
		button.mouse_entered.connect(func(target_button: Button = button) -> void:
			if aimed_card_button != null and aimed_card_button != target_button:
				return
			hovered_hand_card = target_button
			_refresh_actor_views()
			_layout_hand_fan(true)
		)
		button.mouse_exited.connect(func(target_button: Button = button) -> void:
			if aimed_card_button != null and aimed_card_button != target_button:
				return
			if hovered_hand_card == target_button:
				hovered_hand_card = null
			_refresh_actor_views()
			_layout_hand_fan(true)
		)
		button.pressed.connect(func(index: int = i, played_card: CardData = card) -> void:
			_on_card_pressed(index, played_card)
		)
		hand_container.add_child(button)
	call_deferred("_layout_hand_fan", false)
	call_deferred("_play_pending_draw_animations")

func _process(_delta: float) -> void:
	_update_aim_line()

func _refresh_enemies() -> void:
	for child in enemy_container.get_children():
		child.queue_free()
	_update_enemy_intent_panel()

func _setup_actor_views() -> void:
	if player_actor_view == null:
		player_actor_view = COMBAT_ACTOR_VIEW.new()
		player_actor_view.set_anchors_preset(Control.PRESET_FULL_RECT)
		player_actor_stage.add_child(player_actor_view)
		player_actor_view.setup_actor(
			LocalizationManager.text("map.hero_chip"),
			PLAYER_ACTOR_TEXTURE,
			null,
			Color(0.60, 0.84, 1.0, 1.0),
			"left"
		)
		player_actor_view.apply_ui_scale(_actor_ui_scale())
	_refresh_actor_views(true)

func _refresh_actor_views(force_rebuild: bool = false) -> void:
	if player_actor_view != null and manager.player != null:
		player_actor_view.update_stats(manager.player.hp, manager.player.max_hp, manager.player.block)
		player_actor_view.update_statuses(_player_status_entries())
		player_actor_view.set_state_badge("", Color.WHITE, "")
		player_actor_view.set_warning_state(_count_curse_in_hand("blast_countdown") > 0, Color(1.0, 0.44, 0.30, 1.0))
	var should_rebuild: bool = force_rebuild or enemy_actor_views.size() != manager.enemies.size()
	if should_rebuild:
		for child in enemy_actor_stage.get_children():
			child.queue_free()
		enemy_actor_views.clear()
		for i in range(manager.enemies.size()):
			var enemy: UnitState = manager.enemies[i]
			var actor_view: CombatActorView = COMBAT_ACTOR_VIEW.new()
			actor_view.custom_minimum_size = _enemy_actor_min_size()
			enemy_actor_stage.add_child(actor_view)
			actor_view.setup_actor(
				LocalizationManager.enemy_name(enemy.id, enemy.display_name),
				enemy_visual_resolver.actor_texture(enemy.id),
				enemy_visual_resolver.actor_emblem(enemy.id),
				enemy_visual_resolver.actor_accent(enemy.id),
				"right"
			)
			actor_view.apply_ui_scale(_actor_ui_scale())
			actor_view.set_portrait_tint(enemy_visual_resolver.actor_tint(enemy.id))
			actor_view.actor_pressed.connect(func(index: int = i) -> void:
				_on_enemy_actor_pressed(index)
			)
			actor_view.mouse_entered.connect(func(index: int = i) -> void:
				_on_enemy_actor_hovered(index)
			)
			enemy_actor_views.append(actor_view)
	for i in range(min(enemy_actor_views.size(), manager.enemies.size())):
		var enemy: UnitState = manager.enemies[i]
		var actor_view: CombatActorView = enemy_actor_views[i]
		if actor_view != null:
			actor_view.update_stats(enemy.hp, enemy.max_hp, enemy.block)
			actor_view.update_statuses(_status_entries(enemy))
			actor_view.set_selected(i == selected_target_index)
			actor_view.set_preview_target(i == selected_target_index and _is_targeting_enemy_now())
			var is_w_phase_two: bool = _enemy_is_w_phase_two(i)
			if _enemy_is_bomb_threat(enemy):
				var bomb_count: int = max(1, int(enemy.intent.get("value", 1)))
				actor_view.set_state_badge("炸 x%d" % bomb_count, Color(1.0, 0.50, 0.28, 1.0), "这回合会往你的牌堆塞入爆破倒计时。")
			elif is_w_phase_two:
				actor_view.set_state_badge("P2", Color(1.0, 0.32, 0.30, 1.0), "W 已进入第二阶段：攻击更快，假动作更多。")
			else:
				actor_view.set_state_badge("", Color.WHITE, "")
			actor_view.set_warning_state(is_w_phase_two or _enemy_is_bomb_threat(enemy), Color(1.0, 0.34, 0.30, 1.0))
			if is_w_phase_two and not w_phase_fx_seen.has(enemy.get_instance_id()):
				w_phase_fx_seen[enemy.get_instance_id()] = true
				actor_view.play_arts()
			var intent_data: Dictionary = _intent_visuals(enemy, enemy.intent)
			actor_view.set_intent(
				String(intent_data.get("icon", "")),
				String(intent_data.get("value", "")),
				intent_data.get("color", Color.WHITE),
				String(intent_data.get("tooltip", ""))
			)
	_update_enemy_intent_panel()

func _append_log(text: String) -> void:
	log_label.append_text(text + "\n")

func _on_battle_ended(victory: bool) -> void:
	if abandon_overlay != null:
		abandon_overlay.set_disabled(true)
	_clear_aim_mode(true)
	if victory:
		return

func _is_boss_battle_from_node() -> bool:
	var node: MapNodeModel = RunManager.current_node()
	if node != null and node.node_type == "boss":
		return true
	return false

func _is_boss_battle() -> bool:
	if _is_boss_battle_from_node():
		return true
	for enemy_data in manager.enemy_datas:
		if "Boss" in enemy_data.tags:
			return true
	return false

func _embed_settings_icon() -> void:
	var icon_rect: TextureRect = settings_button.get_node_or_null("SettingsIcon") as TextureRect
	if icon_rect == null:
		icon_rect = TextureRect.new()
		icon_rect.name = "SettingsIcon"
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_rect.layout_mode = 1
		icon_rect.anchor_left = 0.0
		icon_rect.anchor_top = 0.0
		icon_rect.anchor_right = 1.0
		icon_rect.anchor_bottom = 1.0
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		settings_button.add_child(icon_rect)
	icon_rect.texture = SETTINGS_TILE

func _attach_settings_feedback() -> void:
	settings_button.flat = true
	settings_button.pivot_offset = settings_button.size * 0.5
	var ring: Panel = settings_button.get_node_or_null("FeedbackRing") as Panel
	if ring == null:
		ring = Panel.new()
		ring.name = "FeedbackRing"
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ring.layout_mode = 1
		ring.anchor_left = 0.0
		ring.anchor_top = 0.0
		ring.anchor_right = 1.0
		ring.anchor_bottom = 1.0
		ring.offset_left = -3.0
		ring.offset_top = -3.0
		ring.offset_right = 3.0
		ring.offset_bottom = 3.0
		settings_button.add_child(ring)
		settings_button.move_child(ring, 0)
	settings_button.mouse_entered.connect(func() -> void:
		_update_settings_feedback(false)
	)
	settings_button.button_down.connect(func() -> void:
		_update_settings_feedback(true)
	)
	settings_button.button_up.connect(func() -> void:
		_update_settings_feedback(false)
	)
	settings_button.mouse_exited.connect(func() -> void:
		_update_settings_feedback(false)
	)
	_update_settings_feedback(false)

func _setup_abandon_overlay() -> void:
	abandon_overlay = BATTLE_ABANDON_OVERLAY.new()
	abandon_overlay.name = "BattleAbandonOverlay"
	abandon_overlay.layout_mode = 1
	abandon_overlay.anchor_left = 0.0
	abandon_overlay.anchor_top = 0.0
	abandon_overlay.anchor_right = 1.0
	abandon_overlay.anchor_bottom = 1.0
	abandon_overlay.set_battle_finished_provider(func() -> bool:
		return manager.battle_finished
	)
	add_child(abandon_overlay)
	abandon_overlay.abandon_confirmed.connect(_confirm_abandon_run)

func _confirm_abandon_run() -> void:
	if manager.battle_finished:
		return
	manager.abandon_battle()

func _update_settings_feedback(pressed: bool) -> void:
	var hovered: bool = settings_button.get_global_rect().has_point(settings_button.get_global_mouse_position())
	settings_button.pivot_offset = settings_button.size * 0.5
	settings_button.scale = Vector2(0.96, 0.96) if pressed else (Vector2(1.03, 1.03) if hovered else Vector2.ONE)
	var icon_rect: TextureRect = settings_button.get_node_or_null("SettingsIcon") as TextureRect
	if icon_rect != null:
		icon_rect.position = Vector2(0, 3) if pressed else Vector2.ZERO
	var ring: Panel = settings_button.get_node_or_null("FeedbackRing") as Panel
	if ring == null:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_right = 16
	style.corner_radius_bottom_left = 16
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	if hovered:
		style.border_color = Color(0.82, 0.95, 1.0, 0.76)
		style.shadow_color = Color(0.48, 0.78, 1.0, 0.48)
		style.shadow_size = 14 if not pressed else 6
	else:
		style.border_color = Color(0.82, 0.95, 1.0, 0.0)
		style.shadow_color = Color(0, 0, 0, 0)
		style.shadow_size = 0
	ring.add_theme_stylebox_override("panel", style)

func _play_intro_animation() -> void:
	UI_MOTION.reveal($TopHUD, 0.02, Vector2(0, -16), 0.24)
	UI_MOTION.reveal($Arena, 0.08, Vector2(0, 18), 0.28, Vector2(0.99, 0.99))
	UI_MOTION.reveal($BottomHUD, 0.12, Vector2(0, 26), 0.30, Vector2(0.99, 0.99))
	if player_actor_view != null:
		UI_MOTION.reveal(player_actor_view, 0.10, Vector2(-16, 0), 0.30, Vector2(0.98, 0.98))
	for i in range(enemy_actor_views.size()):
		UI_MOTION.reveal(enemy_actor_views[i], 0.16 + i * 0.04, Vector2(16, 0), 0.28, Vector2(0.98, 0.98))

func _apply_battle_ui_scale() -> void:
	current_ui_scale = float(SettingsManager.get_settings().get("ui_scale", 1.25))
	for label in [health_chip, gold_chip, deck_chip, discard_chip, floor_chip, turn_chip]:
		if label is Control:
			(label as Control).add_theme_font_size_override("font_size", 20)
	if tune_button != null:
		tune_button.add_theme_font_size_override("font_size", 20)
	combat_info.add_theme_font_size_override("font_size", 20)
	end_turn_button.add_theme_font_size_override("font_size", 28)
	log_label.add_theme_font_size_override("normal_font_size", 18)
	energy_panel.custom_minimum_size = Vector2(114, 114)
	energy_icon.add_theme_font_size_override("font_size", 86)
	energy_label.add_theme_font_size_override("font_size", 38)
	settings_button.custom_minimum_size = Vector2(56, 56)
	if player_actor_view != null:
		player_actor_view.apply_ui_scale(_actor_ui_scale())
	for actor_view in enemy_actor_views:
		if actor_view != null:
			actor_view.custom_minimum_size = _enemy_actor_min_size()
			actor_view.apply_ui_scale(_actor_ui_scale())

func _actor_ui_scale() -> float:
	return 1.0 + (current_ui_scale - 1.0) * 0.48

func _enemy_actor_min_size() -> Vector2:
	return Vector2(296, 436) * _actor_ui_scale()

func _hand_card_size() -> Vector2:
	var hand_scale: float = 1.0 + (current_ui_scale - 1.0) * 0.06
	return Vector2(152, 224) * hand_scale

func _press_settings() -> void:
	await UI_MOTION.pulse(settings_button, 0.94, 1.04, 0.06).finished
	SceneRouter.go_settings(SceneRouter.BATTLE_SCENE)

func _ensure_tune_button() -> void:
	if tune_button != null:
		return
	tune_button = Button.new()
	tune_button.name = "TuneButton"
	tune_button.layout_mode = 2
	UI_THEME_KIT.apply_stone_button(tune_button, "ghost", 18)
	UI_MOTION.wire_button_feedback(tune_button, 1.03, 0.97, Color(0.76, 0.92, 1.0, 0.72), 5.0)
	tune_button.pressed.connect(_open_tune_overlay)
	hud_row.add_child(tune_button)
	hud_row.move_child(tune_button, combat_info.get_index())

func _open_tune_overlay() -> void:
	UI_MOTION.pulse(tune_button, 0.95, 1.04, 0.06)
	TUNE_SUMMARY_PRESENTER.open_current_overlay(self)

func _target_name() -> String:
	if manager.enemies.is_empty():
		return LocalizationManager.text("battle.target_none")
	selected_target_index = int(clamp(selected_target_index, 0, manager.enemies.size() - 1))
	var enemy: UnitState = manager.enemies[selected_target_index]
	return LocalizationManager.enemy_name(enemy.id, enemy.display_name)

func _is_card_unplayable(card: CardData) -> bool:
	if card.card_type == "Curse":
		return true
	return manager.player != null and manager.player.energy < manager.deck.effective_cost(card)

func _card_color(card: CardData, disabled: bool) -> Color:
	if card == null:
		return Color(0.86, 0.90, 0.98, 0.92) if not disabled else Color(0.62, 0.62, 0.66, 0.88)
	if disabled:
		return Color(0.62, 0.62, 0.66, 0.88)
	if "Arts" in card.tags:
		return Color(0.48, 0.88, 0.96, 1.0)
	if "Support" in card.tags:
		return Color(0.95, 0.60, 0.30, 1.0)
	if card.card_type == "Skill":
		return Color(0.76, 0.88, 1.0, 1.0)
	return Color(0.96, 0.82, 0.32, 1.0)

func _open_draw_pile_overlay() -> void:
	var cards: Array[CardData] = []
	for i in range(manager.deck.draw_pile.size() - 1, -1, -1):
		cards.append(manager.deck.draw_pile[i])
	_open_gallery(LocalizationManager.text("battle.draw_pile_title"), cards)

func _open_discard_pile_overlay() -> void:
	var cards: Array[CardData] = []
	for card in manager.deck.discard_pile:
		cards.append(card)
	cards.reverse()
	_open_gallery(LocalizationManager.text("battle.discard_pile_title"), cards)

func _open_gallery(title_text: String, cards: Array[CardData]) -> void:
	var overlay: CardGalleryOverlay = CARD_GALLERY_OVERLAY.new()
	overlay.setup(title_text, cards)
	add_child(overlay)

func _on_card_pressed(index: int, card: CardData) -> void:
	if hand_interaction_locked:
		return
	if _card_targets_enemy(card):
		var source_button: Button = null
		if index >= 0 and index < hand_container.get_child_count():
			source_button = hand_container.get_child(index) as Button
		if aimed_card_index == index and aimed_card_button == source_button:
			_confirm_aimed_card()
		else:
			_enter_aim_mode(index, card, source_button)
		return
	_clear_aim_mode(true)
	_play_card_from_hand(index, card)

func _play_card_from_hand(index: int, card: CardData) -> void:
	hand_interaction_locked = true
	var target_center: Vector2 = _card_target_point(card)
	var source_rect: Rect2 = Rect2(Vector2.ZERO, Vector2.ZERO)
	if index >= 0 and index < hand_container.get_child_count():
		var source_button: Control = hand_container.get_child(index) as Control
		if source_button != null:
			source_rect = source_button.get_global_rect()
	await _play_card_launch_animation(card, source_rect, target_center)
	var played: bool = manager.play_card(index, selected_target_index)
	hand_interaction_locked = false
	if not played:
		return
	if player_actor_view == null:
		return
	if "Arts" in card.tags:
		player_actor_view.play_arts()
	elif "Support" in card.tags:
		player_actor_view.play_support()
	elif card.card_type == "Skill":
		player_actor_view.play_skill()
	else:
		player_actor_view.play_attack()

func _enter_aim_mode(index: int, card: CardData, source_button: Button) -> void:
	if source_button == null:
		return
	aimed_card_index = index
	aimed_card = card
	aimed_card_button = source_button
	hovered_hand_card = source_button
	_refresh_actor_views()
	_refresh_combat_info()
	_update_aim_hint()
	_update_enemy_intent_panel()
	_layout_hand_fan(true)
	_append_log("选中 [%s]，请选择目标。" % LocalizationManager.card_name(card))

func _clear_aim_mode(silent: bool = false) -> void:
	if aimed_card_index == -1 and aimed_card_button == null and aimed_card == null:
		return
	aimed_card_index = -1
	aimed_card = null
	aimed_card_button = null
	if silent:
		return
	hovered_hand_card = null
	_refresh_actor_views()
	_refresh_combat_info()
	_update_aim_hint()
	_update_enemy_intent_panel()
	_layout_hand_fan(true)

func _confirm_aimed_card() -> void:
	if aimed_card_index == -1 or aimed_card == null:
		return
	var index: int = aimed_card_index
	var card: CardData = aimed_card
	_clear_aim_mode(true)
	_play_card_from_hand(index, card)

func _on_battle_effect_resolved(effect_type: String, payload: Dictionary) -> void:
	if effect_type == "apply_resonance":
		var resonance_targets: Array = payload.get("targets", [])
		var resonance_amount: int = int(payload.get("amount", 0))
		for target_variant in resonance_targets:
			var resonance_target: UnitState = target_variant as UnitState
			if resonance_target != null and resonance_amount > 0:
				_append_log(LocalizationManager.text("battle.log.resonance_apply", [
					_unit_display_name(resonance_target),
					resonance_amount
				]))
		return
	if effect_type == "damage_per_target_resonance_consume_all":
		var target_unit: UnitState = payload.get("target", null) as UnitState
		var spent_layers: int = int(payload.get("layers", 0))
		if target_unit != null and spent_layers > 0:
			_append_log(LocalizationManager.text("battle.log.resonance_consume", [
				_unit_display_name(target_unit),
				spent_layers
			]))
		return
	if effect_type == "damage_from_will_and_target_resonance":
		var combo_target: UnitState = payload.get("target", null) as UnitState
		var combo_layers: int = int(payload.get("resonance", 0))
		if combo_target != null and combo_layers > 0:
			_append_log(LocalizationManager.text("battle.log.resonance_consume", [
				_unit_display_name(combo_target),
				combo_layers
			]))
		return
	if effect_type == "damage_resonant_all_consume":
		var total_layers: int = int(payload.get("layers", 0))
		if total_layers > 0:
			_append_log(LocalizationManager.text("battle.log.resonance_consume_total", [total_layers]))
		return
	if effect_type != "damage":
		return
	var amount: int = int(payload.get("amount", 0))
	if amount <= 0:
		return
	var source_unit: UnitState = payload.get("source") as UnitState
	var target_unit: UnitState = payload.get("target") as UnitState
	if source_unit == manager.player and player_actor_view != null:
		player_actor_view.play_attack()
	elif source_unit != null:
		var source_enemy_actor: Control = _enemy_actor_for_unit(source_unit)
		if source_enemy_actor != null:
			source_enemy_actor.play_attack()
	if target_unit == manager.player and player_actor_view != null:
		player_actor_view.play_hit()
		_shake_battlefield(clamp(0.75 + float(amount) / 18.0, 0.85, 1.45))
	elif target_unit != null:
		var target_enemy_actor: Control = _enemy_actor_for_unit(target_unit)
		if target_enemy_actor != null:
			target_enemy_actor.play_hit()
		_shake_battlefield(clamp(0.34 + float(amount) / 26.0, 0.34, 0.88))
	var source_name: String = _unit_display_name(source_unit)
	var target_name: String = _unit_display_name(target_unit)
	_append_log(LocalizationManager.text("battle.log.damage_detail", [source_name, target_name, amount]))

func _on_turn_started(side: String) -> void:
	if side == "enemy":
		for actor_view in enemy_actor_views:
			if actor_view != null:
				actor_view.play_skill()

func _enemy_actor_for_unit(unit: UnitState) -> CombatActorView:
	for i in range(min(manager.enemies.size(), enemy_actor_views.size())):
		if manager.enemies[i] == unit:
			return enemy_actor_views[i]
	return null

func _update_enemy_intent_panel() -> void:
	enemy_intent_frame.visible = false
	if manager.enemies.is_empty():
		enemy_intent_label.text = LocalizationManager.text("battle.target_none")
		return
	selected_target_index = int(clamp(selected_target_index, 0, manager.enemies.size() - 1))
	var enemy: UnitState = manager.enemies[selected_target_index]
	var intent_text: String = LocalizationManager.intent_label(_intent_display_label(enemy.intent))
	var resource_line: String = "护盾 %d" % enemy.block
	if enemy.resonance > 0:
		resource_line += "    共振 %d" % enemy.resonance
	enemy_intent_label.text = "%s\n%d / %d    %s\n%s" % [
		LocalizationManager.enemy_name(enemy.id, enemy.display_name),
		enemy.hp,
		enemy.max_hp,
		resource_line,
		intent_text
	]

func _layout_hand_fan(animate: bool = true) -> void:
	var cards: Array = hand_container.get_children()
	if cards.is_empty():
		return
	var area_width: float = max(hand_scroll.size.x, 700.0)
	var card_size: Vector2 = _hand_card_size()
	var count: int = cards.size()
	var spread: float = min(area_width * 0.74, (150.0 + card_size.x * 0.10) * max(1, count - 1))
	var max_angle: float = min(16.0, 4.0 + count * 1.5)
	var base_y: float = max(hand_scroll.size.y, card_size.y + 88.0) - card_size.y - 70.0
	var hovered_index: int = cards.find(hovered_hand_card)
	var aimed_index: int = cards.find(aimed_card_button)
	for i in range(count):
		var card_button: Button = cards[i] as Button
		if card_button == null:
			continue
		var card: CardData = manager.deck.hand[i] if i < manager.deck.hand.size() else null
		var base_modulate: Color = _card_color(card, card_button.disabled)
		var t: float = 0.5 if count <= 1 else float(i) / float(count - 1)
		var centered: float = t - 0.5
		var x: float = area_width * 0.5 + centered * spread - card_size.x * 0.5
		if aimed_index != -1 and i != aimed_index:
			var aimed_distance: int = abs(i - aimed_index)
			var aimed_push: float = (36.0 + card_size.x * 0.10) / float(max(1, aimed_distance))
			x += -aimed_push if i < aimed_index else aimed_push
		elif hovered_index != -1 and i != hovered_index:
			var distance: int = abs(i - hovered_index)
			var push_strength: float = (22.0 + card_size.x * 0.04) / float(distance)
			x += -push_strength if i < hovered_index else push_strength
		var arc_strength: float = 1.0 - min(1.0, abs(centered) * 2.0)
		var y: float = base_y + (1.0 - arc_strength) * (24.0 + card_size.y * 0.012)
		var hovered: bool = hovered_hand_card == card_button
		var aimed: bool = aimed_card_button == card_button
		var target_position: Vector2 = Vector2(x, y - (28.0 + card_size.y * 0.03 if hovered else 0.0))
		var target_rotation: float = centered * max_angle
		var target_scale: Vector2 = Vector2.ONE * (1.10 if hovered else 1.0)
		var target_modulate: Color = base_modulate
		if aimed:
			target_position = Vector2(area_width * 0.5 - card_size.x * 0.5, base_y - (92.0 + card_size.y * 0.05))
			target_rotation = 0.0
			target_scale = Vector2.ONE * 1.14
			target_modulate = base_modulate.lerp(Color(1.0, 1.0, 1.0, 1.0), 0.10)
		elif aimed_index != -1:
			target_position.y += 36.0 + (1.0 - arc_strength) * 10.0
			target_rotation *= 0.72
			target_scale = Vector2.ONE * 0.92
			target_modulate = Color(base_modulate.r, base_modulate.g, base_modulate.b, base_modulate.a * 0.52)
		elif hovered:
			target_rotation *= 0.22
			target_modulate = base_modulate.lerp(Color(1.0, 1.0, 1.0, base_modulate.a), 0.08)
		card_button.pivot_offset = card_size * 0.5
		card_button.z_index = 220 + i if aimed else (100 + i if hovered else i)
		if animate:
			_tween_hand_card(card_button, target_position, target_rotation, target_scale, target_modulate)
		else:
			card_button.position = target_position
			card_button.rotation_degrees = target_rotation
			card_button.scale = target_scale
			card_button.modulate = target_modulate

func _tween_hand_card(card_button: Button, target_position: Vector2, target_rotation: float, target_scale: Vector2, target_modulate: Color) -> void:
	var instance_id: int = card_button.get_instance_id()
	var existing_tween: Tween = hand_card_tweens.get(instance_id) as Tween
	if existing_tween != null:
		existing_tween.kill()
	var tween: Tween = create_tween()
	hand_card_tweens[instance_id] = tween
	tween.set_parallel(true)
	tween.tween_property(card_button, "position", target_position, 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(card_button, "rotation_degrees", target_rotation, 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(card_button, "scale", target_scale, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(card_button, "modulate", target_modulate, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _hovered_card_targets_enemy() -> bool:
	if hovered_hand_card == null:
		return false
	var cards: Array = hand_container.get_children()
	var hovered_index: int = cards.find(hovered_hand_card)
	if hovered_index == -1 or hovered_index >= manager.deck.hand.size():
		return false
	var card: CardData = manager.deck.hand[hovered_index]
	return _card_targets_enemy(card)

func _card_targets_enemy(card: CardData) -> bool:
	if card == null or card.card_type == "Curse":
		return false
	for effect in card.effects:
		var effect_target: String = String(effect.target)
		if effect.effect_type in ["damage", "spend_all_will_damage", "damage_all", "apply_status"]:
			if effect_target in ["enemy", "all_enemies", "random_enemy", ""]:
				return true
	return false

func _card_target_point(card: CardData) -> Vector2:
	if _card_targets_enemy(card) and selected_target_index >= 0 and selected_target_index < enemy_actor_views.size():
		var actor_view: CombatActorView = enemy_actor_views[selected_target_index]
		if actor_view != null:
			var rect: Rect2 = actor_view.get_global_rect()
			return rect.get_center()
	if player_actor_view != null:
		return player_actor_view.get_global_rect().get_center()
	return get_viewport_rect().get_center()

func _play_card_launch_animation(card: CardData, source_rect: Rect2, target_point: Vector2) -> void:
	if source_rect.size == Vector2.ZERO:
		return
	var clone: Button = CARD_DISPLAY_FACTORY.create_card_button(
		card,
		LocalizationManager.card_name(card),
		LocalizationManager.card_description(card),
		manager.deck.effective_cost(card),
		Util.load_card_art(card.id),
		source_rect.size,
		true,
		CARD_DISPLAY_FACTORY.has_upgrade_visual(card)
	)
	clone.disabled = true
	clone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clone.z_index = 900
	clone.position = source_rect.position
	clone.pivot_offset = source_rect.size * 0.5
	add_child(clone)
	var windup_position: Vector2 = source_rect.position + Vector2(0.0, -48.0)
	var target_position: Vector2 = target_point - source_rect.size * 0.5
	var windup: Tween = create_tween()
	windup.set_parallel(true)
	windup.tween_property(clone, "position", windup_position, 0.08).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	windup.tween_property(clone, "scale", Vector2(1.08, 1.08), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	windup.tween_property(clone, "rotation_degrees", 0.0, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await windup.finished
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(clone, "position", target_position, 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(clone, "scale", Vector2(0.68, 0.68), 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(clone, "rotation_degrees", 10.0 if target_point.x > source_rect.position.x else -10.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(clone, "modulate:a", 0.0, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished
	clone.queue_free()

func _on_cards_drawn(cards: Array[CardData], _source: String) -> void:
	for card in cards:
		pending_draw_animation_cards.append(card)

func _play_pending_draw_animations() -> void:
	if pending_draw_animation_cards.is_empty():
		return
	var count: int = min(pending_draw_animation_cards.size(), hand_container.get_child_count())
	if count <= 0:
		pending_draw_animation_cards.clear()
		return
	var cards_to_animate: Array = pending_draw_animation_cards.slice(max(0, pending_draw_animation_cards.size() - count), pending_draw_animation_cards.size())
	pending_draw_animation_cards.clear()
	var start_index: int = hand_container.get_child_count() - count
	for offset in range(count):
		var target_button: Button = hand_container.get_child(start_index + offset) as Button
		if target_button == null:
			continue
		var card: CardData = cards_to_animate[offset]
		_animate_draw_to_hand(card, target_button, float(offset) * 0.05)

func _animate_draw_to_hand(card: CardData, target_button: Button, delay: float) -> void:
	if card == null or target_button == null:
		return
	var target_rect: Rect2 = target_button.get_global_rect()
	var final_modulate: Color = target_button.modulate
	target_button.modulate = Color(final_modulate.r, final_modulate.g, final_modulate.b, 0.06)
	var clone: Button = CARD_DISPLAY_FACTORY.create_card_button(
		card,
		LocalizationManager.card_name(card),
		LocalizationManager.card_description(card),
		manager.deck.effective_cost(card),
		Util.load_card_art(card.id),
		target_rect.size,
		true,
		CARD_DISPLAY_FACTORY.has_upgrade_visual(card)
	)
	clone.disabled = true
	clone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clone.z_index = 860
	clone.pivot_offset = target_rect.size * 0.5
	var deck_center: Vector2 = deck_chip.get_global_rect().get_center()
	clone.position = deck_center - target_rect.size * 0.5
	clone.scale = Vector2.ONE * 0.42
	clone.rotation_degrees = randf_range(-12.0, 12.0)
	clone.modulate = Color(1.0, 1.0, 1.0, 0.92)
	add_child(clone)
	var tween: Tween = create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.set_parallel(true)
	tween.tween_property(clone, "position", target_rect.position, 0.24).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(clone, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(clone, "rotation_degrees", target_button.rotation_degrees, 0.24).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(clone, "modulate:a", 0.0, 0.26).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	var reveal_tween: Tween = create_tween()
	if delay > 0.0:
		reveal_tween.tween_interval(delay + 0.10)
	reveal_tween.tween_property(target_button, "modulate", final_modulate, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.finished.connect(func() -> void:
		target_button.modulate = final_modulate
		clone.queue_free()
	)

func _ensure_aim_line() -> void:
	if aim_line == null:
		aim_line = Line2D.new()
		aim_line.name = "AimLine"
		aim_line.visible = false
		aim_line.z_index = 720
		aim_line.width = 6.0
		aim_line.default_color = Color(1.0, 0.88, 0.58, 0.94)
		aim_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		aim_line.end_cap_mode = Line2D.LINE_CAP_ROUND
		aim_line.joint_mode = Line2D.LINE_JOINT_ROUND
		add_child(aim_line)
	if aim_reticle == null:
		aim_reticle = Panel.new()
		aim_reticle.name = "AimReticle"
		aim_reticle.visible = false
		aim_reticle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		aim_reticle.custom_minimum_size = Vector2(22, 22)
		aim_reticle.z_index = 721
		add_child(aim_reticle)
		var style := StyleBoxFlat.new()
		style.bg_color = Color(1.0, 0.94, 0.76, 0.24)
		style.corner_radius_top_left = 99
		style.corner_radius_top_right = 99
		style.corner_radius_bottom_right = 99
		style.corner_radius_bottom_left = 99
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = Color(1.0, 0.92, 0.70, 0.94)
		style.shadow_color = Color(1.0, 0.84, 0.42, 0.24)
		style.shadow_size = 12
		aim_reticle.add_theme_stylebox_override("panel", style)

func _update_aim_line() -> void:
	if aim_line == null or aim_reticle == null:
		return
	if aimed_card == null or aimed_card_button == null or not is_instance_valid(aimed_card_button) or not _card_targets_enemy(aimed_card):
		aim_line.visible = false
		aim_reticle.visible = false
		return
	var start_global: Vector2 = aimed_card_button.get_global_rect().get_center() + Vector2(0.0, -aimed_card_button.size.y * 0.18)
	var end_global: Vector2 = get_global_mouse_position()
	aim_line.visible = true
	aim_reticle.visible = true
	aim_line.points = PackedVector2Array([_global_to_ui_local(start_global), _global_to_ui_local(end_global)])
	aim_reticle.position = _global_to_ui_local(end_global) - aim_reticle.custom_minimum_size * 0.5

func _global_to_ui_local(point: Vector2) -> Vector2:
	return get_global_transform().affine_inverse() * point

func _shake_battlefield(intensity: float) -> void:
	_shake_control(background_image, Vector2(8, 5) * intensity)
	_shake_control(shade, Vector2(6, 4) * intensity)
	_shake_control($Arena, Vector2(12, 7) * intensity)

func _shake_control(control: Control, amplitude: Vector2) -> void:
	if control == null:
		return
	var key: int = control.get_instance_id()
	var base_position: Vector2 = control.get_meta("shake_base_position", control.position)
	var existing_tween: Tween = battlefield_shake_tweens.get(key) as Tween
	if existing_tween != null:
		existing_tween.kill()
	control.position = base_position
	control.set_meta("shake_base_position", base_position)
	var tween: Tween = UI_MOTION.shake(control, amplitude, 0.22, 4)
	battlefield_shake_tweens[key] = tween
	tween.finished.connect(func() -> void:
		control.position = base_position
		battlefield_shake_tweens.erase(key)
	)

func _player_status_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	if manager.player == null:
		return entries
	entries = _status_entries(manager.player)
	if manager.player.will > 0:
		entries.append({
			"icon": "意",
			"amount": str(manager.player.will),
			"tooltip": LocalizationManager.text("battle.status_will", [
				manager.player.will,
				min(manager.player.will, 6),
				4 if manager.player.will >= 4 else 0
			]),
			"bg": Color(0.22, 0.28, 0.58, 0.88),
			"border": Color(0.72, 0.84, 1.0, 0.90),
			"fg": Color(0.98, 0.98, 1.0, 1.0)
		})
	var countdown_count: int = _count_curse_in_hand("blast_countdown")
	if countdown_count > 0:
		entries.append({
			"icon": "炸",
			"amount": str(countdown_count),
			"tooltip": "手里还有 %d 张爆破倒计时。若直接结束回合，会吃到 %d 点伤害。" % [countdown_count, countdown_count * 8],
			"bg": Color(0.62, 0.18, 0.12, 0.90),
			"border": Color(1.0, 0.72, 0.52, 0.94),
			"fg": Color(1.0, 0.96, 0.92, 1.0)
		})
	if bool(manager.player.meta.get("support_trigger_ready", false)):
		entries.append({
			"icon": "领",
			"amount": "",
			"tooltip": LocalizationManager.text("battle.status_leader_ready"),
			"bg": Color(0.66, 0.44, 0.14, 0.88),
			"border": Color(1.0, 0.88, 0.54, 0.92),
			"fg": Color(1.0, 0.98, 0.92, 1.0)
		})
	return entries

func _status_entries(unit: UnitState) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	if unit.resonance > 0:
		entries.append({
			"icon": "共",
			"amount": str(unit.resonance),
			"tooltip": LocalizationManager.text("battle.status_resonance", [unit.resonance]),
			"bg": Color(0.18, 0.34, 0.70, 0.90),
			"border": Color(0.74, 0.88, 1.0, 0.96),
			"fg": Color(0.98, 0.99, 1.0, 1.0)
		})
	var status_ids: Array[String] = []
	for status_id in unit.statuses.keys():
		status_ids.append(String(status_id))
	status_ids.sort()
	for status_id in status_ids:
		var amount: int = int(unit.statuses.get(status_id, 0))
		if amount <= 0:
			continue
		match status_id:
			"weak":
				entries.append({
					"icon": "虚",
					"amount": str(amount),
					"tooltip": LocalizationManager.text("battle.status_weak", [amount]),
					"bg": Color(0.34, 0.18, 0.54, 0.88),
					"border": Color(0.76, 0.58, 1.0, 0.92),
					"fg": Color(0.98, 0.94, 1.0, 1.0)
				})
			"vulnerable":
				entries.append({
					"icon": "易",
					"amount": str(amount),
					"tooltip": LocalizationManager.text("battle.status_vulnerable", [amount]),
					"bg": Color(0.62, 0.18, 0.18, 0.88),
					"border": Color(1.0, 0.68, 0.68, 0.92),
					"fg": Color(1.0, 0.96, 0.96, 1.0)
				})
			"strength":
				entries.append({
					"icon": "力",
					"amount": str(amount),
					"tooltip": LocalizationManager.text("battle.status_strength", [amount, amount]),
					"bg": Color(0.68, 0.34, 0.10, 0.88),
					"border": Color(1.0, 0.82, 0.56, 0.92),
					"fg": Color(1.0, 0.98, 0.94, 1.0)
				})
	return entries

func _select_enemy_target(index: int, silent: bool = false) -> void:
	if index < 0 or index >= manager.enemies.size():
		return
	selected_target_index = index
	if not silent:
		var enemy: UnitState = manager.enemies[index]
		_append_log(LocalizationManager.text("battle.targeting", [LocalizationManager.enemy_name(enemy.id, enemy.display_name)]))
	_refresh_actor_views()
	_refresh_combat_info()
	_update_aim_hint()
	_update_enemy_intent_panel()

func _on_enemy_actor_hovered(index: int) -> void:
	if aimed_card_index == -1 or aimed_card == null:
		return
	if not _card_targets_enemy(aimed_card):
		return
	if index == selected_target_index:
		return
	_select_enemy_target(index, true)

func _on_enemy_actor_pressed(index: int) -> void:
	if aimed_card_index != -1 and aimed_card != null and _card_targets_enemy(aimed_card):
		_select_enemy_target(index, true)
		_confirm_aimed_card()
		return
	_select_enemy_target(index)

func _refresh_combat_info() -> void:
	if manager.player == null:
		return
	if aimed_card != null and _card_targets_enemy(aimed_card):
		combat_info.text = "回合 %d  选择目标：%s  当前牌：%s" % [
			manager.turn_count,
			_target_name(),
			LocalizationManager.card_name(aimed_card)
		]
		return
	combat_info.text = LocalizationManager.text("battle.combat_info", [
		manager.turn_count,
		_target_name(),
		LocalizationManager.text("battle.buff_ready") if bool(manager.player.meta.get("support_trigger_ready", false)) else LocalizationManager.text("battle.buff_idle")
	])

func _ensure_aim_hint_label() -> void:
	if aim_hint_label != null:
		return
	aim_hint_label = Label.new()
	aim_hint_label.name = "AimHintLabel"
	aim_hint_label.layout_mode = 1
	aim_hint_label.anchor_left = 0.32
	aim_hint_label.anchor_top = 0.04
	aim_hint_label.anchor_right = 0.68
	aim_hint_label.anchor_bottom = 0.12
	aim_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	aim_hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	aim_hint_label.add_theme_font_size_override("font_size", 22)
	aim_hint_label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.88, 1.0))
	aim_hint_label.add_theme_color_override("font_outline_color", Color(0.06, 0.04, 0.02, 0.94))
	aim_hint_label.add_theme_constant_override("outline_size", 4)
	aim_hint_label.visible = false
	$Arena.add_child(aim_hint_label)

func _update_aim_hint() -> void:
	if aim_hint_label == null:
		return
	if aimed_card != null and _card_targets_enemy(aimed_card):
		aim_hint_label.visible = true
		aim_hint_label.text = "选择目标：%s" % LocalizationManager.card_name(aimed_card)
		aim_hint_label.self_modulate = Color(1.0, 0.92, 0.78, 0.98)
	else:
		aim_hint_label.visible = false

func _is_targeting_enemy_now() -> bool:
	if aimed_card != null:
		return _card_targets_enemy(aimed_card)
	return _hovered_card_targets_enemy()

func _unhandled_input(event: InputEvent) -> void:
	if aimed_card_index == -1:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_clear_aim_mode()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_clear_aim_mode()
		get_viewport().set_input_as_handled()

func _style_energy_orb() -> void:
	UI_THEME_KIT.apply_energy_panel(energy_panel)
	UI_THEME_KIT.apply_numeric(energy_label, 38, Color(1.0, 0.98, 0.94, 1.0))
	energy_icon.add_theme_color_override("font_color", Color(1.0, 0.74, 0.18, 0.90))
	UI_MOTION.breathe(energy_panel, 0.90, 1.0, 1.7)

func _ensure_end_turn_warning_label() -> void:
	if end_turn_warning_label != null:
		return
	end_turn_warning_label = Label.new()
	end_turn_warning_label.name = "EndTurnWarning"
	end_turn_warning_label.layout_mode = 1
	end_turn_warning_label.anchor_left = 0.79
	end_turn_warning_label.anchor_top = 0.01
	end_turn_warning_label.anchor_right = 0.98
	end_turn_warning_label.anchor_bottom = 0.09
	end_turn_warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_turn_warning_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	end_turn_warning_label.add_theme_font_size_override("font_size", 18)
	end_turn_warning_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.88, 1.0))
	end_turn_warning_label.add_theme_color_override("font_outline_color", Color(0.18, 0.02, 0.02, 0.96))
	end_turn_warning_label.add_theme_constant_override("outline_size", 4)
	end_turn_warning_label.visible = false
	$BottomHUD.add_child(end_turn_warning_label)

func _apply_ui_theme() -> void:
	UI_THEME_KIT.apply_top_hud($TopHUD)
	UI_THEME_KIT.apply_glass_panel(hand_dock)
	UI_THEME_KIT.apply_log_panel(log_frame)
	UI_THEME_KIT.apply_glass_panel(player_frame)
	UI_THEME_KIT.apply_glass_panel(enemy_intent_frame)
	UI_THEME_KIT.apply_chip_label(health_chip, Color(1.0, 0.84, 0.84, 1.0), 20)
	UI_THEME_KIT.apply_chip_label(gold_chip, Color(1.0, 0.91, 0.66, 1.0), 20)
	UI_THEME_KIT.apply_chip_label(floor_chip, Color(0.95, 0.92, 0.78, 1.0), 20)
	UI_THEME_KIT.apply_chip_label(turn_chip, Color(0.84, 1.0, 0.86, 1.0), 20)
	UI_THEME_KIT.apply_body(combat_info, 19, Color(0.97, 0.95, 0.90, 0.98))
	UI_THEME_KIT.apply_heading(player_stats, 24, Color(1.0, 0.96, 0.90, 1.0), Color(0.06, 0.06, 0.08, 0.72))
	UI_THEME_KIT.apply_body(enemy_intent_label, 19, Color(0.96, 0.92, 0.78, 1.0))
	UI_THEME_KIT.apply_stone_button(deck_chip, "ghost", 18)
	UI_THEME_KIT.apply_stone_button(discard_chip, "ghost", 18)
	UI_THEME_KIT.apply_end_turn_button(end_turn_button)
	UI_THEME_KIT.apply_stone_button(settings_button, "ghost", 18)
	UI_MOTION.wire_button_feedback(deck_chip, 1.03, 0.97, Color(0.72, 0.90, 1.0, 0.72), 5.0)
	UI_MOTION.wire_button_feedback(discard_chip, 1.03, 0.97, Color(0.82, 0.88, 1.0, 0.72), 5.0)
	UI_MOTION.wire_button_feedback(end_turn_button, 1.03, 0.97, Color(1.0, 0.88, 0.64, 0.80), 6.0)

func _update_end_turn_warning() -> void:
	if end_turn_warning_label == null:
		return
	var countdown_count: int = _count_curse_in_hand("blast_countdown")
	var any_w_phase_two: bool = _any_enemy_w_phase_two()
	if countdown_count > 0:
		end_turn_warning_label.visible = true
		end_turn_warning_label.text = "炸药 x%d" % countdown_count
		end_turn_warning_label.self_modulate = Color(1.0, 0.62, 0.36, 1.0)
		end_turn_button.self_modulate = Color(1.0, 0.78, 0.72, 1.0)
		end_turn_button.tooltip_text = "手里还有 %d 张爆破倒计时。直接结束回合会很危险。" % countdown_count
	elif any_w_phase_two:
		end_turn_warning_label.visible = true
		end_turn_warning_label.text = "W 二阶段"
		end_turn_warning_label.self_modulate = Color(1.0, 0.76, 0.72, 0.96)
		end_turn_button.self_modulate = Color(1.0, 0.92, 0.90, 1.0)
		end_turn_button.tooltip_text = "W 已进入第二阶段，注意假动作和炸药节奏。"
	else:
		end_turn_warning_label.visible = false
		end_turn_button.self_modulate = Color(0.90, 0.94, 1.0, 1.0)
		end_turn_button.tooltip_text = ""

func _intent_visuals(source_enemy: UnitState, intent: Dictionary) -> Dictionary:
	var intent_type: String = _intent_display_type(intent)
	var label_text: String = LocalizationManager.intent_label(_intent_display_label(intent))
	match intent_type:
		"attack":
			var preview_amount: int = _intent_display_value(intent)
			var preview: Dictionary = manager.resolver.preview_damage(
				source_enemy,
				manager.player,
				preview_amount,
				null,
				true
			)
			var damage_before_block: int = int(preview.get("damage_before_block", 0))
			var absorbed: int = int(preview.get("absorbed", 0))
			var damage_after_block: int = int(preview.get("damage_after_block", 0))
			return {
				"icon": "⚔",
				"value": str(damage_before_block),
				"color": Color(0.82, 0.26, 0.22, 1.0),
				"tooltip": LocalizationManager.text("battle.intent_attack_tooltip", [
					label_text,
					damage_before_block,
					absorbed,
					damage_after_block
				])
			}
		"apply_curse", "shuffle_and_debuff":
			var curse_count: int = max(1, _intent_display_value(intent))
			var curse_value_text: String = "×%d" % curse_count if curse_count > 1 else "!"
			return {
				"icon": "✦",
				"value": curse_value_text,
				"color": Color(0.72, 0.26, 0.72, 1.0),
				"tooltip": "%s\n将施加 %d 份诅咒或牌组干扰。" % [label_text, curse_count]
			}
		"rule_shift":
			return {
				"icon": "↯",
				"value": "",
				"color": Color(0.96, 0.74, 0.30, 1.0),
				"tooltip": LocalizationManager.text("battle.intent_rule_tooltip", [label_text])
			}
		_:
			return {
				"icon": "◆",
				"value": "",
				"color": Color(0.34, 0.78, 0.96, 1.0),
				"tooltip": LocalizationManager.text("battle.intent_other_tooltip", [label_text])
			}

func _intent_display_type(intent: Dictionary) -> String:
	return String(intent.get("display_type", intent.get("type", "attack")))

func _intent_display_label(intent: Dictionary) -> String:
	return String(intent.get("display_label", intent.get("label", "Unknown")))

func _intent_display_value(intent: Dictionary) -> int:
	return int(intent.get("display_value", intent.get("value", 0)))

func _unit_display_name(unit: UnitState) -> String:
	if unit == null:
		return LocalizationManager.text("battle.target_none")
	if manager.player == unit:
		return LocalizationManager.text("map.hero_chip")
	return LocalizationManager.enemy_name(unit.id, unit.display_name)

func _count_curse_in_hand(curse_id: String) -> int:
	if manager == null or manager.deck == null:
		return 0
	var total: int = 0
	for card in manager.deck.hand:
		if card != null and card.id == curse_id:
			total += 1
	return total

func _enemy_is_bomb_threat(enemy: UnitState) -> bool:
	if enemy == null:
		return false
	return String(enemy.intent.get("type", "")) == "apply_curse" and String(enemy.intent.get("curse", "")) == "blast_countdown"

func _enemy_is_w_phase_two(index: int) -> bool:
	if index < 0 or index >= manager.enemies.size() or index >= manager.enemy_datas.size():
		return false
	var enemy: UnitState = manager.enemies[index]
	if enemy == null:
		return false
	if manager.enemy_datas[index].id != "w_boss":
		return false
	var threshold: int = int(ceil(float(enemy.max_hp) * 0.5))
	return enemy.hp <= threshold or bool(enemy.intent.get("phase_two", false))

func _any_enemy_w_phase_two() -> bool:
	for index in range(min(manager.enemies.size(), manager.enemy_datas.size())):
		if _enemy_is_w_phase_two(index):
			return true
	return false
