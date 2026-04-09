class_name CardGalleryOverlay
extends Control

signal closed

const CARD_DISPLAY_FACTORY = preload("res://scripts/ui/card_display_factory.gd")
const UI_MOTION = preload("res://scripts/core/ui_motion.gd")
const UI_THEME_KIT = preload("res://scripts/ui/ui_theme_kit.gd")

var overlay_title: String = ""
var cards: Array[CardData] = []

var title_label: Label
var close_button: Button
var content_grid: GridContainer
var empty_label: Label
var frame: PanelContainer


func _ready() -> void:
	layout_mode = 3
	anchors_preset = 15
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 500
	_build_ui()
	_render()


func setup(title_text: String, card_list: Array[CardData]) -> void:
	overlay_title = title_text
	cards.clear()
	for card in card_list:
		cards.append(card)
	if is_inside_tree():
		_render()


func _build_ui() -> void:
	var shade := ColorRect.new()
	shade.layout_mode = 1
	shade.anchor_left = 0.0
	shade.anchor_top = 0.0
	shade.anchor_right = 1.0
	shade.anchor_bottom = 1.0
	shade.color = Color(0.02, 0.03, 0.05, 0.76)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)

	frame = PanelContainer.new()
	frame.layout_mode = 1
	frame.anchor_left = 0.08
	frame.anchor_top = 0.08
	frame.anchor_right = 0.92
	frame.anchor_bottom = 0.92
	frame.self_modulate = Color(1, 1, 1, 0.95)
	add_child(frame)
	UI_THEME_KIT.apply_glass_panel(frame)

	var margin := MarginContainer.new()
	margin.layout_mode = 2
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	frame.add_child(margin)

	var root := VBoxContainer.new()
	root.layout_mode = 2
	root.add_theme_constant_override("separation", 16)
	margin.add_child(root)

	var header := HBoxContainer.new()
	header.layout_mode = 2
	header.add_theme_constant_override("separation", 12)
	root.add_child(header)

	title_label = Label.new()
	title_label.layout_mode = 2
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UI_THEME_KIT.apply_heading(title_label, 34, Color(0.98, 0.95, 0.82, 1.0), Color(0.04, 0.04, 0.06, 0.82))
	header.add_child(title_label)

	close_button = Button.new()
	close_button.layout_mode = 2
	close_button.custom_minimum_size = Vector2(64, 52)
	close_button.text = LocalizationManager.text("overlay.close")
	UI_THEME_KIT.apply_stone_button(close_button, "ghost", 22)
	UI_MOTION.wire_button_feedback(close_button, 1.02, 0.98, Color(0.88, 0.96, 1.0, 0.72), 5.0)
	close_button.pressed.connect(_on_close_pressed)
	header.add_child(close_button)

	var scroll := ScrollContainer.new()
	scroll.layout_mode = 2
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	root.add_child(scroll)

	content_grid = GridContainer.new()
	content_grid.layout_mode = 2
	content_grid.columns = 4
	content_grid.add_theme_constant_override("h_separation", 18)
	content_grid.add_theme_constant_override("v_separation", 18)
	scroll.add_child(content_grid)

	empty_label = Label.new()
	empty_label.layout_mode = 2
	empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI_THEME_KIT.apply_body(empty_label, 24, Color(0.93, 0.94, 0.98, 0.84))
	root.add_child(empty_label)
	call_deferred("_play_intro_animation")


func _render() -> void:
	if title_label == null:
		return
	title_label.text = overlay_title
	close_button.text = LocalizationManager.text("overlay.close")

	for child in content_grid.get_children():
		child.queue_free()

	if cards.is_empty():
		empty_label.visible = true
		empty_label.text = LocalizationManager.text("overlay.empty_cards")
		return

	empty_label.visible = false
	for card in cards:
		var button: Button = CARD_DISPLAY_FACTORY.create_card_button(
			card,
			LocalizationManager.card_name(card),
			LocalizationManager.card_description(card),
			card.cost,
			Util.load_card_art(card.id),
			Vector2(210, 300),
			true,
			CARD_DISPLAY_FACTORY.has_upgrade_visual(card)
		)
		button.pressed.connect(func() -> void:
			pass
		)
		content_grid.add_child(button)


func _on_close_pressed() -> void:
	closed.emit()
	queue_free()

func _play_intro_animation() -> void:
	if frame == null:
		return
	UI_MOTION.reveal(frame, 0.03, Vector2(0, 18), 0.26, Vector2(0.99, 0.99))
