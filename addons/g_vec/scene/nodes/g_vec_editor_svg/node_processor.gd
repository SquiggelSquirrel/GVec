extends Object

const ARC_END := GVecPathSVG.SegmentType.ARC_END
const ARC_CENTER := GVecPathSVG.SegmentType.ARC_CENTER


static func process_nodes(editor_node: GVecEditorSVG) -> void:
	var missing_segments := range(0, editor_node.path.get_segment_count())
	
	var nodes := editor_node.get_editor_points() 
	for node in nodes:
		if node.property_name == "end_point":
			missing_segments.erase(node.segment_index)
		process_node(editor_node, node)
	
	missing_segments.reverse()
	
	var missing_start_point := bool(editor_node.get_start_point() == null)
	for node in nodes:
		for segment_index in missing_segments:
			if segment_index < node.segment_index:
				node.segment_index -= 1
		if missing_start_point:
			node.segment_index -= 1
		if node.name.begins_with("End"):
			if node.segment_index == -1:
				node.name = "Start"
				node.property_name = "start_point"
			else:
				node.name = "End" + String.num_int64(node.segment_index)
	
	for segment_index in missing_segments:
		var start_point = editor_node.path.get_segment_property(0, "start_point")
		editor_node.path.remove_segment(segment_index)
		if segment_index == 0:
			editor_node.path.set_segment_property(0, "start_point", start_point)
	
	if missing_start_point:
		editor_node.path.remove_segment(0)


static func process_node(
		editor_node: GVecEditorSVG,
		node: GVecEditorPoint
		) -> void:
	var path := editor_node.path
	var segment_index := node.segment_index
	if node.property_name == "start_point":
		if segment_index > 0:
			push_warning("Cannot set start point on non-start segment")
			return
		if path.get_segment_count() == 0:
			return
	var segment_type: int = \
			path.get_segment_property(segment_index, "segment_type")
	match node.property_name:
		"end_point" when segment_type == ARC_CENTER:
			# NB. slightly hacky - "angle_parameter_to_point" is a method,
			# not a property, but returns as a Callable
			# I guess that works for now?
			path.set_segment_property(
					segment_index,
					"central_angle_parameter",
					path.get_segment_property(
						segment_index,
						"angle_parameter_to_point"
						).call(
							editor_node.to_local(node.global_position)))
			node.global_position = editor_node.to_global(
					path.get_segment_property(segment_index, "end_point"))
		"start_point", \
		"end_point", \
		"control_point", \
		"start_control_point", \
		"end_control_point":
			path.set_segment_property(
					node.segment_index,
					node.property_name,
					editor_node.to_local(node.global_position))
		"ellipse_center":
			path.set_segment_property(
					node.segment_index,
					"ellipse_rotation",
					node.global_rotation - editor_node.global_rotation
			)
			match segment_type:
				GVecPathSVG.SegmentType.ARC_END:
					node.global_position = editor_node.to_global(
							path.get_segment_property(
								node.segment_index,
								"center"))
				GVecPathSVG.SegmentType.ARC_CENTER:
					path.set_segment_property(
							node.segment_index,
							"center",
							editor_node.to_local(node.global_position))
		"radii":
			path.set_segment_property(
					node.segment_index,
					"radii",
					node.position)
