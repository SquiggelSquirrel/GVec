@tool
extends Marker2D


func _process(delta: float) -> void:
	transform = $"../Bone2D/Bone2D".get_rest_relative_to_skeleton()
