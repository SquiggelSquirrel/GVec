@tool
class_name GVecPathToPoints
extends Node

## Set a [PackedVector2Array] property from a [GVecPath]
##
## This node takes any [GVecPath] resource, and listens for change signals.
## On change, it samples the baked points of that resource. It then sets a
## property of type [PackedVector2Array] (or compatible) on this node's parent.
## It will auto-detect the property to set in most cases.[br]
## For example, adding this to a [Polygon2D] and [Line2D] can provide the fill
## and stroke for a vector shape.


## This signal is fired when [member path] changes to reference a different
## [GVecPath], or when the structure of nested [GVecPath] resources changes.
signal structure_changed

## The [GVecPath] resource to get baked points from
@export var path: GVecPath:
	set(value):
		GVecGlobals.disconnect_if_able(path, "changed", _on_path_changed)
		GVecGlobals.disconnect_if_able(path, "path_changed", _on_structure_changed)
		path = value
		GVecGlobals.connect_if_able(path, "changed", _on_path_changed)
		GVecGlobals.connect_if_able(path, "path_changed", _on_structure_changed)
		_on_structure_changed()
		_on_path_changed()
var target_property := "AUTO"


func _get_property_list():
	return [{
		"name": "target_property",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_ENUM_SUGGESTION,
		"hint_string": "AUTO," + ",".join(_get_candidate_target_properies()),
	}]


func _enter_tree():
	# set meta for the SVGTools plugin
	set_meta("_svg_tools_path_property", "path")
	if path != null:
		_on_path_changed()


func _on_path_changed():
	var parent = get_parent()
	if parent == null:
		return
	var points = path.get_baked_points()
	var target: String
	if target_property == "AUTO":
		target = _get_default_target_property()
	else:
		target = target_property
	if target == "":
		return
	parent.set(target, points)


func _on_structure_changed():
	structure_changed.emit()


func _get_default_target_property():
	var parent = get_parent()
	if parent == null:
		return ""
	if parent is Polygon2D:
		return "polygon"
	if parent is Line2D:
		return "points"
	var candidates = _get_candidate_target_properies()
	if candidates.size() > 0:
		return candidates[0]
	return ""


func _get_candidate_target_properies() -> PackedStringArray:
	var candidates = [] as PackedStringArray
	var parent = get_parent()
	if parent == null:
		return candidates
	
	for property in parent.get_property_list():
		if property.type == TYPE_PACKED_VECTOR2_ARRAY:
			candidates.append(property.name)
	
	if candidates.size() > 0:
		return candidates
	
	for property in parent.get_property_list():
		if property.type == TYPE_ARRAY:
			candidates.append(property.name)
	
	return candidates
