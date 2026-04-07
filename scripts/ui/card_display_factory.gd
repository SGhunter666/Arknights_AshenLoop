class_name CardDisplayFactory
extends Object


static func create_card_button(
	card: CardData,
	card_name: String,
	card_description: String,
	cost_value: int,
	art: Texture2D,
	size: Vector2,
	show_description: bool = true,
	is_upgraded_visual: bool = false
) -> Button:
	var button: Button = Button.new()
	button.flat = true
	button.text = ""
	button.clip_contents = true
	button.custom_minimum_size = size
	button.size = size
	button.pivot_offset = size * 0.5
	button.focus_mode = Control.FOCUS_NONE
	button.tooltip_text = "%s\n%s" % [card_name, card_description]
	_apply_card_styles(button, is_upgraded_visual)

	var art_rect: TextureRect = TextureRect.new()
	art_rect.name = "CardArt"
	art_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_rect.layout_mode = 1
	art_rect.anchor_left = 0.0
	art_rect.anchor_top = 0.0
	art_rect.anchor_right = 1.0
	art_rect.anchor_bottom = 1.0
	art_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art_rect.texture = art
	if is_upgraded_visual:
		art_rect.modulate = Color(1.06, 1.04, 0.98, 1.0)
	button.add_child(art_rect)

	var full_tint: ColorRect = ColorRect.new()
	full_tint.name = "FullTint"
	full_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	full_tint.layout_mode = 1
	full_tint.anchor_left = 0.0
	full_tint.anchor_top = 0.0
	full_tint.anchor_right = 1.0
	full_tint.anchor_bottom = 1.0
	full_tint.color = Color(0.02, 0.05, 0.11, 0.10)
	button.add_child(full_tint)

	if is_upgraded_visual:
		var upgrade_glint: ColorRect = ColorRect.new()
		upgrade_glint.name = "UpgradeGlint"
		upgrade_glint.mouse_filter = Control.MOUSE_FILTER_IGNORE
		upgrade_glint.layout_mode = 1
		upgrade_glint.anchor_left = 0.0
		upgrade_glint.anchor_top = 0.0
		upgrade_glint.anchor_right = 1.0
		upgrade_glint.anchor_bottom = 0.0
		upgrade_glint.offset_left = 18.0
		upgrade_glint.offset_top = 18.0
		upgrade_glint.offset_right = -18.0
		upgrade_glint.offset_bottom = 90.0
		upgrade_glint.color = Color(0.96, 0.92, 0.62, 0.12)
		button.add_child(upgrade_glint)

	var bottom_band: ColorRect = ColorRect.new()
	bottom_band.name = "BottomBand"
	bottom_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_band.layout_mode = 1
	bottom_band.anchor_left = 0.0
	bottom_band.anchor_top = 1.0
	bottom_band.anchor_right = 1.0
	bottom_band.anchor_bottom = 1.0
	bottom_band.offset_top = -104.0 if show_description else -72.0
	bottom_band.color = Color(0.03, 0.06, 0.10, 0.74) if not is_upgraded_visual else Color(0.08, 0.10, 0.12, 0.76)
	button.add_child(bottom_band)

	var cost_panel: Panel = Panel.new()
	cost_panel.name = "CostPanel"
	cost_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cost_panel.layout_mode = 1
	cost_panel.anchor_left = 0.0
	cost_panel.anchor_top = 0.0
	cost_panel.anchor_right = 0.0
	cost_panel.anchor_bottom = 0.0
	cost_panel.offset_left = 12.0
	cost_panel.offset_top = 12.0
	cost_panel.offset_right = 64.0
	cost_panel.offset_bottom = 64.0
	cost_panel.add_theme_stylebox_override("panel", _make_badge_style(_card_cost_color(card)))
	button.add_child(cost_panel)

	var cost_label: Label = Label.new()
	cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cost_label.layout_mode = 1
	cost_label.anchor_left = 0.0
	cost_label.anchor_top = 0.0
	cost_label.anchor_right = 1.0
	cost_label.anchor_bottom = 1.0
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cost_label.add_theme_font_size_override("font_size", 24)
	cost_label.add_theme_color_override("font_color", Color(0.97, 0.98, 1.0, 1.0))
	cost_label.text = str(cost_value)
	cost_panel.add_child(cost_label)

	var type_panel: Panel = Panel.new()
	type_panel.name = "TypePanel"
	type_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	type_panel.layout_mode = 1
	type_panel.anchor_left = 1.0
	type_panel.anchor_top = 0.0
	type_panel.anchor_right = 1.0
	type_panel.anchor_bottom = 0.0
	type_panel.offset_left = -96.0
	type_panel.offset_top = 14.0
	type_panel.offset_right = -12.0
	type_panel.offset_bottom = 46.0
	type_panel.add_theme_stylebox_override("panel", _make_type_style(card))
	button.add_child(type_panel)

	if is_upgraded_visual:
		var upgrade_badge: Panel = Panel.new()
		upgrade_badge.name = "UpgradeBadge"
		upgrade_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		upgrade_badge.layout_mode = 1
		upgrade_badge.anchor_left = 0.5
		upgrade_badge.anchor_top = 0.0
		upgrade_badge.anchor_right = 0.5
		upgrade_badge.anchor_bottom = 0.0
		upgrade_badge.offset_left = -28.0
		upgrade_badge.offset_top = 12.0
		upgrade_badge.offset_right = 28.0
		upgrade_badge.offset_bottom = 40.0
		upgrade_badge.add_theme_stylebox_override("panel", _make_upgrade_badge_style())
		button.add_child(upgrade_badge)

		var upgrade_label: Label = Label.new()
		upgrade_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		upgrade_label.layout_mode = 1
		upgrade_label.anchor_left = 0.0
		upgrade_label.anchor_top = 0.0
		upgrade_label.anchor_right = 1.0
		upgrade_label.anchor_bottom = 1.0
		upgrade_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		upgrade_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		upgrade_label.add_theme_font_size_override("font_size", 12)
		upgrade_label.add_theme_color_override("font_color", Color(0.29, 0.22, 0.08, 1.0))
		upgrade_label.text = "UP"
		upgrade_badge.add_child(upgrade_label)

	var type_label: Label = Label.new()
	type_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	type_label.layout_mode = 1
	type_label.anchor_left = 0.0
	type_label.anchor_top = 0.0
	type_label.anchor_right = 1.0
	type_label.anchor_bottom = 1.0
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	type_label.add_theme_font_size_override("font_size", 13)
	type_label.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0, 0.96))
	type_label.text = card.card_type.to_upper()
	type_panel.add_child(type_label)

	var title_label: Label = Label.new()
	title_label.name = "CardTitle"
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.layout_mode = 1
	title_label.anchor_left = 0.0
	title_label.anchor_top = 1.0
	title_label.anchor_right = 1.0
	title_label.anchor_bottom = 1.0
	title_label.offset_left = 14.0
	title_label.offset_top = -94.0 if show_description else -62.0
	title_label.offset_right = -14.0
	title_label.offset_bottom = -54.0 if show_description else -18.0
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 20 if show_description else 22)
	title_label.add_theme_color_override("font_color", Color(0.97, 0.98, 1.0, 1.0) if not is_upgraded_visual else Color(1.0, 0.95, 0.78, 1.0))
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.text = card_name
	button.add_child(title_label)

	if show_description:
		var desc_label: Label = Label.new()
		desc_label.name = "CardDescription"
		desc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		desc_label.layout_mode = 1
		desc_label.anchor_left = 0.0
		desc_label.anchor_top = 1.0
		desc_label.anchor_right = 1.0
		desc_label.anchor_bottom = 1.0
		desc_label.offset_left = 14.0
		desc_label.offset_top = -52.0
		desc_label.offset_right = -14.0
		desc_label.offset_bottom = -12.0
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_label.add_theme_font_size_override("font_size", 13)
		desc_label.add_theme_color_override("font_color", Color(0.90, 0.95, 1.0, 0.94) if not is_upgraded_visual else Color(0.98, 0.96, 0.86, 0.96))
		desc_label.text = card_description
		button.add_child(desc_label)

	return button


