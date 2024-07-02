extends Object

const METHOD_ADD_SEGMENT = &"add_segment"
const METHOD_REMOVE_SEGMENT = &"remove_segment"
const PROPERTY_HANDLE_OUT = &"handle_out"
var adding := false
var start_position: Vector2
var start_handle_out: Vector2
var handle_out: Vector2
var handle_in: Vector2
var type: int


func input(plugin: GVecPlugin, event: InputEvent) -> bool:
	if plugin.menu_controls.get_is_add_checked() == false:
		return false
	
	var position := Vector2.ZERO
	if event is InputEventMouse:
		position = event_position_to_node_local(event, plugin.editor_node)
	
	if ! adding:
		if ! (event is InputEventMouseButton
				and event.button_index == MOUSE_BUTTON_LEFT
				and event.is_pressed()):
			return false
		print("Mouse down")
		if handle_out == null or ! handle_out.is_finite():
			handle_out = plugin.editor_node.path.get_vector_out()
		adding = true
		type = plugin.menu_controls.get_add_type()
		start_handle_out = handle_out
		start_position = position
		handle_in = position
		plugin.editor_node.add_segment(
				type,
				position,
				handle_out,
				handle_in,
				plugin.editor_node.get_path_to(
					node_get_non_handle_ancestor(plugin.selected_node)))
		return true
	
	if ! Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		print("Mouse up")
		end_action_add(plugin)
		return true
	
	if event is InputEventMouseMotion:
		print("Mouse move")
		handle_out = position
		if plugin.menu_controls.get_mirror_angles():
			var offset_out := handle_out - start_position
			if plugin.menu_controls.get_mirror_lengths():
				handle_in = start_position - offset_out
			else:
				var offset_in := handle_in - start_position
				offset_in = Vector2(
						-offset_in.length(),
						0
						).rotated(offset_out.angle())
				handle_in = start_position + offset_in
		
		plugin.editor_node.set_end_control_point(handle_in)
		return true
	
	return false


func end_action_add(plugin: GVecPlugin) -> void:
	adding = false
	plugin.undo_redo.create_action("Add Cubic Segment", UndoRedo.MERGE_DISABLE)
	
	plugin.undo_redo.add_undo_method(
			plugin.editor_node,
			METHOD_REMOVE_SEGMENT)
	plugin.undo_redo.add_undo_property(
			self,
			PROPERTY_HANDLE_OUT,
			start_handle_out)
	
	plugin.undo_redo.add_do_method(
			plugin.editor_node,
			METHOD_ADD_SEGMENT,
			type,
			start_position,
			start_handle_out,
			handle_in,
			plugin.editor_node.get_path_to(
				node_get_non_handle_ancestor(plugin.selected_node)))
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


func node_get_non_handle_ancestor(node: Node2D) -> Node2D:
	while node is GVecEditorHandle:
		node = node.parent()
	return node
