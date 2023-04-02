@tool
class_name PathShape2DFromCurve2D
extends PathShape2D

## Wrapper for [Curve2D] as a [PathShape2D]
##
## This resource wraps a [Curve2D], allowing it to be used in places that
## require a [PathShape2D]. It exposes segments based on the curve's point
## count, however this may fail in case of duplicate/overlapping points.

## The [Curve2D] to wrap
@export var curve := Curve2D.new():
	set(value):
		if value == curve:
			return
		if curve.changed.is_connected(emit_changed):
			curve.changed.disconnect(emit_changed)
		curve = value
		curve.changed.connect(emit_changed)
		emit_changed()


func get_baked_length() -> float:
	return curve.get_baked_length()


func get_baked_points() -> PackedVector2Array:
	return curve.get_baked_points()


func get_segment_baked_points(segment_index :int) -> PackedVector2Array:
	var curve_points := curve.get_baked_points()
	var start_index :int
	var end_index :int
	for i in curve_points.size():
		if curve_points[i] == curve.get_point_position(segment_index):
			start_index = i
			break
	for i in range(start_index, curve_points.size()):
		if curve_points[i] == curve.get_point_position(segment_index + 1):
			end_index = i
	return curve_points.slice(start_index, end_index + 1)


func get_segment_baked_length(segment_index :int) -> float:
	var points := get_segment_baked_points(segment_index)
	var length: float = 0.0
	for i in range(1, points.size()):
		length += points[i].distance_to(points[i-1])
	return length


func get_segment_count() -> int:
	return max(curve.point_count - 1, 0)


func sample_baked(f :float) -> Vector2:
	return curve.sample_baked(f)
