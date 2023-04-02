@tool
class_name SVGSegmentProperties
extends Object
## This class of static method is used by SVGPath, to define the properties
## array that is exported to the editor, for interface with the underlying
## array of SVGSegment elements

## Return an array of dictionaries as per _get_property_list
static func get_list(
		segments :Array[SVGSegment],
		segment_index :int
) -> Array[Dictionary]:
	var properties :Array[Dictionary] = []
	var segment = segments[segment_index]
	
	if segment is SVGSegmentLine:
		properties.append_array(_line_segment_property_list(segment_index))
	
	elif segment is SVGSegmentQuadratic:
		properties.append_array(_quadratic_segment_property_list(segment_index))
	
	elif segment is SVGSegmentCubic:
		properties.append_array(_cubic_segment_property_list(segment_index))
	
	elif segment is SVGSegmentArc:
		match segment.calc_mode:
			SVGSegmentArc.CalcMode.ENDPOINT:
				properties.append_array(
						_arc_segment_endpoint_property_list(segment_index))
			SVGSegmentArc.CalcMode.CENTER:
				properties.append_array(
						_arc_segment_center_property_list(segment_index))
		
	return properties
	
## Return the segment_index and property_name (as an Array of two values)
## from a segment properties array name
static func segment_name_to_property(name :String) -> Array:
	var parts := name.trim_prefix("segment_").split("/")
	return [parts[0].to_int(), parts[1]]


## Return the properties array name
## that maps to a segment index and property
static func segment_property_to_name(
		segment_index :int,
		property :String
) -> String:
	return "segment_%d/%s" % [segment_index, property]


## Test if the supplied property name
## is part of the segment properties array
static func is_segment_property(
		name :String
) -> bool:
	return name.begins_with("segment_")


# Return the property list for a line segment
static func _line_segment_property_list(
		segment_index :int
) -> Array[Dictionary]:
	return [
		_segment_type(segment_index),
		_start_point(segment_index),
		_property_vec2(segment_index, "end_point"),
		_property_bake_interval(segment_index),
	]


# Return the property list for a Bézier quadratic segment
static func _quadratic_segment_property_list(
		segment_index :int
) -> Array[Dictionary]:
	var properties: Array[Dictionary] = [
		_segment_type(segment_index),
		_start_point(segment_index),
		_property_vec2(segment_index, "end_point"),
		_property_vec2(segment_index, "control_point"),
	]
	if segment_index > 0:
		properties.append_array([
			_property_bool(segment_index, "mirror_previous_angle"),
			_property_bool(segment_index, "mirror_previous_length"),
		])
	properties.append(_property_bake_interval(segment_index))
	return properties


# Return the property list for a Bézier cubic segment
static func _cubic_segment_property_list(
		segment_index :int
) -> Array[Dictionary]:
	var properties: Array[Dictionary] = [
		_segment_type(segment_index),
		_start_point(segment_index),
		_property_vec2(segment_index, "end_point"),
		_property_vec2(segment_index, "start_control_point"),
		_property_vec2(segment_index, "end_control_point"),
	]
	if segment_index > 0:
		properties.append_array([
			_property_bool(segment_index, "mirror_previous_angle"),
			_property_bool(segment_index, "mirror_previous_length"),
		])
	properties.append(_property_bake_interval(segment_index))
	return properties


# Return the property list for an elliptical arc segmentin ENDPOINT mode
static func _arc_segment_endpoint_property_list(
		segment_index :int
) -> Array[Dictionary]:
	return [
		_segment_type(segment_index),
		_arc_calc_mode(segment_index),
		_start_point(segment_index),
		_property_vec2(segment_index, "end_point"),
		_property_vec2(segment_index, "radii"),
		_property_float(segment_index, "ellipse_rotation"),
		_property_bool(segment_index, "large_arc_flag"),
		_property_bool(segment_index, "sweep_flag"),
		_property_bake_interval(segment_index),
	]


# Return the property list for an elliptical arc segmentin CENTER mode
static func _arc_segment_center_property_list(
		segment_index :int
) -> Array[Dictionary]:
	return [
		_segment_type(segment_index),
		_arc_calc_mode(segment_index),
		_start_point(segment_index),
		_property_vec2(segment_index, "center"),
		_property_vec2(segment_index, "radii"),
		_property_float(segment_index, "ellipse_rotation"),
		_property_float(segment_index, "central_angle_parameter"),
		_property_bake_interval(segment_index),
	]


# Return the dictionary that defines the "segment_type" property
static func _segment_type(segment_index :int) -> Dictionary:
	return {
		"name": segment_property_to_name(segment_index, "segment_type"),
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": "Line,Quadratic,Cubic,Arc"
	}


# Returns the dictionary that defines a "start_point" property
static func _start_point(segment_index :int) -> Dictionary:
	if segment_index == 0:
		return {
			"name": segment_property_to_name(segment_index, "start_point"),
			"type": TYPE_VECTOR2
		}
	else:
		return {
			"name": segment_property_to_name(segment_index, "start_point"),
			"type": TYPE_VECTOR2,
			"usage": PROPERTY_USAGE_INTERNAL
		}


static func _arc_calc_mode(segment_index :int) -> Dictionary:
	return {
		"name": segment_property_to_name(segment_index, "calc_mode"),
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": "Endpoint,Center"
	}


# Returns the dictionary for a property of type Vec2
static func _property_vec2(
		segment_index :int,
		property_name :String
) -> Dictionary:
	return {
		"name": segment_property_to_name(segment_index, property_name),
		"type": TYPE_VECTOR2
	}


# Returns the dictionary for a property of type float
static func _property_float(
		segment_index :int,
		property_name :String
) -> Dictionary:
	return {
		"name": segment_property_to_name(segment_index, property_name),
		"type": TYPE_FLOAT
	}


# Returns the dictionary for a property of type bool
static func _property_bool(
		segment_index :int,
		property_name :String
) -> Dictionary:
	return {
		"name": segment_property_to_name(segment_index, property_name),
		"type": TYPE_BOOL
	}


# Return the dictionary for a "baked_points" property
static func _property_bake_interval(segment_index :int) -> Dictionary:
	return {
		"name": segment_property_to_name(segment_index, "bake_interval"),
		"type": TYPE_FLOAT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0,512"
	}
