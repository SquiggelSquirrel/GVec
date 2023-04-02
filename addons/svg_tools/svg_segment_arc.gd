class_name SVGSegmentArc
extends SVGSegment
## This class defines an elliptical arc segment for an [SVGPath].
## Its behaviour is based on the SVG specifications.


## Options for calculation mode of the elliptical arc.
enum CalcMode {
	ENDPOINT, ## Set both endpoints, calculate center from radii and angle
	CENTER, ## Set start point, center point, and angle delta. Scale radii to
		## fit, and calculate end point from that.
}


## The calculation mode to use - see [enum CalcMode]
var calc_mode := CalcMode.ENDPOINT:
	set(value):
		if value != calc_mode:
			calc_mode = value
			if calc_mode == CalcMode.ENDPOINT:
				radii = _adjusted_radii
			_is_dirty = true
			bake()

## Radii of the ellipse (will scale up if necessary to fit, and will scale down
## in center mode if necessary to fit).
var radii := Vector2.ONE:
	set(value):
		if radii != value:
			radii = value
			_is_dirty = true

## Angle between the x-axis of the ellipse and the local x-axis
## (Measured in radians)
var ellipse_rotation := 0.0:
	set(value):
		if ellipse_rotation != value:
			ellipse_rotation = value
			_is_dirty = true

## If true, use the larger arc of the ellipse
var large_arc_flag := false:
	set(value):
		if large_arc_flag != value:
			large_arc_flag = value
			_is_dirty = true

## If true, select whichever candidate ellipse results in a clockwise
## path around the center
var sweep_flag := true:
	set(value):
		if sweep_flag != value:
			sweep_flag = value
			_is_dirty = true

## Center point of the ellipse
var center :Vector2:
	set(value):
		if value != center:
			center = value
			_is_dirty = true

## Starting "angle" parameter for standard parametric representation
## (aka. center parameterization). Measured in radians.
var start_angle_parameter :float:
	set(value):
		if value != start_angle_parameter:
			start_angle_parameter = value


## Parameter delta for standard parametric representation
## (aka. center parameterization).
## Positive values will extend the arc clockwise from the start point,
## negative values will extend counter-clockwise. Measured in radians.
var central_angle_parameter :float:
	set(value):
		if value != central_angle_parameter:
			central_angle_parameter = wrapf(value, -2.0 * PI, 2.0 * PI)
			_central_angle_is_dirty = true

var _adjusted_radii :Vector2
var _parameterizing := false
var _central_angle_is_dirty := false


func get_baked_points() -> PackedVector2Array:
	if _is_dirty:
		bake()
	if _central_angle_is_dirty:
		bake_no_parameterize()
	return super()


func get_baked_length() -> float:
	if _is_dirty:
		bake()
	if _central_angle_is_dirty:
		bake_no_parameterize()
	return super()


## Get the angle parameter closest to a target point
func angle_parameter_to_point(point :Vector2) -> float:
	return (
			(point - center).rotated(-ellipse_rotation) / _adjusted_radii
			).angle()


## Re-generate the baked points cache for this segment.
## Should be called automatically as needed, no need to call manually.
func bake() -> void:
	_is_dirty = false
	if radii.x == 0 or radii.y == 0:
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
			return
	match calc_mode:
		CalcMode.ENDPOINT:
			_parameterize_endpoint_to_center()
		CalcMode.CENTER:
			_parameterize_center_to_endpoint()
	bake_no_parameterize()


## Re-generate points without re-parameterizing first, except that central
## angle may have changed.
func bake_no_parameterize() -> void:
	_central_angle_is_dirty = false
	
	if calc_mode == CalcMode.CENTER:
		_parameterizing = true
		end_point = sample(1.0)
		large_arc_flag = bool(abs(central_angle_parameter) > PI)
		sweep_flag = bool(central_angle_parameter > 0)
		_parameterizing = false
	
	_is_dirty = false
	_baked_points = PackedVector2Array([])
	_baked_points.append(start_point)
	_baked_points += _get_baked_points_range(0.0, 1.0)
	_baked_points.append(end_point)


## Returns a position on the segment between the start point (t=0.0)
## and the end point (t=1). (Values outside this range will still follow
## the chosen ellipse).
func sample(t :float) -> Vector2:
	if _is_dirty:
		bake()
	var p = start_angle_parameter + t * central_angle_parameter
	var point := center + (
			Vector2.RIGHT.rotated(p) * _adjusted_radii
			).rotated(ellipse_rotation)
	return point


# Generate endpoint parameterization from center parameterization
func _parameterize_center_to_endpoint() -> void:
	_parameterizing = true
	var start_point_rel := (start_point - center).rotated(-ellipse_rotation)
	_adjusted_radii = radii.abs()
	var r2 := _adjusted_radii * _adjusted_radii
	var prime2 := start_point_rel * start_point_rel
	_adjusted_radii *= sqrt((prime2.x/r2.x) + (prime2.y/r2.y))
	
	start_angle_parameter = (
			start_point_rel / _adjusted_radii
			).angle()
	_parameterizing = false


# Generate center parameterization from endpoint parameterization
func _parameterize_endpoint_to_center() -> void:
	_parameterizing = true
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
		center = lerp(start_point, end_point, 0.5)
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
		center = center_prime.rotated(ellipse_rotation) + lerp(
				start_point, end_point, 0.5)
	
	var start_point_rel := (start_point_prime - center_prime) / _adjusted_radii
	
	start_angle_parameter = start_point_rel.angle()
	central_angle_parameter = start_point_rel.angle_to(
			( - start_point_prime - center_prime) / _adjusted_radii)
	
	if sweep_flag:
		central_angle_parameter = wrapf(central_angle_parameter, 0.0, 2.0 * PI)
	else:
		central_angle_parameter = wrapf(central_angle_parameter, -2.0 * PI, 0.0)
	_central_angle_is_dirty = false
	_parameterizing = false


# Returns a PackedVector2Array of the baked points between start and end
# vaues of t (exclusive). Recursive. Used from bake().s
func _get_baked_points_range(
		start: float, end: float
		) -> PackedVector2Array:
	var middle = (start + end) * 0.5
	var range_start_point := sample(start)
	var range_end_point := sample(end)
	var mid_point := sample(middle)
	
	var left_points :PackedVector2Array
	if range_start_point.distance_to(mid_point) > bake_interval:
		left_points = _get_baked_points_range(start, middle)
	else:
		left_points = PackedVector2Array()
		
	var right_points :PackedVector2Array
	if range_end_point.distance_to(mid_point) > bake_interval:
		right_points = _get_baked_points_range(middle, end)
	else:
		right_points = PackedVector2Array()
	
	return left_points + PackedVector2Array([mid_point]) + right_points
