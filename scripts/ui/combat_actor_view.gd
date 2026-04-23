class_name CombatActorView
extends Control

signal actor_pressed

var accent_color: Color = Color(0.72, 0.88, 1.0, 1.0)
var portrait_tint: Color = Color(1.0, 1.0, 1.0, 1.0)
var side: String = "left"
var is_selected: bool = false
var is_preview_target: bool = false
var is_action_focus: bool = false
var warning_active: bool = false
var warning_color: Color = Color(1.0, 0.36, 0.30, 1.0)

var glow: ColorRect
var idle_root: Control
var action_root: Control
var shadow: ColorRect
var portrait_frame: Panel
var portrait_rect: TextureRect
var emblem_rect: TextureRect
var name_chip: Label
var hp_chip: Label
var block_chip: Label
var hp_bar_back: ColorRect
var hp_bar_fill: ColorRect
var block_bar_back: ColorRect
var block_bar_fill: ColorRect
var intent_bubble: Panel
var intent_icon_plate: PanelContainer
var intent_icon_rect: TextureRect
var intent_icon_label: Label
var intent_value_label: Label
var status_strip: HBoxContainer
var state_badge: Panel
var state_badge_icon_plate: PanelContainer
var state_badge_icon_rect: TextureRect
var state_badge_label: Label

var idle_tween: Tween
var action_tween: Tween
var ui_scale_factor: float = 1.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_build_ui()

func _exit_tree() -> void:
	_kill_actor_tween(idle_tween)
	idle_tween = null
	_kill_actor_tween(action_tween)
	action_tween = null

func setup_actor(display_name: String, portrait: Texture2D, emblem: Texture2D, accent: Color, facing: String = "left") -> void:
	accent_color = accent
	side = facing
	name_chip.text = display_name
	portrait_rect.texture = portrait
	portrait_rect.visible = portrait != null
	portrait_rect.flip_h = side == "right"
	portrait_rect.modulate = portrait_tint
	emblem_rect.texture = emblem
	emblem_rect.visible = emblem != null and portrait == null
	emblem_rect.modulate = portrait_tint
	_apply_visual_state()
	_start_idle()
	set_intent("", "", Color.WHITE)

func set_portrait_tint(tint: Color) -> void:
	portrait_tint = tint
	if portrait_rect != null:
		portrait_rect.modulate = portrait_tint
	if emblem_rect != null:
		emblem_rect.modulate = portrait_tint

func update_stats(current_hp: int, max_hp: int, block_value: int = 0) -> void:
	hp_chip.text = "%d / %d" % [current_hp, max_hp]
	var ratio: float = 0.0 if max_hp <= 0 else clamp(float(current_hp) / float(max_hp), 0.0, 1.0)
	hp_bar_fill.scale.x = ratio
	var block_ratio: float = 0.0 if max_hp <= 0 else clamp(float(block_value) / float(max_hp), 0.0, 1.0)
	block_bar_back.visible = block_value > 0
	block_bar_fill.scale.x = block_ratio
	block_chip.text = str(block_value)

func apply_ui_scale(scale_value: float) -> void:
	ui_scale_factor = clamp(scale_value, 0.64, 1.8)
	var intent_scale: float = lerpf(1.0, ui_scale_factor, 0.56)
	if intent_icon_label != null:
		intent_icon_label.add_theme_font_size_override("font_size", int(round(21 * intent_scale)))
	if intent_icon_plate != null:
		intent_icon_plate.custom_minimum_size = Vector2(36, 36) * intent_scale
	if intent_value_label != null:
		intent_value_label.add_theme_font_size_override("font_size", int(round(21 * intent_scale)))
	if name_chip != null:
		name_chip.add_theme_font_size_override("font_size", int(round(20 * ui_scale_factor)))
	if hp_chip != null:
		hp_chip.add_theme_font_size_override("font_size", int(round(16 * ui_scale_factor)))
	if block_chip != null:
		block_chip.add_theme_font_size_override("font_size", int(round(15 * ui_scale_factor)))
	if state_badge_label != null:
		state_badge_label.add_theme_font_size_override("font_size", int(round(14 * ui_scale_factor)))
	if state_badge_icon_plate != null:
		state_badge_icon_plate.custom_minimum_size = Vector2(24, 24) * ui_scale_factor
	if status_strip != null:
		status_strip.add_theme_constant_override("separation", int(round(6 * ui_scale_factor)))
	for chip in status_strip.get_children():
		if chip is PanelContainer:
			(chip as PanelContainer).custom_minimum_size = Vector2(36, 36) * ui_scale_factor

