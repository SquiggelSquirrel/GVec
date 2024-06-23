@tool
class_name GVecSdf
extends Node2D


func get_distance_at_global_point(global_point: Vector2) -> float:
	return get_distance_at_local_point(to_local(global_point))


func get_distance_at_local_point(local_point) -> float:
	return 0
