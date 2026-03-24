@abstract class_name SerializableNode extends Node

@export_category("Serialization")
@export_group("Property Lists")
@export var excluded_properties : Array[StringName]
@export var partial_properties : Array[StringName]

func _get_excluded_properties() -> Array[StringName]:
	return excluded_properties

func _get_partial_properties() -> Array[StringName]:
	return partial_properties

func _register_self() -> void:
	ObjectSerializer.register_script(get_script().get_global_name(), get_script())

func _init() -> void:
	_register_self()

func _save(save_data : Object) -> void:
	var saved_data = AnotherSerializer.serialize_var(save_data)
	print(saved_data)
	return
