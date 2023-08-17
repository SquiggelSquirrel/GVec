@tool
class_name PathShape2DSVG
extends PathShape2D

## Describes a shape in 2D space.
##
## This class describes a shape in 2D space, made up of segments which can be
## straight lines, Bézier quadritic curves, Bézier cubic curves,
## and/or elliptical arcs. Loosely based on the SVG specifications.

## Enumerated values for segment type
enum SegmentType {
	LINE      = 0, ## Indicates a straight-line
	QUADRATIC = 1, ## Indicates a Bézier quadratic curve
	CUBIC     = 2, ## Indicates a Bézier cubic curve
	ARC       = 3, ## Indicates an ellsiptical arc
}

# An internal array of Segment objects - not intended for direct access
var _segments: Array[SVGSegment] = []
var _is_ready := false


# ----------
# Beginning of virtual methods


# The property list exposes segments as a properties array
func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary] = [] as Array[Dictionary]
	properties.append(_get_property_list_segment_count())
	for segment_index in _segments.size():
		properties.append_array(
				SVGSegmentProperties.get_list(_segments, segment_index))
	return properties


# This custom setter handles the property list of segment properties
# Segment properties should only be set via this method, to preserve integrity
func _set(property, value):
	if property == "segment_count":
		_set_segments_count(value)
		return
	if ! SVGSegmentProperties.is_segment_property(property):
		return
	
	var parts := SVGSegmentProperties.segment_name_to_property(property)
	var segment_index: int = parts[0]
	var segment_property: String = parts[1]
	var segment := _segments[segment_index] as SVGSegment
	var has_changed := false
	
	if segment_property == "segment_type":
		has_changed = _set_segment_type(segment_index, value)
		if has_changed:
			notify_property_list_changed()
	
	elif segment_property == "start_point" and segment_index > 0:
		has_changed = _resync_segment_start_point(segment_index)
	
	else:
		var old_value = segment.get(segment_property)
		if value != old_value:
			has_changed = true
			_segments[segment_index].set(segment_property, value)
	
	match segment_property:
		"end_point":
			var next := segment_index + 1
			if next < _segments.size():
				if segment.get("calc_mode") == SVGSegmentArc.CalcMode.CENTER:
					# Actual end point may differ from what is passed in,
					# recalculate before resync
					segment.bake()
				_resync_segment_start_point(next)
		"control_point":
			_mirror_handles_forward(segment_index)
			_mirror_handles_backward(segment_index)
		"start_control_point":
			_mirror_handles_backward(segment_index)
		"end_control_point":
			_mirror_handles_forward(segment_index)
		"mirror_previous_angle", "mirror_previous_length":
			if bool(value) and segment_index > 0:
				_mirror_handles_forward(segment_index - 1)
	
	if has_changed:
		_on_path_changed()
		
		# Hard-coded exception for arc segment calc mode
		if segment_property == "calc_mode":
			notify_property_list_changed()


# This custom getter handles the property list of segment properties
func _get(property):
	if property == "segment_count":
		return _segments.size()
	
	if SVGSegmentProperties.is_segment_property(property):
		var parts := SVGSegmentProperties.segment_name_to_property(property)
		var segment_index :int = parts[0]
		var segment_property :String = parts[1]
		if segment_index >= _segments.size():
			return null
		var segment = _segments[segment_index]
		
		if segment_property == "segment_type":
			if segment is SVGSegmentLine:
				return SegmentType.LINE
			elif segment is SVGSegmentQuadratic:
				return SegmentType.QUADRATIC
			elif segment is SVGSegmentCubic:
				return SegmentType.CUBIC
			elif segment is SVGSegmentArc:
				return SegmentType.ARC
		else:
			return segment.get(segment_property)


func _init():
	set_deferred("_is_ready", true)


# ----------
# Beginning of public methods


## Add an arc segment to the path.
func add_arc_segment(
		end_point: Vector2,
		r1: float,
		r2: float,
		angle: float,
		large_arc_flag: bool,
		sweep_flag: bool,
		index: int = -1
		) -> void:
	_add_segment(SVGSegmentArc, {
		"end_point": end_point,
		"r1": r1,
		"r2": r2,
		"angle": angle,
		"large_arc_flag": large_arc_flag,
		"sweep_flag": sweep_flag,
	}, index)
	_on_path_changed()


## Add a Bézier cubic segment to the path.
func add_cubic_segment(
		end_point: Vector2,
		start_control_point: Vector2,
		end_control_point: Vector2,
		index: int = -1
		) -> void:
	_add_segment(SVGSegmentCubic, {
		"end_point": end_point,
		"start_control_point": start_control_point,
		"end_control_point": end_control_point,
	}, index)
	_on_path_changed()


