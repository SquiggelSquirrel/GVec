@tool
class_name GVecToolsHandlesSVG
extends GVecToolsHandles

enum State {
	ADD, ADDING_START_POINT, ADDING_SEGMENT,
	ADD_WITH_INCOMPLETE_START,
	CURVE, DELETE, EDIT
}

var _is_dragging := false
var _drag_anchor: GVecToolsAnchor
var _unconfirmed_start_point: Vector2
var _uncomfirmed_control_in: Vector2


func _init(init_shape: GVecPathSVG = GVecPathSVG.new()) -> void:
	super(init_shape)
	shape.segments_changed.connect(_on_segments_changed)


func forward_action(
		action: String,
		options: Dictionary,
		undo_redo: EditorUndoRedoManager) -> void:
	if action == "Close":
		_close_shape(options, undo_redo)
	else:
		super(action, options, undo_redo)


func forward_input(
		event: InputEvent,
		state: String,
		options: Dictionary,
		undo_redo: EditorUndoRedoManager
		) -> bool:
	if _is_dragging:
		_forward_drag(event, options, undo_redo)
		return true
		
	if ! event is InputEventMouseButton:
		return false
	if ! event.is_pressed():
		return false
	
	match state:
		"Edit":
			if event.button_index == MOUSE_BUTTON_RIGHT:
				return _forward_input_delete(event, options, undo_redo)
			if event.button_index != MOUSE_BUTTON_LEFT:
				return false
			if Input.is_key_pressed(KEY_CTRL):
				return _forward_input_add(event, options, undo_redo)
			if Input.is_key_pressed(KEY_SHIFT):
				return _forward_input_curve(event, options, undo_redo)
			return _forward_input_edit(event, options, undo_redo)
		"Curve":
			if event.button_index != MOUSE_BUTTON_LEFT:
				return false
			return _forward_input_curve(event, options, undo_redo)
		"Add":
			if event.button_index != MOUSE_BUTTON_LEFT:
				return false
			return _forward_input_add(event, options, undo_redo)
		"Delete":
			if event.button_index != MOUSE_BUTTON_LEFT:
				return false
			return _forward_input_delete(event, options, undo_redo)
	return false


func _forward_drag(
		event: InputEvent,
		options: Dictionary,
		undo_redo: EditorUndoRedoManager) -> void:
	pass


func _forward_input_add(
		event: InputEvent,
		options: Dictionary,
		undo_redo: EditorUndoRedoManager) -> bool:
	if shape.segment_count == 0:
		var local_position := _local_position(event)
		_unconfirmed_start_point = local_position
		_uncomfirmed_control_in = local_position
		return true
	var old_count = shape.segment_count
	shape.segment_count = old_count + 1
	shape.set_segment_property(
			old_count,
			"segment_type",
			GVecPathSVG.SegmentType.CUBIC)
	return true


func _forward_input_curve(
		event: InputEvent,
		options: Dictionary,
		undo_redo: EditorUndoRedoManager) -> bool:
	return false


func _forward_input_delete(
		event: InputEvent,
		options: Dictionary,
		undo_redo: EditorUndoRedoManager) -> bool:
	if ! event is InputEventMouseButton:
		return false
	if event.button_index != MOUSE_BUTTON_LEFT:
		return false
	var local_position := transform * (event.get('position') as Vector2)
	for anchor in anchors:
		if anchor.has_point(local_position):
			_delete_point(
					anchor.key.segment,
					anchor.key.property,
					options,
					undo_redo)
			return true
	return false


func _forward_input_edit(
		event: InputEvent,
		options: Dictionary,
		undo_redo: EditorUndoRedoManager) -> bool:
	return false


func _new_point_end_drag(
		event: InputEvent,
		options: Dictionary,
		undo_redo: EditorUndoRedoManager) -> void:
	pass


func _local_position(event: InputEventMouse) -> Vector2:
	return transform * event.position


func _on_segments_changed() -> void:
	anchors.clear()
	var previous_anchor := _add_svg_anchor(
			0, "start_point", GVecToolsAnchor.AnchorShape.SQUARE)
	var previous_point := previous_anchor.position
	for i in shape.get_segment_count():
		var type := _get_segment_property(i, "segment_type") as int
		match type:
			GVecPathSVG.SegmentType.LINE:
				previous_anchor = _add_line(i, previous_point)
			GVecPathSVG.SegmentType.QUADRATIC:
				previous_anchor = _add_quadratic(i, previous_point)
			GVecPathSVG.SegmentType.CUBIC:
				previous_anchor = _add_cubic(
						i, previous_point, previous_anchor)
			GVecPathSVG.SegmentType.ARC_CENTER:
				previous_anchor = _add_arc_from_center(i, previous_point)
			GVecPathSVG.SegmentType.ARC_END:
				previous_anchor = _add_arc_from_endpoint(i, previous_point)
		previous_point = previous_anchor.position
		if type == GVecPathSVG.SegmentType.ARC_CENTER:
			previous_anchor = null


