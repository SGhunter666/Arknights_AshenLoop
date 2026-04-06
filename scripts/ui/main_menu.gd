extends Control

const UI_MOTION = preload("res://scripts/core/ui_motion.gd")

@onready var save_slot_button: Button = $SaveSlot
@onready var single_player_button: Button = $CenterWrap/CenterBox/Menu/SinglePlayer
@onready var multiplayer_button: Button = $CenterWrap/CenterBox/Menu/Multiplayer
@onready var timeline_button: Button = $CenterWrap/CenterBox/Menu/Timeline
@onready var settings_button: Button = $CenterWrap/CenterBox/Menu/Settings
@onready var codex_button: Button = $CenterWrap/CenterBox/Menu/Codex
@onready var quit_button: Button = $CenterWrap/CenterBox/Menu/Quit

func _ready() -> void:
	MusicManager.play_menu_bgm()
	_apply_text()
	_refresh_save_slot()
	LocalizationManager.language_changed.connect(_apply_text)
	RunManager.run_updated.connect(_refresh_save_slot)
	save_slot_button.pressed.connect(func() -> void:
		_press_and_call(save_slot_button, Callable(SceneRouter, "go_single_player"))
	)
	single_player_button.pressed.connect(func() -> void:
		_press_and_call(single_player_button, Callable(SceneRouter, "go_single_player"))
	)
	settings_button.pressed.connect(func() -> void:
		_press_and_call(settings_button, Callable(SceneRouter, "go_settings"))
	)
	codex_button.pressed.connect(func() -> void:
		_press_and_call(codex_button, Callable(SceneRouter, "go_encyclopedia"))
	)
	quit_button.pressed.connect(func() -> void:
		_press_and_call(quit_button, Callable(SceneRouter, "go_quit_page"))
	)
	call_deferred("_play_intro_animation")

func _apply_text(_language_code: String = "") -> void:
	$CenterWrap/CenterBox/BrandTop.text = LocalizationManager.text("main.brand_top")
	$CenterWrap/CenterBox/BrandBottom.text = LocalizationManager.text("main.brand_bottom")
	single_player_button.text = LocalizationManager.text("main.single_player")
	multiplayer_button.text = LocalizationManager.text("main.multiplayer")
	timeline_button.text = LocalizationManager.text("main.timeline")
	settings_button.text = LocalizationManager.text("main.settings")
	codex_button.text = LocalizationManager.text("main.codex")
	quit_button.text = LocalizationManager.text("main.quit")
	_refresh_save_slot()

func _refresh_save_slot(_unused: Variant = null) -> void:
	if not RunManager.has_saved_run():
		save_slot_button.visible = false
		return
	var save_data: Dictionary = RunManager.saved_run_summary()
	save_slot_button.visible = true
	save_slot_button.text = LocalizationManager.text("main.save_slot", [
		int(save_data.get("current_floor", 1)),
		int(save_data.get("hp", 0)),
		int(save_data.get("max_hp", 0))
	])

func _play_intro_animation() -> void:
	var center_box: Control = $CenterWrap/CenterBox
	UI_MOTION.reveal(center_box, 0.02, Vector2(0, 36), 0.38, Vector2(0.985, 0.985))
	UI_MOTION.reveal(save_slot_button, 0.00, Vector2(-20, 0), 0.28) if save_slot_button.visible else null
	UI_MOTION.reveal($VersionLabel, 0.06, Vector2(24, 0), 0.26)
	var menu_buttons: Array[Button] = [
		single_player_button, multiplayer_button, timeline_button, settings_button, codex_button, quit_button
	]
	for i in range(menu_buttons.size()):
		UI_MOTION.reveal(menu_buttons[i], 0.10 + float(i) * 0.05, Vector2(0, 14), 0.28)

func _press_and_call(button: Control, action: Callable) -> void:
	await UI_MOTION.pulse(button, 0.96, 1.02, 0.06).finished
	action.call()
