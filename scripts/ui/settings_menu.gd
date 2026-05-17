extends Control

const RESOLUTIONS := ["1920x1080", "1920x1200", "2560x1440", "2560x1600", "1600x900"]
const UI_SCALE_PRESETS := ["auto", "windows", "macbook"]
const UI_MOTION = preload("res://scripts/core/ui_motion.gd")
const UI_THEME_KIT = preload("res://scripts/ui/ui_theme_kit.gd")

signal close_requested

@onready var resolution_options: OptionButton = $Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/ResolutionOptions
@onready var display_mode_options: OptionButton = $Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/DisplayModeOptions
@onready var language_options: OptionButton = $Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/LanguageOptions
@onready var ui_scale_options: OptionButton = $Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/UIScaleOptions
@onready var fullscreen_toggle: CheckBox = $Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/FullscreenToggle
@onready var borderless_toggle: CheckBox = $Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/BorderlessToggle
@onready var vsync_toggle: CheckBox = $Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/VSyncToggle
@onready var auto_end_turn_toggle: CheckBox = $Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/AutoEndTurnToggle
@onready var master_slider: HSlider = $Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/MasterSlider
@onready var master_value: Label = $Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/MasterValue
@onready var music_slider: HSlider = $Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/MusicSlider
@onready var music_value: Label = $Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/MusicValue
@onready var sfx_slider: HSlider = $Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/SfxSlider
@onready var sfx_value: Label = $Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/SfxValue
@onready var voice_slider: HSlider = $Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/VoiceSlider
@onready var voice_value: Label = $Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/VoiceValue
@onready var back_button: Button = $Margin/LeftPanel/LeftMargin/LeftBox/Footer/Back
@onready var return_main_button: Button = $Margin/LeftPanel/LeftMargin/LeftBox/Footer/ReturnMain
@onready var left_panel: Control = $Margin/LeftPanel

var overlay_mode: bool = false
var loading_settings: bool = false
var section_labels: Dictionary = {}
var category_tabs: HBoxContainer
var category_buttons: Dictionary = {}
var active_category: String = "video"

func _ready() -> void:
	_configure_overlay_visuals()
	_inject_section_headers()
	_build_category_tabs()
	_apply_ui_theme()
	_setup_option_buttons()
	_apply_text()
	_load_saved_settings()
	_select_settings_category(active_category)
	LocalizationManager.language_changed.connect(_on_language_changed)
	_bind_interactions()
	call_deferred("_play_intro_animation")

func enable_overlay_mode() -> void:
	overlay_mode = true
	_configure_overlay_visuals()
	if is_node_ready():
		_configure_settings_layout()

func _setup_option_buttons() -> void:
	resolution_options.clear()
	display_mode_options.clear()
	language_options.clear()
	ui_scale_options.clear()
	for item in RESOLUTIONS:
		resolution_options.add_item(item)
	for item in _display_mode_labels():
		display_mode_options.add_item(item)
	for item in _language_labels():
		language_options.add_item(item)
	for item in _ui_scale_option_labels():
		ui_scale_options.add_item(item)
	ui_scale_options.disabled = false

func _bind_interactions() -> void:
	resolution_options.item_selected.connect(_on_resolution_selected)
	display_mode_options.item_selected.connect(_on_display_mode_selected)
	language_options.item_selected.connect(_on_language_selected)
	ui_scale_options.item_selected.connect(_on_ui_scale_selected)
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	borderless_toggle.toggled.connect(_on_borderless_toggled)
	vsync_toggle.toggled.connect(_on_vsync_toggled)
	auto_end_turn_toggle.toggled.connect(_on_auto_end_turn_toggled)
	master_slider.value_changed.connect(func(value: float) -> void:
		if loading_settings:
			return
		master_value.text = "%d%%" % int(round(value))
		_save_audio_settings()
	)
	music_slider.value_changed.connect(func(value: float) -> void:
		if loading_settings:
			return
		music_value.text = "%d%%" % int(round(value))
		_save_audio_settings()
	)
	sfx_slider.value_changed.connect(func(value: float) -> void:
		if loading_settings:
			return
		sfx_value.text = "%d%%" % int(round(value))
		_save_audio_settings()
	)
	voice_slider.value_changed.connect(func(value: float) -> void:
		if loading_settings:
			return
		voice_value.text = "%d%%" % int(round(value))
		_save_audio_settings()
	)
	back_button.pressed.connect(func() -> void:
		_press_and_call(back_button, Callable(self, "_handle_back"))
	)
	return_main_button.pressed.connect(func() -> void:
		_press_and_call(return_main_button, Callable(self, "_return_to_main"))
	)