func update_statuses(status_entries: Array[Dictionary]) -> void:
	if status_strip == null:
		return
	for child in status_strip.get_children():
		child.queue_free()
	for entry in status_entries:
		var chip: PanelContainer = PanelContainer.new()
		chip.custom_minimum_size = Vector2(36, 36) * ui_scale_factor
		chip.mouse_filter = Control.MOUSE_FILTER_PASS
		chip.tooltip_text = String(entry.get("tooltip", ""))
		var style := StyleBoxFlat.new()
		style.bg_color = entry.get("bg", Color(0.10, 0.12, 0.18, 0.86))
		style.corner_radius_top_left = 16
		style.corner_radius_top_right = 16
		style.corner_radius_bottom_right = 16
		style.corner_radius_bottom_left = 16
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.border_color = entry.get("border", Color(0.96, 0.98, 1.0, 0.55))
		style.shadow_color = Color(0.0, 0.0, 0.0, 0.24)
		style.shadow_size = 8
		chip.add_theme_stylebox_override("panel", style)
		status_strip.add_child(chip)

		var icon_rect: TextureRect = TextureRect.new()
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_rect.layout_mode = 1
		icon_rect.anchor_left = 0.18
		icon_rect.anchor_top = 0.18
		icon_rect.anchor_right = 0.82
		icon_rect.anchor_bottom = 0.82
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var icon_texture: Texture2D = entry.get("icon_texture", null) as Texture2D
		icon_rect.texture = icon_texture
		icon_rect.modulate = entry.get("fg", Color(0.98, 0.98, 1.0, 1.0))
		icon_rect.visible = icon_texture != null
		chip.add_child(icon_rect)

		var icon_label: Label = Label.new()
		icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_label.layout_mode = 1
		icon_label.anchor_left = 0.0
		icon_label.anchor_top = 0.0
		icon_label.anchor_right = 1.0
		icon_label.anchor_bottom = 1.0
		icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon_label.add_theme_font_size_override("font_size", int(round(16 * ui_scale_factor)))
		icon_label.add_theme_color_override("font_color", entry.get("fg", Color(0.98, 0.98, 1.0, 1.0)))
		icon_label.add_theme_color_override("font_outline_color", Color(0.04, 0.06, 0.10, 0.86))
		icon_label.add_theme_constant_override("outline_size", 1)
		icon_label.text = String(entry.get("icon", ""))
		icon_label.visible = icon_texture == null
		chip.add_child(icon_label)

		var amount_text: String = String(entry.get("amount", ""))
		if not amount_text.is_empty():
			var amount_badge: Panel = Panel.new()
			amount_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
			amount_badge.layout_mode = 1
			amount_badge.anchor_left = 0.54
			amount_badge.anchor_top = 0.54
			amount_badge.anchor_right = 1.02
			amount_badge.anchor_bottom = 1.02
			var amount_style := StyleBoxFlat.new()
			amount_style.bg_color = Color(0.96, 0.98, 1.0, 0.94)
			amount_style.corner_radius_top_left = 16
			amount_style.corner_radius_top_right = 16
			amount_style.corner_radius_bottom_right = 16
			amount_style.corner_radius_bottom_left = 16
			amount_style.border_width_left = 1
			amount_style.border_width_top = 1
			amount_style.border_width_right = 1
			amount_style.border_width_bottom = 1
			amount_style.border_color = Color(0.10, 0.14, 0.18, 0.72)
			amount_style.shadow_color = Color(0.0, 0.0, 0.0, 0.18)
			amount_style.shadow_size = 6
			amount_badge.add_theme_stylebox_override("panel", amount_style)
			chip.add_child(amount_badge)

			var amount_label: Label = Label.new()
			amount_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			amount_label.layout_mode = 1
			amount_label.anchor_left = 0.0
			amount_label.anchor_top = 0.0
			amount_label.anchor_right = 1.0
			amount_label.anchor_bottom = 1.0
			amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			amount_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			amount_label.add_theme_font_size_override("font_size", int(round(11 * ui_scale_factor)))
			amount_label.add_theme_color_override("font_color", Color(0.12, 0.14, 0.18, 1.0))
			amount_label.add_theme_color_override("font_outline_color", Color(1.0, 1.0, 1.0, 0.62))
			amount_label.add_theme_constant_override("outline_size", 1)
			amount_label.text = amount_text
			amount_badge.add_child(amount_label)

