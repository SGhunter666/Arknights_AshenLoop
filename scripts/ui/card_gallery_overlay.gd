class_name CardGalleryOverlay
extends Control

signal closed

const CARD_DISPLAY_FACTORY = preload("res://scripts/ui/card_display_factory.gd")
const UI_MOTION = preload("res://scripts/core/ui_motion.gd")
const UI_THEME_KIT = preload("res://scripts/ui/ui_theme_kit.gd")

var overlay_title: String = ""
var cards: Array[CardData] = []
var sections: Array[Dictionary] = []

var title_label: Label
var close_button: Button
var content_box: VBoxContainer
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
	sections.clear()
	for card in card_list:
		cards.append(card)
	if is_inside_tree():
		_render()


func setup_sections(title_text: String, grouped_sections: Array[Dictionary]) -> void:
	overlay_title = title_text
	cards.clear()
	sections.clear()
	for section in grouped_sections:
		sections.append(section.duplicate(true))
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

	content_box = VBoxContainer.new()
	content_box.layout_mode = 2
	content_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_box.add_theme_constant_override("separation", 18)
	scroll.add_child(content_box)

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

	for child in content_box.get_children():
		child.queue_free()

	if not sections.is_empty():
		var rendered_any: bool = _render_sections()
		empty_label.visible = not rendered_any
		empty_label.text = LocalizationManager.text("overlay.empty_cards")
		return

	if cards.is_empty():
		empty_label.visible = true
		empty_label.text = LocalizationManager.text("overlay.empty_cards")
		return

	empty_label.visible = false
	content_box.add_child(_make_card_section({
		"title": overlay_title,
		"cards": cards
	}))


func _on_close_pressed() -> void:
	closed.emit()
	queue_free()


func _play_intro_animation() -> void:
	if frame == null:
		return
	UI_MOTION.reveal(frame, 0.03, Vector2(0, 18), 0.26, Vector2(0.99, 0.99))


func _render_sections() -> bool:
	var rendered_any: bool = false
	for section in sections:
		var section_cards: Array[CardData] = _section_cards(section.get("cards", []))
		if section_cards.is_empty():
			continue
		content_box.add_child(_make_card_section(section))
		rendered_any = true
	return rendered_any


func _make_card_section(section: Dictionary) -> VBoxContainer:
	var section_box := VBoxContainer.new()
	section_box.layout_mode = 2
	section_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section_box.add_theme_constant_override("separation", 12)

	var title_text: String = String(section.get("title", ""))
	var subtitle_text: String = String(section.get("subtitle", ""))
	var accent_variant: Variant = section.get("accent", Color(0.84, 0.92, 1.0, 0.86))
	var accent: Color = accent_variant if typeof(accent_variant) == TYPE_COLOR else Color(0.84, 0.92, 1.0, 0.86)

	if not title_text.is_empty():
		var title := Label.new()
		title.layout_mode = 2
		UI_THEME_KIT.apply_heading(title, 28, accent, Color(0.04, 0.04, 0.06, 0.82))
		title.text = title_text
		section_box.add_child(title)

	if not subtitle_text.is_empty():
		var subtitle := Label.new()
		subtitle.layout_mode = 2
		UI_THEME_KIT.apply_body(subtitle, 18, Color(0.92, 0.95, 0.98, 0.90))
		subtitle.text = subtitle_text
		section_box.add_child(subtitle)

	section_box.add_child(_make_cards_grid(_section_cards(section.get("cards", []))))
	return section_box


func _make_cards_grid(card_list: Array[CardData]) -> VBoxContainer:
	var list := VBoxContainer.new()
	list.layout_mode = 2
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 14)
	for card in card_list:
		var button: Button = CARD_DISPLAY_FACTORY.create_codex_card_button(
			card,
			LocalizationManager.card_name(card),
			LocalizationManager.card_description(card),
			card.cost,
			Util.load_card_art(card.id),
			Vector2(0, 266),
			CARD_DISPLAY_FACTORY.has_upgrade_visual(card)
		)
		list.add_child(button)
	return list


func _section_cards(raw_cards: Variant) -> Array[CardData]:
	var result: Array[CardData] = []
	if typeof(raw_cards) != TYPE_ARRAY:
		return result
	for card_variant in raw_cards:
		var card: CardData = card_variant as CardData
		if card != null:
			result.append(card)
	return result
