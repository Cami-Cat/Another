@tool
extends EditorPlugin

const AUTOLOAD_PATH = "res://addons/nb-tween/Global/NB-Tween.gd"
const AUTOLOAD_NAME = "NBTween"

func _enable_plugin() -> void:
	add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)
	pass


func _disable_plugin() -> void:
	remove_autoload_singleton(AUTOLOAD_NAME)
	pass