func set_selected(active: bool) -> void:
	is_selected = active
	_apply_visual_state()

func set_preview_target(active: bool) -> void:
	is_preview_target = active
	_apply_visual_state()

func set_action_focus(active: bool) -> void:
	is_action_focus = active
	_apply_visual_state()

func set_intent(icon_text: String, value_text: String, tint: Color = Color.WHITE, tooltip_text: String = "", icon_texture: Texture2D = null) -> void:
	if intent_bubble == null:
		return
	intent_bubble.visible = not icon_text.is_empty() or not value_text.is_empty()
	intent_bubble.tooltip_text = tooltip_text
	var accent_color: Color = tint.lightened(0.24)
	var icon_color: Color = Color(
		lerpf(accent_color.r, 1.0, 0.26),
		lerpf(accent_color.g, 1.0, 0.26),
		lerpf(accent_color.b, 1.0, 0.26),
		1.0
	)
	var value_color: Color = Color(
		lerpf(accent_color.r, 1.0, 0.76),
		lerpf(accent_color.g, 1.0, 0.76),
		lerpf(accent_color.b, 1.0, 0.76),
		1.0
	)
	var outline_color: Color = Color(0.01, 0.02, 0.05, 0.96)
	var bubble_style := StyleBoxFlat.new()
	bubble_style.bg_color = Color(0.06, 0.08, 0.14, 0.97)
	bubble_style.corner_radius_top_left = 22
	bubble_style.corner_radius_top_right = 22
	bubble_style.corner_radius_bottom_right = 22
	bubble_style.corner_radius_bottom_left = 22
	bubble_style.border_width_left = 2
	bubble_style.border_width_top = 2
	bubble_style.border_width_right = 2
	bubble_style.border_width_bottom = 2
	bubble_style.border_color = Color(accent_color.r, accent_color.g, accent_color.b, 0.82)
	bubble_style.shadow_color = Color(accent_color.r, accent_color.g, accent_color.b, 0.34)
	bubble_style.shadow_size = 16
	intent_bubble.add_theme_stylebox_override("panel", bubble_style)
	if intent_icon_rect != null:
		intent_icon_rect.texture = icon_texture
		intent_icon_rect.modulate = icon_color
		intent_icon_rect.visible = icon_texture != null
	intent_icon_label.text = icon_text
	intent_icon_label.modulate = Color.WHITE
	intent_icon_label.add_theme_color_override("font_color", icon_color)
	intent_icon_label.add_theme_color_override("font_outline_color", outline_color)
	intent_icon_label.add_theme_constant_override("outline_size", 3)
	intent_icon_label.visible = icon_texture == null
	intent_value_label.text = value_text
	intent_value_label.modulate = Color.WHITE
	intent_value_label.add_theme_color_override("font_color", value_color)
	intent_value_label.add_theme_color_override("font_outline_color", outline_color)
	intent_value_label.add_theme_constant_override("outline_size", 5)
	if intent_icon_plate != null:
		var plate_style := StyleBoxFlat.new()
		plate_style.bg_color = Color(accent_color.r, accent_color.g, accent_color.b, 0.22)
		plate_style.corner_radius_top_left = 999
		plate_style.corner_radius_top_right = 999
		plate_style.corner_radius_bottom_right = 999
		plate_style.corner_radius_bottom_left = 999
		plate_style.border_width_left = 2
		plate_style.border_width_top = 2
		plate_style.border_width_right = 2
		plate_style.border_width_bottom = 2
		plate_style.border_color = Color(icon_color.r, icon_color.g, icon_color.b, 0.92)
		plate_style.shadow_color = Color(accent_color.r, accent_color.g, accent_color.b, 0.18)
		plate_style.shadow_size = 6
		intent_icon_plate.add_theme_stylebox_override("panel", plate_style)

