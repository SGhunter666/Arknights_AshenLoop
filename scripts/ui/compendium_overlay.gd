class_name CompendiumOverlay
extends Control

signal closed

const UI_MOTION = preload("res://scripts/core/ui_motion.gd")
const UI_THEME_KIT = preload("res://scripts/ui/ui_theme_kit.gd")

var overlay_title: String = ""
var entries: Array[Dictionary] = []

var title_label: Label
var close_button: Button
var list_box: VBoxContainer
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


func setup(title_text: String, overlay_entries: Array[Dictionary]) -> void:
	overlay_title = title_text
	entries.clear()
	for entry in overlay_entries:
		var cloned_entry: Dictionary = entry.duplicate(true)
		entries.append(cloned_entry)
	if is_inside_tree():
		_render()


func _build_ui() -> void:
	var shade := ColorRect.new()
	shade.layout_mode = 1
	shade.anchor_left = 0.0
	shade.anchor_top = 0.0
	shade.anchor_right = 1.0
	shade.anchor_bottom = 1.0
	shade.color = Color(0.02, 0.03, 0.05, 0.78)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)

	frame = PanelContainer.new()
	frame.layout_mode = 1
	frame.anchor_left = 0.08
	frame.anchor_top = 0.08
	frame.anchor_right = 0.92
	frame.anchor_bottom = 0.92
	frame.self_modulate = Color(1, 1, 1, 0.98)
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
	root.add_child(header)

	title_label = Label.new()
	title_label.layout_mode = 2
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UI_THEME_KIT.apply_heading(title_label, 34, Color(0.98, 0.95, 0.82, 1.0), Color(0.04, 0.04, 0.06, 0.82))
	header.add_child(title_label)

	close_button = Button.new()
	close_button.layout_mode = 2
	close_button.custom_minimum_size = Vector2(76, 52)
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

	list_box = VBoxContainer.new()
	list_box.layout_mode = 2
	list_box.add_theme_constant_override("separation", 14)
	scroll.add_child(list_box)

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
	for child in list_box.get_children():
		child.queue_free()

	if entries.is_empty():
		empty_label.visible = true
		empty_label.text = LocalizationManager.text("overlay.empty_entries")
		return

	empty_label.visible = false
	var use_grid: bool = false
	if not entries.is_empty():
		use_grid = String(entries[0].get("display_mode", "")) == "grid"
	if use_grid:
		_render_grid_entries()
	else:
		for entry in entries:
			list_box.add_child(_make_entry_panel(entry))


func _render_grid_entries() -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.layout_mode = 2
	row.add_theme_constant_override("separation", 14)
	list_box.add_child(row)
	var count_in_row: int = 0
	for entry in entries:
		if count_in_row == 5:
			row = HBoxContainer.new()
			row.layout_mode = 2
			row.add_theme_constant_override("separation", 14)
			list_box.add_child(row)
			count_in_row = 0
		row.add_child(_make_grid_entry_panel(entry))
		count_in_row += 1
	while count_in_row < 5:
		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(0, 0)
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(spacer)
		count_in_row += 1


func _make_entry_panel(entry: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 176)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.15, 0.22, 0.78)
	var accent_variant: Variant = entry.get("accent", Color(0.72, 0.86, 1.0, 0.72))
	var accent: Color = accent_variant if typeof(accent_variant) == TYPE_COLOR else Color(0.72, 0.86, 1.0, 0.72)
	style.border_color = accent
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_right = 18
	style.corner_radius_bottom_left = 18
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.24)
	style.shadow_size = 6
	panel.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.layout_mode = 2
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var row := HBoxContainer.new()
	row.layout_mode = 2
	row.add_theme_constant_override("separation", 18)
	margin.add_child(row)

	var image_path: String = String(entry.get("image_path", ""))
	if not image_path.is_empty():
		var portrait_frame := PanelContainer.new()
		portrait_frame.custom_minimum_size = Vector2(132, 132)
		portrait_frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var portrait_style := StyleBoxFlat.new()
		portrait_style.bg_color = Color(0.95, 0.97, 1.0, 0.08)
		portrait_style.border_color = accent
		portrait_style.border_width_left = 2
		portrait_style.border_width_top = 2
		portrait_style.border_width_right = 2
		portrait_style.border_width_bottom = 2
		portrait_style.corner_radius_top_left = 16
		portrait_style.corner_radius_top_right = 16
		portrait_style.corner_radius_bottom_right = 16
		portrait_style.corner_radius_bottom_left = 16
		portrait_frame.add_theme_stylebox_override("panel", portrait_style)
		row.add_child(portrait_frame)

		var portrait_margin := MarginContainer.new()
		portrait_margin.layout_mode = 2
		portrait_margin.add_theme_constant_override("margin_left", 8)
		portrait_margin.add_theme_constant_override("margin_top", 8)
		portrait_margin.add_theme_constant_override("margin_right", 8)
		portrait_margin.add_theme_constant_override("margin_bottom", 8)
		portrait_frame.add_child(portrait_margin)

		var portrait := TextureRect.new()
		portrait.layout_mode = 2
		portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.texture = load(image_path) as Texture2D
		portrait.custom_minimum_size = Vector2(116, 116)
		portrait_margin.add_child(portrait)

	var box := VBoxContainer.new()
	box.layout_mode = 2
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 8)
	row.add_child(box)

	var title := Label.new()
	title.layout_mode = 2
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.98, 0.96, 0.88, 1.0))
	title.text = String(entry.get("title", ""))
	box.add_child(title)

	var subtitle_text: String = String(entry.get("subtitle", ""))
	if not subtitle_text.is_empty():
		var subtitle := Label.new()
		subtitle.layout_mode = 2
		subtitle.add_theme_font_size_override("font_size", 18)
		subtitle.add_theme_color_override("font_color", Color(0.72, 0.88, 1.0, 0.94))
		subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		subtitle.text = subtitle_text
		box.add_child(subtitle)

	var body := Label.new()
	body.layout_mode = 2
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 18)
	body.add_theme_color_override("font_color", Color(0.90, 0.94, 0.98, 0.92))
	body.text = String(entry.get("body", ""))
	box.add_child(body)

	return panel


