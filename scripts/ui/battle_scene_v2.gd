extends Control

const SETTINGS_TILE: Texture2D = preload("res://assets/ui_icons/settings_tile.svg")
const NODE_BATTLE_ICON: Texture2D = preload("res://assets/ui_icons/node_battle.svg")
const NODE_ELITE_ICON: Texture2D = preload("res://assets/ui_icons/node_elite.svg")
const NODE_BOSS_ICON: Texture2D = preload("res://assets/ui_icons/node_boss.svg")
const PLAYER_ACTOR_TEXTURE: Texture2D = preload("res://人物选择页面的角色壁纸.png")
const UI_MOTION = preload("res://scripts/core/ui_motion.gd")
const CARD_DISPLAY_FACTORY = preload("res://scripts/ui/card_display_factory.gd")
const CARD_GALLERY_OVERLAY = preload("res://scripts/ui/card_gallery_overlay.gd")
const COMBAT_ACTOR_VIEW = preload("res://scripts/ui/combat_actor_view.gd")

@onready var manager: BattleManager = $BattleManager
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
@onready var hand_scroll: Control = $BottomHUD/HandDock/HandMargin/HandScroll
@onready var hand_container: Control = $BottomHUD/HandDock/HandMargin/HandScroll/HandContainer
@onready var log_label: RichTextLabel = $BottomHUD/LogFrame/LogLabel
@onready var end_turn_button: Button = $BottomHUD/EndTurnButton

var abandon_button: Button
var abandon_dialog: ConfirmationDialog
var selected_target_index: int = 0
var player_actor_view: CombatActorView
var enemy_actor_views: Array[CombatActorView] = []
var hovered_hand_card: Button = null
var hand_card_tweens: Dictionary = {}
var hand_interaction_locked: bool = false
var enemy_portrait_cache: Dictionary = {}
var current_ui_scale: float = 1.0

func _ready() -> void:
	MusicManager.stop_menu_bgm()
	MusicManager.play_battle_bgm(_is_boss_battle_from_node())
	_embed_settings_icon()
	_attach_settings_feedback()
	_setup_abandon_controls()
	_style_energy_orb()
	_apply_battle_ui_scale()
	player_frame.visible = false
	enemy_container.visible = false
	enemy_intent_frame.visible = false
	_apply_static_text()
	LocalizationManager.language_changed.connect(_on_language_changed)
	manager.resolver.effect_resolved.connect(_on_battle_effect_resolved)
	manager.turn_started.connect(_on_turn_started)
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
	_update_abandon_text()
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
		combat_info.text = LocalizationManager.text("battle.combat_info", [
			manager.turn_count,
			_target_name(),
			LocalizationManager.text("battle.buff_ready") if bool(manager.player.meta.get("support_trigger_ready", false)) else LocalizationManager.text("battle.buff_idle")
		])
		energy_label.text = str(manager.player.energy)

func _refresh_hand() -> void:
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
			hovered_hand_card = target_button
			_refresh_actor_views()
			_layout_hand_fan(true)
		)
		button.mouse_exited.connect(func(target_button: Button = button) -> void:
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
				_enemy_actor_texture(enemy.id),
				_enemy_actor_emblem(enemy.id),
				_enemy_actor_accent(enemy.id),
				"right"
			)
			actor_view.apply_ui_scale(_actor_ui_scale())
			actor_view.set_portrait_tint(_enemy_actor_tint(enemy.id))
			actor_view.actor_pressed.connect(func(index: int = i) -> void:
				_select_enemy_target(index)
			)
			enemy_actor_views.append(actor_view)
	for i in range(min(enemy_actor_views.size(), manager.enemies.size())):
		var enemy: UnitState = manager.enemies[i]
		var actor_view: CombatActorView = enemy_actor_views[i]
		if actor_view != null:
			actor_view.update_stats(enemy.hp, enemy.max_hp, enemy.block)
			actor_view.update_statuses(_status_entries(enemy))
			actor_view.set_selected(i == selected_target_index)
			actor_view.set_preview_target(i == selected_target_index and _hovered_card_targets_enemy())
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
	if abandon_button != null:
		abandon_button.disabled = true
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

