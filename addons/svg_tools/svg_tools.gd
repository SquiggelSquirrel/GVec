@tool
extends EditorPlugin

## Provides GUI anchors and handles for editing a [PathShape2DSVG] resource
##
## This plugin allows [PathShape2DSVG] resources to be edited in the 2D viewport,
## provided that they are attached to a node that uses the
## "_svg_tools_path_property" meta tag to indicate which property holds the
## [PathShape2DSVG] resource, and that the edited node either is, or is descended from,
## a [Node2D] which can defined the [Transform2D] to use.
## It supports nested resources, provided that the wrapping resources also
## use an "_svg_tools_path_property" meta to indicate which property holds the
## [PathShape2DSVG] resource (or the next layer down of wrapping).

const SVG_PATH_PROPERTY_META := "_svg_tools_path_property"
const ANCHOR_INNER_RADIUS: float = 8.0
const ANCHOR_OUTER_RADIUS: float = 10.0
const ANCHOR_INNER_COLOR := Color.WHITE
const ANCHOR_OUTER_COLOR := Color.RED
const LINE_COLOR := Color.RED
const LINE_WIDTH: float = 1.0
const LINE_DASH_LENGTH: float = 5.0
var current_node: Node:
	set(value):
		if value == current_node:
			return
		_disconnect_if_able(
				current_node,
				"path_changed",
				_on_current_node_path_changed)
		current_node = value
		_connect_if_able(
				current_node,
				"path_changed",
				_on_current_node_path_changed)
		transform_root = _get_transform_root(current_node)
		_rebuild_svg_index_options()
		var new_path = _get_svg_path(current_node)
		if new_path is PathShape2DSVG:
			svg_path = new_path
		else:
			svg_path = null
var transform_root: Node2D
var svg_path: PathShape2DSVG:
	set(value):
		if value == svg_path:
			return
		_disconnect_if_able(svg_path, "changed", _on_path_changed)
		svg_path = value
		_connect_if_able(svg_path, "changed", _on_path_changed)
		add_mode_button.set_visible(svg_path != null)
var anchors :Array[Dictionary]
var drag_start_values := []
var draw_start_point := Vector2.INF
var path_has_changed := false
var add_mode_button := Button.new()
var svg_index_button := OptionButton.new()


# Virtual methods
func _enter_tree() -> void:
	add_mode_button.text = "Add Points"
	add_mode_button.toggle_mode = true
	add_control_to_container(
			EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, add_mode_button)
	add_mode_button.hide()
	add_control_to_container(
			EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, svg_index_button)
	svg_index_button.hide()
	svg_index_button.item_selected.connect(_on_svg_index_changed)


func _exit_tree() -> void:
	current_node = null
	drag_start_values = []
	draw_start_point = Vector2.INF
	svg_index_button.item_selected.disconnect(_on_svg_index_changed)
	remove_control_from_container(
			EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, svg_index_button)
	remove_control_from_container(
			EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, add_mode_button)


func _edit(object: Object) -> void:
	if _object_uses_editor(object):
		current_node = object
	else:
		current_node = null


func _handles(object: Object) -> bool:
	return _object_uses_editor(object)


func _make_visible(visible: bool):
	if ! visible:
		drag_start_values = []


