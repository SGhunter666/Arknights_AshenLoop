extends Control

@onready var info_label: Label = $Panel/Margin/VBox/Info

func _ready() -> void:
	RunManager.heal_full()
	info_label.text = LocalizationManager.text("rest.info")

func _on_continue_pressed() -> void:
	if RunManager.should_take_interfloor_rest():
		RunManager.consume_interfloor_rest()
	RunManager.complete_current_node()
	if RunManager.has_flag("run_complete"):
		SceneRouter.go_main_menu()
	else:
		SceneRouter.go_map()
