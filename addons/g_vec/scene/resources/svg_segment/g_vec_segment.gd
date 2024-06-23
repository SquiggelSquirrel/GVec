@tool
class_name GVecSegment
extends Resource

## Base for all segment classes used by [GVecPathSVG]
##
## This class is not intended for direct instantiation.[br]
## It defines a base for all Segment classes used by [GVecPathSVG]

## The start point of this segment
@export var start_point := Vector2.ZERO:
	set(value):
		if start_point != value:
			start_point = value
			_is_dirty = true
			
## The end point of this segment
@export var end_point := Vector2.ZERO:
	set(value):
		if end_point != value:
			end_point = value
			_is_dirty = true
			
## The bake interval of this segment
## - baked points should be no more than this pixel distance apart
## (approximately)
@export_range(0, 512, 1, "or_greater") var bake_interval := 5.0:
	set(value):
		if bake_interval != value:
			bake_interval = max(value,0.1)
			_is_dirty = true

# Internal cache of baked points for this segment
var _baked_points := PackedVector2Array()

# Flag if the internal cache of points needs to be re-calculated
var _is_dirty := true:
	set(value):
		if _is_dirty != value:
			_is_dirty = value
			emit_changed()


# Initialise this segment, optionally copying properties from a
# different segment or configuration [Dictionary]
func _init(old_segment = {}):
	for property in _get_copyable_property_names():
		var old = old_segment.get(property)
		if old != null:
			set(property, old)


## Returns the cache of points as a [PackedVector2Array]
func get_baked_points() -> PackedVector2Array:
	if _is_dirty:
		bake()
	return _baked_points


## Re-generate the baked points cache for this segment.
## Should be called automatically as needed, no need to call manually.
## (Implementing sub-classes *must* override this method).
func bake() -> void:
	@warning_ignore("assert_always_false")
	assert(false)


## Return the total length of the path, based on the baked points
func get_baked_length() -> float:
	if _is_dirty:
		bake()
	var length := 0.0
	for i in range(1, _baked_points.size()):
		length += _baked_points[i].distance_to(_baked_points[i - 1])
	return length


# Return a [PackedStringArray] containing names of properties which can be
# copied from a different segment in initialisation
func _get_copyable_property_names() -> PackedStringArray:
	var names := PackedStringArray()
	for property in get_property_list():
		if ! (property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		if ! (property.usage & PROPERTY_USAGE_EDITOR):
			continue
		names.append(property.name)
	return names