func _setup_abandon_controls() -> void:
	abandon_button = Button.new()
	abandon_button.name = "AbandonRunButton"
	abandon_button.layout_mode = 1
	abandon_button.anchor_left = 1.0
	abandon_button.anchor_right = 1.0
	abandon_button.offset_left = -226.0
	abandon_button.offset_top = 18.0
	abandon_button.offset_right = -82.0
	abandon_button.offset_bottom = 62.0
	abandon_button.focus_mode = Control.FOCUS_NONE
	abandon_button.self_modulate = Color(1.0, 0.66, 0.60, 0.94)
	abandon_button.add_theme_font_size_override("font_size", 18)
	add_child(abandon_button)
	abandon_button.pressed.connect(_open_abandon_dialog)

	abandon_dialog = ConfirmationDialog.new()
	abandon_dialog.name = "AbandonRunDialog"
	abandon_dialog.exclusive = true
	add_child(abandon_dialog)
	abandon_dialog.confirmed.connect(_confirm_abandon_run)
	_update_abandon_text()

func _update_abandon_text() -> void:
	if abandon_button != null:
		abandon_button.text = LocalizationManager.text("battle.abandon")
		abandon_button.tooltip_text = LocalizationManager.text("battle.abandon_tooltip")
	if abandon_dialog != null:
		abandon_dialog.title = LocalizationManager.text("battle.abandon_title")
		abandon_dialog.dialog_text = LocalizationManager.text("battle.abandon_body")
		abandon_dialog.ok_button_text = LocalizationManager.text("battle.abandon_confirm")
		abandon_dialog.cancel_button_text = LocalizationManager.text("battle.abandon_cancel")

func _open_abandon_dialog() -> void:
	if abandon_dialog == null or manager.battle_finished:
		return
	abandon_dialog.popup_centered()

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

func _on_battle_effect_resolved(effect_type: String, payload: Dictionary) -> void:
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
	elif target_unit != null:
		var target_enemy_actor: Control = _enemy_actor_for_unit(target_unit)
		if target_enemy_actor != null:
			target_enemy_actor.play_hit()
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

func _enemy_actor_texture(enemy_id: String) -> Texture2D:
	var direct_path: String = "res://assets/enemy_portraits/%s.png" % enemy_id
	if FileAccess.file_exists(ProjectSettings.globalize_path(direct_path)):
		return _load_enemy_portrait(direct_path)
	match enemy_id:
		"reunion_scout":
			return _load_enemy_portrait("res://assets/enemy_portraits/reunion_scout.png")
		"reunion_caster":
			return _load_enemy_portrait("res://assets/enemy_portraits/reunion_caster.png")
		"riot_shieldbearer":
			return _load_enemy_portrait("res://assets/enemy_portraits/riot_shieldbearer.png")
		"crossbow_sniper":
			return _load_enemy_portrait("res://assets/enemy_portraits/crossbow_sniper.png")
		"field_captain":
			return _load_enemy_portrait("res://assets/enemy_portraits/field_captain.png")
		"originium_channeler":
			return _load_enemy_portrait("res://assets/enemy_portraits/originium_channeler.png")
		"scout_chief":
			return _load_enemy_portrait("res://assets/enemy_portraits/scout_chief.png")
		"lockdown_core":
			return _load_enemy_portrait("res://assets/enemy_portraits/lockdown_core.png")
		"w_boss":
			return _load_enemy_portrait("res://assets/enemy_portraits/w_boss.png")
		"ash_echo":
			return _load_enemy_portrait("res://assets/enemy_portraits/ash_echo.png")
	return null

func _load_enemy_portrait(resource_path: String) -> Texture2D:
	if enemy_portrait_cache.has(resource_path):
		return enemy_portrait_cache[resource_path] as Texture2D
	var image: Image = Image.load_from_file(ProjectSettings.globalize_path(resource_path))
	if image == null or image.is_empty():
		return null
	var texture: ImageTexture = ImageTexture.create_from_image(image)
	enemy_portrait_cache[resource_path] = texture
	return texture

