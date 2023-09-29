@tool
class_name GVecPathSVG
extends GVecPath

## Describes a shape in 2D space.
##
## This class describes a shape in 2D space, made up of segments which can be
## straight lines, Bézier quadritic curves, Bézier cubic curves,
## and/or elliptical arcs. Loosely based on the SVG specifications.


## This signal indicates that the count or type of segments have changed
## (not just the parameters of segments)
signal segments_changed

## Enumerated values for segment type
enum SegmentType {
	LINE       = 0, ## Indicates a straight-line
	QUADRATIC  = 1, ## Indicates a Bézier quadratic curve
	CUBIC      = 2, ## Indicates a Bézier cubic curve
	ARC_END    = 3, ## Indicates an elliptical arc with endpoint parameters
	ARC_CENTER = 4, ## Indicates an elliptical arc with center parameterization
}

# An internal array of Segment objects
var _segments: Array[GVecSegment] = []


# ----------
# Beginning of virtual methods


# The property list exposes segments as a properties array
func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary] = [] as Array[Dictionary]
	properties.append({
		"name": _segments,
		"type": TYPE_ARRAY,
		"usage": PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_ALWAYS_DUPLICATE
	})
	properties.append({
		"name": "segment_count",
		"type": TYPE_INT,
		"usage": PROPERTY_USAGE_ARRAY | PROPERTY_USAGE_DEFAULT,
		"class_name": "Segments,segment_",
		"hint": PROPERTY_HINT_NONE
	})
	for segment_index in _segments.size():
		properties.append_array(get_segment_property_list(segment_index))
	return properties


# This custom setter handles the property list of segment properties
# Segment properties should only be set via this method, to preserve integrity
func _set(property, value) -> bool:
	if property == "segment_count":
		_set_segments_count(value)
		return true
	
	if ! is_segment_property(property):
		return false
	
	var parts := segment_name_to_property(property)
	var segment_index: int = parts[0]
	var segment_property: String = parts[1]
	var segment := _segments[segment_index] as GVecSegment
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
			_segments[segment_index].set(segment_property, value)
			has_changed = (segment.get(segment_property) != old_value)
	
	if segment_property == "end_point":
		var next := segment_index + 1
		if next < _segments.size():
			_resync_segment_start_point(next)
	
	if has_changed:
		_on_path_changed()
	
	return true


# This custom getter handles the property list of segment properties
func _get(property):
	if property == "segment_count":
		return _segments.size()
	
	if ! is_segment_property(property):
		return
	
	var parts := segment_name_to_property(property)
	var segment_index :int = parts[0]
	var segment_property :String = parts[1]
	if segment_index >= _segments.size():
		return null
	var segment = _segments[segment_index]
	
	if segment_property == "segment_type":
		return get_segment_type(segment)
	else:
		return segment.get(segment_property)


# ----------
# Beginning of public methods


## Get a property of a segment
func get_segment_property(
		segment_index: int,
		property_name: String
):
	get(segment_property_to_name(
			segment_index, property_name))


