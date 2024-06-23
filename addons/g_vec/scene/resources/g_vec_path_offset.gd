@tool
class_name GVecPathOffset
extends GVecPathNested

## [GVecPath] that generates points offset from another [GVecPath]
##
## This resource contains another [GVecPath]. It takes the
## source's [method GVecPath.get_baked_points] and outputs
## a [PackedVector2Array] for which each point is offset orthoganal
## (counter-clockwise) to the vector connecting the previous and next point,
## with a length defined by [member offset].[br]
## Note that when shrinking a closed path, or offsetting towards the concave
## side of a curve, this can cause points to collide or switch order.
## To avoid this, increase your bake interval or use
## [GVecPathWithPointReduction]


## The pixel distance offset to be applied to each point. Positive values
## will offset left of the path's direction, negative will go right.
@export var offset: float = 0.0:
	set(value):
		offset = value
		if caching_enabled:
			cache_clear()
		emit_changed()

## If closed, the first and last points will use the second-to-last and second
## points (respectively) when calculating their orthogonal vector. This produces
## better results for closed paths, but weird results for non-closed paths.
@export var closed := false:
	set(value):
		closed = value
		if caching_enabled:
			cache_clear()
		emit_changed()


func modify_points(points_in: PackedVector2Array) -> PackedVector2Array:
	if points_in.size() < 2:
		return points_in
	if points_in.size() < 4:
		closed = false
	var result_points := [] as PackedVector2Array
	
	# First point
	var end_point_offset :Vector2
	if closed:
		end_point_offset = (points_in[1] - points_in[-2]
				).normalized().orthogonal() * offset
	else:
		end_point_offset = (points_in[1] - points_in[0]
				).normalized().orthogonal() * offset
	result_points.append(points_in[0] + end_point_offset)
	
	# Non-end points
	for i in range(1, points_in.size() - 1):
		result_points.append(
				points_in[i]
				+ (points_in[i + 1] - points_in[i - 1]
				).normalized().orthogonal() * offset)
	
	# End point
	if closed:
		result_points.append(points_in[-1] + end_point_offset)
	else:
		result_points.append(
				points_in[-1]
				+ (points_in[-1] - points_in[-2]
				).normalized().orthogonal() * offset)
	
	return result_points