func _load_saved_settings() -> void:
	loading_settings = true
	var settings: Dictionary = SettingsManager.get_settings()
	_select_resolution(String(settings.get("resolution", RESOLUTIONS[0])))
	display_mode_options.select(int(settings.get("display_mode", 0)))
	fullscreen_toggle.set_pressed_no_signal(bool(settings.get("fullscreen", false)))
	borderless_toggle.set_pressed_no_signal(bool(settings.get("borderless", false)))
	vsync_toggle.set_pressed_no_signal(bool(settings.get("vsync", true)))
	auto_end_turn_toggle.set_pressed_no_signal(bool(settings.get("auto_end_turn", false)))
	_select_ui_scale_preset(String(settings.get("ui_scale_preset", "auto")))
	master_slider.set_value_no_signal(float(settings.get("master_volume", 80.0)))
	music_slider.set_value_no_signal(float(settings.get("music_volume", 70.0)))
	sfx_slider.set_value_no_signal(float(settings.get("sfx_volume", 75.0)))
	voice_slider.set_value_no_signal(float(settings.get("voice_volume", 85.0)))
	master_value.text = "%d%%" % int(round(master_slider.value))
	music_value.text = "%d%%" % int(round(music_slider.value))
	sfx_value.text = "%d%%" % int(round(sfx_slider.value))
	voice_value.text = "%d%%" % int(round(voice_slider.value))
	if LocalizationManager.current_language == LocalizationManager.LANG_ZH:
		language_options.select(0)
	else:
		language_options.select(1)
	loading_settings = false

func _apply_text() -> void:
	_apply_section_text()
	_apply_category_tab_text()
	$Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/Title.text = LocalizationManager.text("settings.title")
	$Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/Body.text = LocalizationManager.text("settings.body")
	$Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/ResolutionLabel.text = LocalizationManager.text("settings.resolution")
	$Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/DisplayModeLabel.text = LocalizationManager.text("settings.display_mode")
	$Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/LanguageLabel.text = LocalizationManager.text("settings.language")
	$Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/UIScaleLabel.text = LocalizationManager.text("settings.ui_scale")
	fullscreen_toggle.text = LocalizationManager.text("settings.fullscreen")
	borderless_toggle.text = LocalizationManager.text("settings.borderless")
	vsync_toggle.text = LocalizationManager.text("settings.vsync")
	auto_end_turn_toggle.text = LocalizationManager.text("settings.auto_end_turn")
	$Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/MasterLabel.text = LocalizationManager.text("settings.master")
	$Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/MusicLabel.text = LocalizationManager.text("settings.music")
	$Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/SfxLabel.text = LocalizationManager.text("settings.sfx")
	$Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/VoiceLabel.text = LocalizationManager.text("settings.voice")
	back_button.text = _back_button_text()
	return_main_button.text = LocalizationManager.text("system.return_main")
	var display_index: int = display_mode_options.selected
	display_mode_options.clear()
	for item in _display_mode_labels():
		display_mode_options.add_item(item)
	display_mode_options.select(clamp(display_index, 0, 2))
	var language_index: int = language_options.selected
	language_options.clear()
	for item in _language_labels():
		language_options.add_item(item)
	language_options.select(clamp(language_index, 0, 1))
	if ui_scale_options.item_count > 0:
		var scale_index: int = ui_scale_options.selected
		ui_scale_options.clear()
		for item in _ui_scale_option_labels():
			ui_scale_options.add_item(item)
		ui_scale_options.select(clamp(scale_index, 0, UI_SCALE_PRESETS.size() - 1))
	_select_settings_category(active_category)

