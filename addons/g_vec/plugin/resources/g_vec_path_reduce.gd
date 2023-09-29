@tool
class_name GVecPathReduce
extends GVecPathNested

## Reduces the points of a [GVecPath]
##
## This resource references another [GVecPath] resource, and exposes the
## baked points reduced by sampling every nth point (preserving the start
## and end points). This may be more performant than modifying the bake
## interval, at runtime depending on the source [GVecPath] being used.


## The reduction factor to apply to the baked points. 1 for every point,
## 2 for every 2nd point, 3 for every 3rd point, etc.
@export_range(1, 64, 1, "or_greater") var reduction_factor :int = 1:
	set(value):
		reduction_factor = value
		if caching_enabled:
			cache_clear()
		emit_changed()


func modify_points(points_in: PackedVector2Array) -> PackedVector2Array:
	if points_in.size() == 0:
		return points_in
	var array_out := [] as PackedVector2Array
	for i in range(0, points_in.size(), reduction_factor):
		array_out.append(points_in[i])
	if points_in.size() % reduction_factor != 1:
		array_out.append(points_in[-1])
	return array_out
