@tool
class_name GVecTools
extends EditorPlugin

## Provides GUI anchors and handles for editing a [GVecPathSVG] resource
##
## This plugin allows [GVecPathSVG] resources to be edited in the 2D viewport,
## provided that they are attached to a node that uses the
## "_svg_tools_path_property" meta tag to indicate which property holds the
## [GVecPathSVG] resource, and that the edited node either is, or is descended from,
## a [Node2D] which can defined the [Transform2D] to use.
## It supports nested resources, provided that the wrapping resources also
## use an "_svg_tools_path_property" meta to indicate which property holds the
## [GVecPathSVG] resource (or the next layer down of wrapping).
const PANEL_SCENE := preload(
		"res://addons/g_vec/scene/g_vec_tools_controls_panel.tscn")
var target: GVecToolsTarget
var target_has_unprocessed_changes := false
var overlay: GVecToolsOverlay
var controls: Control


# Virtual methods
func _enter_tree() -> void:
	controls = PANEL_SCENE.instantiate()
	add_control_to_container(
			EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, controls)
	controls.load_button_icons(self)
	controls.action.connect(_forward_action)
	
	overlay = GVecToolsOverlay.new()
	
	target = GVecToolsTarget.new()
	target.changed.connect(_on_target_changed)
	target.structure_changed.connect(_on_target_structure_changed)
	target.focus_changed.connect(_on_target_focus_changed)


func _exit_tree() -> void:
	remove_control_from_container(
			EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, controls)
	controls.queue_free()
	controls = null
	
	target.destroy()
	target = null
	
	overlay.destroy()
	overlay = null


func _edit(object: Object) -> void:
	target.edit(object)


func _handles(object: Object) -> bool:
	return target.handles(object)


func _make_visible(visible: bool) -> void:
	controls.visible = visible
	overlay.make_visible(visible)


func _forward_canvas_draw_over_viewport(viewport_control: Control) -> void:
	if target.root_path == null:
		return
	overlay.update_transforms(target.get_active_shapes())
	overlay.forward_draw(viewport_control)


func _forward_canvas_gui_input(event: InputEvent) -> bool:
	if target.root_path == null:
		return false
	return overlay.forward_input(
			event,
			controls.get_state(),
			controls.get_options(),
			get_undo_redo())


func _forward_action(action: String) -> void:
	overlay.forward_action(
			action,
			controls.get_options(),
			get_undo_redo())


func _on_target_structure_changed() -> void:
	var shapes := target.get_active_shapes()
	overlay.update_shapes(shapes)
	controls.edit_shapes(shapes)


func _on_target_focus_changed() -> void:
	var shapes := target.get_active_shapes()
	overlay.update_shapes(shapes)
	controls.edit_shapes(shapes)


func _on_target_changed() -> void:
	target_has_unprocessed_changes = true
	await get_tree().process_frame
	if target_has_unprocessed_changes:
		update_overlays()
		target_has_unprocessed_changes = false