func _on_language_changed(_language_code: String) -> void:
	_apply_text()

func _inject_section_headers() -> void:
	var vbox: VBoxContainer = $Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox
	_add_section_before(vbox, "SectionVideo", "settings.section_video", "ResolutionLabel")
	_add_section_before(vbox, "SectionLanguage", "settings.section_language", "LanguageLabel")
	_add_section_before(vbox, "SectionGame", "settings.section_game", "AutoEndTurnToggle")
	_add_section_before(vbox, "SectionAudio", "settings.section_audio", "MasterLabel")

func _add_section_before(vbox: VBoxContainer, node_name: String, text_key: String, before_node_name: String) -> void:
	if vbox.has_node(node_name):
		section_labels[text_key] = vbox.get_node(node_name)
		return
	var before_node: Node = vbox.get_node_or_null(before_node_name)
	if before_node == null:
		return
	var label := Label.new()
	label.name = node_name
	label.layout_mode = 2
	label.text = LocalizationManager.text(text_key)
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.66, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0.03, 0.04, 0.07, 0.95))
	label.add_theme_constant_override("outline_size", 2)
	vbox.add_child(label)
	vbox.move_child(label, before_node.get_index())
	section_labels[text_key] = label

func _build_category_tabs() -> void:
	var vbox: VBoxContainer = $Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox
	if category_tabs != null and is_instance_valid(category_tabs):
		return
	category_tabs = HBoxContainer.new()
	category_tabs.name = "CategoryTabs"
	category_tabs.layout_mode = 2
	category_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	category_tabs.add_theme_constant_override("separation", 8)
	vbox.add_child(category_tabs)
	var body_label: Node = vbox.get_node_or_null("Body")
	if body_label != null:
		vbox.move_child(category_tabs, body_label.get_index() + 1)
	for category in ["video", "language", "game", "audio"]:
		var button := Button.new()
		button.name = "%sTab" % category.capitalize()
		button.layout_mode = 2
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0, 46)
		button.focus_mode = Control.FOCUS_NONE
		button.toggle_mode = true
		category_tabs.add_child(button)
		category_buttons[category] = button
		button.pressed.connect(func(target_category: String = category) -> void:
			_select_settings_category(target_category)
		)

func _apply_category_tab_text() -> void:
	if category_buttons.is_empty():
		return
	var labels: Dictionary = {
		"video": LocalizationManager.text("settings.section_video"),
		"language": LocalizationManager.text("settings.section_language"),
		"game": LocalizationManager.text("settings.section_game"),
		"audio": LocalizationManager.text("settings.section_audio")
	}
	for category in category_buttons.keys():
		var button: Button = category_buttons[category] as Button
		if button != null:
			button.text = String(labels.get(category, category.capitalize()))

func _select_settings_category(category: String) -> void:
	active_category = category
	for category_key in category_buttons.keys():
		var button: Button = category_buttons[category_key] as Button
		if button != null:
			button.set_pressed_no_signal(category_key == active_category)
			_apply_category_button_style(button, category_key == active_category)
	_set_category_nodes_visible("video", active_category == "video")
	_set_category_nodes_visible("language", active_category == "language")
	_set_category_nodes_visible("game", active_category == "game")
	_set_category_nodes_visible("audio", active_category == "audio")

func _set_category_nodes_visible(category: String, visible: bool) -> void:
	for node_path in _category_node_paths(category):
		var node: CanvasItem = get_node_or_null(node_path) as CanvasItem
		if node != null:
			node.visible = visible

