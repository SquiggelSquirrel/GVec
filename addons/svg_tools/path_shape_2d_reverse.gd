@tool
class_name PathShape2DReverse
extends PathShape2DNested

## Reverse a [PathShape2D] resource
##
## This [PathShape2D] exposes the baked points of another [PathShape2D], in
## reversed order. It does not change the shape, but may be useful where
## order is important (such as for concatenation or tweening).


func modify_points(points_in: PackedVector2Array) -> PackedVector2Array:
	points_in.reverse()
	return points_in
