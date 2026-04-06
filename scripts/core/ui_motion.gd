class_name UIMotion
extends RefCounted

static func reveal(control: Control, delay: float = 0.0, offset: Vector2 = Vector2(0, 26), duration: float = 0.32, start_scale: Vector2 = Vector2(0.98, 0.98)) -> Tween:
	var tween: Tween = control.create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var original_position: Vector2 = control.position
	control.position = original_position + offset
	control.modulate.a = 0.0
	control.scale = start_scale
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.set_parallel(true)
	tween.tween_property(control, "position", original_position, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "modulate:a", 1.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "scale", Vector2.ONE, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return tween

static func pulse(control: Control, press_scale: float = 0.94, rebound_scale: float = 1.02, duration: float = 0.08) -> Tween:
	var tween: Tween = control.create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(control, "scale", Vector2.ONE * press_scale, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "scale", Vector2.ONE * rebound_scale, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "scale", Vector2.ONE, duration * 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	return tween
