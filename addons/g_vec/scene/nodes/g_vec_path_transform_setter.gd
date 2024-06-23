@tool
class_name GVecPathTransformSetter
extends Marker2D

## [Node2D] that applies a [Transform2D] to a [GVecPathWithTransform]
##
## This node provides a convenient way to set the
## [member GVecPathWithTransform.transform] property of a
## [GVecPathWithTransform]. It applies its own (local) [Transform2D] to the
## attached resource, which can then be referenced elsewhere.


## This signal is fired when [member path] changes to reference a different
## [GVecPath], or when the structure of nested [GVecPath] resources changes.
signal structure_changed


## The [GVecPathWithTransform] to transform
@export var path := GVecPathTransform.new():
	set(value):
		GVecGlobals.disconnect_if_able(path, "path_changed", _on_structure_changed)
		path = value
		GVecGlobals.connect_if_able(path, "path_changed", _on_structure_changed)
		_on_structure_changed()


func _enter_tree():
	# set meta for the SVGTools plugin
	set_meta("_svg_tools_path_property", "path")


func _ready():
	set_notify_local_transform(true)


func _notification(what):
	if what == NOTIFICATION_LOCAL_TRANSFORM_CHANGED:
		path.transform = transform


func _on_structure_changed():
	structure_changed.emit()
