@tool
class_name GVecToolsTarget
extends RefCounted

signal structure_changed
signal focus_changed
signal changed

const PATH_PROPERTY_META := "_svg_tools_path_property"
var current_node: Node:
	set(value):
		if value == current_node:
			return
		GVec.disconnect_if_able(
				current_node,
				"structure_changed",
				_on_structure_changed)
		current_node = value
		GVec.connect_if_able(
				current_node,
				"structure_changed",
				_on_structure_changed)
		_on_structure_changed()
var focussed_path: GVecPath:
	set(value):
		if focussed_path == value:
			return
		focussed_path = value
		focus_changed.emit()
var root_path: GVecPath:
	set(value):
		if value == root_path:
			return
		GVec.disconnect_if_able(root_path, "changed", _on_change)
		root_path = value
		GVec.connect_if_able(root_path, "changed", _on_change)


func destroy() -> void:
	edit(null)


func edit(target) -> bool:
	if target == null:
		unfocus()
		return false
	if _object_uses_editor(target):
		current_node = target
		return true
	if can_focus(target):
		focus(target)
		return true
	return false


func handles(target) -> bool:
	if _object_uses_editor(target):
		return true
	return can_focus(target)


func can_focus(target) -> bool:
	if current_node == null:
		return false
	if not target is GVecPath:
		return false
	if ! root_path.contains_path(target):
		return false
	return true


func focus(target: GVecPath) -> void:
	focussed_path = target
	focus_changed.emit()


func unfocus() -> void:
	focussed_path = null
	focus_changed.emit()


func get_active_shapes() -> Array[Dictionary]:
	return get_shapes_with_transforms(focussed_path)


func get_root_transform() -> Transform2D:
	var transform_root = _get_transform_root(current_node)
	var transform: Transform2D = (
			transform_root.get_viewport_transform()
			* transform_root.get_canvas_transform()
			* transform_root.global_transform)
	return transform


func get_shapes_with_transforms(path = root_path) -> Array[Dictionary]:
	var transform := get_root_transform()
	return _get_nested_shapes_with_transforms(
			path, transform)


func _get_nested_shapes_with_transforms(
		root, transform: Transform2D
) -> Array[Dictionary]:
	if root.has_meta(PATH_PROPERTY_META):
		var property_name = root.get_meta(PATH_PROPERTY_META)
		if root is GVecPathTransform:
			transform *= root.transform
		return _get_nested_shapes_with_transforms(
				root.get(property_name), transform)
	if root is Array:
		var deduplicated_shapes: Array[Dictionary] = []
		var object_ids := {}
		for child in root:
			var nested_shapes = _get_nested_shapes_with_transforms(
					child, transform)
			for shape in nested_shapes:
				var object_id = shape.path.get_instance_id()
				if object_ids.has(object_id):
					continue
				object_ids[object_id] = true
				deduplicated_shapes.append(shape)
		return deduplicated_shapes
	return [{
		"path": root,
		"transform": transform
	}]


func _on_structure_changed() -> void:
	var property_name = current_node.get_meta(PATH_PROPERTY_META)
	root_path = current_node.get(property_name)
	structure_changed.emit()
	if ! root_path.contains_path(focussed_path):
		focus(root_path)


func _on_change() -> void:
	changed.emit()


func _object_uses_editor(object :Object) -> bool:
	if ! object is Node:
		return false
	if ! object.has_meta(PATH_PROPERTY_META):
		return false
	return true


func _get_transform_root(object :Object):
	if object is Node2D and not object is GVecPathTransformSetter:
		return object
	if object is Node:
		return _get_transform_root(object.get_parent())
	return null
