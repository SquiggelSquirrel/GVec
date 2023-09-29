@tool
class_name GVecSegmentArcFromCenter
extends GVecSegment
## This class defines an elliptical arc segment for an [SVGPath],
## using center-point parameterization

## Radii of the ellipse (will scale as necessary to fit).
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

## Center point of the ellipse
@export var center :Vector2:
	set(value):
		if value != center:
			center = value
			_is_dirty = true

## Parameter delta for standard parametric representation
## (aka. center parameterization).
## Positive values will extend the arc clockwise from the start point,
## negative values will extend counter-clockwise. Measured in radians.
@export var central_angle_parameter :float:
	set(value):
		if value != central_angle_parameter:
			central_angle_parameter = wrapf(value, -2.0 * PI, 2.0 * PI)
			_central_angle_is_dirty = true

# Private vars:
# ============
var _start_angle_parameter :float
var _adjusted_radii :Vector2
var _central_angle_is_dirty := false


func _set(property, value):
	if property == "end_point":
		central_angle_parameter = angle_parameter_to_point(value)
		end_point = sample(1.0)


func _init(old_segment = {}) -> void:
	if not old_segment is Object:
		super(old_segment)
	elif old_segment.has_method("get_center_parameters"):
		super(old_segment.get_center_parameters())
	else:
		super(old_segment)


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


func get_endpoint_parameters() -> Dictionary:
	return {
		"start_point": start_point,
		"radii": radii,
		"ellipse_rotation": ellipse_rotation,
		"large_arc_flag": bool(abs(central_angle_parameter) > PI),
		"sweep_flag": bool(central_angle_parameter > 0),
		"end_point": sample(1.0)
	}


## Get the angle parameter closest to a target point
func angle_parameter_to_point(point :Vector2) -> float:
	if _is_dirty:
		bake()
	return (
			(point - center).rotated(-ellipse_rotation) / _adjusted_radii
			).angle()


## Re-generate the baked points cache for this segment.
## Should be called automatically as needed, no need to call manually.
func bake() -> void:
	_is_dirty = false
	
	if radii.x == 0 or radii.y == 0:
		_bake_as_line()
		return
	
	parameterize()
	bake_no_parameterize()


## Re-generate points without re-parameterizing first, except that central
## angle may have changed.
func bake_no_parameterize() -> void:
	_central_angle_is_dirty = false
	_is_dirty = false
	
	var small := min(_adjusted_radii.x, _adjusted_radii.y)
	var large := max(_adjusted_radii.x, _adjusted_radii.y)
	var avg := lerpf(small, large, 0.5)
	var avg_angle := bake_interval / avg
	var count := roundi(absf(central_angle_parameter) / avg_angle)
	
	if count < 2:
		_baked_points = PackedVector2Array([start_point, end_point])
		return
	
	_baked_points = PackedVector2Array([])
	var f_interval := signf(central_angle_parameter) / count
	for i in count + 1:
		var p := _start_angle_parameter + i * f_interval
		_baked_points.append(sample(p))


## Re-generate ellipse parameters (adjusted radii and start angle parameter)
func parameterize() -> void:
	var start_point_rel := (start_point - center).rotated(-ellipse_rotation)
	_adjusted_radii = radii.abs()
	var r2 := _adjusted_radii * _adjusted_radii
	var prime2 := start_point_rel * start_point_rel
	_adjusted_radii *= sqrt((prime2.x/r2.x) + (prime2.y/r2.y))
	
	_start_angle_parameter = (
			start_point_rel / _adjusted_radii
			).angle()


## Returns a position on the segment between the start point (t=0.0)
## and the end point (t=1). (Values outside this range will still follow
## the chosen ellipse).
func sample(t :float) -> Vector2:
	if _is_dirty:
		bake()
	var p = _start_angle_parameter + t * central_angle_parameter
	var point := center + (
			Vector2.RIGHT.rotated(p) * _adjusted_radii
			).rotated(ellipse_rotation)
	return point


## Re-generate baked points on a straight line from start to end point
func _bake_as_line() -> void:
	var _end_point = lerp(start_point, center, 2.0)
	_baked_points = PackedVector2Array()
	var actual_length = start_point.distance_to(_end_point)
	var f_count :float = round(actual_length / bake_interval)
	
	if f_count < 2:
		_baked_points = PackedVector2Array([start_point, _end_point])
		return
	
	var f_interval := 1.0 / f_count
	for i in f_count + 1:
		var p := i * f_interval
		_baked_points.append(lerp(start_point, _end_point, p))
