@tool
class_name GVecPathReverse
extends GVecPathNested

## Reverse a [GVecPath] resource
##
## This [GVecPath] exposes the baked points of another [GVecPath], in
## reversed order. It does not change the shape, but may be useful where
## order is important (such as for concatenation or tweening).


func modify_points(points_in: PackedVector2Array) -> PackedVector2Array:
	points_in.reverse()
	return points_in