func _forward_canvas_draw_over_viewport(viewport_control : Control) -> void:
	if svg_path == null:
		return

	var lines := []
	anchors.clear()
	if svg_path.segment_count == 0:
		return

	var transform :Transform2D = (
			transform_root.get_viewport_transform()
			* transform_root.get_canvas_transform()
			* transform_root.global_transform)

	var svg_start_point :Vector2 = (
			transform * svg_path.get_segment_start_point(0))
	_add_anchor(svg_start_point, 0, "start_point")
	for i in svg_path.segment_count:
		var start_point :Vector2 = (
				transform * svg_path.get_segment_start_point(i))
		var end_point :Vector2 = (
				transform * svg_path.get_segment_end_point(i))

		match svg_path.get_segment_type(i):
			PathShape2DSVG.SegmentType.LINE:
				_add_anchor(end_point, i, "end_point")
			PathShape2DSVG.SegmentType.QUADRATIC:
				var control_point :Vector2 = (
						transform *
						svg_path.get_quadratic_segment_control_point(i))
				lines.append({"from": start_point, "to": control_point})
				lines.append({"from": control_point, "to": end_point})
				_add_anchor(end_point, i, "end_point")
				_add_anchor(control_point, i, "control_point")

			PathShape2DSVG.SegmentType.CUBIC:
				# Search backwards for previous end point anchor, and add
				# a link to the start control point of this segment.
				# Abort if previous anchor was an arc central angle handle.
				for j in range(anchors.size() -1, -1, -1):
					if anchors[j].property_name == "central_angle_parameter":
						break
					if anchors[j].property_name == "end_point":
						anchors[j].handles.append({
							"segment_index": i,
							"property_name": "start_control_point",
						})
						break
				var start_control_point :Vector2 = (transform
						* svg_path.get_cubic_segment_start_control_point(i))
				var end_control_point :Vector2 = (transform
						* svg_path.get_cubic_segment_end_control_point(i))
				lines.append({"from": start_point, "to": start_control_point})
				lines.append({"from": end_point, "to": end_control_point})
				_add_anchor(end_point, i, "end_point", [{
					"segment_index": i,
					"property_name": "end_control_point",
				}])
				_add_anchor(start_control_point, i, "start_control_point")
				_add_anchor(end_control_point, i, "end_control_point")

			PathShape2DSVG.SegmentType.ARC:
				var center :Vector2 = (transform *
						svg_path.get_arc_segment_center(i))
				lines.append({"from": start_point, "to": center})
				lines.append({"from": end_point, "to": center})
				match svg_path.get_arc_segment_calc_mode(i):
					SVGSegmentArc.CalcMode.CENTER:
						_add_anchor(center, i, "center")
						_add_anchor(end_point, i, "central_angle_parameter")
					SVGSegmentArc.CalcMode.ENDPOINT:
						_add_anchor(end_point, i, "end_point")
						if (
								(start_point - center).angle_to(
										end_point - center)) > 2.0:
							var start_to_end := (
									end_point - start_point).normalized()
							var crossbar_direction := (
									start_to_end.orthogonal() * 10.0)
							var crossbar_start := center - (
									crossbar_direction * 0.5)
							var crossbar_end := (
									crossbar_start + crossbar_direction)
							lines.append({
								"from": crossbar_start,
								"to": crossbar_end,
							})

	for line in lines:
		viewport_control.draw_dashed_line(
				line.from,
				line.to,
				LINE_COLOR,
				LINE_WIDTH,
				LINE_DASH_LENGTH)

	for anchor in anchors:
		if anchor.property_name in ["start_point", "end_point"]:
			viewport_control.draw_circle(
					anchor.position, ANCHOR_OUTER_RADIUS, ANCHOR_OUTER_COLOR)
			viewport_control.draw_circle(
					anchor.position, ANCHOR_INNER_RADIUS, ANCHOR_INNER_COLOR)
		else:
			viewport_control.draw_rect(
					anchor.rect, ANCHOR_INNER_COLOR, true)
			viewport_control.draw_rect(
					anchor.rect, ANCHOR_OUTER_COLOR, false, 2.0)


func _forward_canvas_gui_input(event: InputEvent) -> bool:
	if svg_path == null:
		return false
	if svg_path.segment_count == 0 and ! add_mode_button.button_pressed:
		return false
	var is_dragging = bool(drag_start_values.size() > 0)
	var is_drawing = draw_start_point.is_finite()
	var is_click := false
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and ! is_dragging:
				if add_mode_button.button_pressed:
					return _draw_start(event.position)
				else:
					return _drag_start(event.position)
			elif is_dragging and ! event.pressed:
				return _drag_end(event.position)
			elif is_drawing and ! event.pressed:
				return _draw_end(event.position)
	elif event is InputEventMouseMotion:
		if is_dragging:
			_drag_anchor_to(event.position)
		elif is_drawing:
			_draw_to(event.position)
	return false


# Private Methods
func _object_uses_editor(object :Object) -> bool:
	if ! object is Node:
		return false
	if ! object.has_meta(SVG_PATH_PROPERTY_META):
		return false
	return true


