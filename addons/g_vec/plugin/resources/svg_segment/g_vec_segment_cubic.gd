@tool
class_name GVecSegmentCubic
extends GVecSegment

## This class defines a Bézier cubic segment for an [SVGPath].
##
## This class defines a Bézier cubic segment for an [SVGPath].
## It uses Godot's Curve2D internally, acting as a wrapper.

## Incoming control point (relative to path)
@export var start_control_point := Vector2.ZERO:
	set(value):
		if start_control_point != value:
			start_control_point = value
			_is_dirty = true

## Outgoing control point (relative to path)
@export var end_control_point := Vector2.ZERO:
	set(value):
		if end_control_point != value:
			end_control_point = value
			_is_dirty = true

var _curve = Curve2D.new()


func _init(old_segment = {}) -> void:
	super(old_segment)
	start_control_point = start_point
	end_control_point = end_point
	if old_segment.get("start_control_point") != null:
		start_control_point = old_segment.start_control_point
	if old_segment.get("end_control_point") != null:
		end_control_point = old_segment.end_control_point
	if old_segment.get("control_point") != null:
		start_control_point = lerp(start_point, old_segment.control_point, 0.75)
		end_control_point = lerp(end_point, old_segment.control_point, 0.75)
	_curve.add_point(start_point)
	_curve.add_point(end_point)


## Re-generate the baked points cache for this segment.
## Should be called automatically as needed, no need to call manually.
func bake() -> void:
	_curve.set_point_position(0, start_point)
	_curve.set_point_out(0, start_control_point - start_point)
	_curve.set_point_position(1, end_point)
	_curve.set_point_in(1, end_control_point - end_point)
	_curve.bake_interval = bake_interval
	_baked_points = _curve.get_baked_points()


## Get the position of [member start_control_point] relative to
## [member start_point]
func get_vector_in() -> Vector2:
	return start_control_point - start_point


## Get the position of [member end_control_point] relative to
## [member end_point]
func get_vector_out() -> Vector2:
	return end_control_point - end_point


## Returns a position on the segment between the start point (t=0.0)
## and the end point (t=1). Values outside this range give strange but
## predictable results.
func sample(t :float) -> Vector2:
	if _is_dirty:
		bake()
	return _curve.sample(0, t)


## Set the position of [member start_control_point] relative to
## [member start_point]
func set_vector_in(value: Vector2) -> void:
	start_control_point = start_point + value


## Set the position of [member end_control_point] relative to
## [member end_point]
func set_vector_out(value: Vector2) -> void:
	end_control_point = end_point + value