func set_state_badge(text_value: String, tint: Color = Color(1.0, 0.28, 0.24, 1.0), tooltip_text: String = "", icon_texture: Texture2D = null) -> void:
	if state_badge == null or state_badge_label == null:
		return
	state_badge.visible = not text_value.is_empty() or icon_texture != null
	state_badge.tooltip_text = tooltip_text
	state_badge_label.text = text_value
	var style := StyleBoxFlat.new()
	style.bg_color = Color(tint.r, tint.g, tint.b, 0.24)
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_right = 18
	style.corner_radius_bottom_left = 18
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(tint.r, tint.g, tint.b, 0.82)
	style.shadow_color = Color(tint.r, tint.g, tint.b, 0.32)
	style.shadow_size = 10
	state_badge.add_theme_stylebox_override("panel", style)
	state_badge_label.add_theme_color_override("font_color", Color(1.0, 0.98, 0.95, 1.0))
	state_badge_label.visible = not text_value.is_empty()
	if state_badge_icon_plate != null:
		state_badge_icon_plate.visible = icon_texture != null
		var icon_plate_style := StyleBoxFlat.new()
		icon_plate_style.bg_color = Color(tint.r, tint.g, tint.b, 0.18)
		icon_plate_style.corner_radius_top_left = 999
		icon_plate_style.corner_radius_top_right = 999
		icon_plate_style.corner_radius_bottom_right = 999
		icon_plate_style.corner_radius_bottom_left = 999
		icon_plate_style.border_width_left = 2
		icon_plate_style.border_width_top = 2
		icon_plate_style.border_width_right = 2
		icon_plate_style.border_width_bottom = 2
		icon_plate_style.border_color = Color(tint.r, tint.g, tint.b, 0.78)
		icon_plate_style.shadow_color = Color(tint.r, tint.g, tint.b, 0.18)
		icon_plate_style.shadow_size = 8
		state_badge_icon_plate.add_theme_stylebox_override("panel", icon_plate_style)
	if state_badge_icon_rect != null:
		state_badge_icon_rect.texture = icon_texture
		state_badge_icon_rect.modulate = Color(1.0, 0.98, 0.94, 1.0)
		state_badge_icon_rect.visible = icon_texture != null

func set_warning_state(active: bool, tint: Color = Color(1.0, 0.36, 0.30, 1.0)) -> void:
	warning_active = active
	warning_color = tint
	_apply_visual_state()

func play_attack() -> void:
	_flash(accent_color.lightened(0.22), 0.28)
	_kick(24 if side == "left" else -24, 0.92, 1.04)

func play_arts() -> void:
	_flash(Color(0.48, 0.90, 1.0, 0.95), 0.34)
	_kick(18 if side == "left" else -18, 0.94, 1.05)

func play_support() -> void:
	_flash(Color(1.0, 0.86, 0.58, 1.0), 0.42)
	_kick(8 if side == "left" else -8, 0.98, 1.06)
	_pulse(1.10)

func play_skill() -> void:
	_flash(Color(0.78, 0.92, 1.0, 0.88), 0.24)
	_pulse(1.03)

func play_resonance_gain() -> void:
	_flash(Color(0.58, 0.88, 1.0, 0.98), 0.32)
	_pulse(1.06)

func play_resonance_burst() -> void:
	_flash(Color(0.34, 0.82, 1.0, 1.0), 0.46)
	_kick(14 if side == "left" else -14, 0.96, 1.08)

func play_block_absorb() -> void:
	_flash(Color(0.96, 0.99, 1.0, 0.92), 0.28)
	_pulse(1.03)

func play_block_break() -> void:
	_flash(Color(1.0, 0.90, 0.72, 1.0), 0.40)
	_kick(-14 if side == "left" else 14, 0.96, 1.07)

func play_hit() -> void:
	_flash(Color(1.0, 0.42, 0.42, 0.96), 0.28)
	_kick(-14 if side == "left" else 14, 0.96, 1.03)