## Get a list of properties exposed for a given segment,
## as per [member get_property_list]
func get_segment_property_list(segment_index: int) -> Array[Dictionary]:
	var properties = [] as Array[Dictionary]
	properties.append({
		"name": segment_property_to_name(segment_index, "segment_type"),
		"type": TYPE_INT,
		"usage": PROPERTY_USAGE_EDITOR,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": "Line,Quadratic,Cubic,Arc"
	})
	for property in _segments[segment_index].get_property_list():
		if ! (property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		if segment_index > 0 and property.name == 'start_point':
			continue
		property.name = segment_property_to_name(segment_index, property.name)
		property.usage = PROPERTY_USAGE_EDITOR
		properties.append(property)
	return properties


func insert_new_segment(segment_index: int = -1) -> void:
	_segments.insert(segment_index, GVecSegmentLine.new())


func is_closed() -> bool:
	return _segments[0].start_point == _segments[-1].end_point


## Remove a segment (default to the last segment)
func remove_segment(segment_index: int = -1) -> void:
	assert(segment_index > -2)
	if segment_index == -1:
		segment_index = _segments.size() - 1
	_segments.remove_at(segment_index)
	
	if segment_index > 0 and segment_index < _segments.size():
		_resync_segment_start_point(segment_index)
	
	_on_path_changed()


## Set a property of a segment
func set_segment_property(
		segment_index: int,
		property_name: String,
		value
		) -> void:
	set(segment_property_to_name(
			segment_index, property_name), value)


# ----------
# Begin static methods


## Return the type of a segment object
static func get_segment_type(segment: GVecSegment) -> SegmentType:
	if segment is GVecSegmentArcFromCenter:
		return SegmentType.ARC_CENTER
	elif segment is GVecSegmentArcFromEndpoints:
		return SegmentType.ARC_END
	elif segment is GVecSegmentCubic:
		return SegmentType.CUBIC
	elif segment is GVecSegmentQuadratic:
		return SegmentType.QUADRATIC
	else:
		return SegmentType.LINE


## Return the segment_index and property_name (as an Array of two values)
## from a segment properties array name
static func segment_name_to_property(name: String) -> Array:
	var parts := name.trim_prefix("segment_").split("/")
	return [parts[0].to_int(), parts[1]]


## Return the properties array name
## that maps to a segment index and property
static func segment_property_to_name(
		segment_index: int,
		property: String
) -> String:
	return "segment_%d/%s" % [segment_index, property]


## Test if the supplied property name
## is part of the segment properties array
static func is_segment_property(name: String) -> bool:
	return name.begins_with("segment_")


# ----------
# Begin private methods


func _calculate_baked_length() -> float:
	var length: float = 0.0
	for segment in _segments:
		if ! segment is GVecSegment:
			continue
		length += segment.get_baked_length()
	return length


func _calculate_baked_points() -> PackedVector2Array:
	var points = PackedVector2Array()
	for segment in _segments:
		if ! segment is GVecSegment:
			continue
		if points.size() > 0:
			points += segment.get_baked_points().slice(1)
		else:
			points += segment.get_baked_points()
	return points


func _calculate_segment_length(segment_index: int) -> float:
	return _segments[segment_index].get_baked_length()


func _calculate_segment_points(segment_index: int) -> PackedVector2Array:
	return _segments[segment_index].get_baked_points()


func _on_path_changed() -> void:
	if caching_enabled:
		cache_clear()
	emit_changed()


func _set_segments_count(value: int) -> void:
	if value == _segments.size():
		return
	_segments.resize(value)
	for i in _segments.size():
		if ! _segments[i] is GVecSegment:
			_segments[i] = GVecSegmentLine.new()
	notify_property_list_changed()
	segments_changed.emit()
	_on_path_changed()


func _set_segment_type(segment_index: int, type: SegmentType) -> bool:
	var segment = _segments[segment_index]
	var old_type := get_segment_type(segment)
	if type == old_type:
		return false
	match type:
		SegmentType.LINE:
			_segments[segment_index] = GVecSegmentLine.new(segment)
		SegmentType.QUADRATIC:
			_segments[segment_index] = GVecSegmentQuadratic.new(segment)
		SegmentType.CUBIC:
			_segments[segment_index] = GVecSegmentCubic.new(segment)
		SegmentType.ARC_CENTER:
			_segments[segment_index] = GVecSegmentArcFromCenter.new(segment)
		SegmentType.ARC_END:
			_segments[segment_index] = GVecSegmentArcFromEndpoints.new(segment)
	segments_changed.emit()
	return true


func _resync_segment_start_point(segment_index: int) -> bool:
	var previous_end_point = _segments[segment_index-1].get("end_point")
	var old_value = _segments[segment_index].get("start_point")
	if old_value != previous_end_point:
		_segments[segment_index].set("start_point", previous_end_point)
		return true
	return false
