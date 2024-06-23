@tool
extends Bone2D

@export var print_transforms := false:
	set(value):
		if value:
			print(get_rest_relative_to_skeleton())


func get_rest_relative_to_skeleton() -> Transform2D:
	var result := rest
	var parent := get_parent()
	while parent is Bone2D:
		result = parent.rest * result
		parent = parent.get_parent()
	return result
