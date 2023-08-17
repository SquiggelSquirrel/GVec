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
@export var enable_logging := false
@export var tween_parameter :float = 0.0:
	set(value):
		value = round(value * 64) / 64
		if enable_logging:
			print("Setting ", value)
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

@export var align_segments := false:
	set(value):
		if value:
			for i in range(1, paths.size()):
				assert(paths[0].get_segment_count() == paths[i].get_segment_count())
		if value != align_segments:
			align_segments = value
			_is_dirty = true
			emit_changed()

var _baked_start_points: Array[Array] = []
var _baked_deltas: Array[Array] = []
var _is_dirty := false


func get_segment_count() -> int:
	if align_segments:
		return paths[0].get_segment_count()
	else:
		return 1


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
		
		if align_segments:
			var start_points := Array()
			var deltas := Array()
			for j in left.get_segment_count():
				var left_segment := left.get_segment_baked_points(j)
				var right_segment := right.get_segment_baked_points(j)
				var tweens = _bake_tweens_from_points(
						left_segment, right_segment)
				start_points.append(tweens.start_points)
				deltas.append(tweens.deltas)
			_baked_start_points.append(start_points)
			_baked_deltas.append(deltas)
		else:
			var tweens = _bake_tweens_from_points(
					left.get_baked_points(),
					right.get_baked_points())
			_baked_start_points.append([tweens.start_points])
			_baked_deltas.append([tweens.deltas])
	_is_dirty = false


func _bake_tweens_from_points(
	left_points :PackedVector2Array,
	right_points :PackedVector2Array
	) -> Dictionary:
	var start_points := PackedVector2Array()
	var deltas := PackedVector2Array()
	if left_points.size() == right_points.size():
		for j in left_points.size():
			start_points.append(left_points[j])
			deltas.append(right_points[j] - left_points[j])
	elif left_points.size() > right_points.size():
		for j in left_points.size():
			var f := float(j) / (left_points.size() - 1)
			start_points.append(left_points[j])
			deltas.append(
					PathShape2D.sample_points(right_points, f) - left_points[j])
	else:
		for j in right_points.size():
			var f := float(j) / (right_points.size() - 1)
			var start_point := PathShape2D.sample_points(left_points, f)
			start_points.append(start_point)
			deltas.append(right_points[j] - start_point)
	return {"start_points": start_points, "deltas": deltas}


func _calculate_baked_points() -> PackedVector2Array:
	if enable_logging:
		print(tween_parameter)
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
		var baked_start_points := flatten_segments(_baked_start_points[tween_index])
		if new_tween_index != tween_index:
			tween_index = new_tween_index
			baked_start_points = flatten_segments(_baked_start_points[tween_index])
			point_index = ceili(
					progress * (_baked_start_points[tween_index].size() - 1))
		else:
			tween_fraction = wrapf(fmod(tween_amount, 1.0), 0.0, 1.0)
			var start_point := baked_start_points[point_index]
			var delta := flatten_segments(_baked_deltas[tween_index])[point_index]
			return_points.append(start_point + delta * tween_fraction)
			point_index += 1
		if enable_logging and progress == 0.0:
			print(tween_index, ' ', tween_fraction)
		progress = (
				float(point_index)
				/ (baked_start_points.size() - 1))
	return return_points


func _calculate_segment_points(segment_index: int) -> PackedVector2Array:
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
		var baked_start_points: PackedVector2Array
		baked_start_points = _baked_start_points[tween_index][segment_index]
		if new_tween_index != tween_index:
			tween_index = new_tween_index
			baked_start_points = _baked_start_points[tween_index][segment_index]
			point_index = ceili(
					progress * (_baked_start_points[tween_index].size() - 1))
		else:
			tween_fraction = wrapf(fmod(tween_amount, 1.0), 0.0, 1.0)
			var start_point := baked_start_points[point_index]
			var delta: Vector2
			delta = _baked_deltas[tween_index][segment_index][point_index]
			return_points.append(start_point + delta * tween_fraction)
			point_index += 1
		progress = (
				float(point_index)
				/ (baked_start_points.size() - 1))
	return return_points


static func flatten_segments(segments: Array) -> PackedVector2Array:
	var out := segments[0] as PackedVector2Array
	for i in range(1, segments.size()):
		out.append_array(segments[i].slice(1))
	return out


func _on_path_changed() -> void:
	if align_segments:
		for i in range(1, paths.size()):
			assert(paths[0].get_segment_count() == paths[i].get_segment_count())
	_is_dirty = true
	super()


func _on_tween_parameter_changed() -> void:
	if caching_enabled:
		cache_clear()
	emit_changed()
