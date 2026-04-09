extends Control

const VICTORY_BG_PATH := "res://assets/backgrounds/victory_bg.png"

@onready var background_image: TextureRect = $BackgroundImage
@onready var title_label: Label = $Layout/Margin/Content/Title
@onready var body_label: Label = $Layout/Margin/Content/Body
@onready var summary_label: Label = $Layout/Margin/Content/Summary
@onready var hint_label: Label = $Layout/Margin/Content/Hint
@onready var back_button: Button = $Layout/Margin/Content/Back

func _ready() -> void:
	_apply_background()
	SfxManager.play_victory()
	_apply_text()
	LocalizationManager.language_changed.connect(_apply_text)
	back_button.pressed.connect(func() -> void:
		RunManager.abandon_run()
		SceneRouter.go_main_menu()
	)

func _apply_background() -> void:
	var image: Image = Image.new()
	var err: Error = image.load(ProjectSettings.globalize_path(VICTORY_BG_PATH))
	if err != OK:
		return
	background_image.texture = ImageTexture.create_from_image(image)

func _apply_text(_language_code: String = "") -> void:
	var hidden_clear: bool = RunManager.has_flag("hidden_truth_cleared") or String(RunManager.story_flags.get("ending_variant", "")) == "hidden"
	var character_name: String = LocalizationManager.active_character_name()
	title_label.text = LocalizationManager.text("victory.title_hidden") if hidden_clear else LocalizationManager.text("victory.title")
	body_label.text = LocalizationManager.text("victory.body_hidden", [character_name]) if hidden_clear else LocalizationManager.text("victory.body", [character_name])
	var floor_value: int = int(RunManager.last_run_summary.get("floor", RunManager.current_floor))
	var gold_value: int = int(RunManager.last_run_summary.get("gold", RunManager.gold))
	var deck_size: int = int(RunManager.last_run_summary.get("deck_size", RunManager.deck.size()))
	var module_count: int = int(RunManager.last_run_summary.get("modules", RunManager.modules.size()))
	summary_label.text = LocalizationManager.text("victory.summary", [floor_value, gold_value, deck_size, module_count])
	hint_label.text = LocalizationManager.text("victory.hint_hidden") if hidden_clear else LocalizationManager.text("victory.hint")
	back_button.text = LocalizationManager.text("victory.back")