func _make_grid_entry_panel(entry: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(184, 300)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.15, 0.22, 0.76)
	var accent_variant: Variant = entry.get("accent", Color(0.72, 0.86, 1.0, 0.72))
	var accent: Color = accent_variant if typeof(accent_variant) == TYPE_COLOR else Color(0.72, 0.86, 1.0, 0.72)
	style.border_color = accent
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_right = 16
	style.corner_radius_bottom_left = 16
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.20)
	style.shadow_size = 5
	panel.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.layout_mode = 2
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.layout_mode = 2
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)

	var image_path: String = String(entry.get("image_path", ""))
	if not image_path.is_empty():
		var portrait_frame := PanelContainer.new()
		portrait_frame.custom_minimum_size = Vector2(0, 148)
		var portrait_style := StyleBoxFlat.new()
		portrait_style.bg_color = Color(0.95, 0.97, 1.0, 0.06)
		portrait_style.border_color = Color(accent.r, accent.g, accent.b, 0.72)
		portrait_style.border_width_left = 2
		portrait_style.border_width_top = 2
		portrait_style.border_width_right = 2
		portrait_style.border_width_bottom = 2
		portrait_style.corner_radius_top_left = 12
		portrait_style.corner_radius_top_right = 12
		portrait_style.corner_radius_bottom_right = 12
		portrait_style.corner_radius_bottom_left = 12
		portrait_frame.add_theme_stylebox_override("panel", portrait_style)
		box.add_child(portrait_frame)

		var portrait_margin := MarginContainer.new()
		portrait_margin.layout_mode = 2
		portrait_margin.add_theme_constant_override("margin_left", 6)
		portrait_margin.add_theme_constant_override("margin_top", 6)
		portrait_margin.add_theme_constant_override("margin_right", 6)
		portrait_margin.add_theme_constant_override("margin_bottom", 6)
		portrait_frame.add_child(portrait_margin)

		var portrait := TextureRect.new()
		portrait.layout_mode = 2
		portrait.custom_minimum_size = Vector2(140, 136)
		portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.texture = load(image_path) as Texture2D
		portrait_margin.add_child(portrait)

	var title := Label.new()
	title.layout_mode = 2
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.98, 0.96, 0.88, 1.0))
	title.text = String(entry.get("title", ""))
	box.add_child(title)

	var subtitle := Label.new()
	subtitle.layout_mode = 2
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.add_theme_color_override("font_color", Color(0.74, 0.88, 1.0, 0.95))
	subtitle.text = String(entry.get("subtitle", ""))
	box.add_child(subtitle)

	var body_text: String = String(entry.get("body", ""))
	if not body_text.is_empty():
		var body := Label.new()
		body.layout_mode = 2
		body.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		body.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.add_theme_font_size_override("font_size", 13)
		body.add_theme_color_override("font_color", Color(0.90, 0.94, 0.98, 0.88))
		body.custom_minimum_size = Vector2(0, 72)
		body.max_lines_visible = 4
		body.text = body_text
		box.add_child(body)
	panel.tooltip_text = "%s\n%s\n%s" % [title.text, subtitle.text, body_text]
	return panel


func _on_close_pressed() -> void:
	closed.emit()
	queue_free()

func _play_intro_animation() -> void:
	if frame == null:
		return
	UI_MOTION.reveal(frame, 0.03, Vector2(0, 18), 0.26, Vector2(0.99, 0.99))
