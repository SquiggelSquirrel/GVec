@tool
class_name GVecSdfInnerToOuter
extends GVecSdf


func get_distance_at_global_point(global_point: Vector2) -> float:
	var inner := get_child(0) as GVecSdf
	var outer := get_child(1) as GVecSdf
	if inner == null or outer == null:
		return 0.0
	var inner_value := inner.get_distance_at_global_point(global_point)
	if inner_value < 0.0:
		return 1.0
	var outer_value := -1.0 * outer.get_distance_at_global_point(global_point)
	if outer_value < 0.0:
		return 0.0
	return outer_value / (inner_value + outer_value)


func get_distance_at_local_point(local_point: Vector2) -> float:
	return get_distance_at_global_point(to_global(local_point))
