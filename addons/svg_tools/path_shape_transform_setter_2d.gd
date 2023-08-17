@tool
class_name PathShapeTransformSetter2D
extends Marker2D

## [Node2D] that applies a [Transform2D] to a [PathShape2DWithTransform]
##
## This node provides a conveneint way to set the
## [member PathShape2DWithTransform.transform] property of a
## [PathShape2DWithTransform]. It applies its own (local) [Transform2D] to the
## attached resource, which can then be referenced elsewhere.


## The [PathShape2DWithTransform] to transform
@export var path := PathShape2DTransform.new()


func _enter_tree():
	# set meta for the SVGTools plugin
	set_meta("_svg_tools_path_property", "path")


func _ready():
	set_notify_local_transform(true)


func _notification(what):
	if what == NOTIFICATION_LOCAL_TRANSFORM_CHANGED:
		path.transform = transform
