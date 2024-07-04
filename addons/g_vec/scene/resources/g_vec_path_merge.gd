@tool
class_name GVecPathMerge
extends GVecPathCombination


func _calculate_baked_points() -> PackedVector2Array:
	var result: PackedVector2Array = []
	for path in paths:
		if path != null:
			result = Geometry2D.merge_polygons(result, path.get_baked_points())[0]
	return result
