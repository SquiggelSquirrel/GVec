@tool
extends Sprite2D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var bone := $"../../Bone2D/Bone2D" as Bone2D
	var rest := bone.get_rest_relative_to_skeleton() as Transform2D
	var pose := bone.get_relative_transform_to_parent($"../..") as Transform2D
	transform = rest.affine_inverse() * pose
	scale = Vector2.ONE * 0.01
