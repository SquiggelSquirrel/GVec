@tool
class_name GVecEditorSVG
extends Node2D

const NodeProcessor := preload("g_vec_editor_svg/node_processor.gd")
const Guides := preload("g_vec_editor_svg/svg_guides.gd")
@export var display := false:
	set(value):
		display = value
		queue_redraw()
		set_process(display)
@export var path: GVecPathSVG = GVecPathSVG.new()
var has_unprocessed_changes := false
var old_zoom := Vector2.INF


func _process(delta: float) -> void:
	var new_zoom := get_viewport_transform().get_scale()
	if new_zoom != old_zoom:
		old_zoom = new_zoom
		queue_redraw()


func _draw() -> void:
	if ! display:
		return
	Guides.draw_guides(path, self)


func _notification(what: int) -> void:
	if what == NOTIFICATION_CHILD_ORDER_CHANGED:
		notify_controls_have_changed()


func notify_controls_have_changed() -> void:
	has_unprocessed_changes = true
	update_path.call_deferred()


func update_path() -> void:
	if ! has_unprocessed_changes:
		return
	has_unprocessed_changes = false
	NodeProcessor.process_nodes(self)
	queue_redraw()


func add_segment(
		type: GVecPathSVG.SegmentType,
		end_position: Vector2,
		handle_out_position := Vector2.ZERO
		) -> GVecEditorPoint:
	var index := path.get_segment_count()
	
	if index == 0 and get_start_point() == null:
		return add_point(self, 0, "start_point", end_position)
	
	var end_point := add_point(self, index, "end_point", end_position)
	
	var previous_point := get_end_point(index - 1)
	match type:
		GVecPathSVG.SegmentType.QUADRATIC:
			add_point(
					previous_point,
					index,
					"control_point",
					handle_out_position)
		GVecPathSVG.SegmentType.CUBIC:
			add_point(
					previous_point,
					index,
					"start_control_point",
					handle_out_position)
			add_point(
					end_point,
					index,
					"end_control_point",
					end_position)
		GVecPathSVG.SegmentType.ARC_CENTER, \
		GVecPathSVG.SegmentType.ARC_END:
			var center := add_point(
					self,
					index,
					"ellipse_center",
					lerp(previous_point.position, end_position, 0.5))
			add_point(
					center,
					index,
					"radii",
					Vector2.ONE
					* previous_point.position.distance_to(end_position)
					* 0.5)
			previous_point.move_to_front()
	
	path.insert_new_segment(index)
	path.set_segment_property(index, "segment_type", type)
	return end_point


func remove_segment() -> void:
	for i in range(get_child_count() -1 , -1, -1):
		var child = get_child(i)
		if child is GVecEditorPoint:
			child.queue_free()
			remove_child(child)
			break
	var last_handle := get_editor_points()[-1]
	if last_handle.name in ["HandleOut", "Handle"]:
		last_handle.queue_free()


func add_point(
		parent: Node2D,
		index: int,
		property: String,
		editor_position: Vector2
		) -> GVecEditorPoint:
	var point := GVecEditorPoint.new()
	point.name = {
			"start_point": "Start",
			"end_point": "End",
			"control_point": "Handle",
			"start_control_point": "HandleOut",
			"end_control_point": "HandleIn",
			"ellipse_center": "Center",
			"radii": "Radii"
		}[property]
	if property in ["end_point", "ellipse_center"]:
		point.name += String.num_int64(index)
	point.segment_index = index
	point.property_name = property
	parent.add_child(point)
	point.owner = owner
	point.position = parent.to_local(to_global(editor_position))
	point.set_display_folded(true)
	return point


func get_start_point() -> GVecEditorPoint:
	for node in get_editor_points():
		if node.property_name == "start_point":
			return node
	return null


func get_end_point(index: int = path.get_segment_count() - 1) -> GVecEditorPoint:
	if index == -1:
		return get_start_point()
	for node in get_editor_points():
		if node.property_name == "end_point" and node.segment_index == index:
			return node
	return null


func get_editor_points(root_node: Node2D = self) -> Array[GVecEditorPoint]:
	var editor_points: Array[GVecEditorPoint] = []
	for node in root_node.get_children():
		if ! node is Node2D:
			continue
		if node is GVecEditorPoint:
			editor_points.append(node)
		editor_points.append_array(get_editor_points(node))
	return editor_points
