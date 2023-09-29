@tool
class_name GVecPathRange
extends GVecPathNested

## Outputs a range from a [GVecPath]
##
## This resource references another [GVecPath], and outputs a slice
## of its baked points, based on a given [member start], [member end], and
## [member range_mode]. This does not preserve segments
## (the entire slice is treated as a single segment). If [member start]
## resolves to a point index greater than [member end], slices will be taken
## from the end and start of the path, then concatenated, with the start point
## of the path omitted. This allows closed paths to wrap seemlessly, but results
## in odd behaviour for non-closed paths.
## (See [enum RangeMode] for more details)


## Possible modes for [member range_mode]
enum RangeMode {
	RATIO_OF_TOTAL_LENGTH, ## [member start] and [member end] are ratios of the
		## baked points' size.
		## Use 0.0 and 1.0 for the start and end of the path.
	RATIO_OF_SEGMENTS_LENGTH, ## The integer part of [member start] and
		## [member end] identify a segment of the source path, while the
		## fractional part is a ratio of the segments baked points' size.
	PIXELS, ## [member start] and [member end] represent pixel distances from
		## the start of the path. This wraps, and negative values will be
		## measured backwards from the end.
}
## The [enum RangeMode] to use when calculating the range of points to output
@export var range_mode: RangeMode = RangeMode.RATIO_OF_TOTAL_LENGTH:
	set(value):
		if value == range_mode:
			return
		range_mode = value
		if caching_enabled:
			cache_clear()
		emit_changed()
## The start of the slice. See [enum RangeMode] for more details.
@export var start: float = 0.0:
	set(value):
		if value == start:
			return
		start = value
		if caching_enabled:
			cache_clear()
		emit_changed()
## The end of the slice. See [enum RangeMode] for more details.
@export var end: float = 1.0:
	set(value):
		if value == end:
			return
		end = value
		if caching_enabled:
			cache_clear()
		emit_changed()


func get_segment_count() -> int:
	return 1


func get_segment_baked_points(_segment_index: int) -> PackedVector2Array:
	return get_baked_points()


func get_segment_length(_segment_index: int) -> float:
	return get_baked_length()


func _calculate_baked_points() -> PackedVector2Array:
	match range_mode:
		RangeMode.RATIO_OF_TOTAL_LENGTH:
			return _calculate_ratio_of_total_length_baked_points(start, end)
		RangeMode.RATIO_OF_SEGMENTS_LENGTH:
			return _calculate_ratio_of_segments_length_baked_points()
		RangeMode.PIXELS:
			return _calculate_pixels_length_baked_points()
		_:
			return [] as PackedVector2Array


func _calculate_pixels_length_baked_points() -> PackedVector2Array:
	var start_r = start / path.get_baked_length()
	var end_r = end / path.get_baked_length()
	return _calculate_ratio_of_total_length_baked_points(start_r, end_r)


func _calculate_ratio_of_segments_length_baked_points() -> PackedVector2Array:
	var start_segment: int = floori(start)
	var end_segment: int = ceili(end) - 1
	var segment_start: float = fmod(start, 1.0)
	var segment_end: float = fmod(end, 1.0)
	if segment_end == 0.0:
		segment_end = 1.0
	if start_segment < 0:
		segment_start += 1.0
	if end_segment < 0:
		segment_end += 1.0
	start_segment = wrapi(start_segment, 0, path.get_segment_count())
	end_segment = wrapi(end_segment, 0, path.get_segment_count())
	
	var segment_sequence: PackedInt32Array
	var wrapped := false
	if start_segment < end_segment:
		segment_sequence = range(start_segment, end_segment + 1)
	elif start_segment == end_segment and segment_end > segment_start:
		segment_sequence = [start_segment] as PackedInt32Array
	else:
		segment_sequence = range(start_segment, path.get_segment_count())
		segment_sequence.append_array(range(0, end_segment + 1))
		wrapped = true
	
	var points := [] as PackedVector2Array
	for i in segment_sequence.size():
		var s := segment_sequence[i]
		var segment_points := path.get_segment_baked_points(s)
		var segment_size := segment_points.size()
		
		var start_index: int = 0
		var end_index := segment_size
		if i == segment_sequence.size() - 1:
			end_index = roundi(segment_end * (segment_size - 1) + 1)
		if i == 0:
			start_index = roundi(segment_start * (segment_size - 1))
		elif s == 0 and wrapped:
			start_index = 1
		
		points.append_array(segment_points.slice(start_index, end_index))
	return points


func _calculate_ratio_of_total_length_baked_points(
		start_r: float,
		end_r: float
		) -> PackedVector2Array:
	var source_points := path.get_baked_points()
	var start_index := roundi(start_r * (source_points.size() - 1))
	var end_index := roundi(end_r * (source_points.size() - 1))
	if start_index == end_index:
		return [] as PackedVector2Array
	start_index = wrapi(start_index, 0, source_points.size())
	end_index = wrapi(end_index, 0, source_points.size())
	if start_index < end_index:
		return source_points.slice(start_index, end_index + 1)
	else:
		return (
				source_points.slice(start_index)
				+ source_points.slice(1, end_index + 1))