func play_defeat() -> void:
	if action_tween != null:
		action_tween.kill()
	action_tween = _make_actor_tween()
	action_tween.tween_property(self, "modulate:a", 0.36, 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	action_tween.parallel().tween_property(action_root, "scale", Vector2(0.94, 0.94), 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	action_tween.parallel().tween_property(glow, "modulate:a", 0.0, 0.20).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _build_ui() -> void:
	if glow != null:
		return
	glow = ColorRect.new()
	glow.name = "Glow"
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.layout_mode = 1
	glow.anchor_left = 0.08
	glow.anchor_top = 0.08
	glow.anchor_right = 0.92
	glow.anchor_bottom = 0.84
	glow.color = Color(0.62, 0.84, 1.0, 0.18)
	add_child(glow)

	idle_root = Control.new()
	idle_root.name = "IdleRoot"
	idle_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	idle_root.layout_mode = 1
	idle_root.anchor_right = 1.0
	idle_root.anchor_bottom = 1.0
	add_child(idle_root)

	action_root = Control.new()
	action_root.name = "ActionRoot"
	action_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	action_root.layout_mode = 1
	action_root.anchor_right = 1.0
	action_root.anchor_bottom = 1.0
	idle_root.add_child(action_root)

	shadow = ColorRect.new()
	shadow.name = "Shadow"
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shadow.layout_mode = 1
	shadow.anchor_left = 0.16
	shadow.anchor_top = 0.78
	shadow.anchor_right = 0.84
	shadow.anchor_bottom = 0.88
	shadow.color = Color(0.0, 0.0, 0.0, 0.18)
	action_root.add_child(shadow)

	portrait_frame = Panel.new()
	portrait_frame.name = "PortraitFrame"
	portrait_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_frame.layout_mode = 1
	portrait_frame.anchor_left = 0.08
	portrait_frame.anchor_top = 0.02
	portrait_frame.anchor_right = 0.92
	portrait_frame.anchor_bottom = 0.80
	portrait_frame.clip_contents = true
	action_root.add_child(portrait_frame)

	var portrait_style: StyleBoxFlat = StyleBoxFlat.new()
	portrait_style.bg_color = Color(0.04, 0.05, 0.08, 0.18)
	portrait_style.corner_radius_top_left = 10
	portrait_style.corner_radius_top_right = 10
	portrait_style.corner_radius_bottom_right = 10
	portrait_style.corner_radius_bottom_left = 10
	portrait_style.border_width_left = 1
	portrait_style.border_width_top = 1
	portrait_style.border_width_right = 1
	portrait_style.border_width_bottom = 1
	portrait_style.border_color = Color(0.92, 0.96, 1.0, 0.14)
	portrait_style.shadow_color = Color(0.0, 0.0, 0.0, 0.20)
	portrait_style.shadow_size = 12
	portrait_frame.add_theme_stylebox_override("panel", portrait_style)

	portrait_rect = TextureRect.new()
	portrait_rect.name = "Portrait"
	portrait_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_rect.layout_mode = 1
	portrait_rect.anchor_left = 0.0
	portrait_rect.anchor_top = 0.0
	portrait_rect.anchor_right = 1.0
	portrait_rect.anchor_bottom = 1.0
	portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait_frame.add_child(portrait_rect)

	emblem_rect = TextureRect.new()
	emblem_rect.name = "Emblem"
	emblem_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	emblem_rect.layout_mode = 1
	emblem_rect.anchor_left = 0.26
	emblem_rect.anchor_top = 0.18
	emblem_rect.anchor_right = 0.74
	emblem_rect.anchor_bottom = 0.66
	emblem_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	emblem_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_frame.add_child(emblem_rect)

	state_badge = Panel.new()
	state_badge.name = "StateBadge"
	state_badge.layout_mode = 1
	state_badge.anchor_left = 0.06
	state_badge.anchor_top = -0.02
	state_badge.anchor_right = 0.42
	state_badge.anchor_bottom = 0.10
	state_badge.mouse_filter = Control.MOUSE_FILTER_PASS
	state_badge.visible = false
	action_root.add_child(state_badge)

	var state_badge_margin := MarginContainer.new()
	state_badge_margin.layout_mode = 1
	state_badge_margin.anchor_left = 0.0
	state_badge_margin.anchor_top = 0.0
	state_badge_margin.anchor_right = 1.0
	state_badge_margin.anchor_bottom = 1.0
	state_badge_margin.add_theme_constant_override("margin_left", 8)
	state_badge_margin.add_theme_constant_override("margin_top", 2)
	state_badge_margin.add_theme_constant_override("margin_right", 8)
	state_badge_margin.add_theme_constant_override("margin_bottom", 2)
	state_badge.add_child(state_badge_margin)

	var state_badge_row := HBoxContainer.new()
	state_badge_row.layout_mode = 2
	state_badge_row.alignment = BoxContainer.ALIGNMENT_CENTER
	state_badge_row.add_theme_constant_override("separation", 6)
	state_badge_margin.add_child(state_badge_row)

	state_badge_icon_plate = PanelContainer.new()
	state_badge_icon_plate.name = "StateBadgeIconPlate"
	state_badge_icon_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	state_badge_icon_plate.custom_minimum_size = Vector2(24, 24)
	state_badge_icon_plate.visible = false
	state_badge_row.add_child(state_badge_icon_plate)

	var state_badge_icon_center := CenterContainer.new()
	state_badge_icon_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	state_badge_icon_plate.add_child(state_badge_icon_center)

	state_badge_icon_rect = TextureRect.new()
	state_badge_icon_rect.name = "StateBadgeIcon"
	state_badge_icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	state_badge_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	state_badge_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	state_badge_icon_rect.custom_minimum_size = Vector2(14, 14)
	state_badge_icon_rect.visible = false
	state_badge_icon_center.add_child(state_badge_icon_rect)

	state_badge_label = Label.new()
	state_badge_label.name = "StateBadgeLabel"
	state_badge_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	state_badge_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	state_badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	state_badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	state_badge_label.add_theme_font_size_override("font_size", 14)
	state_badge_row.add_child(state_badge_label)

	intent_bubble = Panel.new()
	intent_bubble.name = "IntentBubble"
	intent_bubble.layout_mode = 1
	intent_bubble.anchor_left = 0.68
	intent_bubble.anchor_top = 0.012
	intent_bubble.anchor_right = 0.94
	intent_bubble.anchor_bottom = 0.125
	intent_bubble.mouse_filter = Control.MOUSE_FILTER_PASS
	action_root.add_child(intent_bubble)
	intent_bubble.visible = false

	var bubble_style: StyleBoxFlat = StyleBoxFlat.new()
	bubble_style.bg_color = Color(0.96, 0.94, 0.88, 0.96)
	bubble_style.corner_radius_top_left = 22
	bubble_style.corner_radius_top_right = 22
	bubble_style.corner_radius_bottom_right = 22
	bubble_style.corner_radius_bottom_left = 22
	bubble_style.border_width_left = 2
	bubble_style.border_width_top = 2
	bubble_style.border_width_right = 2
	bubble_style.border_width_bottom = 2
	bubble_style.border_color = Color(0.42, 0.34, 0.22, 0.36)
	bubble_style.shadow_color = Color(0.0, 0.0, 0.0, 0.24)
	bubble_style.shadow_size = 8
	intent_bubble.add_theme_stylebox_override("panel", bubble_style)

	intent_icon_plate = PanelContainer.new()
	intent_icon_plate.name = "IntentIconPlate"
	intent_icon_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intent_icon_plate.layout_mode = 1
	intent_icon_plate.anchor_left = 0.07
	intent_icon_plate.anchor_top = 0.16
	intent_icon_plate.anchor_right = 0.38
	intent_icon_plate.anchor_bottom = 0.84
	intent_icon_plate.custom_minimum_size = Vector2(36, 36)
	intent_bubble.add_child(intent_icon_plate)

	var intent_plate_center := CenterContainer.new()
	intent_plate_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	intent_icon_plate.add_child(intent_plate_center)

	intent_icon_rect = TextureRect.new()
	intent_icon_rect.name = "IntentIconTexture"
	intent_icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intent_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	intent_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	intent_icon_rect.custom_minimum_size = Vector2(24, 24)
	intent_plate_center.add_child(intent_icon_rect)

	intent_icon_label = Label.new()
	intent_icon_label.name = "IntentIcon"
	intent_icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intent_icon_label.layout_mode = 1
	intent_icon_label.anchor_left = 0.07
	intent_icon_label.anchor_top = 0.12
	intent_icon_label.anchor_right = 0.38
	intent_icon_label.anchor_bottom = 0.88
	intent_icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intent_icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	intent_icon_label.add_theme_font_size_override("font_size", 21)
	intent_icon_label.add_theme_color_override("font_color", Color(0.30, 0.24, 0.20, 1.0))
	intent_bubble.add_child(intent_icon_label)

	intent_value_label = Label.new()
	intent_value_label.name = "IntentValue"
	intent_value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intent_value_label.layout_mode = 1
	intent_value_label.anchor_left = 0.40
	intent_value_label.anchor_top = 0.16
	intent_value_label.anchor_right = 0.92
	intent_value_label.anchor_bottom = 0.84
	intent_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intent_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	intent_value_label.add_theme_font_size_override("font_size", 17)
	intent_value_label.add_theme_color_override("font_color", Color(0.30, 0.24, 0.20, 1.0))
	intent_bubble.add_child(intent_value_label)

	name_chip = Label.new()
	name_chip.name = "NameChip"
	name_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_chip.layout_mode = 1
	name_chip.anchor_left = 0.08
	name_chip.anchor_top = 0.80
	name_chip.anchor_right = 0.92
	name_chip.anchor_bottom = 0.88
	name_chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_chip.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_chip.add_theme_font_size_override("font_size", 18)
	name_chip.add_theme_color_override("font_color", Color(0.98, 0.97, 0.94, 1.0))
	action_root.add_child(name_chip)

	hp_bar_back = ColorRect.new()
	hp_bar_back.name = "HPBarBack"
	hp_bar_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_bar_back.layout_mode = 1
	hp_bar_back.anchor_left = 0.10
	hp_bar_back.anchor_top = 0.866
	hp_bar_back.anchor_right = 0.90
	hp_bar_back.anchor_bottom = 0.912
	hp_bar_back.color = Color(0.42, 0.12, 0.14, 0.58)
	action_root.add_child(hp_bar_back)

	hp_bar_fill = ColorRect.new()
	hp_bar_fill.name = "HPBarFill"
	hp_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_bar_fill.layout_mode = 1
	hp_bar_fill.anchor_left = 0.0
	hp_bar_fill.anchor_top = 0.0
	hp_bar_fill.anchor_right = 1.0
	hp_bar_fill.anchor_bottom = 1.0
	hp_bar_fill.grow_horizontal = Control.GROW_DIRECTION_END
	hp_bar_fill.color = Color(0.96, 0.28, 0.30, 0.98)
	hp_bar_back.add_child(hp_bar_fill)

	block_bar_back = ColorRect.new()
	block_bar_back.name = "BlockBarBack"
	block_bar_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	block_bar_back.layout_mode = 1
	block_bar_back.anchor_left = 0.10
	block_bar_back.anchor_top = 0.920
	block_bar_back.anchor_right = 0.90
	block_bar_back.anchor_bottom = 0.966
	block_bar_back.color = Color(0.78, 0.80, 0.84, 0.58)
	block_bar_back.visible = false
	action_root.add_child(block_bar_back)

	block_bar_fill = ColorRect.new()
	block_bar_fill.name = "BlockBarFill"
	block_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	block_bar_fill.layout_mode = 1
	block_bar_fill.anchor_left = 0.0
	block_bar_fill.anchor_top = 0.0
	block_bar_fill.anchor_right = 1.0
	block_bar_fill.anchor_bottom = 1.0
	block_bar_fill.grow_horizontal = Control.GROW_DIRECTION_END
	block_bar_fill.color = Color(0.98, 0.99, 1.0, 1.0)
	block_bar_back.add_child(block_bar_fill)

	hp_chip = Label.new()
	hp_chip.name = "HPChip"
	hp_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_chip.layout_mode = 1
	hp_chip.anchor_left = 0.0
	hp_chip.anchor_top = 0.0
	hp_chip.anchor_right = 1.0
	hp_chip.anchor_bottom = 1.0
	hp_chip.offset_top = -2
	hp_chip.offset_bottom = -2
	hp_chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_chip.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hp_chip.add_theme_font_size_override("font_size", 17)
	hp_chip.add_theme_color_override("font_color", Color(1.0, 0.96, 0.96, 0.98))
	hp_chip.add_theme_color_override("font_outline_color", Color(0.08, 0.02, 0.03, 0.96))
	hp_chip.add_theme_constant_override("outline_size", 4)
	hp_chip.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.55))
	hp_chip.add_theme_constant_override("shadow_offset_x", 1)
	hp_chip.add_theme_constant_override("shadow_offset_y", 1)
	hp_chip.add_theme_constant_override("shadow_outline_size", 1)
	hp_bar_back.add_child(hp_chip)

	block_chip = Label.new()
	block_chip.name = "BlockChip"
	block_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	block_chip.layout_mode = 1
	block_chip.anchor_left = 0.0
	block_chip.anchor_top = 0.0
	block_chip.anchor_right = 1.0
	block_chip.anchor_bottom = 1.0
	block_chip.offset_top = -2
	block_chip.offset_bottom = -2
	block_chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	block_chip.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	block_chip.add_theme_font_size_override("font_size", 16)
	block_chip.add_theme_color_override("font_color", Color(0.10, 0.14, 0.20, 1.0))
	block_chip.add_theme_color_override("font_outline_color", Color(0.96, 0.99, 1.0, 0.98))
	block_chip.add_theme_constant_override("outline_size", 4)
	block_chip.add_theme_color_override("font_shadow_color", Color(0.08, 0.08, 0.10, 0.28))
	block_chip.add_theme_constant_override("shadow_offset_x", 1)
	block_chip.add_theme_constant_override("shadow_offset_y", 1)
	block_chip.add_theme_constant_override("shadow_outline_size", 1)
	block_bar_back.add_child(block_chip)

	status_strip = HBoxContainer.new()
	status_strip.name = "StatusStrip"
	status_strip.layout_mode = 1
	status_strip.anchor_left = 0.12
	status_strip.anchor_top = 0.975
	status_strip.anchor_right = 0.88
	status_strip.anchor_bottom = 1.0
	status_strip.alignment = BoxContainer.ALIGNMENT_CENTER
	status_strip.mouse_filter = Control.MOUSE_FILTER_PASS
	status_strip.add_theme_constant_override("separation", 6)
	action_root.add_child(status_strip)

