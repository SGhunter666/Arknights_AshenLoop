extends Node

const DISPLAY_UI_SCALE := 1.75
const LOGICAL_UI_SCALE := 1.0
const DEFAULT_SETTINGS := {
	"resolution": "1920x1080",
	"display_mode": 0,
	"ui_scale": LOGICAL_UI_SCALE,
	"fullscreen": false,
	"borderless": false,
	"vsync": true,
	"auto_end_turn": false,
	"master_volume": 80.0,
	"music_volume": 70.0,
	"sfx_volume": 75.0,
	"voice_volume": 85.0
}

func _ready() -> void:
	apply_saved_settings()

func get_settings() -> Dictionary:
	var profile: Dictionary = SaveManager.load_profile()
	for key in DEFAULT_SETTINGS.keys():
		if not profile.has(key):
			profile[key] = DEFAULT_SETTINGS[key]
	profile["ui_scale"] = LOGICAL_UI_SCALE
	return profile

func save_settings(overrides: Dictionary) -> void:
	var profile: Dictionary = get_settings()
	for key in overrides.keys():
		if String(key) == "ui_scale":
			profile[key] = LOGICAL_UI_SCALE
		else:
			profile[key] = overrides[key]
	profile["ui_scale"] = LOGICAL_UI_SCALE
	SaveManager.save_profile(profile)

func apply_saved_settings() -> void:
	apply_settings(get_settings())

func apply_settings(settings: Dictionary) -> void:
	var display_mode: int = int(settings.get("display_mode", 0))
	if bool(settings.get("fullscreen", false)):
		display_mode = 2
	_apply_display_mode(display_mode)
	_apply_resolution(String(settings.get("resolution", "1920x1080")))
	_apply_borderless(bool(settings.get("borderless", false)))
	_apply_vsync(bool(settings.get("vsync", true)))
	_apply_ui_scale(DISPLAY_UI_SCALE)

func get_ui_layout_scale() -> float:
	return LOGICAL_UI_SCALE

func get_ui_display_scale() -> float:
	return DISPLAY_UI_SCALE

func _apply_display_mode(mode_index: int) -> void:
	match mode_index:
		1:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
		2:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		_:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _apply_resolution(resolution_text: String) -> void:
	var parts: PackedStringArray = resolution_text.split("x")
	if parts.size() != 2:
		return
	var width: int = int(parts[0])
	var height: int = int(parts[1])
	if width <= 0 or height <= 0:
		return
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
		get_window().size = Vector2i(width, height)

func _apply_borderless(enabled: bool) -> void:
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, enabled)

func _apply_vsync(enabled: bool) -> void:
	var mode: DisplayServer.VSyncMode = DisplayServer.VSYNC_ENABLED if enabled else DisplayServer.VSYNC_DISABLED
	DisplayServer.window_set_vsync_mode(mode)

func _apply_ui_scale(scale_value: float) -> void:
	var root: Window = get_tree().root
	root.content_scale_factor = max(0.75, scale_value)