func _get_svg_path(object :Object):
	var options = _get_svg_path_options(object)
	match options.size():
		0:
			return
		1:
			return options.values()[0]
		_:
			var index := svg_index_button.selected
			if index == -1:
				return
			var item := svg_index_button.get_item_text(index)
			return options[item]


func _get_svg_path_options(object: Object) -> Dictionary:
	if ! object is Object:
		return {}
	if ! object.has_meta(SVG_PATH_PROPERTY_META):
		return {}
	var property_name = object.get_meta(SVG_PATH_PROPERTY_META)
	var property = object.get(property_name)
	
	if property is Array:
		var dict := {}
		for i in property.size():
			var sub_object = property[i]
			if sub_object is PathShape2DSVG:
				dict[String.num_int64(i)] = sub_object
			else:
				var sub_options := _get_svg_path_options(sub_object)
				if sub_options.size() == 1:
					dict[String.num_int64(i)] = sub_options.values()[0]
				else:
					for key in sub_options:
						dict[String.num_int64(i) + "," + key] = sub_options[key]
		return dict
	
	if property is PathShape2DSVG:
		return {"": property}
	else:
		return _get_svg_path_options(property)


func _get_transform_root(object :Object):
	if object is Node2D:
		return object
	if object is Node:
		return _get_transform_root(object.get_parent())
	return null


func _add_anchor(
		position :Vector2,
		segment_index :int,
		property_name :String,
		handles := []
		) -> void:
	var properties := {
		"position": position,
		"rect": Rect2(
				position - Vector2.ONE * ANCHOR_OUTER_RADIUS,
				2.0 * Vector2.ONE * ANCHOR_OUTER_RADIUS),
		"segment_index": segment_index,
		"property_name": property_name,
		"handles": handles
	}
	anchors.append(properties)


func _anchor_at_position(position :Vector2) -> int:
	for i in range(anchors.size()-1, -1, -1):
		if anchors[i].rect.has_point(position):
			return i
	return -1


func _event_position_to_local(event_position : Vector2) -> Vector2:
	var transform :Transform2D = (
			transform_root.get_viewport_transform()
			* transform_root.get_canvas_transform()
			* transform_root.global_transform).affine_inverse()
	return transform * event_position


func _drag_start(event_position :Vector2) -> bool:
	var dragged_anchor_index = _anchor_at_position(event_position)
	if dragged_anchor_index == -1:
		return false
	var anchor = anchors[dragged_anchor_index]
	var anchor_start_value = svg_path.get_segment_property(
			anchor.segment_index, anchor.property_name)
	drag_start_values = [{
		"segment_index": anchor.segment_index,
		"property_name": anchor.property_name,
		"value": anchor_start_value,
		"offset": Vector2.ZERO,
	}]
	if anchor.property_name == "central_angle_parameter":
		anchor_start_value = svg_path.get_segment_end_point(
				anchor.segment_index)
	for handle in anchor.handles:
		var value: Vector2 = svg_path.get_segment_property(
				handle.segment_index, handle.property_name)
		drag_start_values.append({
			"segment_index": handle.segment_index,
			"property_name": handle.property_name,
			"value": value,
			"offset": value - anchor_start_value
		})
	return true


func _drag_end(event_position :Vector2) -> bool:
	if drag_start_values.size() == 0:
		return false
	var drag_end_position = _event_position_to_local(event_position)
	get_undo_redo().create_action(_drag_action_name())
	for start_value in drag_start_values:
		var new_value = drag_end_position + start_value.offset
		
		if start_value.property_name == "central_angle_parameter":
			var start_angle = svg_path.get_segment_property(
					start_value.segment_index, "start_angle_parameter")
			var end_angle = svg_path.get_arc_segment_angle_parameter_to_point(
					start_value.segment_index, new_value)
			var angle_delta = end_angle - start_angle
			var old_value = svg_path.get_segment_property(
					start_value.segment_index, "central_angle_parameter")
			new_value = wrapf(angle_delta, old_value - PI, old_value + PI)
		
		get_undo_redo().add_undo_method(
				svg_path,
				"set_segment_property",
				start_value.segment_index,
				start_value.property_name,
				start_value.value)
		get_undo_redo().add_do_method(
				svg_path,
				"set_segment_property",
				start_value.segment_index,
				start_value.property_name,
				new_value)
	get_undo_redo().commit_action()
	drag_start_values = []
	return true


