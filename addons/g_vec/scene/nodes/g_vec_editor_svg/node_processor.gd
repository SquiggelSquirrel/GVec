extends Object

const ARC_END := GVecPathSVG.SegmentType.ARC_END
const ARC_CENTER := GVecPathSVG.SegmentType.ARC_CENTER


static func process_nodes(editor_node: GVecEditorSVG) -> void:
	var nodes := editor_node.get_editor_handles()
	erase_missing_segments(editor_node)
	for node in nodes:
		process_node(editor_node, node)


static func erase_missing_segments(editor_node: GVecEditorSVG) -> void:
	var nodes := editor_node.get_editor_handles()
	var missing_start_point := bool(editor_node.get_start_handle() == null)
	if missing_start_point:
		for node in nodes:
			node.segment_index -= 1
	
	var missing_segments := range(0, editor_node.path.get_segment_count())
	for node in nodes:
		if node.property_name == "end_point":
			missing_segments.erase(node.segment_index)
	
	for node in nodes:
		for segment_index in missing_segments:
			if segment_index < node.segment_index:
				node.segment_index -= 1
	
	for node in nodes:
		if node.name.begins_with("End"):
			if node.segment_index == -1:
				node.segment_index = 0
				node.name = "Start"
				node.property_name = "start_point"
			else:
				node.name = "End" + String.num_int64(node.segment_index)
	
	missing_segments.reverse()
	for segment_index in missing_segments:
		# Get the start point before removing the first segment;
		# Set the start point on the new first segment after
		var start_point = editor_node.path.get_segment_property(0, "start_point")
		editor_node.path.remove_segment(segment_index)
		if segment_index == 0:
			editor_node.path.set_segment_property(0, "start_point", start_point)
	
	if missing_start_point:
		editor_node.path.remove_segment(0)


static func process_node(
		editor_node: GVecEditorSVG,
		node: GVecEditorHandle
		) -> void:
	var svg_path := editor_node.path
	var segment_index := node.segment_index
	var node_position := editor_node.to_local(node.global_position)
	var property := node.property_name
	
	if property == "start_point":
		if segment_index != 0:
			push_warning("Cannot set start point on non-start segment")
			return
		if svg_path.get_segment_count() > 0:
			svg_path.set_segment_property(0, "start_point", node_position)
		return
	
	if segment_index < 0:
		node.unmatched_property = true
		return
	
	if segment_index >= svg_path.get_segment_count():
		node.unmatched_property = true
		return
	
	node.unmatched_property = false
	
	var segment_type: int = \
			svg_path.get_segment_property(segment_index, "segment_type")
	match property:
		"end_point" when segment_type == ARC_CENTER:
			# NB. slightly hacky - calling "get_segment_property" for
			# "angle_parameter_to_point", which is a method,
			# not a property, but returns as a Callable
			# I guess that works for now?
			svg_path.set_segment_property(
					segment_index,
					"central_angle_parameter",
					svg_path.get_segment_property(
						segment_index,
						"angle_parameter_to_point"
						).call(
							editor_node.to_local(node.global_position)))
			node.global_position = editor_node.to_global(
					svg_path.get_segment_property(segment_index, "end_point"))
		"start_point", \
		"end_point", \
		"control_point", \
		"start_control_point", \
		"end_control_point":
			svg_path.set_segment_property(
					node.segment_index,
					property,
					editor_node.to_local(node.global_position))
		"ellipse_center":
			svg_path.set_segment_property(
					node.segment_index,
					"ellipse_rotation",
					node.global_rotation - editor_node.global_rotation
			)
			match segment_type:
				GVecPathSVG.SegmentType.ARC_END:
					node.global_position = editor_node.to_global(
							svg_path.get_segment_property(
								node.segment_index,
								"center"))
				GVecPathSVG.SegmentType.ARC_CENTER:
					svg_path.set_segment_property(
							node.segment_index,
							"center",
							editor_node.to_local(node.global_position))
		"radii":
			svg_path.set_segment_property(
					node.segment_index,
					"radii",
					node.position)
