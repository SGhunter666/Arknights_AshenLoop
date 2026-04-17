extends Control

@onready var title_label: Label = $Layout/Margin/Content/Title
@onready var body_label: Label = $Layout/Margin/Content/Body
@onready var hint_label: Label = $Layout/Margin/Content/Hint
@onready var confirm_button: Button = $Layout/Margin/Content/Confirm
@onready var cancel_button: Button = $Layout/Margin/Content/Cancel

func _ready() -> void:
	_apply_text()
	LocalizationManager.language_changed.connect(_apply_text)
	confirm_button.pressed.connect(func() -> void:
		SfxManager.play_ui_click()
		RunManager.flush_persistent_state()
		get_tree().quit()
	)
	cancel_button.pressed.connect(func() -> void:
		SfxManager.play_ui_click()
		SceneRouter.go_main_menu()
	)

func _apply_text(_language_code: String = "") -> void:
	title_label.text = LocalizationManager.text("quit.title")
	body_label.text = LocalizationManager.text("quit.body")
	hint_label.text = LocalizationManager.text("quit.hint")
	confirm_button.text = LocalizationManager.text("quit.confirm")
	cancel_button.text = LocalizationManager.text("quit.cancel")
