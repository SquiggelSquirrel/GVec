@tool
class_name GVecGlobals
extends Object

## Static methods and config for GVec plugin


static func connect_if_able(nullable_object, signal_name, callable):
	if nullable_object == null:
		return
	if ! nullable_object.has_signal(signal_name):
		return
	if nullable_object.is_connected(signal_name, callable):
		return
	nullable_object.connect(signal_name, callable)


static func disconnect_if_able(nullable_object, signal_name, callable):
	if nullable_object == null:
		return
	if ! nullable_object.has_signal(signal_name):
		return
	if ! nullable_object.is_connected(signal_name, callable):
		return
	nullable_object.disconnect(signal_name, callable)
