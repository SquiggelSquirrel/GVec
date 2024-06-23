@tool
extends Node2D

var internal_var := 0


func _get_property_list() -> Array[Dictionary]:
	return [{
		"name": "internal_var",
		"type": TYPE_INT,
		"usage": PROPERTY_USAGE_STORAGE
	}, {
		"name": "external_var",
		"type": TYPE_INT,
		"usage": PROPERTY_USAGE_EDITOR
	}]


func _get(property: StringName) -> Variant:
	match property:
		"external_var":
			return internal_var * 10
	return null


func _set(property: StringName, value: Variant) -> bool:
	match property:
		"external_var":
			internal_var = value / 10
		_:
			return false
	return true


func _ready() -> void:
	var curve := Curve2D.new()
	var callable = curve.get("add_point")
	callable.call(Vector2(2.0, 3.5))
	print(curve.get_point_position(0))
