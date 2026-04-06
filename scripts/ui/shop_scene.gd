extends Control

@onready var info_label: Label = $Panel/Margin/VBox/Info

func _ready() -> void:
	info_label.text = LocalizationManager.text("shop.info")

func _on_remove_card_pressed() -> void:
	if RunManager.gold >= 40 and not RunManager.deck.is_empty():
		RunManager.add_gold(-40)
		RunManager.remove_card(RunManager.deck[0])
		info_label.text = LocalizationManager.text("shop.removed")

func _on_buy_module_pressed() -> void:
	if RunManager.gold >= 50:
		RunManager.add_gold(-50)
		RunManager.add_module("signal_booster")
		info_label.text = LocalizationManager.text("shop.bought")

func _on_continue_pressed() -> void:
	RunManager.complete_current_node()
	if RunManager.has_flag("run_complete"):
		SceneRouter.go_main_menu()
	else:
		SceneRouter.go_map()