static func _apply_card_styles(button: Button, is_upgraded_visual: bool = false) -> void:
	if is_upgraded_visual:
		button.add_theme_stylebox_override("normal", _make_card_style(Color(0, 0, 0, 0), Color(1.0, 0.91, 0.63, 0.68), 5, 8))
		button.add_theme_stylebox_override("hover", _make_card_style(Color(0, 0, 0, 0), Color(1.0, 0.96, 0.76, 0.96), 6, 22))
		button.add_theme_stylebox_override("pressed", _make_card_style(Color(0, 0, 0, 0), Color(1.0, 0.92, 0.72, 0.94), 6, 10))
		button.add_theme_stylebox_override("focus", _make_card_style(Color(0, 0, 0, 0), Color(1.0, 0.96, 0.76, 0.96), 6, 20))
		button.add_theme_stylebox_override("disabled", _make_card_style(Color(0, 0, 0, 0), Color(0.90, 0.84, 0.70, 0.22), 4, 0))
	else:
		button.add_theme_stylebox_override("normal", _make_card_style(Color(0, 0, 0, 0), Color(0.86, 0.95, 1.0, 0.44), 4, 0))
		button.add_theme_stylebox_override("hover", _make_card_style(Color(0, 0, 0, 0), Color(0.90, 0.98, 1.0, 0.92), 5, 18))
		button.add_theme_stylebox_override("pressed", _make_card_style(Color(0, 0, 0, 0), Color(0.80, 0.93, 1.0, 0.90), 5, 8))
		button.add_theme_stylebox_override("focus", _make_card_style(Color(0, 0, 0, 0), Color(0.90, 0.98, 1.0, 0.90), 5, 16))
		button.add_theme_stylebox_override("disabled", _make_card_style(Color(0, 0, 0, 0), Color(0.76, 0.84, 0.92, 0.18), 3, 0))