func _enemy_actor_emblem(enemy_id: String) -> Texture2D:
	match enemy_id:
		"field_captain", "originium_channeler":
			return NODE_ELITE_ICON
		"scout_chief", "lockdown_core", "w_boss", "ash_echo":
			return NODE_BOSS_ICON
		_:
			return NODE_BATTLE_ICON

func _enemy_actor_accent(enemy_id: String) -> Color:
	match enemy_id:
		"reunion_scout":
			return Color(0.88, 0.88, 0.92, 1.0)
		"reunion_caster":
			return Color(0.74, 0.58, 1.0, 1.0)
		"riot_shieldbearer":
			return Color(0.80, 0.86, 0.96, 1.0)
		"crossbow_sniper":
			return Color(0.92, 0.78, 0.54, 1.0)
		"field_captain":
			return Color(0.98, 0.42, 0.38, 1.0)
		"originium_channeler":
			return Color(0.82, 0.54, 1.0, 1.0)
		"scout_chief":
			return Color(0.92, 0.66, 0.46, 1.0)
		"lockdown_core":
			return Color(0.78, 0.80, 0.88, 1.0)
		"w_boss":
			return Color(1.0, 0.50, 0.66, 1.0)
		"ash_echo":
			return Color(0.82, 0.58, 1.0, 1.0)
		_:
			return Color(0.96, 0.86, 0.70, 1.0)

func _enemy_actor_tint(enemy_id: String) -> Color:
	match enemy_id:
		"reunion_scout":
			return Color(0.96, 0.98, 1.0, 1.0)
		"reunion_caster":
			return Color(0.92, 0.88, 1.0, 1.0)
		"riot_shieldbearer":
			return Color(0.90, 0.94, 1.0, 1.0)
		"crossbow_sniper":
			return Color(1.0, 0.95, 0.86, 1.0)
		"field_captain":
			return Color(1.0, 0.90, 0.92, 1.0)
		"originium_channeler":
			return Color(0.90, 0.86, 1.0, 1.0)
		"scout_chief":
			return Color(1.0, 0.94, 0.88, 1.0)
		"lockdown_core":
			return Color(0.86, 0.88, 0.96, 1.0)
		"w_boss":
			return Color(1.0, 0.90, 0.94, 1.0)
		"ash_echo":
			return Color(0.95, 0.90, 1.0, 1.0)
		_:
			return Color(1.0, 1.0, 1.0, 1.0)

