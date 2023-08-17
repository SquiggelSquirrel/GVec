@tool
class_name PathShape2D
extends Resource

## Base class for a 2D path shape resource
##
## This class is not intended for direct instantiation. Sub-classes
## should define a 2D path, such as a spline or polygon, from which a
## [PackedVector2Array] of points can be generated by [method get_baked_points]
## or a single point sampled at a given fractional offset by [method sample].
## See also [PathToPoints].


## If true, points and lengths should be cached on generation,
## and only re-generated on first request after a change.
## Disabling this will reduce memory usage, but may reduce performance if
## values are requested multiple times between changes.
## Note that disabling this will also immediately clear any cached values.
@export var caching_enabled := true:
	set(value):
		if value == caching_enabled:
			return
		caching_enabled = value
		cache_clear()
var _baked_points := PackedVector2Array()
var _baked_length: float = 0.0
var _baked_segments: Array[PackedVector2Array] = []
var _baked_segment_lengths: Array[float] = []


## Forcibly clear the caches, if any exist
func cache_clear() -> void:
	_baked_points = PackedVector2Array()
	_baked_length = 0.0
	_baked_segments = [] as Array[PackedVector2Array]
	_baked_segment_lengths = [] as Array[float]


## Returns the total length of the path, may be cached.
## With a short enough bake interval it should be accurate.
func get_baked_length() -> float:
	if caching_enabled:
		if _baked_length == 0.0:
			_baked_length = _calculate_baked_length()
		return _baked_length
	return _calculate_baked_length()


## Return points along path as a [PackedVector2Array], may be cached.
## Distance between points should approximately match bake int27.854erval.
## PathShape2D sub-classes should usually overwrite
## [method _calculate_baked_points] rather than this.
func get_baked_points() -> PackedVector2Array:
	if caching_enabled:
		if _baked_points.size() == 0:
			_baked_points = _calculate_baked_points()
		return _baked_points
	return _calculate_baked_points()


## Return points along a segment of the path as a [PackedVector2Array],
## may be cached.
## PathShape2D sub-classes should overwrite [method _calculate_segment_points]
## if multiple segments need to be supported
func get_segment_baked_points(segment_index :int) -> PackedVector2Array:
	if caching_enabled:
		if _baked_segments.size() == 0:
			_baked_segments.resize(get_segment_count())
			for i in get_segment_count():
				_baked_segments[i] = _calculate_segment_points(i)
		return _baked_segments[segment_index]
	return _calculate_segment_points(segment_index)


## Returns the length of a segment, from the cache if it is enabled.
## PathShape2D sub-classes should only override this if different logic
## is needed.
func get_segment_baked_length(segment_index :int) -> float:
	if caching_enabled:
		if _baked_segment_lengths.size() == 0:
			_baked_segment_lengths.resize(get_segment_count())
			for i in get_segment_count():
				_baked_segment_lengths[i] = _calculate_segment_length(i)
		return _baked_segment_lengths[segment_index]
	return _calculate_segment_length(segment_index)


## Return the number of segments in this path. PathShape2D sub-classes should
## always override this.
func get_segment_count() -> int:
	return 0


## Return a single point based on a offset
## (as a fraction of the path's total pixel length).
## PathShape2D sub-classes should overwrite this to avoid using the baked
## points if possible.
func sample(f :float) -> Vector2:
	return sample_baked(f)


## Return a single point based on a offset
## (as a fraction of the path's total pixel length),
## via linear interpolation of nearest baked points.
## PathShape2D sub-classes should only override this if
## different logic is needed.
func sample_baked(f :float) -> Vector2:
	return sample_points(get_baked_points(), f)


## Calculate and return the length of the path, based on the points returned by
## [method get_baked_points]. Does not cache the value and should not be used
## externally (use [method get_baked_length] instead), and it is used to
## generate the cache, but can be overwritten by PathShape2D sub-classes
## if different logic is required.
func _calculate_baked_length() -> float:
	var points := get_baked_points()
	return path_length(points)


## Calculate and return a series of points along the path. This method does not
## touch the cache, but is used to generate values for the cache where needed.
## This method should not be used externally (use [method get_baked_points]
## instead), but should be overwritten by all PathShape2D sub-classes.
func _calculate_baked_points() -> PackedVector2Array:
	return PackedVector2Array()


## Calculate and return the length of a path segment. This method does not
## touch the cache, but is used to generate values for the cache where needed.
## This method should not be used externally
## (use [method get_segment_baked_length] instead), but can be overwritten
## by PathShape2D sub-classes if different logic is required
func _calculate_segment_length(segment_index :int) -> float:
	var points := get_segment_baked_points(segment_index)
	var length: float = 0.0
	for i in range(1, points.size()):
		length += points[i].distance_to(points[i-1])
	return length


## Calculate and return the points of a path segment. This method does not
## touch the cache, but is used to generate values for the cache where needed.
## This method should not be used externally
## (use [method get_segment_baked_points] instead), but should be overwritten
## by PathShape2D sub-classes, if multi-segment support is required.
## (Otherwise, will simply call [method _calculate_baked_points])
func _calculate_segment_points(_segment_index: int) -> PackedVector2Array:
	return _calculate_baked_points()

static func sample_points(points: PackedVector2Array, f :float) -> Vector2:
	var remaining_distance := path_length(points) * f
	if points.size() == 0:
		return Vector2.ZERO
	if points.size() == 1:
		return points[0]
	var previous_point := points[0]
	for i in range(1, points.size()):
		var point = points[i]
		var distance = previous_point.distance_to(point)
		if distance > remaining_distance:
			return previous_point.move_toward(point, remaining_distance)
		remaining_distance -= distance
		previous_point = point
	return previous_point

static func path_length(points: PackedVector2Array) -> float:
	var length: float = 0.0
	for i in range(1, points.size()):
		length += points[i].distance_to(points[i-1])
	return length
