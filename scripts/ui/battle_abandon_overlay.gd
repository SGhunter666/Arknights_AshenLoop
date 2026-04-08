class_name BattleAbandonOverlay
extends Control

signal abandon_confirmed

var abandon_button: Button
var abandon_dialog: ConfirmationDialog
var battle_finished_provider: Callable = Callable()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_controls()
	refresh_text()
	if not LocalizationManager.language_changed.is_connected(_on_language_changed):
		LocalizationManager.language_changed.connect(_on_language_changed)

func set_battle_finished_provider(provider: Callable) -> void:
	battle_finished_provider = provider

func set_disabled(disabled: bool) -> void:
	if abandon_button != null:
		abandon_button.disabled = disabled

func refresh_text() -> void:
	if abandon_button != null:
		abandon_button.text = LocalizationManager.text("battle.abandon")
		abandon_button.tooltip_text = LocalizationManager.text("battle.abandon_tooltip")
	if abandon_dialog != null:
		abandon_dialog.title = LocalizationManager.text("battle.abandon_title")
		abandon_dialog.dialog_text = LocalizationManager.text("battle.abandon_body")
		abandon_dialog.ok_button_text = LocalizationManager.text("battle.abandon_confirm")
		abandon_dialog.cancel_button_text = LocalizationManager.text("battle.abandon_cancel")

func _build_controls() -> void:
	abandon_button = Button.new()
	abandon_button.name = "AbandonRunButton"
	abandon_button.layout_mode = 1
	abandon_button.anchor_left = 1.0
	abandon_button.anchor_right = 1.0
	abandon_button.offset_left = -226.0
	abandon_button.offset_top = 18.0
	abandon_button.offset_right = -82.0
	abandon_button.offset_bottom = 62.0
	abandon_button.focus_mode = Control.FOCUS_NONE
	abandon_button.self_modulate = Color(1.0, 0.66, 0.60, 0.94)
	abandon_button.add_theme_font_size_override("font_size", 18)
	add_child(abandon_button)
	abandon_button.pressed.connect(_open_abandon_dialog)

	abandon_dialog = ConfirmationDialog.new()
	abandon_dialog.name = "AbandonRunDialog"
	abandon_dialog.exclusive = true
	add_child(abandon_dialog)
	abandon_dialog.confirmed.connect(_confirm_abandon_run)

func _open_abandon_dialog() -> void:
	if abandon_dialog == null or _is_battle_finished():
		return
	abandon_dialog.popup_centered()

func _confirm_abandon_run() -> void:
	if _is_battle_finished():
		return
	abandon_confirmed.emit()

func _is_battle_finished() -> bool:
	if battle_finished_provider.is_valid():
		return bool(battle_finished_provider.call())
	return false

func _on_language_changed(_language_code: String) -> void:
	refresh_text()
