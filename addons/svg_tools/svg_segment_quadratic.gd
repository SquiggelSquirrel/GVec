@tool
class_name SVGSegmentQuadratic
extends SVGSegment

## This class defines a Bézier quadratic segment for an [SVGPath]

## Position of the segment's control point.
@export var control_point := Vector2.ZERO:
	set(value):
		if control_point != value:
			control_point = value
			_is_dirty = true

@export var mirror_previous_angle := false
@export var mirror_previous_length := false


func _init(old_segment = {}):
	super(old_segment)
	if old_segment.get("control_point") != null:
		control_point = old_segment.get("control_point")
	elif old_segment is SVGSegmentCubic:
		control_point = 0.5 * (
				old_segment.start_control_point + old_segment.end_control_point)
	else:
		control_point = 0.5 * (start_point + end_point)


## Re-generate the baked points cache for this segment.
## Should be called automatically as needed, no need to call manually.
func bake():
	_is_dirty = false
	_baked_points = PackedVector2Array()
	var lower_bound := start_point.distance_to(end_point)
	var upper_bound := start_point.distance_to(control_point) + control_point.distance_to(end_point)
	var estimated_length := lerpf(lower_bound, upper_bound, 0.5)
	var bake_resolution := ceili(estimated_length / bake_interval)
	for i in bake_resolution:
		var f := float(i) / (bake_resolution - 1)
		_baked_points.append(sample(f))


## Get the position of [member control_point] relative to [member start_point]
func get_vector_in() -> Vector2:
	return control_point - start_point


## Get the position of [member control_point] relative to [member end_point]
func get_vector_out() -> Vector2:
	return control_point - end_point


## Returns a position on the segment between the start point (t=0.0)
## and the end point (t=1). Values outside this range give strange but
## predictable results.
func sample(t: float) -> Vector2:
	if _is_dirty:
		bake()
	return lerp(
			lerp(start_point, control_point, t),
			lerp(control_point, end_point, t),
			t)


## Set the position of [member control_point] relative to [member start_point]
func set_vector_in(value: Vector2) -> void:
	control_point = start_point + value


## Set the position of [member control_point] relative to [member end_point]
func set_vector_out(value: Vector2) -> void:
	control_point = end_point + value
