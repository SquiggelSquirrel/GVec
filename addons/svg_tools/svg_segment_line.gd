@tool
class_name SVGSegmentLine
extends SVGSegment
## This class defines a straight-line segment for an [SVGPath]

## Re-generate the baked points cache for this segment.
## Should be called automatically as needed, no need to call manually.
func bake() -> void:
	_is_dirty = false
	_baked_points = PackedVector2Array()
	var actual_length = start_point.distance_to(end_point)
	var f_count :float = round(actual_length / bake_interval)
	
	if f_count < 2:
		_baked_points = PackedVector2Array([start_point, end_point])
		return
	
	var f_interval := 1.0 / f_count
	for i in f_count + 1:
		var p := i * f_interval
		_baked_points.append(lerp(start_point, end_point, p))