## Add a line segment to the path.
func add_line_segment(end_point: Vector2, index: int = -1) -> void:
	_add_segment(SVGSegmentLine, {"end_point": end_point}, index)
	_on_path_changed()


## Add a Bézier quadratic segment to the path
func add_quadratic_segment(
		end_point: Vector2,
		control_point: Vector2,
		index: int = -1
		) -> void:
	_add_segment(SVGSegmentQuadratic, {
		"control_point": control_point,
		"end_point": end_point,
	}, index)
	_on_path_changed()


## Add a segment of the given type, only specifying and end point and leaving
## the rest to default values
func add_segment(
		segment_type: SegmentType,
		end_point: Vector2
		) -> void:
	match segment_type:
		SegmentType.LINE:
			_add_segment(SVGSegmentLine, {"end_point": end_point}, -1)
		SegmentType.QUADRATIC:
			_add_segment(SVGSegmentQuadratic, {"end_point": end_point}, -1)
		SegmentType.CUBIC:
			_add_segment(SVGSegmentCubic, {"end_point": end_point}, -1)
		SegmentType.ARC:
			_add_segment(SVGSegmentArc, {"end_point": end_point}, -1)
	_on_path_changed()
	notify_property_list_changed()


## Get the [member SVGSegmentArc.calc_mode] of an elliptical arc segment
func get_arc_segment_calc_mode(segment_index: int) -> int:
	return _segments[segment_index].calc_mode


## Get the center of an elliptical arc segment
func get_arc_segment_center(segment_index: int) -> Vector2:
	return _segments[segment_index].center


## Get the arc segment "angle" parameter that points toward a target point.
func get_arc_segment_angle_parameter_to_point(
		segment_index: int,
		target: Vector2
		) -> float:
	var segment := _segments[segment_index] as SVGSegmentArc
	return segment.angle_parameter_to_point(target)


## Return the number of segments in this path
func get_segment_count() -> int:
	return get("segment_count")


## Return the end point of a segment
func get_segment_end_point(segment_index: int) -> Vector2:
	return _segments[segment_index].end_point


## Return the start point of a segment
func get_segment_start_point(segment_index: int) -> Vector2:
	return _segments[segment_index].start_point


## Return the [enum SegmentType] of a segment
func get_segment_type(segment_index: int) -> int:
	return get(SVGSegmentProperties.segment_property_to_name(
			segment_index, "segment_type"))


## Get a property of a segment
func get_segment_property(
		segment_index: int,
		property_name: String
		):
	return get(SVGSegmentProperties.segment_property_to_name(
			segment_index, property_name))


## Return the start control point of a cubic segment
func get_cubic_segment_start_control_point(segment_index: int) -> Vector2:
	return _segments[segment_index].start_control_point


## Return the end control point of a cubic segment
func get_cubic_segment_end_control_point(segment_index: int) -> Vector2:
	return _segments[segment_index].end_control_point


## Return the control point of a quadratic segment
func get_quadratic_segment_control_point(segment_index: int) -> Vector2:
	return _segments[segment_index].control_point


## Remove a segment (default to the last segment)
func remove_segment(segment_index :int = -1) -> void:
	assert(segment_index > -2)
	if segment_index == -1:
		segment_index = _segments.size() - 1
	_segments.remove_at(segment_index)
	
	if segment_index > 0 and segment_index < _segments.size():
		_resync_segment_start_point(segment_index)
	
	_on_path_changed()


func segment_has_vector_out(segment_index :int) -> bool:
	return _segments[segment_index].has_method("get_vector_out")


## Set a property of a segment
func set_segment_property(
		segment_index: int,
		property_name: String,
		value
		) -> void:
	set(SVGSegmentProperties.segment_property_to_name(
			segment_index, property_name), value)


func set_segment_vector_out(
		segment_index: int,
		vector_out: Vector2,
		) -> void:
	_segments[segment_index].set_vector_out(vector_out)
	segment_index = wrapi(segment_index, 0, _segments.size())
	_mirror_handles_forward(segment_index)
	_mirror_handles_backward(segment_index)
	_on_path_changed()


# ----------
# Begin private methods


# Add a segment at the specified index
func _add_segment(
		segment_class :Object, config :Dictionary, index :int
) -> void:
	if index == -1:
		index = _segments.size()
	var vector_in := Vector2.ZERO
	if index == 0:
		config.start_point = Vector2.ZERO
	else:
		config.start_point = _segments[index - 1].end_point
		if _segments[index - 1].has_method("get_vector_out"):
			vector_in = _segments[index - 1].get_vector_out() * -1.0
	_segments.insert(index, segment_class.new(config))
	if _segments[index].has_method("set_vector_in"):
		_segments[index].set_vector_in(vector_in)


