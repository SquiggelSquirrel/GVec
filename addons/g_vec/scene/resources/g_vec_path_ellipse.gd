@tool
class_name GVecPathEllipse
extends GVecPath


@export var radii := Vector2.ONE
@export var angle: float = 0.0
@export var center := Vector2.ZERO
@export var bake_interval: float = 5.0


func _calculate_baked_points() -> PackedVector2Array:
	var small := min(radii.x, radii.y)
	var large := max(radii.x, radii.y)
	var avg := lerpf(small, large, 0.5)
	var avg_angle := bake_interval / avg
	var count := maxi(3, roundi(6.28319 / avg_angle))
	
	var points = PackedVector2Array([])
	var f_interval := 1.0 / count
	for i in count + 1:
		var p := i * f_interval
		points.append(sample(p))
	
	return points


func sample(t :float) -> Vector2:
	var p = t * 6.28319
	var point := center + (
			Vector2.RIGHT.rotated(p) * radii
			).rotated(angle)
	return point
