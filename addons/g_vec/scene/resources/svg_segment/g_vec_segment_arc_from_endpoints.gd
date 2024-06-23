@tool
class_name GVecSegmentArcFromEndpoints
extends GVecSegment
## This class defines an elliptical arc segment for an [SVGPath].
## Its behaviour is based on the SVG specifications.


## Radii of the ellipse (will scale up if necessary to fit).
@export var radii := Vector2.ONE:
	set(value):
		if radii != value:
			radii = value
			_is_dirty = true

## Angle between the x-axis of the ellipse and the local x-axis
## (Measured in radians)
@export var ellipse_rotation := 0.0:
	set(value):
		if ellipse_rotation != value:
			ellipse_rotation = value
			_is_dirty = true

## If true, use the larger arc of the ellipse
@export var large_arc_flag := false:
	set(value):
		if large_arc_flag != value:
			large_arc_flag = value
			_is_dirty = true

## If true, select whichever candidate ellipse results in a clockwise
## path around the center
@export var sweep_flag := true:
	set(value):
		if sweep_flag != value:
			sweep_flag = value
			_is_dirty = true


# Private vars:
var _adjusted_radii: Vector2
var _center: Vector2
var _start_angle_parameter: float
var _central_angle_parameter: float


func _init(old_segment = {}) -> void:
	if not old_segment is Object:
		super(old_segment)
	elif old_segment.has_method("get_endpoint_parameters"):
		super(old_segment.get_endpoint_parameters())
	else:
		super(old_segment)


## Re-generate the baked points cache for this segment.
## Should be called automatically as needed, no need to call manually.
func bake() -> void:
	_is_dirty = false
	if radii.x == 0 or radii.y == 0:
		_bake_as_line()
		return
	_parameterize()
	_bake_from_parameters()


func get_center_parameters() -> Dictionary:
	return {
		"start_point": start_point,
		"radii": radii,
		"ellipse_rotation": ellipse_rotation,
		"center": _center,
		"central_angle_parameter": _central_angle_parameter
	}


## Returns a position on the segment between the start point (t=0.0)
## and the end point (t=1). (Values outside this range will still follow
## the chosen ellipse).
func sample(t :float) -> Vector2:
	if _is_dirty:
		bake()
	var p = _start_angle_parameter + t * _central_angle_parameter
	var point := _center + (
			Vector2.RIGHT.rotated(p) * _adjusted_radii
			).rotated(ellipse_rotation)
	return point


func get_vector_out() -> Vector2:
	if _is_dirty:
		bake()
	var end_angle = _start_angle_parameter + _central_angle_parameter
	return (Vector2.DOWN.rotated(end_angle)
			* _adjusted_radii).rotated(ellipse_rotation)


# Generate center parameterization from endpoint parameterization
func _parameterize() -> void:
	_adjusted_radii = radii.abs()
	
	var start_point_prime := (
			0.5 * (start_point - end_point)).rotated(-ellipse_rotation)
	
	var r2 := _adjusted_radii * _adjusted_radii
	var prime2 := start_point_prime * start_point_prime
	
	var scale_factor := (prime2.x/r2.x) + (prime2.y/r2.y)
	
	var center_prime :Vector2
	if scale_factor > 1.0:
		scale_factor = sqrt(scale_factor)
		_adjusted_radii *= scale_factor
		_center = lerp(start_point, end_point, 0.5)
		center_prime = Vector2.ZERO
	else:
		center_prime = Vector2(
				_adjusted_radii.x * start_point_prime.y / _adjusted_radii.y,
				- _adjusted_radii.y * start_point_prime.x / _adjusted_radii.x
				) * sqrt(
				((r2.x * r2.y) - (r2.x * prime2.y) - (r2.y * prime2.x))
				/ ((r2.x * prime2.y) + (r2.y * prime2.x))
				)
		if large_arc_flag == sweep_flag:
			center_prime *= -1.0
		_center = center_prime.rotated(ellipse_rotation) + lerp(
				start_point, end_point, 0.5)
	
	var start_point_rel := (start_point_prime - center_prime) / _adjusted_radii
	
	_start_angle_parameter = start_point_rel.angle()
	_central_angle_parameter = start_point_rel.angle_to(
			( - start_point_prime - center_prime) / _adjusted_radii)
	
	if sweep_flag:
		_central_angle_parameter = wrapf(_central_angle_parameter, 0.0, 2.0 * PI)
	else:
		_central_angle_parameter = wrapf(_central_angle_parameter, -2.0 * PI, 0.0)


func _bake_from_parameters() -> void:
	var small := min(_adjusted_radii.x, _adjusted_radii.y)
	var large := max(_adjusted_radii.x, _adjusted_radii.y)
	var avg := lerpf(small, large, 0.5)
	var avg_angle := bake_interval / avg
	var count := roundi(absf(_central_angle_parameter) / avg_angle)
	
	if count < 2:
		_baked_points = PackedVector2Array([start_point, end_point])
		return
	
	_baked_points = PackedVector2Array([])
	var f_interval := 1.0 / count
	for i in count + 1:
		var p := i * f_interval
		_baked_points.append(sample(p))


## Re-generate baked points on a straight line from start to end point
func _bake_as_line() -> void:
	_baked_points = PackedVector2Array()
	var actual_length = start_point.distance_to(end_point)
	var f_count :float = round(actual_length / bake_interval)
	
	if f_count < 2:
		_baked_points = PackedVector2Array([start_point, end_point])
		return
	
	var f_interval := 1.0 / f_count
	for i in f_count + 1:
		var p := i * f_interval
		_baked_points.append(lerp(start_point, end_point, p))
