@tool
class_name PathShape2DTween
extends PathShape2DCombination

## Tweens two [PathShape2D] baked points.
##
## This resource stores an array of [PathShape2D] resources, and generates
## a [PackedVector2Array] from between two of them, depending on
## [member tween_parameter]. This should perform better than modifying the
## parameters of a [SVGPath] or [Curve2D] at runtime, and allows for tween
## shapes that would not otherwise be possible.


## The interger part of this parameter selects which [PathShape2D] to start
## from, while the fractional part determines how far to the next [PathShape2D]
## to tween. These values wrap, so a tween from the last back to the first is
## possible
@export var tween_parameter :float = 0.0:
	set(value):
		tween_parameter = value
		_on_tween_parameter_changed()

## If provided, this [Curve] will be sampled for each tweened point, and
## added to the tween_parameter for calculating that point. This allows the
## line to be tweened at different rates along its length.
@export var tween_curve :Curve:
	set(value):
		if value != tween_curve and tween_curve != null:
			if tween_curve.changed.is_connected(_on_tween_parameter_changed):
				tween_curve.changed.disconnect(_on_tween_parameter_changed)
		tween_curve = value
		if tween_curve != null:
			if ! tween_curve.changed.is_connected(_on_tween_parameter_changed):
				tween_curve.changed.connect(_on_tween_parameter_changed)
		_on_tween_parameter_changed()
var _baked_start_points: Array[PackedVector2Array] = []
var _baked_deltas: Array[PackedVector2Array] = []
var _is_dirty := false


func get_segment_count() -> int:
	return 1


func get_segment_baked_points(_segment_index: int) -> PackedVector2Array:
	return get_baked_points()


func get_segment_baked_length(_segment_index: int) -> float:
	return get_baked_length()


func _bake_tweens() -> void:
	_baked_start_points.clear()
	_baked_deltas.clear()
	for path in paths:
		if path == null:
			return
	for i in paths.size():
		var left := paths[i] as PathShape2D
		var right: PathShape2D
		if i == paths.size() - 1:
			right = paths[0]
		else:
			right = paths[i+1]
		var start_points := PackedVector2Array()
		var deltas := PackedVector2Array()
		var _baked_left := left.get_baked_points() as PackedVector2Array
		var _baked_right := right.get_baked_points() as PackedVector2Array
		if _baked_left.size() == _baked_right.size():
			for j in _baked_left.size():
				start_points.append(_baked_left[j])
				deltas.append(_baked_right[j] - _baked_left[j])
		elif _baked_left.size() > _baked_right.size():
			for j in _baked_left.size():
				start_points.append(_baked_left[j])
				deltas.append(
						right.sample(float(j) / (_baked_left.size() - 1))
						- _baked_left[j])
		else:
			for j in _baked_right.size():
				var start_point := (
						left.sample(float(j) / (_baked_right.size() - 1))
						) as Vector2
				start_points.append(start_point)
				deltas.append(_baked_right[j] - start_point)
		_baked_start_points.append(start_points)
		_baked_deltas.append(deltas)
	_is_dirty = false


func _calculate_baked_points() -> PackedVector2Array:
	if paths.size() == 0:
		return PackedVector2Array()
	if _is_dirty:
		_bake_tweens()
	if _baked_start_points.size() == 0:
		return PackedVector2Array()
	var return_points := PackedVector2Array()
	var point_index: int = 0
	var progress: float = 0.0
	var tween_amount: float
	var tween_index: int
	var tween_fraction :float
	while progress <= 1.0:
		tween_amount = tween_parameter
		if tween_curve != null:
			tween_amount += tween_curve.sample(progress)
		var new_tween_index: int = wrapi(
				floori(tween_amount),
				0,
				paths.size())
		if new_tween_index != tween_index:
			tween_index = new_tween_index
			point_index = ceili(
					progress * (_baked_start_points[tween_index].size() - 1))
		else:
			tween_fraction = wrapf(fmod(tween_amount, 1.0), 0.0, 1.0)
			var start_point := _baked_start_points[tween_index][point_index]
			var delta := _baked_deltas[tween_index][point_index]
			return_points.append(start_point + delta * tween_fraction)
			point_index += 1
		progress = (
				float(point_index)
				/ (_baked_start_points[tween_index].size() - 1))
	return return_points


func _on_path_changed() -> void:
	_is_dirty = true
	super()


func _on_tween_parameter_changed() -> void:
	if caching_enabled:
		cache_clear()
	emit_changed()
