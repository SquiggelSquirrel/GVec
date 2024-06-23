@tool
class_name GVecPlugin
extends EditorPlugin

const MenuControls := preload("menu.tscn")
const InputHandler := preload("input_handler.gd")
var menu_controls: HBoxContainer
var input_handler := InputHandler.new()
var editor_node: GVecEditorSVG
var undo_redo: EditorUndoRedoManager
var adding := false
var latest_point: GVecEditorPoint
var handle_out := Vector2.INF


# ==============================================================================
# Virtual methods

# Called when the node enters the scene tree
# (use for plugin intialisation)
func _enter_tree() -> void:
	undo_redo = get_undo_redo()
	menu_controls = MenuControls.instantiate()
	add_control_to_container(
			EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, menu_controls)


# Called when the node exists the scene tree
# (use for plugin cleanup)
func _exit_tree() -> void:
	if input_handler.adding:
		input_handler.end_action_add(self)
	undo_redo = null
	remove_control_from_container(
			EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, menu_controls)
	menu_controls.queue_free()
	menu_controls = null


# Called when attempting to edit the given object - or null if object deselected
# Pass to the target manager and listen for signals to determine any additional
# action required
func _edit(object: Object) -> void:
	editor_node = object
	if editor_node == null and input_handler.adding:
		input_handler.end_action_add(self)


# Called to test if plugin handles the supplied object - pass to target
# manager to perform this test
func _handles(object: Object) -> bool:
	return object is GVecEditorSVG


# Called when this plugin is requested to become visible
# Mange menu controls and overlay visible
func _make_visible(visible: bool) -> void:
	menu_controls.visible = visible


# Called for GUI input when editing an object - return true if event should
# be consumed, false if event should be passed on for other editors to handle
# (forward event to overlay for handling)
func _forward_canvas_gui_input(event: InputEvent) -> bool:
	return input_handler.input(self, event)
