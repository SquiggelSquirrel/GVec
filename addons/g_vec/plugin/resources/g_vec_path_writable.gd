@tool
class_name GVecPathWritable
extends GVecPath

## A [GVecPath] which simply holds data written to it.
##
## This resource exposes a [member segments] property which represents a set
## of baked points for a [GVecPath]. It is most commonly used by
## [GVecPathWithSkeleton], to generate a set of posed points, which can
## then be read in by a [PathToPoints] node.

## The segments to expose
@export var segments: Array[PackedVector2Array] = []:
	set(value):
		segments = value
		emit_changed()


func get_baked_points() -> PackedVector2Array:
	var baked_points := PackedVector2Array()
	for segment in segments:
		if segment.size() == 0:
			continue
		if baked_points.size() > 0 and baked_points[-1] == segment[0]:
			baked_points.append_array(segment.slice(1))
		else:
			baked_points.append_array(segment)
	return baked_points


func get_segment_baked_points(segment_index: int) -> PackedVector2Array:
	return segments[segment_index]


func get_segment_count() -> int:
	return segments.size()
