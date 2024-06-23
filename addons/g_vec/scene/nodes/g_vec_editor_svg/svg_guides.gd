extends Object


static func draw_guides(path: GVecPathSVG, canvas_item: CanvasItem) -> void:
	var zoom := canvas_item.get_viewport_transform().get_scale()
	var scaled_radius = Vector2(5.0, 5.0) / zoom
	canvas_item.draw_polyline(path.get_baked_points(), Color.LIGHT_CORAL, 1)
	canvas_item.draw_multiline(get_handle_lines(path), Color.DIM_GRAY, 1)
	for knot in get_knots(path):
		var rect := Rect2(knot - scaled_radius, scaled_radius * 2.0)
		canvas_item.draw_rect(rect, Color.WHITE, true)
		canvas_item.draw_rect(rect, Color.BLACK, false, -1.0)
	for handle in get_handles(path):
		canvas_item.draw_circle(handle, scaled_radius.x, Color.BLACK)
		canvas_item.draw_circle(handle, scaled_radius.x * 0.8, Color.WHITE)


static func get_knots(path: GVecPathSVG) -> PackedVector2Array:
	var knots := [] as PackedVector2Array
	if path.get_segment_count() > 0:
		knots.append(path.get_segment_property(0, "start_point"))
	for index in path.get_segment_count():
		knots.append(path.get_segment_property(index, "end_point"))
	return knots


static func get_handles(path: GVecPathSVG) -> PackedVector2Array:
	var handles := [] as PackedVector2Array
	for index in path.get_segment_count():
		match path.get_segment_property(index, "segment_type"):
			GVecPathSVG.SegmentType.QUADRATIC:
				handles.append(
						path.get_segment_property(index, "control_point"))
			GVecPathSVG.SegmentType.CUBIC:
				handles.append(
						path.get_segment_property(index, "start_control_point"))
				handles.append(
						path.get_segment_property(index, "end_control_point"))
	return handles


static func get_handle_lines(path: GVecPathSVG) -> PackedVector2Array:
	var handle_lines := [] as PackedVector2Array
	for index in path.get_segment_count():
		match path.get_segment_property(index, "segment_type"):
			GVecPathSVG.SegmentType.QUADRATIC:
				handle_lines.append_array([
					path.get_segment_property(index, "start_point"),
					path.get_segment_property(index, "control_point")
				])
				handle_lines.append_array([
					path.get_segment_property(index, "control_point"),
					path.get_segment_property(index, "end_point")
				])
			GVecPathSVG.SegmentType.CUBIC:
				handle_lines.append_array([
					path.get_segment_property(index, "start_point"),
					path.get_segment_property(index, "start_control_point")
				])
				handle_lines.append_array([
					path.get_segment_property(index, "end_control_point"),
					path.get_segment_property(index, "end_point")
				])
	return handle_lines
