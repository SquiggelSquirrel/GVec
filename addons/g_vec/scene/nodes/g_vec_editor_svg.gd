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
	var handle_out := get_handle(path.get_segment_count(), "start_control_point")
	if handle_out:
		Guides.draw_guides(path, self, to_local(handle_out.global_position))
	else:
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


## Add a new segment (or a start point if no start point is set)
## Return end point handle or start point handle
func add_segment(
		type: GVecPathSVG.SegmentType,
		end_point: Vector2,
		start_control_point := Vector2.ZERO,
		end_control_point := Vector2.ZERO,
		parent_nodepath: NodePath = ^"."
		) -> GVecEditorHandle:
	var parent: Node2D = get_node(parent_nodepath)
	var new_segment_index := path.get_segment_count()
	
	if new_segment_index == 0 and get_start_handle() == null:
		return add_handle(
				parent,
				new_segment_index,
				"start_point",
				end_point)
	
	var previous_handle := get_end_handle(new_segment_index - 1)
	var end_handle := add_handle(
			parent,
			new_segment_index,
			"end_point",
			end_point)
	
	match type:
		GVecPathSVG.SegmentType.QUADRATIC:
			add_handle(
					previous_handle,
					new_segment_index,
					"control_point",
					start_control_point)
		GVecPathSVG.SegmentType.CUBIC:
			add_handle(
					previous_handle,
					new_segment_index,
					"start_control_point",
					start_control_point)
			add_handle(
					end_handle,
					new_segment_index,
					"end_control_point",
					end_control_point)
		GVecPathSVG.SegmentType.ARC_CENTER, \
		GVecPathSVG.SegmentType.ARC_END:
			var center_handle := add_handle(
					parent,
					new_segment_index,
					"ellipse_center",
					lerp(previous_handle.position, end_point, 0.5))
			add_handle(
					center_handle,
					new_segment_index,
					"radii",
					Vector2.ONE
					* previous_handle.position.distance_to(end_point)
					* 0.5)
			end_handle.move_to_front()
	
	path.insert_new_segment(new_segment_index)
	path.set_segment_property(new_segment_index, "segment_type", type)
	return end_handle


func remove_segment() -> void:
	for i in range(get_child_count() -1 , -1, -1):
		var child = get_child(i)
		if child is GVecEditorHandle:
			child.queue_free()
			remove_child(child)
			break
	var last_handle := get_editor_handles()[-1]
	if last_handle.name in ["HandleOut", "Handle"]:
		last_handle.queue_free()


func add_handle(
		parent: Node2D,
		index: int,
		property: String,
		editor_position: Vector2
		) -> GVecEditorHandle:
	var point := GVecEditorHandle.new()
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


func get_start_handle() -> GVecEditorHandle:
	for node in get_editor_handles():
		if node.property_name == "start_point":
			return node
	return null


func get_end_handle(index: int = path.get_segment_count() - 1) -> GVecEditorHandle:
	if index == -1:
		return get_start_handle()
	return get_handle(index, "end_point")
	return null


func get_handle(index: int, property_name: StringName) -> GVecEditorHandle:
	for node in get_editor_handles():
		if node.segment_index == index and node.property_name == property_name:
			return node
	return null


func get_editor_handles(root_node: Node2D = self) -> Array[GVecEditorHandle]:
	var editor_handles: Array[GVecEditorHandle] = []
	for node in root_node.get_children():
		if ! node is Node2D:
			continue
		if node is GVecEditorHandle:
			editor_handles.append(node)
		editor_handles.append_array(get_editor_handles(node))
	return editor_handles


func set_end_control_point(control_point: Vector2) -> void:
	var end_handle := get_end_handle()
	if end_handle == null:
		return
	
	var nested_handles := get_editor_handles(end_handle)
	var nested_handle_positions: PackedVector2Array = []
	for handle in nested_handles:
		nested_handle_positions.append(handle.global_position)
	
	var control_point_global := to_global(control_point)
	end_handle.look_at(control_point_global)
	end_handle.rotate(PI)
	
	for i in nested_handles.size():
		var handle := nested_handles[i]
		if handle.property_name == "end_control_point":
			handle.global_position = control_point_global
		else:
			handle.global_position = nested_handle_positions[i]