func _category_node_paths(category: String) -> Array[String]:
	match category:
		"video":
			return [
				"Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/SectionVideo",
				"Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/ResolutionLabel",
				"Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/ResolutionOptions",
				"Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/DisplayModeLabel",
				"Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/DisplayModeOptions",
				"Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/UIScaleLabel",
				"Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/UIScaleOptions",
				"Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/FullscreenToggle",
				"Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/BorderlessToggle",
				"Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/VSyncToggle"
			]
		"language":
			return [
				"Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/SectionLanguage",
				"Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/LanguageLabel",
				"Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/LanguageOptions"
			]
		"game":
			return [
				"Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/SectionGame",
				"Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/AutoEndTurnToggle"
			]
		"audio":
			return [
				"Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/SectionAudio",
				"Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/MasterLabel",
				"Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/MasterSlider",
				"Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/MasterValue",
				"Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/MusicLabel",
				"Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/MusicSlider",
				"Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/MusicValue",
				"Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/SfxLabel",
				"Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/SfxSlider",
				"Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/SfxValue",
				"Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/VoiceLabel",
				"Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/VoiceSlider",
				"Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/VoiceValue"
			]
	return []

func _apply_section_text() -> void:
	for key in section_labels.keys():
		var label: Label = section_labels[key] as Label
		if label != null:
			label.text = LocalizationManager.text(String(key))

func _on_resolution_selected(index: int) -> void:
	if loading_settings:
		return
	SfxManager.play_ui_click()
	var resolution_text: String = RESOLUTIONS[index]
	SettingsManager.save_settings({"resolution": resolution_text})
	SettingsManager.apply_saved_settings()

func _on_display_mode_selected(index: int) -> void:
	if loading_settings:
		return
	SfxManager.play_ui_click()
	fullscreen_toggle.button_pressed = index == 2
	SettingsManager.save_settings({"display_mode": index, "fullscreen": index == 2})
	SettingsManager.apply_saved_settings()

func _on_language_selected(index: int) -> void:
	if loading_settings:
		return
	SfxManager.play_ui_click()
	if index == 0:
		LocalizationManager.set_language(LocalizationManager.LANG_ZH)
	else:
		LocalizationManager.set_language(LocalizationManager.LANG_EN)

func _on_ui_scale_selected(index: int) -> void:
	if loading_settings:
		return
	SfxManager.play_ui_click()
	var safe_index: int = clamp(index, 0, UI_SCALE_PRESETS.size() - 1)
	SettingsManager.save_settings({"ui_scale_preset": UI_SCALE_PRESETS[safe_index]})
	SettingsManager.apply_saved_settings()

func _on_fullscreen_toggled(enabled: bool) -> void:
	if loading_settings:
		return
	SfxManager.play_ui_click()
	var display_mode: int = 2 if enabled else min(display_mode_options.selected, 1)
	display_mode_options.select(display_mode)
	SettingsManager.save_settings({"fullscreen": enabled, "display_mode": display_mode})
	SettingsManager.apply_saved_settings()

func _on_borderless_toggled(enabled: bool) -> void:
	if loading_settings:
		return
	SfxManager.play_ui_click()
	SettingsManager.save_settings({"borderless": enabled})
	SettingsManager.apply_saved_settings()

func _on_vsync_toggled(enabled: bool) -> void:
	if loading_settings:
		return
	SfxManager.play_ui_click()
	SettingsManager.save_settings({"vsync": enabled})
	SettingsManager.apply_saved_settings()

func _on_auto_end_turn_toggled(enabled: bool) -> void:
	if loading_settings:
		return
	SfxManager.play_ui_click()
	SettingsManager.save_settings({"auto_end_turn": enabled})

func _save_audio_settings() -> void:
	SettingsManager.save_settings({
		"master_volume": master_slider.value,
		"music_volume": music_slider.value,
		"sfx_volume": sfx_slider.value,
		"voice_volume": voice_slider.value
	})
	MusicManager.refresh_menu_volume()
	SfxManager.refresh_volume()

