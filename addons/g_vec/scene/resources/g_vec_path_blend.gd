@tool
class_name GVecPathBlend
extends GVecPathCombination

@export var weights: PackedFloat32Array:
	set(value):
		for i in value.size():
			value[i] = clampf(value[i], 0.0, 1.0)
		weights = value
		if caching_enabled:
			cache_clear()
		_normalise_weights()
		emit_changed()
var normalised_weights: PackedFloat32Array
var baked_source_points: Array[PackedVector2Array]


func _on_path_changed() -> void:
	_bake_source_points()
	_normalise_weights()
	super()


func _normalise_weights() -> void:
	var total_weight := 0.0
	for i in baked_source_points.size():
		if i < weights.size():
			total_weight += weights[i]
	if total_weight == 0.0:
		normalised_weights = [1.0]
	else:
		normalised_weights = []
		for i in baked_source_points.size():
			if i < weights.size():
				normalised_weights.append(weights[i] / total_weight)


func _bake_source_points() -> void:
	var max_point_count := 0
	for path in paths:
		if path == null:
			continue
		max_point_count = maxi(max_point_count, path.get_baked_points().size())
	
	baked_source_points = []
	if max_point_count < 2:
		for path in paths:
			if path == null:
				continue
			if path.get_baked_points().size() == 1:
				baked_source_points.append(path.get_baked_points())
		return
	
	for path in paths:
		if path == null:
			continue
		var baked_points: PackedVector2Array = []
		for i in max_point_count:
			var f := float(i) / float(max_point_count - 1)
			var sample_point := path.sample(f)
			baked_points.append(sample_point)
		baked_source_points.append(baked_points)


func _calculate_baked_points() -> PackedVector2Array:
	var results: PackedVector2Array = []
	if baked_source_points.size() == 0:
		return results
	for point_index in baked_source_points[0].size():
		var point := Vector2.ZERO
		for weight_index in normalised_weights.size():
			point += baked_source_points[weight_index][point_index] * normalised_weights[weight_index]
		results.append(point)
	return results
