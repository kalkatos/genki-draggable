@tool
## Editor plugin script for registering the Draggable custom type and its InputController singleton.
extends EditorPlugin

const AUTOLOAD_NAME := "InputController"
const CUSTOM_TYPE_NAME := "Draggable"


## Called when the plugin is enabled; registers the InputController autoload and Draggable custom type.
func _enter_tree () -> void:
	# Initialization of the plugin goes here.
	add_autoload_singleton(AUTOLOAD_NAME, "InputController.tscn")
	add_custom_type(CUSTOM_TYPE_NAME, "Area3D", preload("draggable.gd"), _get_plugin_icon())


## Called when the plugin is disabled; removes registered types and singletons.
func _exit_tree () -> void:
	remove_autoload_singleton(AUTOLOAD_NAME)
	remove_custom_type(CUSTOM_TYPE_NAME)


## Returns the icon used for the Draggable custom type in the editor.
func _get_plugin_icon () -> Texture2D:
	return EditorInterface.get_editor_theme().get_icon("Area3D", "EditorIcons")
