extends Control

@onready var title_label: Label = $Layout/Margin/Content/Title
@onready var body_label: Label = $Layout/Margin/Content/Body
@onready var summary_label: Label = $Layout/Margin/Content/Summary
@onready var back_button: Button = $Layout/Margin/Content/Back

func _ready() -> void:
	_apply_text()
	LocalizationManager.language_changed.connect(_apply_text)
	back_button.pressed.connect(func() -> void:
		SceneRouter.go_main_menu()
	)

func _apply_text(_language_code: String = "") -> void:
	title_label.text = LocalizationManager.text("defeat.title")
	body_label.text = LocalizationManager.text("defeat.body")
	var floor_value: int = int(RunManager.last_run_summary.get("floor", RunManager.current_floor))
	var gold_value: int = int(RunManager.last_run_summary.get("gold", RunManager.gold))
	var deck_size: int = int(RunManager.last_run_summary.get("deck_size", RunManager.deck.size()))
	summary_label.text = LocalizationManager.text("defeat.summary", [floor_value, gold_value, deck_size])
	back_button.text = LocalizationManager.text("defeat.retry")