func _select_resolution(resolution_text: String) -> void:
	var index: int = RESOLUTIONS.find(resolution_text)
	resolution_options.select(index if index != -1 else 0)

func _select_ui_scale_preset(preset: String) -> void:
	var index: int = UI_SCALE_PRESETS.find(preset)
	ui_scale_options.select(index if index != -1 else 0)

func _ui_scale_option_labels() -> Array[String]:
	if LocalizationManager.current_language == LocalizationManager.LANG_ZH:
		return [
			"自动推荐（当前系统）",
			"Windows 推荐（100%）",
			"MacBook 推荐（175%）"
		]
	return [
		"Auto Recommended",
		"Windows Recommended (100%)",
		"MacBook Recommended (175%)"
	]

func _display_mode_labels() -> Array[String]:
	var labels: Array[String] = []
	labels.append(LocalizationManager.text("settings.windowed"))
	labels.append(LocalizationManager.text("settings.maximized"))
	labels.append(LocalizationManager.text("settings.fullscreen_mode"))
	return labels

func _language_labels() -> Array[String]:
	if LocalizationManager.current_language == LocalizationManager.LANG_ZH:
		return ["简体中文", "英语"]
	return ["Simplified Chinese", "English"]

func _back_button_text() -> String:
	if overlay_mode:
		return LocalizationManager.text("system.return_game")
	if SceneRouter.return_scene_after_settings in [
		SceneRouter.MAP_SCENE,
		SceneRouter.BATTLE_SCENE,
		SceneRouter.EVENT_SCENE,
		SceneRouter.REWARD_SCENE,
		SceneRouter.SHOP_SCENE,
		SceneRouter.REST_SCENE
	]:
		return LocalizationManager.text("system.return_game")
	return LocalizationManager.text("settings.back")

func _play_intro_animation() -> void:
	UI_MOTION.reveal(left_panel, 0.04, Vector2(-34, 0), 0.36, Vector2(0.985, 0.985))
	UI_MOTION.reveal(back_button, 0.16, Vector2(0, 20), 0.26)
	UI_MOTION.reveal(return_main_button, 0.22, Vector2(0, 20), 0.26)

func _press_and_call(button: Control, action: Callable) -> void:
	UI_MOTION.pulse_then(button, action, 0.96, 1.02, 0.06)

func _handle_back() -> void:
	if overlay_mode:
		close_requested.emit()
		queue_free()
		return
	SceneRouter.return_from_settings()

func _return_to_main() -> void:
	RunManager.save_run_snapshot()
	SceneRouter.go_main_menu()

