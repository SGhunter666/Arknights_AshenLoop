class_name CardGalleryOverlay
extends Control

signal closed

const CARD_DISPLAY_FACTORY = preload("res://scripts/ui/card_display_factory.gd")

var overlay_title: String = ""
var cards: Array[CardData] = []

var title_label: Label
var close_button: Button
var content_grid: GridContainer
var empty_label: Label


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

	var frame := PanelContainer.new()
	frame.layout_mode = 1
	frame.anchor_left = 0.08
	frame.anchor_top = 0.08
	frame.anchor_right = 0.92
	frame.anchor_bottom = 0.92
	frame.self_modulate = Color(1, 1, 1, 0.95)
	add_child(frame)

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
	title_label.add_theme_font_size_override("font_size", 32)
	title_label.add_theme_color_override("font_color", Color(0.98, 0.95, 0.82, 1.0))
	header.add_child(title_label)

	close_button = Button.new()
	close_button.layout_mode = 2
	close_button.custom_minimum_size = Vector2(64, 52)
	close_button.text = LocalizationManager.text("overlay.close")
	close_button.add_theme_font_size_override("font_size", 22)
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
	empty_label.add_theme_font_size_override("font_size", 24)
	empty_label.add_theme_color_override("font_color", Color(0.93, 0.94, 0.98, 0.84))
	root.add_child(empty_label)


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
