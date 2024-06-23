@tool
class_name GVecPathConcatenate
extends GVecPathCombination

## Concatenate two or more [GVecPath] resources.
##
## This [GVecPath] concatenates two or more [GVecPath] resources.


func _calculate_baked_points():
	var points := PackedVector2Array()
	for path in paths:
		if path != null:
			points.append_array(path.get_baked_points())
	return points


func get_segment_count():
	var count := 0
	for path in paths:
		if path != null:
			count += path.get_segment_count()
	return count


func _calculate_segment_baked_points(segment_index: int):
	for path in paths:
		if path == null:
			continue
		if segment_index < path.get_segment_count():
			return path.get_segment_baked_points(segment_index)
		segment_index -= path.get_segment_count()