func _apply_visual_state() -> void:
	if portrait_frame == null:
		return
	var style: StyleBoxFlat = portrait_frame.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	if is_action_focus:
		style.border_color = Color(1.0, 0.88, 0.54, 0.98)
		style.shadow_color = Color(1.0, 0.72, 0.24, 0.54)
		style.shadow_size = 24
	elif is_preview_target:
		style.border_color = Color(1.0, 0.44, 0.38, 0.92)
		style.shadow_color = Color(1.0, 0.28, 0.22, 0.42)
		style.shadow_size = 18
	elif is_selected:
		style.border_color = accent_color.lightened(0.26)
		style.shadow_color = accent_color.darkened(0.10)
		style.shadow_size = 16
	elif warning_active:
		style.border_color = warning_color.lightened(0.08)
		style.shadow_color = Color(warning_color.r, warning_color.g, warning_color.b, 0.34)
		style.shadow_size = 16
	else:
		style.border_color = Color(0.90, 0.96, 1.0, 0.0)
		style.shadow_color = Color(0.0, 0.0, 0.0, 0.20)
		style.shadow_size = 8
	portrait_frame.add_theme_stylebox_override("panel", style)
	if is_action_focus:
		glow.color = Color(1.0, 0.78, 0.28, 0.28)
	elif is_preview_target:
		glow.color = Color(1.0, 0.34, 0.26, 0.24)
	elif is_selected:
		glow.color = Color(accent_color.r, accent_color.g, accent_color.b, 0.20)
	elif warning_active:
		glow.color = Color(warning_color.r, warning_color.g, warning_color.b, 0.18)
	else:
		glow.color = Color(accent_color.r, accent_color.g, accent_color.b, 0.06)
	name_chip.add_theme_color_override("font_color", Color(1.0, 0.92, 0.66, 1.0) if is_action_focus else (accent_color.lightened(0.32) if is_selected else Color(0.98, 0.97, 0.94, 1.0)))