func _drag_anchor_to(event_position :Vector2) -> void:
	if drag_start_values.size() == 0:
		return
	
	var drag_end_position = _event_position_to_local(event_position)
	for start_value in drag_start_values:
		var new_value = drag_end_position + start_value.offset
		
		if start_value.property_name == "central_angle_parameter":
			var start_angle = svg_path.get_segment_property(
					start_value.segment_index, "start_angle_parameter")
			var end_angle = svg_path.get_arc_segment_angle_parameter_to_point(
					start_value.segment_index, new_value)
			var angle_delta = end_angle - start_angle
			var old_value = svg_path.get_segment_property(
					start_value.segment_index, "central_angle_parameter")
			new_value = wrapf(angle_delta, old_value - PI, old_value + PI)
		
		svg_path.set_segment_property(
				start_value.segment_index,
				start_value.property_name,
				new_value)


func _drag_action_name() -> String:
	for start_value in drag_start_values:
		if start_value.offset == Vector2.ZERO:
			return "Move segment %d %s" % [
					start_value.segment_index, start_value.property_name]
	return "Move SVG points"


func _draw_start(event_position :Vector2) -> bool:
	var segment_type: int
	if svg_path.get_segment_count() > 0:
		segment_type = svg_path.get_segment_property(-1, "segment_type")
	else:
		segment_type = PathShape2DSVG.SegmentType.CUBIC
	draw_start_point = _event_position_to_local(event_position)
	svg_path.add_segment(segment_type, draw_start_point)
	return true


func _draw_to(event_position: Vector2) -> bool:
	if svg_path.segment_has_vector_out(-1):
		svg_path.set_segment_vector_out(-1, draw_start_point
				- _event_position_to_local(event_position))
	return true


func _draw_end(event_position: Vector2) -> bool:
	var segment_type: int
	if svg_path.get_segment_count() > 0:
		segment_type = svg_path.get_segment_property(-1, "segment_type")
	else:
		segment_type = PathShape2DSVG.SegmentType.CUBIC
	get_undo_redo().create_action("Add SVG Segment")
	get_undo_redo().add_undo_method(
			svg_path,
			"remove_segment")
	get_undo_redo().add_do_method(
			svg_path,
			"add_segment",
			segment_type,
			draw_start_point)
	if svg_path.segment_has_vector_out(-1):
		svg_path.set_segment_vector_out(-1, draw_start_point
				- _event_position_to_local(event_position))
		get_undo_redo().add_do_method(
				svg_path,
				"set_segment_vector_out",
				-1,
				draw_start_point - _event_position_to_local(event_position))
	get_undo_redo().commit_action(false)
	draw_start_point = Vector2.INF
	return true


func _on_current_node_path_changed() -> void:
	_rebuild_svg_index_options()
	svg_path = _get_svg_path(current_node)
	_on_path_changed()


func _on_path_changed() -> void:
	path_has_changed = true
	await get_tree().process_frame
	if path_has_changed:
		update_overlays()
		path_has_changed = false


func _on_svg_index_changed(_index :int) -> void:
	svg_path = _get_svg_path(current_node)
	_on_path_changed()


func _rebuild_svg_index_options() -> void:
	svg_index_button.clear()
	var options = _get_svg_path_options(current_node)
	if options.size() > 1:
		for key in options:
			svg_index_button.add_item(key)
		svg_index_button.show()
		svg_index_button.select(0)
	else:
		svg_index_button.hide()


static func _connect_if_able(nullable_object, signal_name, callable):
	if nullable_object == null:
		return
	if ! nullable_object.has_signal(signal_name):
		return
	if nullable_object.is_connected(signal_name, callable):
		return
	nullable_object.connect(signal_name, callable)


static func _disconnect_if_able(nullable_object, signal_name, callable):
	if nullable_object == null:
		return
	if ! nullable_object.has_signal(signal_name):
		return
	if ! nullable_object.is_connected(signal_name, callable):
		return
	nullable_object.disconnect(signal_name, callable)
