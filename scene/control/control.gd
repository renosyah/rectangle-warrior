extends Node2D

signal touch_position(pos)
signal disconnect

onready var _touch_input = $touch_input

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	
func _on_touch_input_any_gesture(_sig, val):
	if val is InputEventSingleScreenTap:
		emit_signal("touch_position", get_global_mouse_position())

func _unhandled_input(event):
	if event is InputEventMouseButton and event.is_action_pressed("left_click"):
		emit_signal("touch_position", get_global_mouse_position())
		
	_touch_input.check_input(event)
	
	
	
func _on_disconnect_button_pressed():
	emit_signal("disconnect")
