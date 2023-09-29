@tool
class_name GVecPathTransform
extends GVecPathNested

## A [GVecPath] with a [Transform2D] applied to each point.
##
## This resource takes another [GVecPath] and applies a [Transform2D] to each
## baked point, when outputting its own baked points. See also
## [PathShapeTransformSetter2D]

@export var transform := Transform2D.IDENTITY:
	set(value):
		transform = value
		if caching_enabled:
			cache_clear()
		emit_changed()


func modify_points(points_in: PackedVector2Array) -> PackedVector2Array:
	var points_out := PackedVector2Array()
	for point in points_in:
		points_out.append(transform * point)
	return points_out
