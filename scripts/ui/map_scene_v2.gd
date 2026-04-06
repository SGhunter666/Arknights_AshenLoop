extends Control

const SETTINGS_TILE: Texture2D = preload("res://assets/ui_icons/settings_tile.svg")
const UI_MOTION = preload("res://scripts/core/ui_motion.gd")

@onready var hero_chip: Label = $TopHUD/HudMargin/HudRow/HeroChip
@onready var hp_chip: Label = $TopHUD/HudMargin/HudRow/HpChip
@onready var gold_chip: Label = $TopHUD/HudMargin/HudRow/GoldChip
@onready var deck_chip: Label = $TopHUD/HudMargin/HudRow/DeckChip
@onready var module_chip: Label = $TopHUD/HudMargin/HudRow/ModuleChip
@onready var floor_chip: Label = $TopHUD/HudMargin/HudRow/FloorChip
@onready var settings_button: Button = $TopHUD/HudMargin/HudRow/SettingsButton
@onready var header_label: Label = $PaperFrame/PaperMargin/PaperContent/MapColumn/Header
@onready var hint_label: Label = $PaperFrame/PaperMargin/PaperContent/MapColumn/Hint
@onready var legend_title_label: Label = $PaperFrame/PaperMargin/PaperContent/LegendPanel/LegendMargin/LegendBox/LegendTitle
@onready var legend_items_box: VBoxContainer = $PaperFrame/PaperMargin/PaperContent/LegendPanel/LegendMargin/LegendBox/LegendItems
@onready var rows_box: VBoxContainer = $PaperFrame/PaperMargin/PaperContent/MapColumn/Scroll/Rows

var node_icons: Dictionary = {}
var node_buttons: Dictionary = {}

func _ready() -> void:
	MusicManager.stop_menu_bgm()
	MusicManager.play_map_bgm()
	RunManager.clear_stale_node_selection()
	_load_node_icons()
	_embed_settings_icon()
	_attach_settings_feedback()
	LocalizationManager.language_changed.connect(_refresh)
	RunManager.map_changed.connect(_refresh)
	RunManager.run_updated.connect(_refresh)
	settings_button.pressed.connect(func() -> void:
		_press_settings()
	)
	_refresh()
	_reset_layout_visuals()

func _refresh(_unused: Variant = null) -> void:
	hero_chip.text = LocalizationManager.text("map.hero_chip")
	hp_chip.text = LocalizationManager.text("map.hud_hp", [RunManager.hp, RunManager.max_hp])
	gold_chip.text = LocalizationManager.text("map.hud_gold", [RunManager.gold])
	deck_chip.text = LocalizationManager.text("map.hud_deck", [RunManager.deck.size()])
	module_chip.text = LocalizationManager.text("map.hud_modules", [RunManager.modules.size()])
	floor_chip.text = LocalizationManager.text("map.hud_floor", [RunManager.current_floor])
	settings_button.text = LocalizationManager.text("main.settings")
	settings_button.tooltip_text = LocalizationManager.text("main.settings")
	header_label.text = LocalizationManager.text("map.header", [RunManager.current_floor, LocalizationManager.floor_name(RunManager.current_floor)])
	hint_label.text = _hint_text()
	legend_title_label.text = LocalizationManager.text("map.legend_title")
	_refresh_legend()
	node_buttons.clear()
	for child in rows_box.get_children():
		child.queue_free()
	if RunManager.has_flag("run_complete"):
		var done_label: Label = Label.new()
		done_label.text = LocalizationManager.text("map.complete")
		done_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		done_label.add_theme_font_size_override("font_size", 24)
		rows_box.add_child(done_label)
		return
	for row_nodes in RunManager.get_rows():
		_add_row(row_nodes)
	_reset_layout_visuals()

func _add_row(row_nodes: Array) -> void:
	var row_box: HBoxContainer = HBoxContainer.new()
	row_box.alignment = BoxContainer.ALIGNMENT_CENTER
	row_box.add_theme_constant_override("separation", 92)
	row_box.custom_minimum_size = Vector2(0, 78)
	rows_box.add_child(row_box)
	for node_variant in row_nodes:
		var node: MapNodeModel = node_variant
		var button: Button = Button.new()
		button.custom_minimum_size = Vector2(72, 72)
		button.text = ""
		button.tooltip_text = LocalizationManager.node_type_name(node.node_type)
		button.disabled = not RunManager.is_node_reachable(node.id)
		button.modulate = _node_color(node)
		_add_node_icon(button, node)
		node_buttons[node.id] = button
		button.pressed.connect(func(target_id: String = node.id, target_button: Button = button) -> void:
			_on_node_pressed(target_id, target_button)
		)
		row_box.add_child(button)

func _add_node_icon(button: Button, node: MapNodeModel) -> void:
	var texture: Texture2D = node_icons.get("event") as Texture2D
	if node_icons.has(node.node_type):
		texture = node_icons[node.node_type] as Texture2D
	if texture == null:
		return
	var icon_rect: TextureRect = TextureRect.new()
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_rect.layout_mode = 1
	icon_rect.anchor_left = 0.12
	icon_rect.anchor_top = 0.12
	icon_rect.anchor_right = 0.88
	icon_rect.anchor_bottom = 0.88
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.texture = texture
	icon_rect.modulate = _node_icon_modulate(node)
	button.add_child(icon_rect)

