@tool
extends EditorPlugin

const AUTOLOAD_NAME := "InputController"
const CUSTOM_TYPE_NAME := "Draggable"


func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	add_autoload_singleton(AUTOLOAD_NAME, "InputController.tscn")
	add_custom_type(CUSTOM_TYPE_NAME, "Area3D", preload("draggable.gd"), _get_plugin_icon())


func _exit_tree() -> void:
	remove_autoload_singleton(AUTOLOAD_NAME)
	remove_custom_type(CUSTOM_TYPE_NAME)


func _get_plugin_icon () -> Texture2D:
	return EditorInterface.get_editor_theme().get_icon("Area3D", "EditorIcons")
