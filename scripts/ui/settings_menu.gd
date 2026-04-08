extends Control

const RESOLUTIONS := ["1920x1080", "1600x900", "1280x720"]
const UI_MOTION = preload("res://scripts/core/ui_motion.gd")
const UI_THEME_KIT = preload("res://scripts/ui/ui_theme_kit.gd")

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

func _ready() -> void:
	_apply_ui_theme()
	_setup_option_buttons()
	_apply_text()
	LocalizationManager.language_changed.connect(_on_language_changed)
	_bind_interactions()
	_load_saved_settings()
	call_deferred("_play_intro_animation")

func _setup_option_buttons() -> void:
	resolution_options.clear()
	display_mode_options.clear()
	language_options.clear()
	ui_scale_options.clear()
	for item in RESOLUTIONS:
		resolution_options.add_item(item)
	for item in _display_mode_labels():
		display_mode_options.add_item(item)
	for item in ["简体中文", "English"]:
		language_options.add_item(item)
	ui_scale_options.add_item("175% (Fixed)")
	ui_scale_options.disabled = true

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
		master_value.text = "%d%%" % int(round(value))
		_save_audio_settings()
	)
	music_slider.value_changed.connect(func(value: float) -> void:
		music_value.text = "%d%%" % int(round(value))
		_save_audio_settings()
	)
	sfx_slider.value_changed.connect(func(value: float) -> void:
		sfx_value.text = "%d%%" % int(round(value))
		_save_audio_settings()
	)
	voice_slider.value_changed.connect(func(value: float) -> void:
		voice_value.text = "%d%%" % int(round(value))
		_save_audio_settings()
	)
	back_button.pressed.connect(func() -> void:
		_press_and_call(back_button, Callable(SceneRouter, "return_from_settings"))
	)
	return_main_button.pressed.connect(func() -> void:
		_press_and_call(return_main_button, Callable(self, "_return_to_main"))
	)

func _load_saved_settings() -> void:
	var settings: Dictionary = SettingsManager.get_settings()
	_select_resolution(String(settings.get("resolution", RESOLUTIONS[0])))
	display_mode_options.select(int(settings.get("display_mode", 0)))
	fullscreen_toggle.button_pressed = bool(settings.get("fullscreen", false))
	borderless_toggle.button_pressed = bool(settings.get("borderless", false))
	vsync_toggle.button_pressed = bool(settings.get("vsync", true))
	auto_end_turn_toggle.button_pressed = bool(settings.get("auto_end_turn", false))
	_select_ui_scale(float(settings.get("ui_scale", SettingsManager.FIXED_UI_SCALE)))
	master_slider.value = float(settings.get("master_volume", 80.0))
	music_slider.value = float(settings.get("music_volume", 70.0))
	sfx_slider.value = float(settings.get("sfx_volume", 75.0))
	voice_slider.value = float(settings.get("voice_volume", 85.0))
	master_value.text = "%d%%" % int(round(master_slider.value))
	music_value.text = "%d%%" % int(round(music_slider.value))
	sfx_value.text = "%d%%" % int(round(sfx_slider.value))
	voice_value.text = "%d%%" % int(round(voice_slider.value))
	if LocalizationManager.current_language == LocalizationManager.LANG_ZH:
		language_options.select(0)
	else:
		language_options.select(1)

func _apply_text() -> void:
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

func _on_language_changed(_language_code: String) -> void:
	_apply_text()

func _on_resolution_selected(index: int) -> void:
	var resolution_text: String = RESOLUTIONS[index]
	SettingsManager.save_settings({"resolution": resolution_text})
	SettingsManager.apply_saved_settings()

func _on_display_mode_selected(index: int) -> void:
	fullscreen_toggle.button_pressed = index == 2
	SettingsManager.save_settings({"display_mode": index, "fullscreen": index == 2})
	SettingsManager.apply_saved_settings()

func _on_language_selected(index: int) -> void:
	if index == 0:
		LocalizationManager.set_language(LocalizationManager.LANG_ZH)
	else:
		LocalizationManager.set_language(LocalizationManager.LANG_EN)

func _on_ui_scale_selected(index: int) -> void:
	ui_scale_options.select(0)

func _on_fullscreen_toggled(enabled: bool) -> void:
	var display_mode: int = 2 if enabled else min(display_mode_options.selected, 1)
	display_mode_options.select(display_mode)
	SettingsManager.save_settings({"fullscreen": enabled, "display_mode": display_mode})
	SettingsManager.apply_saved_settings()

func _on_borderless_toggled(enabled: bool) -> void:
	SettingsManager.save_settings({"borderless": enabled})
	SettingsManager.apply_saved_settings()

func _on_vsync_toggled(enabled: bool) -> void:
	SettingsManager.save_settings({"vsync": enabled})
	SettingsManager.apply_saved_settings()

func _on_auto_end_turn_toggled(enabled: bool) -> void:
	SettingsManager.save_settings({"auto_end_turn": enabled})

func _save_audio_settings() -> void:
	SettingsManager.save_settings({
		"master_volume": master_slider.value,
		"music_volume": music_slider.value,
		"sfx_volume": sfx_slider.value,
		"voice_volume": voice_slider.value
	})
	MusicManager.refresh_menu_volume()

func _select_resolution(resolution_text: String) -> void:
	var index: int = RESOLUTIONS.find(resolution_text)
	resolution_options.select(index if index != -1 else 0)

func _select_ui_scale(scale_value: float) -> void:
	ui_scale_options.select(0)

func _display_mode_labels() -> Array[String]:
	var labels: Array[String] = []
	labels.append(LocalizationManager.text("settings.windowed"))
	labels.append(LocalizationManager.text("settings.maximized"))
	labels.append(LocalizationManager.text("settings.fullscreen_mode"))
	return labels

func _back_button_text() -> String:
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
	await UI_MOTION.pulse(button, 0.96, 1.02, 0.06).finished
	action.call()

func _return_to_main() -> void:
	RunManager.save_run_snapshot()
	SceneRouter.go_main_menu()

func _apply_ui_theme() -> void:
	UI_THEME_KIT.apply_glass_panel(left_panel)
	UI_THEME_KIT.apply_heading($Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/Title as Label, 42, Color(1.0, 0.96, 0.88, 1.0), Color(0.04, 0.05, 0.07, 0.74))
	UI_THEME_KIT.apply_body($Margin/LeftPanel/LeftMargin/LeftBox/Scroll/VBox/Body as Label, 18, Color(0.92, 0.94, 0.98, 0.92))
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