static func _make_card_style(bg: Color, border: Color, border_width: int, shadow_size: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.corner_radius_top_left = 24
	style.corner_radius_top_right = 24
	style.corner_radius_bottom_right = 24
	style.corner_radius_bottom_left = 24
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.border_color = border
	style.shadow_color = Color(0.45, 0.84, 1.0, 0.36) if shadow_size > 0 else Color(0, 0, 0, 0)
	style.shadow_size = shadow_size
	style.content_margin_left = 0
	style.content_margin_top = 0
	style.content_margin_right = 0
	style.content_margin_bottom = 0
	return style


static func _make_badge_style(fill: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_right = 20
	style.corner_radius_bottom_left = 20
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.94, 0.98, 1.0, 0.72)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.24)
	style.shadow_size = 6
	return style


static func _make_type_style(card: CardData) -> StyleBoxFlat:
	var color: Color = _card_type_color(card)
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_right = 16
	style.corner_radius_bottom_left = 16
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.94, 0.98, 1.0, 0.60)
	return style


static func _make_upgrade_badge_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.94, 0.72, 0.96)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_right = 14
	style.corner_radius_bottom_left = 14
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(1.0, 0.98, 0.86, 0.95)
	style.shadow_color = Color(1.0, 0.88, 0.52, 0.35)
	style.shadow_size = 8
	return style


static func has_upgrade_visual(card: CardData) -> bool:
	return card != null and card.has_meta("upgraded_visual") and bool(card.get_meta("upgraded_visual"))


static func _card_cost_color(card: CardData) -> Color:
	if "Arts" in card.tags:
		return Color(0.15, 0.55, 0.96, 0.92)
	if "Support" in card.tags:
		return Color(0.17, 0.72, 0.80, 0.92)
	if card.card_type == "Curse":
		return Color(0.52, 0.20, 0.62, 0.92)
	return Color(0.82, 0.34, 0.18, 0.92)


static func _card_type_color(card: CardData) -> Color:
	match card.card_type:
		"Attack":
			return Color(0.73, 0.20, 0.16, 0.74)
		"Skill":
			return Color(0.12, 0.42, 0.62, 0.74)
		"Power":
			return Color(0.60, 0.34, 0.12, 0.74)
		"Curse":
			return Color(0.42, 0.16, 0.52, 0.74)
	return Color(0.18, 0.28, 0.40, 0.74)