func _add_line(i: int, start_point: Vector2) -> GVecToolsAnchor:
	var end_anchor := _add_svg_anchor(
			i, "end_point", GVecToolsAnchor.AnchorShape.SQUARE)
	var end_point = end_anchor.position
	guides.append(GVecToolsGuide.new(start_point, end_point))
	return end_anchor


func _add_quadratic(i: int, start_point: Vector2) -> GVecToolsAnchor:
	var control_anchor := _add_svg_anchor(
			i, "control_point", GVecToolsAnchor.AnchorShape.CIRCLE)
	var end_anchor := _add_svg_anchor(
			i, "end_point", GVecToolsAnchor.AnchorShape.SQUARE)
	var control_point := control_anchor.position
	var end_point := end_anchor.position
	guides.append(GVecToolsGuide.new(start_point, control_point))
	guides.append(GVecToolsGuide.new(control_point, end_point))
	return end_anchor


func _add_cubic(
		i: int, start_point: Vector2, previous_anchor
) -> GVecToolsAnchor:
	var start_control_anchor := _add_svg_anchor(
			i, "start_control_point", GVecToolsAnchor.AnchorShape.CIRCLE)
	if previous_anchor is GVecToolsAnchor:
		previous_anchor.linked_anchors.append(start_control_anchor)
	var end_control_anchor := _add_svg_anchor(
			i, "end_control_point", GVecToolsAnchor.AnchorShape.CIRCLE)
	var end_anchor := _add_svg_anchor(
			i, "end_point", GVecToolsAnchor.AnchorShape.SQUARE)
	end_anchor.linked_anchors.append(end_control_anchor)
	var start_control_point := start_control_anchor.position
	var end_control_point := end_control_anchor.position
	var end_point := end_anchor.position
	guides.append(GVecToolsGuide.new(start_point, start_control_point))
	guides.append(GVecToolsGuide.new(end_control_point, end_point))
	return end_anchor


func _add_arc_from_center(i: int, start_point: Vector2) -> GVecToolsAnchor:
	_add_svg_anchor(i, "center", GVecToolsAnchor.AnchorShape.SQUARE)
	return _add_svg_anchor(i, "end_point", GVecToolsAnchor.AnchorShape.CIRCLE)


func _add_arc_from_endpoint(i: int, start_point: Vector2) -> GVecToolsAnchor:
	return _add_svg_anchor(i, "end_point", GVecToolsAnchor.AnchorShape.CIRCLE)


func _get_segment_property(i: int, name: String):
	name = GVecPathSVG.segment_property_to_name(i, name)
	return shape.get(name)


func _add_svg_anchor(
		i: int,
		name: String,
		anchor_shape: GVecToolsAnchor.AnchorShape
		) -> GVecToolsAnchor:
	var point := shape.get(name) as Vector2
	return _add_anchor(point, {
		"property" = name,
		"segment" = i
	}, anchor_shape)


func _delete_point(
		segment_index: int,
		point_name: String,
		options: Dictionary,
		undo_redo: EditorUndoRedoManager
		) -> void:
	undo_redo.create_action("Delete Point")
	
	undo_redo.add_undo_method(shape, "insert_segment", segment_index)
	for property in shape.get_segment_property_list(segment_index):
		var value = shape.get(property.name)
		undo_redo.add_undo_property(shape, property.name, value)
	
	undo_redo.add_do_method(shape, "remove_segment", segment_index)
	if segment_index == 0 and point_name == "end_point":
		undo_redo.add_do_property(
				shape,
				GVecPathSVG.segment_property_to_name(0, "start_point"),
				shape.get_segment_property(0, "start_point"))
	
	undo_redo.commit_action()


func _close_shape(
		options: Dictionary,
		undo_redo: EditorUndoRedoManager) -> void:
	if shape.is_closed():
		return
	var end_point = shape.get_segment_property(0, "start_point")
	var count := (shape as GVecPathSVG).segment_count as int
	
	undo_redo.create_action("Close Shape")
	undo_redo.add_do_property(shape, "segment_count", count + 1)
	undo_redo.add_undo_property(shape, "segment_count", count)
	
	var end_point_name = GVecPathSVG.segment_property_to_name(
			count, "end_point")
	undo_redo.add_do_property(shape, end_point_name, end_point)
	
	undo_redo.commit_action()