func _update_enemy_intent_panel() -> void:
	enemy_intent_frame.visible = false
	if manager.enemies.is_empty():
		enemy_intent_label.text = LocalizationManager.text("battle.target_none")
		return
	selected_target_index = int(clamp(selected_target_index, 0, manager.enemies.size() - 1))
	var enemy: UnitState = manager.enemies[selected_target_index]
	var intent_text: String = LocalizationManager.intent_label(String(enemy.intent.get("label", "Unknown")))
	enemy_intent_label.text = "%s\n%d / %d    护盾 %d\n%s" % [
		LocalizationManager.enemy_name(enemy.id, enemy.display_name),
		enemy.hp,
		enemy.max_hp,
		enemy.block,
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
	for i in range(count):
		var card_button: Button = cards[i] as Button
		if card_button == null:
			continue
		var t: float = 0.5 if count <= 1 else float(i) / float(count - 1)
		var centered: float = t - 0.5
		var x: float = area_width * 0.5 + centered * spread - card_size.x * 0.5
		if hovered_index != -1 and i != hovered_index:
			var distance: int = abs(i - hovered_index)
			var push_strength: float = (22.0 + card_size.x * 0.04) / float(distance)
			x += -push_strength if i < hovered_index else push_strength
		var arc_strength: float = 1.0 - min(1.0, abs(centered) * 2.0)
		var y: float = base_y + (1.0 - arc_strength) * (24.0 + card_size.y * 0.012)
		var hovered: bool = hovered_hand_card == card_button
		var target_position: Vector2 = Vector2(x, y - (18.0 + card_size.y * 0.01 if hovered else 0.0))
		var target_rotation: float = centered * max_angle
		var target_scale: Vector2 = Vector2.ONE * (1.05 if hovered else 1.0)
		card_button.pivot_offset = card_size * 0.5
		card_button.z_index = 100 + i if hovered else i
		if animate:
			_tween_hand_card(card_button, target_position, target_rotation, target_scale)
		else:
			card_button.position = target_position
			card_button.rotation_degrees = target_rotation
			card_button.scale = target_scale

func _tween_hand_card(card_button: Button, target_position: Vector2, target_rotation: float, target_scale: Vector2) -> void:
	var instance_id: int = card_button.get_instance_id()
	var existing_tween: Tween = hand_card_tweens.get(instance_id) as Tween
	if existing_tween != null:
		existing_tween.kill()
	var tween: Tween = create_tween()
	hand_card_tweens[instance_id] = tween
	tween.set_parallel(true)
	tween.tween_property(card_button, "position", target_position, 0.14).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(card_button, "rotation_degrees", target_rotation, 0.14).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(card_button, "scale", target_scale, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

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
	var target_position: Vector2 = target_point - source_rect.size * 0.5
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(clone, "position", target_position, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(clone, "scale", Vector2(0.72, 0.72), 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(clone, "rotation_degrees", 8.0 if target_point.x > source_rect.position.x else -8.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(clone, "modulate:a", 0.0, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished
	clone.queue_free()

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

func _select_enemy_target(index: int) -> void:
	if index < 0 or index >= manager.enemies.size():
		return
	selected_target_index = index
	var enemy: UnitState = manager.enemies[index]
	_append_log(LocalizationManager.text("battle.targeting", [LocalizationManager.enemy_name(enemy.id, enemy.display_name)]))
	_refresh_state()

func _style_energy_orb() -> void:
	var orb_style := StyleBoxFlat.new()
	orb_style.bg_color = Color(0.68, 0.20, 0.10, 0.96)
	orb_style.corner_radius_top_left = 60
	orb_style.corner_radius_top_right = 60
	orb_style.corner_radius_bottom_right = 60
	orb_style.corner_radius_bottom_left = 60
	orb_style.border_width_left = 4
	orb_style.border_width_top = 4
	orb_style.border_width_right = 4
	orb_style.border_width_bottom = 4
	orb_style.border_color = Color(1.0, 0.82, 0.46, 0.96)
	orb_style.shadow_color = Color(0.0, 0.0, 0.0, 0.26)
	orb_style.shadow_size = 14
	energy_panel.add_theme_stylebox_override("panel", orb_style)
	energy_icon.add_theme_color_override("font_color", Color(1.0, 0.74, 0.18, 0.90))
	energy_label.add_theme_color_override("font_color", Color(1.0, 0.98, 0.94, 1.0))

func _intent_visuals(source_enemy: UnitState, intent: Dictionary) -> Dictionary:
	var intent_type: String = String(intent.get("type", "attack"))
	var label_text: String = LocalizationManager.intent_label(String(intent.get("label", "Unknown")))
	match intent_type:
		"attack":
			var preview: Dictionary = manager.resolver.preview_damage(
				source_enemy,
				manager.player,
				int(intent.get("value", 0)),
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
			return {
				"icon": "✦",
				"value": "",
				"color": Color(0.72, 0.26, 0.72, 1.0),
				"tooltip": LocalizationManager.text("battle.intent_curse_tooltip", [label_text])
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

func _unit_display_name(unit: UnitState) -> String:
	if unit == null:
		return LocalizationManager.text("battle.target_none")
	if manager.player == unit:
		return LocalizationManager.text("map.hero_chip")
	return LocalizationManager.enemy_name(unit.id, unit.display_name)