func _start_idle() -> void:
	if idle_tween != null:
		idle_tween.kill()
	idle_root.position = Vector2.ZERO
	idle_tween = _make_actor_tween()
	idle_tween.set_loops()
	idle_tween.tween_property(idle_root, "position:y", -5.0, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	idle_tween.tween_property(idle_root, "position:y", 0.0, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _pulse(target_scale: float) -> void:
	if action_tween != null:
		action_tween.kill()
	action_root.position = Vector2.ZERO
	action_tween = _make_actor_tween()
	action_tween.tween_property(action_root, "scale", Vector2(target_scale, target_scale), 0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	action_tween.tween_property(action_root, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _kick(offset_x: float, press_scale: float, overshoot_scale: float) -> void:
	if action_tween != null:
		action_tween.kill()
	action_root.position = Vector2.ZERO
	action_root.scale = Vector2.ONE
	action_tween = _make_actor_tween()
	action_tween.tween_property(action_root, "position:x", offset_x, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	action_tween.parallel().tween_property(action_root, "scale", Vector2(overshoot_scale, overshoot_scale), 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	action_tween.tween_property(action_root, "position:x", 0.0, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	action_tween.parallel().tween_property(action_root, "scale", Vector2(press_scale, press_scale), 0.06).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	action_tween.tween_property(action_root, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _flash(color_value: Color, peak_alpha: float) -> void:
	var tween: Tween = _make_actor_tween()
	tween.tween_property(glow, "color", Color(color_value.r, color_value.g, color_value.b, peak_alpha), 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(glow, "color", Color(accent_color.r, accent_color.g, accent_color.b, 0.30 if is_selected else 0.14), 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		actor_pressed.emit()

func _make_actor_tween() -> Tween:
	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tree_exiting.connect(func() -> void:
		if tween != null:
			tween.kill()
	, CONNECT_ONE_SHOT)
	return tween

func _kill_actor_tween(tween: Tween) -> void:
	if tween != null:
		tween.kill()
