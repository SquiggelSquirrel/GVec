@tool
class_name GVecEditorHandle
extends Node2D

@export var segment_index := 0
@export_enum(
		"start_point",
		"end_point",
		"control_point",
		"start_control_point",
		"end_control_point",
		"ellipse_center",
		"radii"
		) var property_name: String
var unmatched_property := false


func _ready() -> void:
	set_notify_transform(true)


func _enter_tree() -> void:
	update_configuration_warnings()
	get_editor().notify_controls_have_changed()


func _get_configuration_warnings() -> PackedStringArray:
	if get_editor() == null:
		return ["This node expects a GVecEditorSVG ancestor"]
	if unmatched_property:
		return ["This node did not match a property in parent's SVGPath"]
	return []


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		get_editor().notify_controls_have_changed()


func get_editor():
	var e = get_parent()
	while e != null:
		if e.has_method("notify_controls_have_changed"):
			return e
		e = e.get_parent()
	return e