func _calculate_baked_length() -> float:
	var length: float = 0.0
	for segment in _segments:
		if segment is SVGSegment:
			length += segment.get_baked_length()
	return length


func _calculate_baked_points() -> PackedVector2Array:
	var points = PackedVector2Array()
	for segment in _segments:
		if segment is SVGSegment:
			if points.size() > 0:
				points += segment.get_baked_points().slice(1)
			else:
				points += segment.get_baked_points()
	return points


func _calculate_segment_length(segment_index: int) -> float:
	return _segments[segment_index].get_baked_length()


func _calculate_segment_points(segment_index: int) -> PackedVector2Array:
	return _segments[segment_index].get_baked_points()


# Definition of "segment_count" property for _get_property_list
func _get_property_list_segment_count():
	return {
		"name": "segment_count",
		"type": TYPE_INT,
		"usage": PROPERTY_USAGE_ARRAY | PROPERTY_USAGE_DEFAULT,
		"class_name": "Segments,segment_",
		"hint": PROPERTY_HINT_NONE
	}


func _mirror_handles_backward(start_index :int) -> void:
	if ! _is_ready:
		return
	for i in range(start_index, 0, -1):
		var prev = i - 1
		if ! _segments[i].get("mirror_previous_angle"):
			return
		if ! _segments[i].has_method("get_vector_in"):
			return
		if ! _segments[prev].has_method("set_vector_out"):
			return
		
		if _segments[i].get("mirror_previous_length"):
			_segments[prev].set_vector_out(-1.0 * _segments[i].get_vector_in())
		else:
			var length = _segments[prev].get_vector_out().length()
			_segments[prev].set_vector_out(
					-1.0 * _segments[i].get_vector_in().normalized() * length)
		
		if ! _segments[prev] is SVGSegmentQuadratic:
			return


func _mirror_handles_forward(start_index :int) -> void:
	if ! _is_ready:
		return
	for i in range(start_index, _segments.size() - 1):
		var next = i + 1
		if ! _segments[next].get("mirror_previous_angle"):
			return
		if ! _segments[i].has_method("get_vector_out"):
			return
		if ! _segments[next].has_method("set_vector_in"):
			return
		
		if _segments[next].get("mirror_previous_length"):
			_segments[next].set_vector_in(-1.0 * _segments[i].get_vector_out())
		else:
			var length = _segments[next].get_vector_in().length()
			_segments[next].set_vector_in(
					-1.0 * _segments[i].get_vector_out().normalized() * length)
		
		if ! _segments[next] is SVGSegmentQuadratic:
			return


func _on_path_changed() -> void:
	if caching_enabled:
		cache_clear()
	emit_changed()


# Resize the segments array, ensuring that all new values default to a new
# SVGSegmentLine
func _resize_segments_array(new_size :int) -> void:
	_segments.resize(new_size)
	for i in _segments.size():
		if ! _segments[i] is SVGSegment:
			_segments[i] = SVGSegmentLine.new()


func _set_segments_count(value: int) -> void:
	if value != _segments.size():
		_resize_segments_array(value)
		notify_property_list_changed()
		_on_path_changed()


# Set the type of an existing segment, keeping values where possible, and
# returning a bool to indicate whether the type has changed
func _set_segment_type(segment_index :int, type :SegmentType) -> bool:
	var segment = _segments[segment_index]
	match type:
		SegmentType.LINE:
			if ! segment is SVGSegmentLine:
				_segments[segment_index] = SVGSegmentLine.new(segment)
				return true
		SegmentType.QUADRATIC:
			if ! segment is SVGSegmentQuadratic:
				_segments[segment_index] = SVGSegmentQuadratic.new(segment)
				return true
		SegmentType.CUBIC:
			if ! segment is SVGSegmentCubic:
				_segments[segment_index] = SVGSegmentCubic.new(segment)
				return true
		SegmentType.ARC:
			if ! segment is SVGSegmentArc:
				_segments[segment_index] = SVGSegmentArc.new(segment)
				return true
	return false



# Set the segment start point to match the previous segment's end point,
# return bool has_changed
func _resync_segment_start_point(segment_index :int) -> bool:
	var previous_end_point = _segments[segment_index-1].get("end_point")
	var old_value = _segments[segment_index].get("start_point")
	if old_value != previous_end_point:
		_segments[segment_index].set("start_point", previous_end_point)
		return true
	return false