func _apply_ui_theme() -> void:
	_configure_settings_layout()
	UI_THEME_KIT.apply_glass_panel(left_panel)
	UI_THEME_KIT.apply_heading($Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/Title as Label, 42, Color(1.0, 0.96, 0.88, 1.0), Color(0.04, 0.05, 0.07, 0.74))
	UI_THEME_KIT.apply_body($Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/Body as Label, 18, Color(0.92, 0.94, 0.98, 0.92))
	for key in section_labels.keys():
		var section_label: Label = section_labels[key] as Label
		if section_label != null:
			UI_THEME_KIT.apply_body(section_label, 22, Color(1.0, 0.92, 0.66, 1.0))
			section_label.add_theme_color_override("font_outline_color", Color(0.03, 0.04, 0.07, 0.95))
			section_label.add_theme_constant_override("outline_size", 2)
	for label_path in [
		"Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/ResolutionLabel",
		"Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/DisplayModeLabel",
		"Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/LanguageLabel",
		"Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/UIScaleLabel",
		"Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/MasterLabel",
		"Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/MusicLabel",
		"Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/SfxLabel",
		"Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/VoiceLabel"
	]:
		var label: Label = get_node(label_path) as Label
		if label != null:
			UI_THEME_KIT.apply_body(label, 22, Color(0.98, 0.98, 0.98, 0.98))
	for option in [resolution_options, display_mode_options, language_options, ui_scale_options]:
		UI_THEME_KIT.apply_option_button(option)
		UI_MOTION.wire_button_feedback(option, 1.01, 0.99, Color(0.76, 0.92, 1.0, 0.56), 4.0)
	for category_key in category_buttons.keys():
		var category_button: Button = category_buttons[category_key] as Button
		if category_button != null:
			UI_MOTION.wire_button_feedback(category_button, 1.01, 0.99, Color(1.0, 0.88, 0.56, 0.44), 4.0)
			_apply_category_button_style(category_button, category_key == active_category)
	for toggle in [fullscreen_toggle, borderless_toggle, vsync_toggle, auto_end_turn_toggle]:
		UI_THEME_KIT.apply_toggle(toggle)
	for slider in [master_slider, music_slider, sfx_slider, voice_slider]:
		UI_THEME_KIT.apply_slider(slider)
	for value_label in [master_value, music_value, sfx_value, voice_value]:
		UI_THEME_KIT.apply_numeric(value_label, 18, Color(1.0, 0.96, 0.88, 1.0))
	UI_THEME_KIT.apply_stone_button(back_button, "paper", 24)
	UI_THEME_KIT.apply_stone_button(return_main_button, "paper", 22)
	UI_MOTION.wire_button_feedback(back_button, 1.02, 0.98, Color(1.0, 0.88, 0.66, 0.68), 5.0)
	UI_MOTION.wire_button_feedback(return_main_button, 1.02, 0.98, Color(1.0, 0.88, 0.66, 0.68), 5.0)

func _configure_settings_layout() -> void:
	left_panel.custom_minimum_size = Vector2(560, 0) if overlay_mode else Vector2(760, 0)
	left_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN if overlay_mode else Control.SIZE_SHRINK_CENTER
	left_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var left_margin: MarginContainer = $Margin/LeftPanel/LeftMargin as MarginContainer
	if left_margin != null:
		left_margin.add_theme_constant_override("margin_left", 26)
		left_margin.add_theme_constant_override("margin_top", 24)
		left_margin.add_theme_constant_override("margin_right", 26)
		left_margin.add_theme_constant_override("margin_bottom", 24)
	var title: Label = $Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/Title as Label
	var body: Label = $Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/Body as Label
	if title != null:
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if body != null:
		body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for option in [resolution_options, display_mode_options, language_options, ui_scale_options]:
		option.custom_minimum_size = Vector2(0, 50)
	for slider in [master_slider, music_slider, sfx_slider, voice_slider]:
		slider.custom_minimum_size = Vector2(0, 48)
	for button in [back_button, return_main_button]:
		button.custom_minimum_size = Vector2(0, 58)

func _apply_category_button_style(button: Button, selected: bool) -> void:
	UI_THEME_KIT.apply_stone_button(button, "danger" if selected else "ghost", 20)
	button.add_theme_color_override("font_color", Color(1.0, 0.95, 0.72, 1.0) if selected else Color(0.92, 0.96, 1.0, 0.92))

func _configure_overlay_visuals() -> void:
	if not is_node_ready():
		return
	var background_image: CanvasItem = get_node_or_null("BackgroundImage") as CanvasItem
	var background_shade: ColorRect = get_node_or_null("BackgroundShade") as ColorRect
	var left_shade: ColorRect = get_node_or_null("LeftShade") as ColorRect
	if overlay_mode:
		if background_image != null:
			background_image.visible = false
		if background_shade != null:
			background_shade.color = Color(0.02, 0.03, 0.05, 0.74)
		if left_shade != null:
			left_shade.color = Color(0.02, 0.03, 0.05, 0.84)
	else:
		if background_image != null:
			background_image.visible = true
		if background_shade != null:
			background_shade.color = Color(0.04, 0.05, 0.07, 0.22)
		if left_shade != null:
			left_shade.color = Color(0.03, 0.04, 0.06, 0.72)
