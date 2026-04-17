extends CanvasLayer

const FADE_IN_TIME: float = 0.20
const FADE_OUT_TIME: float = 0.26

var overlay: ColorRect
var is_transitioning: bool = false
var queued_scene: String = ""

func _ready() -> void:
	layer = 200
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_overlay()

func _ensure_overlay() -> void:
	if overlay != null and is_instance_valid(overlay):
		return
	overlay = ColorRect.new()
	overlay.name = "SceneFade"
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.color = Color(0.02, 0.03, 0.05, 0.0)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

func transition_to(path: String) -> void:
	if path.is_empty():
		return
	if is_transitioning:
		queued_scene = path
		return
	_run_transition(path)

func _run_transition(path: String) -> void:
	is_transitioning = true
	queued_scene = ""
	_ensure_overlay()
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var fade_in: Tween = _make_transition_tween()
	fade_in.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade_in.tween_property(overlay, "color:a", 1.0, FADE_IN_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await fade_in.finished
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	var fade_out: Tween = _make_transition_tween()
	fade_out.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade_out.tween_property(overlay, "color:a", 0.0, FADE_OUT_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await fade_out.finished
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	is_transitioning = false
	if not queued_scene.is_empty():
		var next_scene: String = queued_scene
		queued_scene = ""
		_run_transition(next_scene)

func _make_transition_tween() -> Tween:
	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tree_exiting.connect(func() -> void:
		if tween != null:
			tween.kill()
	, CONNECT_ONE_SHOT)
	return tween
