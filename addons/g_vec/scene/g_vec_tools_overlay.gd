@tool
class_name GVecToolsOverlay
extends RefCounted

var handles: Array[GVecToolsHandles] = []
var shapes: Array[Dictionary]


func forward_draw(viewport: Control) -> void:
	var lines := []
	for handle in handles:
		handle.forward_draw(viewport)


func forward_input(
		event: InputEvent,
		state: String,
		options: Dictionary,
		undo_redo: EditorUndoRedoManager) -> bool:
	for handle in handles:
		var handled := handle.forward_input(event, state, options, undo_redo)
		if handled:
			return true
	return false


func forward_action(
		action: String,
		options: Dictionary,
		undo_redo: EditorUndoRedoManager) -> void:
	handles[0].forward_action(action, options, undo_redo)


func update_shapes(shapes_with_transforms: Array[Dictionary]) -> void:
	handles.clear()
	for shape_with_transform in shapes_with_transforms:
		var shape := shape_with_transform.path as GVecPath
		handles.append(_new_handle(shape))


func update_transforms(shapes_with_transforms: Array[Dictionary]) -> void:
	for i in shapes_with_transforms.size():
		var transform := shapes_with_transforms[i].transform as Transform2D
		handles[i].transform = transform


func _new_handle(shape: GVecPath) -> GVecToolsHandles:
	if shape is GVecPathSVG:
		return GVecToolsHandlesSVG.new(shape)
	return GVecToolsHandles.new(shape)


func set_state_and_options(state_and_options: Dictionary) -> void:
	for handle in handles:
		handle.set_state_and_options(state_and_options)