func _refresh_legend() -> void:
	for child in legend_items_box.get_children():
		child.queue_free()
	var legend_order: Array[String] = ["battle", "elite", "event", "story", "shop", "boss"]
	for node_type in legend_order:
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var icon_holder: Control = Control.new()
		icon_holder.custom_minimum_size = Vector2(36, 36)
		var icon: TextureRect = TextureRect.new()
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.layout_mode = 1
		icon.anchor_right = 1.0
		icon.anchor_bottom = 1.0
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = node_icons.get(node_type) as Texture2D
		icon.modulate = _node_icon_modulate_for_legend(node_type)
		icon_holder.add_child(icon)
		var label: Label = Label.new()
		label.text = LocalizationManager.node_type_name(node_type)
		label.add_theme_font_size_override("font_size", 22)
		label.add_theme_color_override("font_color", Color(0.22, 0.17, 0.11, 1))
		row.add_child(icon_holder)
		row.add_child(label)
		legend_items_box.add_child(row)

func _load_node_icons() -> void:
	node_icons = {
		"battle": load("res://assets/ui_icons/node_battle.svg"),
		"elite": load("res://assets/ui_icons/node_elite.svg"),
		"boss": load("res://assets/ui_icons/node_boss.svg"),
		"event": load("res://assets/ui_icons/node_event.svg"),
		"story": load("res://assets/ui_icons/node_story.svg"),
		"rest": load("res://assets/ui_icons/node_rest.svg"),
		"shop": load("res://assets/ui_icons/node_shop.svg")
	}

func _node_color(node: MapNodeModel) -> Color:
	if node.completed:
		return Color(1, 1, 1, 0.78)
	if RunManager.is_node_reachable(node.id):
		return Color(1, 1, 1, 1)
	return Color(1, 1, 1, 0.56)

func _node_icon_modulate(node: MapNodeModel) -> Color:
	if node.completed:
		return Color(0.80, 0.74, 0.70, 0.96)
	if RunManager.is_node_reachable(node.id):
		match node.node_type:
			"elite":
				return Color(1.0, 0.76, 0.76, 1.0)
			"boss":
				return Color(1.0, 0.64, 0.64, 1.0)
			"rest":
				return Color(0.96, 0.90, 0.82, 1.0)
			"shop":
				return Color(0.90, 0.98, 0.88, 1.0)
			"event", "story":
				return Color(1.0, 0.96, 0.82, 1.0)
		return Color(1.0, 1.0, 1.0, 1.0)
	return Color(0.80, 0.74, 0.70, 0.72)

func _node_icon_modulate_for_legend(node_type: String) -> Color:
	match node_type:
		"elite":
			return Color(1.0, 0.76, 0.76, 1.0)
		"boss":
			return Color(1.0, 0.64, 0.64, 1.0)
		"rest":
			return Color(0.96, 0.90, 0.82, 1.0)
		"shop":
			return Color(0.90, 0.98, 0.88, 1.0)
		"event", "story":
			return Color(1.0, 0.96, 0.82, 1.0)
	return Color(1.0, 1.0, 1.0, 1.0)

func _hint_text() -> String:
	var current: MapNodeModel = RunManager.current_node()
	if current != null:
		return LocalizationManager.text("map.current_node", [LocalizationManager.node_type_name(current.node_type)])
	if RunManager.has_flag("run_complete"):
		return LocalizationManager.text("map.complete")
	return LocalizationManager.text("map.pick_route")

func _on_node_pressed(node_id: String, button: Button) -> void:
	if not RunManager.select_node(node_id):
		return
	for button_value in node_buttons.values():
		var node_button: Button = button_value as Button
		if node_button != null:
			node_button.disabled = true
	UI_MOTION.pulse(button, 0.92, 1.05, 0.07)
	var node: MapNodeModel = RunManager.current_node()
	if node == null:
		return
	_route_for_node(node)

func _route_for_node(node: MapNodeModel) -> void:
	match node.node_type:
		"battle", "elite", "boss":
			SceneRouter.go_battle()
		"event", "story":
			SceneRouter.go_event()
		"rest":
			SceneRouter.go_rest()
		"shop":
			SceneRouter.go_shop()
		_:
			SceneRouter.go_battle()

func _embed_settings_icon() -> void:
	settings_button.text = ""
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

func _reset_layout_visuals() -> void:
	$TopHUD.position = Vector2(12.0, 10.0)
	$TopHUD.scale = Vector2.ONE
	$TopHUD.modulate.a = 1.0
	$PaperFrame.position = Vector2(78.0, 92.0)
	$PaperFrame.scale = Vector2.ONE
	$PaperFrame.modulate.a = 1.0
	for row_variant in rows_box.get_children():
		var row_control: Control = row_variant as Control
		if row_control != null:
			row_control.scale = Vector2.ONE
			row_control.modulate.a = 1.0

func _press_settings() -> void:
	await UI_MOTION.pulse(settings_button, 0.94, 1.04, 0.06).finished
	SceneRouter.go_settings(SceneRouter.MAP_SCENE)
