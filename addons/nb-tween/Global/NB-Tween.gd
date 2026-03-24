extends Node

var tweens : Array[Tween]

func create_one_shot_tween_property(caller : Object, tween_property : NodePath, to : Variant, length : float, transition_type : Tween.TransitionType = Tween.TRANS_LINEAR) -> void:
	var tween = _add_new_tween()
	if caller is Node:
		tween.bind_node(caller)
	if typeof(caller.get(str(tween_property))) != typeof(to):
		return

	tween.tween_property(caller, tween_property, to, length).set_trans(transition_type)
	
	await tween.finished
	_remove_tween(tween)
	return

func create_tween_and_tween_property(caller : Object, tween_property : NodePath, to : Variant, length : float, transition_type : Tween.TransitionType = Tween.TRANS_LINEAR) -> Tween:
	var tween = _add_new_tween()
	if caller is Node:
		tween.bind_node(caller)
	if !caller.get(str(tween_property)) || typeof(caller.get(str(tween_property))) != typeof(to):
		return null
	
	tween.tween_property(caller, tween_property, to, length).set_trans(transition_type)
	
	return tween

func _add_new_tween() -> Tween:
	var tween = create_tween()
	tweens.append(tween)
	return tween

func _remove_tween(in_tween : Tween) -> void:
	if in_tween.is_running() : in_tween.pause()
	if in_tween : in_tween.kill()
	if tweens.has(in_tween) : tweens.erase(in_tween)
	return

func get_all_tweens() -> Array[Tween]:
	return tweens

func clear_tweens() -> void:
	if !tweens.any(is_running) :
		tweens.clear()
	return

func is_running(tween : Tween) -> bool:
	return tween.is_running()
