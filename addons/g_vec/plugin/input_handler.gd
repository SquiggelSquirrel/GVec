extends Object

const METHOD_ADD_SEGMENT = &"add_segment"
const METHOD_REMOVE_SEGMENT = &"remove_segment"
const PROPERTY_HANDLE_OUT = &"handle_out"
var adding := false
var handle_out: Vector2


func input(plugin: GVecPlugin, event: InputEvent) -> bool:
	if plugin.menu_controls.get_node("Add").button_pressed == false:
		return false
	
	var position := Vector2.ZERO
	if event is InputEventMouse:
		position = event_position_to_node_local(event, plugin.editor_node)
	
	if ! adding:
		if ! (event is InputEventMouseButton
				and event.button_index == MOUSE_BUTTON_LEFT
				and event.is_pressed()):
			return false
		if handle_out == null or ! handle_out.is_finite():
			handle_out = plugin.editor_node.path.get_vector_out()
		plugin.undo_redo.create_action(
				"Add Cubic Segment", UndoRedo.MERGE_DISABLE)
		plugin.undo_redo.add_do_method(
				plugin.editor_node,
				METHOD_ADD_SEGMENT,
				GVecPathSVG.SegmentType.CUBIC,
				position,
				handle_out)
		plugin.undo_redo.add_undo_method(
				plugin.editor_node,
				METHOD_REMOVE_SEGMENT)
		plugin.undo_redo.add_undo_property(
				self,
				PROPERTY_HANDLE_OUT,
				handle_out)
		plugin.editor_node.add_segment(
				GVecPathSVG.SegmentType.CUBIC,
				position,
				handle_out)
	else:
		if ! Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			end_action_add(plugin)
			return true
		
		if event is InputEventMouseMotion:
			handle_out = position
			var end_point := plugin.editor_node.get_end_point()
			end_point.look_at(handle_out)
			var mirror_handle = end_point.get_node_or_null("HandleIn")
			if mirror_handle is GVecEditorPoint:
				mirror_handle.position = Vector2(
						-1.0 * (handle_out - end_point.position).length(),
						0.0)
	return true


func end_action_add(plugin: GVecPlugin) -> void:
	adding = false
	plugin.undo_redo.add_do_property(
			self,
			PROPERTY_HANDLE_OUT,
			handle_out)
	plugin.undo_redo.commit_action(false)


func event_position_to_node_local(
		event: InputEventMouse,
		node: Node2D
		) -> Vector2:
	return node.to_local(
			node.get_viewport().get_global_canvas_transform().affine_inverse()
			* (event.position as Vector2))
